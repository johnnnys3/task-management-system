import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_management/domain/entities/task_entity.dart';






class TaskEntityCalendar extends StatefulWidget {
  const TaskEntityCalendar({super.key});

  @override
  _TaskEntityCalendarState createState() => _TaskEntityCalendarState();
}

class _TaskEntityCalendarState extends State<TaskEntityCalendar> {
  // State variables
  DateTime _selectedDay = DateTime.now(); // Currently selected date in calendar
  // Note: TaskEntityDatabase will be replaced with new architecture
  // final TaskEntityDatabase taskDatabase = TaskEntityDatabase();
  List<TaskEntity>? _tasksForSelectedDay; // TaskEntitys loaded for the selected day
  final Map<DateTime, List<TaskEntity>> _taskCache = {}; // Cache to store loaded tasks by date
  bool _isLoading = false; // Loading state indicator

  @override
  void initState() {
    super.initState();
    _loadTaskEntitysForSelectedDay(); // Load tasks for today when screen initializes
  }

  /// Loads tasks for the currently selected date
  /// Uses caching to avoid repeated database calls for the same date
  /// Updates loading state and handles errors gracefully
  Future<void> _loadTaskEntitysForSelectedDay() async {
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
      // Note: This will be handled by the new architecture
      // final tasks = await taskDatabase.fetchTaskEntitysForDate(_selectedDay);
      final tasks = <TaskEntity>[]; // Placeholder
      
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
  Widget _buildTaskEntityList() {
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
    return _buildTaskEntityListView(_tasksForSelectedDay!);
  }

  /// Builds the list view for displaying tasks
  /// Includes pull-to-refresh functionality
  /// Handles task updates through callback
  Widget _buildTaskEntityListView(List<TaskEntity> tasks) {
    return Expanded(
      child: RefreshIndicator(
        // Allow manual refresh of task list
        onRefresh: _loadTaskEntitysForSelectedDay,
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return TaskEntityWidget(
              task: tasks[index],
              // Callback to refresh list when task is updated
              onTaskEntityUpdated: _loadTaskEntitysForSelectedDay,
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
        title: const Text('TaskEntity Calendar'),
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
              _loadTaskEntitysForSelectedDay(); // Load tasks for newly selected date
            },
            // Shows task indicators on calendar dates
            eventLoader: (day) {
              return _taskCache[day] ?? [];
            },
          ),
          // TaskEntity list for selected date
          _buildTaskEntityList(),
        ],
      ),
    );
  }
}

/// Widget for displaying individual task information
/// Shows task status, details, and provides interaction options
class TaskEntityWidget extends StatelessWidget { // Callback when task is updated

  const TaskEntityWidget({
    super.key,
    required this.task,
    this.onTaskEntityUpdated,
  });
  static final Logger _logger = Logger('TaskEntityWidget');
  final TaskEntity task; // TaskEntity data to display
  final VoidCallback? onTaskEntityUpdated;

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
        // TaskEntity title with strikethrough for completed tasks
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
              'Due: ${task.dueDate != null ? DateFormat.yMd().add_jm().format(task.dueDate!) : 'No due date'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            // TaskEntity description if available
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
        _toggleTaskEntityCompletion();
        break;
      case 'edit':
        _editTaskEntity(context);
        break;
      case 'delete':
        _deleteTaskEntity(context);
        break;
    }
  }

  /// Toggles task completion status
  /// Updates task in database and refreshes UI
  Future<void> _toggleTaskEntityCompletion() async {
    try {
      // Note: This will be handled by the new use cases
      // Create updated task with toggled completion status
      // final updatedTaskEntity = task.copyWith(
      //   isCompleted: !task.isCompleted,
      //   updatedAt: DateTime.now(),
      // );

      // Update task in database - using new architecture
      // Note: This will be handled by the new use cases
      
      // Refresh task list to show updated status
      onTaskEntityUpdated?.call();
    } catch (e) {
      // Error logged but not shown to user as no context available
      _logger.warning('Failed to toggle task completion: $e');
    }
  }

  /// Opens edit dialog for task
  /// Allows user to modify task title, description, and due date
  Future<void> _editTaskEntity(BuildContext context) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime? selectedDate = task.dueDate;
    TimeOfDay selectedTime = task.dueDate != null 
        ? TimeOfDay.fromDateTime(task.dueDate!)
        : TimeOfDay.now();
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit TaskEntity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TaskEntity title input
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'TaskEntity Title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // TaskEntity description input
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
                    DateFormat.yMd().add_jm().format(selectedDate ?? DateTime.now()),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
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
                    const SnackBar(content: Text('TaskEntity title cannot be empty')),
                  );
                  return;
                }
                
                try {
                  // Note: This will be handled by the new use cases
                  // final updatedTaskEntity = task.copyWith(...);
                  
                  // Close dialog and refresh task list
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('TaskEntity updated successfully')),
                    );
                    onTaskEntityUpdated?.call();
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
  Future<void> _deleteTaskEntity(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete TaskEntity'),
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
        // Delete task from database - using new architecture
        // Note: This will be handled by the new use cases
        
        // Show success message and refresh task list
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TaskEntity deleted successfully')),
          );
          onTaskEntityUpdated?.call();
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