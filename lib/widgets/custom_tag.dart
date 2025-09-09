import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CustomTag extends StatelessWidget {
  const CustomTag({
    super.key,
    this.color = Colors.black,
    this.text = "Tag",
    this.textColor = kPrimaryColor,
  });

  final Color? color;
  final String? text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            getProportionateScreenHeight(kDefaultPadding / 3),
          ),
          color: color),
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
        vertical: getProportionateScreenHeight(kDefaultPadding / 4),
      ),
      child: Text(
        text!,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
