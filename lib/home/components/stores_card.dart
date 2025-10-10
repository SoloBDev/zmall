///updated
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';

class StoresCard extends StatelessWidget {
  const StoresCard({
    super.key,
    required this.imageUrl,
    required this.storeName,
    required this.deliveryType,
    required this.distance,
    required this.press,
    required this.rating,
    required this.ratingCount,
    this.featuredTag = "",
    this.isFeatured = false,
  });

  final String imageUrl;
  final String storeName;
  final String deliveryType;
  final String distance, rating, ratingCount, featuredTag;
  final GestureTapCallback press;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        // width: getProportionateScreenWidth(kDefaultPadding * 12),
        width: getProportionateScreenWidth(kDefaultPadding * 11),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          // border: Border.all(
          //   color: kWhiteColor,
          // ),
          border: Border.all(color: kBlackColor.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding / 2)),
          // boxShadow: [
          //   BoxShadow(
          //     color: kBlackColor.withValues(alpha: 0.08),
          //     spreadRadius: 0,
          //     blurRadius: 8,
          //     offset: Offset(0, 4),
          //   ),
          // ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: getProportionateScreenHeight(kDefaultPadding * 5.0),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                      topLeft: Radius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                      topLeft: Radius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2)),
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
                          width:
                              getProportionateScreenWidth(kDefaultPadding * 5),
                          height:
                              getProportionateScreenHeight(kDefaultPadding * 5),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.transparent,
                            ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maxLines: 1,
                        Service.capitalizeFirstLetters(storeName),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: kBlackColor,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //store rating and distance

                          Row(
                            spacing: 2,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: getProportionateScreenWidth(
                                    kDefaultPadding * 0.9),
                              ),
                              Text(
                                "$rating",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kBlackColor,
                                    ),
                              ),
                              Text(
                                "($ratingCount)",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.normal,
                                      color: kGreyColor,
                                    ),
                              ),
                            ],
                          ),
                          //store distance
                          // Row(
                          //   spacing: 2,
                          //   mainAxisAlignment: MainAxisAlignment.start,
                          //   children: [
                          //     Icon(
                          //       Icons.social_distance_rounded,
                          //       color: kGreyColor,
                          //       size: getProportionateScreenWidth(
                          //           kDefaultPadding * 0.9),
                          //     ),
                          //     Text(
                          //       "$distance KM",
                          //       style: Theme.of(context)
                          //           .textTheme
                          //           .labelSmall
                          //           ?.copyWith(
                          //             // fontWeight: FontWeight.w500,
                          //             color: kGreyColor,
                          //           ),
                          //     ),
                          //   ],
                          // ),

                          ///dot separator

                          Container(
                            width: 5,
                            height: kDefaultPadding / 1.2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kGreyColor.withValues(alpha: 0.6),
                            ),
                          ),

                          ///store delivery type
                          Text(
                            Service.capitalizeFirstLetters(deliveryType),
                            // Service.capitalizeFirstLetters(storeName),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              color: kBlackColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
            if (isFeatured)
              Positioned(
                right: -1,
                top: -3,
                child: Container(
                  height: getProportionateScreenWidth(kDefaultPadding * 3),
                  width: getProportionateScreenWidth(kDefaultPadding * 3),
                  //
                  child: Center(
                      child: Image.asset("images/store_tags/$featuredTag.png")),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// with transparent overlay for featured stores
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';

// class StoresCard extends StatelessWidget {
//   const StoresCard({
//     super.key,
//     required this.imageUrl,
//     required this.storeName,
//     required this.deliveryType,
//     required this.distance,
//     required this.press,
//     required this.rating,
//     required this.ratingCount,
//     this.featuredTag = "",
//     this.isFeatured = false,
//     this.isStoreOpened,
//     // this.isPromotional = false,
//   });

//   final String imageUrl;
//   final String storeName;
//   final String deliveryType;
//   final String distance, rating, ratingCount, featuredTag;
//   final GestureTapCallback press;
//   final bool isFeatured;
//   final bool? isStoreOpened;
//   // final bool isPromotional;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: press, child: featuredStoresCard(context),
//       // isFeatured ? featuredStoresCard(context) : nearbyStoresCard(context),
//     );
//   }

//   // Blurred details section for promotional stores
//   Widget _buildPromotionalDetailsSection(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.only(
//         bottomLeft: Radius.circular(
//           getProportionateScreenWidth(kDefaultPadding / 2),
//         ),
//         bottomRight: Radius.circular(
//           getProportionateScreenWidth(kDefaultPadding / 2),
//         ),
//       ),
//       // child: BackdropFilter(
//       //   filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//       child: Container(
//         width: double.infinity,
//         color: kBlackColor.withValues(alpha: 0.8),
//         padding: EdgeInsets.symmetric(
//           horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
//           vertical: getProportionateScreenHeight(kDefaultPadding / 3),
//         ),
//         child: _buildDetailsContent(context, true),
//       ),
//       // ),
//     );
//   }

//   // Common details content with different styling based on whether it's promotional
//   Widget _buildDetailsContent(BuildContext context, bool isPromotionalStyle) {
//     final textColor = isPromotionalStyle ? kWhiteColor : kBlackColor;
//     final iconColor = isPromotionalStyle ? kWhiteColor : kGreyColor;
//     final dotColor =
//         isPromotionalStyle ? kWhiteColor : kGreyColor.withValues(alpha: 0.6);

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           maxLines: 1,
//           Service.capitalizeFirstLetters(storeName),
//           style: Theme.of(context).textTheme.labelLarge?.copyWith(
//               fontWeight: FontWeight.w900,
//               color: textColor,
//               overflow: TextOverflow.ellipsis),
//         ),
//         // store delivery type
//         Text(
//           Service.capitalizeFirstLetters(deliveryType),
//           style: TextStyle(
//             fontSize: 10,
//             color: kPrimaryColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         //store rating and distance
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             //store rating
//             Row(
//               spacing: 2,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Icon(
//                   Icons.star_rounded,
//                   color: Colors.amber,
//                   size: getProportionateScreenWidth(kDefaultPadding * 0.9),
//                 ),
//                 Text(
//                   "$rating ($ratingCount)",
//                   style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: iconColor,
//                       ),
//                 ),
//               ],
//             ),

//             ///dot separator
//             Container(
//               width: 5,
//               height: kDefaultPadding / 1.2,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: dotColor,
//               ),
//             ),

//             //store distance
//             Row(
//               spacing: 2,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Icon(
//                   Icons.social_distance_rounded,
//                   color: iconColor,
//                   size: getProportionateScreenWidth(kDefaultPadding * 0.9),
//                 ),
//                 Text(
//                   "$distance KM",
//                   style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: iconColor,
//                       ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   ///nearbay store card
//   Widget featuredStoresCard(BuildContext context) {
//     // final constants = Constants(context: context);

//     return Container(
//       width: getProportionateScreenWidth(kDefaultPadding * 12),
//       // width: isFeatured
//       //     ? getProportionateScreenWidth(kDefaultPadding * 12)
//       //     : MediaQuery.sizeOf(context).width * 1.0,
//       decoration: BoxDecoration(
//         color: kPrimaryColor,
//         border: Border.all(color: kWhiteColor),
//         borderRadius: BorderRadius.circular(kDefaultPadding),
//         boxShadow: [
//           BoxShadow(
//             color: kBlackColor.withValues(alpha: 0.08),
//             spreadRadius: 0,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(
//           getProportionateScreenWidth(kDefaultPadding / 2),
//         ),
//         child: Stack(
//           children: [
//             // Conditional full-size background image for promotional stores
//             if (isFeatured)
//               Positioned.fill(
//                 // width: double.infinity,
//                 // height: double.infinity,
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
//                       width: getProportionateScreenWidth(kDefaultPadding * 5),
//                       height: getProportionateScreenHeight(kDefaultPadding * 5),
//                       child: CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           Colors.transparent,
//                         ),
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

//             // Content column
//             Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Image container - standard for non-promotional, transparent for promotional
//                 Container(
//                   width: double.infinity,
//                   height: getProportionateScreenHeight(kDefaultPadding * 7),
//                   decoration: isFeatured
//                       ? null
//                       : BoxDecoration(
//                           color: kPrimaryColor,
//                           borderRadius: BorderRadius.only(
//                             topRight: Radius.circular(
//                                 getProportionateScreenWidth(
//                                     kDefaultPadding / 2)),
//                             topLeft: Radius.circular(
//                                 getProportionateScreenWidth(
//                                     kDefaultPadding / 2)),
//                           ),
//                         ),
//                   child: isFeatured
//                       ? null
//                       : ClipRRect(
//                           borderRadius: BorderRadius.only(
//                             topRight: Radius.circular(
//                                 getProportionateScreenWidth(
//                                     kDefaultPadding / 2)),
//                             topLeft: Radius.circular(
//                                 getProportionateScreenWidth(
//                                     kDefaultPadding / 2)),
//                           ),
//                           child: CachedNetworkImage(
//                             imageUrl: imageUrl,
//                             imageBuilder: (context, imageProvider) => Container(
//                               decoration: BoxDecoration(
//                                 image: DecorationImage(
//                                   fit: BoxFit.cover,
//                                   image: imageProvider,
//                                 ),
//                               ),
//                             ),
//                             placeholder: (context, url) => Center(
//                               child: Container(
//                                 width: getProportionateScreenWidth(
//                                     kDefaultPadding * 5),
//                                 height: getProportionateScreenHeight(
//                                     kDefaultPadding * 5),
//                                 child: CircularProgressIndicator(
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                     Colors.transparent,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             errorWidget: (context, url, error) => Container(
//                               decoration: BoxDecoration(
//                                 image: DecorationImage(
//                                   fit: BoxFit.cover,
//                                   image: AssetImage('images/trending.png'),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                 ),

//                 // Details section - with blurred background for promotional, regular for standard
//                 _buildPromotionalDetailsSection(context)

//                 // isFeatured
//                 //     ? _buildPromotionalDetailsSection(context)
//                 // : _buildStandardDetailsSection(context),
//               ],
//             ),

//             // Featured tag
//             // if (isFeatured)
//             Positioned(
//               right: -3,
//               top: -3,
//               child: Container(
//                 height: getProportionateScreenWidth(kDefaultPadding * 4),
//                 width: getProportionateScreenWidth(kDefaultPadding * 4),
//                 child: Center(
//                     child: Image.asset("images/store_tags/$featuredTag.png")),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

///nearby store card
// Widget nearbyStoresCard(BuildContext context) {
//   // final constants = Constants(context: context);

//   return Container(
//     width: MediaQuery.sizeOf(context).width * 0.9,
//     // width: double.infinity,
//     margin: EdgeInsets.only(
//         bottom: getProportionateScreenHeight(kDefaultPadding / 2)),
//     padding: EdgeInsets.symmetric(
//       horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
//       vertical: getProportionateScreenHeight(kDefaultPadding / 4),
//     ),
//     height: getProportionateScreenHeight(kDefaultPadding * 7),
//     decoration: BoxDecoration(
//       color: kPrimaryColor,
//       borderRadius: BorderRadius.circular(kDefaultPadding),
//       border: Border.all(width: 0.1, color: kWhiteColor),
//     ),
//     child: Row(
//       children: [
//         // Enhanced Image Section
//         Container(
//           height: double.maxFinite,
//           width: getProportionateScreenWidth(kDefaultPadding * 7),
//           margin:
//               EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding / 4)),
//           decoration: BoxDecoration(
//             color: kPrimaryColor,
//             border: Border(
//               bottom: BorderSide(width: 0.1, color: kWhiteColor),
//             ),
//             borderRadius: BorderRadius.circular(kDefaultPadding),
//             image: DecorationImage(
//               image: CachedNetworkImageProvider(imageUrl),
//               fit: BoxFit.cover,
//               onError: (exception, stackTrace) {
//                 Icon(
//                   Icons.broken_image,
//                   color: Colors.grey,
//                   size: 32,
//                 );
//               },
//             ),
//           ),
//         ),
//         // Enhanced Content Section with Flexible Width
//         Expanded(
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//                 horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
//                 vertical: getProportionateScreenHeight(kDefaultPadding / 2)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   Service.capitalizeFirstLetters(storeName),
//                   style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                         // color: kBlackColor,
//                       ),
//                   // style: constants.textTheme.bodyMedium?.copyWith(
//                   //   fontWeight: FontWeight.w700,
//                   //   letterSpacing: -0.2,
//                   // ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 Spacer(),
//                 // Rating Row
//                 if (rating.isNotEmpty && rating != "0.00")
//                   Padding(
//                     padding: EdgeInsets.only(
//                         top: getProportionateScreenHeight(kDefaultPadding / 2)),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.max,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Row(
//                             children: [
//                               Container(
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: kDefaultPadding / 4),
//                                 decoration: BoxDecoration(
//                                     color: Colors.amber.withValues(alpha: 0.2),
//                                     shape: BoxShape.circle),
//                                 child: Icon(
//                                   Icons.star_rounded,
//                                   color: Colors.amber[600],
//                                   size: 14,
//                                 ),
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 rating,
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .bodySmall
//                                     ?.copyWith(
//                                       fontWeight: FontWeight.w600,
//                                       color: kBlackColor,
//                                       fontSize: 12,
//                                     ),
//                               ),
//                               if (ratingCount.isNotEmpty &&
//                                   ratingCount != "0") ...[
//                                 SizedBox(width: 2),
//                                 Flexible(
//                                   child: Text(
//                                     '($ratingCount)',
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall
//                                         ?.copyWith(
//                                           fontWeight: FontWeight.w400,
//                                           color: Colors.grey[600],
//                                           fontSize: 11,
//                                         ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),
//                         // Spacer(),

//                         // Distance
//                         Flexible(
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 padding: EdgeInsets.all(kDefaultPadding / 4),
//                                 decoration: BoxDecoration(
//                                   color: kWhiteColor,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Icon(
//                                   Icons.location_on_rounded,
//                                   size: 12,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               // SizedBox(width: 4),
//                               Flexible(
//                                 child: Text(
//                                   "$distance km",
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodySmall
//                                       ?.copyWith(
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.grey[700],
//                                         fontSize: 11,
//                                       ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 SizedBox(
//                   height: kDefaultPadding / 2,
//                 ),
//                 // Delivery type and Status Row
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     // Delivery Type Chip
//                     deliveryTypeChip(deliveryType),
//                     // Store Status
//                     if (isStoreOpened != null) //isStoreOpened
//                       Flexible(
//                         child: OpenCloseStatusCard(
//                           isOpen: isStoreOpened!,
//                         ),
//                       ),
//                   ],
//                 ),
//                 // SizedBox(height: 4),
//               ],
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

/////old
// // // import 'package:cached_network_image/cached_network_image.dart';
// // // import 'package:flutter/material.dart';
// // // import 'dart:ui';
// // // import 'package:zmall/constants.dart';
// // // import 'package:zmall/size_config.dart';
// // // import 'package:zmall/service.dart';
// // // import 'package:zmall/widgets/open_close_status_card.dart';

// // // class StoresCard extends StatelessWidget {
// // //   const StoresCard({
// // //     Key? key,
// // //     required this.imageUrl,
// // //     required this.storeName,
// // //     required this.deliveryType,
// // //     required this.distance,
// // //     required this.press,
// // //     required this.rating,
// // //     required this.ratingCount,
// // //     this.featuredTag = "",
// // //     this.isFeatured = false,
// // //     this.isStoreOpened,
// // //   }) : super(key: key);

// // //   final String imageUrl;
// // //   final String storeName;
// // //   final String deliveryType;
// // //   final String distance, rating, ratingCount, featuredTag;
// // //   final GestureTapCallback press;
// // //   final bool isFeatured;
// // //   final bool? isStoreOpened;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return GestureDetector(
// // //       onTap: press,
// // //       child: Container(
// // //         // height: isFeatured
// // //         //     ? null
// // //         //     : getProportionateScreenHeight(kDefaultPadding * 10),
// // //         decoration: BoxDecoration(
// // //           color: Colors.white.withValues(alpha: 0.1),
// // //           gradient: LinearGradient(
// // //             begin: Alignment.topLeft,
// // //             end: Alignment.bottomRight,
// // //             colors: [
// // //               Colors.white.withValues(alpha: 0.2),
// // //               Colors.white.withValues(alpha: 0.05),
// // //             ],
// // //           ),
// // //           borderRadius: BorderRadius.circular(
// // //             getProportionateScreenWidth(kDefaultPadding),
// // //           ),
// // //           border: Border.all(
// // //             color: kWhiteColor,
// // //             // !isFeatured ? kWhiteColor : Colors.white.withValues(alpha: 0.5),
// // //             width: 1.5,
// // //           ),
// // //         ),
// // //         child: isFeatured
// // //             ? featuredStoresCard(context)
// // //             : nearbyStoresCard(context),
// // //       ),
// // //     );
// // //   }

// // //   Widget featuredStoresCard(BuildContext context) {
// // //     // final constants = Constants(context: context);
// // //     return Container(
// // //       height: getProportionateScreenHeight(kDefaultPadding * 12),
// // //       width: getProportionateScreenWidth(kDefaultPadding * 14),
// // //       decoration: BoxDecoration(
// // //         borderRadius: BorderRadius.circular(
// // //           getProportionateScreenWidth(kDefaultPadding),
// // //         ),
// // //       ),
// // //       child: ClipRRect(
// // //         borderRadius: BorderRadius.circular(
// // //           getProportionateScreenWidth(kDefaultPadding),
// // //         ),
// // //         child: Stack(
// // //           children: [
// // //             // Full background image - completely clear
// // //             Positioned.fill(
// // //               child: CachedNetworkImage(
// // //                 imageUrl: imageUrl,
// // //                 fit: BoxFit.cover,
// // //                 errorWidget: (context, url, error) => Container(
// // //                   color: kPrimaryColor.withValues(alpha: 0.3),
// // //                   child: Icon(Icons.store,
// // //                       color: kBlackColor.withValues(alpha: 0.7)),
// // //                 ),
// // //               ),
// // //             ),
// // //             // Blur overlay only at the bottom 30%
// // //             Positioned(
// // //               bottom: 0,
// // //               left: 0,
// // //               right: 0,
// // //               height: getProportionateScreenHeight(kDefaultPadding * 12) * 0.3,
// // //               child: ClipRRect(
// // //                 borderRadius: BorderRadius.only(
// // //                   bottomLeft: Radius.circular(
// // //                     getProportionateScreenWidth(kDefaultPadding),
// // //                   ),
// // //                   bottomRight: Radius.circular(
// // //                     getProportionateScreenWidth(kDefaultPadding),
// // //                   ),
// // //                 ),
// // //                 child: BackdropFilter(
// // //                   filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
// // //                   child: Container(
// // //                     decoration: BoxDecoration(
// // //                       gradient: LinearGradient(
// // //                         begin: Alignment.topCenter,
// // //                         end: Alignment.bottomCenter,
// // //                         colors: [
// // //                           Colors.transparent,
// // //                           Colors.black.withValues(alpha: 0.2),
// // //                           Colors.black.withValues(alpha: 0.4),
// // //                           Colors.black.withValues(alpha: 0.6),
// // //                         ],
// // //                         stops: [0.0, 0.3, 0.7, 1.0],
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //             // Glass effect container at bottom
// // //             Positioned(
// // //               bottom: 0,
// // //               left: 0,
// // //               right: 0,
// // //               child: Container(
// // //                 padding: EdgeInsets.symmetric(
// // //                   horizontal: getProportionateScreenWidth(kDefaultPadding),
// // //                   vertical: getProportionateScreenHeight(kDefaultPadding / 2),
// // //                 ),
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     begin: Alignment.topCenter,
// // //                     end: Alignment.bottomCenter,
// // //                     colors: [
// // //                       Colors.transparent,
// // //                       Colors.white.withValues(alpha: 0.1),
// // //                       Colors.white.withValues(alpha: 0.2),
// // //                     ],
// // //                   ),
// // //                   borderRadius: BorderRadius.only(
// // //                     bottomLeft: Radius.circular(
// // //                       getProportionateScreenWidth(kDefaultPadding),
// // //                     ),
// // //                     bottomRight: Radius.circular(
// // //                       getProportionateScreenWidth(kDefaultPadding),
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 child: Align(
// // //                   alignment: Alignment.bottomLeft,
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     mainAxisSize: MainAxisSize.min,
// // //                     children: [
// // //                       SizedBox(
// // //                           height:
// // //                               getProportionateScreenHeight(kDefaultPadding)),
// // //                       Container(
// // //                         padding:
// // //                             EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //                         decoration: BoxDecoration(
// // //                           color: Colors.black.withValues(alpha: 0.35),
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                         child: Text(
// // //                           Service.capitalizeFirstLetters(storeName),
// // //                           style:
// // //                               Theme.of(context).textTheme.labelLarge?.copyWith(
// // //                                     fontWeight: FontWeight.bold,
// // //                                     color: Colors.white,
// // //                                   ),
// // //                           maxLines: 1,
// // //                         ),
// // //                       ),
// // //                       SizedBox(
// // //                           height: getProportionateScreenHeight(
// // //                               kDefaultPadding / 5)),
// // //                       Row(
// // //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                         children: [
// // //                           // Rating Section with Glass Effect
// // //                           Container(
// // //                             padding: EdgeInsets.symmetric(
// // //                                 horizontal: 8, vertical: 4),
// // //                             decoration: BoxDecoration(
// // //                               color: Colors.black.withValues(alpha: 0.35),
// // //                               borderRadius: BorderRadius.circular(8),
// // //                             ),
// // //                             child: Row(
// // //                               mainAxisSize: MainAxisSize.min,
// // //                               children: [
// // //                                 Icon(
// // //                                   Icons.star_rounded,
// // //                                   color: Colors.amber,
// // //                                   size: getProportionateScreenWidth(
// // //                                       kDefaultPadding),
// // //                                 ),
// // //                                 SizedBox(width: 4),
// // //                                 Text(
// // //                                   "$rating ($ratingCount)",
// // //                                   style: Theme.of(context)
// // //                                       .textTheme
// // //                                       .labelSmall
// // //                                       ?.copyWith(
// // //                                         fontWeight: FontWeight.w500,
// // //                                         color: Colors.white,
// // //                                       ),
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                           ),

// // //                           // Delivery Type with Glass Effect
// // //                           Container(
// // //                             decoration: BoxDecoration(
// // //                               color: Colors.black.withValues(alpha: 0.35),
// // //                               borderRadius: BorderRadius.circular(12),
// // //                             ),
// // //                             padding: EdgeInsets.symmetric(
// // //                                 horizontal: 8, vertical: 4),
// // //                             child: Text(
// // //                               Service.capitalizeFirstLetters(deliveryType),
// // //                               style: TextStyle(
// // //                                 fontSize: 10,
// // //                                 color: Colors.white,
// // //                                 fontWeight: FontWeight.w600,
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //             // Featured Tag with Glass Effect
// // //             if (isFeatured)
// // //               Positioned(
// // //                 right: -2,
// // //                 top: -2,
// // //                 child: Container(
// // //                   height: getProportionateScreenWidth(kDefaultPadding * 4),
// // //                   width: getProportionateScreenWidth(kDefaultPadding * 4),
// // //                   decoration: BoxDecoration(
// // //                     // color: Colors.white.withValues(alpha: 0.2),
// // //                     borderRadius: BorderRadius.only(
// // //                       topLeft: Radius.circular(
// // //                         getProportionateScreenWidth(kDefaultPadding),
// // //                       ),
// // //                       bottomRight: Radius.circular(
// // //                         getProportionateScreenWidth(kDefaultPadding / 2),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   child: Center(
// // //                     child: Image.asset(
// // //                       "images/store_tags/$featuredTag.png",
// // //                       fit: BoxFit.contain,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget nearbyStoresCard(BuildContext context) {
// // //     // final constants = Constants(context: context);

// // //     return Container(
// // //       width: MediaQuery.sizeOf(context).width * 0.6,
// // //       height: getProportionateScreenHeight(kDefaultPadding * 7),
// // //       child: Row(
// // //         children: [
// // //           // Enhanced Image Section
// // //           Container(
// // //             height: double.maxFinite,
// // //             width: getProportionateScreenWidth(kDefaultPadding * 5),
// // //             margin: EdgeInsets.all(kDefaultPadding / 2),
// // //             decoration: BoxDecoration(
// // //               color: kPrimaryColor,
// // //               border: Border(
// // //                 bottom: BorderSide(width: 0.1, color: kGreyColor),
// // //               ),
// // //               borderRadius: BorderRadius.circular(kDefaultPadding),
// // //               image: DecorationImage(
// // //                 image: CachedNetworkImageProvider(imageUrl),
// // //                 fit: BoxFit.cover,
// // //                 onError: (exception, stackTrace) {
// // //                   Icon(
// // //                     Icons.broken_image,
// // //                     color: Colors.grey,
// // //                     size: 32,
// // //                   );
// // //                 },
// // //               ),
// // //             ),
// // //           ),
// // //           // Enhanced Content Section with Flexible Width
// // //           Expanded(
// // //             child: Padding(
// // //               padding: EdgeInsets.symmetric(
// // //                   horizontal: getProportionateScreenWidth(kDefaultPadding / 4),
// // //                   vertical: getProportionateScreenHeight(kDefaultPadding / 2)),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text(
// // //                     Service.capitalizeFirstLetters(storeName),
// // //                     style: Theme.of(context).textTheme.labelMedium?.copyWith(
// // //                           fontWeight: FontWeight.w700,
// // //                           // color: kBlackColor,
// // //                         ),
// // //                     // style: constants.textTheme.bodyMedium?.copyWith(
// // //                     //   fontWeight: FontWeight.w700,
// // //                     //   letterSpacing: -0.2,
// // //                     // ),
// // //                     maxLines: 2,
// // //                     overflow: TextOverflow.ellipsis,
// // //                   ),
// // //                   // Spacer(),
// // //                   // Rating Row
// // //                   if (rating.isNotEmpty && rating != "0.00")
// // //                     Row(
// // //                       children: [
// // //                         Container(
// // //                           padding: EdgeInsets.symmetric(
// // //                               horizontal: kDefaultPadding / 4),
// // //                           decoration: BoxDecoration(
// // //                               color: Colors.amber.withValues(alpha: 0.2),
// // //                               shape: BoxShape.circle),
// // //                           child: Icon(
// // //                             Icons.star_rounded,
// // //                             color: Colors.amber[600],
// // //                             size: 14,
// // //                           ),
// // //                         ),
// // //                         SizedBox(width: 4),
// // //                         Text(
// // //                           rating,
// // //                           style:
// // //                               Theme.of(context).textTheme.bodySmall?.copyWith(
// // //                                     fontWeight: FontWeight.w600,
// // //                                     color: kBlackColor,
// // //                                     fontSize: 12,
// // //                                   ),
// // //                         ),
// // //                         if (ratingCount.isNotEmpty && ratingCount != "0") ...[
// // //                           SizedBox(width: 2),
// // //                           Flexible(
// // //                             child: Text(
// // //                               '($ratingCount)',
// // //                               style: Theme.of(context)
// // //                                   .textTheme
// // //                                   .bodySmall
// // //                                   ?.copyWith(
// // //                                     fontWeight: FontWeight.w400,
// // //                                     color: Colors.grey[600],
// // //                                     fontSize: 11,
// // //                                   ),
// // //                               overflow: TextOverflow.ellipsis,
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ],
// // //                     ),

// // //                   // Distance
// // //                   Row(
// // //                     mainAxisSize: MainAxisSize.min,
// // //                     children: [
// // //                       Container(
// // //                         padding: EdgeInsets.all(kDefaultPadding / 4),
// // //                         decoration: BoxDecoration(
// // //                           color: kWhiteColor,
// // //                           shape: BoxShape.circle,
// // //                         ),
// // //                         child: Icon(
// // //                           Icons.location_on_rounded,
// // //                           size: 12,
// // //                           color: Colors.grey[600],
// // //                         ),
// // //                       ),
// // //                       // SizedBox(width: 4),
// // //                       Flexible(
// // //                         child: Text(
// // //                           "$distance km",
// // //                           style:
// // //                               Theme.of(context).textTheme.bodySmall?.copyWith(
// // //                                     fontWeight: FontWeight.w500,
// // //                                     color: Colors.grey[700],
// // //                                     fontSize: 11,
// // //                                   ),
// // //                           overflow: TextOverflow.ellipsis,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   // Delivery Type Chip
// // //                   deliveryTypeChip(deliveryType),
// // //                   // Delivery type and Status Row
// // //                   if (isStoreOpened != null)
// // //                     Flexible(
// // //                       child: OpenCloseStatusCard(
// // //                         isOpen: isStoreOpened!,
// // //                       ),
// // //                     ),
// // //                 ],
// // //               ),
// // //             ),
// // //           )
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   //   // Delivery Type Chip
// // //   Widget deliveryTypeChip(String deliveryType) {
// // //     return Container(
// // //       padding: EdgeInsets.symmetric(
// // //         horizontal: 10,
// // //         vertical: 4,
// // //       ),
// // //       decoration: BoxDecoration(
// // //         color: kSecondaryColor.withValues(alpha: 0.1),
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(
// // //           color: kSecondaryColor.withValues(alpha: 0.2),
// // //           width: 0.5,
// // //         ),
// // //       ),
// // //       child: Text(
// // //         Service.capitalizeFirstLetters(deliveryType),
// // //         style: TextStyle(
// // //           fontSize: 10,
// // //           color: kSecondaryColor,
// // //           fontWeight: FontWeight.w600,
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   // Glass Delivery Type Chip
// // //   Widget glassDeliveryTypeChip(String deliveryType) {
// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         color: kSecondaryColor.withValues(alpha: 0.1),
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             kSecondaryColor.withValues(alpha: 0.15),
// // //             kSecondaryColor.withValues(alpha: 0.05),
// // //           ],
// // //         ),
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(
// // //           color: kSecondaryColor.withValues(alpha: 0.3),
// // //           width: 1,
// // //         ),
// // //       ),
// // //       child: Padding(
// // //         padding: EdgeInsets.symmetric(
// // //           horizontal: 8,
// // //           vertical: 4,
// // //         ),
// // //         child: Text(
// // //           Service.capitalizeFirstLetters(deliveryType),
// // //           style: TextStyle(
// // //             fontSize: 10,
// // //             color: kSecondaryColor,
// // //             fontWeight: FontWeight.w600,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
