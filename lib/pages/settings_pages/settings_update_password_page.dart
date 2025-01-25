import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/settings_pages/forgot_password_page.dart';
import 'package:edconnect_mobile/widgets/buttons.dart';
import 'package:edconnect_mobile/widgets/forms.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountPassword extends StatefulWidget {
  const AccountPassword({super.key});

  @override
  State<AccountPassword> createState() => _AccountPasswordState();
}

class _AccountPasswordState extends State<AccountPassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _newPasswordVisible = false;
  bool _currentPasswordVisible = false;
  bool _confirmNewPasswordVisible = false;

  bool passwordConfirmed() {
    if (_newPasswordController.text.trim() ==
        _confirmNewPasswordController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _currentPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _newPasswordController.dispose();
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
                    AppLocalizations.of(context)!.globalSettingsLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              ];
            },
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 700
                        ? MediaQuery.of(context).size.width
                        : MediaQuery.of(context).size.width / 2,
                    child: Card(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: PIPPasswordForm(
                                  label: AppLocalizations.of(context)!
                                      .settingsPageCurrentPasswordHintText,
                                  width: MediaQuery.of(context).size.width,
                                  controller: _currentPasswordController,
                                  passwordVisible: _currentPasswordVisible,
                                  onPressed: () {
                                    setState(() {
                                      _currentPasswordVisible =
                                          !_currentPasswordVisible;
                                    });
                                  }),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: PIPPasswordForm(
                                  label: AppLocalizations.of(context)!
                                      .settingsPageNewPasswordHintText,
                                  width: MediaQuery.of(context).size.width,
                                  controller: _newPasswordController,
                                  passwordVisible: _newPasswordVisible,
                                  onPressed: () {
                                    setState(() {
                                      _newPasswordVisible =
                                          !_newPasswordVisible;
                                    });
                                  }),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: PIPPasswordForm(
                                  label: AppLocalizations.of(context)!
                                      .authPagesRegisterConfirmPasswordTextFieldHintText,
                                  width: MediaQuery.of(context).size.width,
                                  controller: _confirmNewPasswordController,
                                  passwordVisible: _confirmNewPasswordVisible,
                                  onPressed: () {
                                    setState(() {
                                      _confirmNewPasswordVisible =
                                          !_confirmNewPasswordVisible;
                                    });
                                  }),
                            ),

                            // forgot password button
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              settings: const RouteSettings(
                                                  name: 'Forgot Password Page'),
                                              builder: (context) {
                                                return const ForgotPasswordPage();
                                              }));
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .authPagesForgotPasswordButtonLabel,
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25.0),
                              child: PIPResponsiveRaisedButton(
                                  fontWeight: FontWeight.w600,
                                  label: AppLocalizations.of(context)!
                                      .globalApplyChangesButtonLabel,
                                  onPressed: () async {
                                    if (passwordConfirmed()) {
                                      try {
                                        var currentUser =
                                            FirebaseAuth.instance.currentUser!;
                                        final cred =
                                            EmailAuthProvider.credential(
                                                email: currentUser.email!,
                                                password:
                                                    _currentPasswordController
                                                        .text);
                                        await currentUser
                                            .reauthenticateWithCredential(cred)
                                            .then((value) async {
                                          await currentUser
                                              .updatePassword(
                                                  _newPasswordController.text)
                                              .then((value) {
                                            successMessage(
                                                context,
                                                AppLocalizations.of(context)!
                                                    .settingsPageSuccessOnPasswordChangedSnackbarLabel);
                                            FirebaseAnalytics.instance.logEvent(
                                                name: 'password_changed',
                                                parameters: {
                                                  'user_id': currentUser.uid,
                                                  'timestamp': Timestamp.now()
                                                      .toDate()
                                                      .toString()
                                                });
                                          });
                                        });
                                      } on FirebaseAuthException catch (e) {
                                        if (!context.mounted) return;
                                        errorMessage(
                                            context, e.message.toString());
                                      }
                                    } else {
                                      errorMessage(
                                          context,
                                          AppLocalizations.of(context)!
                                              .authPagesConfirmPasswordErrorSnackbarLabel);
                                    }
                                  },
                                  width: MediaQuery.of(context).size.width),
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ));
  }
}
