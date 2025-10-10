import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/models/language.dart';

class OpenCloseStatusCard extends StatelessWidget {
  final bool isOpen;
  final Color? color;
  final String? statusText;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  const OpenCloseStatusCard(
      {super.key,
      required this.isOpen,
      this.statusText,
      this.padding,
      this.textStyle,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding / 5,
          ),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ??
            (isOpen == true
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color?.withValues(alpha: 0.3) ??
              (isOpen == true
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3)),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color ?? (isOpen == true ? Colors.green : Colors.red),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            statusText ??
                (isOpen == true
                    ? Provider.of<ZLanguage>(context).open
                    : Provider.of<ZLanguage>(context).closed),
            // "Open" : "Closed")
            style: textStyle ??
                TextStyle(
                  fontSize: 12,
                  color: color?.withValues(alpha: 0.7) ??
                      (isOpen == true ? Colors.green[700] : Colors.red[700]),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
