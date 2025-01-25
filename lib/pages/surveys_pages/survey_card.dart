import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/surveys_pages/survey_viewer.dart';
import 'package:edconnect_mobile/widgets/glassmorphism.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SurveyCard extends StatefulWidget {
  final String surveyTitle;
  final String surveyDescription;
  final String surveyID;
  final Timestamp timestamp;

  const SurveyCard(
      {super.key,
      required this.timestamp,
      required this.surveyTitle,
      required this.surveyDescription,
      required this.surveyID});

  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GlassMorphismCard(
      start: 0.1,
      end: 0.1,
      color: themeProvider.darkTheme ? Colors.grey[850]! : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                settings: const RouteSettings(name: 'Survey Viewer'),
                builder: (context) => SurveyViewer(
                      surveyTitle: widget.surveyTitle,
                      surveyDescription: widget.surveyDescription,
                      surveyID: widget.surveyID,
                    )),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(widget.surveyTitle,
                            style: TextStyle(
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        Text(
                          DateFormat.yMd()
                              .add_jm()
                              .format(widget.timestamp.toDate())
                              .toString(),
                          style: TextStyle(
                              color: Color.fromARGB(135, 255, 255, 255),
                              fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(widget.surveyDescription,
                  style: TextStyle(color: Colors.white70)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(width: 8),
                TextButton(
                  child: Text(AppLocalizations.of(context)!
                      .surveysPagesTakeSurveyButtonLabel),
                  style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: const RouteSettings(name: 'Survey Viewer'),
                          builder: (context) => SurveyViewer(
                                surveyTitle: widget.surveyTitle,
                                surveyDescription: widget.surveyDescription,
                                surveyID: widget.surveyID,
                              )),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SurveyCardTaken extends StatefulWidget {
  final String surveyTitle;
  final Timestamp timestamp;
  final String surveyDescription;

  const SurveyCardTaken(
      {super.key,
      required this.surveyTitle,
      required this.surveyDescription,
      required this.timestamp});

  @override
  State<SurveyCardTaken> createState() => _SurveyCardTakenState();
}

class _SurveyCardTakenState extends State<SurveyCardTaken> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GlassMorphismCard(
      start: 0.1,
      end: 0.1,
      color: themeProvider.darkTheme ? Colors.grey[850]! : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            trailing: ClipOval(
              child: Container(
                padding: EdgeInsets.zero,
                color: Colors.white,
                child: Icon(
                  size: 32,
                  Icons.check_circle,
                  color: Colors.green[800],
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.surveyTitle,
                          maxLines: 2,
                          style: TextStyle(
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      Text(
                          DateFormat.yMd()
                              .add_jm()
                              .format(widget.timestamp.toDate())
                              .toString(),
                          style:
                              TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  widget.surveyDescription,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
