/// Advanced task list screen for comprehensive task management
/// Provides rich task display with modern UI and interactive features
/// Includes filtering, sorting, search, and batch operations
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/models/task.dart' as TaskModel;
import 'package:task_management/screens/task_details_screen.dart';
import 'package:task_management/screens/task_creation_screen.dart';
import 'package:task_management/screens/update_task_screen.dart';
import 'package:task_management/service/task_service.dart';

class TaskListScreen extends StatefulWidget {
  /// User ID for filtering tasks
  final String userId;
  /// Current user information
  final CustomUser user;
  /// Admin status for permission-based actions
  final bool isAdmin;
  /// Initial list of tasks
  final List<TaskModel.Task> tasks;

  const TaskListScreen({
    super.key,
    required this.userId,
    required this.user,
    required this.isAdmin,
    required this.tasks,
  });

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with AutomaticKeepAliveClientMixin {
  // State variables for task management
  List<TaskModel.Task> _tasks = [];
  List<TaskModel.Task> _filteredTasks = [];
  final TaskService _taskService = TaskService();
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
    // Initialize tasks from passed list
    _tasks = widget.tasks;
    _filteredTasks = _tasks;
    // Load tasks from database and setup listeners
    _loadTasks();
    _setupSearchListener();
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /// Loads tasks from database with error handling
  /// Updates both full list and filtered list
  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Fetch tasks using service
      final List<TaskModel.Task> loadedTasks =
          (await _taskService.getTasks(userId: widget.userId)).cast<TaskModel.Task>();

      setState(() {
        _tasks = loadedTasks;
        _filteredTasks = loadedTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading tasks: $e';
      });
    }
  }

  /// Sets up search listener for real-time filtering
  /// Updates filtered tasks as user types
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
  bool _matchesFilter(TaskModel.Task task) {
    switch (_selectedFilter) {
      case 'Pending':
        return !task.isCompleted;
      case 'Completed':
        return task.isCompleted;
      case 'Overdue':
        return !task.isCompleted && 
               task.hasDueDate && 
               task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
      default:
        return true; // 'All' filter
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
      backgroundColor: const Color(0xFFF8F9FF),
      // Modern app bar with search and filters
      appBar: _buildAppBar(),
      // Main content with loading overlay
      body: Stack(
        children: [
          // Content with search, filters, and task list
          _buildContent(),
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
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
      automaticallyImplyLeading: false,
      // Search bar in app bar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).primaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Filter and sort row
              Row(
                children: [
                  // Filter dropdown
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
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
                  const SizedBox(width: 12),
                  // Sort dropdown
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSort,
                        decoration: InputDecoration(
                          labelText: 'Sort',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds main content area
  /// Creates layout with error display and task list
  Widget _buildContent() {
    return Column(
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

  /// Builds loading overlay
  /// Shows loading indicator during operations
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading tasks...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds task statistics
  /// Shows count of tasks by status
  Widget _buildTaskStatistics() {
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    final inProgressCount = _tasks.where((task) => !task.isCompleted && task.status.value == 'in_progress').length;
    final pendingCount = _tasks.where((task) => !task.isCompleted).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Completed Card (Purple)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$completedCount',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // In Progress Card (White)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$inProgressCount',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In Progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Pending Card (White)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pending_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$pendingCount',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Builds empty state widget
  /// Shows message when no tasks match filters
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
                ? 'No tasks found matching "${_searchController.text}"'
                : 'No tasks found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create a new task',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
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
        mainAxisSize: MainAxisSize.min,
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
  Future<void> addTask(TaskModel.Task newTask) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      await _taskService.addTask(userId: widget.userId, task: newTask);
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
  Future<void> deleteTask(TaskModel.Task task) async {
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
        
        await _taskService.deleteTask(
          userId: widget.userId,
          taskId: task.id,
        );
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
  /// Handles task creation and result
  Future<void> _navigateToCreateTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTask(availableProjects: []),
      ),
    );

    if (result != null && result is TaskModel.Task) {
      addTask(result);
    }
  }

  /// Navigates to task details screen
  /// Opens task details for viewing and editing
  void _navigateToTaskDetailsScreen(TaskModel.Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailsScreen(task: task)),
    );
  }

  /// Navigates to task update screen
  /// Opens task update for modification
  void _navigateToUpdateTaskScreen(TaskModel.Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateTaskScreen(task: task)),
    );
  }

  /// Deletes a single task
  /// Shows confirmation and removes task from list
  Future<void> _deleteTask(TaskModel.Task task) async {
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
        await _taskService.deleteTask(
          userId: widget.userId,
          taskId: task.id,
        );
        
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


  /// Toggles individual task selection
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
        for (final taskId in _selectedTasks) {
          await _taskService.deleteTask(
            userId: widget.userId,
            taskId: taskId,
          );
        }
        
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
  /// Returns to normal task list mode
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
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
  final List<TaskModel.Task> tasks;
  final Function(TaskModel.Task) onTaskTap;
  final void Function(TaskModel.Task)? onUpdateTask;
  final void Function(TaskModel.Task)? onDeleteTask;

  const TaskListView({super.key, 
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

/// Modern task list item with selection support
/// Provides rich task display with interactive features
/// Includes status indicators, priority badges, and selection checkboxes
class TaskListItem extends StatelessWidget {
  /// Task to display
  final TaskModel.Task task;
  /// Callback for task tap
  final VoidCallback onTaskTap;
  /// Callback for task update
  final void Function(TaskModel.Task)? onUpdateTask;
  /// Callback for task delete
  final void Function(TaskModel.Task)? onDeleteTask;
  /// Whether task is selected
  final bool isSelected;
  /// Callback for selection toggle
  final void Function(String)? onSelectionToggle;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTaskTap,
    this.onUpdateTask,
    this.onDeleteTask,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.isCompleted && 
                     task.hasDueDate && 
                     task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    
    final timeStr = task.dueDate != null 
        ? DateFormat.jm().format(task.dueDate!)
        : 'No time';
    
    String statusLabel = 'PENDING';
    Color statusColor = Colors.blue;
    
    if (task.isCompleted) {
      statusLabel = 'DONE';
      statusColor = Colors.green;
    } else if (task.priority.value == 'urgent') {
      statusLabel = 'URGENT';
      statusColor = Colors.red;
    } else if (task.status.value == 'in_progress') {
      statusLabel = 'CALL';
      statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          task.isCompleted
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                )
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                ),
          const SizedBox(width: 16),
          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted ? Colors.grey : Colors.black87,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
  /// Returns formatted date string
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Modern error display component
/// Provides user-friendly error messages with retry option
class ErrorDisplay extends StatelessWidget {
  /// Error message to display
  final String message;
  /// Optional retry callback
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
