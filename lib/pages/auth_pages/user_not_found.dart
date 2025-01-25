import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/buttons.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UserNotFoundPage extends StatelessWidget {
  const UserNotFoundPage({super.key});

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
        child: Center(
            child: SizedBox(
          width: MediaQuery.of(context).size.width < 700
              ? MediaQuery.of(context).size.width
              : MediaQuery.of(context).size.width / 2,
          child: Card(
            elevation: 50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '404 - User Not Found',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 50),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .authPagesUserNotFoundErrorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  PIPResponsiveRaisedButton(
                      label:
                          AppLocalizations.of(context)!.globalBackToLoginLabel,
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                      },
                      fontWeight: FontWeight.w600,
                      width: MediaQuery.of(context).size.width / 3,
                      height: MediaQuery.of(context).size.height / 15),
                  const SizedBox(
                    height: 5,
                  ),
                  PIPResponsiveRaisedButton(
                      label: 'Print In Progress Homepage',
                      onPressed: () async {
                        final Uri uri =
                            Uri.parse('https://printinprogress.net/');
                        try {
                          await launchUrl(uri);
                        } catch (e) {
                          if (!context.mounted) return;
                          errorMessage(context,
                              '${AppLocalizations.of(context)!.blogPageWasNotAbleToLaunchURLErrorLabel} $uri');
                        }
                      },
                      fontWeight: FontWeight.w600,
                      width: MediaQuery.of(context).size.width / 3,
                      height: MediaQuery.of(context).size.height / 15),
                ],
              ),
            ),
          ),
        )),
      ),
    );
  }
}
