import 'package:flutter/material.dart';

/// Centralized semantic and brand colors for the Gravity Fintracker design system.
///
/// All direct `Color(0xFF...)` usages outside of this file and [app_theme.dart]
/// should reference these constants.
class PrismColors {
  PrismColors._();

  // Brand — Gravity Fintracker palette
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleGreen = Color(0xFF34A853);

  // Semantic roles
  static const Color primary = googleBlue;
  static const Color success = googleGreen;
  static const Color income = Color(0xFF2E7D32);
  static const Color error = Color(0xFFEA4335);
  static const Color expense = Color(0xFFC62828);
  static const Color warning = googleYellow;
  static const Color info = googleBlue;
  static const Color verified = income;

  // Dark theme surfaces
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);

  // Success/error variants used by [AppTheme]
  static const Color successLight = Color(0xFF0AA553);
  static const Color successDark = Color(0xFF4CAF50);
  static const Color errorLight = Color(0xFFE0302A);
  static const Color errorDark = Color(0xFFEF5350);

  // Material accent options presented in the color picker
  static const List<Color> accentOptions = [
    Color(0xFF6750A4),
    Color(0xFF006A60),
    Color(0xFF006D37),
    Color(0xFF005AC1),
    Color(0xFF984061),
    Color(0xFF934B00),
  ];

  // Legacy Google brand accent options
  static const List<Color> brandAccentOptions = [
    googleBlue,
    googleRed,
    googleYellow,
    googleGreen,
  ];
}
