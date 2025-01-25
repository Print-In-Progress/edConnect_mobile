import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final String likes;
  final void Function()? onTap;

  const LikeButton(
      {super.key,
      required this.isLiked,
      required this.onTap,
      required this.likes});

  @override
  Widget build(BuildContext context) {
    final themeChangeProvider = Provider.of<ThemeProvider>(context);
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);

    return TextButton(
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero, minimumSize: Size.zero),
        onPressed: onTap,
        child: Row(
          children: [
            Row(
              children: [
                Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  color: isLiked
                      ? Color(
                          int.parse(currentColorSchemeProvider.secondaryColor))
                      : themeChangeProvider.darkTheme
                          ? const Color.fromRGBO(202, 196, 208, 1)
                          : Colors.grey[700],
                ),
                const SizedBox(width: 2),
                Text(likes,
                    style: TextStyle(
                        color: themeChangeProvider.darkTheme
                            ? const Color.fromRGBO(202, 196, 208, 1)
                            : Colors.grey[700]))
              ],
            )
          ],
        ));
  }
}
