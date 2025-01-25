import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/connectivity_provider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SurveyViewer extends StatefulWidget {
  final String surveyTitle;
  final String surveyDescription;
  final String surveyID;
  const SurveyViewer(
      {super.key,
      required this.surveyTitle,
      required this.surveyDescription,
      required this.surveyID});

  @override
  State<SurveyViewer> createState() => _SurveyViewerState();
}

class _SurveyViewerState extends State<SurveyViewer> {
  final Map<String, double> sliderValues = {};
  final Map<String, Map<String, bool>> selectedOptions = {};
  final Map<String, String> singleSelectedOptions = {};
  final Map<String, String> dropdownValues = {};
  final Map<String, TextEditingController> freeRespones = {};
  bool functionCalled = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(databaseProvider.customerSpecificCollectionSurveys)
            .doc(widget.surveyID)
            .collection('questions')
            .orderBy('pos', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasData) {
            if (!functionCalled) {
              for (var question in snapshot.data!.docs) {
                if (question['type'] == 'slider') {
                  sliderValues
                      .addAll({question.id: double.parse(question['end']) / 2});
                }
                if (question['type'] == 'multi_select') {
                  selectedOptions.addAll({question.id: {}});
                  for (var option in question['options']) {
                    selectedOptions[question.id]!.addAll({option: false});
                  }
                }
                if (question['type'] == 'single_select') {
                  singleSelectedOptions.addAll({question.id: ''});
                }
                if (question['type'] == 'dropdown') {
                  dropdownValues.addAll({question.id: ''});
                }
                if (question['type'] == 'free_response') {
                  freeRespones.addAll({question.id: TextEditingController()});
                }
              }
              functionCalled = true;
            }
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
              child: SafeArea(
                child: NestedScrollView(
                    floatHeaderSlivers: true,
                    headerSliverBuilder: (context, bool innerBoxIsScrolled) {
                      return [
                        SliverAppBar(
                          foregroundColor: Colors.white,
                          toolbarHeight: kToolbarHeight - 10,
                          automaticallyImplyLeading: true,
                          floating: true,
                          snap: true,
                          title: Text(
                            widget.surveyTitle,
                            style: const TextStyle(color: Colors.white),
                          ),
                          forceMaterialTransparency: true,
                        )
                      ];
                    },
                    body: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Center(
                            child: SizedBox(
                                width: MediaQuery.of(context).size.width < 700
                                    ? MediaQuery.of(context).size.width
                                    : MediaQuery.of(context).size.width / 2,
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.surveyTitle,
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          widget.surveyDescription,
                                          style: TextStyle(
                                              color: themeProvider.darkTheme
                                                  ? const Color.fromRGBO(
                                                      202, 196, 208, 1)
                                                  : Colors.grey[700],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400),
                                        )
                                      ],
                                    ),
                                  ),
                                )),
                          ),
                        ),
                        SliverList.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              QueryDocumentSnapshot<Map<String, dynamic>>
                                  survey = snapshot.data!.docs[index];
                              if (survey['type'] == 'multi_select') {
                                return Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width <
                                            700
                                        ? MediaQuery.of(context).size.width
                                        : MediaQuery.of(context).size.width / 2,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20.0,
                                            right: 20.0,
                                            bottom: 20.0,
                                            top: 5),
                                        child: Column(
                                          children: [
                                            Text(
                                              survey['title'],
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              survey['description'],
                                              style: TextStyle(
                                                  color: themeProvider.darkTheme
                                                      ? const Color.fromRGBO(
                                                          202, 196, 208, 1)
                                                      : Colors.grey[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            ListView.builder(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount:
                                                    survey['options'].length,
                                                itemBuilder:
                                                    (context, indexOption) {
                                                  return ListTile(
                                                      leading: Checkbox(
                                                          value: selectedOptions[
                                                                  survey.id]![
                                                              survey['options'][
                                                                  indexOption]],
                                                          onChanged: (value) {
                                                            setState(() {
                                                              selectedOptions[survey
                                                                  .id]![survey[
                                                                      'options']
                                                                  [
                                                                  indexOption]] = value!;
                                                            });
                                                          }),
                                                      title: Text(
                                                          survey['options']
                                                              [indexOption]));
                                                }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else if (survey['type'] == 'single_select') {
                                return Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width <
                                            700
                                        ? MediaQuery.of(context).size.width
                                        : MediaQuery.of(context).size.width / 2,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20.0,
                                            right: 20.0,
                                            bottom: 20.0,
                                            top: 5),
                                        child: Column(
                                          children: [
                                            Text(
                                              survey['title'],
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              survey['description'],
                                              style: TextStyle(
                                                  color: themeProvider.darkTheme
                                                      ? const Color.fromRGBO(
                                                          202, 196, 208, 1)
                                                      : Colors.grey[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            ListView.builder(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount:
                                                    survey['options'].length,
                                                itemBuilder:
                                                    (context, indexOption) {
                                                  return ListTile(
                                                      leading: Radio(
                                                          groupValue:
                                                              singleSelectedOptions[
                                                                  survey.id],
                                                          value:
                                                              survey['options']
                                                                  [indexOption],
                                                          onChanged: (value) {
                                                            setState(() {
                                                              singleSelectedOptions[
                                                                      survey
                                                                          .id] =
                                                                  value;
                                                            });
                                                          }),
                                                      title: Text(
                                                          survey['options']
                                                              [indexOption]));
                                                }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else if (survey['type'] == 'slider') {
                                return Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width <
                                            700
                                        ? MediaQuery.of(context).size.width
                                        : MediaQuery.of(context).size.width / 2,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20.0,
                                            right: 20.0,
                                            bottom: 20.0,
                                            top: 5),
                                        child: Column(
                                          children: [
                                            Text(
                                              survey['title'],
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              survey['description'],
                                              style: TextStyle(
                                                  color: themeProvider.darkTheme
                                                      ? const Color.fromRGBO(
                                                          202, 196, 208, 1)
                                                      : Colors.grey[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Slider(
                                                    value: sliderValues[
                                                        survey.id]!,
                                                    label:
                                                        sliderValues[survey.id]!
                                                            .round()
                                                            .toString(),
                                                    min: double.parse(
                                                        survey['start']),
                                                    max: double.parse(
                                                        survey['end']),
                                                    divisions: int.parse(
                                                        survey['end']),
                                                    onChanged: (double value) {
                                                      setState(() {
                                                        sliderValues[
                                                            survey.id] = value;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                    survey['start_label'] == ""
                                                        ? survey['start']
                                                        : survey['start_label'],
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                const Spacer(),
                                                Text(
                                                  survey['end_label'] == ""
                                                      ? survey['end']
                                                      : survey['end_label'],
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else if (survey['type'] == 'dropdown') {
                                return Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width <
                                            700
                                        ? MediaQuery.of(context).size.width
                                        : MediaQuery.of(context).size.width / 2,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20.0,
                                            right: 20.0,
                                            bottom: 20.0,
                                            top: 5),
                                        child: Column(
                                          children: [
                                            Text(
                                              survey['title'],
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              survey['description'],
                                              style: TextStyle(
                                                  color: themeProvider.darkTheme
                                                      ? const Color.fromRGBO(
                                                          202, 196, 208, 1)
                                                      : Colors.grey[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            DropdownMenu<dynamic>(
                                              expandedInsets:
                                                  const EdgeInsets.all(8),
                                              initialSelection:
                                                  survey['options'].first,
                                              onSelected: (value) {
                                                setState(() {
                                                  dropdownValues[survey.id] =
                                                      value!;
                                                });
                                              },
                                              dropdownMenuEntries:
                                                  survey['options']
                                                      .map<DropdownMenuEntry>(
                                                          (value) {
                                                return DropdownMenuEntry(
                                                    value: value, label: value);
                                              }).toList(),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else if (survey['type'] == 'free_response') {
                                return Center(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width <
                                            700
                                        ? MediaQuery.of(context).size.width
                                        : MediaQuery.of(context).size.width / 2,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20.0,
                                            right: 20.0,
                                            bottom: 20.0,
                                            top: 5),
                                        child: Column(
                                          children: [
                                            Text(
                                              survey['title'],
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              survey['description'],
                                              style: TextStyle(
                                                  color: themeProvider.darkTheme
                                                      ? const Color.fromRGBO(
                                                          202, 196, 208, 1)
                                                      : Colors.grey[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            TextField(
                                              controller:
                                                  freeRespones[survey.id],
                                              textInputAction:
                                                  TextInputAction.newline,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              maxLines: null,
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                              maxLength: int.parse(
                                                  survey['word_limit']),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }),
                        SliverToBoxAdapter(
                          child: Center(
                            child: SizedBox(
                                width: MediaQuery.of(context).size.width < 700
                                    ? MediaQuery.of(context).size.width / 2
                                    : MediaQuery.of(context).size.width / 4,
                                child: FilledButton(
                                    onPressed: () async {
                                      Map<String, Map<String, dynamic>>
                                          submission = {};

                                      for (var answer in sliderValues.keys) {
                                        submission.addAll({
                                          answer: {
                                            'type': 'slider',
                                            'response': sliderValues[answer]
                                          }
                                        });
                                      }
                                      for (var answer in selectedOptions.keys) {
                                        submission.addAll({
                                          answer: {
                                            'type': 'multi_select',
                                            'response': selectedOptions[answer]
                                          }
                                        });
                                      }
                                      for (var answer
                                          in singleSelectedOptions.keys) {
                                        submission.addAll({
                                          answer: {
                                            'type': 'single_select',
                                            'response':
                                                singleSelectedOptions[answer]
                                          }
                                        });
                                      }
                                      for (var answer in dropdownValues.keys) {
                                        submission.addAll({
                                          answer: {
                                            'type': 'dropdown',
                                            'response': dropdownValues[answer]
                                          }
                                        });
                                      }
                                      for (var answer in freeRespones.keys) {
                                        submission.addAll({
                                          answer: {
                                            'type': 'free_response',
                                            'response':
                                                freeRespones[answer]!.text
                                          }
                                        });
                                      }
                                      if (connectivityProvider
                                          .connectivityResults
                                          .contains(ConnectivityResult.none)) {
                                        WriteBatch batch =
                                            FirebaseFirestore.instance.batch();

                                        // Add the survey response
                                        DocumentReference responseRef =
                                            FirebaseFirestore.instance
                                                .collection(databaseProvider
                                                    .customerSpecificCollectionSurveys)
                                                .doc(widget.surveyID)
                                                .collection('responses')
                                                .doc();
                                        batch.set(responseRef, submission);

                                        // Update the respondents list
                                        DocumentReference surveyRef =
                                            FirebaseFirestore.instance
                                                .collection(databaseProvider
                                                    .customerSpecificCollectionSurveys)
                                                .doc(widget.surveyID);
                                        batch.update(surveyRef, {
                                          'respondents': FieldValue.arrayUnion([
                                            FirebaseAuth
                                                .instance.currentUser!.uid
                                          ])
                                        });
                                        batch.commit();
                                        warningMessage(context,
                                            'Response saved. It\'ll be submitted when you have an internet connection');
                                        Navigator.of(context).pop();
                                        return;
                                      }
                                      try {
                                        WriteBatch batch =
                                            FirebaseFirestore.instance.batch();

                                        // Add the survey response
                                        DocumentReference responseRef =
                                            FirebaseFirestore.instance
                                                .collection(databaseProvider
                                                    .customerSpecificCollectionSurveys)
                                                .doc(widget.surveyID)
                                                .collection('responses')
                                                .doc();
                                        batch.set(responseRef, submission);

                                        // Update the respondents list
                                        DocumentReference surveyRef =
                                            FirebaseFirestore.instance
                                                .collection(databaseProvider
                                                    .customerSpecificCollectionSurveys)
                                                .doc(widget.surveyID);
                                        batch.update(surveyRef, {
                                          'respondents': FieldValue.arrayUnion([
                                            FirebaseAuth
                                                .instance.currentUser!.uid
                                          ])
                                        });

                                        await batch.commit();

                                        if (!context.mounted) return;
                                        successMessage(context,
                                            'Response successfully submitted');
                                      } on Exception catch (e) {
                                        if (!context.mounted) return;
                                        errorMessage(context,
                                            'Error submitting response: $e');
                                      }
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(AppLocalizations.of(context)!
                                        .globalSubmitLabel))),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 10,
                          ),
                        )
                      ],
                    )),
              ),
            ));
          } else if (snapshot.hasError) {
            return SliverToBoxAdapter(
                child: Center(child: Text('Error: ${snapshot.error}')));
          }
          return const Scaffold(
              body: Center(
            child: CircularProgressIndicator(),
          ));
        });
  }
}
