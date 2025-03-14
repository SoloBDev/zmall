import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';

import 'package:zmall/constants.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/size_config.dart';

class StoreInfo extends StatelessWidget {
  const StoreInfo({
    Key? key,
    @required this.store,
    @required this.isOpen,
    this.isAbroad = false,
  }) : super(key: key);

  final store;
  final bool? isOpen;
  final bool isAbroad;

  @override
  Widget build(BuildContext context) {
    double rating = double.parse(store['user_rate'].toStringAsFixed(2));
    List ratingVal = ["☆", "☆", "☆", "☆", "☆"];
    for (int i = 0; i < int.parse(rating.ceil().toString()); i++) {
      ratingVal[i] = '★';
    }
    String parsedRVAl = ratingVal.join("");
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store['name'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: kBlackColor,
                ),
            softWrap: true,
          ),
          Text(
            parsedRVAl,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: kSecondaryColor,
                  fontSize: getProportionateScreenWidth(kDefaultPadding * .7),
                ),
          ),
          isAbroad
              ? Text(
                  'Addis Ababa, Ethiopia',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: kGreyColor),
                )
              : store['distance'] != null
                  ? Text(
                      "${store['distance'].toStringAsFixed(2)} ${Provider.of<ZLanguage>(context).kmAway}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kGreyColor,
                          ),
                    )
                  : Container(),
//          Row(
//            children: [
//              Icon(
//                Icons.star,
//                color: kSecondaryColor,
//                size: getProportionateScreenWidth(kDefaultPadding / 1.5),
//              ),
//              Text(
//                " ${store['user_rate'].toStringAsFixed(2)} (${store['user_rate_count']})",
//                style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                      color: kGreyColor,
//                    ),
//              )
//            ],
//          ),
//           SmoothStarRating(
//             // rating: double.parse(store['user_rate'].toStringAsFixed(2)),
//             rating: rating,
//             isReadOnly: true,
//             size: getProportionateScreenWidth(kDefaultPadding * .7),
//             starCount: 5,
//             color: kSecondaryColor,
//             borderColor: kSecondaryColor,
//           ),

          Text(
            store['is_store_busy']
                ? Provider.of<ZLanguage>(context).busy
                : isOpen!
                    ? Provider.of<ZLanguage>(context).open
                    : Provider.of<ZLanguage>(context).closed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: store['is_store_busy']
                    ? kYellowColor
                    : isOpen!
                        ? Colors.green
                        : kSecondaryColor),
          )
        ],
      ),
    );
  }
}

class FavoriteStoreInfo extends StatelessWidget {
  const FavoriteStoreInfo({
    Key? key,
    @required this.store,
    @required this.isOpen,
    this.isAbroad = false,
  }) : super(key: key);

  final store;
  final bool? isOpen;
  final bool isAbroad;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            store['name'],
            style: TextStyle(
              fontSize: getProportionateScreenWidth(kDefaultPadding / 1.5),
              fontWeight: FontWeight.w600,
              color: kBlackColor,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          isAbroad
              ? Text(
                  'Addis Ababa, Ethiopia',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: kGreyColor),
                )
              : store['distance'] != null
                  ? Text(
                      "${store['distance'].toStringAsFixed(2)} ${Provider.of<ZLanguage>(context).kmAway}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: kGreyColor,
                          ),
                    )
                  : Container(),
//          Row(
//            children: [
//              Icon(
//                Icons.star,
//                color: kSecondaryColor,
//                size: getProportionateScreenWidth(kDefaultPadding / 1.5),
//              ),
//              Text(
//                " ${store['user_rate'].toStringAsFixed(2)} (${store['user_rate_count']})",
//                style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                      color: kGreyColor,
//                    ),
//              )
//            ],
//          ),
          SmoothStarRating(
            rating: double.parse(store['user_rate'].toStringAsFixed(2)),
            size: getProportionateScreenWidth(kDefaultPadding * .7),
            color: Colors.amber,
            borderColor: kSecondaryColor,
          ),
          Text(
            store['is_store_busy']
                ? Provider.of<ZLanguage>(context).busy
                : isOpen!
                    ? Provider.of<ZLanguage>(context).open
                    : Provider.of<ZLanguage>(context).closed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: store['is_store_busy']
                    ? kYellowColor
                    : isOpen!
                        ? Colors.green
                        : kSecondaryColor),
          )
        ],
      ),
    );
  }
}
