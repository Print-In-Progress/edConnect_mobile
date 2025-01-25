import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/components/article.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/delegates/search_delegates/abstract_search_delegate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';

class ArticleSearchDelegate extends PIPSearchDelegate {
  ArticleSearchDelegate()
      : super(
          searchFieldLabel: 'Search Articles...',
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
        );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded));

  @override
  Widget buildResults(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);

    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    int articleDisplayLimit = 5;

    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(databaseProvider.customerSpecificCollectionArticles)
            .limit(articleDisplayLimit)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List filteredArticlesList = snapshot.data!.docs
                .where((article) => article['status'] == 'published')
                .where((article) => article['title']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
                .toList();
            return CustomScrollView(
              slivers: [
                MediaQuery.of(context).size.width < 700 ||
                        MediaQuery.of(context).orientation ==
                            Orientation.portrait
                    ? SliverList.builder(
                        itemCount: filteredArticlesList.length,
                        itemBuilder: (context, index) {
                          final article = filteredArticlesList[index];
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
                        })
                    : SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width ~/ 400,
                          childAspectRatio:
                              MediaQuery.of(context).size.aspectRatio >= 1.5
                                  ? 16 / 15.25
                                  : 1 / 0.9,
                        ),
                        itemCount: filteredArticlesList.length,
                        itemBuilder: (context, index) {
                          final article = filteredArticlesList[index];
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
                filteredArticlesList.length >= 5 &&
                        !(articleDisplayLimit > snapshot.data!.docs.length)
                    ? SliverToBoxAdapter(
                        child: TextButton(
                            onPressed: () {
                              articleDisplayLimit = articleDisplayLimit + 5;
                            },
                            child: Text(
                              AppLocalizations.of(context)!
                                  .blogPageMoreArticlesButtonLabel,
                              style: TextStyle(
                                  color: themeChangeProvider.darkTheme
                                      ? const Color.fromRGBO(202, 196, 208, 1)
                                      : Colors.grey[700]),
                            )),
                      )
                    : const SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      ),
                if (filteredArticlesList.isEmpty)
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
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Text(
        'Searching for "$query"',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
