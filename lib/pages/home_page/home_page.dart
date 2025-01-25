import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/connectivity_provider.dart';
import 'package:edconnect_mobile/models/providers/modulesprovider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/pages/events_pages/events_page.dart';
import 'package:edconnect_mobile/pages/home_page/components/newspaper_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/pages/messaging_pages/messaging_home_page.dart';
import 'package:edconnect_mobile/pages/surveys_pages/surveys_page.dart';
import 'package:edconnect_mobile/utils/device_manager.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final AppUser currentUser;
  const HomePage({super.key, required this.currentUser});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions = <Widget>[
    const Newspaper(),
    Events(
      currentUser: widget.currentUser,
    ),
    Surveys(
      groups: widget.currentUser.groups,
    ),
    const MessagingHomePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      checkIfNewDevice();
    });
  }

  void checkIfNewDevice() async {
    final databaseProvider =
        Provider.of<DatabaseCollectionProvider>(context, listen: false);
    final DeviceManager deviceManager = DeviceManager();
    final String currentDeviceId = await deviceManager.getUniqueDeviceId();
    if (!widget.currentUser.deviceIds.keys.contains(currentDeviceId)) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      FirebaseFirestore.instance
          .collection(databaseProvider.customerSpecificCollectionUsers)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'fcm_token': FieldValue.arrayUnion([fcmToken])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final userModulesProvider = Provider.of<UserModulesProvider>(context);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    FirebaseAnalytics.instance
        .setUserId(id: FirebaseAuth.instance.currentUser!.uid);
    FirebaseAnalytics.instance.setUserProperty(
        name: 'parent_organization',
        value: databaseProvider.customerSpecificRootCollectionName);
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
            child: Column(
          children: [
            if (connectivityProvider.connectivityResults
                .contains(ConnectivityResult.none))
              MaterialBanner(
                content: Text(
                    AppLocalizations.of(context)!.globalOfflineBannerLabel),
                backgroundColor: Colors.red,
                contentTextStyle: TextStyle(color: Colors.white),
                actions: [SizedBox.shrink()],
              ),
            Expanded(
              child: MediaQuery.of(context).size.width > 700 &&
                      MediaQuery.of(context).orientation ==
                          Orientation.landscape
                  ? Row(
                      children: [
                        NavigationRail(
                            labelType: NavigationRailLabelType.all,
                            onDestinationSelected: (int index) {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            groupAlignment: 0.0,
                            destinations: <NavigationRailDestination>[
                              if (userModulesProvider.userModules
                                  .contains('newspaper'))
                                NavigationRailDestination(
                                    icon: const Icon(Icons.article_outlined),
                                    selectedIcon: const Icon(Icons.article),
                                    label: Text(AppLocalizations.of(context)!
                                        .homePageBlogNavbarButtonLabel)),
                              if (userModulesProvider.userModules
                                  .contains('events'))
                                NavigationRailDestination(
                                    icon: const Icon(Icons.event_outlined),
                                    selectedIcon: const Icon(Icons.event),
                                    label: Text(AppLocalizations.of(context)!
                                        .homePageEventsNavbarButtonLabel)),
                              if (userModulesProvider.userModules
                                      .contains('surveys') ||
                                  userModulesProvider.userModules
                                      .contains('sorting'))
                                NavigationRailDestination(
                                    icon: const Icon(Icons.checklist_outlined),
                                    selectedIcon: const Icon(Icons.checklist),
                                    label: Text(AppLocalizations.of(context)!
                                        .surveysPagesNavbarButtonLabel)),
                              if (userModulesProvider.userModules
                                  .contains('messaging'))
                                NavigationRailDestination(
                                    icon: const Icon(Icons.chat_outlined),
                                    selectedIcon: const Icon(Icons.chat),
                                    label: Text(AppLocalizations.of(context)!
                                        .homePageMessagingNavbarButtonLabel)),
                            ],
                            selectedIndex: _selectedIndex),
                        Expanded(
                            child: _widgetOptions.elementAt(_selectedIndex))
                      ],
                    )
                  : _widgetOptions.elementAt(_selectedIndex),
            ),
          ],
        )),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 700 ||
              MediaQuery.of(context).orientation == Orientation.portrait
          ? NavigationBar(
              height: 60,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: <NavigationDestination>[
                  NavigationDestination(
                      selectedIcon: const Icon(Icons.newspaper),
                      icon: const Icon(Icons.newspaper_outlined),
                      label: AppLocalizations.of(context)!
                          .homePageBlogNavbarButtonLabel),
                  NavigationDestination(
                      selectedIcon: const Icon(Icons.event),
                      icon: const Icon(Icons.event_outlined),
                      label: AppLocalizations.of(context)!
                          .homePageEventsNavbarButtonLabel),
                  NavigationDestination(
                      selectedIcon: const Icon(Icons.checklist),
                      icon: const Icon(Icons.checklist_outlined),
                      label: AppLocalizations.of(context)!
                          .surveysPagesNavbarButtonLabel),
                  NavigationDestination(
                      selectedIcon: const Icon(Icons.chat),
                      icon: const Icon(Icons.chat_outlined),
                      label: AppLocalizations.of(context)!
                          .homePageMessagingNavbarButtonLabel),
                ])
          : const SizedBox.shrink(),
    );
  }
}
