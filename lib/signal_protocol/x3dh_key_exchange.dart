import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/signal_protocol/signal_key_manager.dart';

class X3DHKeyExchange {
  final SignalKeyManager keyManager = SignalKeyManager();

  // Properties to store the results of the key exchange

  Uint8List? _sharedSecret;
  SimplePublicKey? _ephemeralPublicKey;
  int? _usedOneTimePreKeyId;

  Uint8List get sharedSecret => _sharedSecret!;
  SimplePublicKey get ephemeralPublicKey => _ephemeralPublicKey!;
  int? get usedOneTimePreKeyId => _usedOneTimePreKeyId;

  Future<void> initiateKeyExchange(
      AppUser currentUser,
      List<int> recipientPublicIdentityKey,
      Map<String, List<int>> recipientSignedPublicPreKey,
      List<Map<String, dynamic>> recipientOneTimePreKeys,
      String org) async {
    final currentUserIdentityKeyPair =
        await keyManager.getIdentityKeyPair(currentUser.id, org);
    final ephemeralKeyPair = await X25519().newKeyPair();
    _ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // if (publicIdentityKey == null ||
    //     otherUser.signedpublicPreKey == null ||
    //     otherUser.oneTimePreKeys == null) {
    //   throw Exception("Missing required keys for the other user.");
    // }

    final otherUserIdentityPublicKey = SimplePublicKey(
      Uint8List.fromList(List<int>.from(recipientPublicIdentityKey)),
      type: KeyPairType.x25519,
    );

    SimplePublicKey? otherUserOneTimePrekeyPublic;
    if (recipientOneTimePreKeys.isNotEmpty) {
      final prekeyMap = recipientOneTimePreKeys.first;
      _usedOneTimePreKeyId = prekeyMap['prekeyId'];
      final prekeyBytes =
          Uint8List.fromList(List<int>.from(prekeyMap['publicKey']));
      otherUserOneTimePrekeyPublic =
          SimplePublicKey(prekeyBytes, type: KeyPairType.x25519);
    }

    _sharedSecret = await _performDHOperations(
      currentUserIdentityKeyPair,
      ephemeralKeyPair,
      otherUserIdentityPublicKey,
      SimplePublicKey(
        Uint8List.fromList(recipientSignedPublicPreKey['public_key']!),
        type: KeyPairType.x25519,
      ),
      otherUserOneTimePrekeyPublic,
    );
  }

  Future<Uint8List> _performDHOperations(
    SimpleKeyPair initiatorIdentityKeyPair,
    SimpleKeyPair initiatorEphemeralKeyPair,
    SimplePublicKey recipientIdentityPublicKey,
    SimplePublicKey recipientSignedPrekeyPublic,
    SimplePublicKey? recipientOneTimePrekeyPublic,
  ) async {
    final dh1 = await X25519().sharedSecretKey(
      keyPair: initiatorIdentityKeyPair,
      remotePublicKey: recipientSignedPrekeyPublic,
    );

    final dh2 = await X25519().sharedSecretKey(
      keyPair: initiatorEphemeralKeyPair,
      remotePublicKey: recipientIdentityPublicKey,
    );

    final dh3 = await X25519().sharedSecretKey(
      keyPair: initiatorEphemeralKeyPair,
      remotePublicKey: recipientSignedPrekeyPublic,
    );

    List<int> combinedSecrets = [
      ...await dh1.extractBytes(),
      ...await dh2.extractBytes(),
      ...await dh3.extractBytes(),
    ];

    if (recipientOneTimePrekeyPublic != null) {
      final dh4 = await X25519().sharedSecretKey(
        keyPair: initiatorEphemeralKeyPair,
        remotePublicKey: recipientOneTimePrekeyPublic,
      );
      combinedSecrets.addAll(await dh4.extractBytes());
    }

    return Uint8List.fromList(sha256.convert(combinedSecrets).bytes);
  }

  Future<Uint8List> performX3DHAsRecipient(
    AppUser recipient,
    AppUser initiator,
    String org,
    SimplePublicKey initiatorEphemeralPublicKey,
    SimplePublicKey initiatorIdentityPublicKey,
    int? usedOneTimePreKeyId,
  ) async {
    final recipientIdentityKeyPair =
        await keyManager.getIdentityKeyPair(recipient.id, org);
    final recipientSignedPrekeyPair =
        await keyManager.getSignedPrekeyPair(recipient.id, org);

    SimpleKeyPair? recipientOneTimePrekeyPair;
    if (usedOneTimePreKeyId != null) {
      recipientOneTimePrekeyPair = await keyManager.getOneTimePrekey(
          recipient.id, org, usedOneTimePreKeyId);
    }

    final dh1 = await X25519().sharedSecretKey(
      keyPair: recipientSignedPrekeyPair,
      remotePublicKey: initiatorIdentityPublicKey,
    );

    final dh2 = await X25519().sharedSecretKey(
      keyPair: recipientIdentityKeyPair,
      remotePublicKey: initiatorEphemeralPublicKey,
    );

    final dh3 = await X25519().sharedSecretKey(
      keyPair: recipientSignedPrekeyPair,
      remotePublicKey: initiatorEphemeralPublicKey,
    );

    List<int> combinedSecrets = [
      ...await dh1.extractBytes(),
      ...await dh2.extractBytes(),
      ...await dh3.extractBytes(),
    ];

    if (recipientOneTimePrekeyPair != null) {
      final dh4 = await X25519().sharedSecretKey(
        keyPair: recipientOneTimePrekeyPair,
        remotePublicKey: initiatorEphemeralPublicKey,
      );
      combinedSecrets.addAll(await dh4.extractBytes());
    }

    return Uint8List.fromList(sha256.convert(combinedSecrets).bytes);
  }
}
