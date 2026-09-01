import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF0B7A75);
  static const background = Color(0xFFF6F9F8);
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
}
