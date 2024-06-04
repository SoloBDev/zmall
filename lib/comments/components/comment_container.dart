import 'package:flutter/material.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';

import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CommentContainer extends StatelessWidget {
  const CommentContainer({
    Key? key,
    required this.comment,
    required this.userName,
    required this.dateTime,
    required this.rating,
    required this.press,
  }) : super(key: key);

  final String userName, comment, dateTime;
  final double rating;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
            vertical: getProportionateScreenHeight(kDefaultPadding / 10)),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SmoothStarRating(
                    allowHalfRating: false,
                    starCount: 5,
                    rating: rating,
                    onRatingChanged: (value) {},
                    size: getProportionateScreenWidth(kDefaultPadding / 1.5),
                    color: kSecondaryColor,
                    borderColor: kWhiteColor,
                    spacing: 0.0,
                  ),
                ],
              ),
              Text(
                "${dateTime.split('T')[0]} ${int.parse(dateTime.split('T')[1].split('.')[0].split(':')[0]) + 3}:${dateTime.split('T')[1].split('.')[0].split(':')[1]}:${dateTime.split('T')[1].split('.')[0].split(':')[2]}",
                style: Theme.of(context).textTheme.caption?.copyWith(
                      color: kGreyColor,
                    ),
              ),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 5)),
              Text(comment, style: Theme.of(context).textTheme.bodyText1),
            ],
          ),
        ),
      ),
    );
  }
}
