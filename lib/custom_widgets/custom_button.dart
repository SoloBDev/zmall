import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    key,
    required this.title,
    required this.press,
    this.color = kPrimaryColor,
  }) : super(key: key);
  final String title;
  final GestureTapCallback press;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      onTap: press,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        padding: EdgeInsets.all(kDefaultPadding * 0.75),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.all(
            Radius.circular(kDefaultPadding / 2),
          ),
          // boxShadow: [boxShadow],
        ),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.button?.copyWith(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
