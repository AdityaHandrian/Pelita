import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_db.dart';

final themeProvider = FutureProvider<ThemeData>((ref) async {
  final isar = ref.read(isarDbProvider);
  final settings = await isar.getSettings();
  if (settings.themeMode == 'black_yellow') {
    return AppTheme.highContrastTheme;
  }
  return AppTheme.darkTheme;
});

class AppTheme {
  // Pure black and absolute contrast colors for OLED power saving and low-vision clarity
  static const Color background = Color(0xFF000000);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color highlight = Color(0xFFFFEB3B); // Yellow for highlights
  static const Color error = Color(0xFFFF5252);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: highlight,
        secondary: highlight,
        error: error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: primaryText,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        displayMedium: TextStyle(
          color: primaryText,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(
          color: primaryText,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(
          color: primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: primaryText,
          side: const BorderSide(color: primaryText, width: 4),
          textStyle: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(32),
        ),
      ),
    );
  }

  static ThemeData get highContrastTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: highlight,
        secondary: highlight,
        error: error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: highlight,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        displayMedium: TextStyle(
          color: highlight,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(
          color: highlight,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(
          color: highlight,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: highlight,
          side: const BorderSide(color: highlight, width: 4),
          textStyle: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(32),
        ),
      ),
    );
  }
}
