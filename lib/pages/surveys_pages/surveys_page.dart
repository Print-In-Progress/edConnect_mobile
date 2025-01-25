import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/delegates/search_delegates/abstract_search_delegate.dart';
import 'package:edconnect_mobile/delegates/search_delegates/survey_delegate.dart';
import 'package:edconnect_mobile/models/providers/modulesprovider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/about_pages/about_page.dart';
import 'package:edconnect_mobile/pages/settings_pages/settings_main_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/pages/surveys_pages/sorting_task_cards.dart';
import 'package:edconnect_mobile/pages/surveys_pages/survey_card.dart';
import 'package:provider/provider.dart';

class Surveys extends StatefulWidget {
  final List<String> groups;
  const Surveys({super.key, required this.groups});

  @override
  State<Surveys> createState() => _SurveysState();
}

class _SurveysState extends State<Surveys> {
  int _filterValue = 0;
  List<QueryDocumentSnapshot> sortingSurveys = [];
  List<QueryDocumentSnapshot> otherSurveys = [];

  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final userModulesProvider = Provider.of<UserModulesProvider>(context);
    return NestedScrollView(
      floatHeaderSlivers: true,
      headerSliverBuilder: (context, bool innerBoxIsScrolled) {
        return [
          SliverAppBar(
            toolbarHeight: kToolbarHeight - 10,
            automaticallyImplyLeading: true,
            floating: true,
            snap: true,
            forceMaterialTransparency: true,
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight - 7),
                child: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Container(
                    alignment: Alignment.topLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChoiceChip(
                            padding: const EdgeInsets.all(0),
                            label: Text(AppLocalizations.of(context)!
                                .filtersNewestChipLabel),
                            selected: _filterValue == 0,
                            onSelected: (bool selected) {
                              setState(() {
                                _filterValue = 0;
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          ChoiceChip(
                              padding: const EdgeInsets.all(0),
                              label: Text(AppLocalizations.of(context)!
                                  .filtersOldestChipLabel),
                              selected: _filterValue == 1,
                              onSelected: (bool selected) {
                                setState(() {
                                  _filterValue = 1;
                                });
                              }),
                          const SizedBox(
                            width: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  List<QueryDocumentSnapshot> combinedSurveys = [
                    ...sortingSurveys,
                    ...otherSurveys
                  ];
                  showPIPCustomSearch(
                      context: context,
                      delegate: SurveySearchDelegate(
                          groups: (widget.groups as List<String>),
                          surveys: combinedSurveys));
                },
              ),
              PopupMenuButton(
                  onSelected: (result) {
                    if (result == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            settings:
                                const RouteSettings(name: 'accountOverview'),
                            builder: (context) => const AccountOverview()),
                      );
                    } else if (result == 2) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings: const RouteSettings(name: 'about'),
                              builder: (context) => const About()));
                    }
                  },
                  itemBuilder: ((context) => [
                        PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  color: Color(int.parse(
                                      currentColorSchemeProvider
                                          .secondaryColor)),
                                ),
                                Text(AppLocalizations.of(context)!
                                    .globalSettingsLabel)
                              ],
                            )),
                        PopupMenuItem(
                            value: 2,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(int.parse(
                                      currentColorSchemeProvider
                                          .secondaryColor)),
                                ),
                                Text(AppLocalizations.of(context)!
                                    .globalAboutUsLabel)
                              ],
                            )),
                      ])),
            ],
            actionsIconTheme: const IconThemeData(color: Colors.white),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              currentColorSchemeProvider.customerName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ];
      },
      body: CustomScrollView(
        slivers: [
          userModulesProvider.userModules.contains('sorting')
              ? StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection(
                          databaseProvider.customerSpecificCollectionSortingAlg)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<QueryDocumentSnapshot> filteredDataSortingAlg =
                          snapshot.data!.docs
                              .where((sortingSurvey) =>
                                  sortingSurvey['status'] == 'published')
                              .toList();
                      if (_filterValue == 0) {
                        filteredDataSortingAlg.sort((b, a) =>
                            a['creation_timestamp']
                                .compareTo(b['creation_timestamp']));
                      }
                      if (_filterValue == 1) {
                        filteredDataSortingAlg.sort((a, b) =>
                            a['creation_timestamp']
                                .compareTo(b['creation_timestamp']));
                      }
                      sortingSurveys = filteredDataSortingAlg;
                      return SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                        final sortingSurvey = filteredDataSortingAlg[index];
                        final Timestamp timestamp =
                            sortingSurvey['creation_timestamp'];
                        permissionGroupCheck(value) =>
                            widget.groups.contains(value.toString());
                        bool hasViewAccess =
                            sortingSurvey['groups'].any(permissionGroupCheck);

                        if (!sortingSurvey['respondents'].contains(
                                FirebaseAuth.instance.currentUser!.uid) &&
                            (hasViewAccess ||
                                sortingSurvey['groups'].contains('everyone'))) {
                          return SortingCard(
                              timestamp: timestamp,
                              surveyTitle: sortingSurvey['title'],
                              factorSex: sortingSurvey['factor_gender'],
                              maxPrefs: sortingSurvey['num_preferences'],
                              students: sortingSurvey['students'],
                              nonCalcQuestions:
                                  sortingSurvey['non_calc_questions'],
                              optionalParam:
                                  sortingSurvey['optional_parameter'],
                              secondOptionalParam:
                                  sortingSurvey['second_optional_parameter'],
                              sortingSurveyID: sortingSurvey.id);
                        } else {
                          if ((hasViewAccess ||
                                  sortingSurvey['groups']
                                      .contains('everyone')) &&
                              sortingSurvey['respondents'].contains(
                                  FirebaseAuth.instance.currentUser!.uid) &&
                              sortingSurvey['solution'].isEmpty) {
                            return SortingCardTaken(
                                timestamp: timestamp,
                                surveyTitle: sortingSurvey['title']);
                          } else if (hasViewAccess ||
                              sortingSurvey['groups'].contains('everyone') &&
                                  sortingSurvey['respondents'].contains(
                                      FirebaseAuth.instance.currentUser!.uid) &&
                                  sortingSurvey['solution'].isNotEmpty) {
                            return SortingCardSolutionAvailable(
                              surveyTitle: sortingSurvey['title'],
                              sortingSolution: sortingSurvey['solution'],
                              timestamp: sortingSurvey['creation_timestamp'],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                      }, childCount: filteredDataSortingAlg.length));
                    } else if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                )
              : const SliverToBoxAdapter(child: SizedBox.shrink()),
          userModulesProvider.userModules.contains('surveys')
              ? StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection(
                          databaseProvider.customerSpecificCollectionSurveys)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<QueryDocumentSnapshot> filteredData = snapshot
                          .data!.docs
                          .where((survey) => survey['status'] == 'published')
                          .toList();
                      if (_filterValue == 0) {
                        filteredData.sort((b, a) => a['creation_timestamp']
                            .compareTo(b['creation_timestamp']));
                      }
                      if (_filterValue == 1) {
                        filteredData.sort((a, b) => a['creation_timestamp']
                            .compareTo(b['creation_timestamp']));
                      }
                      otherSurveys = filteredData;
                      return SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                        final survey = filteredData[index];
                        final Timestamp timestamp =
                            survey['creation_timestamp'];
                        permissionGroupCheck(value) =>
                            widget.groups.contains(value.toString());
                        bool hasViewAccess =
                            survey['groups'].any(permissionGroupCheck);

                        if (!survey['respondents'].contains(
                                FirebaseAuth.instance.currentUser!.uid) &&
                            (hasViewAccess ||
                                survey['groups'].contains('everyone'))) {
                          return SurveyCard(
                              timestamp: timestamp,
                              surveyTitle: survey['title'],
                              surveyDescription: survey['description'],
                              surveyID: survey.id);
                        } else {
                          if (hasViewAccess ||
                              survey['groups'].contains('everyone')) {
                            return SurveyCardTaken(
                                timestamp: timestamp,
                                surveyTitle: survey['title'],
                                surveyDescription: survey['description']);
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                      }, childCount: filteredData.length));
                    } else if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  })
              : const SliverToBoxAdapter(child: SizedBox.shrink())
        ],
      ),
    );
  }
}
