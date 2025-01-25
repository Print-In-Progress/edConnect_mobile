import 'dart:convert';
import 'package:edconnect_mobile/services/data_services.dart';
import 'package:edconnect_mobile/signal_protocol/signal_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:edconnect_mobile/utils/device_manager.dart';

class DeviceLinkingManager {
  final SignalKeyManager _keyManager = SignalKeyManager();

  Future<String> generateLinkingQRCode(String userId, String org) async {
    try {
      final identityKeyPair = await _keyManager.getIdentityKeyPair(userId, org);
      final publicKey = await identityKeyPair.extractPublicKey();
      final privateKeyBytes = await identityKeyPair.extractPrivateKeyBytes();
      final linkingData = {
        'userId': userId,
        'org': org,
        'publicKey': base64Encode(publicKey.bytes),
        'privateKey': base64Encode(privateKeyBytes),
      };
      return jsonEncode(linkingData);
    } on Exception catch (e) {
      throw Exception('Error generating QR code: ${e.toString()}');
    }
  }

  Future<void> processScannedQRCode(String scannedData, String usersCollection,
      String currentUserId, String currentOrg) async {
    final linkingData = jsonDecode(scannedData);
    final userId = linkingData['userId'];
    final org = linkingData['org'];

    if (userId != currentUserId || org != currentOrg) {
      throw Exception('Invalid QR code. Wrong user or organization.');
    }

    final publicKeyBytes = base64Decode(linkingData['publicKey']);
    final privateKeyBytes = base64Decode(linkingData['privateKey']);

    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.x25519);
    final keyPair = SimpleKeyPairData(privateKeyBytes,
        publicKey: publicKey, type: KeyPairType.x25519);

    // Store the identity key pair for the new device
    await _keyManager.storeScannedIdentityKeyPair(userId, org, keyPair);

    final currentDeviceId = await DeviceManager().getUniqueDeviceId();

    // Update user's device list in Firestore (implement this method)
    await DataService()
        .addNewDevice(userId, org, currentDeviceId, usersCollection);
  }
}
