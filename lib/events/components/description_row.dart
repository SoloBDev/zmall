import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class DescriptionRow extends StatelessWidget {
  const DescriptionRow({Key? key, required this.title, required this.iconData})
      : super(key: key);

  final String title;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          iconData,
          color: kSecondaryColor,
          size: getProportionateScreenWidth(kDefaultPadding * 0.75),
        ),
        SizedBox(
          width: getProportionateScreenWidth(kDefaultPadding / 4),
        ),
        Expanded(
          child: Text(
            title.toString().toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: kBlackColor,
                ),
          ),
        ),
      ],
    );
  }
}
