import 'dart:ui';
import 'package:fintracker/screens/lock/app_lock.screen.dart';
import 'package:flutter/material.dart';

/// Wraps the app content and enforces App Lock: locked immediately on cold
/// start (if enabled) and again whenever the app returns from the
/// background. The underlying content stays mounted (state preserved) but
/// is blurred and non-interactive while locked.
class AppLockGate extends StatefulWidget {
  final bool appLockEnabled;
  final Widget child;

  const AppLockGate({super.key, required this.appLockEnabled, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late bool _locked = widget.appLockEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the user just disabled App Lock in Settings, release immediately.
    if (!widget.appLockEnabled && _locked) {
      setState(() => _locked = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && widget.appLockEnabled) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: _locked,
          child: _locked
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: widget.child,
                )
              : widget.child,
        ),
        if (_locked)
          AppLockScreen(onUnlocked: () => setState(() => _locked = false)),
      ],
    );
  }
}
