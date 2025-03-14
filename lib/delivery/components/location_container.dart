import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class LocationContainer extends StatelessWidget {
  const LocationContainer({
    Key? key,
    required this.title,
    this.isSelected = false,
    required this.press,
    required this.note,
  }) : super(key: key);

  final String? title, note;
  final bool isSelected;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected
                  ? kSecondaryColor
                  : kGreyColor.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
          boxShadow: [kDefaultShadow],
          color: kPrimaryColor,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
            Container(
              height: kDefaultPadding,
              width: getProportionateScreenWidth(kDefaultPadding / 2),
              decoration: BoxDecoration(
                color: isSelected ? kSecondaryColor : kPrimaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                    width: 1, color: isSelected ? kGreyColor : kBlackColor),
              ),
            ),
            SizedBox(
              width: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical:
                        getProportionateScreenHeight(kDefaultPadding / 2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isSelected ? kBlackColor : kGreyColor,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w200,
                          ),
                    ),
                    Text(
                      title ?? "Location",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                      softWrap: true,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
