import 'package:flutter/material.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';

/// Pill-shaped button matching the TaskHub redesign.
/// [outlined] gives the transparent/bordered secondary style,
/// [danger] tints an outlined button in the rust accent (used for destructive actions).
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool danger;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: danger
            ? OutlinedButton.styleFrom(
                foregroundColor: AppColors.rust,
                side: const BorderSide(color: Color(0x66A63D2F)),
              )
            : null,
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        textStyle: AppTheme.display(size: 14, color: AppColors.shell),
      ),
      child: child,
    );
  }
}
