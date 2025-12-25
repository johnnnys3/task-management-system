import 'package:flutter/material.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/models/project.dart' as TaskProject;
import 'package:task_management/screens/project_details_screen.dart';
import 'package:task_management/screens/create_project_screen.dart';
import 'package:task_management/screens/update_project_screen.dart';
import 'package:task_management/service/project_service.dart';

class ProjectManagementScreen extends StatefulWidget {
  final String userId;
  final CustomUser user;
  final bool isAdmin;

  ProjectManagementScreen({required this.userId, required this.user, required this.isAdmin});

  @override
  _ProjectManagementScreenState createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> with AutomaticKeepAliveClientMixin {
  List<TaskProject.Project> projects = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      ProjectService projectService = ProjectService();
      List<TaskProject.Project> loadedProjects = (await projectService.getProjects(userId: widget.userId)).cast<TaskProject.Project>();
      setState(() {
        projects = loadedProjects;
      });
    } catch (e) {
      print('Error loading projects: $e');
      // Handle error loading projects
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Project Management'),
        backgroundColor: Colors.orange,
      ),
      body: _buildProjectList(),
      floatingActionButton: widget.isAdmin ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildProjectList() {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              projects[index].name,
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              _navigateToProjectDetailsScreen(projects[index]);
            },
            onLongPress: () {
              if (widget.isAdmin) {
                _showOptionsDialog(projects[index]);
              }
            },
          ),
        );
      },
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _navigateToCreateProjectScreen();
      },
      tooltip: 'Create Project',
      child: Icon(Icons.add),
      backgroundColor: Colors.orange,
    );
  }

  void _navigateToCreateProjectScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectScreen(),
      ),
    );

    if (result != null && result is TaskProject.Project) {
      setState(() {
        projects.add(result);
      });
    }
  }

  void _navigateToProjectDetailsScreen(TaskProject.Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(project: project),
      ),
    );
  }

  void _showOptionsDialog(TaskProject.Project project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Edit Project'),
                onTap: () {
                  Navigator.pop(context);
                  _editProject(project);
                },
              ),
              ListTile(
                title: Text('Delete Project'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProject(project);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editProject(TaskProject.Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateProjectScreen(project: project),
      ),
    );
  }

  void _deleteProject(TaskProject.Project project) async {
  try {
    ProjectService projectService = ProjectService();
    await projectService.deleteProject(projectId: project.id as String, userId: widget.userId);

    setState(() {
      projects.remove(project);
    });
  } catch (e) {
    print('Error deleting project: $e');
    // Handle error deleting project
  }
}

}
