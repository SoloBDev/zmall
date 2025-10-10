import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class StoreHeader extends StatelessWidget {
  const StoreHeader({
    super.key,
    this.storeName,
    this.imageUrl,
    this.distance,
    this.rating,
    this.ratingCount,
  });

  final String? storeName, imageUrl, distance, rating, ratingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            HeroiconsSolid.star,
            color: Colors.orange,
            size: getProportionateScreenWidth(kDefaultPadding * 0.8),
          ),
          SmoothStarRating(
            rating: double.parse("$rating"),
            size: getProportionateScreenWidth(kDefaultPadding * 0.6),
            starCount: 5,
            color: Colors.orange,
            borderColor: Colors.orange,
          ),
          Text(
            "($ratingCount)",
            style: Theme.of(context)
                .textTheme
                .labelSmall!
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
