import 'package:flutter/material.dart';

/// Material Design 3 theme system with dynamic color support
class AppTheme {
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2), // Primary blue
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C1B1F),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1C1B1F),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF1C1B1F),
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Color(0xFF1C1B1F),
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE3F2FD),
        selectedColor: const Color(0xFF1976D2),
        labelStyle: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 3,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFFFDF5F1),
        selectedItemColor: Color(0xFF1976D2),
        unselectedItemColor: Color(0xFF49454F),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
        shape: CircleBorder(),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        iconSize: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1976D2),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(
          color: Color(0xFF9E9E9E),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF1C1B1F),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF49454F),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 6,
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        actionTextColor: const Color(0xFF64B5F6),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF1976D2),
        linearTrackColor: Color(0xFFE3F2FD),
        linearMinHeight: 4,
        circularTrackColor: Color(0xFFE3F2FD),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1976D2);
            }
            return const Color(0xFFBDBDBD);
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF90CAF9);
            }
            return const Color(0xFFE0E0E0);
          },
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1976D2);
            }
            return const Color(0xFFBDBDBD);
          },
        ),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1976D2);
            }
            return const Color(0xFFBDBDBD);
          },
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF1976D2),
        inactiveTrackColor: Color(0xFFE0E0E0),
        activeTickMarkColor: Color(0xFF1976D2),
        inactiveTickMarkColor: Color(0xFF757575),
        thumbColor: Color(0xFF1976D2),
        overlayColor: Color(0x1976D2),
        valueIndicatorColor: Color(0xFF1976D2),
        trackHeight: 6,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2), // Primary blue
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE0E0E0),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFE0E0E0),
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Color(0xFFE0E0E0),
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF37474F),
        selectedColor: const Color(0xFF64B5F6),
        labelStyle: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 3,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF121212),
        selectedItemColor: Color(0xFF64B5F6),
        unselectedItemColor: Color(0xFF9E9E9E),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
        shape: CircleBorder(),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        iconSize: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF424242),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF424242),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF64B5F6),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFCF6679),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(
          color: Color(0xFF9E9E9E),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFE0E0E0),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFFBDBDBD),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 6,
        backgroundColor: const Color(0xFF424242),
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        actionTextColor: const Color(0xFF90CAF9),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF64B5F6),
        linearTrackColor: Color(0xFF37474F),
        linearMinHeight: 4,
        circularTrackColor: Color(0xFF37474F),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF64B5F6);
            }
            return const Color(0xFF757575);
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1976D2);
            }
            return const Color(0xFF424242);
          },
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1976D2);
            }
            return const Color(0xFF757575);
          },
        ),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1976D2);
            }
            return const Color(0xFF757575);
          },
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF64B5F6),
        inactiveTrackColor: Color(0xFF424242),
        activeTickMarkColor: Color(0xFF64B5F6),
        inactiveTickMarkColor: Color(0xFF757575),
        thumbColor: Color(0xFF64B5F6),
        overlayColor: Color(0x1964B5F6),
        valueIndicatorColor: Color(0xFF64B5F6),
        trackHeight: 6,
      ),
    );
  }

  /// Get system theme (light/dark based on system preferences)
  static Future<ThemeMode> getSystemTheme() async {
    try {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      switch (brightness) {
        case Brightness.dark:
          return ThemeMode.dark;
        case Brightness.light:
          return ThemeMode.light;
      }
    } catch (e) {
      return ThemeMode.system;
    }
  }

  /// Check if dark mode is preferred
  static bool isDarkModePreferred(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  /// Get appropriate theme based on theme mode
  static ThemeData getTheme(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
            ? darkTheme
            : lightTheme;
    }
  }

  /// Get text theme based on theme
  static TextTheme getTextTheme(ThemeData theme) {
    return theme.textTheme.copyWith(
      displayLarge: theme.textTheme.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      displayMedium: theme.textTheme.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      displaySmall: theme.textTheme.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      headlineLarge: theme.textTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      headlineMedium: theme.textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      headlineSmall: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      titleLarge: theme.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      titleMedium: theme.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
      titleSmall: theme.textTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
      bodyLarge: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurface,
      ),
      bodyMedium: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurface,
      ),
      bodySmall: theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurface,
      ),
      labelLarge: theme.textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
      labelMedium: theme.textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
      labelSmall: theme.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  /// Get color scheme based on theme
  static ColorScheme getColorScheme(ThemeData theme) {
    return theme.colorScheme;
  }

  /// Get primary color
  static Color getPrimaryColor(ThemeData theme) {
    return theme.colorScheme.primary;
  }

  /// Get background color
  static Color getBackgroundColor(ThemeData theme) {
    return theme.colorScheme.surface;
  }

  /// Get surface color
  static Color getSurfaceColor(ThemeData theme) {
    return theme.colorScheme.surface;
  }

  /// Get on-surface color
  static Color getOnSurfaceColor(ThemeData theme) {
    return theme.colorScheme.onSurface;
  }

  /// Get error color
  static Color getErrorColor(ThemeData theme) {
    return theme.colorScheme.error;
  }

  /// Get success color
  static Color getSuccessColor(ThemeData theme) {
    return theme.colorScheme.primary;
  }

  /// Get warning color
  static Color getWarningColor(ThemeData theme) {
    return theme.colorScheme.secondary;
  }

  /// Get info color
  static Color getInfoColor(ThemeData theme) {
    return theme.colorScheme.tertiary;
  }
}

/// Theme extension for easy color access
extension ThemeExtension on ThemeData {
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
