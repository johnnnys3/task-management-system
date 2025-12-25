import 'package:flutter/material.dart';
import 'package:task_management/models/project.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  ProjectDetailsScreen({required this.project});

  @override
  _ProjectDetailsScreenState createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late Project project;
  String projectDescription = '';
  List<String> relatedTaskTitles = [];

  @override
  void initState() {
    super.initState();
    project = widget.project;
    _fetchProjectDetails();
    _fetchRelatedTasks();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> projectSnapshot =
          await FirebaseFirestore.instance.collection('projects').doc(project.id).get();

      if (projectSnapshot.exists) {
        setState(() {
          projectDescription = projectSnapshot.data()?['description'] ?? '';
        });
      }
    } catch (error) {
      print('Error fetching project details: $error');
      // Handle error accordingly
    }
  }

  Future<void> _fetchRelatedTasks() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> projectSnapshot =
          await FirebaseFirestore.instance.collection('projects').doc(project.id).get();

      if (projectSnapshot.exists) {
        List<String> taskTitles = (projectSnapshot.data()?['tasks'] as List<dynamic>? ?? [])
            .map<String>((task) => task['title'].toString())
            .toList();

        setState(() {
          relatedTaskTitles = taskTitles;
        });
      }
    } catch (error) {
      print('Error fetching related tasks: $error');
      // Handle error accordingly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Due Date: ${_formattedDate(project.dueDate)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Status: ${project.isCompleted ? 'Completed' : 'Pending'}',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      projectDescription.isNotEmpty ? projectDescription : 'No description available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Related Tasks',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    if (relatedTaskTitles.isNotEmpty)
                      Container(
                        height: 150, // Adjust the height based on your preference
                        child: ListView.builder(
                          itemCount: relatedTaskTitles.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                relatedTaskTitles[index],
                                style: TextStyle(fontSize: 16),
                              ),
                              // Add more details if needed
                            );
                          },
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          'No related tasks available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
