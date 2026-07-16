import 'package:flutter/material.dart';

/// Prism — the Gravity design token system.
/// These primitives power the award-winning UI surfaces across the app.
class PrismTokens {
  // Border radius
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  // Spacing
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // Motion
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveBounce = Curves.bounceOut;

  // Glass & depth
  static const double blurSigma = 12;
  static const double borderOpacity = 0.15;
  static const double glassOpacity = 0.4;

  // Components
  static const double buttonHeight = 52;
  static const double buttonRadius = 16;
  static const double iconButtonSize = 44;
  static const double avatarSize = 44;
  static const double avatarIconSize = 22;
}

/// Curated set of premium page-transition curves.
class PrismCurves {
  static const Cubic smooth = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Cubic snap = Cubic(0.4, 0, 0.2, 1);
  static const Cubic bounce = Cubic(0.68, -0.55, 0.265, 1.55);
}

/// Pre-defined brand color roles used by UI primitives.
extension PrismColorExtension on ColorScheme {
  Color get glassSurface => surface.withValues(alpha: 0.55);
  Color get softPrimary => primary.withValues(alpha: 0.08);
  Color get softOutline => outlineVariant.withValues(alpha: 0.3);
}
