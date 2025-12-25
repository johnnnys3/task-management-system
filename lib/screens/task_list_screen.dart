import 'package:flutter/material.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/models/task.dart' as TaskModel;
import 'package:task_management/screens/task_details_screen.dart';
import 'package:task_management/screens/task_creation_screen.dart';
import 'package:task_management/screens/update_task_screen.dart';
import 'package:task_management/service/task_service.dart';

class TaskListScreen extends StatefulWidget {
  final String userId;
  final CustomUser user;
  final bool isAdmin;
  final List<TaskModel.Task> tasks;

  TaskListScreen({
    required this.userId,
    required this.user,
    required this.isAdmin,
    required this.tasks,
  });

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with AutomaticKeepAliveClientMixin {
  List<TaskModel.Task> tasks = [];
  TaskService taskService = TaskService();
  bool isLoading = false;
  String errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize tasks from the passed list
    tasks = widget.tasks;
    // Load tasks from the database
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      // Fetch tasks using the instance
      List<TaskModel.Task> loadedTasks =
          (await taskService.getTasks(userId: widget.userId)).cast<TaskModel.Task>();

      // Explicitly cast to the correct type
      setState(() {
        tasks = loadedTasks;
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading tasks: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? ErrorDisplay(message: errorMessage)
              : TaskListView(
                  tasks: tasks,
                  onTaskTap: navigateToTaskDetailsScreen,
                  onUpdateTask: widget.isAdmin ? navigateToUpdateTaskScreen : null,
                  onDeleteTask: widget.isAdmin ? deleteTask : null,
                ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await _navigateToCreateTask();
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void navigateToTaskDetailsScreen(TaskModel.Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailsScreen(task: task)),
    );
  }

  void navigateToUpdateTaskScreen(TaskModel.Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateTaskScreen(task: task)),
    );
  }

  void addTask(TaskModel.Task newTask) async {
    try {
      await taskService.addTask(userId: widget.userId, task: newTask);
      await _loadTasks();
    } catch (e) {
      setState(() {
        errorMessage = 'Error adding task: $e';
      });
    }
  }

  void deleteTask(TaskModel.Task task) async {
    try {
      await taskService.deleteTask(
        userId: widget.userId,
        taskId: task.id as String,
      );
      await _loadTasks();
    } catch (e) {
      setState(() {
        errorMessage = 'Error deleting task: $e';
      });
    }
  }

  Future<void> _navigateToCreateTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTask(availableProjects: []),
      ),
    );

    if (result != null && result is TaskModel.Task) {
      addTask(result);
    }
  }
}

class TaskListView extends StatelessWidget {
  final List<TaskModel.Task> tasks;
  final Function(TaskModel.Task) onTaskTap;
  final void Function(TaskModel.Task)? onUpdateTask;
  final void Function(TaskModel.Task)? onDeleteTask;

  TaskListView({
    required this.tasks,
    required this.onTaskTap,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return TaskListItem(
          task: tasks[index],
          onTaskTap: () => onTaskTap(tasks[index]),
          onUpdateTask: onUpdateTask,
          onDeleteTask: onDeleteTask,
        );
      },
    );
  }
}

class TaskListItem extends StatelessWidget {
  final TaskModel.Task task;
  final VoidCallback onTaskTap;
  final void Function(TaskModel.Task)? onUpdateTask;
  final void Function(TaskModel.Task)? onDeleteTask;

  TaskListItem({
    required this.task,
    required this.onTaskTap,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(task.description),
        onTap: onTaskTap,
        onLongPress: () {
          if (onUpdateTask != null || onDeleteTask != null) {
            _showTaskOptionsDialog(context);
          }
        },
      ),
    );
  }

  void _showTaskOptionsDialog(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
      items: [
        if (onUpdateTask != null)
          PopupMenuItem(
            value: 'update',
            child: ListTile(
              title: Text('Update Task'),
              onTap: () {
                Navigator.pop(context);
                onUpdateTask!(task);
              },
            ),
          ),
        if (onDeleteTask != null)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              title: Text('Delete Task'),
              onTap: () {
                Navigator.pop(context);
                onDeleteTask!(task);
              },
            ),
          ),
      ],
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String message;

  ErrorDisplay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
