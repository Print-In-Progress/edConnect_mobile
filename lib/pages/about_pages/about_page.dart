import 'package:about/about.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    return AboutPage(
      values: {
        'version': '1.0.0',
        'buildNumber': '1',
        'year': DateTime.now().year.toString(),
        'author': 'Print In Progress LLC',
      },
      title: Text(AppLocalizations.of(context)!.globalAboutUsLabel),
      applicationName: '${currentColorSchemeProvider.customerName} NewsApp',
      applicationVersion: 'Version 1.0.0, build #3',
      applicationDescription: Text(
        AppLocalizations.of(context)!.aboutPageAppDescription,
        textAlign: TextAlign.justify,
      ),
      applicationIcon: themeChangeProvider.darkTheme
          ? FractionallySizedBox(
              widthFactor: MediaQuery.of(context).size.width < 700 ||
                      MediaQuery.of(context).orientation == Orientation.portrait
                  ? 1
                  : 0.5,
              child: Image.asset(
                  'assets/pip_branding_dark_mode_verticalxxxhdpi.png'))
          : FractionallySizedBox(
              widthFactor: MediaQuery.of(context).size.width < 700 ||
                      MediaQuery.of(context).orientation == Orientation.portrait
                  ? 1
                  : 0.5,
              child: Image.asset(
                  'assets/pip_branding_light_mode_verticalxxxhdpi.png')),
      applicationLegalese:
          'Copyright © Print In Progress LLC, ${DateTime.now().year.toString()}',
      children: <Widget>[
        ListTile(
          title: Text(AppLocalizations.of(context)!.aboutPageToSLabel),
          leading: const Icon(Icons.toc),
          trailing: const Icon(Icons.arrow_forward_ios_rounded),
          onTap: () async {
            final uri = Uri.parse("https://printinprogress.net/terms");
            await launchUrl(uri);
          },
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.globalPrivacyPolicyLabel),
          leading: const Icon(Icons.private_connectivity_rounded),
          trailing: const Icon(Icons.arrow_forward_ios_rounded),
          onTap: () async {
            final uri = Uri.parse("https://printinprogress.net/privacy");
            await launchUrl(uri);
          },
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.aboutPageLegalNoticeLabel),
          leading: const Icon(Icons.gavel_rounded),
          trailing: const Icon(Icons.arrow_forward_ios_rounded),
          onTap: () async {
            final uri = Uri.parse("https://printinprogress.net/legal");
            await launchUrl(uri);
          },
        ),
        LicensesPageListTile(
          title: Text(
              AppLocalizations.of(context)!.aboutPageOpenSourceLicencesLabel),
          icon: const Icon(Icons.favorite),
        ),
      ],
    );
  }
}
