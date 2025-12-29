import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/models/task.dart';

/// Enumeration for task filtering options
/// Used to control which tasks are displayed in the list
enum TaskFilter { all, completed, pending, overdue }

/// Enumeration for task sorting options
/// Used to control the order of tasks in the list
enum TaskSort { dueDate, title, createdDate }

class TaskStatsPage extends StatefulWidget {
  const TaskStatsPage({super.key});

  @override
  _TaskStatsPageState createState() => _TaskStatsPageState();
}

class _TaskStatsPageState extends State<TaskStatsPage> {
  // State variables
  List<Task>? tasks; // All tasks loaded from database
  List<Task>? filteredTasks; // Tasks after applying search and filters
  bool _isLoading = true; // Loading state indicator
  String _errorMessage = ''; // Error message for database operations
  String _searchQuery = ''; // Current search query for filtering
  TaskFilter _currentFilter = TaskFilter.all; // Currently active filter
  TaskSort _currentSort = TaskSort.dueDate; // Currently active sorting option

  @override
  void initState() {
    super.initState();
    _getTasks(); // Load tasks when screen initializes
  }

  /// Loads all tasks from database
  /// Sets loading state and handles errors gracefully
  /// Updates filtered tasks after loading
  Future<void> _getTasks() async {
    // Prevent operation if widget is disposed
    if (!mounted) return;
    
    // Show loading state and clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch all tasks from database
      final fetchedTasks = await TaskDatabase().fetchTasks();
      if (mounted) {
        setState(() {
          tasks = fetchedTasks;
          _applyFiltersAndSort(); // Apply current filters and sort
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle any errors during database operations
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tasks: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Applies current search query, filter, and sort options to tasks
  /// Updates filteredTasks list with results
  /// Called whenever search, filter, or sort changes
  void _applyFiltersAndSort() {
    if (tasks == null) return;

    // Start with all tasks as base
    List<Task> result = List.from(tasks!);

    // Apply search filter if query exists
    if (_searchQuery.isNotEmpty) {
      result = result.where((task) =>
        task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (task.description.isNotEmpty && 
         task.description.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    // Apply status filter based on current selection
    switch (_currentFilter) {
      case TaskFilter.completed:
        result = result.where((task) => task.isCompleted).toList();
        break;
      case TaskFilter.pending:
        result = result.where((task) => !task.isCompleted).toList();
        break;
      case TaskFilter.overdue:
        result = result.where((task) => 
          !task.isCompleted && 
          task.dueDate != null &&
          task.dueDate!.isBefore(DateTime.now())
        ).toList();
        break;
      case TaskFilter.all:
        break; // Show all tasks
    }

    // Apply sorting based on current selection
    switch (_currentSort) {
      case TaskSort.dueDate:
        result.sort((a, b) {
          // Sort by due date, tasks without due dates go to end
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSort.title:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case TaskSort.createdDate:
        result.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return a.createdAt!.compareTo(b.createdAt!);
        });
        break;
    }

    // Update UI with filtered and sorted results
    setState(() {
      filteredTasks = result;
    });
  }

  /// Handles search query changes
  /// Updates search query state and reapplies filters
  /// Called whenever user types in search field
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort(); // Reapply all filters with new search
  }

  /// Handles filter selection changes
  /// Updates current filter and reapplies all filters
  /// Called when user selects different filter chip
  void _onFilterChanged(TaskFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    _applyFiltersAndSort(); // Reapply all filters with new selection
  }

  /// Handles sort selection changes
  /// Updates current sort option and reapplies sorting
  /// Called when user selects different sort option from menu
  void _onSortChanged(TaskSort sort) {
    setState(() {
      _currentSort = sort;
    });
    _applyFiltersAndSort(); // Reapply all filters with new sort
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<TaskSort>(
            icon: const Icon(Icons.sort),
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TaskSort.dueDate,
                child: Text('Sort by Due Date'),
              ),
              const PopupMenuItem(
                value: TaskSort.title,
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem(
                value: TaskSort.createdDate,
                child: Text('Sort by Created Date'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _getTasks,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }
    
    return Column(
      children: [
        _buildStatsCards(),
        _buildSearchAndFilter(),
        Expanded(
          child: _buildTaskList(),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text('Loading tasks...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _getTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (tasks == null) return const SizedBox.shrink();
    
    final totalTasks = tasks!.length;
    final completedTasks = tasks!.where((t) => t.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;
    final overdueTasks = tasks!.where((t) => 
      !t.isCompleted && 
      t.dueDate != null &&
      t.dueDate!.isBefore(DateTime.now())
    ).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Total', totalTasks.toString(), Icons.task_alt),
              const SizedBox(width: 8),
              _buildStatCard('Completed', completedTasks.toString(), Icons.check_circle),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('Pending', pendingTasks.toString(), Icons.pending),
              const SizedBox(width: 8),
              _buildStatCard('Overdue', overdueTasks.toString(), Icons.warning, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, [Color? color]) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: color ?? Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.toString().split('.').last),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _onFilterChanged(filter);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (filteredTasks == null || filteredTasks!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'No tasks found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              if (_searchQuery.isNotEmpty || _currentFilter != TaskFilter.all)
                Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _getTasks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredTasks!.length,
        itemBuilder: (context, index) {
          final task = filteredTasks![index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isOverdue = !task.isCompleted && 
                     task.dueDate != null && 
                     task.dueDate!.isBefore(DateTime.now());
    final isDueSoon = !task.isCompleted && 
                     task.dueDate != null && 
                     task.dueDate!.difference(DateTime.now()).inDays <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue 
            ? BorderSide(color: Colors.red.shade300, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleTaskTap(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: task.isCompleted 
                            ? Colors.grey 
                            : Colors.black87,
                      ),
                    ),
                  ),
                  _buildTaskStatusIndicator(task, isOverdue, isDueSoon),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (task.hasDueDate) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(task.dueDate),
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isOverdue ? FontWeight.w500 : null,
                      ),
                    ),
                  ],
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleTaskAction(task, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_complete',
                        child: Text(task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                      ),
                      const PopupMenuItem(
                        value: 'details',
                        child: Text('View Details'),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStatusIndicator(Task task, bool isOverdue, bool isDueSoon) {
    if (task.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Completed',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Overdue',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    if (isDueSoon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Due Soon',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Pending',
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';
    
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${DateFormat.jm().format(dueDate)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${DateFormat.jm().format(dueDate)}';
    } else if (difference.inDays == -1) {
      return 'Yesterday at ${DateFormat.jm().format(dueDate)}';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return 'In ${difference.inDays} days';
    } else if (difference.inDays < 0) {
      return '${difference.inDays.abs()} days overdue';
    } else {
      return DateFormat.yMd().add_jm().format(dueDate);
    }
  }

  void _handleTaskTap(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Status', task.isCompleted ? 'Completed' : 'Pending'),
                _buildDetailRow('Created', task.createdAt != null ? DateFormat.yMd().add_jm().format(task.createdAt!) : 'Unknown'),
                if (task.dueDate != null)
                  _buildDetailRow('Due Date', DateFormat.yMd().add_jm().format(task.dueDate!)),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(task.description),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleTaskAction(task, 'toggle_complete');
              },
              child: Text(task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleTaskAction(Task task, String action) async {
    try {
      switch (action) {
        case 'toggle_complete':
          // TODO: Implement task completion toggle
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(task.isCompleted 
                  ? 'Task marked as incomplete' 
                  : 'Task marked as complete'),
              duration: const Duration(seconds: 2),
            ),
          );
          await _getTasks(); // Refresh the list
          break;
        case 'details':
          _handleTaskTap(task);
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
