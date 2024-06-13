import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({Key? key, this.sectionTitle, this.press, this.subTitle})
      : super(key: key);

  final String? sectionTitle, subTitle;
  final GestureTapCallback? press;

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
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: kBlackColor,
                    fontSize:
                        getProportionateScreenHeight(kDefaultPadding * 1.3),
                    fontWeight:
                        Platform.isIOS ? FontWeight.bold : FontWeight.w800,
                  ),
            ),
          ),
          subTitle != null && subTitle!.isNotEmpty
              ? InkWell(
                  onTap: press,
                  child: Text(
                    subTitle!,
                    style: TextStyle(color: kGreyColor),
                  ),
                )
              : GestureDetector(
                  onTap: press,
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
