import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/surveys_pages/sorting_solution_viewer.dart';
import 'package:edconnect_mobile/pages/surveys_pages/sorting_task_viewer.dart';
import 'package:edconnect_mobile/widgets/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SortingCard extends StatefulWidget {
  final String surveyTitle;
  final Timestamp timestamp;
  final bool factorSex;
  final int maxPrefs;
  final String optionalParam;
  final String secondOptionalParam;
  final String sortingSurveyID;
  final List nonCalcQuestions;
  final Map students;

  const SortingCard(
      {super.key,
      required this.surveyTitle,
      required this.timestamp,
      required this.factorSex,
      required this.maxPrefs,
      required this.optionalParam,
      required this.secondOptionalParam,
      required this.students,
      required this.nonCalcQuestions,
      required this.sortingSurveyID});

  @override
  State<SortingCard> createState() => _SortingCardState();
}

class _SortingCardState extends State<SortingCard> {
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
                settings: const RouteSettings(name: 'Sorting Task Viewer'),
                builder: (context) => SortingViewer(
                      surveyTitle: widget.surveyTitle,
                      factorSex: widget.factorSex,
                      maxPrefs: widget.maxPrefs,
                      optionalParam: widget.optionalParam,
                      secondOptionalParam: widget.secondOptionalParam,
                      students: widget.students,
                      nonCalcQuestions: widget.nonCalcQuestions,
                      sortingSurveyID: widget.sortingSurveyID,
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
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        )
                      ],
                    ),
                  ),
                ],
              ),
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
                          settings:
                              const RouteSettings(name: 'Sortzing Task Viewer'),
                          builder: (context) => SortingViewer(
                                surveyTitle: widget.surveyTitle,
                                factorSex: widget.factorSex,
                                maxPrefs: widget.maxPrefs,
                                optionalParam: widget.optionalParam,
                                secondOptionalParam: widget.secondOptionalParam,
                                students: widget.students,
                                nonCalcQuestions: widget.nonCalcQuestions,
                                sortingSurveyID: widget.sortingSurveyID,
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

class SortingCardTaken extends StatefulWidget {
  final String surveyTitle;
  final Timestamp timestamp;
  const SortingCardTaken(
      {super.key, required this.surveyTitle, required this.timestamp});

  @override
  State<SortingCardTaken> createState() => _SortingCardTakenState();
}

class _SortingCardTakenState extends State<SortingCardTaken> {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 10),
                      Text(widget.surveyTitle,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      Text(
                        DateFormat.yMd()
                            .add_jm()
                            .format(widget.timestamp.toDate())
                            .toString(),
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SortingCardSolutionAvailable extends StatefulWidget {
  final String surveyTitle;
  final Timestamp timestamp;
  final Map sortingSolution;

  const SortingCardSolutionAvailable(
      {super.key,
      required this.surveyTitle,
      required this.timestamp,
      required this.sortingSolution});

  @override
  State<SortingCardSolutionAvailable> createState() =>
      _SortingCardSolutionAvailableState();
}

class _SortingCardSolutionAvailableState
    extends State<SortingCardSolutionAvailable> {
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    settings:
                        const RouteSettings(name: 'Sorting Solution Viewer'),
                    builder: (context) => SortingSolutionViewer(
                          surveyTitle: widget.surveyTitle,
                          surveySolution: widget.sortingSolution,
                        )),
              );
            },
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.checklist_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.surveyTitle,
                          style: TextStyle(
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      Text(
                        'Lösung Verfügbar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.greenAccent,
                        ),
                      ),
                      Text(
                        DateFormat.yMd()
                            .add_jm()
                            .format(widget.timestamp.toDate())
                            .toString(),
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
