import 'package:flutter/material.dart';
import 'package:task_management/data/database_helper(project).dart';
import 'package:task_management/models/project.dart';

class UpdateProjectScreen extends StatefulWidget {
  Project project;

  UpdateProjectScreen({required this.project});

  @override
  _UpdateProjectScreenState createState() => _UpdateProjectScreenState();
}

class _UpdateProjectScreenState extends State<UpdateProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late DateTime _dueDate;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing project details
    _nameController.text = widget.project.name;
    _descriptionController.text = widget.project.description;
    _dueDate = widget.project.dueDate;
    _isCompleted = widget.project.isCompleted;
  }

  void _updateProject() async {
    // Extract updated project details from controllers
    String updatedName = _nameController.text;
    String updatedDescription = _descriptionController.text;

    // Create a new Project object with updated details
    Project updatedProject = Project(
      name: updatedName,
      description: updatedDescription,
      dueDate: _dueDate,
      tasks: widget.project.tasks,
      id: widget.project.id,
      isCompleted: _isCompleted,
    );

    try {
      // Update the project in the local state
      setState(() {
        widget.project = updatedProject;
      });

      // Update the project in the database
      await ProjectDatabase().updateProject(updatedProject);

      // Pop the screen
      Navigator.pop(context);
    } catch (e) {
      // Handle errors, e.g., show a snackbar or display an error message
      print('Error updating project: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16),
            // Due Date Picker
            Row(
              children: [
                Text('Due Date: '),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != _dueDate) {
                      setState(() {
                        _dueDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    "${_dueDate.toLocal()}".split(' ')[0],
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Completion Status Toggle
            Row(
              children: [
                Text('Completed:'),
                SizedBox(width: 8),
                Switch(
                  value: _isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _isCompleted = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProject,
              child: Text('Update Project'),
            ),
          ],
        ),
      ),
    );
  }
}
