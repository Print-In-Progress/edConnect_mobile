import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/pages/auth_pages/user_not_found.dart';
import 'package:edconnect_mobile/pages/home_page/home_page.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
          const Duration(seconds: 3), (timer) => checkIfEmailVerified());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future checkIfEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) timer?.cancel();
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() => canResendEmail = false);
      Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } on Exception catch (e) {
      if (!context.mounted) return;
      errorMessage(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    if (isEmailVerified) {
      return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(databaseProvider.customerSpecificCollectionUsers)
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.exists) {
                final currentUser =
                    AppUser.fromDocument(snapshot.data!, snapshot.data!.id);
                return HomePage(
                  currentUser: currentUser,
                );
              } else if (!snapshot.data!.exists) {
                return const UserNotFoundPage();
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          });
    } else {
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
          child: SafeArea(
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width < 700
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width / 2,
                child: Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          AppLocalizations.of(context)!
                              .authPagesVerifyEmailPageTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.green, fontSize: 50),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          AppLocalizations.of(context)!
                              .authPagesVerifyEmailPageContent,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      ElevatedButton.icon(
                          onPressed:
                              canResendEmail ? sendVerificationEmail : () {},
                          icon: const Icon(Icons.email),
                          label: Text(AppLocalizations.of(context)!
                              .globalResendEmailButtonLabel)),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.cancel),
                          label: Text(AppLocalizations.of(context)!
                              .globalCancelButtonLabel)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
