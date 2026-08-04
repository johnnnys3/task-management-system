import 'package:flutter/material.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/theme/app_colors.dart';

/// Pill chip for a task's priority (urgent/high/medium/low), colored per design tokens.
class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  static String labelOf(TaskPriority p) => _label(p);

  static String _label(TaskPriority p) {
    switch (p) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.priorityColors(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        _label(priority),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.fg),
      ),
    );
  }
}
