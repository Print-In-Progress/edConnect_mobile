import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/connectivity_provider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/buttons.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:readmore/readmore.dart';

class CommentUserSettingsCard extends StatefulWidget {
  final String content;
  final String author;
  final String commentID;
  final Timestamp timestamp;

  const CommentUserSettingsCard(
      {super.key,
      required this.content,
      required this.author,
      required this.commentID,
      required this.timestamp});

  @override
  State<CommentUserSettingsCard> createState() =>
      _CommentUserSettingsCardState();
}

class _CommentUserSettingsCardState extends State<CommentUserSettingsCard> {
  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final connectivtiyProvider = Provider.of<ConnectivityProvider>(context);
    return Card(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.author,
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
                            .format(widget.timestamp.toDate())
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
                    widget.content,
                    trimLines: 3,
                    style: const TextStyle(fontSize: 18),
                    trimMode: TrimMode.Line,
                    trimCollapsedText: AppLocalizations.of(context)!
                        .commentSectionReadMoreTextButtonLabel,
                    trimExpandedText: AppLocalizations.of(context)!
                        .commentSectionShowLessTextButtonLabel,
                  )
                ],
              ),
            ),
            IconButton(
                onPressed: () async {
                  return showDialog(
                      context: context,
                      builder: ((BuildContext context) {
                        return AlertDialog(
                          title: Text(AppLocalizations.of(context)!
                              .globalConfirmationDialogLabel),
                          content: Text(AppLocalizations.of(context)!
                              .settingsPageCommmentDeletionConfirmationDialogContent),
                          actions: [
                            PIPDialogTextButton(
                                label: AppLocalizations.of(context)!
                                    .globalNoButtonLabel,
                                onPressed: () {
                                  Navigator.pop(context);
                                }),
                            PIPDialogTextButton(
                              label: AppLocalizations.of(context)!
                                  .globalYesButtonLabel,
                              onPressed: () async {
                                try {
                                  if (connectivtiyProvider.connectivityResults
                                      .contains(ConnectivityResult.none)) {
                                    FirebaseFirestore.instance
                                        .collection(databaseProvider
                                            .customerSpecificCollectionComments)
                                        .doc(widget.commentID)
                                        .delete()
                                        .then((value) {
                                      Navigator.pop(context);
                                      successMessage(
                                          context,
                                          AppLocalizations.of(context)!
                                              .settingsPageOnSuccessCommentDeleted,
                                          closeIcon: false);
                                    });
                                    Navigator.pop(context);
                                    warningMessage(context,
                                        'You are offline. All changes will be made once you\'re online again.');
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection(databaseProvider
                                            .customerSpecificCollectionComments)
                                        .doc(widget.commentID)
                                        .delete()
                                        .then((value) {
                                      Navigator.pop(context);
                                      successMessage(
                                          context,
                                          AppLocalizations.of(context)!
                                              .settingsPageOnSuccessCommentDeleted,
                                          closeIcon: false);
                                    });
                                  }
                                } catch (e) {
                                  if (!context.mounted) {
                                    return;
                                  }
                                  errorMessage(
                                      context,
                                      AppLocalizations.of(context)!
                                          .globalUnexpectedErrorLabel,
                                      closeIcon: false);
                                }
                                FirebaseAnalytics.instance.logEvent(
                                    name: 'comment_deleted',
                                    parameters: {
                                      'user_id': FirebaseAuth
                                          .instance.currentUser!.uid,
                                      'comment_id': widget.commentID,
                                      'timestamp':
                                          Timestamp.now().toDate().toString()
                                    });
                              },
                            ),
                          ],
                        );
                      }));
                },
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                )),
          ],
        ),
      ),
    );
  }
}
