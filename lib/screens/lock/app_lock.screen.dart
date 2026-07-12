import 'package:fintracker/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Full-screen authentication gate shown on cold start and whenever the app
/// resumes from the background, if App Lock is enabled.
///
/// Gracefully handles devices with no biometric hardware (falls back to
/// device PIN/pattern/password via `local_auth`) and devices with no secure
/// lock screen at all (auto-releases rather than permanently trapping the
/// user out of their own financial data — see [BiometricCapability.unavailable]).
class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> with SingleTickerProviderStateMixin {
  final BiometricService _biometrics = BiometricService();
  bool _checking = true;
  bool _authenticating = false;
  String? _errorMessage;
  BiometricCapability _capability = BiometricCapability.unavailable;

  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final capability = await _biometrics.getCapability();
    if (!mounted) return;

    if (capability == BiometricCapability.unavailable) {
      // The device has no biometric AND no PIN/pattern/password configured.
      // Enforcing a lock here would permanently strand the user with no way
      // back into their own data — release the gate instead of bricking it.
      widget.onUnlocked();
      return;
    }

    setState(() {
      _capability = capability;
      _checking = false;
    });
    _attemptUnlock();
  }

  Future<void> _attemptUnlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    final result = await _biometrics.authenticate(
      reason: 'Verify your identity to open Gravity Fintracker',
    );

    if (!mounted) return;

    if (result == AuthResult.success) {
      widget.onUnlocked();
      return;
    }

    if (result == AuthResult.unavailable) {
      // Lock screen was removed from the device after App Lock was enabled.
      widget.onUnlocked();
      return;
    }

    setState(() {
      _authenticating = false;
      _errorMessage = _biometrics.friendlyMessage(result);
    });
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isBiometric = _capability == BiometricCapability.biometric;

    return Material(
      color: const Color(0xFF0A0C1B),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shake = _shakeController.status == AnimationStatus.forward || _shakeController.value > 0
              ? _shakeOffset(_shakeController.value)
              : 0.0;
          return Transform.translate(offset: Offset(shake, 0), child: child);
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2044), Color(0xFF0A0C1B)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _BarGlyph(),
                    const SizedBox(height: 28),
                    const Text(
                      'Gravity Fintracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _checking
                          ? 'Checking device security...'
                          : (_errorMessage ?? 'Verify your identity to continue'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _errorMessage != null ? const Color(0xFFEA4335) : Colors.white60,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (!_checking)
                      GestureDetector(
                        onTap: _attemptUnlock,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final glow = 0.15 + (_pulseController.value * 0.15);
                            return Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4285F4).withOpacity(0.12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4285F4).withOpacity(glow),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: _authenticating
                                  ? const Padding(
                                      padding: EdgeInsets.all(28),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF4285F4),
                                      ),
                                    )
                                  : Icon(
                                      isBiometric ? Symbols.fingerprint : Symbols.lock,
                                      color: const Color(0xFF4285F4),
                                      size: 36,
                                      fill: 1,
                                    ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!_checking && !_authenticating)
                      Text(
                        isBiometric ? 'Tap to unlock' : 'Tap to enter PIN',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _shakeOffset(double t) {
    // Decaying sine wave for a natural "denied" shake.
    return 10 * (1 - t) * (t < 0.5 ? 1 : -1) * (1 - (2 * (t - 0.5)).abs());
  }
}

class _BarGlyph extends StatelessWidget {
  const _BarGlyph();

  @override
  Widget build(BuildContext context) {
    Widget bar(double height, Color color) => Container(
          width: 12,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bar(18, const Color(0xFFEA4335)),
        bar(28, const Color(0xFFFBBC05)),
        bar(38, const Color(0xFF34A853)),
        bar(48, const Color(0xFF4285F4)),
      ],
    );
  }
}
