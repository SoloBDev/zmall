import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../size_config.dart';

class NavigationArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: getProportionateScreenWidth(kDefaultPadding),
      height: getProportionateScreenWidth(kDefaultPadding),
      child: Icon(
        Icons.keyboard_arrow_right,
        color: kSecondaryColor,
      ),
    );
  }
}
