import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';

class SortingSolutionViewer extends StatefulWidget {
  final String surveyTitle;
  final Map surveySolution;

  const SortingSolutionViewer(
      {super.key, required this.surveyTitle, required this.surveySolution});

  @override
  State<SortingSolutionViewer> createState() => _SortingSolutionViewerState();
}

class _SortingSolutionViewerState extends State<SortingSolutionViewer> {
  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
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
                    '${widget.surveyTitle} Results',
                    style: const TextStyle(color: Colors.white),
                  ),
                  forceMaterialTransparency: true,
                )
              ];
            },
            body: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, indexClass) {
                      var students = widget.surveySolution[
                          widget.surveySolution.keys.elementAt(indexClass)];
                      students.sort((a, b) => a
                          .split(' ')
                          .last
                          .compareTo(b.split(' ').last) as int);
                      return Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width < 700
                              ? MediaQuery.of(context).size.width
                              : MediaQuery.of(context).size.width / 2,
                          child: Card(
                              child: Column(
                            children: [
                              Text(
                                widget.surveySolution.keys
                                    .elementAt(indexClass),
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (context, indexStudent) {
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        students[indexStudent],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                itemCount: students.length,
                              )
                            ],
                          )),
                        ),
                      );
                    },
                    childCount: widget.surveySolution.keys.length,
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
