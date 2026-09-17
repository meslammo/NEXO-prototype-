import 'package:flutter/material.dart';

class NexoColors {
  static const background = Color(0xFF0A1929);
  static const surface = Color(0xFF0F2238);
  static const card = Color(0xFF132F4C);
  static const cardBorder = Color(0xFF234A6B);
  static const primary = Color(0xFF00D4FF);
  static const secondary = Color(0xFF7C3AED);
  static const gold = Color(0xFFFFC107);
  static const social = Color(0xFFFF4D8D);
  static const success = Color(0xFF35D07F);
  static const ticket = Color(0xFFFF8A65);
  static const textSecondary = Color(0xFF90A4AE);
}

class NexoTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NexoColors.background,
    colorScheme: const ColorScheme.dark(
      primary: NexoColors.primary,
      secondary: NexoColors.secondary,
      surface: NexoColors.surface,
      error: Color(0xFFFF5370),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NexoColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardTheme(
      color: NexoColors.card,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: NexoColors.surface,
      indicatorColor: Color(0x3323D6FF),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: NexoColors.textSecondary),
    ),
  );
}
