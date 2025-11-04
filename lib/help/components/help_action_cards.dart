import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class HelpActionCards extends StatelessWidget {
  final String? title;
  final IconData icon;
  final Function()? onTap;
  final Color iconColor;
  final Color containerColor;
  final double padding;
  const HelpActionCards({
    super.key,
    this.title,
    required this.icon,
    this.onTap,
    this.iconColor = kBlackColor,
    this.padding = kDefaultPadding,
    this.containerColor = kWhiteColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kDefaultPadding / 1.6),
      splashColor: kBlackColor.withValues(alpha: 0.1),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: getProportionateScreenHeight(kDefaultPadding / 4),
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: containerColor,
                //  kBlackColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
                //  kBlackColor,
              ),
            ),

            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kBlackColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
