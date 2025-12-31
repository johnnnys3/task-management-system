import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

/// Theme settings widget for managing app theme
class ThemeSettingsWidget extends ConsumerWidget {
  const ThemeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Theme mode selection
            Text(
              'Theme Mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeNotifier.setThemeMode(value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        themeNotifier.setThemeMode(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow device settings'),
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setThemeMode(value);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Quick toggle button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  themeNotifier.toggleTheme();
                },
                icon: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                label: Text(
                  themeMode == ThemeMode.light
                      ? 'Switch to Dark Mode'
                      : 'Switch to Light Mode',
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current theme info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Theme',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    themeMode.toString().split('.').last,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dark Mode: ${ref.watch(isDarkModeProvider) ? "On" : "Off"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact theme toggle button for use in app bars or toolbars
class ThemeToggleWidget extends ConsumerWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return IconButton(
      onPressed: () {
        themeNotifier.toggleTheme();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          themeMode == ThemeMode.light
              ? Icons.dark_mode_outlined
              : Icons.light_mode_outlined,
          key: ValueKey(themeMode),
        ),
      ),
      tooltip: themeMode == ThemeMode.light
          ? 'Switch to Dark Mode'
          : 'Switch to Light Mode',
    );
  }
}

/// Theme switcher with animated icon
class AnimatedThemeSwitcher extends ConsumerWidget {
  const AnimatedThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return GestureDetector(
      onTap: () {
        themeNotifier.toggleTheme();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                themeMode == ThemeMode.light
                    ? Icons.light_mode
                    : Icons.dark_mode,
                key: ValueKey(themeMode),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                themeMode == ThemeMode.light ? 'Light' : 'Dark',
                key: ValueKey(themeMode),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme preview widget showing color palettes
class ThemePreviewWidget extends ConsumerWidget {
  const ThemePreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Palette',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Primary colors
            _buildColorRow(context, 'Primary', [
              colorScheme.primary,
              colorScheme.onPrimary,
            ]),
            
            // Secondary colors
            _buildColorRow(context, 'Secondary', [
              colorScheme.secondary,
              colorScheme.onSecondary,
            ]),
            
            // Surface colors
            _buildColorRow(context, 'Surface', [
              colorScheme.surface,
              colorScheme.onSurface,
            ]),
            
            // Error colors
            _buildColorRow(context, 'Error', [
              colorScheme.error,
              colorScheme.onError,
            ]),
            
            // Success colors (using primary)
            _buildColorRow(context, 'Success', [
              colorScheme.primary,
              colorScheme.onPrimary,
            ]),
            
            // Warning colors (using secondary)
            _buildColorRow(context, 'Warning', [
              colorScheme.secondary,
              colorScheme.onSecondary,
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(BuildContext context, String label, List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          ...colors.map((color) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// Theme settings dialog
class ThemeSettingsDialog extends StatelessWidget {
  const ThemeSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Theme Settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              const ThemeSettingsWidget(),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme settings screen
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        actions: const [
          ThemeToggleWidget(),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ThemeSettingsWidget(),
            SizedBox(height: 16),
            ThemePreviewWidget(),
          ],
        ),
      ),
    );
  }
}

/// Theme-aware container widget
class ThemeAwareContainer extends StatelessWidget {

  const ThemeAwareContainer({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
    this.image,
  });
  final Widget child;
  final Color? color;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final DecorationImage? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: color ?? theme.colorScheme.surface,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        border: border ?? Border.all(
          color: theme.colorScheme.outline,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        image: image,
      ),
      child: child,
    );
  }
}

/// Theme-aware card widget
class ThemeAwareCard extends StatelessWidget {

  const ThemeAwareCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: color ?? theme.colorScheme.surface,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
