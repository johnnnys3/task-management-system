/// Reporting screen for comprehensive task analytics and insights
/// Provides visual charts, statistics, and performance metrics
/// Includes real-time data updates and export functionality
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/domain/entities/task_entity.dart';

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  _ReportingScreenState createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  // State variables for reporting data
  List<TaskEntity> tasks = []; // All tasks
  bool _isLoading = true; // Loading state
  String _errorMessage = ''; // Error message for user feedback

  
  // Statistics variables
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _overdueTasks = 0;
  double _completionRate = 0.0;
  
  // Note: Database will be handled by the new architecture

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  /// Fetches tasks from database with error handling
  /// Updates statistics and handles errors gracefully
  Future<void> _fetchTasks() async {
    try {
      // Note: This will be handled by the new architecture
      // final fetchedTasks = await TaskDatabase().fetchTasks();
      final fetchedTasks = <TaskEntity>[]; // Placeholder
      
      if (mounted) {
        setState(() {
          tasks = fetchedTasks;
          _calculateStatistics();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch tasks: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Calculates comprehensive statistics from task data
  /// Updates all metric variables with current values
  void _calculateStatistics() {
    final now = DateTime.now();
    
    _totalTasks = tasks.length;
    _completedTasks = tasks.where((task) => task.isCompleted).length;
    _pendingTasks = tasks.where((task) => !task.isCompleted).length;
    _overdueTasks = tasks.where((task) =>
      !task.isCompleted &&
      (task.dueDate?.isBefore(now) ?? false)
    ).length;
    
    _completionRate = _totalTasks > 0 
        ? (_completedTasks / _totalTasks) * 100 
        : 0.0;
  }

  /// Builds comprehensive reporting interface
  /// Creates modern layout with charts, statistics, and analytics
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      // Modern app bar with refresh and export
      appBar: _buildAppBar(context),
      // Main content with loading/error states
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
    );
  }

  /// Builds modern app bar with actions
  /// Includes title, refresh, and export options
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Task Analytics',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      actions: [
        // Period filter dropdown
        PopupMenuButton<String>(
          icon: const Icon(Icons.date_range, color: Colors.white),
          tooltip: 'Filter by Period',
          onSelected: (String period) {
            setState(() {
              _calculateStatistics();
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'All Time',
              child: Text('All Time'),
            ),
            const PopupMenuItem(
              value: 'Today',
              child: Text('Today'),
            ),
            const PopupMenuItem(
              value: 'This Week',
              child: Text('This Week'),
            ),
            const PopupMenuItem(
              value: 'This Month',
              child: Text('This Month'),
            ),
            const PopupMenuItem(
              value: 'This Year',
              child: Text('This Year'),
            ),
          ],
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh Data',
          onPressed: _refreshData,
        ),
      ],
    );
  }

  /// Builds loading widget with modern styling
  /// Shows centered loading indicator with message
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds main content area
  /// Shows analytics dashboard or error state
  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }
    
    if (tasks.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary cards
            _buildSummaryCards(),
            const SizedBox(height: 20),
            // Progress chart
            _buildProgressChart(),
            const SizedBox(height: 20),
            // Task breakdown
            _buildTaskBreakdown(),
            const SizedBox(height: 20),
            // Recent activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  /// Builds summary statistics cards
  /// Displays key metrics in a grid layout
  Widget _buildSummaryCards() {
    return Row(
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
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
                    color: Colors.white.withValues(alpha:0.2),
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
                  '$_completedTasks',
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
                  color: Colors.black.withValues(alpha:0.05),
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
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
                  '${tasks.where((t) => !t.isCompleted).length}',
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
                  color: Colors.black.withValues(alpha:0.05),
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
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
                  '$_pendingTasks',
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
    );
  }


  /// Builds progress chart section
  /// Shows completion rate with visual indicator
  Widget _buildProgressChart() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Rate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_completionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _completionRate >= 75 
                            ? Colors.green 
                            : _completionRate >= 50 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _completionRate / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _completionRate >= 75 
                        ? Colors.green 
                        : _completionRate >= 50 
                            ? Colors.orange 
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds task breakdown section
  /// Shows detailed task distribution
  Widget _buildTaskBreakdown() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Task list items
            _buildTaskListItem(
              'Completed Tasks',
              _completedTasks,
              _totalTasks,
              Colors.green,
              Icons.check_circle,
            ),
            const SizedBox(height: 12),
            _buildTaskListItem(
              'Pending Tasks',
              _pendingTasks,
              _totalTasks,
              Colors.orange,
              Icons.pending,
            ),
            const SizedBox(height: 12),
            _buildTaskListItem(
              'Overdue Tasks',
              _overdueTasks,
              _totalTasks,
              Colors.red,
              Icons.warning,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual task list item
  /// Creates styled list item with progress bar
  Widget _buildTaskListItem(String title, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$count / $total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Builds recent activity section
  /// Shows recent tasks with status
  Widget _buildRecentActivity() {
    final recentTasks = tasks.take(5).toList();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (recentTasks.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: recentTasks.map((task) {
                  return _buildRecentTaskItem(task);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds individual recent task item
  /// Creates styled item for recent tasks
  Widget _buildRecentTaskItem(TaskEntity task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: task.isCompleted ? Colors.green : Colors.orange,
            child: Icon(
              task.isCompleted ? Icons.check : Icons.pending,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM dd').format(task.dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.dueDate!.isBefore(DateTime.now()) 
                          ? Colors.red 
                          : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds error state widget
  /// Shows error message with retry option
  Widget _buildErrorWidget() {
    return Center(
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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds empty state widget
  /// Shows message when no tasks are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start creating tasks to see analytics here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Refreshes data from database
  /// Reloads tasks and recalculates statistics
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _fetchTasks();
  }
}
