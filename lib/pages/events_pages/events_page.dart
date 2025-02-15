import 'package:calendar_view/calendar_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/components/event.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/pages/about_pages/about_page.dart';
import 'package:edconnect_mobile/pages/events_pages/create_event_page.dart';
import 'package:edconnect_mobile/pages/events_pages/event_details.dart';
import 'package:edconnect_mobile/pages/settings_pages/settings_main_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/widgets/glassmorphism.dart';
import 'package:provider/provider.dart';

enum ViewType { month, week, overview }

class Events extends StatefulWidget {
  final AppUser currentUser;
  const Events({super.key, required this.currentUser});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  ViewType _selectedView = ViewType.month;
  Stream? stream;
  final EventController _calendarController = EventController();
  List<CalendarEventData> eventsList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(screenName: 'Events Screen');
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CreateEventPage(
                    currentUserGroups: widget.currentUser.groups,
                    isAllowedToCreatePublicEvents:
                        widget.currentUser.permissions.contains('admin'))));
          },
          child: const Icon(Icons.add)),
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
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
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
                                    .globalLabelMonth),
                                selected: _selectedView == ViewType.month,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedView = ViewType.month;
                                  });
                                },
                              ),
                              const SizedBox(width: 5),
                              ChoiceChip(
                                padding: const EdgeInsets.all(0),
                                label: Text(AppLocalizations.of(context)!
                                    .globalLabelWeek),
                                selected: _selectedView == ViewType.week,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedView = ViewType.week;
                                  });
                                },
                              ),
                              const SizedBox(width: 5),
                              ChoiceChip(
                                padding: const EdgeInsets.all(0),
                                label: Text(AppLocalizations.of(context)!
                                    .globalLabelOverview),
                                selected: _selectedView == ViewType.overview,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedView = ViewType.overview;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                actions: [
                  PopupMenuButton(
                      onSelected: (result) {
                        if (result == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                settings: const RouteSettings(
                                    name: 'accountOverview'),
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
          body: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(databaseProvider.customerSpecificCollectionEvents)
                  .orderBy('start_date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<CalendarEventData> events =
                      snapshot.data!.docs.map((event) {
                    DateTime startDate =
                        (event['start_date'] as Timestamp).toDate().toLocal();
                    DateTime endDate =
                        (event['end_date'] as Timestamp).toDate().toLocal();

                    DateTime startTime = DateTime(
                      startDate.year,
                      startDate.month,
                      startDate.day,
                      startDate.hour,
                      startDate.minute,
                    );

                    DateTime endTime = DateTime(
                      endDate.year,
                      endDate.month,
                      endDate.day,
                      endDate.hour,
                      endDate.minute,
                    );

                    if (event['all_day']) {
                      return CalendarEventData(
                        date: startDate,
                        endDate: endDate,
                        title: event['title'],
                        description: event['description'],
                      );
                    }

                    return CalendarEventData(
                      date: startDate,
                      endDate: endDate,
                      startTime: startTime,
                      endTime: endTime,
                      title: event['title'],
                      description: event['description'],
                    );
                  }).toList();
                  _calendarController.addAll(events);
                  eventsList = events;
                  return _buildView();
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }),
        ),
      ),
    );
  }

  Widget _buildView() {
    switch (_selectedView) {
      case ViewType.month:
        return _buildMonthView();
      case ViewType.week:
        return _buildWeekView();
      case ViewType.overview:
        return _buildOverviewView();
      default:
        return Container();
    }
  }

  Widget _buildMonthView() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = Localizations.localeOf(context).toString();
    final dateSymbols =
        dateTimeSymbolMap()[locale] ?? dateTimeSymbolMap()['en_US']!;
    final firstDayOfWeek = dateSymbols.FIRSTDAYOFWEEK;

    // Map the first day of the week to WeekDays enum
    final startDay = firstDayOfWeek == 0 ? WeekDays.monday : WeekDays.sunday;

    return GlassMorphismCard(
      start: 0.1,
      end: 0.1,
      color: themeProvider.darkTheme
          ? Color.fromRGBO(48, 48, 48, 1)
          : Color.fromRGBO(255, 255, 255, 1),
      margin: EdgeInsets.zero,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
      child: MonthView(
        useAvailableVerticalSpace: true,
        headerStringBuilder: (date, {secondaryDate}) {
          return DateFormat.yMMMM(Localizations.localeOf(context).toString())
              .format(date.toLocal());
        },
        showWeekTileBorder: false,
        weekDayBuilder: (day) {
          DateTime date =
              DateTime.utc(2024, 1, 1 + day); // January 1, 2024 is a Monday
          String weekdayAbbreviation = DateFormat('EEE', locale)
              .format(date); // Get short day abbreviation
          return Center(
            child: Text(
              weekdayAbbreviation,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        },
        startDay: startDay,
        borderColor: Colors.white60,
        borderSize: 0.5,
        cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
          return Container(
            decoration: BoxDecoration(
              color: isInMonth
                  ? Colors.transparent
                  : Color(0xFF212121).withOpacity(0.2),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: isToday
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade300,
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 5,
                            ),
                          )
                        : const BoxDecoration(),
                    child: Text(
                      date.day.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ...events.map((event) {
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) {
                            if (event.isFullDayEvent) {
                              return EventDetailsPage(
                                title: event.title,
                                description: event.description!,
                                startDate: event.date,
                                endDate: event.endDate,
                                isFullDayEvent: event.isFullDayEvent,
                              );
                            } else {
                              return EventDetailsPage(
                                title: event.title,
                                description: event.description!,
                                startDate: event.date,
                                endDate: event.endDate,
                                startTime: event.startTime!,
                                endTime: event.endTime!,
                                isFullDayEvent: event.isFullDayEvent,
                              );
                            }
                          }),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          border: Border.all(
                            color: Colors.white,
                            width: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              style: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
        headerStyle: const HeaderStyle(
          leftIcon: Icon(
            Icons.arrow_back,
            color: Colors.white60,
          ),
          rightIcon: Icon(
            Icons.arrow_forward,
            color: Color.fromRGBO(255, 255, 255, 0.6),
          ),
          headerTextStyle: TextStyle(
            color: Colors.white60,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
        ),
        controller: _calendarController,
        onPageChange: (date, pageIndex) => print("$date, $pageIndex"),
        onCellTap: (events, date) {
          // Handle cell tap if needed
          print(events);
        },
        onEventTap: (event, date) {
          // Handle event tap if needed
          print(event);
        },
      ),
    );
  }

  Widget _buildWeekView() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final locale = Localizations.localeOf(context).toString();
    final dateSymbols =
        dateTimeSymbolMap()[locale] ?? dateTimeSymbolMap()['en_US']!;
    final firstDayOfWeek = dateSymbols.FIRSTDAYOFWEEK;

    // Map the first day of the week to WeekDays enum
    final startDay = firstDayOfWeek == 0 ? WeekDays.monday : WeekDays.sunday;

    // Implement your week view here
    return GlassMorphismCard(
      start: 0.1,
      end: 0.1,
      margin: EdgeInsets.zero,
      color: themeProvider.darkTheme ? Colors.grey[850]! : Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
      child: WeekView(
        controller: _calendarController,
        onEventTap: (event, date) {
          // Handle event tap if needed
          print(event);
        },
        headerStringBuilder: (date, {secondaryDate}) {
          return ' ${DateFormat.MMMd(Localizations.localeOf(context).toString()).format(date.toLocal())} - ${DateFormat.MMMd(Localizations.localeOf(context).toString()).format(secondaryDate!.toLocal())}';
        },
        fullDayEventBuilder: (events, date) {
          return Column(
            children: events.map((event) {
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(
                        title: event.title,
                        description: event.description!,
                        startDate: event.date,
                        endDate: event.endDate,
                        isFullDayEvent: event.isFullDayEvent,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    border: Border.all(
                      color: Colors.white,
                      width: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
        showVerticalLines: false,
        keepScrollOffset: true,
        weekDetectorBuilder: (
            {required DateTime date,
            required double height,
            required double heightPerMinute,
            required MinuteSlotSize minuteSlotSize,
            required double width}) {
          return Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.white60,
                  width: 0.5,
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                // Handle tap interaction
              },
            ),
          );
        },
        liveTimeIndicatorSettings: const LiveTimeIndicatorSettings(
          color: Colors.redAccent,
        ),
        startDay: startDay,
        showLiveTimeLineInAllDays: false,
        eventTileBuilder: (date, events, boundary, startDuration, endDuration) {
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(
                    title: events.first.title,
                    description: events.first.description!,
                    startDate: events.first.date,
                    endDate: events.first.endDate,
                    startTime: events.first.startTime!,
                    endTime: events.first.endTime!,
                    isFullDayEvent: events.first.isFullDayEvent,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                border: Border.all(
                  color: Colors.white,
                  width: 0.3,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  Text(
                    events.first.title,
                    maxLines: 2,
                    style: const TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        startHour: 5,
        backgroundColor: Colors.transparent,
        weekNumberBuilder: (firstDayOfWeek) {
          int dayOfYear = int.parse(DateFormat("D").format(firstDayOfWeek));
          return Center(
            child: Text(
              (((dayOfYear - firstDayOfWeek.weekday + 10) / 7).floor())
                  .toString(),
              style: const TextStyle(color: Colors.white54),
            ),
          );
        },
        timeLineBuilder: (date) {
          return Text(
            DateFormat.Hm(Localizations.localeOf(context).toString())
                .format(date.toLocal()),
            style: const TextStyle(
              color: Colors.white54,
            ),
          );
        },
        weekDayBuilder: (date) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.E(Localizations.localeOf(context).toString())
                    .format(date.toLocal()),
                style: const TextStyle(
                  color: Colors.white54,
                ),
              ),
              Text(
                date.day.toString(),
                style: const TextStyle(
                  color: Colors.white54,
                ),
              ),
            ],
          );
        },
        headerStyle: const HeaderStyle(
          leftIcon: Icon(
            Icons.arrow_back,
            color: Colors.white60,
          ),
          rightIcon: Icon(
            Icons.arrow_forward,
            color: Colors.white60,
          ),
          headerTextStyle: TextStyle(
            color: Colors.white60,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewView() {
    return CustomScrollView(
      slivers: [
        SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EventCard(
                title: eventsList[index].title,
                description: eventsList[index].description!,
                startDate: eventsList[index].date,
                endDate: eventsList[index].endDate,
                isFullDayEvent: eventsList[index].isFullDayEvent,
              ),
            ],
          );
        }, childCount: eventsList.length))
      ],
    );
  }
}
