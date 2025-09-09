import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class OrderStatusRow extends StatelessWidget {
  const OrderStatusRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.fontSize,
    this.iconColor,
    this.textColor,
    this.iconBackgroundColor,
  });
  final double? fontSize;
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with modern styling
        Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(8)),
            decoration: BoxDecoration(
                color: iconBackgroundColor ?? kWhiteColor,
                borderRadius: BorderRadius.circular(kDefaultPadding / 2)),
            child: Icon(
              icon,
              color: iconColor ?? kBlackColor,
              size: getProportionateScreenWidth(kDefaultPadding * 1.4),
            )),
        SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
        // Text with improved hierarchy
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: fontSize ?? getProportionateScreenHeight(14),
                      fontWeight: FontWeight.bold,
                      color:
                          textColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor != null
                          ? textColor!.withValues(alpha: 0.7)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
