import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized keyboard intents and shortcut activators for the desktop/web app.
class NewPaymentIntent extends Intent {
  const NewPaymentIntent();
}

class NavigateToTabIntent extends Intent {
  final int index;
  const NavigateToTabIntent(this.index);
}

/// App-wide keyboard shortcuts.
abstract class AppShortcuts {
  AppShortcuts._();

  static const Map<ShortcutActivator, Intent> shortcuts = {
    SingleActivator(LogicalKeyboardKey.keyN, control: true): NewPaymentIntent(),
    SingleActivator(LogicalKeyboardKey.keyN, meta: true): NewPaymentIntent(),
    SingleActivator(LogicalKeyboardKey.digit1, control: true): NavigateToTabIntent(0),
    SingleActivator(LogicalKeyboardKey.digit1, meta: true): NavigateToTabIntent(0),
    SingleActivator(LogicalKeyboardKey.digit2, control: true): NavigateToTabIntent(1),
    SingleActivator(LogicalKeyboardKey.digit2, meta: true): NavigateToTabIntent(1),
    SingleActivator(LogicalKeyboardKey.digit3, control: true): NavigateToTabIntent(2),
    SingleActivator(LogicalKeyboardKey.digit3, meta: true): NavigateToTabIntent(2),
    SingleActivator(LogicalKeyboardKey.digit4, control: true): NavigateToTabIntent(3),
    SingleActivator(LogicalKeyboardKey.digit4, meta: true): NavigateToTabIntent(3),
    SingleActivator(LogicalKeyboardKey.digit5, control: true): NavigateToTabIntent(4),
    SingleActivator(LogicalKeyboardKey.digit5, meta: true): NavigateToTabIntent(4),
  };
}
