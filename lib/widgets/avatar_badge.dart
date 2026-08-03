import 'package:flutter/material.dart';
import 'package:task_management/theme/app_colors.dart';

/// Initials circle for a person, colored deterministically from their name.
class AvatarBadge extends StatelessWidget {
  final String name;
  final double size;

  const AvatarBadge({super.key, required this.name, this.size = 30});

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.avatarColor(name), shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: AppColors.shell,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
