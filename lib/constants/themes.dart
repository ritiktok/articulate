import 'package:flutter/material.dart';
import 'palette.dart';
import 'styles.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Palette.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.surface,
        foregroundColor: Palette.textPrimary,
        elevation: Styles.elevationS,
        centerTitle: true,
        titleTextStyle: Styles.headline3,
      ),
      cardTheme: CardThemeData(
        color: Palette.surface,
        elevation: Styles.elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Styles.radiusM),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.primary,
          foregroundColor: Palette.surface,
          textStyle: Styles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Styles.radiusM),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Styles.spacingL,
            vertical: Styles.spacingM,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Palette.primary,
        foregroundColor: Palette.surface,
      ),
      iconTheme: const IconThemeData(color: Palette.textPrimary, size: 24.0),
      textTheme: const TextTheme(
        headlineLarge: Styles.headline1,
        headlineMedium: Styles.headline2,
        headlineSmall: Styles.headline3,
        bodyLarge: Styles.body1,
        bodyMedium: Styles.body2,
        bodySmall: Styles.caption,
        labelLarge: Styles.button,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: Styles.elevationS,
        centerTitle: true,
        titleTextStyle: Styles.headline3,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: Styles.elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Styles.radiusM),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.primary,
          foregroundColor: Palette.surface,
          textStyle: Styles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Styles.radiusM),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Styles.spacingL,
            vertical: Styles.spacingM,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Palette.primary,
        foregroundColor: Palette.surface,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 24.0),
      textTheme: const TextTheme(
        headlineLarge: Styles.headline1,
        headlineMedium: Styles.headline2,
        headlineSmall: Styles.headline3,
        bodyLarge: Styles.body1,
        bodyMedium: Styles.body2,
        bodySmall: Styles.caption,
        labelLarge: Styles.button,
      ),
    );
  }
}
