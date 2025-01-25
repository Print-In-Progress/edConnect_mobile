import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/connectivity_provider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/auth_pages/select_org_page.dart';
import 'package:edconnect_mobile/pages/home_page/main_page.dart';
import 'package:edconnect_mobile/pages/settings_pages/my_likes_and_dislikes_page.dart';
import 'package:edconnect_mobile/pages/settings_pages/resubmit_reg_info.dart';
import 'package:edconnect_mobile/pages/settings_pages/settings_change_name_page.dart';
import 'package:edconnect_mobile/pages/settings_pages/settings_update_email.dart';
import 'package:edconnect_mobile/pages/settings_pages/settings_update_password_page.dart';
import 'package:edconnect_mobile/pages/settings_pages/user_comment_management.dart';
import 'package:edconnect_mobile/widgets/buttons.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import '../../../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountOverview extends StatefulWidget {
  const AccountOverview({super.key});

  @override
  State<AccountOverview> createState() => _AccountOverviewState();
}

class _AccountOverviewState extends State<AccountOverview> {
  final _reauthenticatePasswordController = TextEditingController();

  bool reauthenticatePasswordVisible = false;

  Widget _buildDeleteAccountDialog(
      BuildContext context, DatabaseCollectionProvider databaseProvider) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.globalReauthenticateLabel),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!
                  .settingsPageAccountDeleteDialogContent),
              Text(AppLocalizations.of(context)!
                  .settingsPageActionRequiresReauthentification),
              TextFormField(
                obscureText: !reauthenticatePasswordVisible,
                controller: _reauthenticatePasswordController,
                decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(
                        reauthenticatePasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          reauthenticatePasswordVisible =
                              !reauthenticatePasswordVisible;
                        });
                      },
                    ),
                    hintText:
                        AppLocalizations.of(context)!.globalPasswordLabel),
              ),
            ],
          ),
          actions: [
            const PIPCancelButton(),
            PIPDialogTextButton(
                label: 'Ok',
                onPressed: () async {
                  FirebaseAuth.instance.currentUser!
                      .reauthenticateWithCredential(
                          EmailAuthProvider.credential(
                              email: FirebaseAuth.instance.currentUser!.email!,
                              password: _reauthenticatePasswordController.text))
                      .then((value) async {
                    // Create a batch instance
                    var batch = FirebaseFirestore.instance.batch();

                    // Fetch all documents from the comments collection where author_uid matches the user's UID
                    var querySnapshot = await FirebaseFirestore.instance
                        .collection(
                            databaseProvider.customerSpecificCollectionComments)
                        .where('author_uid',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                        .get();
                    for (var doc in querySnapshot.docs) {
                      batch.update(doc.reference,
                          {'author_full_name': '', 'author_uid': ''});
                    }

                    // Add the delete operation for the user's document to the batch
                    var userDocRef = FirebaseFirestore.instance
                        .collection(
                            databaseProvider.customerSpecificCollectionUsers)
                        .doc(FirebaseAuth.instance.currentUser!.uid);
                    batch.delete(userDocRef);

                    // Commit the batch
                    await batch.commit();

                    // Delete the user's folder in Cloud Storage
                    try {
                      var userFolderRef = FirebaseStorage.instance.ref().child(
                          '${databaseProvider.customerSpecificCollectionFiles}/user_data/${FirebaseAuth.instance.currentUser!.uid}');
                      var listResult = await userFolderRef.listAll();
                      var deleteFutures = listResult.items
                          .map((item) => item.delete())
                          .toList();
                      await Future.wait(deleteFutures);
                    } on Exception catch (e) {
                      if (!context.mounted) return;
                      errorMessage(
                          context,
                          AppLocalizations.of(context)!
                              .settingsPageErrorDeletingUserFolder(
                                  e.toString()));
                    }

                    // Delete the user's account from Firebase Authentication
                    await FirebaseAuth.instance.currentUser!.delete();

                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    successMessage(
                        context,
                        AppLocalizations.of(context)!
                            .settingsPageSuccessOnDeleteAccountSnackbarLabel);
                  }).catchError((e) {
                    Navigator.of(context).pop();
                    errorMessage(context, e.toString());
                  });
                })
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _reauthenticatePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);

    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    bool connectivity = !connectivityProvider.connectivityResults
        .contains(ConnectivityResult.none);

    return Scaffold(
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
      padding: const EdgeInsets.all(8.0),
      child: SafeArea(
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: true,
                floating: true,
                snap: true,
                forceMaterialTransparency: true,
                actionsIconTheme: const IconThemeData(color: Colors.white),
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  AppLocalizations.of(context)!.globalSettingsLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            ];
          },
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name and Profile Picture
//                SizedBox(
//                    width: MediaQuery.of(context).size.width < 700
//                        ? MediaQuery.of(context).size.width
//                        : MediaQuery.of(context).size.width / 2,
//                    child: Card(
//                      child: Column(
//                        mainAxisSize: MainAxisSize.min,
//                        children: [],
//                      ),
//                    )),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 700
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2,
                  child: Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            AppLocalizations.of(context)!
                                .settingsPageManageAccountCardLabel,
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),

                        // Change Name Button
                        TextButton.icon(
                          icon: Icon(
                            Icons.abc,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .settingsPageChangeNameButtonLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeChangeProvider.darkTheme
                                      ? Colors.white
                                      : Color(int.parse(
                                          currentColorSchemeProvider
                                              .primaryColor)),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            if (connectivity) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      settings: const RouteSettings(
                                          name: 'Settings Change Name Page'),
                                      builder: (context) {
                                        return const AccountName();
                                      }));
                            } else {
                              errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .globalNoInternetConnectionErrorLabel);
                              return;
                            }
                          },
                        ),

                        // Change Email Button
                        TextButton.icon(
                          icon: Icon(
                            Icons.email_outlined,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.globalEmailLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeChangeProvider.darkTheme
                                      ? Colors.white
                                      : Color(int.parse(
                                          currentColorSchemeProvider
                                              .primaryColor)),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            if (connectivity) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      settings: const RouteSettings(
                                          name: 'Settings Change Email Screen'),
                                      builder: (context) {
                                        return const ChangeEmail();
                                      }));
                            } else {
                              errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .globalNoInternetConnectionErrorLabel);
                              return;
                            }
                          },
                        ),

                        // Change Password Button
                        TextButton.icon(
                          icon: Icon(
                            Icons.password,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .globalPasswordLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeChangeProvider.darkTheme
                                      ? Colors.white
                                      : Color(int.parse(
                                          currentColorSchemeProvider
                                              .primaryColor)),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            if (connectivity) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      settings: const RouteSettings(
                                          name:
                                              'Settings Change Password Screen'),
                                      builder: (context) {
                                        return const AccountPassword();
                                      }));
                            } else {
                              errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .globalNoInternetConnectionErrorLabel);
                              return;
                            }
                          },
                        ),

                        // Resubmit Registration Information Button
                        TextButton.icon(
                          icon: Icon(
                            Icons.app_registration,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  // Resubmit Questionnaire
                                  AppLocalizations.of(context)!
                                      .settingsPageResubmitQuestionaire,
                                  style: TextStyle(
                                    fontSize: 17,
                                    overflow: TextOverflow.ellipsis,
                                    color: themeChangeProvider.darkTheme
                                        ? Colors.white
                                        : Color(int.parse(
                                            currentColorSchemeProvider
                                                .primaryColor)),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            if (connectivity) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(
                                        name: 'resubmitRegInfo'),
                                    builder: (context) {
                                      return const ResubmitRegInfo();
                                    },
                                  ));
                            } else {
                              errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .globalNoInternetConnectionErrorLabel);
                              return;
                            }
                          },
                        ),

                        // Change Organization Button
                        TextButton.icon(
                          icon: Icon(
                            Icons.corporate_fare_outlined,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .settingsPageChangeOrganizationButtonLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeChangeProvider.darkTheme
                                      ? Colors.white
                                      : Color(int.parse(
                                          currentColorSchemeProvider
                                              .primaryColor)),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            if (connectivity) {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    settings:
                                        const RouteSettings(name: 'selectOrg'),
                                    builder: (context) {
                                      return const SelectOrgPage();
                                    },
                                  ));
                            } else {
                              errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .globalNoInternetConnectionErrorLabel);
                              return;
                            }
                          },
                        ),
/*
                        TextButton.icon(
                          icon: Icon(
                            Icons.download,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Konto-Info anfragen',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeChangeProvider.darkTheme
                                      ? Colors.white
                                      : Color(int.parse(
                                          currentColorSchemeProvider
                                              .primaryColor)),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            if (connectivity) {
                            } else {
                              errorMessage(context, 'No Internet Connection');
                              return;
                            }
                          },
                        ),
*/
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: MediaQuery.of(context).size.width < 700
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2,
                  child: Card(
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          AppLocalizations.of(context)!
                              .settingsPageAppearanceCardLabel,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!
                              .settingsPageEnableDarkModeSwitchTileLabel,
                          style: TextStyle(
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                        ),
                        value: themeChangeProvider.darkTheme,
                        onChanged: (value) {
                          themeChangeProvider.darkTheme = value;
                        },
                        secondary: themeChangeProvider.darkTheme
                            ? const Icon(Icons.light_mode_outlined)
                            : const Icon(Icons.dark_mode_outlined),
                      )
                    ]),
                  ),
                ),

                SizedBox(
                  width: MediaQuery.of(context).size.width < 700
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2,
                  child: Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            AppLocalizations.of(context)!
                                .settingsPageMyActivityCardLabel,
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(
                            Icons.thumbs_up_down_outlined,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .settingsPageMyLikesAndDislikesButtonLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeChangeProvider.darkTheme
                                      ? Colors.white
                                      : Color(int.parse(
                                          currentColorSchemeProvider
                                              .primaryColor)),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    settings: const RouteSettings(
                                        name:
                                            'Settings My Like/Dislikes Screen'),
                                    builder: (context) {
                                      return const MyLikesAndDislikesPage();
                                    }));
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(
                            Icons.comment_outlined,
                            size: 30,
                            color: themeChangeProvider.darkTheme
                                ? Colors.white
                                : Color(int.parse(
                                    currentColorSchemeProvider.primaryColor)),
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .settingsPageMyCommentsButtonLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeChangeProvider.darkTheme
                                      ? Colors.white
                                      : Color(int.parse(
                                          currentColorSchemeProvider
                                              .primaryColor)),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: themeChangeProvider.darkTheme
                                    ? Colors.white
                                    : Color(int.parse(currentColorSchemeProvider
                                        .primaryColor)),
                              )
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    settings: const RouteSettings(
                                        name: 'Settings My Comments Page'),
                                    builder: (context) {
                                      return const MyCommentsPage();
                                    }));
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Logout Button
                SizedBox(
                  width: MediaQuery.of(context).size.width < 700
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2,
                  child: Card(
                    child: Column(
                      children: [
                        TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .globalLogoutButtonLabel,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 17),
                              ),
                              const Icon(Icons.logout, color: Colors.red)
                            ],
                          ),
                          onPressed: () async {
                            if (connectivity) {
                              await FirebaseAuth.instance
                                  .signOut()
                                  .then((value) {
                                Navigator.pop(context);
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      settings:
                                          const RouteSettings(name: 'main'),
                                      builder: (context) => const MainPage()),
                                );
                              });
                            } else {
                              errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .globalNoInternetConnectionErrorLabel);
                              return;
                            }
                          },
                        ),

                        // Delete Button
                        TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .settingsPageDeletePIPAccountButtonLabel,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 17),
                              ),
                              const Icon(Icons.delete, color: Colors.red)
                            ],
                          ),
                          onPressed: () async {
                            if (connectivity) {
                              await showDialog(
                                  context: context,
                                  builder: ((BuildContext context) {
                                    return _buildDeleteAccountDialog(
                                        context, databaseProvider);
                                  }));
                            } else {
                              errorMessage(
                                  context,
                                  AppLocalizations.of(context)!
                                      .globalNoInternetConnectionErrorLabel);
                              return;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
