import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
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
        width: getProportionateScreenWidth(kDefaultPadding * 8),
        decoration: BoxDecoration(
          boxShadow: [
            kDefaultShadow,
          ],
        ),
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                imageBuilder: (context, imageProvider) => Container(
                  width: getProportionateScreenWidth(kDefaultPadding * 5),
                  height: getProportionateScreenHeight(kDefaultPadding * 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: imageProvider,
                    ),
                  ),
                ),
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: getProportionateScreenWidth(kDefaultPadding * 6),
                  height: getProportionateScreenHeight(kDefaultPadding * 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kWhiteColor,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('images/zmall.jpg'),
                    ),
                  ),
                ),
              ),
              VerticalSpacing(),
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding / 2)),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(16.0),
                    fontWeight: FontWeight.w500,
                    color: selected ? kPrimaryColor : kBlackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          color: selected ? kSecondaryColor : kPrimaryColor,
        ),
      ),
    );
  }
}
