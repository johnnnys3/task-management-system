import 'package:flutter/material.dart';
import 'package:task_management/data/database_helper(project).dart';
import 'package:task_management/models/project.dart';

class CreateProjectScreen extends StatefulWidget {
  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectDescriptionController = TextEditingController();
  DateTime selectedDueDate = DateTime.now();

  void _createProject(BuildContext context) async {
    if (_validateInput()) {
      Project newProject = Project(
        name: projectNameController.text,
        description: projectDescriptionController.text,
        dueDate: selectedDueDate,
        tasks: [],
        id: '', isCompleted: false,
        // Add other fields as needed
      );

      try {
        await ProjectDatabase().addProject(newProject);
        Navigator.pop(context, newProject);
      } catch (e) {
        _showErrorSnackbar(context, 'An error occurred. Please try again.');
        print('Error creating project: $e');
      }
    }
  }

  bool _validateInput() {
    if (projectNameController.text.isEmpty) {
      _showErrorSnackbar(context, 'Project name cannot be empty.');
      return false;
    }
    // Add more validation as needed
    return true;
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Project'),
        backgroundColor: Theme.of(context).primaryColor, // Use ThemeData for styling
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: projectNameController,
              decoration: InputDecoration(
                labelText: 'Project Name',
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: projectDescriptionController,
              decoration: InputDecoration(
                labelText: 'Project Description',
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 16),
            // Due Date Picker
            Row(
              children: [
                Text('Due Date: ', style: TextStyle(color: Theme.of(context).primaryColor)),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != selectedDueDate) {
                      setState(() {
                        selectedDueDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    "${selectedDueDate.toLocal()}".split(' ')[0],
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _createProject(context);
              },
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).primaryColor,
              ),
              child: Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}
