import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure PIN storage and verification.
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinHashKey = 'fintracker_pin_hash';
  static const int _pbkdf2Iterations = 100000;
  static const int _keyLength = 32;
  static final Random _secureRandom = Random.secure();

  Future<void> setPin(String pin) async {
    if (pin.isEmpty) throw ArgumentError('PIN cannot be empty');
    final salt = _randomBytes(32);
    final hash = _pbkdf2Hash(pin, salt);
    await _secureStorage.write(key: _pinHashKey, value: 'v2:${base64Encode(salt)}:$hash');
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final stored = await _secureStorage.read(key: _pinHashKey);
      if (stored == null || stored.isEmpty) return false;

      if (stored.startsWith('v2:')) {
        final parts = stored.split(':');
        if (parts.length == 3) {
          final salt = base64Decode(parts[1]);
          return _secureCompare(_pbkdf2Hash(pin, salt), parts[2]);
        }
        return false;
      }

      final parts = stored.split(':');
      if (parts.length == 2) {
        final salt = base64Decode(parts[0]);
        return _secureCompare(_hash(pin, salt), parts[1]);
      }

      // Legacy unsalted SHA-256 fallback
      return _secureCompare(stored, _legacyHash(pin));
    } catch (e) {
      debugPrint('PIN verification error: $e');
      return false;
    }
  }

  Future<bool> hasPin() async {
    try {
      final stored = await _secureStorage.read(key: _pinHashKey);
      return stored != null && stored.isNotEmpty;
    } catch (e) {
      debugPrint('PIN check error: $e');
      return false;
    }
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinHashKey);
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
  }

  String _pbkdf2Hash(String pin, Uint8List salt) {
    final bytes = _pbkdf2Sha256(Uint8List.fromList(utf8.encode(pin)), salt, _pbkdf2Iterations, _keyLength);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _pbkdf2Sha256(Uint8List password, Uint8List salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final saltWithI = Uint8List(salt.length + 4);
    saltWithI.setRange(0, salt.length, salt);
    saltWithI[salt.length] = 0;
    saltWithI[salt.length + 1] = 0;
    saltWithI[salt.length + 2] = 0;
    saltWithI[salt.length + 3] = 1;

    Digest digest = hmac.convert(saltWithI);
    Uint8List last = Uint8List.fromList(digest.bytes);
    final Uint8List result = Uint8List.fromList(last);

    for (int i = 1; i < iterations; i++) {
      digest = hmac.convert(last);
      last = Uint8List.fromList(digest.bytes);
      for (int j = 0; j < result.length; j++) {
        result[j] ^= last[j];
      }
    }

    return Uint8List.fromList(result.sublist(0, keyLength));
  }

  String _hash(String pin, Uint8List salt) {
    final bytes = utf8.encode(pin);
    final hmac = Hmac(sha256, salt);
    return hmac.convert(bytes).toString();
  }

  String _legacyHash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Constant-time string comparison to mitigate timing side-channels.
  bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
