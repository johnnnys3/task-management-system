import 'package:flutter/material.dart';
import 'package:task_management/models/task.dart';

/// Design tokens for the TaskHub redesign.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF1E1C1B);
  static const Color ink2 = Color(0xFF57534E);
  static const Color ink3 = Color(0xFF857E77);
  static const Color paper = Color(0xFFFBFAF8);
  static const Color shell = Color(0xFFF4F2EF);
  static const Color sand = Color(0xFFE9E6E1);
  static const Color edge = Color(0x1A1E1C1B); // rgba(30,28,27,.1)
  static const Color pageBg = Color(0xFFE4E1DB);

  static const Color terra = Color(0xFF2F6F5F);
  static const Color terraDark = Color(0xFF245A4C);
  static const Color rust = Color(0xFFA63D2F);
  static const Color sage = Color(0xFF4E7D63);
  static const Color peach = Color(0xFFE8CBB8);
  static const Color blush = Color(0xFFF7E2D9);
  static const Color mint = Color(0xFFCFE3D6);

  static const Color statusTodo = Color(0xFF9A938C);
  static const Color statusInProgress = Color(0xFF2F6F5F);
  static const Color statusReview = Color(0xFFC08A3E);
  static const Color statusDone = Color(0xFF3F6B52);

  static Color statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return statusTodo;
      case TaskStatus.inProgress:
        return statusInProgress;
      case TaskStatus.review:
        return statusReview;
      case TaskStatus.completed:
        return statusDone;
      case TaskStatus.cancelled:
        return ink3;
    }
  }

  static ({Color bg, Color fg}) priorityColors(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return (bg: const Color(0xFFF2CFC3), fg: rust);
      case TaskPriority.high:
        return (bg: blush, fg: rust);
      case TaskPriority.medium:
        return (bg: const Color(0xFFE6DDCB), fg: ink2);
      case TaskPriority.low:
        return (bg: const Color(0xFFE6DDCB), fg: ink3);
    }
  }

  /// Deterministic avatar color from a stable key (name/id), matching the
  /// design's small fixed palette of person colors.
  static Color avatarColor(String key) {
    const palette = [terra, sage, rust, Color(0xFF4A6B8A), Color(0xFFB07D3A)];
    final index = key.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[index];
  }
}
