import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/connectivity_provider.dart';
import 'package:edconnect_mobile/models/firebase_messaging_api.dart';
import 'package:edconnect_mobile/models/providers/modulesprovider.dart';
import 'package:edconnect_mobile/models/providers/orgprovider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/auth_pages/select_org_page.dart';
import 'package:edconnect_mobile/pages/home_page/main_page.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // catches all asynchronous errors
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    FirebaseCrashlytics.instance
        .recordError(exception, stackTrace, fatal: true);
    return true;
  };

  await FirebaseMessagingApi().initNotifications();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  findSystemLocale();
  runApp(const NewsApp());
}

class NewsApp extends StatefulWidget {
  const NewsApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  ThemeProvider themeChangeProvider = ThemeProvider();
  OrgProvider currentOrgProvider = OrgProvider();
  DatabaseCollectionProvider databaseProvider = DatabaseCollectionProvider();
  ColorANDLogoProvider currentColorSchemeProvider = ColorANDLogoProvider();
  UserModulesProvider userModulesProvider = UserModulesProvider();
  ConnectivityProvider connectivityProvider = ConnectivityProvider();
  StreamSubscription? _userModulesSubscription;

  @override
  void initState() {
    super.initState();
    currentOrgProvider = OrgProvider(fetchUserModules: fetchUserModules);
    initializeDateFormatting();
    getCurrentAppTheme();
    getCurrentAppOrg();
    setRootCollection();
    initializeColorScheme();
    fetchUserModules();

    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.themePreference.getTheme();
  }

  void getCurrentAppOrg() async {
    currentOrgProvider.org = await currentOrgProvider.currentOrg.getOrg();
  }

  void setRootCollection() async {
    databaseProvider
        .setRootCollection(await currentOrgProvider.currentOrg.getOrg());
  }

  void initializeColorScheme() async {
    if (await currentOrgProvider.currentOrg.getOrg() != '') {
      DocumentSnapshot<Map<String, dynamic>> orgRef = await FirebaseFirestore
          .instance
          .collection(await currentOrgProvider.currentOrg.getOrg())
          .doc('newsapp')
          .get();
      String primaryColor = orgRef['primary_color'];
      primaryColor = '0xFF${primaryColor.replaceAll('#', '')}';
      String secondaryColor = orgRef['secondary_color'];
      secondaryColor = '0xFF${secondaryColor.replaceAll('#', '')}';
      String logoLink = orgRef['logo_link'];
      if (primaryColor.isNotEmpty && primaryColor != '0xFF') {
        currentColorSchemeProvider.setPrimaryColor(primaryColor);
      } else {
        currentColorSchemeProvider.setPrimaryColor('0xFF192B4C');
      }
      if (secondaryColor.isNotEmpty && secondaryColor != '0xFF') {
        currentColorSchemeProvider.setSecondaryColor(secondaryColor);
      } else {
        currentColorSchemeProvider.setSecondaryColor('0xFF01629C');
      }
      if (logoLink.isNotEmpty && logoLink != '') {
        final checkURL = await http.head(Uri.parse(logoLink));
        if (checkURL.statusCode == 200) {
          currentColorSchemeProvider.setLogoLink(logoLink);
        } else {
          currentColorSchemeProvider.setLogoLink('');
        }
      }
    } else {
      currentColorSchemeProvider.setPrimaryColor('0xFF192B4C');
      currentColorSchemeProvider.setSecondaryColor('0xFF01629C');
    }
    currentColorSchemeProvider.customerName =
        await currentColorSchemeProvider.colors.getCustomerName();
  }

  void fetchUserModules() async {
    if (await currentOrgProvider.currentOrg.getOrg() != '') {
      _userModulesSubscription = FirebaseFirestore.instance
          .collection(await currentOrgProvider.currentOrg.getOrg())
          .doc('newsapp')
          .snapshots()
          .listen((DocumentSnapshot<Map<String, dynamic>> orgRef) {
        List<String> userModules = List<String>.from(orgRef['modules']);
        userModulesProvider.userModules = userModules;
      });
    }
  }

  @override
  void dispose() {
    _userModulesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) {
            return themeChangeProvider;
          }),
          ChangeNotifierProvider(create: (context) {
            return currentOrgProvider;
          }),
          ChangeNotifierProvider(create: (context) {
            return databaseProvider;
          }),
          ChangeNotifierProvider(create: (context) {
            return currentColorSchemeProvider;
          }),
          ChangeNotifierProvider(create: (context) {
            return userModulesProvider;
          }),
          ChangeNotifierProvider(create: (context) {
            return connectivityProvider;
          }),
        ],
        child: Consumer6<ThemeProvider, OrgProvider, DatabaseCollectionProvider,
            ColorANDLogoProvider, UserModulesProvider, ConnectivityProvider>(
          builder: (context,
              themeProvider,
              orgProvider,
              databaseProvider,
              currentColorSchemeProvider,
              userModulesProvider,
              connectivityProvider,
              child) {
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              debugShowCheckedModeBanner: false,
              title: currentColorSchemeProvider.customerName,
              routes: {
                '/main': (context) => const MainPage(),
                '/selectOrg': (context) => const SelectOrgPage(),
              },
              navigatorObservers: [NewsApp.observer],
              themeMode: themeChangeProvider.darkTheme
                  ? ThemeMode.dark
                  : ThemeMode.light,
              darkTheme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Inter',
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white, iconColor: Colors.white),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
                colorScheme: ColorScheme.dark(
                  primary:
                      Color(int.parse(currentColorSchemeProvider.primaryColor)),
                  onPrimary: Colors.white,
                  secondary: Color(
                      int.parse(currentColorSchemeProvider.secondaryColor)),
                  onSecondary: Colors.white,
                  background: Colors.grey.shade900,
                  surface: Colors.grey.shade900,
                  shadow: Colors.grey.shade700,
                ),
                tabBarTheme: const TabBarTheme(
                  dividerColor: Colors.transparent,
                  indicatorColor: Color.fromRGBO(202, 196, 208, 1),
                  labelColor: Color.fromRGBO(202, 196, 208, 1),
                ),
                navigationRailTheme: const NavigationRailThemeData(
                    selectedIconTheme:
                        IconThemeData(color: Color.fromRGBO(202, 196, 208, 1)),
                    unselectedIconTheme:
                        IconThemeData(color: Color.fromRGBO(202, 196, 208, 1)),
                    unselectedLabelTextStyle:
                        TextStyle(color: Color.fromRGBO(202, 196, 208, 1)),
                    selectedLabelTextStyle:
                        TextStyle(color: Color.fromRGBO(202, 196, 208, 1))),
                primaryColor:
                    Color(int.parse(currentColorSchemeProvider.primaryColor)),
              ),
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Inter',
                colorScheme: ColorScheme.light(
                  primary:
                      Color(int.parse(currentColorSchemeProvider.primaryColor)),
                  onPrimary: Colors.white,
                  secondary: Color(
                      int.parse(currentColorSchemeProvider.secondaryColor)),
                  onSecondary: Colors.white,
                ),
                tabBarTheme: const TabBarTheme(
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                ),
                primaryColor:
                    Color(int.parse(currentColorSchemeProvider.primaryColor)),
              ),
              home:
                  currentOrgProvider.org == '' || currentOrgProvider.org.isEmpty
                      ? const SelectOrgPage()
                      : const MainPage(),
            );
          },
        ));
  }
}
