import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pqcrypto/pqcrypto.dart';
import 'package:cryptography/cryptography.dart';

void main() {
  group('ML-KEM-768 primitive', () {
    test('encapsulate/decapsulate shared secret matches', () {
      final kem = PqcKem.kyber768;
      final (pk, sk) = kem.generateKeyPair();
      final (ct, ss1) = kem.encapsulate(pk);
      final ss2 = kem.decapsulate(sk, ct);
      expect(ss1, equals(ss2));
    });

    test('different encapsulations produce different ciphertexts', () {
      final kem = PqcKem.kyber768;
      final (pk, _) = kem.generateKeyPair();
      final (ct1, _) = kem.encapsulate(pk);
      final (ct2, _) = kem.encapsulate(pk);
      expect(ct1, isNot(equals(ct2)));
    });
  });

  group('X25519 primitive', () {
    test('shared secret is symmetric', () async {
      final algo = X25519();
      final alice = await algo.newKeyPair();
      final bob = await algo.newKeyPair();
      final alicePub = await alice.extractPublicKey();
      final bobPub = await bob.extractPublicKey();
      final aliceShared = await algo.sharedSecretKey(
        keyPair: alice,
        remotePublicKey: bobPub,
      );
      final bobShared = await algo.sharedSecretKey(
        keyPair: bob,
        remotePublicKey: alicePub,
      );
      expect(
        await aliceShared.extractBytes(),
        equals(await bobShared.extractBytes()),
      );
    });
  });
}
