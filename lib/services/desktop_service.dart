import 'dart:io';
import 'package:fintracker/config/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class DesktopService {
  static final SystemTray _systemTray = SystemTray();
  static final AppWindow _appWindow = AppWindow();
  static bool _initialized = false;

  static bool get isDesktop {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }

  static Future<void> initialize() async {
    if (!isDesktop || _initialized) return;
    try {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 800),
        minimumSize: Size(800, 600),
        center: true,
        title: AppConstants.appName,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      await _systemTray.initSystemTray(
        title: AppConstants.appName,
        toolTip: AppConstants.appTagline,
        iconPath: Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
      );

      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: 'Open', onClicked: (menuItem) => _appWindow.show()),
        MenuSeparator(),
        MenuItemLabel(label: 'Hide', onClicked: (menuItem) => _appWindow.hide()),
        MenuItemLabel(label: 'Exit', onClicked: (menuItem) => _appWindow.close()),
      ]);
      await _systemTray.setContextMenu(menu);

      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          _appWindow.show();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('Desktop service init failed: $e');
    }
  }

  static Future<void> hide() async {
    if (!_initialized) return;
    try {
      await _appWindow.hide();
    } catch (_) {}
  }

  static Future<void> show() async {
    if (!_initialized) return;
    try {
      await _appWindow.show();
    } catch (_) {}
  }
}
