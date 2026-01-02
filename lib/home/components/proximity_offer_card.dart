import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';

class ProximityOfferCard extends StatelessWidget {
  const ProximityOfferCard({
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
    required this.distance,
    required this.maxDistance,
    required this.minDistance, // Add minimum distance (from the first/closest item)
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
  final double distance; // Distance in km
  final double maxDistance; // Maximum distance in the list (for normalization)
  final double minDistance; // Minimum distance (closest item)
  final bool? isOpen;

  /// Calculate opacity based on distance
  /// First item (closest/minDistance) = 1.0 (no opacity change)
  /// Items get progressively more transparent based on distance
  double _getOpacity() {
    if (maxDistance == minDistance)
      return 1.0; // Only one item or all same distance

    // Normalize distance relative to the range (minDistance to maxDistance)
    // This ensures the first item gets 0.0 and the last item gets 1.0
    double normalized = (distance - minDistance) / (maxDistance - minDistance);

    // First item stays at 1.0, others fade progressively
    // Map to opacity range: closest = 1.0, farthest = 0.5
    return 1.0 - (normalized * 0.5);
  }

  /// Calculate saturation based on distance
  /// First item (closest/minDistance) = 1.0 (full color, no desaturation)
  /// Items get progressively more desaturated (grayed out) based on distance
  // double _getSaturation() {
  //   if (maxDistance == minDistance)
  //     return 1.0; // Only one item or all same distance

  //   // Normalize distance relative to the range (minDistance to maxDistance)
  //   double normalized = (distance - minDistance) / (maxDistance - minDistance);

  //   // First item stays at 1.0 (full color), others desaturate progressively
  //   // Map to saturation range: closest = 1.0, farthest = 0.4
  //   return 1.0 - (normalized * 0.6);
  // }

  /// Get border color based on distance
  Color _getBorderColor() {
    if (maxDistance == minDistance) return kBlackColor.withValues(alpha: 0.09);

    double normalized = (distance - minDistance) / (maxDistance - minDistance);

    // Closest items: darker border, Farthest: lighter border
    if (normalized < 0.33) {
      return kBlackColor.withValues(alpha: 0.09);
    } else if (normalized < 0.66) {
      return kBlackColor.withValues(alpha: 0.07);
    } else {
      return kBlackColor.withValues(alpha: 0.06);
    }
  }

  /// Get badge color based on distance
  // Color _getDistanceBadgeColor() {
  //   return kSecondaryColor;
  // if (maxDistance == 0) return kSecondaryColor;

  // double normalized = distance / maxDistance;

  // // Closest: Green-ish, Medium: Orange-ish, Far: Red-ish
  // if (normalized < 0.33) {
  //   return Colors.green;
  // } else if (normalized < 0.66) {
  //   return Colors.orange;
  // } else {
  //   return Colors.red.shade400;
  // }
  // }

  /// Calculate scale based on distance
  /// First item (closest/minDistance) = 1.0 (full size)
  /// Items get progressively smaller based on distance
  // double _getScale() {
  //   if (maxDistance == minDistance)
  //     return 1.0; // Only one item or all same distance

  //   // Normalize distance relative to the range (minDistance to maxDistance)
  //   double normalized = (distance - minDistance) / (maxDistance - minDistance);

  //   // First item stays at 1.0 (full size), others shrink progressively
  //   // Scale range: closest = 1.0, farthest = 0.85 (15% smaller)
  //   return 1.0 - (normalized * 0.05);
  // }

  @override
  Widget build(BuildContext context) {
    final opacity = _getOpacity();
    // final saturation = _getSaturation();
    final borderColor = _getBorderColor();
    final badgeColor = kSecondaryColor; //_getDistanceBadgeColor();
    // final scale = _getScale();

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: press,
        child: Container(
          width: getProportionateScreenWidth(kDefaultPadding * 8),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            border: Border.all(color: borderColor),

            // Border.all(color: kBlackColor.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            boxShadow: opacity > 0.7
                ? [
                    BoxShadow(
                      color: kSecondaryColor.withValues(alpha: 0.1 * opacity),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
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
                        height: getProportionateScreenHeight(
                          kDefaultPadding * 6.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
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
                                kDefaultPadding * 3.5,
                              ),
                              height: getProportionateScreenHeight(
                                kDefaultPadding * 3.5,
                              ),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kSecondaryColor,
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
                        left: getProportionateScreenWidth(kDefaultPadding / 3),
                        right: getProportionateScreenWidth(kDefaultPadding / 3),
                        bottom: getProportionateScreenHeight(
                          kDefaultPadding / 4,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Service.capitalizeFirstLetters(itemName),
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
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
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: kGreyColor,
                                        fontWeight: FontWeight.w100,
                                        decorationColor: kGreyColor,
                                        overflow: TextOverflow.ellipsis,
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: getProportionateScreenWidth(
                                          9,
                                        ),
                                      ),
                                ),
                              Flexible(
                                child: Text(
                                  "${newPrice}${Provider.of<ZMetaData>(context, listen: false).currency}",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: kBlackColor,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: getProportionateScreenWidth(
                                          11,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                kDefaultPadding,
                              ),
                            ),
                            child: InkWell(
                              onTap: storePress,
                              child: Text(
                                Service.capitalizeFirstLetters(storeName),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kGreyColor,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Distance Badge (Top Left)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(
                        kDefaultPadding / 2.5,
                      ),
                      vertical: getProportionateScreenHeight(
                        kDefaultPadding / 4,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(kDefaultPadding / 1.5),
                        topLeft: Radius.circular(kDefaultPadding / 2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kBlackColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          HeroiconsOutline.mapPin,
                          size: 12,
                          color: kPrimaryColor,
                        ),
                        SizedBox(width: 3),
                        Text(
                          "${distance.toStringAsFixed(1)}km",
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: getProportionateScreenWidth(9),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Discount Badge (Top Right)
                if (isDiscounted || specialOffer.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        left: getProportionateScreenWidth(kDefaultPadding / 6),
                        bottom: getProportionateScreenHeight(
                          kDefaultPadding / 6,
                        ),
                      ),
                      height: getProportionateScreenHeight(
                        kDefaultPadding * 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(kDefaultPadding / 1.2),
                          topRight: Radius.circular(kDefaultPadding / 1.2),
                        ),
                      ),
                      child: Container(
                        height: getProportionateScreenHeight(kDefaultPadding),
                        padding: EdgeInsets.only(
                          left: getProportionateScreenWidth(
                            kDefaultPadding / 6,
                          ),
                          right: getProportionateScreenWidth(
                            kDefaultPadding / 4,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: kSecondaryColor,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(kDefaultPadding / 1.6),
                            topRight: Radius.circular(kDefaultPadding / 2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            specialOffer.isNotEmpty
                                ? specialOffer
                                : "${(100.00 - (double.parse(newPrice) / double.parse(originalPrice) * 100)).toStringAsFixed(0)}% Off",
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: getProportionateScreenWidth(
                                    kDefaultPadding / 1.6,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Store closed overlay
                if (isOpen != null && !isOpen!)
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
                            kDefaultPadding / 1.2,
                          ),
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
      ),
    );
  }
}
  //  colorFilter: ColorFilter.matrix([
  //           saturation,
  //           0,
  //           0,
  //           0,
  //           0,
  //           0,
  //           saturation,
  //           0,
  //           0,
  //           0,
  //           0,
  //           0,
  //           saturation,
  //           0,
  //           0,
  //           0,
  //           0,
  //           0,
  //           1,
  //           0,
  //         ]),