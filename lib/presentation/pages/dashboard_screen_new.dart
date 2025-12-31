import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_management/constants/app_constants.dart';
import 'package:task_management/core/constants/app_strings.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/domain/entities/user_entity.dart';
import 'package:task_management/presentation/providers/task_providers.dart';
import 'package:task_management/screens/notification_screen.dart';
import 'package:fl_chart/fl_chart.dart';

/// New dashboard screen using Clean Architecture and Riverpod
class DashboardScreenNew extends ConsumerWidget {
  
  const DashboardScreenNew({super.key, this.user});
  final UserEntity? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysTasksAsync = ref.watch(todaysTasksProvider);
    final taskCountsAsync = ref.watch(taskCountsProvider);
    final tasksDueTodayCountAsync = ref.watch(tasksDueTodayCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(tasksProvider.notifier).refresh();
            await ref.read(todaysTasksProvider.notifier).refresh();
          },
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(context, user, tasksDueTodayCountAsync),
                const SizedBox(height: AppSpacing.sectionSpacing),
                
                // Summary Cards
                _buildSummaryCards(context, taskCountsAsync),
                const SizedBox(height: AppSpacing.sectionSpacing),
                
                // Productivity Section
                _buildProductivitySection(),
                const SizedBox(height: AppSpacing.sectionSpacing),
                
                // Today's Tasks Section
                _buildTodaysTasksSection(context, todaysTasksAsync),
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

  Widget _buildHeader(BuildContext context, UserEntity? user, AsyncValue<int> tasksDueTodayCountAsync) {
    final userName = user?.displayName.split(' ').first ?? 'Alex';
    
    return tasksDueTodayCountAsync.when(
      data: (count) => _buildHeaderContent(context, userName, count),
      loading: () => _buildHeaderContent(context, userName, 0),
      error: (error, stack) => _buildHeaderContent(context, userName, 0),
    );
  }

  Widget _buildHeaderContent(BuildContext context, String userName, int tasksDueTodayCount) {
    return Row(
      children: [
        // Profile Picture
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryPurple],
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
                '${_getGreeting()}, $userName',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You have $tasksDueTodayCount tasks due today.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  Widget _buildSummaryCards(BuildContext context, AsyncValue<Map<String, int>> taskCountsAsync) {
    return taskCountsAsync.when(
      data: (counts) => _buildSummaryCardsContent(counts),
      loading: () => _buildSummaryCardsLoading(),
      error: (error, stack) => _buildSummaryCardsError(),
    );
  }

  Widget _buildSummaryCardsContent(Map<String, int> counts) {
    final completed = counts['completed'] ?? 0;
    final inProgress = counts['in_progress'] ?? 0;
    final pending = counts['pending'] ?? 0;

    return Row(
      children: [
        // Completed Card (Primary Blue)
        Expanded(
          child: _buildSummaryCard(
            AppColors.primaryBlue,
            Icons.check_circle_outline,
            completed,
            AppStrings.completed,
            Colors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // In Progress Card (White)
        Expanded(
          child: _buildSummaryCard(
            AppColors.surfaceLight,
            Icons.access_time,
            inProgress,
            AppStrings.inProgress,
            AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Pending Card (White)
        Expanded(
          child: _buildSummaryCard(
            AppColors.surfaceLight,
            Icons.pending_outlined,
            pending,
            AppStrings.pending,
            AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Color backgroundColor, IconData icon, int count, String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
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
              color: backgroundColor == AppColors.primaryBlue 
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: backgroundColor == AppColors.primaryBlue ? Colors.white : AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$count',
            style: AppTextStyles.displaySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: backgroundColor == AppColors.primaryBlue ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardsLoading() {
    return Row(
      children: List.generate(3, (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index < 2 ? AppSpacing.md : 0),
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      )),
    );
  }

  Widget _buildSummaryCardsError() {
    return Row(
      children: List.generate(3, (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index < 2 ? AppSpacing.md : 0),
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Center(
            child: Icon(Icons.error_outline, color: AppColors.error),
          ),
        ),
      )),
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
              AppStrings.productivity,
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
                value: AppStrings.filterWeekly,
                underline: const SizedBox(),
                isDense: true,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryBlue,
                ),
                items: [AppStrings.filterDaily, AppStrings.filterWeekly, AppStrings.filterMonthly].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  // TODO: Implement time filter change
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
                const days = [AppStrings.monday, AppStrings.tuesday, AppStrings.wednesday, AppStrings.thursday, AppStrings.friday, AppStrings.saturday, AppStrings.sunday];
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

  Widget _buildTodaysTasksSection(BuildContext context, AsyncValue<List<TaskEntity>> todaysTasksAsync) {
    return todaysTasksAsync.when(
      data: (tasks) => _buildTodaysTasksContent(context, tasks),
      loading: () => _buildTodaysTasksLoading(),
      error: (error, stack) => _buildTodaysTasksError(),
    );
  }

  Widget _buildTodaysTasksContent(BuildContext context, List<TaskEntity> todaysTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.todaysTasks,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full task list
              },
              child: Text(
                AppStrings.seeAll,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...todaysTasks.take(3).map((task) => _buildTaskItem(task)),
        if (todaysTasks.isEmpty)
          _buildEmptyState(AppStrings.emptyStateTasks, AppStrings.emptyStateTasksDescription),
      ],
    );
  }

  Widget _buildTodaysTasksLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.todaysTasks,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(3, (index) => _buildTaskItemSkeleton()),
      ],
    );
  }

  Widget _buildTodaysTasksError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.todaysTasks,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load tasks',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    // Retry
                  },
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(TaskEntity task) {
    final timeStr = task.dueDate != null 
        ? DateFormat.jm().format(task.dueDate!)
        : 'No time';
    
    String statusLabel = 'PENDING';
    Color statusColor = AppColors.info;
    
    if (task.isCompleted) {
      statusLabel = 'DONE';
      statusColor = AppColors.success;
    } else if (task.priority == TaskPriority.urgent) {
      statusLabel = 'URGENT';
      statusColor = AppColors.error;
    } else if (task.status == TaskStatus.inProgress) {
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
          // Task Info
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

  Widget _buildTaskItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 80,
                  height: 12,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentActivity,
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
          'Comment left on Task #42',
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
