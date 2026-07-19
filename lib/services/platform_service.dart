import 'dart:io';

import 'package:flutter/foundation.dart';

/// Centralized platform capability detection.
///
/// This service keeps platform-specific decisions in one place so that the UI
/// and other services can gracefully fall back when a feature is not available.
class PlatformService {
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isMobile => isAndroid || isIOS;
  static bool get isApple => isIOS || isMacOS;
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Haptic feedback is only meaningful on mobile devices.
  static bool get supportsHaptic => isMobile;

  /// Biometric hardware is available on most modern mobile devices and macOS.
  /// Windows Hello and Linux support depend on the local_auth plugin.
  static bool get supportsBiometric => isMobile || isMacOS;

  /// Local notifications are supported on all target platforms, but some
  /// desktop platforms require a packaged app to show them.
  static bool get supportsNotifications => true;

  /// File picker is available on all mobile and desktop platforms.
  static bool get supportsFilePicker => true;

  /// External storage permission is an Android-only concern.
  static bool get requiresStoragePermission => isAndroid;
}
