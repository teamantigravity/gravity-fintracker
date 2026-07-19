import 'package:flutter/services.dart';
import 'package:fintracker/services/platform_service.dart';

/// Provides haptic feedback for state-of-the-art tactile interactions.
/// No-op on platforms that do not support haptic feedback.
class HapticService {
  static void _run(void Function() action) {
    if (PlatformService.supportsHaptic) action();
  }

  static void light() => _run(HapticFeedback.lightImpact);
  static void medium() => _run(HapticFeedback.mediumImpact);
  static void heavy() => _run(HapticFeedback.heavyImpact);
  static void selection() => _run(HapticFeedback.selectionClick);
  static void vibrate() => _run(HapticFeedback.vibrate);
}
