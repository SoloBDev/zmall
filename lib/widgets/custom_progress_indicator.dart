import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class CustomLinearProgressIndicator extends StatelessWidget {
  const CustomLinearProgressIndicator({
    super.key,
    this.message = "Loading...",
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitWave(
            color: kSecondaryColor,
            size: getProportionateScreenWidth(kDefaultPadding),
          ),
          SizedBox(height: kDefaultPadding * 0.5),
          Text(
            message,
            style: TextStyle(color: kBlackColor),
          ),
        ],
      ),
    );
  }
}
