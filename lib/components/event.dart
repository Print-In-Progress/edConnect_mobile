import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/glassmorphism.dart';
import 'package:provider/provider.dart';

class EventCard extends StatefulWidget {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isFullDayEvent;

  const EventCard(
      {super.key,
      required this.title,
      required this.description,
      required this.startDate,
      required this.endDate,
      this.isFullDayEvent = false});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    return GlassMorphismCard(
      start: 0.1,
      end: 0.1,
      color: themeChangeProvider.darkTheme ? Colors.grey[850]! : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            maxLines: 1,
                            style: TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        Text(
                            DateFormat.yMd()
                                .add_jm()
                                .format(widget.startDate)
                                .toString(),
                            style:
                                TextStyle(fontSize: 15, color: Colors.white54))
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  childrenPadding: EdgeInsets.zero,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white,
                  collapsedTextColor: Colors.white,
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Description',
                    style: TextStyle(fontSize: 14),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.description,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
