import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:provider/provider.dart';

class DislikeButton extends StatelessWidget {
  final bool isDisliked;
  final void Function()? onTap;
  final String dislikes;
  const DislikeButton(
      {super.key,
      required this.isDisliked,
      required this.onTap,
      required this.dislikes});

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
                  isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                  color: isDisliked
                      ? Color(
                          int.parse(currentColorSchemeProvider.secondaryColor))
                      : themeChangeProvider.darkTheme
                          ? const Color.fromRGBO(202, 196, 208, 1)
                          : const Color.fromARGB(255, 97, 97, 97),
                ),
                const SizedBox(width: 2),
                Text(
                  dislikes,
                  style: TextStyle(
                      color: themeChangeProvider.darkTheme
                          ? const Color.fromRGBO(202, 196, 208, 1)
                          : Colors.grey[700]),
                )
              ],
            )
          ],
        ));
  }
}
