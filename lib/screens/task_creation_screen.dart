import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/models/task_list_notifier.dart';
import 'package:task_management/authentication/authentication_service.dart'; // Import your authentication service


class CreateTask extends StatefulWidget {
  final List<String> availableProjects;

  CreateTask({required this.availableProjects});

  @override
  _CreateTaskState createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDueDate = DateTime.now();
  TextEditingController _taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? selectedMember;
  String? selectedProject;
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  List<String> memberList = []; // Initialize with an empty list
  bool isProjectValid = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

 Future<void> _fetchMembers() async {
  try {
    final QuerySnapshot<Map<String, dynamic>> usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    if (usersSnapshot.docs.isNotEmpty) {
      List<String> users = usersSnapshot.docs
          .map((doc) => doc.data()['name'].toString())
          .toList();

      setState(() {
        memberList = users;
      });
    }
  } catch (error) {
    print('Error fetching members: $error');
    // Handle error accordingly
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Task'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Task Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _taskNameController,
                          decoration: InputDecoration(
                            labelText: 'Task Name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a task name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Task Description',
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text('Due Date: '),
                            SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDueDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (pickedDate != null &&
                                    pickedDate != selectedDueDate) {
                                  setState(() {
                                    selectedDueDate = pickedDate;
                                  });
                                }
                              },
                              child: Text(
                                "${selectedDueDate.toLocal()}".split(' ')[0],
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Assign Members',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(selectedMember ?? 'Select Member'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _selectMember(context);
                              },
                              child: Text('Choose'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Project Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(selectedProject ?? 'Select Project'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _selectProject(context);
                              },
                              child: Text('Choose'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isProjectValid && selectedMember != null
                      ? () => _createTask(context)
                      : null,
                  child: Text('Create Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectMember(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: ListView.builder(
            itemCount: memberList.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(memberList[index]),
                onTap: () {
                  setState(() {
                    selectedMember = memberList[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Project>> fetchAvailableProjects() async {
    try {
      final QuerySnapshot result =
          await FirebaseFirestore.instance.collection('projects').get();
      final List<DocumentSnapshot> documents = result.docs;

      List<Project> projects = documents.map((doc) {
        Timestamp? dueDateTimestamp = doc['dueDate'] as Timestamp?;
        DateTime dueDate = dueDateTimestamp?.toDate() ?? DateTime.now();

        return Project(
          id: doc.id,
          name: doc['name'] ?? '',
          description: doc['description'] ?? '',
          dueDate: dueDate,
          tasks: [], isCompleted: false,
          // Add other necessary fields for the Project object
        );
      }).toList();

      return projects;
    } catch (error) {
      print('Error fetching projects: $error');
      throw error; // Rethrow the error to propagate it to the caller
    }
  }

void _selectProject(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 200,
        child: FutureBuilder(
          future: fetchAvailableProjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading projects'));
            }

            List<Project> projects = snapshot.data as List<Project>;
            return ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(projects[index].name),
                  onTap: () {
  setState(() {
    selectedProject = projects[index].name;
    isProjectValid = true;

    // Update the selected project's task array
    _updateProjectTask(projects[index].id, _taskNameController.text);
  });
  Navigator.pop(context);
},
                );
              },
            );
          },
        ),
      );
    },
  );
}

void _updateProjectTask(String projectId, String taskTitle) {
  try {
    FirebaseFirestore.instance.collection('projects').doc(projectId).update({
      'tasks': FieldValue.arrayUnion([
        {
          'title': taskTitle,
          'projectId': projectId,  // Include the project ID in the task data
          // Add other necessary fields for the task object
        }
      ]),
    }).then((_) {
      print('Project task updated successfully!');
    }).catchError((error) {
      print('Error updating project task: $error');
    });
  } catch (error) {
    print('Error updating project task: $error');
  }
}



  void _createTask(BuildContext context) async {
    if (_formKey.currentState!.validate() && selectedMember != null) {
      String projectName = selectedProject ?? '';

      if (projectName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a project'),
          ),
        );
        return;
      }

      Task newTask = Task(
        id: DateTime.now().toIso8601String(),
        title: _taskNameController.text,
        description: descriptionController.text,
        dueDate: selectedDueDate,
        assignedMembers: [selectedMember!],
        associatedProject: Project(
          id: 'project_id',
          name: projectName,
          description: '',
          dueDate: DateTime.now(),
          tasks: [], isCompleted: false,
          // Add other necessary fields for the Project object
        ),
        attachments: [],
        isCompleted: false,
      );

      tasksCollection
          .add(newTask.toMap())
          .then((_) {
            Provider.of<TaskListNotifier>(context, listen: false).addTask(newTask);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task Created Successfully!'),
              ),
            );

            // Send the created task back to the task list screen
            Navigator.pop(context, newTask);
          })
          .catchError((error) {
            print('Error adding task: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create task. Please try again.'),
              ),
            );
          });
    }
  }
}
