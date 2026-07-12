import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// What kind of device authentication is available, so the UI can degrade
/// gracefully instead of assuming every device has fingerprint/face hardware.
enum BiometricCapability {
  /// Biometric hardware present AND at least one biometric is enrolled.
  biometric,

  /// No biometric hardware/enrollment, but the device has a secure lock
  /// screen (PIN/pattern/password) that `local_auth` can fall back to.
  deviceCredentialOnly,

  /// Nothing available — no biometric hardware and no lock screen set up.
  /// App Lock cannot be offered at all on this device.
  unavailable,
}

enum AuthResult { success, failed, unavailable, error }

/// Wraps `local_auth` so every call site gets graceful, user-friendly
/// behavior instead of raw PlatformExceptions — critical on devices (e.g.
/// tablets) that lack biometric hardware entirely.
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<BiometricCapability> getCapability() async {
    try {
      final bool hasHardwareAndEnrolled =
          await _auth.canCheckBiometrics && (await _auth.getAvailableBiometrics()).isNotEmpty;
      if (hasHardwareAndEnrolled) return BiometricCapability.biometric;

      final bool deviceSupported = await _auth.isDeviceSupported();
      if (deviceSupported) return BiometricCapability.deviceCredentialOnly;

      return BiometricCapability.unavailable;
    } catch (_) {
      // Any plugin/platform failure while merely probing capability should
      // never crash or block the UI — treat as "not available" and move on.
      return BiometricCapability.unavailable;
    }
  }

  Future<AuthResult> authenticate({required String reason}) async {
    try {
      final bool ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN/pattern/password fallback
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok ? AuthResult.success : AuthResult.failed;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
        case auth_error.notEnrolled:
        case auth_error.passcodeNotSet:
          return AuthResult.unavailable;
        default:
          return AuthResult.error;
      }
    } catch (_) {
      return AuthResult.error;
    }
  }

  /// Friendly, non-technical copy for every outcome — never surface a raw
  /// exception string to the user.
  String friendlyMessage(AuthResult result) {
    switch (result) {
      case AuthResult.success:
        return 'Verified';
      case AuthResult.failed:
        return "That didn't match. Try again.";
      case AuthResult.unavailable:
        return 'No screen lock found on this device. Set a PIN, pattern or biometric in your device settings first.';
      case AuthResult.error:
        return "Couldn't verify your identity right now. Please try again.";
    }
  }
}
