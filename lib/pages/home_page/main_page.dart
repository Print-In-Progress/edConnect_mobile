import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edconnect_mobile/pages/auth_pages/auth_page.dart';
import 'package:edconnect_mobile/pages/auth_pages/verify_email_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const VerifyEmailPage();
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}
