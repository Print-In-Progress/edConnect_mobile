import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PIPCancelButton extends StatelessWidget {
  const PIPCancelButton({super.key});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
      },
      label: Text(
        AppLocalizations.of(context)!.globalCancelButtonLabel,
        style: const TextStyle(
          color: Color(0xFFFF0000),
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: const Icon(
        Icons.block,
        color: Color(0xFFFF0000),
      ),
    );
  }
}

class PIPDialogTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PIPDialogTextButton(
      {super.key, required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          onPressed();
        },
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
  }
}

class PIPResponsiveRaisedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final dynamic width;
  final IconData? icon;
  final dynamic height;
  final FontWeight? fontWeight;
  final double fontSize;
  const PIPResponsiveRaisedButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.height,
      this.fontWeight = FontWeight.normal,
      this.fontSize = 18,
      this.icon,
      required this.width});
  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      if (height != null) {
        return ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size(width, height)),
            onPressed: () {
              onPressed();
            },
            child: Text(
              label,
              style: TextStyle(fontWeight: fontWeight, fontSize: fontSize),
            ));
      } else {
        return SizedBox(
          width: width,
          child: ElevatedButton(
              onPressed: () {
                onPressed();
              },
              child: Text(
                label,
                style: TextStyle(fontWeight: fontWeight, fontSize: fontSize),
              )),
        );
      }
    } else {
      if (height != null) {
        return ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: Size(width, height)),
            onPressed: () {
              onPressed();
            },
            icon: Icon(icon!),
            label: Text(
              label,
              style: TextStyle(fontWeight: fontWeight, fontSize: fontSize),
            ));
      } else {
        return SizedBox(
          width: width,
          child: ElevatedButton.icon(
              onPressed: () {
                onPressed();
              },
              icon: Icon(icon!),
              label: Text(
                label,
                style: TextStyle(fontWeight: fontWeight, fontSize: fontSize),
              )),
        );
      }
    }
  }
}

class PIPResponsiveTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final dynamic width;
  final dynamic height;
  final FontWeight? fontWeight;
  final double? fontSize;
  final IconData? icon;
  final Color? color;
  const PIPResponsiveTextButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.height,
      this.color,
      this.fontWeight,
      this.fontSize,
      this.icon,
      this.width});
  @override
  Widget build(BuildContext context) {
    return icon == null
        ? TextButton(
            style: TextButton.styleFrom(minimumSize: Size(width, height)),
            onPressed: () {
              onPressed();
            },
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: fontWeight, fontSize: fontSize, color: color),
            ))
        : TextButton.icon(
            onPressed: () {
              onPressed();
            },
            icon: Icon(icon),
            label: Text(
              label,
              style: TextStyle(
                  fontWeight: fontWeight, fontSize: fontSize, color: color),
            ));
  }
}
