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
  // State variables
  DateTime _selectedDay = DateTime.now(); // Currently selected date in calendar
  final TaskDatabase taskDatabase = TaskDatabase(); // Database instance for task operations
  List<Task>? _tasksForSelectedDay; // Tasks loaded for the selected day
  Map<DateTime, List<Task>> _taskCache = {}; // Cache to store loaded tasks by date
  bool _isLoading = false; // Loading state indicator

  @override
  void initState() {
    super.initState();
    _loadTasksForSelectedDay(); // Load tasks for today when screen initializes
  }

  /// Loads tasks for the currently selected date
  /// Uses caching to avoid repeated database calls for the same date
  /// Updates loading state and handles errors gracefully
  Future<void> _loadTasksForSelectedDay() async {
    // Check cache first to avoid unnecessary database calls
    if (_taskCache.containsKey(_selectedDay)) {
      setState(() {
        _tasksForSelectedDay = _taskCache[_selectedDay];
      });
      return;
    }

    // Show loading indicator while fetching data
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch tasks from database for the selected date
      final tasks = await taskDatabase.fetchTasksForDate(_selectedDay);
      
      // Cache the results for future use
      _taskCache[_selectedDay] = tasks;
      
      // Update UI with loaded tasks
      setState(() {
        _tasksForSelectedDay = tasks;
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors during database operations
      setState(() {
        _isLoading = false;
      });
      // TODO: Show error message to user
    }
  }

  /// Builds the task list widget based on current state
  /// Shows loading indicator, empty state, or task list
  Widget _buildTaskList() {
    if (_isLoading) {
      // Show loading spinner while fetching tasks
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tasksForSelectedDay == null || _tasksForSelectedDay!.isEmpty) {
      // Show empty state when no tasks exist for selected day
      return const Expanded(
        child: Center(
          child: Text('No tasks available for the selected day.'),
        ),
      );
    }

    // Show task list when tasks are available
    return _buildTaskListView(_tasksForSelectedDay!);
  }

  /// Builds the list view for displaying tasks
  /// Includes pull-to-refresh functionality
  /// Handles task updates through callback
  Widget _buildTaskListView(List<Task> tasks) {
    return Expanded(
      child: RefreshIndicator(
        // Allow manual refresh of task list
        onRefresh: _loadTasksForSelectedDay,
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return TaskWidget(
              task: tasks[index],
              // Callback to refresh list when task is updated
              onTaskUpdated: _loadTasksForSelectedDay,
            );
          },
        ),
      ),
    );
  }

  /// Main build method for the calendar screen
  /// Creates the overall layout with calendar and task list
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Calendar'),
      ),
      body: Column(
        children: [
          // Calendar widget with date selection and task indicators
          TableCalendar(
            // Dynamic date range (1 year before/after current date)
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDay,
            // Highlights the currently selected date
            selectedDayPredicate: (day) {
              return _selectedDay == day;
            },
            // Handles date selection and triggers task loading
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
              _loadTasksForSelectedDay(); // Load tasks for newly selected date
            },
            // Shows task indicators on calendar dates
            eventLoader: (day) {
              return _taskCache[day] ?? [];
            },
          ),
          // Task list for selected date
          _buildTaskList(),
        ],
      ),
    );
  }
}

/// Widget for displaying individual task information
/// Shows task status, details, and provides interaction options
class TaskWidget extends StatelessWidget {
  final Task task; // Task data to display
  final VoidCallback? onTaskUpdated; // Callback when task is updated

  const TaskWidget({
    Key? key,
    required this.task,
    this.onTaskUpdated,
  }) : super(key: key);

  /// Builds the task card with status indicator and details
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        // Status indicator icon (check for completed, pending for incomplete)
        leading: CircleAvatar(
          backgroundColor: task.isCompleted ? Colors.green : Colors.blue,
          child: Icon(
            task.isCompleted ? Icons.check : Icons.pending,
            color: Colors.white,
            size: 20,
          ),
        ),
        // Task title with strikethrough for completed tasks
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Formatted due date and time
            Text(
              'Due: ${DateFormat.yMd().add_jm().format(task.dueDate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            // Task description if available
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                task.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        // Menu button for task actions
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleMenuAction(context, value);
          },
          itemBuilder: (context) => [
            // Toggle completion status
            PopupMenuItem(
              value: 'toggle_complete',
              child: Text(task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            ),
            // Edit task (placeholder)
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            // Delete task (placeholder)
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles menu actions for task operations
  /// Routes to appropriate method based on selected action
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'toggle_complete':
        _toggleTaskCompletion();
        break;
      case 'edit':
        _editTask(context);
        break;
      case 'delete':
        _deleteTask(context);
        break;
    }
  }

  /// Toggles task completion status
  /// Updates task in database and refreshes UI
  Future<void> _toggleTaskCompletion() async {
    try {
      // Create updated task with toggled completion status
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        createdAt: task.createdAt,
        isCompleted: !task.isCompleted,
        hasDueDate: task.hasDueDate,
      );

      // Update task in database
      await TaskDatabase().updateTask(updatedTask);
      
      // Refresh task list to show updated status
      onTaskUpdated?.call();
    } catch (e) {
      // Show error message if update fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Opens edit dialog for task
  /// Allows user to modify task title, description, and due date
  Future<void> _editTask(BuildContext context) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDate = task.dueDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(task.dueDate);
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task title input
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // Task description input
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Due date picker
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(
                    DateFormat.yMd().add_jm().format(selectedDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          selectedTime = pickedTime;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            // Save button
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task title cannot be empty')),
                  );
                  return;
                }
                
                try {
                  // Create updated task with new values
                  final updatedTask = Task(
                    id: task.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    dueDate: selectedDate,
                    createdAt: task.createdAt,
                    isCompleted: task.isCompleted,
                    hasDueDate: true,
                  );

                  // Update task in database
                  await TaskDatabase().updateTask(updatedTask);
                  
                  // Close dialog and refresh task list
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task updated successfully')),
                    );
                    onTaskUpdated?.call();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update task: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows confirmation dialog for task deletion
  /// Handles user confirmation and deletion process
  Future<void> _deleteTask(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          // Cancel button - closes dialog without action
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          // Delete button - confirms deletion
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Only proceed if user confirmed deletion
    if (confirmed == true) {
      try {
        // Delete task from database
        await TaskDatabase().deleteTask(task.id);
        
        // Show success message and refresh task list
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
          onTaskUpdated?.call();
        }
      } catch (e) {
        // Show error message if deletion fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}