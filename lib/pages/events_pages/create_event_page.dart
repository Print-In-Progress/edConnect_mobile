import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/services/data_services.dart';
import 'package:edconnect_mobile/widgets/dropdown_multi_select.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateEventPage extends StatefulWidget {
  final List<String> currentUserGroups;
  final bool isAllowedToCreatePublicEvents;
  const CreateEventPage(
      {super.key,
      required this.currentUserGroups,
      required this.isAllowedToCreatePublicEvents});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<String> selectedGroups = [];

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _validateTitle = false;
  bool _validateDescription = false;
  bool _dateValidator = false;
  bool _timeValidator = false;
  bool _allDay = false;

  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    Map<String, String> groups = {
      for (var group in widget.currentUserGroups) group: group,
    };
    if (widget.isAllowedToCreatePublicEvents) {
      groups['public'] = AppLocalizations.of(context)!.eventsPagesPublicEvent;
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(int.parse(currentColorSchemeProvider.primaryColor)),
                  Color(int.parse(currentColorSchemeProvider.secondaryColor)),
                ],
              ),
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: themeProvider.darkTheme
                    ? Colors.grey[850]!.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1), // Transparency
                elevation: 1.0,
                title: Text(
                  AppLocalizations.of(context)!.eventsPagesCreateEvent,
                ),
                foregroundColor: Colors.white,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(
                            int.parse(currentColorSchemeProvider.primaryColor)),
                        Color(int.parse(
                            currentColorSchemeProvider.secondaryColor)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_dateValidator)
                        Text(
                            AppLocalizations.of(context)!
                                .eventsPagesSelectDateErrorLabel,
                            style: const TextStyle(color: Colors.red)),
                      if (_timeValidator)
                        Text(
                            AppLocalizations.of(context)!
                                .eventsPagesTimeValidator,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 5),
                      Material(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        elevation: 1.0,
                        child: TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            errorText: _validateTitle
                                ? AppLocalizations.of(context)!
                                    .globalEmptyFormFieldErrorLabel
                                : null,
                            labelStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: themeProvider.darkTheme
                                ? Colors.grey.shade800.withOpacity(0.1)
                                : Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // Event Title
                            labelText: AppLocalizations.of(context)!.eventTitle,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Wrap(
                        children: [
                          ElevatedButton(
                            style: ButtonStyle(
                              side: MaterialStateProperty.all(BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5)),
                              backgroundColor: themeProvider.darkTheme
                                  ? MaterialStateProperty.all(
                                      Colors.grey.shade800.withOpacity(0.1))
                                  : MaterialStateProperty.all(
                                      Colors.white.withOpacity(0.1)),
                              foregroundColor:
                                  MaterialStateProperty.all(Colors.white),
                            ),
                            onPressed: () async {
                              DateTime? datePicked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _selectedStartDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 36500)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              setState(() {
                                if (datePicked != null) {
                                  _selectedStartDate = datePicked;
                                }
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedStartDate == null
                                      ? AppLocalizations.of(context)!
                                          .eventsPagesStartDateLabel
                                      : DateFormat.yMd()
                                          .format(_selectedStartDate!)
                                          .toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          ElevatedButton(
                            style: ButtonStyle(
                              side: MaterialStateProperty.all(BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5)),
                              backgroundColor: themeProvider.darkTheme
                                  ? MaterialStateProperty.all(
                                      Colors.grey.shade800.withOpacity(0.1))
                                  : MaterialStateProperty.all(
                                      Colors.white.withOpacity(0.1)),
                              foregroundColor:
                                  MaterialStateProperty.all(Colors.white),
                            ),
                            onPressed: () async {
                              DateTime? datePicked = await showDatePicker(
                                context: context,
                                initialDate: _selectedEndDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 36500)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              setState(() {
                                if (datePicked != null) {
                                  _selectedEndDate = datePicked;
                                }
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedEndDate == null
                                      ? AppLocalizations.of(context)!
                                          .eventsPagesEndDateLabel
                                      : DateFormat.yMd()
                                          .format(_selectedEndDate!)
                                          .toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!_allDay)
                        Wrap(
                          children: [
                            ElevatedButton(
                              style: ButtonStyle(
                                side: MaterialStateProperty.all(BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5)),
                                backgroundColor: themeProvider.darkTheme
                                    ? MaterialStateProperty.all(
                                        Colors.grey.shade800.withOpacity(0.1))
                                    : MaterialStateProperty.all(
                                        Colors.white.withOpacity(0.1)),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white),
                              ),
                              onPressed: () async {
                                TimeOfDay? timePicked = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime ?? TimeOfDay.now(),
                                );
                                setState(() {
                                  if (timePicked != null) {
                                    _startTime = timePicked;
                                  }
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _startTime == null
                                        ? AppLocalizations.of(context)!
                                            .eventsPagesStartTime
                                        : _startTime!.format(context),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            ElevatedButton(
                              style: ButtonStyle(
                                side: MaterialStateProperty.all(BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5)),
                                backgroundColor: themeProvider.darkTheme
                                    ? MaterialStateProperty.all(
                                        Colors.grey.shade800.withOpacity(0.1))
                                    : MaterialStateProperty.all(
                                        Colors.white.withOpacity(0.1)),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white),
                              ),
                              onPressed: () async {
                                TimeOfDay? timePicked = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime ?? TimeOfDay.now(),
                                );
                                setState(() {
                                  if (timePicked != null) {
                                    _endTime = timePicked;
                                  }
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _endTime == null
                                        ? AppLocalizations.of(context)!
                                            .eventsPagesEndTime
                                        : _endTime!.format(context),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 5),
                      CheckboxListTile(
                          side: const BorderSide(color: Colors.white),
                          value: _allDay,
                          onChanged: (bool? value) {
                            setState(() {
                              _allDay = value!;
                            });
                          },
                          title: Text(
                            AppLocalizations.of(context)!
                                .eventsPagesFullDayEvent,
                            style: const TextStyle(color: Colors.white),
                          )),
                      Material(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        elevation: 1.0,
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          controller: _descriptionController,
                          maxLines: null,
                          decoration: InputDecoration(
                            errorText: _validateDescription
                                ? AppLocalizations.of(context)!
                                    .globalEmptyFormFieldErrorLabel
                                : null,
                            filled: true,
                            fillColor: themeProvider.darkTheme
                                ? Colors.grey.shade800.withOpacity(0.1)
                                : Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                            labelText: AppLocalizations.of(context)!
                                .eventsPagesEventDescriptionLabel, //Event Desc
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Material(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        elevation: 1.0,
                        child: MultiSelectDropdown(
                          items: groups,
                          selectedItems: selectedGroups,
                          color: Colors.white,
                          onSelectionChanged: (List<String> selectedList) {
                            setState(() {
                              selectedGroups = selectedList;
                            });
                          },
                          searchHint: AppLocalizations.of(context)!
                              .globalSearchGroups, // Search
                          dropdownLabel: AppLocalizations.of(context)!
                              .eventsPagesSelectGroupsLabel, // Select
                        ),
                      ),
                      const SizedBox(height: 5),
                      FilledButton(
                          onPressed: () async {
                            if (_titleController.text.isEmpty) {
                              setState(() {
                                _validateTitle = true;
                              });
                            }
                            if (_descriptionController.text.isEmpty) {
                              setState(() {
                                _validateDescription = true;
                              });
                            }
                            if (_selectedStartDate == null ||
                                ((_startTime == null || _endTime == null) &&
                                    !_allDay)) {
                              _dateValidator = true;
                              return;
                            }

                            try {
                              final startDateTime = DateTime(
                                _selectedStartDate!.year,
                                _selectedStartDate!.month,
                                _selectedStartDate!.day,
                                _allDay ? 0 : _startTime!.hour,
                                _allDay ? 0 : _startTime!.minute,
                              );

                              final endDateTime = DateTime(
                                _selectedEndDate!.year,
                                _selectedEndDate!.month,
                                _selectedEndDate!.day,
                                _allDay ? 23 : _endTime!.hour,
                                _allDay ? 59 : _endTime!.minute,
                              );

                              if (startDateTime.isAfter(endDateTime)) {
                                setState(() {
                                  _timeValidator = true;
                                });
                                return;
                              }

                              if (!_validateTitle && !_validateDescription) {
                                try {
                                  await DataService().addEvent(
                                      databaseProvider
                                          .customerSpecificCollectionEvents,
                                      _titleController.text,
                                      _descriptionController.text,
                                      selectedGroups,
                                      Timestamp.fromDate(startDateTime),
                                      Timestamp.fromDate(endDateTime),
                                      _allDay);
                                } on Exception catch (e) {
                                  if (mounted) {
                                    errorMessage(context,
                                        '${AppLocalizations.of(context)!.globalUnexpectedErrorLabel}: ${e.toString()}');
                                  }
                                }
                                if (mounted) {
                                  Navigator.pop(context);
                                  successMessage(
                                    context,
                                    AppLocalizations.of(context)!
                                        .eventsPagesEventCreatedSnackbarMessage,
                                  );
                                }
                              }
                            } on Exception catch (e) {
                              if (mounted) {
                                errorMessage(context, e.toString());
                              }
                            }
                          },
                          child: Text(AppLocalizations.of(context)!
                              .eventsPagesCreateEvent)),
                    ]),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
