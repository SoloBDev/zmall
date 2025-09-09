import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';

class LocationContainer extends StatelessWidget {
  const LocationContainer({
    super.key,
    required this.title,
    this.isSelected = false,
    required this.press,
    required this.note,
  });

  final String? title, note;
  final bool isSelected;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return ProfileListTile(
      onTap: press,
      showTrailing: false,
      subtitle: Text(note!),
      title: title ?? "Other Location",
      borderColor: isSelected ? kSecondaryColor : kWhiteColor,
      icon: Icon(
        isSelected ? HeroiconsSolid.checkCircle : HeroiconsSolid.minusCircle,
        color: isSelected ? kSecondaryColor : kGreyColor,
      ),
    );
  }
}

    // GestureDetector(
    //   onTap: press,
    //   child: Container(
    //     decoration: BoxDecoration(
    //       color: kPrimaryColor,
    //       boxShadow: [kDefaultShadow],
    //       border: Border.all(
    //         width: isSelected ? 2 : 1,
    //         color: isSelected ? kSecondaryColor : kWhiteColor,
    //       ),
    //       borderRadius: BorderRadius.circular(
    //         getProportionateScreenWidth(kDefaultPadding / 2),
    //       ),
    //     ),
    //     padding: EdgeInsets.symmetric(
    //         horizontal: getProportionateScreenWidth(kDefaultPadding / 2)),
    //     child: Row(
    //       crossAxisAlignment: CrossAxisAlignment.center,
    //       spacing: getProportionateScreenWidth(kDefaultPadding / 2),
    //       children: [
    //         Container(
    //           height: kDefaultPadding,
    //           width: getProportionateScreenWidth(kDefaultPadding / 1.5),
    //           decoration: BoxDecoration(
    //             color: isSelected ? kSecondaryColor : kPrimaryColor,
    //             shape: BoxShape.circle,
    //             border: Border.all(
    //                 width: 1.5,
    //                 color: isSelected ? kSecondaryColor : kBlackColor),
    //           ),
    //         ),
    //         Expanded(
    //           child: Padding(
    //             padding: EdgeInsets.symmetric(
    //                 vertical:
    //                     getProportionateScreenHeight(kDefaultPadding / 2)),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Text(
    //                   note!,
    //                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
    //                         color: isSelected ? kBlackColor : kGreyColor,
    //                         fontWeight:
    //                             isSelected ? FontWeight.w500 : FontWeight.w200,
    //                       ),
    //                 ),
    //                 Text(
    //                   title ?? "Location",
    //                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
    //                         fontWeight:
    //                             isSelected ? FontWeight.w700 : FontWeight.w500,
    //                       ),
    //                   softWrap: true,
    //                   textAlign: TextAlign.left,
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );