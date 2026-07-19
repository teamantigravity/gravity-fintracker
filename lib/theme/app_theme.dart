import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:google_fonts/google_fonts.dart';
import 'package:fintracker/ui/prism_tokens.dart';
import 'package:fintracker/theme/prism_colors.dart';

enum AppThemeMode { light, dark, amoled, system }

class AppTheme {
  static const Color _defaultSeedColor = PrismColors.primary;

  static const Color successLight = PrismColors.successLight;
  static const Color successDark = PrismColors.successDark;
  static const Color errorLight = PrismColors.errorLight;
  static const Color errorDark = PrismColors.errorDark;
  static const Color incomeColor = PrismColors.income;
  static const Color expenseColor = PrismColors.expense;

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.outfitTextTheme(base);
  }

  static Color _seedColor(int? themeColor) {
    return themeColor != null ? Color(themeColor) : _defaultSeedColor;
  }

  static ThemeData light({int? themeColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor(themeColor),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      pageTransitionsTheme: _pageTransitionsTheme,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      navigationBarTheme: _navigationBarTheme(),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PrismTokens.radiusMd)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
      pageTransitionsTheme: _pageTransitionsTheme,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      navigationBarTheme: _navigationBarTheme(),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PrismTokens.radiusMd)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
      pageTransitionsTheme: _pageTransitionsTheme,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      navigationBarTheme: _navigationBarTheme().copyWith(
        backgroundColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PrismTokens.radiusLg)),
        color: PrismColors.darkSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.black,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PrismTokens.radiusMd)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dividerTheme: const DividerThemeData(
        color: PrismColors.darkSurfaceVariant,
        thickness: 0.5,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PrismColors.darkSurface,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: PrismColors.darkSurface,
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
  static const List<Color> accentOptions = PrismColors.brandAccentOptions;

  static NavigationBarThemeData _navigationBarTheme() {
    return NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        TextStyle style = GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
        if (states.contains(WidgetState.selected)) {
          style = style.merge(const TextStyle(fontWeight: FontWeight.w700));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PrismTokens.radiusLg)),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PrismTokens.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PrismTokens.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PrismTokens.radiusMd),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  static const PageTransitionsTheme _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );
}
