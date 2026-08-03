import 'package:flutter/material.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/theme/app_colors.dart';

String statusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return 'To do';
    case TaskStatus.inProgress:
      return 'In progress';
    case TaskStatus.review:
      return 'In review';
    case TaskStatus.completed:
      return 'Done';
    case TaskStatus.cancelled:
      return 'Cancelled';
  }
}

/// Small colored dot for a task status, used as a group/column header marker.
class StatusDot extends StatelessWidget {
  final TaskStatus status;
  final double size;

  const StatusDot({super.key, required this.status, this.size = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.statusColor(status), shape: BoxShape.circle),
    );
  }
}

/// Filled pill showing a task's status label, used on the task detail header.
class StatusPill extends StatelessWidget {
  final TaskStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
