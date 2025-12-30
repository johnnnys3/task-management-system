import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/screens/notification_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class TaskStatsPage extends StatefulWidget {
  final CustomUser? user;
  
  const TaskStatsPage({super.key, this.user});

  @override
  _TaskStatsPageState createState() => _TaskStatsPageState();
}

class _TaskStatsPageState extends State<TaskStatsPage> {
  List<Task>? tasks;
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedTimeFilter = 'Weekly';

  @override
  void initState() {
    super.initState();
    _getTasks();
  }

  Future<void> _getTasks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final fetchedTasks = await TaskDatabase().fetchTasks();
      if (mounted) {
        setState(() {
          tasks = fetchedTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tasks: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<Task> _getTodaysTasks() {
    if (tasks == null) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks!.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return taskDate.isAtSameMomentAs(today);
    }).toList();
  }

  int _getTasksDueToday() {
    return _getTodaysTasks().length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _getTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final completedCount = tasks?.where((t) => t.isCompleted).length ?? 0;
    final inProgressCount = tasks?.where((t) => !t.isCompleted && t.status.value == 'in_progress').length ?? 0;
    final pendingCount = tasks?.where((t) => !t.isCompleted).length ?? 0;
    final todaysTasks = _getTodaysTasks();
    final userName = widget.user?.name.split(' ').first ?? 'Alex';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _getTasks,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(userName),
                const SizedBox(height: 24),
                
                // Summary Cards
                _buildSummaryCards(completedCount, inProgressCount, pendingCount),
                const SizedBox(height: 24),
                
                // Productivity Section
                _buildProductivitySection(),
                const SizedBox(height: 24),
                
                // Today's Tasks Section
                _buildTodaysTasksSection(todaysTasks),
                const SizedBox(height: 24),
                
                // Recent Activity Section
                _buildRecentActivitySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      children: [
        // Profile Picture
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting and Task Count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, $userName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You have ${_getTasksDueToday()} tasks due today.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Notification Bell
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.grey[800],
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards(int completed, int inProgress, int pending) {
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
                  '$completed',
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
                  '$inProgress',
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
                  '$pending',
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

  Widget _buildProductivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Productivity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            // Time Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<String>(
                value: _selectedTimeFilter,
                underline: const SizedBox(),
                isDense: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeFilter = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Chart Area
        Container(
          height: 200,
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
          child: _buildProductivityChart(),
        ),
      ],
    );
  }

  Widget _buildProductivityChart() {
    // Simple bar chart for productivity
    final weekData = [20, 35, 45, 30, 50, 40, 35]; // Sample data for M T W T F S S
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: weekData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTodaysTasksSection(List<Task> todaysTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Tasks",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full task list
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...todaysTasks.take(3).map((task) => _buildTaskItem(task)),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
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
      margin: const EdgeInsets.only(bottom: 12),
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

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        // Activity Item 1
        _buildActivityItem(
          'Project "Mobile App" updated',
          '2 hours ago',
          Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        // Activity Item 2
        _buildActivityItem(
          'Comment left on Task #42',
          '4 hours ago',
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, Color dotColor) {
    return Container(
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
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
