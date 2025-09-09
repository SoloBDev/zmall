import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    this.icon,
    this.onSubTitlePress,
    this.subTitle,
    this.sectionTitle,
    this.subTitleColor,
    this.subTitleFontWeight,
  });
  final IconData? icon;
  final Color? subTitleColor;
  final String? sectionTitle, subTitle;
  final FontWeight? subTitleFontWeight;
  final GestureTapCallback? onSubTitlePress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: getProportionateScreenHeight(kDefaultPadding / 2),
        bottom: getProportionateScreenWidth(kDefaultPadding / 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              sectionTitle!,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: kBlackColor,
                    fontSize: getProportionateScreenHeight(kDefaultPadding),
                    fontWeight:
                        Platform.isIOS ? FontWeight.bold : FontWeight.w800,
                  ),
            ),
          ),
          subTitle != null && subTitle!.isNotEmpty
              ? InkWell(
                  onTap: onSubTitlePress,
                  child: icon != null
                      ? Row(
                          spacing:
                              getProportionateScreenWidth(kDefaultPadding / 3),
                          children: [
                            Text(
                              subTitle!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: subTitleFontWeight,
                                color: subTitleColor ?? kGreyColor,
                              ),
                            ),
                            Icon(
                              icon,
                              size: 18,
                              color: subTitleColor,
                            ),
                          ],
                        )
                      : Text(
                          subTitle!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: subTitleFontWeight,
                            color: subTitleColor ?? kGreyColor,
                          ),
                        ),
                )
              : GestureDetector(
                  onTap: onSubTitlePress,
                  child: Icon(
                    Icons.add_circle,
                    color: kSecondaryColor,
                  ),
                )
        ],
      ),
    );
  }
}
