import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/models/task.dart';

class TaskStatsPage extends StatefulWidget {
  @override
  _TaskStatsPageState createState() => _TaskStatsPageState();
}

class _TaskStatsPageState extends State<TaskStatsPage> {
  List<Task>? tasks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getTasks();
  }

  _getTasks() async {
    setState(() => _isLoading = true);
    tasks = await TaskDatabase.getTasks();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deadlines'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildUpcomingDeadlines(tasks),
            ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }

  Widget _buildUpcomingDeadlines(List<Task>? tasks) {
    List<Task> upcomingTasks = tasks!.where((task) => task.hasDueDate).toList();

    return ListView.builder(
      itemCount: upcomingTasks.length,
      itemBuilder: (context, index) {
        Task task = upcomingTasks[index];
        String formattedDate = DateFormat('yyyy-MM-dd').format(task.dueDate);

        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(task.title, style: TextStyle(color: Colors.orange)),
            subtitle: Text(
              'Due Date: $formattedDate',
              style: TextStyle(color: Colors.orange),
            ),
            trailing: Icon(Icons.arrow_forward, color: Colors.orange),
            onTap: () {
              _handleTaskTap(task);
            },
          ),
        );
      },
    );
  }

  void _handleTaskTap(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Task Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Title: ${task.title}'),
              Text('Due Date: ${DateFormat('yyyy-MM-dd').format(task.dueDate)}'),
              // Add more details as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
