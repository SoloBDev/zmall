import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CommentContainer extends StatelessWidget {
  const CommentContainer({
    super.key,
    required this.comment,
    required this.userName,
    required this.dateTime,
    required this.rating,
    required this.press,
  });

  final String userName, comment, dateTime;
  final double rating;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    // Parse and format the dateTime using intl
    DateTime parsedDateTime;
    try {
      parsedDateTime = DateTime.parse(dateTime).toUtc().add(Duration(hours: 3));
    } catch (e) {
      parsedDateTime = DateTime.now();
    }
    final formattedDateTime =
        DateFormat('MMM d, yyyy HH:mm').format(parsedDateTime);
    // DateFormat('yyyy-MM-dd HH:mm').format(parsedDateTime);
    //

    return GestureDetector(
      onTap: press,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(1.0), // Default scale
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            vertical: getProportionateScreenHeight(kDefaultPadding / 4),
            horizontal: getProportionateScreenWidth(kDefaultPadding / 8),
          ),
          // padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            border: Border.all(color: kWhiteColor),
            borderRadius: BorderRadius.circular(
                getProportionateScreenWidth(kDefaultPadding)),
          ),
          child: ListTile(
            // mainAxisSize: MainAxisSize.min,
            // crossAxisAlignment: CrossAxisAlignment.start,
            leading: CircleAvatar(
              radius: getProportionateScreenWidth(kDefaultPadding),
              backgroundColor: kWhiteColor,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kBlackColor,
                      fontWeight: FontWeight.normal,
                    ),
              ),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: getProportionateScreenHeight(kDefaultPadding / 8),
              children: [
                Text(
                  userName.isNotEmpty ? userName : 'Anonymous',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                      ),
                ),
                Text(
                  formattedDateTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kGreyColor,
                      ),
                ),
                // SmoothStarRating(
                //   allowHalfRating: false,
                //   starCount: 5,
                //   rating: rating,
                //   onRatingChanged: (value) {}, // Read-only rating
                //   size: getProportionateScreenWidth(kDefaultPadding / 1.2),
                //   color: kSecondaryColor,
                //   borderColor: kGreyColor,
                //   spacing: 2.0,
                // ),
              ],
            ),

            subtitle: Text(
              comment.isNotEmpty ? comment : 'No comment provided',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: kBlackColor,
                    height: 1.4, // Improved line spacing
                  ),
            ),
            trailing: Container(
              width: getProportionateScreenWidth(kDefaultFontSize * 3),
              child: Row(
                children: [
                  Icon(
                    HeroiconsSolid.star,
                    color: Colors.orange,
                    size: getProportionateScreenWidth(kDefaultPadding * 0.8),
                  ),
                  Text(
                    rating.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kBlackColor,
                          height: 1.4, // Improved line spacing
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';

// import 'package:zmall/constants.dart';
// import 'package:zmall/size_config.dart';

// class CommentContainer extends StatelessWidget {
//   const CommentContainer({
//     super.key,
//     required this.comment,
//     required this.userName,
//     required this.dateTime,
//     required this.rating,
//     required this.press,
//   });

//   final String userName, comment, dateTime;
//   final double rating;
//   final GestureTapCallback press;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: press,
//       child: Container(
//         width: double.infinity,
//         margin: EdgeInsets.symmetric(
//             vertical: getProportionateScreenHeight(kDefaultPadding / 10)),
//         decoration: BoxDecoration(
//           color: kWhiteColor,
//           borderRadius: BorderRadius.circular(
//             getProportionateScreenWidth(kDefaultPadding),
//           ),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(kDefaultPadding),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     userName,
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                   SmoothStarRating(
//                     allowHalfRating: false,
//                     starCount: 5,
//                     rating: rating,
//                     onRatingChanged: (value) {},
//                     size: getProportionateScreenWidth(kDefaultPadding / 1.5),
//                     color: kSecondaryColor,
//                     borderColor: kWhiteColor,
//                     spacing: 0.0,
//                   ),
//                 ],
//               ),
//               Text(
//                 "${dateTime.split('T')[0]} ${int.parse(dateTime.split('T')[1].split('.')[0].split(':')[0]) + 3}:${dateTime.split('T')[1].split('.')[0].split(':')[1]}:${dateTime.split('T')[1].split('.')[0].split(':')[2]}",
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: kGreyColor,
//                     ),
//               ),
//               SizedBox(
//                   height: getProportionateScreenHeight(kDefaultPadding / 5)),
//               Text(comment,
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyLarge!
//                       .copyWith(color: kBlackColor)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
