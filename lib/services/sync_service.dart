import 'dart:convert';
import 'dart:math';
import 'package:fintracker/config/constants.dart';
import 'package:fintracker/config/strings.dart';
import 'package:fintracker/events.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:pqcrypto/pqcrypto.dart';
import 'package:cryptography/cryptography.dart' hide Hmac;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hybrid Post-Quantum E2E Encrypted Sync Service
///
/// Encryption Architecture (v3 — Hybrid Post-Quantum KEM-DEM):
///
/// 1. ML-KEM-768 (FIPS 203) post-quantum key encapsulation
///    - Provides IND-CCA2 security against quantum adversaries
///    - Each snapshot uses a fresh ephemeral encapsulation
///
/// 2. X25519 classical ECDH
///    - Combines with ML-KEM for hybrid security as recommended by NIST
///    - Compromise of either X25519 or ML-KEM alone is insufficient
///
/// 3. AES-256-GCM authenticated encryption
///    - Quantum-tolerant symmetric cipher against Grover's algorithm
///
/// 4. HKDF-SHA512 key derivation
///    - Derives a per-snapshot AES key from the combined X25519 + ML-KEM secrets
///
/// 5. Versioned ciphertext format for forward/backward compatibility:
///    `v3:<x25519_ephemeral_pk_b64>:<mlkem_ct_b64>:<salt_b64>:<iv_b64>:<ciphertext_b64>`
///
/// The server (Supabase) stores only ciphertext — zero-knowledge architecture.
///
/// To activate: Set Supabase credentials in constants.dart and set enableSync = true
/// Wrapped long-term hybrid key pair held in secure storage.
class _PqKeySet {
  final Uint8List x25519Public;
  final Uint8List x25519Secret;
  final Uint8List mlkemPublic;
  final Uint8List mlkemSecret;
  final DateTime createdAt;

  _PqKeySet(this.x25519Public, this.x25519Secret, this.mlkemPublic, this.mlkemSecret, this.createdAt);
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _masterKeyStorageKey = AppConstants.syncMasterKeyStorageKey;
  static const String _pqKeysStorageKey = AppConstants.pqKeyStorageKey;
  static const String _pqCipherVersion = AppConstants.pqCipherVersion;
  static const String _pqHybridHkdfInfo = AppConstants.pqHybridHkdfInfo;
  static const String _pqKeyWrapHkdfInfo = AppConstants.pqKeyWrapHkdfInfo;
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 32; // 256-bit salt
  static const int _ivLength = 16; // 128-bit IV for AES

  bool _isInitialized = false;

  bool get isEnabled => AppConstants.enableSync;
  bool get isInitialized => _isInitialized;

  bool get isAuthenticated {
    if (!isEnabled || !_isInitialized) return false;
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (e) {
      debugPrint('Supabase session check failed: $e');
      return false;
    }
  }

  // CSPRNG
  final Random _secureRandom = Random.secure();

  Uint8List _generateSecureBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _secureRandom.nextInt(256)),
    );
  }

  // HKDF-SHA512 key derivation (RFC 5869)
  Uint8List _hkdfExpand(Uint8List prk, Uint8List info, int length) {
    const int hashLen = 64; // SHA-512 output
    final int n = (length / hashLen).ceil();
    Uint8List okm = Uint8List(0);
    Uint8List t = Uint8List(0);
    for (int i = 1; i <= n; i++) {
      final hmacSha512 = Hmac(sha512, prk);
      final input = Uint8List.fromList([...t, ...info, i & 0xFF]);
      t = Uint8List.fromList(hmacSha512.convert(input).bytes);
      okm = Uint8List.fromList([...okm, ...t]);
    }
    return Uint8List.fromList(okm.sublist(0, length));
  }

  Uint8List _hkdfDerive(Uint8List masterKey, Uint8List salt, {String infoString = AppConstants.syncHkdfInfo}) {
    // Extract: PRK = HMAC-SHA512(salt, masterKey)
    final hmacSha512 = Hmac(sha512, salt);
    final Uint8List prk = Uint8List.fromList(hmacSha512.convert(masterKey).bytes);

    // Expand: derive 256-bit key
    final Uint8List info = Uint8List.fromList(utf8.encode(infoString));
    return _hkdfExpand(prk, info, _keyLength);
  }

  // Master key management
  Future<Uint8List?> _getMasterKey() async {
    final String? stored = await _secureStorage.read(key: _masterKeyStorageKey);
    if (stored == null) return null;
    // Legacy unsalted keys have no separator; modern format is salt:key.
    if (stored.contains(':')) {
      final parts = stored.split(':');
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        return base64Decode(parts[1]);
      }
      return null;
    }
    if (stored.isNotEmpty) return base64Decode(stored);
    return null;
  }

  Future<void> _wrapAndStorePqKeys(Uint8List masterKey, _PqKeySet keys) async {
    final keyMap = {
      'x25519Public': base64Encode(keys.x25519Public),
      'x25519Secret': base64Encode(keys.x25519Secret),
      'mlkemPublic': base64Encode(keys.mlkemPublic),
      'mlkemSecret': base64Encode(keys.mlkemSecret),
      'createdAt': keys.createdAt.toIso8601String(),
    };
    final jsonStr = jsonEncode(keyMap);
    final wrapSalt = _generateSecureBytes(_saltLength);
    final wrapIv = encrypt.IV(_generateSecureBytes(_ivLength));
    final wrapKey = _hkdfDerive(masterKey, wrapSalt, infoString: _pqKeyWrapHkdfInfo);
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(wrapKey), mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(jsonStr, iv: wrapIv);
    await _secureStorage.write(
      key: _pqKeysStorageKey,
      value: '${base64Encode(wrapSalt)}:${wrapIv.base64}:${encrypted.base64}',
    );
  }

  Future<_PqKeySet?> _unwrapPqKeys(Uint8List masterKey) async {
    final String? stored = await _secureStorage.read(key: _pqKeysStorageKey);
    if (stored == null) return null;
    final parts = stored.split(':');
    if (parts.length != 3) return null;
    final wrapSalt = base64Decode(parts[0]);
    final wrapIv = encrypt.IV.fromBase64(parts[1]);
    final wrapKey = _hkdfDerive(masterKey, wrapSalt, infoString: _pqKeyWrapHkdfInfo);
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(wrapKey), mode: encrypt.AESMode.gcm));
    try {
      final jsonStr = encrypter.decrypt64(parts[2], iv: wrapIv);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _PqKeySet(
        base64Decode(map['x25519Public'] as String),
        base64Decode(map['x25519Secret'] as String),
        base64Decode(map['mlkemPublic'] as String),
        base64Decode(map['mlkemSecret'] as String),
        DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List _pbkdf2Sha512(
    Uint8List password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha512, password);
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

  Future<void> setEncryptionKey(String passphrase) async {
    // Derive master key from passphrase using PBKDF2-HMAC-SHA512.
    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    final salt = _generateSecureBytes(_saltLength);
    final masterKey = _pbkdf2Sha512(passphraseBytes, salt, AppConstants.syncPbkdf2Iterations, _keyLength);
    await _secureStorage.write(
      key: _masterKeyStorageKey,
      value: '${base64Encode(salt)}:${base64Encode(masterKey)}',
    );

    // Generate long-term hybrid key pair: ML-KEM-768 (PQ) + X25519 (classical)
    final kem = PqcKem.kyber768;
    final (mlkemPublic, mlkemSecret) = kem.generateKeyPair();

    final x25519 = X25519();
    final xKeyPair = await x25519.newKeyPair();
    final xKeyData = await xKeyPair.extract();
    final x25519Secret = Uint8List.fromList(xKeyData.bytes);
    final x25519Public = Uint8List.fromList((await xKeyPair.extractPublicKey()).bytes);

    await _wrapAndStorePqKeys(
      masterKey,
      _PqKeySet(x25519Public, x25519Secret, mlkemPublic, mlkemSecret, DateTime.now()),
    );
  }

  Future<bool> hasEncryptionKey() async {
    return await _secureStorage.read(key: _masterKeyStorageKey) != null;
  }

  Future<void> initialize() async {
    if (!isEnabled || _isInitialized) return;
    try {
      const url = AppConstants.supabaseUrl;
      final key = AppConstants.supabasePublishableKey.isNotEmpty
          ? AppConstants.supabasePublishableKey
          : AppConstants.supabaseAnonKey;
      if (url.isEmpty || key.isEmpty) {
        debugPrint('Supabase URL/key not set. Sync disabled.');
        return;
      }
      await Supabase.initialize(url: url, publishableKey: key);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Supabase init failed: $e');
      _isInitialized = false;
    }
  }

  // Encrypt with hybrid post-quantum KEM-DEM: X25519 + ML-KEM-768 + AES-256-GCM
  Future<String> encryptData(String plainText) async {
    final masterKey = await _getMasterKey();
    if (masterKey == null) throw Exception('Encryption key not set. Run setEncryptionKey first.');
    final keys = await _unwrapPqKeys(masterKey);
    if (keys == null) throw Exception('Encryption keys not initialized. Run setEncryptionKey first.');

    // X25519 ephemeral ECDH
    final x25519 = X25519();
    final ephemeralKeyPair = await x25519.newKeyPair();
    final x25519Public = Uint8List.fromList((await ephemeralKeyPair.extractPublicKey()).bytes);

    final remotePublic = SimplePublicKey(keys.x25519Public, type: KeyPairType.x25519);
    final xSharedKey = await x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: remotePublic,
    );
    final xShared = Uint8List.fromList(await xSharedKey.extractBytes());

    // ML-KEM-768 encapsulation
    final kem = PqcKem.kyber768;
    final (mlkemCt, mlkemShared) = kem.encapsulate(keys.mlkemPublic);

    // Combine classical and post-quantum shared secrets
    final hybridSecret = Uint8List(64);
    hybridSecret.setAll(0, xShared);
    hybridSecret.setAll(32, mlkemShared);

    // Generate unique salt and IV per encryption
    final salt = _generateSecureBytes(_saltLength);
    final iv = encrypt.IV(_generateSecureBytes(_ivLength));

    // Derive unique AES key via HKDF-SHA512
    final sessionKey = _hkdfDerive(hybridSecret, salt, infoString: _pqHybridHkdfInfo);
    final key = encrypt.Key(sessionKey);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Versioned format: v3:<x25519_pk>:<mlkem_ct>:<salt>:<iv>:<ciphertext>
    return '$_pqCipherVersion:${base64Encode(x25519Public)}:${base64Encode(mlkemCt)}:${base64Encode(salt)}:${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptData(String cipherText) async {
    final masterKey = await _getMasterKey();
    if (masterKey == null) throw Exception('Encryption key not set');

    final parts = cipherText.split(':');

    if (parts.length == 6 && parts[0] == _pqCipherVersion) {
      // v3 format: hybrid post-quantum KEM-DEM
      final ephemeralPublic = base64Decode(parts[1]);
      final mlkemCt = base64Decode(parts[2]);
      final salt = base64Decode(parts[3]);
      final iv = encrypt.IV.fromBase64(parts[4]);
      final aesCt = parts[5];

      final keys = await _unwrapPqKeys(masterKey);
      if (keys == null) throw Exception('Encryption keys not initialized');

      // X25519 ECDH using long-term secret and ephemeral public key
      final x25519 = X25519();
      final xPublicKey = SimplePublicKey(keys.x25519Public, type: KeyPairType.x25519);
      final xKeyPair = SimpleKeyPairData(
        keys.x25519Secret,
        publicKey: xPublicKey,
        type: KeyPairType.x25519,
      );
      final ephemeralPublicKey = SimplePublicKey(ephemeralPublic, type: KeyPairType.x25519);
      final xSharedKey = await x25519.sharedSecretKey(
        keyPair: xKeyPair,
        remotePublicKey: ephemeralPublicKey,
      );
      final xShared = Uint8List.fromList(await xSharedKey.extractBytes());

      // ML-KEM-768 decapsulation
      final kem = PqcKem.kyber768;
      final mlkemShared = kem.decapsulate(keys.mlkemSecret, mlkemCt);

      final hybridSecret = Uint8List(64);
      hybridSecret.setAll(0, xShared);
      hybridSecret.setAll(32, mlkemShared);

      final sessionKey = _hkdfDerive(hybridSecret, Uint8List.fromList(salt), infoString: _pqHybridHkdfInfo);
      final key = encrypt.Key(sessionKey);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      return encrypter.decrypt64(aesCt, iv: iv);
    } else if (parts.length == 4 && parts[0] == AppConstants.syncCipherVersion) {
      // v2 format: quantum-hardened
      final salt = base64Decode(parts[1]);
      final iv = encrypt.IV.fromBase64(parts[2]);
      final sessionKey = _hkdfDerive(masterKey, Uint8List.fromList(salt));
      final key = encrypt.Key(sessionKey);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      return encrypter.decrypt64(parts[3], iv: iv);
    } else if (parts.length == 2) {
      // v1 legacy format (backward compat)
      final iv = encrypt.IV.fromBase64(parts[0]);
      final key = encrypt.Key(masterKey);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    }

    throw Exception('Invalid ciphertext format');
  }

  // Sync operations (stub — activate with Supabase credentials)
  Future<Map<String, dynamic>> exportEncryptedSnapshot() async {
    if (!isEnabled) throw Exception('Sync not enabled');

    final db = await getDBInstance();
    final List<dynamic> accounts = await db.query('accounts');
    final List<dynamic> categories = await db.query('categories');
    final List<dynamic> payments = await db.query('payments');
    final List<dynamic> recurring = await db.query('recurring_transactions');
    final List<dynamic> savingsGoals = await db.query('savings_goals');
    final List<dynamic> rules = await db.query('rules');

    final Map<String, dynamic> snapshot = {
      'accounts': accounts,
      'categories': categories,
      'payments': payments,
      'recurring_transactions': recurring,
      'savings_goals': savingsGoals,
      'rules': rules,
      'timestamp': DateTime.now().toIso8601String(),
      'version': AppConstants.dbVersion,
      'encryption': Strings.encryptionStandard,
    };

    final String plainJson = jsonEncode(snapshot);
    final String encrypted = await encryptData(plainJson);

    return {
      'encrypted_data': encrypted,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importEncryptedSnapshot(String encryptedData) async {
    if (!isEnabled) throw Exception('Sync not enabled');

    final String plainJson = await decryptData(encryptedData);
    final Map<String, dynamic> snapshot = jsonDecode(plainJson);

    final db = await getDBInstance();
    await db.transaction((txn) async {
      await txn.delete('rules');
      await txn.delete('savings_goals');
      await txn.delete('payments');
      await txn.delete('recurring_transactions');
      await txn.delete('categories');
      await txn.delete('accounts');

      final Map<int, int> accountsMap = {};
      final Map<int, int> categoriesMap = {};

      final List<dynamic> categories = (snapshot['categories'] ?? []);
      final List<dynamic> accounts = (snapshot['accounts'] ?? []);
      final List<dynamic> payments = (snapshot['payments'] ?? []);
      final List<dynamic> recurring = (snapshot['recurring_transactions'] ?? []);
      final List<dynamic> savingsGoals = (snapshot['savings_goals'] ?? []);
      final List<dynamic> rules = (snapshot['rules'] ?? []);

      for (final Map<String, dynamic> category in categories.cast<Map<String, dynamic>>()) {
        final int oldId = category['id'] ?? 0;
        category.remove('id');
        final int newId = await txn.insert('categories', category);
        categoriesMap[oldId] = newId;
      }

      for (final Map<String, dynamic> account in accounts.cast<Map<String, dynamic>>()) {
        final int oldId = account['id'] ?? 0;
        account.remove('id');
        final int newId = await txn.insert('accounts', account);
        accountsMap[oldId] = newId;
      }

      for (final Map<String, dynamic> payment in payments.cast<Map<String, dynamic>>()) {
        payment.remove('id');
        final int? accountId = accountsMap[payment['account']];
        final int? categoryId = categoriesMap[payment['category']];
        if (accountId == null || categoryId == null) continue;
        payment['account'] = accountId;
        payment['category'] = categoryId;
        await txn.insert('payments', payment);
      }

      for (final Map<String, dynamic> rec in recurring.cast<Map<String, dynamic>>()) {
        rec.remove('id');
        final int? accountId = accountsMap[rec['account']];
        final int? categoryId = categoriesMap[rec['category']];
        if (accountId == null || categoryId == null) continue;
        rec['account'] = accountId;
        rec['category'] = categoryId;
        await txn.insert('recurring_transactions', rec);
      }

      for (final Map<String, dynamic> goal in savingsGoals.cast<Map<String, dynamic>>()) {
        goal.remove('id');
        final accountId = goal['account'];
        if (accountId != null) {
          goal['account'] = accountsMap[accountId];
        }
        await txn.insert('savings_goals', goal);
      }

      for (final Map<String, dynamic> rule in rules.cast<Map<String, dynamic>>()) {
        rule.remove('id');
        _remapRuleId(rule, 'sourceAccount', accountsMap);
        _remapRuleId(rule, 'targetAccount', accountsMap);
        _remapRuleId(rule, 'sourceCategory', categoriesMap);
        _remapRuleId(rule, 'targetCategory', categoriesMap);
        await txn.insert('rules', rule);
      }
    });

    globalEvent.emit('payment_update');
    globalEvent.emit('account_update');
    globalEvent.emit('category_update');
    globalEvent.emit('recurring_update');
    globalEvent.emit('savings_goal_update');
    globalEvent.emit('rule_update');
  }

  void _remapRuleId(Map<String, dynamic> rule, String field, Map<int, int> idMap) {
    final id = rule[field];
    if (id != null && idMap.containsKey(id)) {
      rule[field] = idMap[id];
    }
  }

  // Supabase sync real implementation
  Future<void> signIn({required String email, required String password}) async {
    if (!isEnabled) {
      debugPrint('Sync not enabled. Configure Supabase in constants.dart');
      return;
    }
    await initialize();
    if (!isInitialized) throw Exception('Sync not initialized');
    await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    if (!isEnabled) {
      debugPrint('Sync not enabled. Configure Supabase in constants.dart');
      return;
    }
    await initialize();
    if (!isInitialized) throw Exception('Sync not initialized');
    await Supabase.instance.client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    if (!isEnabled) {
      debugPrint('Sync not enabled. Configure Supabase in constants.dart');
      return;
    }
    await initialize();
    if (!isInitialized) return;
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> pushToCloud() async {
    if (!isEnabled || !isAuthenticated) return;
    try {
      final snapshot = await exportEncryptedSnapshot();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Upsert into Supabase (assumes a sync table exists with user_id, encrypted_data, timestamp)
      await Supabase.instance.client.from(AppConstants.syncTableName).upsert({
        AppConstants.syncUserIdColumn: userId,
        AppConstants.syncEncryptedDataColumn: snapshot['encrypted_data'],
        AppConstants.syncUpdatedAtColumn: snapshot['timestamp'],
      });

      debugPrint('Push to cloud complete: ${snapshot["timestamp"]}');
    } catch (e) {
      debugPrint('Push to cloud failed: $e');
    }
  }

  Future<void> pullFromCloud() async {
    if (!isEnabled || !isAuthenticated) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from(AppConstants.syncTableName)
          .select(AppConstants.syncSelectColumns)
          .eq(AppConstants.syncUserIdColumn, userId)
          .maybeSingle();

      if (response != null && response['encrypted_data'] != null) {
        await importEncryptedSnapshot(response['encrypted_data'] as String);
        debugPrint('Pull from cloud complete: ${response["updated_at"]}');
      } else {
        debugPrint('No cloud snapshot found.');
      }
    } catch (e) {
      debugPrint('Pull from cloud failed: $e');
    }
  }

  Future<SyncStatus> getSyncStatus() async {
    if (!isEnabled) return SyncStatus.disabled;
    if (!isAuthenticated) return SyncStatus.notAuthenticated;
    return SyncStatus.synced;
  }
}

enum SyncStatus {
  disabled,
  notAuthenticated,
  syncing,
  synced,
  error,
}
