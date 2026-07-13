import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { light, dark, amoled, system }

class AppTheme {
  static const Color _defaultSeedColor = Color(0xFF4285F4); // Google Blue

  static const Color successLight = Color(0xFF0AA553);
  static const Color successDark = Color(0xFF4CAF50);
  static const Color errorLight = Color(0xFFE0302A);
  static const Color errorDark = Color(0xFFEF5350);
  static const Color incomeColor = Color(0xFF2E7D32);
  static const Color expenseColor = Color(0xFFC62828);

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base);
  }

  static Color _seedColor(int? themeColor) {
    return themeColor != null ? Color(themeColor) : _defaultSeedColor;
  }

  static ThemeData light({int? themeColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor(themeColor),
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      navigationBarTheme: _navigationBarTheme(),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.3),
        thickness: 0.5,
      ),
    );
  }

  static ThemeData dark({int? themeColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor(themeColor),
      brightness: Brightness.dark,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      navigationBarTheme: _navigationBarTheme(),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.3),
        thickness: 0.5,
      ),
    );
  }

  static ThemeData amoled({int? themeColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor(themeColor),
      brightness: Brightness.dark,
    ).copyWith(
      surface: Colors.black,
      onSurface: Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      navigationBarTheme: _navigationBarTheme().copyWith(
        backgroundColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF121212),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.black,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E1E1E),
        thickness: 0.5,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF121212),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF121212),
      ),
    );
  }

  static ThemeData getTheme(AppThemeMode mode, Brightness platformBrightness, {int? themeColor}) {
    switch (mode) {
      case AppThemeMode.light:
        return light(themeColor: themeColor);
      case AppThemeMode.dark:
        return dark(themeColor: themeColor);
      case AppThemeMode.amoled:
        return amoled(themeColor: themeColor);
      case AppThemeMode.system:
        return platformBrightness == Brightness.dark ? dark(themeColor: themeColor) : light(themeColor: themeColor);
    }
  }

  /// Selectable accent options — Google's four brand colors, offered as a
  /// tasteful personalization choice rather than a decorative afterthought.
  static const List<Color> accentOptions = [
    Color(0xFF4285F4), // Blue
    Color(0xFFEA4335), // Red
    Color(0xFFFBBC05), // Yellow
    Color(0xFF34A853), // Green
  ];

  static NavigationBarThemeData _navigationBarTheme() {
    return NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        TextStyle style = GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        );
        if (states.contains(WidgetState.selected)) {
          style = style.merge(const TextStyle(fontWeight: FontWeight.w600));
        }
        return style;
      }),
      elevation: 0,
      height: 65,
    );
  }

  static CardThemeData _cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}
