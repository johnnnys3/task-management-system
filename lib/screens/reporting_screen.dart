import 'package:flutter/material.dart';
import 'package:task_management/data/database_helper(task).dart';


class ReportingScreen extends StatefulWidget {
  @override
  _ReportingScreenState createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;

  final TaskDatabase _taskDatabase = TaskDatabase();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final tasks = await _taskDatabase.fetchTasks();

      setState(() {
        _totalTasks = tasks.length;
        _completedTasks = tasks.where((task) => task.isCompleted).length;
        _pendingTasks = tasks.where((task) => !task.isCompleted).length;
      });
    } catch (e) {
      // Handle any errors here, e.g., log the error
      print('Error fetching tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporting'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.assignment_turned_in, color: Colors.green),
                title: Text('Completed Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                trailing: Text('$_completedTasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
              ListTile(
                leading: Icon(Icons.assignment_late, color: Colors.red),
                title: Text('Pending Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                trailing: Text('$_pendingTasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
              ListTile(
                leading: Icon(Icons.assignment, color: Colors.grey),
                title: Text('Total Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                trailing: Text('$_totalTasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              SizedBox(height: 20),
              // Add more elements as needed
            ],
          ),
        ),
      ),
    );
  }
}
