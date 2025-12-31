import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Theme mode provider for managing app theme state
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode');
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'system':
            state = ThemeMode.system;
            break;
        }
      }
    } catch (e) {
      // Fallback to system theme if loading fails
      state = ThemeMode.system;
    }
  }

  /// Save theme mode to SharedPreferences
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      await prefs.setString('theme_mode', themeString);
    } catch (e) {
      // Silently fail saving
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = themeMode;
    await _saveThemeMode(themeMode);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newTheme);
  }

  /// Check if dark mode is currently active
  bool get isDarkMode {
    switch (state) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  /// Get current theme data
  ThemeData get currentTheme {
    return AppTheme.getTheme(state);
  }

  /// Get current color scheme
  ColorScheme get currentColorScheme {
    return currentTheme.colorScheme;
  }

  /// Get current text theme
  TextTheme get currentTextTheme {
    return AppTheme.getTextTheme(currentTheme);
  }
}

/// Riverpod provider for theme mode
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Provider for current theme data
final themeDataProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return AppTheme.getTheme(themeMode);
});

/// Provider for current color scheme
final colorSchemeProvider = Provider<ColorScheme>((ref) {
  final themeData = ref.watch(themeDataProvider);
  return themeData.colorScheme;
});

/// Provider for current text theme
final textThemeProvider = Provider<TextTheme>((ref) {
  final themeData = ref.watch(themeDataProvider);
  return themeData.textTheme;
});

/// Provider for dark mode status
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  switch (themeMode) {
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
      return false;
    case ThemeMode.system:
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }
});

/// Extension methods for easy theme access in widgets
extension ThemeExtensions on WidgetRef {
  /// Get current theme data
  ThemeData get theme => watch(themeDataProvider);
  
  /// Get current color scheme
  ColorScheme get colorScheme => watch(colorSchemeProvider);
  
  /// Get current text theme
  TextTheme get textTheme => watch(textThemeProvider);
  
  /// Check if dark mode is active
  bool get isDarkMode => watch(isDarkModeProvider);
  
  /// Get theme mode
  ThemeMode get themeMode => watch(themeModeProvider);
  
  /// Get primary color
  Color get primaryColor => colorScheme.primary;
  
  /// Get background color
  Color get backgroundColor => colorScheme.surface;
  
  /// Get surface color
  Color get surfaceColor => colorScheme.surface;
  
  /// Get on-surface color
  Color get onSurfaceColor => colorScheme.onSurface;
  
  /// Get error color
  Color get errorColor => colorScheme.error;
  
  /// Get success color
  Color get successColor => colorScheme.primary;
  
  /// Get warning color
  Color get warningColor => colorScheme.secondary;
  
  /// Get info color
  Color get infoColor => colorScheme.tertiary;
}

/// Extension methods for easy theme access in BuildContext
extension BuildContextThemeExtensions on BuildContext {
  /// Get current theme data
  ThemeData get theme => Theme.of(this);
  
  /// Get current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Get current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Check if dark mode is active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Get primary color
  Color get primaryColor => colorScheme.primary;
  
  /// Get background color
  Color get backgroundColor => colorScheme.surface;
  
  /// Get surface color
  Color get surfaceColor => colorScheme.surface;
  
  /// Get on-surface color
  Color get onSurfaceColor => colorScheme.onSurface;
  
  /// Get error color
  Color get errorColor => colorScheme.error;
  
  /// Get success color
  Color get successColor => colorScheme.primary;
  
  /// Get warning color
  Color get warningColor => colorScheme.secondary;
  
  /// Get info color
  Color get infoColor => colorScheme.tertiary;
}

/// Theme utilities
class ThemeUtils {
  ThemeUtils._();

  /// Get appropriate text color based on background
  static Color getTextColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  /// Get appropriate icon color based on background
  static Color getIconColor(Color backgroundColor) {
    return getTextColor(backgroundColor);
  }

  /// Get appropriate border color based on theme
  static Color getBorderColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.2);
  }

  /// Get appropriate shadow color based on theme
  static Color getShadowColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
  }

  /// Get appropriate overlay color based on theme
  static Color getOverlayColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);
  }

  /// Check if color is light
  static bool isLightColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.light;
  }

  /// Check if color is dark
  static bool isDarkColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }

  /// Get contrasting color
  static Color getContrastingColor(Color color) {
    return isLightColor(color) ? Colors.black : Colors.white;
  }

  /// Get appropriate card color for theme
  static Color getCardColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? Colors.white
        : const Color(0xFF2C2C2C);
  }

  /// Get appropriate surface variant color for theme
  static Color getSurfaceVariantColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFFF5F5F5)
        : const Color(0xFF37474F);
  }

  /// Get appropriate outline color for theme
  static Color getOutlineColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF424242);
  }

  /// Get appropriate outline variant color for theme
  static Color getOutlineVariantColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFFF0F0F0)
        : const Color(0xFF49454F);
  }

  /// Get appropriate surface tint color for theme
  static Color getSurfaceTintColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFFE3F2FD)
        : const Color(0xFF1E3A8A);
  }

  /// Get appropriate inverse surface color for theme
  static Color getInverseSurfaceColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFF313033)
        : const Color(0xFFFEF7FF);
  }

  /// Get appropriate inverse on-surface color for theme
  static Color getInverseOnSurfaceColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFFE6E1E5)
        : const Color(0xFF313033);
  }

  /// Get appropriate inverse primary color for theme
  static Color getInversePrimaryColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFF90CAF9)
        : const Color(0xFF0D47A1);
  }

  /// Get appropriate scrim color for theme
  static Color getScrimColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? Colors.black.withOpacity(0.32)
        : Colors.black.withOpacity(0.32);
  }

  /// Get appropriate elevation color for theme
  static Color getElevationColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? Colors.black.withOpacity(0.05)
        : Colors.black.withOpacity(0.1);
  }

  /// Get appropriate disabled color for theme
  static Color getDisabledColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFF757575)
        : const Color(0xFF9E9E9E);
  }

  /// Get appropriate divider color for theme
  static Color getDividerColor(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF424242);
  }
}

/// Theme constants
class ThemeConstants {
  ThemeConstants._();

  /// Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  /// Elevation values
  static const double lowElevation = 1.0;
  static const double mediumElevation = 4.0;
  static const double highElevation = 8.0;

  /// Border radius values
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 12.0;
  static const double extraLargeRadius = 16.0;
  static const double circularRadius = 999.0;

  /// Spacing values
  static const double tinySpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  /// Opacity values
  static const double lowOpacity = 0.1;
  static const double mediumOpacity = 0.3;
  static const double highOpacity = 0.6;
  static const double fullOpacity = 1.0;

  /// Icon sizes
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  /// Font sizes
  static const double tinyFontSize = 10.0;
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double extraLargeFontSize = 20.0;
  static const double titleFontSize = 24.0;
  static const double headlineFontSize = 32.0;

  /// Stroke widths
  static const double thinStroke = 1.0;
  static const double mediumStroke = 2.0;
  static const double thickStroke = 3.0;
}
