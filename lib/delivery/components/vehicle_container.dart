import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class VehicleContainer extends StatelessWidget {
  const VehicleContainer({
    super.key,
    required this.imageUrl,
    required this.category,
    required this.press,
    required this.selected,
  });
  final String imageUrl, category;
  final GestureTapCallback press;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: getProportionateScreenWidth(kDefaultPadding * 6),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 4),
            color: kBlackColor.withValues(alpha: 0.08),
          ),
          // BoxShadow(
          //   color: kWhiteColor,
          //   blurRadius: 3,
          //   spreadRadius: 2,
          //   offset: Offset(0, 2),
          // ),
        ],
        border: Border.all(
          width: selected ? 2 : 1,
          color: selected ? kSecondaryColor : kWhiteColor,
        ),
        borderRadius: BorderRadius.circular(
          getProportionateScreenWidth(kDefaultPadding / 1.5),
        ),
      ),
      child: InkWell(
        onTap: press,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imageUrl,
              width: getProportionateScreenWidth(kDefaultPadding * 6),
              height: getProportionateScreenHeight(kDefaultPadding * 3),
              fit: BoxFit.cover,
            ),
            Text(
              Service.capitalizeFirstLetters(category),
              // .toUpperCase(),
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14.0),
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? kSecondaryColor : kBlackColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';

// class VehicleContainer extends StatelessWidget {
//   const VehicleContainer({
//     super.key,
//     required this.imageUrl,
//     required this.category,
//     required this.press,
//     required this.selected,
//   });
//   final String imageUrl, category;
//   final GestureTapCallback press;
//   final bool selected;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: getProportionateScreenWidth(kDefaultPadding * 6),
//       // height: getProportionateScreenHeight(kDefaultPadding * 7),
//       decoration: BoxDecoration(
//         color: kPrimaryColor,
//         boxShadow: [
//           BoxShadow(
//             color: kWhiteColor,
//             blurRadius: 3,
//             spreadRadius: 2,
//             offset: Offset(0, 2),
//           ),
//         ],

//         border: Border.all(
//           width: selected ? 2 : 1,
//           color: selected ? kSecondaryColor : kWhiteColor,
//         ),
//         borderRadius: BorderRadius.circular(
//           getProportionateScreenWidth(kDefaultPadding / 1.5),
//         ),
//         // color:
//         //     selected ? kSecondaryColor.withValues(alpha: 0.2) : kPrimaryColor,
//       ),
//       child: InkWell(
//         onTap: press,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Container(
//             //   decoration: BoxDecoration(
//             //     shape: BoxShape.circle,
//             //     border: Border.all(
//             //       width: selected ? 4 : 1,
//             //       color: selected ? kSecondaryColor : kWhiteColor,
//             //     ),
//             //   ),
//             //   child: Image.asset(
//             //     imageUrl,
//             //     width: getProportionateScreenWidth(kDefaultPadding * 4),
//             //     height: getProportionateScreenHeight(kDefaultPadding * 4),
//             //     fit: BoxFit.cover,
//             //   ),
//             // ),
//             //VerticalSpacing(),
//             Image.asset(
//               imageUrl,
//               width: getProportionateScreenWidth(kDefaultPadding * ),
//               height: getProportionateScreenHeight(kDefaultPadding * 4),
//               fit: BoxFit.cover,
//             ),
//             // SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 3)),
//             Container(
//               //   margin: EdgeInsets.symmetric(
//               //     horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
//               //   ),
//               child: Text(
//                 Service.capitalizeFirstLetters(category),
//                 // .toUpperCase(),
//                 style: TextStyle(
//                   fontSize: getProportionateScreenWidth(14.0),
//                   fontWeight: selected ? FontWeight.bold : FontWeight.w500,
//                   color: selected ? kSecondaryColor : kBlackColor,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
