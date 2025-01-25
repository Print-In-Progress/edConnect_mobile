import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/buttons.dart';
import 'package:edconnect_mobile/widgets/forms.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // text editing controllers
  final _emailController = TextEditingController();

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim())
          .then((value) {
        successMessage(
            context,
            AppLocalizations.of(context)!
                .forgotPasswordPageSuccessLinkSendSnackbarMessage);
        FirebaseAnalytics.instance
            .logEvent(name: 'password_reset', parameters: {
          'user_id': FirebaseAuth.instance.currentUser!.uid,
          'timestamp': Timestamp.now().toDate().toString()
        });
      });
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      errorMessage(context, e.toString());
    } catch (e) {
      if (!context.mounted) return;
      errorMessage(
          context, AppLocalizations.of(context)!.globalUnexpectedErrorLabel);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
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
              Color(int.parse(currentColorSchemeProvider.secondaryColor)),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width < 700
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width / 2,
                child: Card(
                    elevation: 50,
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(context)!
                                .forgotPasswordPagePasswordResetLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 10),
                          PIPOutlinedBorderInputForm(
                            validate: false,
                            width: MediaQuery.of(context).size.width,
                            controller: _emailController,
                            label:
                                AppLocalizations.of(context)!.globalEmailLabel,
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          PIPResponsiveRaisedButton(
                            label: AppLocalizations.of(context)!
                                .forgotPasswordPageResetPasswordButtonLabel,
                            onPressed: passwordReset,
                            fontWeight: FontWeight.w700,
                            width: MediaQuery.of(context).size.width < 700
                                ? MediaQuery.of(context).size.width
                                : MediaQuery.of(context).size.width / 4,
                          ),
                          const SizedBox(height: 10),
                          PIPResponsiveTextButton(
                            label: AppLocalizations.of(context)!
                                .globalBackToLoginLabel,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            width: MediaQuery.of(context).size.width < 700
                                ? MediaQuery.of(context).size.width / 2
                                : MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.height / 20,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
