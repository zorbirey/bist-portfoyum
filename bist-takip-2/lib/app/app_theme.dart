import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    const seed = Color(0xFF7FAE9B);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF7F9F7),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F7F5),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE4EAE6)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4EAE6)),
        ),
      ),
    );
  }
}
