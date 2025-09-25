import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CategoryCardWidget extends StatelessWidget {
  const CategoryCardWidget({
    super.key,
    required this.imageUrl,
    required this.category,
    required this.onPressed,
  });
  final String imageUrl, category;
  final GestureTapCallback onPressed;

  @override
  Widget build(BuildContext context) {
    double width = getProportionateScreenWidth(kDefaultPadding * 3.3);
    double height = getProportionateScreenHeight(kDefaultPadding * 2.8);
    BorderRadiusGeometry borderRadius = BorderRadius.circular(
      getProportionateScreenWidth(kDefaultPadding / 1.5),
    );
    EdgeInsetsGeometry padding = EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding / 4),
        vertical: getProportionateScreenWidth(kDefaultPadding / 4));
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding / 4),
          vertical: getProportionateScreenWidth(kDefaultPadding / 4)),
      decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(kDefaultPadding)),
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: getProportionateScreenHeight(kDefaultPadding / 3),
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => Container(
                width: width,
                height: height,
                padding: padding,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: borderRadius,
                  color: kWhiteColor,
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: imageProvider,
                  ),
                ),
              ),
              placeholder: (context, url) => Center(
                child: Container(
                  width: width,
                  height: height,
                  padding: padding,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kWhiteColor),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: width,
                height: height,
                padding: padding,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kWhiteColor,
                  borderRadius: borderRadius,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(zmallLogo),
                  ),
                ),
              ),
            ),
            Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Theme.of(context)
                  .textTheme
                  // .bodyMedium
                  .bodySmall
                  ?.copyWith(
                      color: kGreyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: getProportionateScreenWidth(10)),
            ),
          ],
        ),
      ),
    );
  }
}
