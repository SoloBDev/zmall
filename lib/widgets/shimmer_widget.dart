import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

Color baseColor = Colors.grey[300]!; // Color(0xff3a3a3a);
Color highlightColor = Colors.grey[100]!; // Color(0xff4a4a4a);

class ItemTagShimmer extends StatelessWidget {
  const ItemTagShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 5,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1000),
          child: Container(
            height: getProportionateScreenHeight(kDefaultPadding * 2),
            width: getProportionateScreenWidth(kDefaultPadding * 5),
            margin: EdgeInsets.symmetric(
              vertical: getProportionateScreenHeight(kDefaultPadding / 2),
              horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}

// class ProductListShimmer extends StatelessWidget {
//   const ProductListShimmer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       shrinkWrap: true,
//       itemCount: 6,
//       scrollDirection: Axis.vertical,
//       itemBuilder: (context, index) {
//         return Shimmer.fromColors(
//           baseColor: baseColor,
//           highlightColor: highlightColor,
//           period: const Duration(milliseconds: 1000),
//           child: Container(
//             height: getProportionateScreenHeight(kDefaultPadding * 6),
//             width: double.infinity,
//             margin: EdgeInsets.symmetric(
//               vertical: getProportionateScreenHeight(kDefaultPadding / 2),
//               horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
//             ),
//             child: Row(
//               children: [
//                 // Image Placeholder
//                 Container(
//                   height: getProportionateScreenHeight(kDefaultPadding * 4),
//                   width: getProportionateScreenWidth(kDefaultPadding * 4),
//                   decoration: BoxDecoration(
//                     color: kPrimaryColor,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 SizedBox(width: getProportionateScreenHeight(kDefaultPadding)),
//                 // Product Details Placeholder
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Title Placeholder
//                       Container(
//                         width: getProportionateScreenWidth(kDefaultPadding * 4),
//                         height: getProportionateScreenHeight(kDefaultPadding),
//                         decoration: BoxDecoration(
//                           color: kPrimaryColor,
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       SizedBox(
//                           height: getProportionateScreenHeight(
//                               kDefaultPadding / 2)),
//                       // Description Placeholder (Line 1)
//                       Container(
//                         width: getProportionateScreenWidth(kDefaultPadding * 6),
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding * 0.8),
//                         decoration: BoxDecoration(
//                           color: kPrimaryColor,
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       SizedBox(
//                           height: getProportionateScreenHeight(
//                               kDefaultPadding / 2)),
//                       // Description Placeholder (Line 2)
//                       Container(
//                         width: getProportionateScreenWidth(kDefaultPadding * 3),
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding * 0.8),
//                         decoration: BoxDecoration(
//                           color: kPrimaryColor,
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       SizedBox(
//                           height: getProportionateScreenHeight(
//                               kDefaultPadding / 2)),
//                       // Price and Button Placeholder
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               height:
//                                   getProportionateScreenHeight(kDefaultPadding),
//                               decoration: BoxDecoration(
//                                 color: kPrimaryColor,
//                                 borderRadius: BorderRadius.circular(5),
//                               ),
//                             ),
//                           ),
//                           SizedBox(
//                               width: getProportionateScreenHeight(
//                                   kDefaultPadding)),
//                           Expanded(
//                             child: Container(
//                               height:
//                                   getProportionateScreenHeight(kDefaultPadding),
//                               decoration: BoxDecoration(
//                                 color: kPrimaryColor,
//                                 borderRadius: BorderRadius.circular(5),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
class ProductListShimmer extends StatelessWidget {
  const ProductListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 6,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, index) {
        return Container(
          height: getProportionateScreenHeight(kDefaultPadding * 6),
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: getProportionateScreenHeight(kDefaultPadding / 2),
            left: getProportionateScreenWidth(kDefaultPadding / 2),
            right: getProportionateScreenWidth(kDefaultPadding / 2),
          ),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            period: const Duration(milliseconds: 1000),
            child: Row(
              children: [
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding * 4),
                  width: getProportionateScreenWidth(kDefaultPadding * 4),
                  decoration: BoxDecoration(
                    color: Colors.white, // Changed from kPrimaryColor
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(width: getProportionateScreenHeight(kDefaultPadding)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: getProportionateScreenHeight(kDefaultPadding / 2),
                  children: [
                    Container(
                      width: getProportionateScreenWidth(kDefaultPadding * 4),
                      height: getProportionateScreenHeight(kDefaultPadding),
                      decoration: BoxDecoration(
                        color: Colors.white, // Changed from kPrimaryColor
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      width: getProportionateScreenWidth(kDefaultPadding * 6),
                      height:
                          getProportionateScreenHeight(kDefaultPadding * 0.8),
                      decoration: BoxDecoration(
                        color: Colors.white, // Changed from kPrimaryColor
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      width: getProportionateScreenWidth(kDefaultPadding * 3),
                      height:
                          getProportionateScreenHeight(kDefaultPadding * 0.8),
                      decoration: BoxDecoration(
                        color: Colors.white, // Changed from kPrimaryColor
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: SizeConfig.screenWidth! * 0.35,
                          height: getProportionateScreenHeight(kDefaultPadding),
                          decoration: BoxDecoration(
                            color: Colors.white, // Changed from kPrimaryColor
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        SizedBox(
                            width:
                                getProportionateScreenHeight(kDefaultPadding)),
                        Container(
                          width: SizeConfig.screenWidth! * 0.35,
                          height: getProportionateScreenHeight(kDefaultPadding),
                          decoration: BoxDecoration(
                            color: Colors.white, // Changed from kPrimaryColor
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ImageShimmerWidget extends StatelessWidget {
  final double? width;
  final double? height;

  const ImageShimmerWidget({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1000),
      child: Container(
        height: height ?? 80,
        width: width ?? 60,
        decoration: BoxDecoration(
          color: kPrimaryColor,
          // borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class SearchButtonShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const SearchButtonShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1000),
      child: Container(
        width: width ?? getProportionateScreenWidth(kDefaultPadding * 10),
        height: height ?? getProportionateScreenHeight(kDefaultPadding * 2.4),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius:
              BorderRadius.circular(borderRadius ?? kDefaultPadding * 2),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding),
            vertical: getProportionateScreenHeight(kDefaultPadding / 5)),
      ),
    );
  }
}

class StoreHeaderShimmer extends StatelessWidget {
  final bool? isCart;
  const StoreHeaderShimmer({super.key, this.isCart});

  @override
  Widget build(BuildContext context) {
    bool isInCart = isCart != null && isCart == true ? true : false;
    double screenWidth = MediaQuery.of(context).size.width;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1000),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
            horizontal: getProportionateScreenHeight(kDefaultPadding / 2)),
        padding: isInCart
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                vertical: getProportionateScreenHeight(kDefaultPadding / 2),
                horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
              ),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          spacing: getProportionateScreenHeight(kDefaultPadding),
          children: [
            Row(
              spacing: getProportionateScreenHeight(kDefaultPadding),
              children: [
                // Image Placeholder (Circular)
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding * 4),
                  width: getProportionateScreenWidth(kDefaultPadding * 4),
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                ),

                // Store Details Placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: getProportionateScreenHeight(kDefaultPadding / 2),
                    children: [
                      // Title Placeholder
                      Container(
                        width: getProportionateScreenWidth(kDefaultPadding * 4),
                        height: getProportionateScreenHeight(kDefaultPadding),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),

                      // Description Placeholder
                      Container(
                        width: getProportionateScreenWidth(kDefaultPadding * 6),
                        height: getProportionateScreenHeight(
                            kDefaultPadding * 0.75),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
                isInCart
                    ? SearchButtonShimmer(
                        width: 60,
                        height: 30,
                        borderRadius: 5,
                      )
                    : SizedBox.shrink()
              ],
            ),

            // Search Button Placeholder
            isInCart
                ? SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding / 2)),
                    child: SearchButtonShimmer(width: screenWidth * 0.8),
                  ),

            // Categories Placeholder
            isInCart
                ? SizedBox.shrink()
                : Container(
                    height: getProportionateScreenHeight(kDefaultPadding * 2),
                    child: ProductCategoryShimmerWidget(),
                  ),
          ],
        ),
      ),
    );
  }
}

class ProductCategoryShimmerWidget extends StatelessWidget {
  final double? width;
  final double? height;
  const ProductCategoryShimmerWidget({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 5,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1000),
          child: Container(
            height: height ?? 60,
            width: width ?? 80,
            margin: EdgeInsets.symmetric(
              vertical: getProportionateScreenHeight(kDefaultPadding / 2),
              horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      },
    );
  }
}

class KifiyaMethodesShimmer extends StatelessWidget {
  final bool? isService;
  const KifiyaMethodesShimmer({super.key, this.isService});

  @override
  Widget build(BuildContext context) {
    bool isServiceScreen = isService != null && isService == true;
    return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1000),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.7,
              child: GridView.builder(
                padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding / 1.5)),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height:
                              getProportionateScreenHeight(kDefaultPadding * 4),
                          width:
                              getProportionateScreenWidth(kDefaultPadding * 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300], // Placeholder color
                            borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(kDefaultPadding)),
                          ),
                        ),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 1.5)),
                        Container(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 1.5),
                          width:
                              getProportionateScreenWidth(kDefaultPadding * 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300], // Placeholder color
                            borderRadius: BorderRadius.circular(
                                getProportionateScreenHeight(kDefaultPadding)),
                          ),
                        ),
                      ]);
                },
              ),
            ),
            // SizedBox(
            //     height: getProportionateScreenHeight(
            //         isServiceScreen ? 0 : kDefaultPadding)),
            // if (!isServiceScreen)
            //   Container(
            //     height: getProportionateScreenHeight(kDefaultPadding * 4),
            //     width: double.infinity,
            //     margin: EdgeInsets.symmetric(
            //         horizontal: getProportionateScreenWidth(kDefaultPadding)),
            //     decoration: BoxDecoration(
            //       color: Colors.grey[300], // Placeholder color
            //       borderRadius: BorderRadius.circular(
            //           getProportionateScreenWidth(kDefaultPadding)),
            //     ),
            //   ),
          ],
        ));
  }
}
