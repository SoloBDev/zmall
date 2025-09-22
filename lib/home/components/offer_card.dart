import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({
    super.key,
    required this.imageUrl,
    required this.itemName,
    required this.specialOffer,
    required this.isDiscounted,
    required this.newPrice,
    required this.originalPrice,
    required this.storeName,
    required this.press,
    required this.storePress,
    //
    this.isOpen,
  });

  final String imageUrl;
  final String itemName;
  final String specialOffer;
  final bool isDiscounted;
  final String newPrice;
  final String originalPrice;
  final String storeName;
  final GestureTapCallback press, storePress;
  final bool? isOpen; // New boolean to indicate if the store is open

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Container(
        width: getProportionateScreenWidth(kDefaultPadding * 9),
        // width: getProportionateScreenWidth(kDefaultPadding * 10),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          // boxShadow: [boxShadow],
          // border: Border.all(color: kWhiteColor),
          border: Border.all(color: kBlackColor.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding / 2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height:
                          getProportionateScreenHeight(kDefaultPadding * 7.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        // boxShadow: [boxShadow],
                      ),
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
                            width: getProportionateScreenWidth(
                                kDefaultPadding * 3.5),
                            height: getProportionateScreenHeight(
                                kDefaultPadding * 3.5),
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
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: getProportionateScreenWidth(kDefaultPadding / 2),
                      right: getProportionateScreenWidth(kDefaultPadding / 2),
                      bottom: getProportionateScreenHeight(kDefaultPadding / 3),
                    ),
                    // width: getProportionateScreenWidth(kDefaultPadding * 8.25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: kBlackColor,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                        Row(
                          spacing: kDefaultPadding / 2,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (isDiscounted)
                              Text(
                                "$originalPrice",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: kGreyColor,
                                      fontWeight: FontWeight.w100,
                                      decorationColor: kGreyColor,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                            Text(
                              "${newPrice}${Provider.of<ZMetaData>(context, listen: false).currency}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: kBlackColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding),
                          ),
                          child: InkWell(
                            onTap: storePress,
                            child: Text(
                              Service.capitalizeFirstLetters(storeName),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kGreyColor,
                                  ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              if (isDiscounted || specialOffer.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: kDefaultPadding / 5,
                      bottom: kDefaultPadding / 5,
                    ),
                    height: getProportionateScreenHeight(kDefaultPadding * 1.6),
                    decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(kDefaultPadding),
                          topRight: Radius.circular(kDefaultPadding),
                        )),
                    child: Container(
                      height: getProportionateScreenHeight(kDefaultPadding),
                      padding: EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 3,
                        vertical: kDefaultPadding / 4,
                      ),
                      decoration: BoxDecoration(
                          color: kSecondaryColor,
                          // .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(kDefaultPadding / 1.55),
                            topRight: Radius.circular(kDefaultPadding / 1.55),
                          )),
                      child: Text(
                        specialOffer.isNotEmpty
                            ? specialOffer
                            : "${(100.00 - (double.parse(newPrice) / double.parse(originalPrice) * 100)).toStringAsFixed(0)}% Off",
                        // : "${(100.00 - (double.parse(newPrice) / double.parse(originalPrice) * 100)).toStringAsFixed(0)}% ${Provider.of<ZLanguage>(context, listen: true).discount}",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding / 1.3)),
                      ),
                    ),
                  ),
                ),
              // Store closed overlay
              if (!isOpen!)
                Container(
                  height: double.infinity,
                  padding: EdgeInsets.only(bottom: kDefaultPadding),
                  decoration: BoxDecoration(
                    color: kBlackColor.withValues(alpha: 0.6),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Store\nClosed",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding / 1.2),
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


///with transparent overlay
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/models/language.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';

// class SpecialOfferCard extends StatelessWidget {
//   const SpecialOfferCard({
//     super.key,
//     required this.imageUrl,
//     required this.itemName,
//     required this.specialOffer,
//     required this.isDiscounted,
//     required this.newPrice,
//     required this.originalPrice,
//     required this.storeName,
//     required this.press,
//     required this.storePress,
//     //
//     this.isOpen,
//   });

//   final String imageUrl;
//   final String itemName;
//   final String specialOffer;
//   final bool isDiscounted;
//   final String newPrice;
//   final String originalPrice;
//   final String storeName;
//   final GestureTapCallback press, storePress;
//   final bool? isOpen; // New boolean to indicate if the store is open

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: press,
//       child: Container(
//         width: getProportionateScreenWidth(kDefaultPadding * 10),
//         decoration: BoxDecoration(
//           color: kPrimaryColor,
//           boxShadow: [boxShadow],
//           border: Border.all(color: kWhiteColor),
//           borderRadius: BorderRadius.circular(kDefaultPadding),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(
//             getProportionateScreenWidth(kDefaultPadding / 2),
//           ),
//           child: Stack(
//             children: [
//               // Full container image
//               SizedBox(
//                 width: double.infinity,
//                 height: double.infinity,
//                 child: CachedNetworkImage(
//                   imageUrl: imageUrl,
//                   imageBuilder: (context, imageProvider) => Container(
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         fit: BoxFit.fill,
//                         image: imageProvider,
//                       ),
//                     ),
//                   ),
//                   placeholder: (context, url) => Center(
//                     child: Container(
//                       width: getProportionateScreenWidth(kDefaultPadding * 3.5),
//                       height:
//                           getProportionateScreenHeight(kDefaultPadding * 3.5),
//                       child: CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(kWhiteColor),
//                       ),
//                     ),
//                   ),
//                   errorWidget: (context, url, error) => Container(
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         fit: BoxFit.cover,
//                         image: AssetImage('images/trending.png'),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               // Item details with blurry black background
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     color: kBlackColor.withValues(alpha: 0.8),
//                     padding: EdgeInsets.symmetric(
//                       vertical:
//                           getProportionateScreenHeight(kDefaultPadding / 3),
//                       horizontal:
//                           getProportionateScreenWidth(kDefaultPadding / 2),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         InkWell(
//                           onTap: storePress,
//                           child: Text(
//                             maxLines: 1,
//                             Service.capitalizeFirstLetters(storeName),
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .labelSmall
//                                 ?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                   color: kWhiteColor,
//                                 ),
//                           ),
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           children: [
//                             if (isDiscounted)
//                               Text(
//                                 "$originalPrice",
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .bodySmall
//                                     ?.copyWith(
//                                       color: kWhiteColor,
//                                       fontWeight: FontWeight.w100,
//                                       decorationColor: kBlackColor,
//                                       decoration: TextDecoration.lineThrough,
//                                     ),
//                               ),
//                             if (isDiscounted)
//                               SizedBox(
//                                 width: getProportionateScreenWidth(
//                                     kDefaultPadding / 4),
//                               ),
//                             Text(
//                               "${newPrice} ${Provider.of<ZMetaData>(context, listen: false).currency}",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodySmall
//                                   ?.copyWith(
//                                     color: kWhiteColor,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                             ),
//                           ],
//                         ),
//                         Text(
//                           itemName,
//                           maxLines: 1,
//                           style:
//                               Theme.of(context).textTheme.titleSmall?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: kWhiteColor,
//                                   ),
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//               if (isDiscounted || specialOffer.isNotEmpty)
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   child: Container(
//                     padding: EdgeInsets.only(
//                       left: kDefaultPadding / 3,
//                       bottom: kDefaultPadding / 3,
//                     ),
//                     height: getProportionateScreenHeight(kDefaultPadding * 1.9),
//                     decoration: BoxDecoration(
//                         color: kWhiteColor,
//                         borderRadius: BorderRadius.only(
//                           bottomLeft: Radius.circular(kDefaultPadding),
//                           topRight: Radius.circular(kDefaultPadding),
//                         )),
//                     child: Container(
//                       height:
//                           getProportionateScreenHeight(kDefaultPadding * 1.5),
//                       padding: EdgeInsets.symmetric(
//                         horizontal: kDefaultPadding / 2,
//                         vertical: kDefaultPadding / 3,
//                       ),
//                       decoration: BoxDecoration(
//                           color: kSecondaryColor,
//                           borderRadius: BorderRadius.only(
//                             bottomLeft: Radius.circular(kDefaultPadding / 1.55),
//                             topRight: Radius.circular(kDefaultPadding / 1.55),
//                           )),
//                       child: Text(
//                         specialOffer.isNotEmpty
//                             ? specialOffer
//                             : "${(100.00 - (double.parse(newPrice) / double.parse(originalPrice) * 100)).toStringAsFixed(0)}% ${Provider.of<ZLanguage>(context, listen: true).discount}",
//                         style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                             color: kPrimaryColor, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ),
//               // Store closed overlay
//               if (isOpen != null && !isOpen!)
//                 Container(
//                   height: double.infinity,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: kBlackColor.withValues(alpha: 0.5),
//                   ),
//                   child: Center(
//                     child: Text(
//                       "Store\nClosed",
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                             fontSize: 16,
//                             color: kPrimaryColor,
//                             fontWeight: FontWeight.bold,
//                           ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }