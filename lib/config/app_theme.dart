import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF123038);
  static const teal = Color(0xFF0F766E);
  static const mint = Color(0xFFDDF3EE);
  static const canvas = Color(0xFFF5F7F6);
  static const ink = Color(0xFF172B2D);
  static const muted = Color(0xFF667779);
  static const line = Color(0xFFE2E8E6);
  static const orange = Color(0xFFE9783A);
  static const red = Color(0xFFC64949);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: teal, surface: Colors.white),
    scaffoldBackgroundColor: canvas,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.25,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: muted, height: 1.4),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
