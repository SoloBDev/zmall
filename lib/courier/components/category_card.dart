import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
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
    return GestureDetector(
      onTap: press,
      child: Container(
        width: getProportionateScreenWidth(kDefaultPadding * 8),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(kDefaultPadding),
          border: Border.all(
            color:
                selected ? kSecondaryColor : kGreyColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: getProportionateScreenHeight(kDefaultPadding / 8),
          children: [
            Image.asset(
              imageUrl,
              width: getProportionateScreenWidth(kDefaultPadding * 5),
              height: getProportionateScreenHeight(kDefaultPadding * 3),
              fit: BoxFit.cover,
            ),
            Text(category,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: kBlackColor,
                    )),
          ],
        ),
      ),
    );
  }
}

 // CachedNetworkImage(
            //   imageUrl: imageUrl,
            //   imageBuilder: (context, imageProvider) => Container(
            //     width: getProportionateScreenWidth(kDefaultPadding * 4),
            //     height: getProportionateScreenHeight(kDefaultPadding * 4),
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       image: DecorationImage(
            //         fit: BoxFit.cover,
            //         image: imageProvider,
            //       ),
            //     ),
            //   ),
            //   placeholder: (context, url) => Center(
            //     child: CircularProgressIndicator(
            //       valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
            //     ),
            //   ),
            //   errorWidget: (context, url, error) => Container(
            //     width: getProportionateScreenWidth(kDefaultPadding * 4),
            //     height: getProportionateScreenHeight(kDefaultPadding * 4),
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       color: kWhiteColor,
            //       image: DecorationImage(
            //         fit: BoxFit.cover,
            //         image: AssetImage('images/zmall.jpg'),
            //       ),
            //     ),
            //   ),
            // ),