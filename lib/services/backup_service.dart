import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:fintracker/helpers/db.helper.dart' as db;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Password-protected, privacy-first backup.
/// No cloud, no analytics — the encrypted file is stored locally.
class BackupService {
  static const String _version = 'v2';
  static const String _legacyVersion = 'v1';
  static const int _keyLength = 32;
  static const int _saltLength = 32;
  static const int _ivLength = 16;
  static const int _iterations = 100000;
  static final Random _secureRandom = Random.secure();

  static Uint8List _randomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
  }

  static encrypt.Key _deriveKeyV1(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, salt);
    final digest = hmac.convert(passwordBytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  static Uint8List _pbkdf2Sha256(
    Uint8List password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final saltWithI = Uint8List(salt.length + 4);
    saltWithI.setRange(0, salt.length, salt);
    saltWithI[salt.length] = 0;
    saltWithI[salt.length + 1] = 0;
    saltWithI[salt.length + 2] = 0;
    saltWithI[salt.length + 3] = 1;

    Digest digest = hmac.convert(saltWithI);
    Uint8List last = Uint8List.fromList(digest.bytes);
    Uint8List result = Uint8List.fromList(last);

    for (int i = 1; i < iterations; i++) {
      digest = hmac.convert(last);
      last = Uint8List.fromList(digest.bytes);
      for (int j = 0; j < result.length; j++) {
        result[j] ^= last[j];
      }
    }

    return Uint8List.fromList(result.sublist(0, keyLength));
  }

  static encrypt.Key _deriveKeyV2(String password, Uint8List salt) {
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final key = _pbkdf2Sha256(passwordBytes, salt, _iterations, _keyLength);
    return encrypt.Key(key);
  }

  static Future<String> encryptWithPassword(String plainText, String password) async {
    final salt = _randomBytes(_saltLength);
    final iv = encrypt.IV(_randomBytes(_ivLength));
    final key = _deriveKeyV2(password, salt);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '$_version:${base64Encode(salt)}:${iv.base64}:${encrypted.base64}';
  }

  static Future<String> decryptWithPassword(String cipherText, String password) async {
    final parts = cipherText.split(':');
    if (parts.length != 4) {
      throw const FormatException('Invalid encrypted backup');
    }
    final version = parts[0];
    final salt = base64Decode(parts[1]);
    final iv = encrypt.IV.fromBase64(parts[2]);
    final encrypt.Key key;
    if (version == _version) {
      key = _deriveKeyV2(password, salt);
    } else if (version == _legacyVersion) {
      key = _deriveKeyV1(password, salt);
    } else {
      throw const FormatException('Invalid encrypted backup');
    }
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    return encrypter.decrypt64(parts[3], iv: iv);
  }

  static Future<String> exportEncrypted(String password, {String? directory, String? filePath}) async {
    if (kIsWeb) throw UnsupportedError('Encrypted backups are not supported on web.');
    final database = await db.getDBInstance();
    final accounts = await database.query('accounts');
    final categories = await database.query('categories');
    final payments = await database.query('payments');
    final recurring = await database.query('recurring_transactions');
    final savingsGoals = await database.query('savings_goals');
    final rules = await database.query('rules');

    final data = {
      'accounts': accounts,
      'categories': categories,
      'payments': payments,
      'recurring_transactions': recurring,
      'savings_goals': savingsGoals,
      'rules': rules,
      'timestamp': DateTime.now().toIso8601String(),
      'version': 4,
    };

    final encrypted = await encryptWithPassword(jsonEncode(data), password);

    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(encrypted);
      return file.path;
    }

    final path = await db.getExternalDocumentPath(fallbackPath: directory);
    final name = 'fintracker-encrypted-backup-${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('$path/$name');
    await file.writeAsString(encrypted);
    return file.path;
  }

  static Future<void> importEncrypted(String filePath, String password) async {
    if (kIsWeb) throw UnsupportedError('Encrypted backups are not supported on web.');
    final file = File(filePath);
    final encrypted = await file.readAsString();
    final plain = await decryptWithPassword(encrypted, password);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(join(tempDir.path, 'fintracker_restore_${DateTime.now().millisecondsSinceEpoch}.json'));
    await tempFile.writeAsString(plain);
    try {
      await db.import(tempFile.path);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}
