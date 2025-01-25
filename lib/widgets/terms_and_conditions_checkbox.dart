import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsCheckbox extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const TermsAndConditionsCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  TermsAndConditionsCheckboxState createState() =>
      TermsAndConditionsCheckboxState();
}

class TermsAndConditionsCheckboxState
    extends State<TermsAndConditionsCheckbox> {
  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Checkbox(
            value: widget.isChecked,
            onChanged: (value) {
              widget.onChanged(value!);
            },
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: localizations.termsAndConditionsPrefix,
                    style: TextStyle(
                      color: themeChangeProvider.darkTheme
                          ? Colors.white
                          : Colors.black,
                      fontSize: 10,
                    ),
                  ),
                  TextSpan(
                    text: localizations.termsAndConditionsLinkText,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri uri =
                            Uri.parse('https://printinprogress.net/terms');
                        try {
                          await launchUrl(uri);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${localizations.blogPageWasNotAbleToLaunchURLErrorLabel} $uri'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                  ),
                  TextSpan(
                    text: localizations.termsAndConditionsMiddle,
                    style: TextStyle(
                      color: themeChangeProvider.darkTheme
                          ? Colors.white
                          : Colors.black,
                      fontSize: 10,
                    ),
                  ),
                  TextSpan(
                    text: localizations.privacyPolicyLinkText,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri uri =
                            Uri.parse('https://printinprogress.net/privacy');
                        try {
                          await launchUrl(uri);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${localizations.blogPageWasNotAbleToLaunchURLErrorLabel} $uri'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                  ),
                  TextSpan(
                    text: localizations.termsAndConditionsSuffix,
                    style: TextStyle(
                      color: themeChangeProvider.darkTheme
                          ? Colors.white
                          : Colors.black,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
