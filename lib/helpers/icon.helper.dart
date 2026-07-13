import 'package:flutter/material.dart';
import 'package:fintracker/data/icons.dart';

/// Converts a stored icon code point back into a const [IconData] when possible.
/// Avoids invoking the [IconData] constructor with a non-constant code point,
/// which triggers the icon-tree-shaker's mustBeConst analysis.
class IconHelper {
  static final List<IconData> _all = AppIcons.icons;
  static final Map<int, IconData> _cache = {};

  static IconData lookup(int? codePoint, {required IconData fallback}) {
    if (codePoint == null) return fallback;
    if (_cache.containsKey(codePoint)) return _cache[codePoint]!;
    try {
      final match = _all.firstWhere((icon) => icon.codePoint == codePoint);
      _cache[codePoint] = match;
      return match;
    } catch (_) {
      _cache[codePoint] = fallback;
      return fallback;
    }
  }
}
