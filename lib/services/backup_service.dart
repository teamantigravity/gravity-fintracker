import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fintracker/helpers/db.helper.dart' as db;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Password-protected, privacy-first backup.
/// No cloud, no analytics — the encrypted file is stored locally.
class BackupService {
  static const String _version = 'v1';
  static final Random _secureRandom = Random.secure();

  static Uint8List _randomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
  }

  static encrypt.Key _deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, salt);
    final digest = hmac.convert(passwordBytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  static Future<String> encryptWithPassword(String plainText, String password) async {
    final salt = _randomBytes(16);
    final iv = encrypt.IV(_randomBytes(16));
    final key = _deriveKey(password, salt);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '$_version:${base64Encode(salt)}:${iv.base64}:${encrypted.base64}';
  }

  static Future<String> decryptWithPassword(String cipherText, String password) async {
    final parts = cipherText.split(':');
    if (parts.length != 4 || parts[0] != _version) {
      throw const FormatException('Invalid encrypted backup');
    }
    final salt = base64Decode(parts[1]);
    final iv = encrypt.IV.fromBase64(parts[2]);
    final key = _deriveKey(password, salt);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    return encrypter.decrypt64(parts[3], iv: iv);
  }

  static Future<String> exportEncrypted(String password, {String? directory}) async {
    await db.getDBInstance();
    final accounts = await db.database!.query('accounts');
    final categories = await db.database!.query('categories');
    final payments = await db.database!.query('payments');
    final recurring = await db.database!.query('recurring_transactions');

    final data = {
      'accounts': accounts,
      'categories': categories,
      'payments': payments,
      'recurring_transactions': recurring,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final encrypted = await encryptWithPassword(jsonEncode(data), password);
    final path = await db.getExternalDocumentPath(fallbackPath: directory);
    final name = 'fintracker-encrypted-backup-${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('$path/$name');
    await file.writeAsString(encrypted);
    return file.path;
  }

  static Future<void> importEncrypted(String filePath, String password) async {
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
