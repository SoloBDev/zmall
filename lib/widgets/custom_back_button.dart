import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

class CustomBackButton extends StatelessWidget {
  final Color? color;
  final Color? backgroundColor;
  final Function()? onPressed;
  const CustomBackButton(
      {Key? key, this.color, this.backgroundColor, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios),
      color: color ?? kBlackColor,
      onPressed: onPressed ??
          () {
            Navigator.of(context).pop();
          },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
            backgroundColor ?? Colors.transparent),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.all(kDefaultPadding * 0.666),
        ),
      ),
    );
  }
}
