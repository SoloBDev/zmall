import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/size_config.dart';

class CustomSearchBar extends StatelessWidget {
  final String? hintText;
  final double? horizontalMarigin;
  final double? verticallMarigin;
  final bool? showFilterButton;
  final void Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final void Function()? onClearButtonTap;
  final void Function()? onFilterButtonTap;
  final TextEditingController controller;
  const CustomSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClearButtonTap,
    this.onFilterButtonTap,
    required this.controller,
    this.horizontalMarigin,
    this.verticallMarigin,
    this.showFilterButton,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal:
            horizontalMarigin ?? getProportionateScreenWidth(kDefaultPadding),
        vertical: verticallMarigin ??
            getProportionateScreenWidth(kDefaultPadding / 2),
      ),
      child: SearchBar(
        controller: controller,
        hintText: hintText ?? Provider.of<ZLanguage>(context).search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,

        // Enhanced Background Color with State Management
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return kPrimaryColor;
          }
          if (states.contains(WidgetState.hovered)) {
            return kPrimaryColor;
          }
          return kPrimaryColor;
        }),

        // Remove Surface Tint for Clean Look
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),

        // Dynamic Shadow Color
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        // .resolveWith((states) {
        //   if (states.contains(WidgetState.focused)) {
        //     return kSecondaryColor.withValues(alpha: 0.08);
        //   }
        //   return Colors.black.withValues(alpha: 0.08);
        // }),

        // Dynamic Elevation
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return 12.0;
          }
          if (states.contains(WidgetState.hovered)) {
            return 8.0;
          }
          return 4.0;
        }),

        // Enhanced Border with Focus States
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(
              color: kSecondaryColor.withValues(alpha: 0.3),
              width: 1.0,
            );
          }
          if (states.contains(WidgetState.hovered)) {
            return BorderSide(
              color: kSecondaryColor.withValues(alpha: 0.2),
              width: 1.5,
            );
          }
          return BorderSide(
            color: kBlackColor.withValues(alpha: 0.1),
            width: 1.0,
          );
        }),

        // Custom Shape with Rounded Corners
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultPadding * 2),
          ),
        ),

        // Enhanced Padding
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding / 1.2),
            vertical: getProportionateScreenHeight(kDefaultPadding / 2),
          ),
        ),

        // Enhanced Text Styling
        textStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return textTheme.bodySmall;
          }
          return textTheme.bodySmall;
        }),

        // Enhanced Hint Styling
        hintStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return textTheme.bodyMedium!
                .copyWith(color: kGreyColor, fontWeight: FontWeight.normal);
          }
          return textTheme.bodyMedium!
              .copyWith(color: kGreyColor, fontWeight: FontWeight.normal);
        }),

        // Enhanced Leading Icon
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: controller.text.isNotEmpty
                ? kSecondaryColor.withValues(alpha: 0.1)
                : kWhiteColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.search_rounded,
            color:
                controller.text.isNotEmpty ? kSecondaryColor : Colors.grey[600],
            size: 18,
          ),
        ),

        // Enhanced Trailing with Multiple Actions
        trailing: <Widget>[
          if (showFilterButton != null && showFilterButton!)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onFilterButtonTap,
              child: Container(
                padding: EdgeInsets.all(kDefaultPadding / 2),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ),
            ),
          if (showFilterButton != null && showFilterButton!)
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
          // if (controller.text.isNotEmpty) ...[
          // Clear Button
          if (controller.text.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onClearButtonTap,
              child: Container(
                padding: EdgeInsets.all(kDefaultPadding / 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red[600],
                  size: 18,
                ),
              ),
            ),
        ],
        //   else ...[
        //     // Filter/Menu Button when empty
        // InkWell(
        //   borderRadius: BorderRadius.circular(20),
        //   onTap: onFilterButtonTap,
        //   child: Container(
        //     padding: EdgeInsets.all(kDefaultPadding / 2),
        //     decoration: BoxDecoration(
        //       color: kWhiteColor,
        //       shape: BoxShape.circle,
        //     ),
        //     child: Icon(
        //       Icons.tune_rounded,
        //       color: Colors.grey[600],
        //       size: 18,
        //     ),
        //   ),
        // ),
        //   ],
        // ],
        // ),
        // Enhanced Constraints
        constraints: BoxConstraints(
          minHeight: getProportionateScreenHeight(kDefaultPadding * 3.2),
          maxHeight: getProportionateScreenHeight(kDefaultPadding * 4),
          minWidth: double.infinity,
        ),
      ),
    );
  }
}

////old
// import 'package:flutter/material.dart';
// import 'package:zmall/constants.dart';

// class CustomSearchBar extends StatelessWidget {
//   final TextEditingController? controller;
//   final void Function(String)? onChanged;
//   final Iterable<Widget>? trailing;
//   const CustomSearchBar(
//       {super.key, this.controller, this.onChanged, this.trailing});

//   @override
//   Widget build(BuildContext context) {
//     return SearchBar(
//       hintText: 'Search',
//       controller: controller,
//       leading: const Icon(Icons.search),
//       onChanged: onChanged,
//       trailing: trailing,
//       elevation: WidgetStateProperty.all(0),
//       padding:
//           WidgetStateProperty.all(EdgeInsets.only(left: kDefaultPadding * 1.5)),
//       textStyle:
//           WidgetStateProperty.all<TextStyle>(TextStyle(color: kBlackColor)),
//       hintStyle:
//           WidgetStateProperty.all<TextStyle>(TextStyle(color: kBlackColor)),
//       backgroundColor: WidgetStateProperty.all(kPrimaryColor),
//       overlayColor: WidgetStateProperty.all(kPrimaryColor),
//       shape: WidgetStateProperty.all(
//         RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(kDefaultPadding * 2),
//         ),
//       ),
//     );
//   }
// }
