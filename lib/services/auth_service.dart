import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/modulesprovider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/models/registration_fields.dart';
import 'package:edconnect_mobile/services/data_services.dart';
import 'package:edconnect_mobile/services/pdf_service.dart';
import 'package:edconnect_mobile/utils/crypto_utils.dart';
import 'package:edconnect_mobile/utils/field_utils.dart';
import 'package:edconnect_mobile/utils/validation_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signUp(
      String email,
      String firstName,
      String lastName,
      String password,
      String confirmedPassword,
      List<BaseRegistrationField> registrationFields,
      DatabaseCollectionProvider databaseProvider,
      UserModulesProvider modulesProvider,
      ColorANDLogoProvider currentColorSchemeProvider) async {
    if (!passwordConfirmed(password, confirmedPassword)) {
      return 'PasswordsDoNotMatch';
    }
    // Create User
    try {
      // Filter out fields of type 'checkbox_section' whose 'checked' parameter is not true
      List<BaseRegistrationField> filteredFields =
          registrationFields.where((field) {
        return !(field.type == 'checkbox_section' && field.checked != true);
      }).toList();

      // Flatten the filtered list of fields
      List<BaseRegistrationField> flattenedRegistrationList =
          flattenRegistrationFields(filteredFields);

      String validateRegistrationFields =
          validateCustomRegistrationFields(flattenedRegistrationList);

      if (validateRegistrationFields.isEmpty) {
        bool hasCheckedSignatureField = flattenedRegistrationList
            .any((field) => field.type == 'signature' && field.checked == true);
        if (registrationFields.isEmpty) {
          await _auth
              .createUserWithEmailAndPassword(
                  email: firstName.trim(), password: password.trim())
              .then((value) async {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            List<String> checkedCheckboxAssignGroupValues =
                flattenedRegistrationList
                    .where((field) =>
                        field.type == 'checkbox_assign_group' &&
                        field.checked == true)
                    .map((field) => field.group!)
                    .toList();

            await DataService().addUserDetails(
              firstName.trim()[0].toUpperCase() + firstName.trim().substring(1),
              lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
              email.trim(),
              checkedCheckboxAssignGroupValues,
              databaseProvider,
              uid,
              false,
              modulesProvider,
            );
          });
        } else if (hasCheckedSignatureField) {
          await _auth
              .createUserWithEmailAndPassword(
                  email: email.trim(), password: password.trim())
              .then((value) async {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            List<String> checkedCheckboxAssignGroupValues =
                flattenedRegistrationList
                    .where((field) =>
                        field.type == 'checkbox_assign_group' &&
                        field.checked == true)
                    .map((field) => field.group!)
                    .toList();

            final keyPair = generateRSAKeyPair();
            final pdfBytes = await generatePdf(
                flattenedRegistrationList,
                true,
                uid,
                currentColorSchemeProvider,
                lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
                firstName.trim()[0].toUpperCase() +
                    firstName.trim().substring(1),
                email.trim(),
                publicKey: keyPair.publicKey);
            final pdfHash = hashBytes(pdfBytes);

            final signature = signHash(pdfHash, keyPair.privateKey);

            verifySignature(pdfHash, signature, keyPair.publicKey);

            await DataService()
                .addUserDetails(
              firstName.trim()[0].toUpperCase() + firstName.trim().substring(1),
              lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
              email.trim(),
              checkedCheckboxAssignGroupValues,
              databaseProvider,
              uid,
              true,
              modulesProvider,
              publicKey: keyPair.publicKey,
              signatureBytes: signature,
            )
                .then((value) async {
              final fileName = '${uid}_registration_form.pdf';

              await DataService().uploadPdf(
                pdfBytes,
                fileName,
                uid,
                true,
                databaseProvider,
              );
              List<PlatformFile> files = [];
              for (var field in flattenedRegistrationList) {
                if (field.type == 'file_upload') {
                  files.addAll(field.file ?? []);
                }
              }
              if (files.isNotEmpty) {
                await DataService().uploadFiles(
                    files, uid, 'registration_form', databaseProvider);
              }
            });
          });
        } else {
          await _auth
              .createUserWithEmailAndPassword(
                  email: email.trim(), password: password.trim())
              .then((value) async {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            List<String> checkedCheckboxAssignGroupValues =
                flattenedRegistrationList
                    .where((field) =>
                        field.type == 'checkbox_assign_group' &&
                        field.checked == true)
                    .map((field) => field.group!)
                    .toList();

            await DataService()
                .addUserDetails(
              firstName.trim()[0].toUpperCase() + firstName.trim().substring(1),
              lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
              email.trim(),
              checkedCheckboxAssignGroupValues,
              databaseProvider,
              uid,
              false,
              modulesProvider,
            )
                .then((value) async {
              final pdfBytes = await generatePdf(
                flattenedRegistrationList,
                false,
                uid,
                currentColorSchemeProvider,
                firstName.trim()[0].toUpperCase() +
                    firstName.trim().substring(1),
                lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
                email.trim(),
              );

              final fileName = '${uid}_registration_form.pdf';

              await DataService().uploadPdf(
                pdfBytes,
                fileName,
                uid,
                false,
                databaseProvider,
              );
              List<PlatformFile> files = [];
              for (var field in flattenedRegistrationList) {
                if (field.type == 'file_upload') {
                  files.addAll(field.file!);
                }
              }
              if (files.isNotEmpty) {
                await DataService().uploadFiles(
                    files, uid, 'registration_form', databaseProvider);
              }
            });
          });
        }
      } else {
        return validateRegistrationFields;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final snapshot = await FirebaseFirestore.instance
            .collection(databaseProvider.customerSpecificCollectionUsers)
            .where('email', isEqualTo: email.trim())
            .get();
        if (snapshot.docs.isEmpty) {
          return 'AccountAlreadyExistsWithOtherOrg';
        } else {
          return 'EmailAlreadyInUse';
        }
      } else {
        return 'AuthError ${e.code}';
      }
    } on Exception catch (e) {
      return 'UnexpectedError $e';
    }
    return null;
  }

  Future<String?> signUpToOrg(
      String email,
      String firstName,
      String lastName,
      String password,
      String confirmedPassword,
      List<BaseRegistrationField> registrationFields,
      DatabaseCollectionProvider databaseProvider,
      UserModulesProvider modulesProvider,
      ColorANDLogoProvider currentColorSchemeProvider) async {
    if (!passwordConfirmed(password, confirmedPassword)) {
      return 'PasswordsDoNotMatch';
    }
    // Create User
    try {
      // Filter out fields of type 'checkbox_section' whose 'checked' parameter is not true
      List<BaseRegistrationField> filteredFields =
          registrationFields.where((field) {
        return !(field.type == 'checkbox_section' && field.checked != true);
      }).toList();

      // Flatten the filtered list of fields
      List<BaseRegistrationField> flattenedRegistrationList =
          flattenRegistrationFields(filteredFields);

      String validateRegistrationFields =
          validateCustomRegistrationFields(flattenedRegistrationList);

      if (validateRegistrationFields.isEmpty) {
        bool hasCheckedSignatureField = flattenedRegistrationList
            .any((field) => field.type == 'signature' && field.checked == true);
        if (registrationFields.isEmpty) {
          await _auth
              .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
              .then((value) async {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            List<String> checkedCheckboxAssignGroupValues =
                flattenedRegistrationList
                    .where((field) =>
                        field.type == 'checkbox_assign_group' &&
                        field.checked == true)
                    .map((field) => field.group!)
                    .toList();

            await DataService().addUserDetails(
              firstName.trim()[0].toUpperCase() + firstName.trim().substring(1),
              lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
              email.trim(),
              checkedCheckboxAssignGroupValues,
              databaseProvider,
              uid,
              false,
              modulesProvider,
            );
          });
        } else if (hasCheckedSignatureField) {
          await _auth
              .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
              .then((value) async {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            List<String> checkedCheckboxAssignGroupValues =
                flattenedRegistrationList
                    .where((field) =>
                        field.type == 'checkbox_assign_group' &&
                        field.checked == true)
                    .map((field) => field.group!)
                    .toList();

            final keyPair = generateRSAKeyPair();
            final pdfBytes = await generatePdf(
                flattenedRegistrationList,
                true,
                uid,
                currentColorSchemeProvider,
                lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
                firstName.trim()[0].toUpperCase() +
                    firstName.trim().substring(1),
                email.trim(),
                publicKey: keyPair.publicKey);
            final pdfHash = hashBytes(pdfBytes);

            final signature = signHash(pdfHash, keyPair.privateKey);

            verifySignature(pdfHash, signature, keyPair.publicKey);
            await DataService()
                .addUserDetails(
                    firstName.trim()[0].toUpperCase() +
                        firstName.trim().substring(1),
                    lastName.trim()[0].toUpperCase() +
                        lastName.trim().substring(1),
                    email.trim(),
                    checkedCheckboxAssignGroupValues,
                    databaseProvider,
                    uid,
                    true,
                    modulesProvider,
                    publicKey: keyPair.publicKey,
                    signatureBytes: signature)
                .then((value) async {
              final fileName = '${uid}_registration_form.pdf';

              await DataService().uploadPdf(
                pdfBytes,
                fileName,
                uid,
                true,
                databaseProvider,
              );
              List<PlatformFile> files = [];
              for (var field in flattenedRegistrationList) {
                if (field.type == 'file_upload') {
                  files.addAll(field.file ?? []);
                }
              }
              if (files.isNotEmpty) {
                await DataService().uploadFiles(
                    files, uid, 'registration_form', databaseProvider);
              }
            });
          });
        } else {
          await _auth
              .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
              .then((value) async {
            final uid = FirebaseAuth.instance.currentUser!.uid;
            List<String> checkedCheckboxAssignGroupValues =
                flattenedRegistrationList
                    .where((field) =>
                        field.type == 'checkbox_assign_group' &&
                        field.checked == true)
                    .map((field) => field.group!)
                    .toList();

            await DataService()
                .addUserDetails(
              firstName.trim()[0].toUpperCase() + firstName.trim().substring(1),
              lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
              email.trim(),
              checkedCheckboxAssignGroupValues,
              databaseProvider,
              uid,
              false,
              modulesProvider,
            )
                .then((value) async {
              final pdfBytes = await generatePdf(
                flattenedRegistrationList,
                false,
                uid,
                currentColorSchemeProvider,
                firstName.trim()[0].toUpperCase() +
                    firstName.trim().substring(1),
                lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
                email.trim(),
              );

              final fileName = '${uid}_registration_form.pdf';

              await DataService().uploadPdf(
                pdfBytes,
                fileName,
                uid,
                false,
                databaseProvider,
              );
              List<PlatformFile> files = [];
              for (var field in flattenedRegistrationList) {
                if (field.type == 'file_upload') {
                  files.addAll(field.file!);
                }
              }
              if (files.isNotEmpty) {
                await DataService().uploadFiles(
                    files, uid, 'registration_form', databaseProvider);
              }
            });
          });
        }
      } else {
        return validateRegistrationFields;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final snapshot = await FirebaseFirestore.instance
            .collection(databaseProvider.customerSpecificCollectionUsers)
            .where('email', isEqualTo: email.trim())
            .get();
        if (snapshot.docs.isEmpty) {
          return 'AccountAlreadyExistsWithOtherOrg';
        } else {
          return 'EmailAlreadyInUse';
        }
      } else {
        return 'AuthError ${e.code}';
      }
    } on Exception catch (e) {
      return 'UnexpectedError $e';
    }
    return null;
  }

  Future<String> signIn(String email, String password,
      DatabaseCollectionProvider databaseProvider) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      FirebaseAnalytics.instance.logLogin(loginMethod: 'Email');
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return 'AuthError ${e.message}';
    } catch (e) {
      return 'UnexpectedError $e';
    }
  }
}
