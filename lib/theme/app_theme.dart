import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_management/theme/app_colors.dart';

/// Builds the TaskHub redesign theme: Bricolage Grotesque display font,
/// Figtree body font, pill-shaped controls, 26px card radius.
class AppTheme {
  AppTheme._();

  static TextStyle display({double size = 20, FontWeight weight = FontWeight.w700, Color? color}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -0.025 * size,
      color: color ?? AppColors.ink,
    );
  }

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1C1B) : AppColors.shell;
    final surface = isDark ? const Color(0xFF2A2827) : AppColors.paper;
    final onSurface = isDark ? AppColors.shell : AppColors.ink;

    final base = GoogleFonts.figtreeTextTheme();
    final textTheme = base.copyWith(
      headlineLarge: display(size: 32, color: onSurface),
      headlineMedium: display(size: 24, color: onSurface),
      titleLarge: display(size: 20, color: onSurface),
      titleMedium: display(size: 18, color: onSurface),
      bodyLarge: GoogleFonts.figtree(fontSize: 16, color: onSurface),
      bodyMedium: GoogleFonts.figtree(fontSize: 14, color: onSurface),
      labelLarge: GoogleFonts.figtree(fontWeight: FontWeight.w700, color: onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.terra,
        brightness: brightness,
        primary: AppColors.terra,
        secondary: AppColors.rust,
        surface: surface,
        error: AppColors.rust,
      ),
      textTheme: textTheme,
      fontFamily: GoogleFonts.figtree().fontFamily,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: bg,
        foregroundColor: onSurface,
        titleTextStyle: display(size: 20, color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terra,
          foregroundColor: AppColors.shell,
          textStyle: display(size: 15, color: AppColors.shell),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: onSurface.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terra,
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: onSurface.withOpacity(0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: onSurface.withOpacity(0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.terra, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sand,
        labelStyle: GoogleFonts.figtree(fontSize: 13.5, fontWeight: FontWeight.w600, color: onSurface),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: onSurface.withOpacity(0.1), thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.sand,
        selectedItemColor: AppColors.terra,
        unselectedItemColor: AppColors.ink3,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
