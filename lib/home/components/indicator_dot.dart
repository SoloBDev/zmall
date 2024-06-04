import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class IndicatorDot extends StatelessWidget {
  const IndicatorDot({
    Key? key,
    required this.isActive,
  }) : super(key: key);

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getProportionateScreenHeight(kDefaultPadding * .2),
      width: getProportionateScreenWidth(kDefaultPadding * .4),
      decoration: BoxDecoration(
        color: isActive ? kWhiteColor : Colors.white30,
        borderRadius: BorderRadius.circular(kDefaultPadding * .6),
      ),
    );
  }
}
