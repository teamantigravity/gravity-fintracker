import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure PIN storage and verification.
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinHashKey = 'fintracker_pin_hash';
  static final Random _secureRandom = Random.secure();

  Future<void> setPin(String pin) async {
    if (pin.isEmpty) throw ArgumentError('PIN cannot be empty');
    final salt = _randomBytes(16);
    final hash = _hash(pin, salt);
    await _secureStorage.write(key: _pinHashKey, value: '${base64Encode(salt)}:$hash');
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final stored = await _secureStorage.read(key: _pinHashKey);
      if (stored == null || stored.isEmpty) return false;

      final parts = stored.split(':');
      if (parts.length == 2) {
        final salt = base64Decode(parts[0]);
        return _hash(pin, salt) == parts[1];
      }

      // Legacy unsalted SHA-256 fallback (setPin now always stores salt)
      return stored == _legacyHash(pin);
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    try {
      final stored = await _secureStorage.read(key: _pinHashKey);
      return stored != null && stored.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinHashKey);
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
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
}
