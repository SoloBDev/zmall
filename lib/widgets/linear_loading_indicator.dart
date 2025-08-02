import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class LinearLoadingIndicator extends StatelessWidget {
  final String? title;
  const LinearLoadingIndicator({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        height: kDefaultPadding * 5,
        width: kDefaultPadding * 5,
        decoration: BoxDecoration(
            color: kGreyColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(kDefaultPadding)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitWave(
              color: kSecondaryColor,
              size: getProportionateScreenWidth(kDefaultPadding),
            ),
            SizedBox(height: kDefaultPadding / 2),
            Text(title ?? "Loading...",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: kPrimaryColor)
                // TextStyle(color: kPrimaryColor),
                ),
          ],
        ),
      ),
    );
  }
}
