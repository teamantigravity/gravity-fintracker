import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure PIN storage and verification.
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _pinHashKey = 'fintracker_pin_hash';

  Future<void> setPin(String pin) async {
    if (pin.isEmpty) throw ArgumentError('PIN cannot be empty');
    final hash = _hash(pin);
    await _secureStorage.write(key: _pinHashKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinHashKey);
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  Future<bool> hasPin() async {
    final stored = await _secureStorage.read(key: _pinHashKey);
    return stored != null && stored.isNotEmpty;
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinHashKey);
  }

  String _hash(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
