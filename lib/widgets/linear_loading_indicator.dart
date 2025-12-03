import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class LinearLoadingIndicator extends StatelessWidget {
  final String? title;
  final double? width;
  final double? height;
  final double? fontSize;
  final Color? iconColor;
  final Color? backgroundColor;

  const LinearLoadingIndicator({
    super.key,
    this.title,
    this.width,
    this.height,
    this.fontSize,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        height: height ?? getProportionateScreenHeight(kDefaultPadding * 5),
        width: width ?? getProportionateScreenWidth(kDefaultPadding * 5),
        decoration: BoxDecoration(
          color: backgroundColor ?? kGreyColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: getProportionateScreenHeight(kDefaultPadding / 2),
            children: [
              SpinKitWave(
                color: iconColor ?? kSecondaryColor,
                size: getProportionateScreenWidth(kDefaultPadding),
              ),
              Text(
                title ?? "Loading...",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: kPrimaryColor,
                  fontSize: fontSize ?? 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
