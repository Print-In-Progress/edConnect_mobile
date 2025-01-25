import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/orgprovider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/home_page/main_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class SelectOrgPage extends StatefulWidget {
  const SelectOrgPage({super.key});

  @override
  State<SelectOrgPage> createState() => _SelectOrgPageState();
}

class _SelectOrgPageState extends State<SelectOrgPage> {
  String selectedOrg = '';
  String selectedOrgName = '';

  bool validateOrgField = false;
  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final orgChangeProvider = Provider.of<OrgProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
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
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width < 700
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2,
                  child: Card(
                    elevation: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // NewsApp Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                                child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: (themeChangeProvider.darkTheme)
                                  ? (AppLocalizations.of(context)!.language ==
                                          'Deutsch')
                                      ? Image.asset(
                                          'assets/NewsApp_Logo_Mobilexxhdpi.png')
                                      : Image.asset(
                                          'assets/NewsApp_Logo_Mobilexxhdpi.png')
                                  : (AppLocalizations.of(context)!.language ==
                                          'Deutsch')
                                      ? Image.asset(
                                          'assets/NewsApp_Logo_Mobilexxhdpi.png')
                                      : Image.asset(
                                          'assets/NewsApp_Logo_Mobilexxhdpi.png'),
                            )),
                            Flexible(
                                child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: themeChangeProvider.darkTheme
                                  ? Image.asset(
                                      'assets/pip_branding_dark_mode_verticalxxxhdpi.png')
                                  : Image.asset(
                                      'assets/pip_branding_light_mode_verticalxxxhdpi.png'),
                            ))
                          ],
                        ),

                        // Greeting
                        Text(
                          AppLocalizations.of(context)!
                              .authPagesWelcomeLabelOne,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 36),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .authPagesSelectOrganizationLabel,
                          style: const TextStyle(fontSize: 18.5),
                        ),
                        const SizedBox(
                          height: 25,
                        ),

                        const SizedBox(height: 15),

                        StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection("general_info")
                                .doc('customer_list')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.data == null) {
                                return const SizedBox.shrink();
                              }
                              if (snapshot.hasData) {
                                Map<String, dynamic> customerMap =
                                    snapshot.data!['customers'];
                                return DropdownMenu(
                                    requestFocusOnTap: true,
                                    enableFilter: true,
                                    enableSearch: true,
                                    expandedInsets: const EdgeInsets.all(8),
                                    errorText: validateOrgField ? '' : null,
                                    onSelected: (value) {
                                      selectedOrg = value.key;
                                      selectedOrgName = value.value;
                                    },
                                    dropdownMenuEntries: customerMap.entries
                                        .map<DropdownMenuEntry>((entry) {
                                      return DropdownMenuEntry(
                                          value: entry, label: entry.value);
                                    }).toList());
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            }),

                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: OutlinedButton(
                              onPressed: () async {
                                if (selectedOrg.isEmpty) {
                                  setState(() {
                                    validateOrgField = true;
                                  });
                                  return;
                                } else {
                                  setState(() {
                                    validateOrgField = false;
                                  });
                                }
                                orgChangeProvider.org = selectedOrg;
                                databaseProvider.setRootCollection(selectedOrg);
                                DocumentSnapshot<Map<String, dynamic>> orgRef =
                                    await FirebaseFirestore.instance
                                        .collection(selectedOrg)
                                        .doc('newsapp')
                                        .get();
                                String primaryColor = orgRef['primary_color'];
                                primaryColor =
                                    '0xFF${primaryColor.replaceAll('#', '')}';
                                String secondaryColor =
                                    orgRef['secondary_color'];
                                secondaryColor =
                                    '0xFF${secondaryColor.replaceAll('#', '')}';
                                String logoLink = orgRef['logo_link'];

                                if (primaryColor.isNotEmpty &&
                                    primaryColor != '0xFF') {
                                  currentColorSchemeProvider
                                      .setPrimaryColor(primaryColor);
                                } else {
                                  currentColorSchemeProvider
                                      .setPrimaryColor('0xFF192B4C');
                                }
                                if (secondaryColor.isNotEmpty &&
                                    primaryColor != '0xFF') {
                                  currentColorSchemeProvider
                                      .setSecondaryColor(secondaryColor);
                                } else {
                                  currentColorSchemeProvider
                                      .setSecondaryColor('0xFF01629C');
                                }
                                if (logoLink.isNotEmpty && logoLink != '') {
                                  final checkURL =
                                      await http.head(Uri.parse(logoLink));
                                  if (checkURL.statusCode == 200) {
                                    currentColorSchemeProvider
                                        .setLogoLink(logoLink);
                                  } else {
                                    currentColorSchemeProvider.setLogoLink('');
                                  }
                                } else {
                                  currentColorSchemeProvider.setLogoLink('');
                                }
                                currentColorSchemeProvider
                                    .setCustomerName(selectedOrgName);
                                if (!context.mounted) return;
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        settings:
                                            const RouteSettings(name: 'main'),
                                        builder: (context) =>
                                            const MainPage()));
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(AppLocalizations.of(context)!
                                      .globalContinueButtonLabel),
                                  const Icon(Icons.arrow_forward_rounded)
                                ],
                              )),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
