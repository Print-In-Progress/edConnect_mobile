import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ArticleContent extends StatefulWidget {
  final String articleTitle;
  final String articleContent;

  const ArticleContent(
      {super.key, required this.articleTitle, required this.articleContent});

  @override
  State<ArticleContent> createState() => _ArticleContentState();
}

class _ArticleContentState extends State<ArticleContent> {
  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.articleTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor:
            Color(int.parse(currentColorSchemeProvider.primaryColor)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: InteractiveViewer(
            child: SelectionArea(
                child: HtmlWidget(
              widget.articleContent,
              enableCaching: true,
              onTapImage: (imageMetadata) async {
                await showDialog(
                    context: context,
                    builder: (_) {
                      return Dialog(
                        insetPadding: EdgeInsets.zero,
                        child: InteractiveViewer(
                            child:
                                Image.network(imageMetadata.sources.first.url)),
                      );
                    });
              },
              onTapUrl: (url) async {
                final Uri uri = Uri.parse(
                    '${url.contains('https://') ? '' : 'https://'}$url');
                try {
                  await launchUrl(uri);
                } catch (e) {
                  if (!context.mounted) return false;
                  errorMessage(context,
                      '${AppLocalizations.of(context)!.blogPageWasNotAbleToLaunchURLErrorLabel} $uri');
                }
                return true;
              },
              onErrorBuilder: (context, element, error) => Text(
                  '${AppLocalizations.of(context)!.blogPageWasNotAbleToLoadArticleErrorLabel} $error'),
              onLoadingBuilder: (context, element, loadingProgress) =>
                  const Center(child: CircularProgressIndicator()),
            )),
          ),
        ),
      ),
    );
  }
}
