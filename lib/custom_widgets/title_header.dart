import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class TitleHeader extends StatelessWidget {
  const TitleHeader({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: getProportionateScreenWidth(kDefaultPadding * .2)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "እንኳን ደህና መጡ",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: kWhiteColor),
            ),
            Text(
              title,
              style: TextStyle(
                color: kWhiteColor,
                fontWeight: FontWeight.bold,
                fontSize: getProportionateScreenWidth(16),
              ),
            ),
          ],
        )
      ],
    );
  }
}
