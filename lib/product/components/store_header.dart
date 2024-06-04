import 'package:flutter/material.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class StoreHeader extends StatelessWidget {
  const StoreHeader({
    Key? key,
    this.storeName,
    this.imageUrl,
    this.distance,
    this.rating,
    this.ratingCount,
  }) : super(key: key);

  final String? storeName, imageUrl, distance, rating, ratingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
//      padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        // borderRadius: BorderRadius.only(
        //   bottomLeft: Radius.circular(kDefaultPadding * .8),
        //   bottomRight: Radius.circular(kDefaultPadding * .8),
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ImageContainer(
          //   url: imageUrl,
          // ),
          // SizedBox(height: kDefaultPadding / 4),
          // Text(
          //   storeName.length > 30 ? storeName.split("(")[0] : storeName,
          //   style: TextStyle(fontWeight: FontWeight.bold),
          // ),
          // SizedBox(height: kDefaultPadding / 4),
          // Text("${distance}km away"),
          // SizedBox(height: kDefaultPadding / 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmoothStarRating(
                rating: double.parse("$rating"),
                size: getProportionateScreenWidth(kDefaultPadding * .7),
                starCount: 5,
                color: kSecondaryColor,
                borderColor: kSecondaryColor,
              ),
              Text("($ratingCount)"),
            ],
          ),
          SizedBox(height: kDefaultPadding / 4),
        ],
      ),
    );
  }
}
