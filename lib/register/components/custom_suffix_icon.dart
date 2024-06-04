import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import '../../size_config.dart';

class CustomSuffixIcon extends StatelessWidget {
  const CustomSuffixIcon({
    Key? key,
    required this.iconData,
  }) : super(key: key);

  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        getProportionateScreenWidth(20),
        getProportionateScreenWidth(20),
        getProportionateScreenWidth(20),
      ),
      child: Icon(
        iconData,
        size: getProportionateScreenWidth(kDefaultPadding),
      ),
    );
  }
}
