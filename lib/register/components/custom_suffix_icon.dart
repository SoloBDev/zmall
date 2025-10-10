import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class CustomSuffixIcon extends StatelessWidget {
  const CustomSuffixIcon({
    Key? key,
    required this.iconData,
  }) : super(key: key);

  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(4),
        vertical: getProportionateScreenHeight(2),
      ),
      child: Icon(
        iconData,
        size: getProportionateScreenWidth(kDefaultPadding * 1.2),
      ),
    );
  }
}
