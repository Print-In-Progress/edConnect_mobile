import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edconnect_mobile/components/comment.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CommentSection extends StatefulWidget {
  final String articleID;
  const CommentSection({super.key, required this.articleID});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  final _sheet = GlobalKey();

  Future<String?> getUserName() async {
    final databaseProvider =
        Provider.of<DatabaseCollectionProvider>(context, listen: false);

    String? userName;

    final value = await FirebaseFirestore.instance
        .collection(databaseProvider.customerSpecificCollectionUsers)
        .doc(currentUser.uid)
        .get();
    if (value.exists) {
      var data = value.data();
      userName = '${data?['first_name']} ${data?['last_name']}';
    } else {}
    return userName;
  }

  void postMessage() async {
    final databaseProvider =
        Provider.of<DatabaseCollectionProvider>(context, listen: false);

    if (_commentController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection(databaseProvider.customerSpecificCollectionComments)
          .add({
        'author_uid': currentUser.uid,
        'parent_article_uid': widget.articleID,
        'content': _commentController.text,
        'timestamp': Timestamp.now(),
        'author_full_name': await getUserName(),
      });
    }

    FirebaseAnalytics.instance.logEvent(name: 'post_comment', parameters: {
      'content': _commentController.text,
      'timestamp': Timestamp.now().toDate().toString(),
      'auhtor_uid': currentUser.uid,
      'parent_article_uid': widget.articleID
    });

    setState(() {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);

    return DraggableScrollableSheet(
        key: _sheet,
        snap: true,
        expand: false,
        snapSizes: const [0.7, 1.0],
        minChildSize: 0.6,
        initialChildSize: 0.7,
        maxChildSize: 1.0,
        builder: (_, controller) => StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(databaseProvider.customerSpecificCollectionComments)
                .where('parent_article_uid', isEqualTo: widget.articleID)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 0, bottom: 0),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .commentSectionAppbarTitle,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              snapshot.data!.docs.length.toString(),
                              style: TextStyle(
                                  color: themeChangeProvider.darkTheme
                                      ? const Color.fromRGBO(202, 196, 208, 1)
                                      : Colors.grey[700],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400),
                            ),
                            const Spacer(),
                            IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.close_rounded)),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 0,
                      ),
                      Expanded(
                          child: ListView.builder(
                              controller: controller,
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: ((context, index) {
                                final comment = snapshot.data!.docs[index];
                                return Comment(
                                    reply: true,
                                    commentID: comment.id,
                                    content: comment['content'],
                                    author: comment['author_full_name'],
                                    timestamp: comment['timestamp']);
                              }))),
                      Container(
                        color: Color(
                            int.parse(currentColorSchemeProvider.primaryColor)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 15,
                            bottom: 5,
                            top: 5,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 100),
                                child: TextField(
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(1000)
                                  ],
                                  style: const TextStyle(color: Colors.white),
                                  controller: _commentController,
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(10),
                                      hintText: AppLocalizations.of(context)!
                                          .commentSectionAddCommentHintTextLabel,
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: const OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.white))),
                                ),
                              )),
                              IconButton(
                                  onPressed: postMessage,
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                  ))
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error:${snapshot.error}'),
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 0, bottom: 0),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .commentSectionAppbarTitle,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 0,
                  ),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            }));
  }
}
