import 'package:flutter/material.dart';
import 'package:task_management/models/task.dart';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;

  TaskDetailsScreen({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Task Title', task.title),
            _buildDetailItem('Description', task.description),
            _buildDetailItem('Due Date', _formattedDate(task.dueDate)),
            _buildDetailItem('Assigned To', task.assignedMembers.join(', ')),
            if (task.associatedProject != null)
              _buildDetailItem('Associated Project', task.associatedProject!.name),
            // Add more details and attachments as needed
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
          Divider(),
        ],
      ),
    );
  }

  String _formattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
