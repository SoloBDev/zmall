import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.title,
    required this.press,
    this.color,
    this.child,
    this.isLoading,
    this.titleColor,
    this.borderColor,
  });
  final Widget? child;
  final String title;
  final Color? color;
  final bool? isLoading;
  final Color? titleColor;
  final Color? borderColor;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: color ?? kSecondaryColor,
        border: Border.all(color: borderColor ?? Colors.transparent),
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          onTap: press,
          child: Center(
            child: isLoading != null && isLoading!
                ? Row(
                    spacing: kDefaultPadding / 2,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      loadingIndicator(size: 30, color: Colors.white),
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor ?? kPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  )
                : Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? kPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
            // isLoading != null && isLoading!
            //     ? loadingIndicator(size: 30, color: Colors.white)
            //     : Text(
            //         title,
            //         style: TextStyle(
            //           color: titleColor ?? kPrimaryColor,
            //           fontSize: 16,
            //           fontWeight: FontWeight.bold,
            //           letterSpacing: 2.0,
            //         ),
            //       ),
          ),
        ),
      ),
    );
    // return InkWell(
    //   borderRadius: BorderRadius.circular(kDefaultPadding),
    //   onTap: press,
    //   child: Container(
    //     alignment: Alignment.center,
    //     width: double.infinity,
    //     padding: EdgeInsets.all(
    //         child != null ? kDefaultPadding / 2 : kDefaultPadding * 0.75),
    //     decoration: BoxDecoration(
    //       color: color,
    //       borderRadius: BorderRadius.all(
    //         Radius.circular(kDefaultPadding / 2),
    //       ),
    //       // boxShadow: [boxShadow],
    //     ),
    //     child: child ??
    //         Text(
    //           title.toUpperCase(),
    //           style: Theme.of(context).textTheme.labelLarge?.copyWith(
    //                 color: kPrimaryColor,
    //                 fontWeight: FontWeight.bold,
    //               ),
    //         ),
    //   ),
    // );
  }
}
