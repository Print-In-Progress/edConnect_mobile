import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/settings_pages/user_comment_management_comment_card.dart';
import 'package:provider/provider.dart';

class MyCommentsPage extends StatefulWidget {
  const MyCommentsPage({super.key});

  @override
  State<MyCommentsPage> createState() => _MyCommentsPageState();
}

class _MyCommentsPageState extends State<MyCommentsPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);

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
          child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    toolbarHeight: kToolbarHeight,
                    automaticallyImplyLeading: true,
                    floating: true,
                    snap: true,
                    forceMaterialTransparency: true,
                    title: Text(
                        style: const TextStyle(color: Colors.white),
                        AppLocalizations.of(context)!
                            .settingsPageMyCommentsPageTitle),
                    actionsIconTheme: const IconThemeData(color: Colors.white),
                    iconTheme: const IconThemeData(color: Colors.white),
                  )
                ];
              },
              body: Column(
                children: [
                  Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(databaseProvider
                                  .customerSpecificCollectionComments)
                              .where('author_uid', isEqualTo: currentUser.uid)
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ListView.builder(
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: ((context, index) {
                                    final comment = snapshot.data!.docs[index];
                                    return CommentUserSettingsCard(
                                        commentID: comment.id,
                                        content: comment['content'],
                                        author: comment['author_full_name'],
                                        timestamp: comment['timestamp']);
                                  }));
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          })),
                ],
              )),
        ),
      ),
    );
  }
}
