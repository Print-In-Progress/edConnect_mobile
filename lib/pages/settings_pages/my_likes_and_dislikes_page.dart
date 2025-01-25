import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/components/article.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';

class MyLikesAndDislikesPage extends StatefulWidget {
  const MyLikesAndDislikesPage({super.key});

  @override
  State<MyLikesAndDislikesPage> createState() => _MyLikesAndDislikesPageState();
}

class _MyLikesAndDislikesPageState extends State<MyLikesAndDislikesPage> {
  int articleDisplayLimit = 5;

  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    return Container(
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
      child: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  toolbarHeight: kToolbarHeight,
                  automaticallyImplyLeading: true,
                  floating: true,
                  snap: true,
                  forceMaterialTransparency: true,
                  bottom: TabBar(tabs: [
                    Tab(
                      text: AppLocalizations.of(context)!
                          .settingsPageMyLikesTabbarTitle,
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!
                          .settingsPageMyDislikesTabbarTitle,
                    )
                  ]),
                  actionsIconTheme: const IconThemeData(color: Colors.white),
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    AppLocalizations.of(context)!
                        .settingsPageMyLikesAndDislikesButtonLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(
                            databaseProvider.customerSpecificCollectionArticles)
                        .where('likes', arrayContains: currentUser.uid)
                        .limit(articleDisplayLimit)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final List filteredData = snapshot.data!.docs
                            .where(
                                (article) => article['status'] == 'published')
                            .toList();
                        return CustomScrollView(
                          slivers: [
                            MediaQuery.of(context).size.width < 700 ||
                                    MediaQuery.of(context).orientation ==
                                        Orientation.portrait
                                ? SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                    final article = snapshot.data!.docs[index];
                                    final Timestamp timestamp =
                                        article['timestamp'];
                                    if (article['status'] == 'published') {
                                      return ArticleCard(
                                        title: Text(
                                          article['title'],
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        titleString: article['title'],
                                        author: article['author'],
                                        articleID: article.id,
                                        content: article['content'],
                                        coverImgLink: article['cover_image'],
                                        dislikes: List<String>.from(
                                            article['dislikes'] ?? []),
                                        likes: List<String>.from(
                                            article['likes'] ?? []),
                                        datetime: DateFormat.yMd()
                                            .add_jm()
                                            .format(timestamp.toDate())
                                            .toString(),
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  }, childCount: snapshot.data!.docs.length))
                                : SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          MediaQuery.of(context).size.width ~/
                                              400,
                                      childAspectRatio: MediaQuery.of(context)
                                                  .size
                                                  .aspectRatio >=
                                              1.5
                                          ? 16 / 15.25
                                          : 1 / 0.9,
                                    ),
                                    itemCount: filteredData.length,
                                    itemBuilder: (context, index) {
                                      final article = filteredData[index];
                                      final Timestamp timestamp =
                                          article['timestamp'];
                                      return ArticleCard(
                                        title: Text(
                                          article['title'].length > 65
                                              ? '${article['title'].substring(0, 65)}...'
                                              : article['title'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        titleString: article['title'],
                                        author: article['author'],
                                        articleID: article.id,
                                        content: article['content'],
                                        coverImgLink: article['cover_image'],
                                        dislikes: List<String>.from(
                                            article['dislikes'] ?? []),
                                        likes: List<String>.from(
                                            article['likes'] ?? []),
                                        datetime: DateFormat.yMd()
                                            .add_jm()
                                            .format(timestamp.toDate())
                                            .toString(),
                                      );
                                    }),
                            snapshot.data!.docs.length >= 5
                                ? SliverToBoxAdapter(
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            articleDisplayLimit =
                                                articleDisplayLimit + 5;
                                          });
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .blogPageMoreArticlesButtonLabel,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )),
                                  )
                                : const SliverToBoxAdapter(
                                    child: SizedBox.shrink())
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
                StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(
                            databaseProvider.customerSpecificCollectionArticles)
                        .where('dislikes', arrayContains: currentUser.uid)
                        .limit(articleDisplayLimit)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final List filteredData = snapshot.data!.docs
                            .where(
                                (article) => article['status'] == 'published')
                            .toList();
                        return CustomScrollView(
                          slivers: [
                            MediaQuery.of(context).size.width < 700 ||
                                    MediaQuery.of(context).orientation ==
                                        Orientation.portrait
                                ? SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                    final article = snapshot.data!.docs[index];
                                    final Timestamp timestamp =
                                        article['timestamp'];
                                    if (article['status'] == 'published') {
                                      return ArticleCard(
                                        title: Text(
                                          article['title'],
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        titleString: article['title'],
                                        author: article['author'],
                                        articleID: article.id,
                                        content: article['content'],
                                        coverImgLink: article['cover_image'],
                                        dislikes: List<String>.from(
                                            article['dislikes'] ?? []),
                                        likes: List<String>.from(
                                            article['likes'] ?? []),
                                        datetime: DateFormat.yMd()
                                            .add_jm()
                                            .format(timestamp.toDate())
                                            .toString(),
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  }, childCount: snapshot.data!.docs.length))
                                : SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          MediaQuery.of(context).size.width ~/
                                              400,
                                      childAspectRatio: MediaQuery.of(context)
                                                  .size
                                                  .aspectRatio >=
                                              1.5
                                          ? 16 / 15.25
                                          : 1 / 0.9,
                                    ),
                                    itemCount: filteredData.length,
                                    itemBuilder: (context, index) {
                                      final article = filteredData[index];
                                      final Timestamp timestamp =
                                          article['timestamp'];
                                      return ArticleCard(
                                        title: Text(
                                          article['title'].length > 65
                                              ? '${article['title'].substring(0, 65)}...'
                                              : article['title'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        titleString: article['title'],
                                        author: article['author'],
                                        articleID: article.id,
                                        content: article['content'],
                                        coverImgLink: article['cover_image'],
                                        dislikes: List<String>.from(
                                            article['dislikes'] ?? []),
                                        likes: List<String>.from(
                                            article['likes'] ?? []),
                                        datetime: DateFormat.yMd()
                                            .add_jm()
                                            .format(timestamp.toDate())
                                            .toString(),
                                      );
                                    }),
                            snapshot.data!.docs.length >= 5
                                ? SliverToBoxAdapter(
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            articleDisplayLimit =
                                                articleDisplayLimit + 5;
                                          });
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .blogPageMoreArticlesButtonLabel,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )),
                                  )
                                : const SliverToBoxAdapter(
                                    child: SizedBox.shrink(),
                                  )
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error ${snapshot.error}'));
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
