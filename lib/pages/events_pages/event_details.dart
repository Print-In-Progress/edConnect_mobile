import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EventDetailsPage extends StatefulWidget {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isFullDayEvent;

  const EventDetailsPage(
      {super.key,
      required this.title,
      required this.description,
      required this.startDate,
      required this.endDate,
      this.startTime,
      this.endTime,
      this.isFullDayEvent = false});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
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
                elevation: 1, // No shadow
                title: Text(
                  widget.title,
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
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width > 600
                          ? MediaQuery.of(context).size.width * 0.5
                          : MediaQuery.of(context).size.width,
                      child: GlassMorphismCard(
                        start: 0.1,
                        end: 0.1,
                        color: themeProvider.darkTheme
                            ? Colors.grey[850]!
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.description,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.date_range_outlined,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Start Date: ${DateFormat.yMEd().format(widget.startDate.toLocal())}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.date_range_outlined,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'End Date: ${DateFormat.yMEd().format(widget.endDate.toLocal())}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!widget.isFullDayEvent)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time_outlined,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Start Time: ${DateFormat.jm().format(widget.startTime!)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time_outlined,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'End Time: ${DateFormat.jm().format(widget.endTime!)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                if (widget.isFullDayEvent)
                                  Text(
                                    AppLocalizations.of(context)!
                                        .eventsPagesFullDayEvent,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                              ]),
                        ),
                      ),
                    ),
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
