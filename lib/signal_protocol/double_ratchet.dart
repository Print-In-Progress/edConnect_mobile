import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DoubleRatchet {
  final storage = const FlutterSecureStorage();

  // Root, sending, receiving chain keys, and skipped message keys map
  Uint8List rootKey = Uint8List(32);
  Uint8List sendingChainKey = Uint8List(32);
  Uint8List receivingChainKey = Uint8List(32);
  Map<int, Uint8List> skippedMessageKeys = {};

  final hmac = Hmac.sha256(); // For deriving chain and message keys

  // Initialize the ratchet with a shared secret (derived from X3DH key exchange)
  Future<void> initialize(Uint8List sharedSecret) async {
    rootKey = sharedSecret;
    sendingChainKey = Uint8List(32);
    receivingChainKey = Uint8List(32);
    skippedMessageKeys = {};
  }

  // Ratchet forward the symmetric key for sending messages
  Future<Uint8List> ratchetSendingKey() async {
    sendingChainKey = await _deriveChainKey(sendingChainKey);
    return await _deriveMessageKey(sendingChainKey);
  }

  // Ratchet forward the symmetric key for receiving messages
  Future<Uint8List> ratchetReceivingKey() async {
    receivingChainKey = await _deriveChainKey(receivingChainKey);
    return await _deriveMessageKey(receivingChainKey);
  }

  // Handle the Diffie-Hellman ratchet step
  Future<void> dhRatchet(SimpleKeyPair newRemoteDHKey) async {
    final ephemeralKeyPair = await X25519().newKeyPair();
    final sharedSecret = await X25519().sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: await newRemoteDHKey.extractPublicKey(),
    );

    // Extract the bytes from the sharedSecret and use them
    final sharedSecretBytes = await sharedSecret.extractBytes();

    // Update root key and reset sending/receiving chain keys
    rootKey = await _deriveRootKey(rootKey, sharedSecretBytes);
    sendingChainKey = Uint8List(32); // Reset the sending chain
    receivingChainKey = Uint8List(32); // Reset the receiving chain
  }

  // Derive the new root key based on the previous root key and DH shared secret
  Future<Uint8List> _deriveRootKey(
      Uint8List oldRootKey, List<int> dhSharedSecret) async {
    final mac = await hmac.calculateMac(
      oldRootKey + dhSharedSecret,
      secretKey: SecretKey(oldRootKey),
    );
    return Uint8List.fromList(mac.bytes);
  }

  // Derive the next chain key from the current chain key
  Future<Uint8List> _deriveChainKey(Uint8List chainKey) async {
    final mac = await hmac.calculateMac(
      utf8.encode('chain') + chainKey,
      secretKey: SecretKey(chainKey),
    );
    return Uint8List.fromList(mac.bytes);
  }

  // Derive a message key from the current chain key
  Future<Uint8List> _deriveMessageKey(Uint8List chainKey) async {
    final mac = await hmac.calculateMac(
      utf8.encode('message') + chainKey,
      secretKey: SecretKey(chainKey),
    );
    return Uint8List.fromList(mac.bytes);
  }

  // Store skipped message keys for out-of-order messages
  Future<void> storeSkippedMessageKey(
      int messageCounter, Uint8List messageKey) async {
    skippedMessageKeys[messageCounter] = messageKey;
    await storage.write(
        key: 'skippedMessageKey_$messageCounter',
        value: base64Encode(messageKey));
  }

  // Retrieve skipped message keys for out-of-order messages
  Future<Uint8List?> retrieveSkippedMessageKey(int messageCounter) async {
    final storedKey =
        await storage.read(key: 'skippedMessageKey_$messageCounter');
    if (storedKey != null) {
      return Uint8List.fromList(base64Decode(storedKey));
    }
    return skippedMessageKeys[messageCounter];
  }

  // Encrypt a message using AES-GCM with the derived message key
  Future<Uint8List> encryptMessage(
      Uint8List plaintext, Uint8List messageKey) async {
    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(messageKey);

    // Generate a random nonce (12 bytes for AES-GCM)
    final nonce = Uint8List(12);
    final random = Random.secure();
    for (int i = 0; i < 12; i++) {
      nonce[i] = random.nextInt(256);
    }

    // Encrypt the message using AES-GCM, which will generate a MAC automatically
    final secretBox = await aesGcm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Concatenate nonce + ciphertext + MAC (already contained in the SecretBox)
    final encryptedMessage = secretBox.concatenation();

    // Log the encryption details

    return encryptedMessage;
  }

  // Decrypt a message using AES-GCM with the derived message key
  Future<Uint8List> decryptMessage(
      Uint8List encryptedMessage, Uint8List messageKey) async {
    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(messageKey);
    // Parse the concatenated encrypted message (including nonce and MAC)
    final secretBox = SecretBox.fromConcatenation(
      encryptedMessage,
      nonceLength: 12, // Length of nonce
      macLength: 16, // Length of MAC (AES-GCM uses a 16-byte MAC)
    );
    // Decrypt the message using AES-GCM

    final decryptedList = await aesGcm.decrypt(secretBox, secretKey: secretKey);
    // Log the decryption details

    // Convert List<int> to Uint8List before returning
    return Uint8List.fromList(decryptedList);
  }
}
