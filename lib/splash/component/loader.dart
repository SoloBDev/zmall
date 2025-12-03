import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: getProportionateScreenHeight(kDefaultPadding * 2),
      children: [
        Container(
          width: getProportionateScreenWidth(kDefaultPadding * 10),
          height: getProportionateScreenHeight(kDefaultPadding * 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(zmallLogo),
              fit: BoxFit.contain,
            ),
          ),
        ),
        LinearLoadingIndicator(
          iconColor: kPrimaryColor,
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }
}
