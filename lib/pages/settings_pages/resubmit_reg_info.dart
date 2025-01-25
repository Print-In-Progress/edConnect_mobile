import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/models/registration_fields.dart';
import 'package:edconnect_mobile/services/data_services.dart';
import 'package:edconnect_mobile/services/pdf_service.dart';
import 'package:edconnect_mobile/utils/card_builders/registration_card_builder.dart';
import 'package:edconnect_mobile/utils/crypto_utils.dart';
import 'package:edconnect_mobile/utils/field_utils.dart';
import 'package:edconnect_mobile/widgets/forms.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';

class ResubmitRegInfo extends StatefulWidget {
  const ResubmitRegInfo({super.key});

  @override
  State<ResubmitRegInfo> createState() => _ResubmitRegInfoState();
}

class _ResubmitRegInfoState extends State<ResubmitRegInfo> {
  late Future<List<BaseRegistrationField>> _futureDocs;
  bool _isDataFetched = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _validateFirstNameField = false;
  bool _validateLastNameField = false;

  bool _isSubmitting = false;
  double _progress = 0.0;
  String _progressLabel = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      _futureDocs = DataService().fetchRegistrationFieldData(
          Provider.of<DatabaseCollectionProvider>(context));
      _isDataFetched = true;
    }
  }

  Future<bool> _submitRegistrationForm(
    List<BaseRegistrationField> registrationFields,
    String firstName,
    String lastName,
  ) async {
    setState(() {
      _isSubmitting = true;
      _progress = 0.0;
      _progressLabel = 'Validating Form';
    });
    // Filter out fields of type 'checkbox_section' whose 'checked' parameter is not true
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context, listen: false);
    DatabaseCollectionProvider databaseProvider =
        Provider.of<DatabaseCollectionProvider>(context, listen: false);

    List<BaseRegistrationField> filteredFields =
        registrationFields.where((field) {
      return !(field.type == 'checkbox_section' && field.checked != true);
    }).toList();
    // Flatten the filtered list of fields
    List<BaseRegistrationField> flattenedRegistrationList =
        flattenRegistrationFields(filteredFields);

    String validateRegistrationFields =
        validateCustomRegistrationFields(flattenedRegistrationList);
    bool hasCheckedSignatureField = flattenedRegistrationList
        .any((field) => field.type == 'signature' && field.checked == true);

    if (validateRegistrationFields.isNotEmpty) {
      switch (validateRegistrationFields) {
        case 'SignatureMissing':
          errorMessage(context, 'Please sign all required fields');
          break;
        case 'QuestionMissing':
          errorMessage(context, 'Please fill out all required fields');
          break;
        default:
          errorMessage(context, 'Please fill out all required fields');
          break;
      }
      setState(() {
        _isSubmitting = false;
      });
      return false;
    } else if (hasCheckedSignatureField) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      List<String> checkedCheckboxAssignGroupValues = flattenedRegistrationList
          .where((field) =>
              field.type == 'checkbox_assign_group' && field.checked == true)
          .map((field) => field.group!)
          .toList();

      final keyPair = generateRSAKeyPair();
      final pdfBytes = await generatePdf(
          flattenedRegistrationList,
          true,
          uid,
          currentColorSchemeProvider,
          lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
          firstName.trim()[0].toUpperCase() + firstName.trim().substring(1),
          FirebaseAuth.instance.currentUser!.email!,
          publicKey: keyPair.publicKey);
      final pdfHash = hashBytes(pdfBytes);

      final signature = signHash(pdfHash, keyPair.privateKey);

      verifySignature(pdfHash, signature, keyPair.publicKey);
      final fileName = '${uid}_registration_form.pdf';

      setState(() {
        _progress = 0.2;
        _progressLabel = 'Uploading Signature';
      });

      await DataService().uploadPdfSignature(
        keyPair.publicKey,
        signature,
        databaseProvider,
      );

      setState(() {
        _progress = 0.4;
        _progressLabel = 'Uploading PDF';
      });

      await DataService().uploadPdf(
        pdfBytes,
        fileName,
        uid,
        true,
        databaseProvider,
      );
      setState(() {
        _progress = 0.6;
        _progressLabel = 'Uploading Files';
      });
      List<PlatformFile> files = [];
      for (var field in flattenedRegistrationList) {
        if (field.type == 'file_upload') {
          files.addAll(field.file ?? []);
        }
      }
      if (files.isNotEmpty) {
        await DataService()
            .uploadFiles(files, uid, 'registration_form', databaseProvider);
      }
      setState(() {
        _progress = 0.8;
        _progressLabel = 'Adding User to Groups';
      });
      if (checkedCheckboxAssignGroupValues.isNotEmpty) {
        await DataService().addGroupsToUser(
            checkedCheckboxAssignGroupValues, databaseProvider);
      }
      setState(() {
        _progress = 1.0;
        _progressLabel = 'Submission Complete!';
      });
      return true;
    } else {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      List<String> checkedCheckboxAssignGroupValues = flattenedRegistrationList
          .where((field) =>
              field.type == 'checkbox_assign_group' && field.checked == true)
          .map((field) => field.group!)
          .toList();

      final pdfBytes = await generatePdf(
        flattenedRegistrationList,
        false,
        uid,
        currentColorSchemeProvider,
        lastName.trim()[0].toUpperCase() + lastName.trim().substring(1),
        firstName.trim()[0].toUpperCase() + firstName.trim().substring(1),
        FirebaseAuth.instance.currentUser!.email!,
      );

      final fileName = '${uid}_registration_form.pdf';

      setState(() {
        _progress = 0.2;
        _progressLabel = 'Uploading PDF';
      });

      await DataService().uploadPdf(
        pdfBytes,
        fileName,
        uid,
        false,
        databaseProvider,
      );

      setState(() {
        _progress = 0.4;
        _progressLabel = 'Uploading Files';
      });

      List<PlatformFile> files = [];
      for (var field in flattenedRegistrationList) {
        if (field.type == 'file_upload') {
          files.addAll(field.file ?? []);
        }
      }
      if (files.isNotEmpty) {
        await DataService()
            .uploadFiles(files, uid, 'registration_form', databaseProvider);
      }
      setState(() {
        _progress = 0.6;
        _progressLabel = 'Adding User to Groups';
      });
      if (checkedCheckboxAssignGroupValues.isNotEmpty) {
        await DataService().addGroupsToUser(
            checkedCheckboxAssignGroupValues, databaseProvider);
      }
      setState(() {
        _progress = 0.8;
      });
      setState(() {
        _progress = 1.0;
        _progressLabel = 'Submission Complete!';
      });
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(int.parse(currentColorSchemeProvider.primaryColor)),
                Color(int.parse(currentColorSchemeProvider.secondaryColor))
              ],
            ),
          ),
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
              child: NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: true,
                  floating: true,
                  snap: true,
                  forceMaterialTransparency: true,
                  actionsIconTheme: const IconThemeData(color: Colors.white),
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    'Registration Information',
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              ];
            },
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width < 700
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PIPOutlinedBorderInputForm(
                                    validate: _validateFirstNameField,
                                    width: MediaQuery.of(context).size.width,
                                    controller: _firstNameController,
                                    label: AppLocalizations.of(context)!
                                        .globalFirstNameTextFieldHintText,
                                    icon: Icons.person,
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  PIPOutlinedBorderInputForm(
                                    validate: _validateLastNameField,
                                    width: MediaQuery.of(context).size.width,
                                    controller: _lastNameController,
                                    label: AppLocalizations.of(context)!
                                        .globalLastNameTextFieldHintText,
                                    icon: Icons.person,
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          FutureBuilder<List<BaseRegistrationField>>(
                              future: _futureDocs,
                              builder: ((context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      5,
                                      (index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  height: 20.0,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  width: double.infinity,
                                                  height: 20.0,
                                                  color: Colors.grey[300],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else if (snapshot.hasData) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListView.builder(
                                          itemBuilder: (context, index) {
                                            return buildRegistrationCard(
                                                context, snapshot.data!, index);
                                          },
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: snapshot.data!.length),
                                      if (!_isSubmitting)
                                        FilledButton(
                                          child: Text('Submit'),
                                          onPressed: () {
                                            setState(() {
                                              _firstNameController.text.isEmpty
                                                  ? _validateFirstNameField =
                                                      true
                                                  : _validateFirstNameField =
                                                      false;
                                              _lastNameController.text.isEmpty
                                                  ? _validateLastNameField =
                                                      true
                                                  : _validateLastNameField =
                                                      false;
                                            });
                                            if (_firstNameController
                                                    .text.isNotEmpty &&
                                                _lastNameController
                                                    .text.isNotEmpty) {
                                              _submitRegistrationForm(
                                                snapshot.data!,
                                                _firstNameController.text,
                                                _lastNameController.text,
                                              ).then((value) {
                                                if (value) {
                                                  _firstNameController.clear();
                                                  _lastNameController.clear();
                                                  successMessage(context,
                                                      'Form Submitted');
                                                }
                                              });
                                            } else {
                                              errorMessage(context,
                                                  'First and Last Name can not be empty');
                                            }
                                          },
                                        ),
                                      if (_isSubmitting)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            LinearProgressIndicator(
                                                value: _progress),
                                            Text(_progressLabel),
                                          ],
                                        )
                                    ],
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              })),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )),
        ));
  }
}
