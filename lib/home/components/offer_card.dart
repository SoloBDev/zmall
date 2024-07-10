import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/size_config.dart';

class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({
    Key? key,
    required this.imageUrl,
    required this.itemName,
    required this.specialOffer,
    required this.isDiscounted,
    required this.newPrice,
    required this.originalPrice,
    required this.storeName,
    required this.press,
    required this.storePress,
  }) : super(key: key);

  final String imageUrl;
  final String itemName;
  final String specialOffer;
  final bool isDiscounted;
  final String newPrice;
  final String originalPrice;
  final String storeName;
  final GestureTapCallback press, storePress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
          topLeft: Radius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding / 2),
                    ),
                    // boxShadow: [boxShadow],
                  ),
                  height: getProportionateScreenHeight(kDefaultPadding * 7.5),
                  width: getProportionateScreenWidth(kDefaultPadding * 8.25),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: imageProvider,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => Center(
                      child: Container(
                        width:
                            getProportionateScreenWidth(kDefaultPadding * 3.5),
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 3.5),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kWhiteColor),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage('images/trending.png'),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: kPrimaryColor,
                  width: getProportionateScreenWidth(kDefaultPadding * 8.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: getProportionateScreenHeight(
                                kDefaultPadding / 5)),
                        child: Text(
                          itemName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: kBlackColor,
                              ),
                          maxLines: 1,
                        ),
                      ),
                      Row(
                        children: [
                          if (isDiscounted)
                            Text(
                              "$originalPrice",
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        fontWeight: FontWeight.w500,
                                        color: kGreyColor,
                                      ),
                            ),
                          if (isDiscounted)
                            SizedBox(
                              width: 5,
                            ),
                          Text(
                            newPrice,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: kBlackColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                          Text(
                            "${Provider.of<ZMetaData>(context, listen: false).currency}",
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: kBlackColor,
                                    ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: storePress,
                        child: Text(
                          storeName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: kSecondaryColor.withOpacity(0.7),
                                // decoration: TextDecoration.underline,
                              ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            isDiscounted || specialOffer.isNotEmpty
                ? Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      color: kSecondaryColor,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2),
                        child: Text(
                          specialOffer.isNotEmpty
                              ? specialOffer
                              : "${(100.00 - (double.parse(newPrice) / double.parse(originalPrice) * 100)).toStringAsFixed(0)}% ${Provider.of<ZLanguage>(context, listen: true).discount}",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: kPrimaryColor),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
