import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

class SignalKeyManager {
  final storage = const FlutterSecureStorage();
  final firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> generateAndStoreKeys(
      String userId, String org) async {
    // Generate long-term identity key pair
    final identityKeyPair = await X25519().newKeyPair();
    final identityPublicKey = await identityKeyPair.extractPublicKey();

    // Generate signed prekey pair
    final signedPrekeyPair = await X25519().newKeyPair();
    final signedPrekeyPublic = await signedPrekeyPair.extractPublicKey();

    // Sign the signed prekey with the identity key
    final signature = await Ed25519().sign(
      signedPrekeyPublic.bytes,
      keyPair: identityKeyPair,
    );

    // Generate one-time prekeys
    List<Map<String, dynamic>> oneTimePrekeys = [];
    for (int i = 0; i < 20; i++) {
      final oneTimePrekeyPair = await X25519().newKeyPair();
      final oneTimePrekeyPublic = await oneTimePrekeyPair.extractPublicKey();
      oneTimePrekeys.add({
        'prekeyId': i,
        'publicKey': oneTimePrekeyPublic.bytes,
      });

      // Store both public and private one-time prekeys
      await storage.write(
        key: 'oneTimePrekey_${org}_${userId}_$i',
        value: await _encodeKeyPair(oneTimePrekeyPair, oneTimePrekeyPublic),
      );
    }

    // Store both private and public identity and signed prekey pairs
    await storage.write(
      key: 'identityKeyPair_${org}_$userId',
      value: await _encodeKeyPair(identityKeyPair, identityPublicKey),
    );

    await storage.write(
      key: 'signedPrekeyPair_${org}_$userId',
      value: await _encodeKeyPair(signedPrekeyPair, signedPrekeyPublic),
    );

    return {
      'identityPublicKey': identityPublicKey.bytes,
      'signedPrekeyPublic': signedPrekeyPublic.bytes,
      'signature': signature.bytes,
      'oneTimePrekeys': oneTimePrekeys,
    };
  }

  Future<Map<String, dynamic>> generateAndStoreKeysForNewDevice(
      String userId, String org, SimpleKeyPair identityKeyPair) async {
    final identityPublicKey = await identityKeyPair.extractPublicKey();
    // Generate signed prekey pair
    final signedPrekeyPair = await X25519().newKeyPair();
    final signedPrekeyPublic = await signedPrekeyPair.extractPublicKey();

    // Sign the signed prekey with the identity key
    final signature = await Ed25519().sign(
      signedPrekeyPublic.bytes,
      keyPair: identityKeyPair,
    );

    // Generate one-time prekeys
    List<Map<String, dynamic>> oneTimePrekeys = [];
    for (int i = 0; i < 20; i++) {
      final oneTimePrekeyPair = await X25519().newKeyPair();
      final oneTimePrekeyPublic = await oneTimePrekeyPair.extractPublicKey();
      oneTimePrekeys.add({
        'prekeyId': i,
        'publicKey': oneTimePrekeyPublic.bytes,
      });

      // Store both public and private one-time prekeys
      await storage.write(
        key: 'oneTimePrekey_${org}_${userId}_$i',
        value: await _encodeKeyPair(oneTimePrekeyPair, oneTimePrekeyPublic),
      );
    }

    // Store both private and public identity and signed prekey pairs
    await storage.write(
      key: 'identityKeyPair_${org}_$userId',
      value: await _encodeKeyPair(identityKeyPair, identityPublicKey),
    );

    await storage.write(
      key: 'signedPrekeyPair_${org}_$userId',
      value: await _encodeKeyPair(signedPrekeyPair, signedPrekeyPublic),
    );

    return {
      'identityPublicKey': identityPublicKey.bytes,
      'signedPrekeyPublic': signedPrekeyPublic.bytes,
      'signature': signature.bytes,
      'oneTimePrekeys': oneTimePrekeys,
    };
  }

  Future<String> _encodeKeyPair(
      SimpleKeyPair privateKey, SimplePublicKey publicKey) async {
    final privateKeyBytes = await privateKey.extractPrivateKeyBytes();
    final publicKeyBytes = publicKey.bytes;

    return jsonEncode({
      'privateKey': base64Encode(privateKeyBytes),
      'publicKey': base64Encode(publicKeyBytes),
    });
  }

  Future<void> storeScannedIdentityKeyPair(
      String userId, String org, SimpleKeyPair keyPair) async {
    final publicKey = await keyPair.extractPublicKey();
    await storage.write(
      key: 'identityKeyPair_${org}_$userId',
      value: await _encodeKeyPair(keyPair, publicKey),
    );
  }

  Future<SimpleKeyPair> getIdentityKeyPair(String userId, String org) async {
    final encodedKeyPair =
        await storage.read(key: 'identityKeyPair_${org}_$userId');
    if (encodedKeyPair == null) {
      throw Exception('Identity key pair not found.');
    }
    return decodeKeyPair(encodedKeyPair);
  }

  Future<SimpleKeyPair> getSignedPrekeyPair(String userId, String org) async {
    final encodedKeyPair =
        await storage.read(key: 'signedPrekeyPair_${org}_$userId');
    if (encodedKeyPair == null) {
      throw Exception('Signed prekey pair not found.');
    }
    return decodeKeyPair(encodedKeyPair);
  }

  Future<void> markPrekeyAsUsed(String otherUserId, int prekeyId) async {
    await firestore.collection('users').doc(otherUserId).update({
      'oneTimePrekeys': FieldValue.arrayRemove([
        {'prekeyId': prekeyId}
      ])
    });
  }

  Future<SimpleKeyPair> decodeKeyPair(String encodedKeyPair) async {
    final decoded = jsonDecode(encodedKeyPair);
    final privateKeyBytes = base64Decode(decoded['privateKey']);
    final publicKeyBytes = base64Decode(decoded['publicKey']);

    final publicKey = SimplePublicKey(
      Uint8List.fromList(publicKeyBytes),
      type: KeyPairType.x25519,
    );

    return SimpleKeyPairData(
      Uint8List.fromList(privateKeyBytes),
      publicKey: publicKey,
      type: KeyPairType.x25519,
    );
  }

  Future<Map<String, dynamic>> getPublicKeys(String userId, String org) async {
    final identityKeyPair = await getIdentityKeyPair(userId, org);
    final signedPrekeyPair = await getSignedPrekeyPair(userId, org);

    final identityPublicKey = await identityKeyPair.extractPublicKey();
    final signedPrekeyPublic = await signedPrekeyPair.extractPublicKey();

    final signature = await Ed25519().sign(
      signedPrekeyPublic.bytes,
      keyPair: identityKeyPair,
    );

    return {
      'identityPublicKey': identityPublicKey.bytes,
      'signedPrekeyPublic': signedPrekeyPublic.bytes,
      'signature': signature.bytes,
    };
  }

  Future<SimpleKeyPair> getOneTimePrekey(
      String userId, String org, int prekeyId) async {
    final encodedKeyPair =
        await storage.read(key: 'oneTimePrekey_${org}_${userId}_$prekeyId');
    if (encodedKeyPair == null) {
      throw Exception('One-time prekey not found.');
    }
    return decodeKeyPair(encodedKeyPair);
  }
}
