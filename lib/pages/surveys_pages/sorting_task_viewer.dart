import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/connectivity_provider.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';

class SortingViewer extends StatefulWidget {
  final String surveyTitle;
  final bool factorSex;
  final int maxPrefs;
  final String optionalParam;
  final String secondOptionalParam;
  final List nonCalcQuestions;
  final String sortingSurveyID;
  final Map students;
  const SortingViewer(
      {super.key,
      required this.surveyTitle,
      required this.factorSex,
      required this.maxPrefs,
      required this.optionalParam,
      required this.secondOptionalParam,
      required this.nonCalcQuestions,
      required this.students,
      required this.sortingSurveyID});

  @override
  State<SortingViewer> createState() => _SortingViewerState();
}

class _SortingViewerState extends State<SortingViewer> {
  final List<bool> optionalParams = [];
  final Map nonCalcQuestions = {};
  final List<TextEditingController> firstNameControllers = [];
  final List<TextEditingController> lastNameControllers = [];
  bool validateSex = true;
  bool validateNonCalcQuestions = true;
  String selectedSex = '';

  @override
  void initState() {
    if (widget.optionalParam.isNotEmpty) {
      optionalParams.add(false);
    }
    if (widget.secondOptionalParam.isNotEmpty) {
      optionalParams.add(false);
    }
    for (int i = 0; i < widget.maxPrefs; i++) {
      firstNameControllers.add(TextEditingController());
      lastNameControllers.add(TextEditingController());
    }
    for (var question in widget.nonCalcQuestions) {
      if (question['type'] == 'free_response') {
        nonCalcQuestions[question['question']] = TextEditingController();
      } else if (question['type'] == 'drop_down') {
        nonCalcQuestions[question['question']] = '';
      } else if (question['type'] == 'multiple_choice') {
        nonCalcQuestions[question['question']] = [];
      } else if (question['type'] == 'single_choice') {
        nonCalcQuestions[question['question']] = question['options'][0];
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final ConnectivityProvider connectivityProvider =
        Provider.of<ConnectivityProvider>(context);

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
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  widget.surveyTitle,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ),
                ),
                widget.factorSex
                    ? SliverToBoxAdapter(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: SizedBox(
                                  width: MediaQuery.of(context).size.width < 700
                                      ? MediaQuery.of(context).size.width
                                      : MediaQuery.of(context).size.width / 2,
                                  child: Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text('Select your biological sex:',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600)),
                                          SizedBox(height: 10),
                                          DropdownMenu(
                                              expandedInsets: EdgeInsets.all(8),
                                              requestFocusOnTap: false,
                                              onSelected: (value) {
                                                setState(() {
                                                  selectedSex = value!;
                                                });
                                              },
                                              errorText: validateSex
                                                  ? null
                                                  : 'Please select your biological sex',
                                              dropdownMenuEntries: [
                                                DropdownMenuEntry(
                                                    value: 'm', label: 'Male'),
                                                DropdownMenuEntry(
                                                    value: 'f', label: 'Female')
                                              ])
                                        ],
                                      ),
                                    ),
                                  )),
                            ),
                          ],
                        ),
                      )
                    : const SliverToBoxAdapter(child: SizedBox.shrink()),
                SliverToBoxAdapter(
                  child: Center(
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width < 700
                            ? MediaQuery.of(context).size.width
                            : MediaQuery.of(context).size.width / 2,
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'Please provide the first and last names of the people you would like to be in a group/class with. You can add up to ${widget.maxPrefs} people. If you don\'t have anyone in mind, you can leave the fields blank. Be cautious of spelling!',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  firstNameControllers[index],
                                              decoration: InputDecoration(
                                                hintText: 'First Name',
                                                filled: true,
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                            topLeft: Radius
                                                                .circular(10),
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    10))),
                                                contentPadding:
                                                    EdgeInsets.only(left: 10),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  lastNameControllers[index],
                                              decoration: InputDecoration(
                                                hintText: 'Last Name',
                                                filled: true,
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                            topRight: Radius
                                                                .circular(10),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    10))),
                                                contentPadding:
                                                    EdgeInsets.only(left: 10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  itemCount: widget.maxPrefs,
                                )
                              ],
                            ),
                          ),
                        )),
                  ),
                ),
                if (widget.optionalParam.isNotEmpty ||
                    widget.secondOptionalParam.isNotEmpty)
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
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                      'Additional information. Check all that apply:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  if (widget.optionalParam.isNotEmpty)
                                    CheckboxListTile(
                                        title: Text(widget.optionalParam),
                                        value: optionalParams[0],
                                        onChanged: (value) {
                                          setState(() {
                                            optionalParams[0] = value!;
                                          });
                                        }),
                                  if (widget.secondOptionalParam.isNotEmpty)
                                    CheckboxListTile(
                                        title: Text(widget.secondOptionalParam),
                                        value: optionalParams[1],
                                        onChanged: (value) {
                                          setState(() {
                                            optionalParams[1] = value!;
                                          });
                                        }),
                                ],
                              ),
                            ),
                          )),
                    ),
                  ),
                if (widget.nonCalcQuestions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width < 700
                            ? MediaQuery.of(context).size.width
                            : MediaQuery.of(context).size.width / 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                !validateNonCalcQuestions
                                    ? const Padding(
                                        padding: EdgeInsets.only(bottom: 10),
                                        child: Text(
                                          'Please answer all questions',
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 16),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.nonCalcQuestions[index]
                                              ['question'],
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 10),
                                        if (widget.nonCalcQuestions[index]
                                                ['type'] ==
                                            'free_response')
                                          TextFormField(
                                            controller: nonCalcQuestions[
                                                widget.nonCalcQuestions[index]
                                                    ['question']],
                                            decoration: InputDecoration(
                                              hintText: 'Answer',
                                              filled: true,
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      left: 10),
                                            ),
                                          ),
                                        if (widget.nonCalcQuestions[index]
                                                ['type'] ==
                                            'drop_down')
                                          DropdownMenu(
                                              expandedInsets:
                                                  const EdgeInsets.all(8),
                                              requestFocusOnTap: false,
                                              onSelected: (value) {
                                                setState(() {
                                                  nonCalcQuestions[
                                                      widget.nonCalcQuestions[
                                                              index]
                                                          ['question']] = value;
                                                });
                                              },
                                              dropdownMenuEntries: widget
                                                  .nonCalcQuestions[index]
                                                      ['options']
                                                  .map<
                                                      DropdownMenuEntry<
                                                          Object>>((entry) {
                                                return DropdownMenuEntry<
                                                        Object>(
                                                    value: entry, label: entry);
                                              }).toList()),
                                        if (widget.nonCalcQuestions[index]
                                                ['type'] ==
                                            'multiple_choice')
                                          ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemBuilder:
                                                  (context, indexOption) {
                                                return CheckboxListTile(
                                                  title: Text(
                                                      widget.nonCalcQuestions[
                                                              index]['options']
                                                          [indexOption]),
                                                  value: nonCalcQuestions.isNotEmpty &&
                                                          nonCalcQuestions[widget
                                                                      .nonCalcQuestions[index]
                                                                  [
                                                                  'question']] !=
                                                              null
                                                      ? nonCalcQuestions[widget
                                                                  .nonCalcQuestions[index]
                                                              ['question']]
                                                          .contains(
                                                              widget.nonCalcQuestions[index]
                                                                      ['options']
                                                                  [indexOption])
                                                      : false,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      if (nonCalcQuestions[
                                                              widget.nonCalcQuestions[
                                                                      index][
                                                                  'question']] ==
                                                          null) {
                                                        nonCalcQuestions[widget
                                                                    .nonCalcQuestions[
                                                                index]
                                                            ['question']] = [];
                                                      }
                                                      if (nonCalcQuestions[
                                                              widget.nonCalcQuestions[
                                                                      index][
                                                                  'question']]
                                                          .contains(
                                                              widget.nonCalcQuestions[
                                                                          index]
                                                                      [
                                                                      'options']
                                                                  [
                                                                  indexOption])) {
                                                        nonCalcQuestions[
                                                                widget.nonCalcQuestions[
                                                                        index][
                                                                    'question']]
                                                            .remove(widget.nonCalcQuestions[
                                                                        index]
                                                                    ['options']
                                                                [indexOption]);
                                                      } else {
                                                        nonCalcQuestions[
                                                                widget.nonCalcQuestions[
                                                                        index][
                                                                    'question']]
                                                            .add(widget.nonCalcQuestions[
                                                                        index]
                                                                    ['options']
                                                                [indexOption]);
                                                      }
                                                    });
                                                  },
                                                );
                                              },
                                              itemCount: widget
                                                  .nonCalcQuestions[index]
                                                      ['options']
                                                  .length),
                                        if (widget.nonCalcQuestions[index]
                                                ['type'] ==
                                            'single_choice')
                                          ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemBuilder:
                                                  (context, indexOption) {
                                                return ListTile(
                                                  onTap: () {
                                                    setState(() {
                                                      nonCalcQuestions[widget
                                                                  .nonCalcQuestions[
                                                              index]
                                                          ['question']] = widget
                                                                  .nonCalcQuestions[
                                                              index]['options']
                                                          [indexOption];
                                                    });
                                                  },
                                                  leading: Radio(
                                                      groupValue: nonCalcQuestions[
                                                          widget.nonCalcQuestions[
                                                                  index][
                                                              'question']],
                                                      value:
                                                          widget.nonCalcQuestions[
                                                                      index]
                                                                  ['options']
                                                              [indexOption],
                                                      onChanged: (value) {
                                                        setState(() {
                                                          nonCalcQuestions[widget
                                                                      .nonCalcQuestions[
                                                                  index][
                                                              'question']] = value;
                                                        });
                                                      }),
                                                  title: Text(
                                                      widget.nonCalcQuestions[
                                                              index]['options']
                                                          [indexOption]),
                                                );
                                              },
                                              itemCount: widget
                                                  .nonCalcQuestions[index]
                                                      ['options']
                                                  .length),
                                        const SizedBox(height: 10),
                                      ],
                                    );
                                  },
                                  itemCount: widget.nonCalcQuestions.length,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 10,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width < 700
                            ? MediaQuery.of(context).size.width / 2
                            : MediaQuery.of(context).size.width / 4,
                        child: FilledButton(
                          child: Text('Submit'),
                          onPressed: () async {
                            if (widget.factorSex && selectedSex.isEmpty) {
                              setState(() {
                                validateSex = false;
                              });
                              return;
                            } else if (selectedSex.isNotEmpty) {
                              setState(() {
                                validateSex = true;
                              });
                            }
                            List prefs = [];
                            int counter = 0;
                            String uid = FirebaseAuth.instance.currentUser!.uid;
                            String? userName;

                            final value = await FirebaseFirestore.instance
                                .collection(databaseProvider
                                    .customerSpecificCollectionUsers)
                                .doc(uid)
                                .get();
                            var data = value.data();
                            userName =
                                '${data?['first_name']} ${data?['last_name']}';

                            for (var controller in firstNameControllers) {
                              counter = counter + 1;
                              if (controller.text.isNotEmpty) {
                                String firstName = controller.text.trim();
                                String lastName =
                                    lastNameControllers[counter - 1]
                                        .text
                                        .trim();
                                String capitalizedFirstName =
                                    firstName.substring(0, 1).toUpperCase() +
                                        firstName.substring(1);
                                String capitalizedLastName =
                                    lastName.substring(0, 1).toUpperCase() +
                                        lastName.substring(1);
                                prefs.add(
                                    '$capitalizedFirstName $capitalizedLastName');
                              }
                            }
                            Map formattedNonCalcQuestionsAnswers = {};
                            for (var question in nonCalcQuestions.keys) {
                              if (nonCalcQuestions[question]
                                  is TextEditingController) {
                                if (nonCalcQuestions[question].text.isEmpty) {
                                  setState(() {
                                    validateNonCalcQuestions = false;
                                  });
                                  return;
                                }
                                formattedNonCalcQuestionsAnswers[question] =
                                    nonCalcQuestions[question].text;
                              } else {
                                if (nonCalcQuestions[question].isEmpty) {
                                  setState(() {
                                    validateNonCalcQuestions = false;
                                  });
                                  return;
                                }
                                formattedNonCalcQuestionsAnswers[question] =
                                    nonCalcQuestions[question];
                              }
                            }
                            if (connectivityProvider.connectivityResults
                                .contains(ConnectivityResult.none)) {
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              errorMessage(context,
                                  'You need an internet connection to submit the sorting task');
                              return;
                            }
                            await FirebaseFirestore.instance
                                .runTransaction((transaction) async {
                              Map<String, dynamic> existingStudents =
                                  Map.from(widget.students);
                              existingStudents[userName!] = {
                                'prefs': prefs,
                                'sex': selectedSex,
                                'non_calc': formattedNonCalcQuestionsAnswers,
                                if (widget.optionalParam.isNotEmpty)
                                  if (optionalParams[0])
                                    widget.optionalParam: 'yes'
                                  else
                                    widget.optionalParam: 'no',
                                if (widget.secondOptionalParam.isNotEmpty)
                                  if (optionalParams[1])
                                    widget.secondOptionalParam: 'yes'
                                  else
                                    widget.secondOptionalParam: 'no',
                              };
                              transaction.update(
                                  FirebaseFirestore.instance
                                      .collection(databaseProvider
                                          .customerSpecificCollectionSortingAlg)
                                      .doc(widget.sortingSurveyID),
                                  {
                                    'students': existingStudents,
                                    'respondents': FieldValue.arrayUnion([
                                      FirebaseAuth.instance.currentUser!.uid
                                    ])
                                  });
                            }).then((value) {
                              successMessage(context, 'Survey submitted!');
                              Navigator.pop(context);
                            });
                          },
                        )),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 10,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
