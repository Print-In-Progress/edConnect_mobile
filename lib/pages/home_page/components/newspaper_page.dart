import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/components/article.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/delegates/search_delegates/abstract_search_delegate.dart';
import 'package:edconnect_mobile/delegates/search_delegates/article_search_delegate.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/pages/about_pages/about_page.dart';
import 'package:edconnect_mobile/pages/settings_pages/settings_main_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class Newspaper extends StatefulWidget {
  const Newspaper({super.key});

  @override
  State<Newspaper> createState() => _NewspaperState();
}

class _NewspaperState extends State<Newspaper> {
  int articleDisplayLimit = 10;
  int _filterValue = 0;
  String? _filterValueCategoryChip;
  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    FirebaseAnalytics.instance.logScreenView(screenName: 'Blog Screen');
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
                          ChoiceChip(
                              padding: const EdgeInsets.all(0),
                              label: Text(AppLocalizations.of(context)!
                                  .filtersTopChipLabel),
                              selected: _filterValue == 2,
                              onSelected: (bool selected) {
                                setState(() {
                                  _filterValue = 2;
                                });
                              }),
                          const SizedBox(
                            width: 5,
                          ),
                          FutureBuilder(
                              future: FirebaseFirestore.instance
                                  .collection(databaseProvider
                                      .customerSpecificCollectionArticles)
                                  .doc('categories')
                                  .get(),
                              builder: (BuildContext context, snapshot) {
                                if (snapshot.hasData) {
                                  List categories =
                                      snapshot.data!['categories'];
                                  return Wrap(
                                      spacing: 5,
                                      children: categories
                                          .map(
                                            (categoryChip) => ChoiceChip(
                                              showCheckmark: false,
                                              padding: const EdgeInsets.all(0),
                                              label: Text(categoryChip),
                                              selected:
                                                  _filterValueCategoryChip ==
                                                      categoryChip,
                                              onSelected: (bool value) {
                                                value
                                                    ? setState(() {
                                                        _filterValueCategoryChip =
                                                            categoryChip;
                                                      })
                                                    : setState(() {
                                                        _filterValueCategoryChip =
                                                            null;
                                                      });
                                              },
                                            ),
                                          )
                                          .toList());
                                }
                                return const SizedBox.shrink();
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
                onPressed: () async {
                  showPIPCustomSearch(
                      context: context, delegate: ArticleSearchDelegate());
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
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(databaseProvider.customerSpecificCollectionArticles)
              .limit(articleDisplayLimit)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List filteredData = snapshot.data!.docs
                  .where((article) => article['status'] == 'published')
                  .toList();
              if (_filterValue == 0) {
                filteredData
                    .sort((b, a) => a['timestamp'].compareTo(b['timestamp']));
              }
              if (_filterValue == 1) {
                filteredData
                    .sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
              }
              if (_filterValue == 2) {
                filteredData.sort(
                  (a, b) => b['likes'].length.compareTo(a['likes'].length),
                );
              }
              if (_filterValueCategoryChip != null) {
                filteredData = filteredData
                    .where((article) =>
                        article['status'] == 'published' &&
                        article['categories']
                            .contains(_filterValueCategoryChip))
                    .toList();
              }
              return CustomScrollView(
                slivers: [
                  MediaQuery.of(context).size.width < 700 ||
                          MediaQuery.of(context).orientation ==
                              Orientation.portrait
                      ? SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                          final article = filteredData[index];
                          final Timestamp timestamp = article['timestamp'];
                          if (article['status'] == 'published') {
                            return ArticleCard(
                              title: Text(
                                article['title'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              titleString: article['title'],
                              author: article['author'],
                              articleID: article.id,
                              content: article['content'],
                              coverImgLink: article['cover_image'],
                              dislikes:
                                  List<String>.from(article['dislikes'] ?? []),
                              likes: List<String>.from(article['likes'] ?? []),
                              datetime: DateFormat.yMd()
                                  .add_jm()
                                  .format(timestamp.toDate())
                                  .toString(),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }, childCount: filteredData.length))
                      : SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width ~/ 400,
                            childAspectRatio:
                                MediaQuery.of(context).size.aspectRatio >= 1.5
                                    ? 16 / 15.25
                                    : 1 / 0.9,
                          ),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final article = filteredData[index];
                            final Timestamp timestamp = article['timestamp'];
                            return ArticleCard(
                              title: Text(
                                article['title'].length > 65
                                    ? '${article['title'].substring(0, 65)}...'
                                    : article['title'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              titleString: article['title'],
                              author: article['author'],
                              articleID: article.id,
                              content: article['content'],
                              coverImgLink: article['cover_image'],
                              dislikes:
                                  List<String>.from(article['dislikes'] ?? []),
                              likes: List<String>.from(article['likes'] ?? []),
                              datetime: DateFormat.yMd()
                                  .add_jm()
                                  .format(timestamp.toDate())
                                  .toString(),
                            );
                          }),
                  snapshot.data!.docs.length >= 9 &&
                          !(articleDisplayLimit > snapshot.data!.docs.length)
                      ? SliverToBoxAdapter(
                          child: TextButton(
                              onPressed: () {
                                setState(() {
                                  articleDisplayLimit = articleDisplayLimit + 5;
                                });
                              },
                              child: Text(
                                AppLocalizations.of(context)!
                                    .blogPageMoreArticlesButtonLabel,
                                style: const TextStyle(color: Colors.white),
                              )),
                        )
                      : const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        )
                ],
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
