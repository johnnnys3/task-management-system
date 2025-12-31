import 'package:flutter/material.dart';
import 'package:task_management/constants/app_constants.dart';
import 'package:task_management/core/constants/app_strings.dart';

/// Optimized summary card widget with const constructors and performance optimizations
class OptimizedSummaryCard extends StatelessWidget {

  const OptimizedSummaryCard({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.count,
    required this.label,
    required this.textColor,
  });
  final Color backgroundColor;
  final IconData icon;
  final int count;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconContainer(),
          const SizedBox(height: AppSpacing.md),
          _buildCountText(),
          const SizedBox(height: AppSpacing.xs),
          _buildLabelText(),
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getIconContainerColor(),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        icon,
        color: _getIconColor(),
        size: 24,
      ),
    );
  }

  Widget _buildCountText() {
    return Text(
      '$count',
      style: AppTextStyles.displaySmall.copyWith(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildLabelText() {
    return Text(
      label,
      style: AppTextStyles.labelLarge.copyWith(
        color: _getLabelTextColor(),
      ),
    );
  }

  Color _getIconContainerColor() {
    return backgroundColor == AppColors.primaryBlue 
        ? Colors.white.withOpacity(0.2)
        : AppColors.primaryBlue.withOpacity(0.1);
  }

  Color _getIconColor() {
    return backgroundColor == AppColors.primaryBlue ? Colors.white : AppColors.primaryBlue;
  }

  Color _getLabelTextColor() {
    return backgroundColor == AppColors.primaryBlue ? Colors.white : AppColors.textSecondary;
  }
}

/// Const factory constructors for common summary card types
class SummaryCardFactory {
  const SummaryCardFactory._();

  static const OptimizedSummaryCard completedCard = OptimizedSummaryCard(
    backgroundColor: AppColors.primaryBlue,
    icon: Icons.check_circle_outline,
    count: 0,
    label: AppStrings.completed,
    textColor: Colors.white,
  );

  static const OptimizedSummaryCard inProgressCard = OptimizedSummaryCard(
    backgroundColor: AppColors.surfaceLight,
    icon: Icons.access_time,
    count: 0,
    label: AppStrings.inProgress,
    textColor: AppColors.primaryBlue,
  );

  static const OptimizedSummaryCard pendingCard = OptimizedSummaryCard(
    backgroundColor: AppColors.surfaceLight,
    icon: Icons.pending_outlined,
    count: 0,
    label: AppStrings.pending,
    textColor: AppColors.primaryPurple,
  );

  static OptimizedSummaryCard completed(int count) {
    return const OptimizedSummaryCard(
      backgroundColor: AppColors.primaryBlue,
      icon: Icons.check_circle_outline,
      count: 0,
      label: AppStrings.completed,
      textColor: Colors.white,
    ).withCount(count);
  }

  static OptimizedSummaryCard inProgress(int count) {
    return const OptimizedSummaryCard(
      backgroundColor: AppColors.surfaceLight,
      icon: Icons.access_time,
      count: 0,
      label: AppStrings.inProgress,
      textColor: AppColors.primaryBlue,
    ).withCount(count);
  }

  static OptimizedSummaryCard pending(int count) {
    return const OptimizedSummaryCard(
      backgroundColor: AppColors.surfaceLight,
      icon: Icons.pending_outlined,
      count: 0,
      label: AppStrings.pending,
      textColor: AppColors.primaryPurple,
    ).withCount(count);
  }
}

// Extension method for updating count
extension OptimizedSummaryCardExtension on OptimizedSummaryCard {
  OptimizedSummaryCard withCount(int count) {
    return OptimizedSummaryCard(
      backgroundColor: backgroundColor,
      icon: icon,
      count: count,
      label: label,
      textColor: textColor,
    );
  }
}
