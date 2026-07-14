
import 'package:flutter_test/flutter_test.dart';
import 'package:fintracker/services/sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Quantum Encryption Tests', () {
    test('Set encryption key and check existence', () async {
      final syncService = SyncService();
      await syncService.setEncryptionKey('my_super_secret_quantum_passphrase');
      
      final hasKey = await syncService.hasEncryptionKey();
      expect(hasKey, true);
    });

    test('Encrypt and Decrypt data roundtrip (v2)', () async {
      final syncService = SyncService();
      await syncService.setEncryptionKey('test_passphrase');
      
      const plainText = '{"message": "Hello Quantum World", "balance": 1000000}';
      final encrypted = await syncService.encryptData(plainText);
      
      expect(encrypted.startsWith('v2:'), true, reason: 'Should use v2 quantum format');
      
      final decrypted = await syncService.decryptData(encrypted);
      expect(decrypted, plainText, reason: 'Decrypted data must match original exactly');
    });

    test('Different encryptions yield different ciphertexts (Salt/IV randomness)', () async {
      final syncService = SyncService();
      await syncService.setEncryptionKey('test_passphrase_2');
      
      const plainText = 'Deterministic text';
      final encrypted1 = await syncService.encryptData(plainText);
      final encrypted2 = await syncService.encryptData(plainText);
      
      expect(encrypted1 != encrypted2, true, reason: 'Salts and IVs must ensure uniqueness');
    });
  });
}
