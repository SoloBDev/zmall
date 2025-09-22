import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CustomBanner extends StatelessWidget {
  const CustomBanner({
    super.key,
    required this.imageUrl,
    required this.press,
    required this.subtitle,
    required this.title,
    this.isNetworkImage = false,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final bool isNetworkImage;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Container(
        width: double.infinity,
        height: getProportionateScreenHeight(kDefaultPadding * 7.5),
        // margin: EdgeInsets.symmetric(
        //   horizontal: getProportionateScreenWidth(kDefaultPadding),
        // ),
        // padding:EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          border: Border.all(color: kWhiteColor
              // kGreyColor.withValues(alpha: 0.1)
              ),
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding),
          ),
          // boxShadow: [boxShadow],
          // image: DecorationImage(
          //   image: isNetworkImage
          //       ? NetworkImage(imageUrl) as ImageProvider<Object>
          //       : AssetImage(imageUrl),
          //   fit: BoxFit.fill,
          // ),
        ),
        child: !isNetworkImage
            ? Container(
                width: double.infinity,
                height: getProportionateScreenHeight(kDefaultPadding * 8),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage(imageUrl),
                  ),
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                imageBuilder: (context, imageProvider) => Container(
                  width: double.infinity,
                  height: getProportionateScreenHeight(kDefaultPadding * 8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(
                        getProportionateScreenHeight(kDefaultPadding)),
                    image: DecorationImage(
                      fit: BoxFit.fill,
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
                  width: double.infinity,
                  height: getProportionateScreenHeight(kDefaultPadding * 8),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage(imageUrl),
                    ),
                  ),
                ),
              ),
        // child: Column(
        //   mainAxisAlignment: MainAxisAlignment.end,
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     Container(
        //       padding: EdgeInsets.all(kDefaultPadding / 2),
        //       decoration: BoxDecoration(
        //         color: kPrimaryColor.withValues(alpha: 0.7),
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
