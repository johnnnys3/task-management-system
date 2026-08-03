import 'package:flutter/material.dart';
import 'package:task_management/theme/app_colors.dart';

/// Rounded progress track matching the TaskHub redesign (used for project
/// completion, task time-logged, etc).
class AppProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.terra,
    this.height = 7,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: height,
        color: AppColors.pageBg,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}
