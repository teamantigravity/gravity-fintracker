import 'package:flutter/material.dart';
import 'package:fintracker/data/icons.dart';

/// Converts a stored icon code point back into a const [IconData] when possible.
/// Avoids invoking the [IconData] constructor with a non-constant code point,
/// which triggers the icon-tree-shaker's mustBeConst analysis.
class IconHelper {
  static final List<IconData> _all = AppIcons.icons;
  static final Map<int, IconData> _cache = {};

  static final Map<int, IconData> _migrationMap = {
    58152: Icons.house, // Housing
    57907: Icons.emoji_transportation, // Transportation
    58674: Icons.restaurant, // Food
    57672: Icons.category, // Utilities
    58117: Icons.health_and_safety, // Insurance
    985004: Icons.medical_information, // Medical
    57522: Icons.attach_money, // Saving
    59015: Icons.tv, // Recreation
    60017: Icons.library_books_sharp, // Miscellaneous
    984868: Icons.credit_card, // Credit Card
    985044: Icons.wallet, // Accounts (Cash)
  };

  static IconData lookup(int? codePoint, {required IconData fallback}) {
    if (codePoint == null) return fallback;
    if (_cache.containsKey(codePoint)) return _cache[codePoint]!;

    if (_migrationMap.containsKey(codePoint)) {
      final match = _migrationMap[codePoint]!;
      _cache[codePoint] = match;
      return match;
    }

    final match = _all.firstWhere(
      (icon) => icon.codePoint == codePoint,
      orElse: () => fallback,
    );
    _cache[codePoint] = match;
    return match;
  }
}
