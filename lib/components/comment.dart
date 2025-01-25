import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/components/comment_section_replies.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Comment extends StatelessWidget {
  final String content;
  final String author;
  final Timestamp timestamp;
  final String commentID;
  final bool reply;

  const Comment(
      {super.key,
      required this.content,
      required this.author,
      required this.timestamp,
      required this.commentID,
      required this.reply});

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    return InkWell(
      onTap: () {
        if (reply) {
          FirebaseAnalytics.instance.logEvent(name: 'replies_section_opened');
          showModalBottomSheet(
              context: context,
              showDragHandle: true,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) =>
                  CommentSectionReplies(commentID: commentID));
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  author,
                  style: TextStyle(
                      color: themeChangeProvider.darkTheme
                          ? const Color.fromRGBO(202, 196, 208, 1)
                          : Colors.grey[700],
                      fontSize: 12),
                ),
                Text(' \u2981 ',
                    style: TextStyle(
                      color: themeChangeProvider.darkTheme
                          ? const Color.fromRGBO(202, 196, 208, 1)
                          : Colors.grey[700],
                    )),
                Text(
                  DateFormat.yMd()
                      .add_jm()
                      .format(timestamp.toDate())
                      .toString(),
                  style: TextStyle(
                      color: themeChangeProvider.darkTheme
                          ? const Color.fromRGBO(202, 196, 208, 1)
                          : Colors.grey[700],
                      fontSize: 12),
                )
              ],
            ),
            const SizedBox(height: 5),
            ReadMoreText(
              content,
              trimLines: 3,
              style: const TextStyle(fontSize: 18),
              trimMode: TrimMode.Line,
              trimCollapsedText: AppLocalizations.of(context)!
                  .commentSectionReadMoreTextButtonLabel,
              trimExpandedText: AppLocalizations.of(context)!
                  .commentSectionShowLessTextButtonLabel,
            ),
            reply
                ? TextButton(
                    onPressed: () {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'replies_section_opened');
                      showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          useSafeArea: true,
                          isScrollControlled: true,
                          builder: (context) =>
                              CommentSectionReplies(commentID: commentID));
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(AppLocalizations.of(context)!
                        .commentSectionRepliesTitle),
                  )
                : const SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}
