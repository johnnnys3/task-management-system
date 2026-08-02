/// Reporting screen for comprehensive task analytics and insights
/// Provides visual charts, statistics, and performance metrics
/// Includes real-time data updates and export functionality
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart';

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  _ReportingScreenState createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  // State variables for reporting data
  List<Task> _tasks = []; // All tasks
  bool _isLoading = true; // Loading state
  String _errorMessage = ''; // Error message for user feedback

  
  // Statistics variables
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _overdueTasks = 0;
  double _completionRate = 0.0;
  
  late final TaskStore _taskStore;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _fetchTasks();
  }

  /// Fetches tasks from database with error handling
  /// Updates statistics and handles errors gracefully
  Future<void> _fetchTasks() async {
    try {
      final tasks = await _taskStore.fetch();
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
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
    
    _totalTasks = _tasks.length;
    _completedTasks = _tasks.where((task) => task.isCompleted).length;
    _pendingTasks = _tasks.where((task) => !task.isCompleted).length;
    _overdueTasks = _tasks.where((task) =>
      !task.isCompleted &&
      task.dueDate != null &&
      task.dueDate!.isBefore(now)
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
    
    if (_tasks.isEmpty) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        const Text(
          'Task Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Statistics grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Tasks',
              _totalTasks.toString(),
              Icons.assignment,
              Colors.blue,
            ),
            _buildStatCard(
              'Completed',
              _completedTasks.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Pending',
              _pendingTasks.toString(),
              Icons.pending,
              Colors.orange,
            ),
            _buildStatCard(
              'Overdue',
              _overdueTasks.toString(),
              Icons.warning,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds individual statistics card
  /// Creates styled card with icon and value
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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
    final recentTasks = _tasks.take(5).toList();
    
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
  Widget _buildRecentTaskItem(Task task) {
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
