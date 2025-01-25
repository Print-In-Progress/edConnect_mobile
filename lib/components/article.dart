import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/components/article_content.dart';
import 'package:edconnect_mobile/components/comment_section.dart';
import 'package:edconnect_mobile/components/dislike_button.dart';
import 'package:edconnect_mobile/components/like_button.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ArticleCard extends StatefulWidget {
  final Widget title;
  final String titleString;
  final String author;
  final String datetime;
  final String articleID;
  final String content;
  final String coverImgLink;
  final List<String> likes;
  final List<String> dislikes;

  const ArticleCard(
      {super.key,
      required this.title,
      required this.titleString,
      required this.author,
      required this.datetime,
      required this.articleID,
      required this.content,
      required this.coverImgLink,
      required this.dislikes,
      required this.likes});

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;
  bool isDisliked = false;

  @override
  void initState() {
    isLiked = widget.likes.contains(currentUser.uid);
    isDisliked = widget.dislikes.contains(currentUser.uid);
    super.initState();
  }

  void toggleLike(collection) {
    setState(() {
      isLiked = !isLiked;
      isDisliked = false;
    });

    // Access doc in Firebase
    DocumentReference articleRef =
        FirebaseFirestore.instance.collection(collection).doc(widget.articleID);

    if (isLiked) {
      articleRef.update({
        'likes': FieldValue.arrayUnion([currentUser.uid])
      });
      if (widget.dislikes.contains(currentUser.uid)) {
        articleRef.update({
          'dislikes': FieldValue.arrayRemove([currentUser.uid])
        });
      }
      FirebaseAnalytics.instance.logEvent(name: 'like', parameters: {
        'user_id': currentUser.uid,
        'article': widget.articleID,
        'timestamp': Timestamp.now().toDate().toString()
      });
    } else {
      articleRef.update({
        'likes': FieldValue.arrayRemove([currentUser.uid])
      });
      FirebaseAnalytics.instance.logEvent(name: 'like_removed', parameters: {
        'user_id': currentUser.uid,
        'article': widget.articleID,
        'timestamp': Timestamp.now().toDate().toString()
      });
    }
  }

  void toggleDislike(collection) {
    setState(() {
      isDisliked = !isDisliked;
      isLiked = false;
    });

    // Access doc in Firebase
    DocumentReference articleRef =
        FirebaseFirestore.instance.collection(collection).doc(widget.articleID);

    if (isDisliked) {
      articleRef.update({
        'dislikes': FieldValue.arrayUnion([currentUser.uid])
      });
      if (widget.likes.contains(currentUser.uid)) {
        articleRef.update({
          'likes': FieldValue.arrayRemove([currentUser.uid])
        });
      }
      FirebaseAnalytics.instance.logEvent(name: 'dislike', parameters: {
        'user_id': currentUser.uid,
        'article': widget.articleID,
        'timestamp': Timestamp.now().toDate().toString()
      });
    } else {
      articleRef.update({
        'dislikes': FieldValue.arrayRemove([currentUser.uid])
      });
      FirebaseAnalytics.instance.logEvent(name: 'dislike_removed', parameters: {
        'user_id': currentUser.uid,
        'article': widget.articleID,
        'timestamp': Timestamp.now().toDate().toString()
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);

    return Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: const RouteSettings(name: 'Article Content'),
                      builder: (context) => ArticleContent(
                            articleTitle: widget.titleString,
                            articleContent: widget.content,
                          )));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                    child: Center(
                      child: (widget.coverImgLink.isEmpty)
                          ? const AspectRatio(
                              aspectRatio: 16 / 9,
                              child: SizedBox(),
                            )
                          : AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedNetworkImage(
                                imageUrl: widget.coverImgLink,
                                fit: BoxFit.contain,
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) => Center(
                                  child: CircularProgressIndicator(
                                      value: downloadProgress.progress),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Text(AppLocalizations.of(context)!
                                      .globalImgCouldNotBeFound),
                                ),
                              ),
                            ),
                    )),
                ListTile(
                    title: widget.title,
                    subtitle: Text(
                      '${widget.author} \u2981 ${widget.datetime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          color: themeChangeProvider.darkTheme
                              ? const Color.fromRGBO(202, 196, 208, 1)
                              : Colors.grey[700]),
                    )),
                Row(
                  children: <Widget>[
                    const SizedBox(width: 10),
                    LikeButton(
                      isLiked: isLiked,
                      onTap: () {
                        toggleLike(databaseProvider
                            .customerSpecificCollectionArticles);
                      },
                      likes: widget.likes.length.toString(),
                    ),
                    DislikeButton(
                      isDisliked: isDisliked,
                      onTap: () {
                        toggleDislike(databaseProvider
                            .customerSpecificCollectionArticles);
                      },
                      dislikes: widget.dislikes.length.toString(),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                        color: themeChangeProvider.darkTheme
                            ? const Color.fromRGBO(202, 196, 208, 1)
                            : Colors.grey[700],
                        onPressed: () {
                          FirebaseAnalytics.instance
                              .logEvent(name: 'comment_section_opened');
                          showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              useSafeArea: true,
                              isScrollControlled: true,
                              builder: (context) =>
                                  CommentSection(articleID: widget.articleID));
                        },
                        icon: const Icon(Icons.comment_outlined)),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            )));
  }
}
