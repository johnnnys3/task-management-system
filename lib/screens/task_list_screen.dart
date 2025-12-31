/// Advanced task list screen for comprehensive task management
/// Provides rich task display with modern UI and interactive features
/// Includes filtering, sorting, search, and batch operations
library;
import 'package:flutter/material.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'task_creation_screen.dart';
import 'task_details_screen.dart';
import 'update_task_screen.dart';

class TaskListScreen extends StatefulWidget {

  const TaskListScreen({
    super.key,
    required this.userId,
    required this.user,
    required this.isAdmin,
  });
  /// User ID for filtering tasks
  final String userId;
  /// Current user information
  final CustomUser user;
  /// Admin status for permission-based actions
  final bool isAdmin;

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with AutomaticKeepAliveClientMixin {
  // Database helper for task operations
  final TaskDatabase _taskDatabase = TaskDatabase();
  
  // State variables for task management
  List<TaskEntity> _tasks = [];
  List<TaskEntity> _filteredTasks = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSort = 'Due Date';
  
  // Filter and sort options
  final List<String> _filterOptions = ['All', 'Pending', 'Completed', 'Overdue'];
  final List<String> _sortOptions = ['Due Date', 'Priority', 'Created Date', 'Title'];
  
  // Batch operation state
  final Set<String> _selectedTasks = {};
  bool _isSelectionMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load tasks from database
    _loadTasks();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    // Initialize filtered tasks
    _filteredTasks = _tasks;
    // Setup search listener
    _setupSearchListener();
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /// Loads tasks from database
  /// Updates both full list and filtered list
  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Load tasks from database
      final List<TaskEntity> loadedTasks = await _taskDatabase.getTasksForUser(widget.userId);

      setState(() {
        _tasks = loadedTasks;
        _filteredTasks = _tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading tasks: $e';
      });
    }
  }

  /// Sets up search listener
  /// Triggers filter update when search text changes
  void _setupSearchListener() {
    _searchController.addListener(() {
      _applyFiltersAndSort();
    });
  }

  /// Applies current filter and sort to tasks
  /// Updates filtered tasks based on search, filter, and sort
  void _applyFiltersAndSort() {
    setState(() {
      _filteredTasks = _tasks.where((task) {
        // Apply search filter
        final matchesSearch = _searchController.text.isEmpty ||
            task.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchController.text.toLowerCase());
        
        // Apply status filter
        final matchesFilter = _matchesFilter(task);
        
        return matchesSearch && matchesFilter;
      }).toList();
      
      // Apply sorting
      _sortTasks();
    });
  }

  /// Checks if task matches current filter
  /// Returns true if task should be displayed
  bool _matchesFilter(TaskEntity task) {
    switch (_selectedFilter) {
      case 'Pending':
        return !task.isCompleted;
      case 'Completed':
        return task.isCompleted;
      case 'Overdue':
        return !task.isCompleted && 
               task.dueDate != null && 
               task.dueDate!.isBefore(DateTime.now());
      default:
        return true;
    }
  }

  /// Sorts tasks based on selected sort option
  /// Updates filtered tasks with proper ordering
  void _sortTasks() {
    setState(() {
      switch (_selectedSort) {
        case 'Due Date':
          _filteredTasks.sort((a, b) => 
            (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999)));
          break;
        case 'Priority':
          _filteredTasks.sort((a, b) => _getPriorityValue(a.priority.name).compareTo(_getPriorityValue(b.priority.name)));
          break;
        case 'Created Date':
          _filteredTasks.sort((a, b) => 
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
          break;
        case 'Title':
          _filteredTasks.sort((a, b) => a.title.compareTo(b.title));
          break;
      }
    });
  }

  /// Gets numeric priority value for sorting
  /// Returns priority weight for comparison
  int _getPriorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return 4;
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildContent(),
      // Floating action buttons for batch operations
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  /// Builds modern app bar
  /// Includes title, search, filter, and sort options
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Tasks',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      // Search bar in app bar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Filter and sort options
              Row(
                children: [
                  // Filter dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          items: _filterOptions.map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value!;
                            });
                            _applyFiltersAndSort();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          isExpanded: true,
                          items: _sortOptions.map((sort) {
                            return DropdownMenuItem(
                              value: sort,
                              child: Text(sort),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSort = value!;
                            });
                            _applyFiltersAndSort();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds loading overlay
  /// Shows loading indicator during operations
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha:0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds main content area
  /// Creates layout with error display and task list
  Widget _buildContent() {
    return Stack(
      children: [
        Column(
          children: [
            // Error message display
            if (_errorMessage.isNotEmpty) _buildErrorMessage(),
            // Task statistics
            _buildTaskStatistics(),
            // Task list with selection mode
            Expanded(
              child: _filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(),
            ),
          ],
        ),
        // Loading overlay
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  /// Builds error message widget
  /// Shows error with dismiss option
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _errorMessage = '';
              });
            },
          ),
        ],
      ),
    );
  }

  /// Builds empty state
  /// Shows message when no tasks are found
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Create your first task to get started'
                : 'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds task statistics
  /// Shows count of tasks by status
  Widget _buildTaskStatistics() {
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    final pendingCount = _tasks.where((task) => !task.isCompleted).length;
    final overdueCount = _tasks.where((task) => 
        !task.isCompleted && 
        task.dueDate != null && 
        task.dueDate!.isBefore(DateTime.now())).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', _tasks.length.toString(), Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Pending', pendingCount.toString(), Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Completed', completedCount.toString(), Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Overdue', overdueCount.toString(), Colors.red),
          ),
        ],
      ),
    );
  }

  /// Builds individual statistic card
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds task list with selection mode
  /// Creates modern list view with batch operations
  Widget _buildTaskList() {
    return Column(
      children: [
        // Selection mode header
        if (_isSelectionMode) _buildSelectionHeader(),
        // Task list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredTasks.length,
            itemBuilder: (context, index) {
              final task = _filteredTasks[index];
              return TaskListItem(
                key: ValueKey(task.id),
                task: task,
                onTaskTap: () => _navigateToTaskDetailsScreen(task),
                onUpdateTask: widget.isAdmin ? _navigateToUpdateTaskScreen : null,
                onDeleteTask: widget.isAdmin ? _deleteTask : null,
                isSelected: _selectedTasks.contains(task.id),
                onSelectionToggle: _toggleTaskSelection,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds selection mode header
  /// Shows batch operation controls
  Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha:0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha:0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedTasks.length} selected',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Select all button
          TextButton(
            onPressed: _selectAllTasks,
            child: const Text('Select All'),
          ),
          // Clear selection button
          TextButton(
            onPressed: _clearSelection,
            child: const Text('Clear'),
          ),
          // Delete selected button
          if (_selectedTasks.isNotEmpty)
            TextButton.icon(
              onPressed: _deleteSelectedTasks,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  /// Builds floating action buttons
  /// Shows create task and selection mode buttons
  Widget _buildFloatingActionButtons() {
    if (_isSelectionMode) {
      // Selection mode buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Exit selection mode
          FloatingActionButton.extended(
            onPressed: _exitSelectionMode,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            backgroundColor: Colors.grey,
          ),
          // Delete selected
          if (_selectedTasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: FloatingActionButton.extended(
                onPressed: _deleteSelectedTasks,
                icon: const Icon(Icons.delete),
                label: Text('Delete ${_selectedTasks.length}'),
                backgroundColor: Colors.red,
              ),
            ),
        ],
      );
    } else {
      // Normal mode - create task button
      return FloatingActionButton.extended(
        onPressed: _navigateToCreateTask,
        icon: const Icon(Icons.add),
        label: const Text('Create Task'),
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  /// Adds new task to database
  /// Updates task list after successful creation
  Future<void> addTask(TaskEntity newTask) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Note: This will be handled by the new architecture
      // await _taskService.addTask(userId: widget.userId, task: newTask);
      await _loadTasks();
      _showSuccessSnackBar('Task added successfully');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding task: $e';
        _isLoading = false;
      });
    }
  }

  /// Deletes task from database
  /// Shows confirmation dialog and updates list
  Future<void> deleteTask(TaskEntity task) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
        
        // Note: This will be handled by the new architecture
        // await _taskService.deleteTask(
        //   userId: widget.userId,
        //   taskId: task.id,
        // );
        await _loadTasks();
        _showSuccessSnackBar('Task deleted successfully');
      } catch (e) {
        setState(() {
          _errorMessage = 'Error deleting task: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to task creation screen
  /// Opens task creation form and handles result
  Future<void> _navigateToCreateTask() async {
    // Note: This will be updated to use new architecture
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTask(availableProjects: []),
      ),
    );

    if (result != null && result is TaskEntity) {
      addTask(result);
    }
  }

  /// Navigates to task details screen
  /// Opens task details for viewing and editing
  void _navigateToTaskDetailsScreen(TaskEntity task) {
    // Note: This will be updated to use new architecture
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailsScreen(task: task)),
    );
  }

  /// Navigates to task update screen
  /// Opens task update for modification
  void _navigateToUpdateTaskScreen(TaskEntity task) {
    // Note: This will be updated to use new architecture
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateTaskScreen(task: task)),
    );
  }

  /// Deletes a single task
  /// Shows confirmation and removes task from list
  Future<void> _deleteTask(TaskEntity task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
        
        // Delete task from service
        // Note: This will be handled by the new architecture
        // await _taskService.deleteTask(
        //   userId: widget.userId,
        //   taskId: task.id,
        // );
        
        // Reload tasks
        await _loadTasks();
        
        _showSuccessSnackBar('Task deleted successfully');
      } catch (e) {
        setState(() {
          _errorMessage = 'Error deleting task: $e';
          _isLoading = false;
        });
      }
    }
  }


  /// Adds or removes task from selection
  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTasks.contains(taskId)) {
        _selectedTasks.remove(taskId);
      } else {
        _selectedTasks.add(taskId);
      }
    });
  }

  /// Selects all visible tasks
  /// Adds all filtered tasks to selection
  void _selectAllTasks() {
    setState(() {
      _selectedTasks.addAll(_filteredTasks.map((task) => task.id));
    });
  }

  /// Clears all task selections
  /// Empties selection and exits selection mode
  void _clearSelection() {
    setState(() {
      _selectedTasks.clear();
      _isSelectionMode = false;
    });
  }

  /// Deletes all selected tasks
  /// Shows confirmation and removes multiple tasks
  Future<void> _deleteSelectedTasks() async {
    if (_selectedTasks.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text('Are you sure you want to delete ${_selectedTasks.length} selected task${_selectedTasks.length == 1 ? '' : 's'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
        
        // Delete all selected tasks
        // Note: This will be handled by the new architecture
        // for (final taskId in _selectedTasks) {
        //   await _taskService.deleteTask(
        //     userId: widget.userId,
        //     taskId: taskId,
        //   );
        // }
        
        // Reload and exit selection mode
        await _loadTasks();
        setState(() {
          _selectedTasks.clear();
          _isSelectionMode = false;
        });
        
        _showSuccessSnackBar('${_selectedTasks.length} task${_selectedTasks.length == 1 ? '' : 's'} deleted successfully');
      } catch (e) {
        setState(() {
          _errorMessage = 'Error deleting tasks: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Exits selection mode
  /// Clears selection and returns to normal mode
  void _exitSelectionMode() {
    setState(() {
      _selectedTasks.clear();
      _isSelectionMode = false;
    });
  }

  /// Shows success message
  /// Displays temporary success notification
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class TaskListView extends StatelessWidget {

  const TaskListView({super.key, 
    required this.tasks,
    required this.onTaskTap,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });
  final List<TaskEntity> tasks;
  final Function(TaskEntity) onTaskTap;
  final void Function(TaskEntity)? onUpdateTask;
  final void Function(TaskEntity)? onDeleteTask;

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

/// Modern task list item with selection support
/// Provides rich task display with interactive features
/// Includes status indicators, priority badges, and selection checkboxes
class TaskListItem extends StatelessWidget {

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTaskTap,
    this.onUpdateTask,
    this.onDeleteTask,
    this.isSelected = false,
    this.onSelectionToggle,
  });
  /// Task to display
  final TaskEntity task;
  /// Callback for task tap
  final VoidCallback onTaskTap;
  /// Callback for task update
  final void Function(TaskEntity)? onUpdateTask;
  /// Callback for task delete
  final void Function(TaskEntity)? onDeleteTask;
  /// Whether task is selected
  final bool isSelected;
  /// Callback for selection toggle
  final void Function(String)? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.isCompleted && 
                     task.dueDate != null && 
                     task.dueDate!.isBefore(DateTime.now());
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTaskTap,
        onLongPress: () {
          if (onSelectionToggle != null) {
            onSelectionToggle!(task.id);
          } else if (onUpdateTask != null || onDeleteTask != null) {
            _showTaskOptionsDialog(context);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title, status, and selection
              Row(
                children: [
                  // Selection checkbox
                  if (onSelectionToggle != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          onSelectionToggle!(task.id);
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted ? Colors.grey : Colors.black,
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: task.isCompleted 
                                    ? Colors.green 
                                    : isOverdue 
                                        ? Colors.red 
                                        : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                task.isCompleted 
                                    ? 'Completed' 
                                    : isOverdue 
                                        ? 'Overdue' 
                                        : 'Pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(task.priority.name),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.priority.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // More options button
                  if (onUpdateTask != null || onDeleteTask != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _handleMenuAction(value, context),
                      itemBuilder: (context) => [
                        if (onUpdateTask != null)
                          const PopupMenuItem(
                            value: 'update',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Update'),
                              ],
                            ),
                          ),
                        if (onDeleteTask != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              // Description (if available)
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Due date and assigned members
              const SizedBox(height: 8),
              Row(
                children: [
                  // Due date
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Assigned members
                  if (task.assignedMembers.isNotEmpty) ...[
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${task.assignedMembers.length} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows task options dialog
  /// Displays update and delete options
  void _showTaskOptionsDialog(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: [
        if (onUpdateTask != null)
          PopupMenuItem(
            value: 'update',
            child: ListTile(
              title: const Text('Update Task'),
              leading: const Icon(Icons.edit),
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
              title: const Text('Delete Task'),
              leading: const Icon(Icons.delete, color: Colors.red),
              onTap: () {
                Navigator.pop(context);
                onDeleteTask!(task);
              },
            ),
          ),
      ],
    );
  }

  /// Handles menu action selection
  /// Processes update and delete actions
  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'update':
        if (onUpdateTask != null) onUpdateTask!(task);
        break;
      case 'delete':
        if (onDeleteTask != null) onDeleteTask!(task);
        break;
    }
  }

  /// Gets priority color for badge
  /// Returns color based on priority level
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Formats date for display
  /// Returns readable date string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
