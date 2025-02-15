import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/delegates/search_delegates/abstract_search_delegate.dart';
import 'package:edconnect_mobile/delegates/search_delegates/messaging_search_delegates.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/about_pages/about_page.dart';
import 'package:edconnect_mobile/pages/messaging_pages/qr_scanner_screen.dart';
import 'package:edconnect_mobile/pages/settings_pages/settings_main_page.dart';
import 'package:edconnect_mobile/signal_protocol/signal_key_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MessagingHomePage extends StatefulWidget {
  const MessagingHomePage({super.key});

  @override
  State<MessagingHomePage> createState() => _MessagingHomePageState();
}

class _MessagingHomePageState extends State<MessagingHomePage> {
  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    return Column(
      children: [
        AppBar(
          toolbarHeight: kToolbarHeight - 10,
          title: Text(
            currentColorSchemeProvider.customerName,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          actionsIconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showPIPCustomSearch(
                    context: context,
                    delegate: MessagingContactsSearchDelegate(databaseProvider),
                  );
                }),
            PopupMenuButton(
                onSelected: (result) async {
                  if (result == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings:
                              const RouteSettings(name: 'accountOverview'),
                          builder: (context) => const AccountOverview()),
                    );
                  } else if (result == 2) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            settings: const RouteSettings(name: 'about'),
                            builder: (context) => const About()));
                  } else if (result == 3) {
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         settings: const RouteSettings(name: 'createGroupChat'),
                    //         builder: (context) => const CreateGroupChat()));
                  } else if (result == 4) {
                    final String uid = FirebaseAuth.instance.currentUser!.uid;
                    final String? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            settings:
                                const RouteSettings(name: 'linkDeviceScreen'),
                            builder: (context) =>
                                ConnectNewDevice(userId: uid)));
                    if (result == 'success') {
                      setState(() {});
                    }
                  }
                },
                itemBuilder: ((context) => [
                      PopupMenuItem(
                          value: 1,
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings_outlined,
                                color: Color(int.parse(
                                    currentColorSchemeProvider.secondaryColor)),
                              ),
                              Text(AppLocalizations.of(context)!
                                  .globalSettingsLabel)
                            ],
                          )),
                      PopupMenuItem(
                          value: 2,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(int.parse(
                                    currentColorSchemeProvider.secondaryColor)),
                              ),
                              Text(AppLocalizations.of(context)!
                                  .globalAboutUsLabel)
                            ],
                          )),
                      PopupMenuItem(
                        value: 3,
                        child: Row(
                          children: [
                            Icon(
                              Icons.group_add_outlined,
                              color: Color(int.parse(
                                  currentColorSchemeProvider.secondaryColor)),
                            ),
                            Text('Create Group Chat')
                          ],
                        ),
                      ),
                      PopupMenuItem(
                          value: 4,
                          child: Row(
                            children: [
                              Icon(
                                Icons.link,
                                color: Color(int.parse(
                                    currentColorSchemeProvider.secondaryColor)),
                              ),
                              Text('Connect New Device')
                            ],
                          )),
                    ])),
          ],
        ),
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<SimpleKeyPair>(
                future: SignalKeyManager().getIdentityKeyPair(
                    FirebaseAuth.instance.currentUser!.uid,
                    databaseProvider.customerSpecificRootCollectionName),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else if (snapshot.hasError) {
                    if (snapshot.error
                        .toString()
                        .contains('Identity key pair not found.')) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_open),
                              Expanded(
                                child: Text(
                                  'New device detected. Please connect the device to your account to enable end-to-end encryption:',
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Text('An error occurred');
                    }
                  } else if (snapshot.hasData) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline),
                            Text(
                              'E2E Encryption Available',
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              // ButtonBar(
              //   alignment: MainAxisAlignment.center,
              //   children: [
              //     // ElevatedButton.icon(
              //     //   onPressed: () async {
              //     //     DataService().addNewDevice(
              //     //         FirebaseAuth.instance.currentUser!.uid,
              //     //         databaseProvider.customerSpecificRootCollectionName,
              //     //         await DeviceManager().getUniqueDeviceId(),
              //     //         databaseProvider.customerSpecificCollectionUsers);
              //     //   },
              //     //   icon: const Icon(Icons.generating_tokens),
              //     //   label: Text(
              //     //       'Generate and store keys for messaging service for this device'),
              //     // ),
              //     ElevatedButton.icon(
              //       onPressed: () async {
              //         final storage = FlutterSecureStorage();
              //         // Retrieve all keys
              //         // Step 1: Retrieve all keys from storage
              //         final allKeys = await storage.readAll();
              //         // Step 2: Filter keys that contain the specified terms
              //         final keysToDelete = allKeys.keys.where((key) =>
              //                 // key.contains('rootKey') ||
              //                 // key.contains('sendingChainKey') ||
              //                 // key.contains('receivingChainKey') ||
              //                 key.contains('session')
              //             // ||
              //             // key.contains('identityKey') ||
              //             // key.contains('signedPrekeyPair') ||
              //             // key.contains('oneTimePrekey_demo_org') ||
              //             // key.contains('ephemeralKey')
              //             );

              //         // Step 3: Delete the filtered keys from storage
              //         for (final key in keysToDelete) {
              //           await storage.delete(key: key);
              //         }

              //         final identityKeys = await storage.readAll();

              //         // Print all keys
              //         identityKeys.forEach((key, value) {
              //           print('$key: $value');
              //         });
              //       },
              //       icon: const Icon(Icons.key),
              //       label: Text('Reset all session keys'),
              //     ),
              //   ],
              // ),
            ],
          ),
        )
      ],
    );
  }
}
