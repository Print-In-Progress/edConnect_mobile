import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/utils/device_manager.dart';
import 'double_ratchet.dart'; // Your Double Ratchet class
import 'signal_key_manager.dart'; // Your Signal Key Manager class
import 'x3dh_key_exchange.dart'; // Your X3DH Key Exchange class

class SessionManager {
  final storage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SignalKeyManager signalKeyManager = SignalKeyManager();
  final X3DHKeyExchange x3dhKeyExchange = X3DHKeyExchange();
  final Map<String, Map<String, DoubleRatchet>> activeSessions = {};

  Future<void> initiateSession(
      AppUser currentUser,
      String recipientId,
      List<int> recipientPublicIdentityKey,
      Map<String, List<int>> recipientSignedPublicPreKey,
      List<Map<String, dynamic>> recipientOneTimePreKeys,
      String recipientDeviceId,
      String org,
      String userCollection,
      String messageCollection) async {
    final String currentDeviceId = await DeviceManager().getUniqueDeviceId();
    print(
        'Initiating session for user: $recipientId with device: $recipientDeviceId using device: $currentDeviceId');

    await x3dhKeyExchange.initiateKeyExchange(
        currentUser,
        recipientPublicIdentityKey,
        recipientSignedPublicPreKey,
        recipientOneTimePreKeys,
        org);
    print('Shared secret: ${x3dhKeyExchange.sharedSecret}');
    final doubleRatchet = DoubleRatchet();
    await doubleRatchet.initialize(x3dhKeyExchange.sharedSecret);
    print('Double ratchet complete. Root key: ${doubleRatchet.rootKey}');

    // Check if the recipientId exists in activeSessions
    if (!activeSessions.containsKey(recipientId)) {
      activeSessions[recipientId] = {};
    }

    // Add the recipientDeviceId and DoubleRatchet instance
    activeSessions[recipientId]![recipientDeviceId] = doubleRatchet;
    print('Active Sessions updated. Active sessions: $activeSessions');

    await _storeChainKeys(
        currentUser.id, recipientId, recipientDeviceId, doubleRatchet);
    print('Chain keys stored');
    await _sendInitialMessage(
      currentUser.id,
      recipientId,
      recipientDeviceId,
      currentDeviceId,
      messageCollection,
      x3dhKeyExchange.ephemeralPublicKey,
      x3dhKeyExchange.usedOneTimePreKeyId,
    );
    print('Initial message sent');
  }

  Future<void> _sendInitialMessage(
      String currentUserId,
      String otherUserId,
      String deviceId,
      String currentDeviceId,
      String messageCollection,
      SimplePublicKey ephemeralPublicKey,
      int? usedOneTimePreKeyId) async {
    final initialMessage = {
      'type': 'x3dh_init',
      'sender': currentUserId,
      'recipient': otherUserId,
      'recipientDeviceId': deviceId,
      'senderDeviceId': currentDeviceId,
      'ephemeralPublicKey': base64Encode(ephemeralPublicKey.bytes),
      'usedOneTimePreKeyId': usedOneTimePreKeyId,
    };

    await _firestore.collection(messageCollection).add(initialMessage);
  }

  Future<Map<String, dynamic>?> checkForInitialMessage(String currentUserId,
      String otherUserId, String messageCollection) async {
    final querySnapshot = await _firestore
        .collection(messageCollection)
        .where('type', isEqualTo: 'x3dh_init')
        .where('recipient', isEqualTo: currentUserId)
        .where('sender', isEqualTo: otherUserId)
        .where('recipientDeviceId',
            isEqualTo: await DeviceManager().getUniqueDeviceId())
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  }

  Future<void> processInitialMessage(
      AppUser currentUser,
      AppUser otherUser,
      String org,
      Map<String, dynamic> initialMessage,
      String messageCollection) async {
    final ephemeralPublicKeyBytes =
        base64Decode(initialMessage['ephemeralPublicKey']);
    final initiatorIdentityPublicKeyBytes =
        List<int>.from(otherUser.publicIdentityKey!);
    final usedOneTimePreKeyId = initialMessage['usedOneTimePreKeyId'];

    final ephemeralPublicKey =
        SimplePublicKey(ephemeralPublicKeyBytes, type: KeyPairType.x25519);
    final initiatorIdentityPublicKey = SimplePublicKey(
        initiatorIdentityPublicKeyBytes,
        type: KeyPairType.x25519);

    final sharedSecret = await x3dhKeyExchange.performX3DHAsRecipient(
      currentUser,
      otherUser,
      org,
      ephemeralPublicKey,
      initiatorIdentityPublicKey,
      usedOneTimePreKeyId,
    );
    final String currentDeviceId = await DeviceManager().getUniqueDeviceId();
    final doubleRatchet = DoubleRatchet();
    await doubleRatchet.initialize(sharedSecret);
    // Check if the recipientId exists in activeSessions
    if (!activeSessions.containsKey(otherUser.id)) {
      activeSessions[otherUser.id] = {};
    }

    activeSessions[otherUser.id]![initialMessage['senderDeviceId']] =
        doubleRatchet;
    await _storeChainKeys(currentUser.id, otherUser.id,
        initialMessage['senderDeviceId'], doubleRatchet);

    // Delete the processed initial message
    final querySnapshot = await _firestore
        .collection(messageCollection)
        .where('type', isEqualTo: 'x3dh_init')
        .where('recipient', isEqualTo: currentUser.id)
        .where('sender', isEqualTo: otherUser.id)
        .where('recipientDeviceId', isEqualTo: currentDeviceId)
        .where('senderDeviceId', isEqualTo: initialMessage['senderDeviceId'])
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _storeChainKeys(String currentUserId, String otherUserId,
      String recipientDeviceId, DoubleRatchet ratchet) async {
    // Serialize session data
    final sessionData = jsonEncode({
      'rootKey': ratchet.rootKey,
      'sendingChainKey': ratchet.sendingChainKey,
      'receivingChainKey': ratchet.receivingChainKey,
      'skippedMessageKeys': ratchet.skippedMessageKeys,
    });

    // Store the session in secure storage
    await storage.write(
        key: 'session_${otherUserId}_$recipientDeviceId', value: sessionData);
  }

  Future<bool> hasExistingSession(
      String recipientId, String recipientDeviceId) async {
    // Check if session exists for this recipient
    String? sessionData =
        await storage.read(key: 'session_${recipientId}_$recipientDeviceId');
    return sessionData != null;
  }

  Future<void> resumeSession(
      String recipientId, String recipientDeviceId) async {
    // Load the session data from secure storage or Firestore
    String? sessionData =
        await storage.read(key: 'session_${recipientId}_$recipientDeviceId');
    print('Session data: $sessionData');
    if (sessionData == null) {
      throw Exception('No existing session found');
    }

    // Deserialize the session data
    final session = jsonDecode(sessionData);

    // Reinitialize the DoubleRatchet with the stored keys and state
    final ratchet = DoubleRatchet();
    await ratchet
        .initialize(Uint8List.fromList(List<int>.from(session['rootKey'])));
    ratchet.sendingChainKey =
        Uint8List.fromList(List<int>.from(session['sendingChainKey']));
    ratchet.receivingChainKey =
        Uint8List.fromList(List<int>.from(session['receivingChainKey']));

    // Load skipped message keys if any
    ratchet.skippedMessageKeys =
        Map<int, Uint8List>.from(session['skippedMessageKeys']);

    // Store the ratchet in active sessions
    // Check if the recipientId exists in activeSessions
    if (!activeSessions.containsKey(recipientId)) {
      activeSessions[recipientId] = {};
    }

    activeSessions[recipientId]![recipientDeviceId] = ratchet;
  }
}
