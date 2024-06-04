import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class VehicleContainer extends StatelessWidget {
  const VehicleContainer({
    Key? key,
    required this.imageUrl,
    required this.category,
    required this.press,
    required this.selected,
  }) : super(key: key);
  final String imageUrl, category;
  final GestureTapCallback press;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        width:
            getProportionateScreenWidth(kDefaultPadding * 9), //change *8 to *9
        decoration: BoxDecoration(
          boxShadow: [
            kDefaultShadow,
          ],
        ),
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        width: selected ? 4 : 1,
                        color: selected
                            ? kSecondaryColor
                            : kGreyColor.withOpacity(0.4))),
                child: Image.asset(
                  imageUrl,
                  width: getProportionateScreenWidth(kDefaultPadding * 5),
                  height: getProportionateScreenHeight(kDefaultPadding * 5),
                  fit: BoxFit.cover,
                ),
              ),
              //VerticalSpacing(),
              const SizedBox(height: 10.0),
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding / 2)),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(16.0),
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: kBlackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          color: kPrimaryColor,
        ),
      ),
    );
  }
}
