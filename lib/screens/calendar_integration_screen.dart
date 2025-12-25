import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/models/task.dart';






class TaskCalendar extends StatefulWidget {
 @override
 _TaskCalendarState createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
 DateTime _selectedDay = DateTime.now();
 final TaskDatabase taskDatabase = TaskDatabase();
 List<Task>? _tasksForSelectedDay;

 FutureBuilder<List<Task>> _buildTaskList(List<Task>? tasks) {
    return FutureBuilder<List<Task>>(
      future: taskDatabase.fetchTasksForDate(_selectedDay),
      builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No tasks available for the selected day.');
        } else {
          List<Task>? tasksCreatedOnSelectedDay = snapshot.data;
          return _buildTaskListView(tasksCreatedOnSelectedDay);
        }
      },
    );
 }

 Widget _buildTaskListView(List<Task>? tasks) {
    return Expanded(
      child: ListView.builder(
        itemCount: tasks?.length ?? 0,
        itemBuilder: (context, index) {
          Task task = tasks![index];
          return TaskWidget(task: task);
        },
      ),
    );
 }

 @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2021),
            lastDay: DateTime(2025),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) {
              return _selectedDay == day;
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),
          _buildTaskList(_tasksForSelectedDay),
        ],
      ),
    );
 }
}

class TaskWidget extends StatelessWidget {
 final Task task;

 TaskWidget({required this.task});

 @override
 Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: Text('Due Date: ${DateFormat.yMd().format(task.dueDate)}'),
    );
 }
}