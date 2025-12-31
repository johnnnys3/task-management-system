import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/constants/app_constants.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/screens/notification_screen.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:fl_chart/fl_chart.dart';

class TaskEntityStatsPage extends StatefulWidget {
  
  const TaskEntityStatsPage({super.key, this.user, this.isAdmin = false});
  final CustomUser? user;
  final bool isAdmin;

  @override
  _TaskEntityStatsPageState createState() => _TaskEntityStatsPageState();
}

class _TaskEntityStatsPageState extends State<TaskEntityStatsPage> {
  final TaskDatabase _taskDatabase = TaskDatabase();
  List<TaskEntity>? tasks;
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedTimeFilter = 'Weekly';

  @override
  void initState() {
    super.initState();
    // Debug: Print admin status and user info
    print('Dashboard: User role = ${widget.user?.role}');
    print('Dashboard: isAdmin = ${widget.isAdmin}');
    print('Dashboard: User name = ${widget.user?.name}');
    print('Dashboard: User ID = ${widget.user?.uid}');
    _getTasks();
  }

  Future<void> _getTasks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load tasks based on user role
      List<TaskEntity> fetchedTasks;
      
      if (widget.isAdmin) {
        // Admin sees all tasks
        print('Dashboard: Loading all tasks for admin');
        fetchedTasks = await _taskDatabase.getAllTasks();
      } else {
        // Regular user sees only their assigned tasks
        print('Dashboard: Loading tasks for user: ${widget.user?.uid}');
        fetchedTasks = await _taskDatabase.getTasksForUser(widget.user?.uid ?? '');
      }
      
      print('Dashboard: Loaded ${fetchedTasks.length} tasks');
      
      // Debug: Print task details
      for (int i = 0; i < fetchedTasks.length; i++) {
        final task = fetchedTasks[i];
        print('Task $i: ${task.title} (assignedTo: ${task.assignedTo})');
      }
      
      // If no tasks found, create sample data for testing
      if (fetchedTasks.isEmpty) {
        print('Dashboard: No tasks found, creating sample data');
        fetchedTasks = _createSampleTasks();
        print('Dashboard: Created ${fetchedTasks.length} sample tasks');
      }
      
      print('Dashboard: Final task count: ${fetchedTasks.length}');
      
      if (mounted) {
        setState(() {
          tasks = fetchedTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard: Error loading tasks: $e');
      print('Dashboard: Error type: ${e.runtimeType}');
      
      // Check if it's a TaskDatabaseException
      if (e is TaskDatabaseException) {
        print('Dashboard: TaskDatabaseException details:');
        print('  - Message: ${(e as TaskDatabaseException).message}');
        print('  - Code: ${(e as TaskDatabaseException).code}');
        print('  - Original error: ${(e as TaskDatabaseException).originalError}');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading tasks: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Builds admin management section with admin-specific features
  Widget _buildAdminManagementSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Admin Management',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildAdminActionCard(
                  'User Management',
                  'Manage users and permissions',
                  Icons.people,
                  AppColors.primaryBlue,
                  () {
                    // Navigate to user management
                    print('Navigate to user management');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildAdminActionCard(
                  'System Settings',
                  'Configure system settings',
                  Icons.settings,
                  AppColors.primaryPurple,
                  () {
                    // Navigate to system settings
                    print('Navigate to system settings');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds admin action card for quick access to admin features
  Widget _buildAdminActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.title.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates sample tasks for testing when no tasks exist
  List<TaskEntity> _createSampleTasks() {
    final now = DateTime.now();
    return [
      TaskEntity(
        id: 'sample1',
        title: 'Sample Task 1',
        description: 'This is a sample task for testing',
        dueDate: now.add(const Duration(days: 1)),
        assignedTo: widget.user?.uid ?? 'user1',
        assignedMembers: [widget.user?.name ?? 'User'],
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: 'sample2',
        title: 'Sample Task 2',
        description: 'Another sample task',
        dueDate: now.add(const Duration(days: 2)),
        assignedTo: widget.user?.uid ?? 'user1',
        assignedMembers: [widget.user?.name ?? 'User'],
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: 'sample3',
        title: 'Completed Sample Task',
        description: 'A completed sample task',
        dueDate: now.subtract(const Duration(days: 1)),
        assignedTo: widget.user?.uid ?? 'user1',
        assignedMembers: [widget.user?.name ?? 'User'],
        status: TaskStatus.completed,
        priority: TaskPriority.low,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        isCompleted: true,
      ),
    ];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<TaskEntity> _getTodaysTaskEntitys() {
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
    return _getTodaysTaskEntitys().length;
  }

  @override
  Widget build(BuildContext context) {
    print('Dashboard: Building UI with ${tasks?.length ?? 0} tasks');
    print('Dashboard: Loading state: $_isLoading');
    print('Dashboard: Error state: $_errorMessage.isNotEmpty}');
    
    if (_isLoading) {
      print('Dashboard: Showing loading indicator');
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      print('Dashboard: Showing error: $_errorMessage');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
    final todaysTaskEntitys = _getTodaysTaskEntitys();
    final userName = widget.user?.name.split(' ').first ?? 'Alex';

    print('Dashboard: Task counts - Completed: $completedCount, In Progress: $inProgressCount, Pending: $pendingCount');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _getTasks,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(userName),
                const SizedBox(height: AppSpacing.sectionSpacing),
                
                // Summary Cards
                _buildSummaryCards(completedCount, inProgressCount, pendingCount),
                const SizedBox(height: AppSpacing.sectionSpacing),
                
                // Admin Management Section
                if (widget.isAdmin) _buildAdminManagementSection(),
                if (widget.isAdmin) const SizedBox(height: AppSpacing.sectionSpacing),
                
                // Productivity Section
                _buildProductivitySection(),
                // const SizedBox(height: AppSpacing.sectionSpacing),
                
                // Today's TaskEntitys Section
                _buildTodaysTaskEntitysSection(todaysTaskEntitys),
                const SizedBox(height: AppSpacing.sectionSpacing),
                
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.isAdmin 
                ? [AppColors.primaryPurple, AppColors.primaryBlue]
                : [AppColors.primaryBlue, AppColors.primaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppElevation.md,
          ),
          child: Center(
            child: Text(
              userName[0].toUpperCase(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Greeting and Task Count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, ${widget.isAdmin ? 'Admin' : userName}',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.isAdmin 
                  ? 'Managing all tasks and users'
                  : 'You have ${_getTasksDueToday()} tasks due today.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Admin Badge
        if (widget.isAdmin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        // Notification Bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
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
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
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
        // Completed Card (Primary Blue)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppElevation.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$completed',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Completed',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // In Progress Card (White)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppElevation.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$inProgress',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'In Progress',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Pending Card (White)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppElevation.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.pending_outlined,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$pending',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pending',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
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
            Text(
              'Productivity',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            // Time Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButton<String>(
                value: _selectedTimeFilter,
                underline: const SizedBox(),
                isDense: true,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryBlue,
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
        const SizedBox(height: AppSpacing.md),
        // Chart Area
        Container(
          height: 220,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppElevation.sm,
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
        barTouchData: const BarTouchData(enabled: false),
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
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
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
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: weekData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: AppColors.primaryBlue,
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xs),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTodaysTaskEntitysSection(List<TaskEntity> todaysTaskEntitys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's TaskEntitys",
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full task list
              },
              child: Text(
                'See All',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...todaysTaskEntitys.take(3).map((task) => _buildTaskEntityItem(task)),
      ],
    );
  }

  Widget _buildTaskEntityItem(TaskEntity task) {
    final timeStr = task.dueDate != null 
        ? DateFormat.jm().format(task.dueDate!)
        : 'No time';
    
    String statusLabel = 'PENDING';
    Color statusColor = AppColors.info;
    
    if (task.isCompleted) {
      statusLabel = 'DONE';
      statusColor = AppColors.success;
    } else if (task.priority.value == 'urgent') {
      statusLabel = 'URGENT';
      statusColor = AppColors.error;
    } else if (task.status.value == 'in_progress') {
      statusLabel = 'CALL';
      statusColor = AppColors.primaryBlue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppElevation.sm,
      ),
      child: Row(
        children: [
          // Checkbox
          task.isCompleted
              ? const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryBlue,
                  size: 28,
                )
              : Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderMedium,
                      width: 2,
                    ),
                  ),
                ),
          const SizedBox(width: AppSpacing.md),
          // TaskEntity Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted 
                        ? AppColors.textTertiary 
                        : AppColors.textPrimary,
                    decoration: task.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      timeStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              statusLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
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
        Text(
          'Recent Activity',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Activity Item 1
        _buildActivityItem(
          'Project "Mobile App" updated',
          '2 hours ago',
          AppColors.primaryBlue,
        ),
        const SizedBox(height: AppSpacing.md),
        // Activity Item 2
        _buildActivityItem(
          'Comment left on TaskEntity #42',
          '4 hours ago',
          AppColors.secondaryBlue,
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, Color dotColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppElevation.sm,
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  time,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
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
