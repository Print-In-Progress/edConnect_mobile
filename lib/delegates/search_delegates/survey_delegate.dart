import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/delegates/search_delegates/abstract_search_delegate.dart';
import 'package:edconnect_mobile/pages/surveys_pages/sorting_solution_viewer.dart';
import 'package:edconnect_mobile/pages/surveys_pages/sorting_task_cards.dart';
import 'package:edconnect_mobile/pages/surveys_pages/sorting_task_viewer.dart';
import 'package:edconnect_mobile/pages/surveys_pages/survey_card.dart';
import 'package:edconnect_mobile/pages/surveys_pages/survey_viewer.dart';

class SurveySearchDelegate extends PIPSearchDelegate {
  final List<QueryDocumentSnapshot> surveys;
  final List<String> groups;
  SurveySearchDelegate({required this.surveys, required this.groups})
      : super(
          searchFieldLabel: 'Search Surveys...',
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
        );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  List<QueryDocumentSnapshot> filterSurveys(
      List<QueryDocumentSnapshot> surveys, String query, List<String> groups) {
    return surveys.where((survey) {
      final String result = survey['title'].toLowerCase();
      final input = query.toLowerCase();
      permissionGroupCheck(value) => groups.contains(value.toString());
      bool hasViewAccess = survey['groups'].any(permissionGroupCheck);

      bool solutionCheck() {
        if (!(survey.data() as Map).containsKey('solution')) {
          return false;
        }
        return survey['solution'].isNotEmpty;
      }

      return result.contains(input) &&
          ((hasViewAccess || survey['groups'].contains('everyone')) &&
              (!List<String>.from(survey['respondents'])
                      .contains(FirebaseAuth.instance.currentUser!.uid) ||
                  solutionCheck()));
    }).toList();
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded));

  @override
  Widget buildResults(BuildContext context) {
    List<QueryDocumentSnapshot> filteredSurveys =
        filterSurveys(surveys, query, groups);

    return CustomScrollView(
      slivers: [
        MediaQuery.of(context).size.width < 700 ||
                MediaQuery.of(context).orientation == Orientation.portrait
            ? SliverList.builder(
                itemCount: filteredSurveys.length,
                itemBuilder: (context, index) {
                  final survey = filteredSurveys[index];
                  final Timestamp timestamp = survey['creation_timestamp'];

                  if (!survey['respondents']
                          .contains(FirebaseAuth.instance.currentUser!.uid) &&
                      (survey.data() as Map).containsKey('description')) {
                    return SurveyCard(
                        timestamp: timestamp,
                        surveyTitle: survey['title'],
                        surveyDescription: survey['description'],
                        surveyID: survey.id);
                  } else if (survey['respondents']
                          .contains(FirebaseAuth.instance.currentUser!.uid) &&
                      (survey.data() as Map).containsKey('description')) {
                    return SurveyCardTaken(
                        timestamp: timestamp,
                        surveyTitle: survey['title'],
                        surveyDescription: survey['description']);
                  } else if (!survey['respondents']
                          .contains(FirebaseAuth.instance.currentUser!.uid) &&
                      !(survey.data() as Map).containsKey('description')) {
                    return SortingCard(
                        surveyTitle: survey['title'],
                        timestamp: timestamp,
                        factorSex: survey['factor_gender'],
                        maxPrefs: survey['num_of_preferences'],
                        optionalParam: survey['optional_parameter'],
                        secondOptionalParam:
                            survey['second_optional_parameter'],
                        students: survey['students'],
                        nonCalcQuestions: survey['non_calc_question'],
                        sortingSurveyID: survey.id);
                  } else if (survey['respondents']
                          .contains(FirebaseAuth.instance.currentUser!.uid) &&
                      survey['solution'].isEmpty) {
                    return SortingCardTaken(
                        surveyTitle: survey['title'], timestamp: timestamp);
                  } else {
                    return SortingCardSolutionAvailable(
                        surveyTitle: survey['title'],
                        timestamp: timestamp,
                        sortingSolution: survey['solution']);
                  }
                })
            : SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 400,
                  childAspectRatio:
                      MediaQuery.of(context).size.aspectRatio >= 1.5
                          ? 16 / 15.25
                          : 1 / 0.9,
                ),
                itemCount: filteredSurveys.length,
                itemBuilder: (context, index) {
                  final survey = filteredSurveys[index];
                  final Timestamp timestamp = survey['creation_timestamp'];

                  if (!survey['respondents']
                          .contains(FirebaseAuth.instance.currentUser!.uid) &&
                      (survey.data() as Map).containsKey('description')) {
                    return SurveyCard(
                        timestamp: timestamp,
                        surveyTitle: survey['title'],
                        surveyDescription: survey['description'],
                        surveyID: survey.id);
                  } else if (survey['respondents']
                          .contains(FirebaseAuth.instance.currentUser!.uid) &&
                      (survey.data() as Map).containsKey('description')) {
                    return SurveyCardTaken(
                        timestamp: timestamp,
                        surveyTitle: survey['title'],
                        surveyDescription: survey['description']);
                  } else if (!survey['respondents']
                          .contains(FirebaseAuth.instance.currentUser!.uid) &&
                      !(survey.data() as Map).containsKey('description')) {
                    return SortingCard(
                        surveyTitle: survey['title'],
                        timestamp: timestamp,
                        factorSex: survey['factor_gender'],
                        maxPrefs: survey['num_of_preferences'],
                        optionalParam: survey['optional_parameter'],
                        secondOptionalParam:
                            survey['second_optional_parameter'],
                        students: survey['students'],
                        nonCalcQuestions: survey['non_calc_question'],
                        sortingSurveyID: survey.id);
                  } else {
                    return SortingCardTaken(
                        surveyTitle: survey['title'], timestamp: timestamp);
                  }
                }),
        if (filteredSurveys.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No results found for "$query"',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<QueryDocumentSnapshot> suggestions =
        filterSurveys(surveys, query, groups);

    return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            title: Text(suggestion['title']),
            textColor: Colors.white,
            onTap: () {
              query = suggestion['title'];
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: const RouteSettings(name: 'Survey Viewer'),
                      builder: (context) {
                        if ((suggestion.data() as Map)
                            .containsKey('description')) {
                          return SurveyViewer(
                            surveyTitle: suggestion['title'],
                            surveyDescription: suggestion['description'],
                            surveyID: suggestion.id,
                          );
                        } else if ((suggestion.data() as Map)
                                .containsKey('solution') &&
                            suggestion['solution'].isNotEmpty) {
                          return SortingSolutionViewer(
                              surveyTitle: suggestion['title'],
                              surveySolution: suggestion['solution']);
                        } else {
                          return SortingViewer(
                            surveyTitle: suggestion['title'],
                            factorSex: suggestion['factor_gender'],
                            maxPrefs: suggestion['num_preferences'],
                            optionalParam: suggestion['optional_parameter'],
                            secondOptionalParam:
                                suggestion['second_optional_parameter'],
                            nonCalcQuestions: suggestion['non_calc_questions'],
                            students: suggestion['students'],
                            sortingSurveyID: suggestion.id,
                          );
                        }
                      }));
            },
          );
        });
  }
}
