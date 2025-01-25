import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/modulesprovider.dart';
import 'package:edconnect_mobile/models/registration_fields.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/signal_protocol/signal_key_manager.dart';
import 'package:edconnect_mobile/utils/crypto_utils.dart';
import 'package:edconnect_mobile/utils/device_manager.dart';
import 'package:pointycastle/export.dart' as pc;

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPdf(
    Uint8List pdfBytes,
    String fileName,
    String uid,
    bool signed,
    DatabaseCollectionProvider databaseProvider,
  ) async {
    final storageRef = _storage.ref();
    final pdfRef = storageRef.child(
        '${databaseProvider.customerSpecificCollectionFiles}/user_data/$uid/$fileName');

    final metaData =
        SettableMetadata(contentType: 'application/pdf', customMetadata: {
      'uploaded_by': uid,
      'signed': signed ? 'true' : 'false',
    });

    final uploadTask = pdfRef.putData(pdfBytes, metaData);
    final snapshot = await uploadTask.whenComplete(() => null);

    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> uploadFiles(List<PlatformFile> files, String uid,
      String fileOrigin, DatabaseCollectionProvider databaseProvider) async {
    List<Future<void>> uploadTasks = [];

    SettableMetadata metadata = SettableMetadata(
      customMetadata: {
        'uploaded_by': uid, // Replace with actual user UID or other metadata
        'origin': fileOrigin,
      },
    );

    for (PlatformFile file in files) {
      if (file.path != null) {
        File localFile = File(file.path!);
        uploadTasks.add(_storage
            .ref(
                '${databaseProvider.customerSpecificCollectionFiles}/user_data/$uid/${file.name}')
            .putFile(localFile, metadata));
      }
    }

    await Future.wait(uploadTasks);
  }

  Future uploadPdfSignature(
      pc.RSAPublicKey? publicKey,
      Uint8List? signatureBytes,
      DatabaseCollectionProvider databaseProvider) async {
    _firestore
        .collection(databaseProvider.customerSpecificCollectionUsers)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'reg_pdf_public_key': convertPublicKeyToPem(publicKey!),
      'reg_pdf_signature': base64Encode(signatureBytes!),
    });
  }

  Future addUserDetails(
    String firstName,
    String lastName,
    String email,
    List<String> groups,
    DatabaseCollectionProvider databaseProvider,
    String uid,
    bool withSignedPdf,
    UserModulesProvider modulesProvider, {
    pc.RSAPublicKey? publicKey,
    Uint8List? signatureBytes,
  }) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    Map<String, dynamic> userDetails = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'groups': groups,
      'registration_timestamp': FieldValue.serverTimestamp(),
      'permissions': ['user'],
      'organization': databaseProvider.customerSpecificRootCollectionName,
      'fcm_token': [fcmToken]
    };

    // Generate and store keys using SignalKeyManager
    final SignalKeyManager keyManager = SignalKeyManager();
    final currentDeviceId = await DeviceManager().getUniqueDeviceId();
    final keys = await keyManager.generateAndStoreKeys(
        uid, databaseProvider.customerSpecificRootCollectionName);
    userDetails.addAll({
      'public_identity_key': keys['identityPublicKey'],
      'device_Ids': {
        currentDeviceId: {
          'signed_pre_key': {
            'public_key': keys['signedPrekeyPublic'],
            'signature': keys['signature']
          },
          'one_time_pre_keys': keys['oneTimePrekeys'],
        }
      }
    });

    if (withSignedPdf && publicKey != null && signatureBytes != null) {
      // Convert the public key to PEM format
      String publicKeyToPem = convertPublicKeyToPem(publicKey);

      // Convert the signature to a Base64 string for storage
      String signatureBase64 = base64Encode(signatureBytes);

      userDetails['reg_pdf_public_key'] = publicKeyToPem;
      userDetails['reg_pdf_signature'] = signatureBase64;
    }

    CollectionReference userCollection =
        _firestore.collection(databaseProvider.customerSpecificCollectionUsers);

    await userCollection.doc(uid).set(userDetails);
  }

  Future<void> addNewDevice(
    String userId,
    String org,
    String newDeviceId,
    String usersCollection,
  ) async {
    final SignalKeyManager keyManager = SignalKeyManager();

    // Retrieve the identity key pair from secure storage
    final identityKeyPair = await keyManager.getIdentityKeyPair(userId, org);

    // Generate and store keys for the new device
    final keys = await keyManager.generateAndStoreKeysForNewDevice(
      userId,
      org,
      identityKeyPair,
    );

    // Update Firestore with the new device keys
    DocumentReference userDocRef =
        _firestore.collection(usersCollection).doc(userId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userDocRef);
      if (!userDoc.exists) {
        throw Exception('User data not found.');
      }

      Map<String, dynamic> deviceIds = userDoc['device_Ids'] ?? {};
      deviceIds[newDeviceId] = {
        'signed_pre_key': {
          'public_key': keys['signedPrekeyPublic'],
          'signature': keys['signature']
        },
        'one_time_pre_keys': keys['oneTimePrekeys'],
      };

      transaction.update(userDocRef, {'device_Ids': deviceIds});
    });
  }

  Future<List<BaseRegistrationField>> fetchRegistrationFieldData(
      DatabaseCollectionProvider databaseProvider) async {
    var snapshot = await FirebaseFirestore.instance
        .collection(databaseProvider.customerSpecificCollectionRegistration)
        .get();

    var docs = snapshot.docs;

    // Sort documents locally in ascending order by 'pos'
    docs.sort((a, b) {
      var aPos = a.data().containsKey('pos') ? a['pos'] : double.maxFinite;
      var bPos = b.data().containsKey('pos') ? b['pos'] : double.maxFinite;
      return aPos.compareTo(bPos);
    });

    // Create a map to hold subfields grouped by parentUid
    Map<String, List<RegistrationSubField>> subFieldsMap = {};

    // First pass: create subfields and group them by parentUid
    for (var doc in docs) {
      var data = doc.data();
      if (data.containsKey('parent_uid')) {
        var subField = RegistrationSubField(
          id: doc.id,
          parentUid: data['parent_uid'] ?? '',
          type: data['type'] ?? '',
          text: data['type'] == 'infobox' ||
                  data['type'] == 'checkbox' ||
                  data['type'] == 'file_upload'
              ? data['text'] ?? ''
              : null,
          options: data['type'] == 'dropdown' ? data['options'] : null,
          group: data['type'] == 'checkbox_assign_group' ? data['group'] : null,
          response: TextEditingController(),
          selectedDate: null,
          checked: false,
          maxFileUploads: data['type'] == 'file_upload'
              ? data['max_file_uploads']?.toInt() ?? 0
              : null,
          checkboxLabel:
              data['type'] == 'checkbox' ? data['checkbox_label'] ?? '' : null,
          title: data['title'] ?? '',
          pos: data['sub_pos']?.toInt() ?? 0,
        );
        if (!subFieldsMap.containsKey(subField.parentUid)) {
          subFieldsMap[subField.parentUid] = [];
        }
        subFieldsMap[subField.parentUid]!.add(subField);
      }
    }

    // Sort subfields by 'pos' within each parentUid group
    subFieldsMap.forEach((key, value) {
      value.sort((a, b) => a.pos.compareTo(b.pos));
    });

    // Recursive function to assign child subfields
    List<RegistrationSubField> assignChildSubFields(String parentId) {
      if (!subFieldsMap.containsKey(parentId)) {
        return [];
      }
      return subFieldsMap[parentId]!.map((subField) {
        return RegistrationSubField(
          id: subField.id,
          parentUid: subField.parentUid,
          type: subField.type,
          text: subField.type == 'infobox' ||
                  subField.type == 'checkbox' ||
                  subField.type == 'file_upload'
              ? subField.text
              : null,
          options: subField.type == 'dropdown' ? subField.options : null,
          checked: subField.checked,
          selectedDate: null,
          response: subField.response,
          group:
              subField.type == 'checkbox_assign_group' ? subField.group : null,
          maxFileUploads: subField.maxFileUploads,
          checkboxLabel: subField.checkboxLabel,
          title: subField.title,
          pos: subField.pos,
          childWidgets: assignChildSubFields(subField.id),
        );
      }).toList();
    }

    // Second pass: create fields and assign subfields
    List<BaseRegistrationField> registrationFieldList = docs
        .map((doc) {
          var data = doc.data();
          if (!data.containsKey('parent_uid')) {
            return RegistrationField(
              id: doc.id,
              type: data['type'] ?? '',
              text: data['type'] == 'infobox' ||
                      data['type'] == 'checkbox' ||
                      data['type'] == 'file_upload'
                  ? data['text'] ?? ''
                  : null,
              options: data['type'] == 'dropdown' ? data['options'] : null,
              group: data['type'] == 'checkbox_assign_group'
                  ? data['group']
                  : null,
              selectedDate: null,
              maxFileUploads: data['type'] == 'file_upload'
                  ? data['max_file_uploads']?.toInt()
                  : null,
              checkboxLabel: data['type'] == 'checkbox'
                  ? data['checkbox_label'] ?? ''
                  : null,
              response: TextEditingController(),
              checked: false,
              title: data['title'] ?? '',
              pos: data['pos']?.toInt() ?? 0,
              childWidgets: assignChildSubFields(doc.id),
            );
          }
          return null;
        })
        .where((field) => field != null)
        .cast<BaseRegistrationField>()
        .toList();

    return registrationFieldList;
  }

  Future<void> addGroupsToUser(
      List<String> groups, DatabaseCollectionProvider databaseProvider) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    DocumentReference userDocRef = _firestore
        .collection(databaseProvider.customerSpecificCollectionUsers)
        .doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userDocRef);
      if (!userDoc.exists) {
        throw Exception('User data not found.');
      }

      transaction.update(userDocRef, {'groups': FieldValue.arrayUnion(groups)});
    });
  }

  // Fetch users based on a query
  Future<List<AppUser>> fetchAllUsers(
      DatabaseCollectionProvider databaseProvider) async {
    QuerySnapshot snapshot = await _firestore
        .collection(databaseProvider.customerSpecificCollectionUsers)
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromDocument(doc, doc.id))
        .toList();
  }

  Future<List<String>> getAllGroups(String rootCollection) async {
    final snaphot =
        await _firestore.collection(rootCollection).doc('newsapp').get();
    return List<String>.from(snaphot.data()!['groups']);
  }

  Future<void> addEvent(
    String eventsCollection,
    String title,
    String description,
    List<String> groups,
    Timestamp startDateTime,
    Timestamp endDateTime,
    bool allDay,
  ) async {
    FirebaseFirestore.instance.collection(eventsCollection).add({
      'title': title,
      'description': description,
      'groups': groups,
      'start_date': startDateTime,
      'end_date': endDateTime,
      'all_day': allDay,
      'created_by': FirebaseAuth.instance.currentUser!.uid,
    });
  }
}
