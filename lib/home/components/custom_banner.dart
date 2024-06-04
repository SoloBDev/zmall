import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CustomBanner extends StatelessWidget {
  const CustomBanner({
    Key? key,
    required this.imageUrl,
    required this.press,
    required this.subtitle,
    required this.title,
  }) : super(key: key);

  final String imageUrl;
  final String title;
  final String subtitle;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        width: double.infinity,
        height: getProportionateScreenHeight(kDefaultPadding * 7.5),
        margin: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding),
        ),
        padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          border: Border.all(color: kGreyColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
          boxShadow: [boxShadow],
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        // child: Column(
        //   mainAxisAlignment: MainAxisAlignment.end,
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     Container(
        //       padding: EdgeInsets.all(kDefaultPadding / 2),
        //       decoration: BoxDecoration(
        //         color: kPrimaryColor.withOpacity(0.7),
        //         borderRadius: BorderRadius.circular(kDefaultPadding),
        //       ),
        //       child: Text.rich(
        //         TextSpan(
        //           text: title,
        //           style: TextStyle(
        //             color: kSecondaryColor,
        //           ),
        //           children: [
        //             TextSpan(
        //               text: subtitle,
        //               style: TextStyle(
        //                 color: kSecondaryColor,
        //                 fontWeight: FontWeight.bold,
        //                 fontSize:
        //                     getProportionateScreenWidth(kDefaultPadding + 4),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
