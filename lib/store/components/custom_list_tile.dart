import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/store/components/image_container.dart';
import 'store_info.dart';

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    Key? key,
    required this.press,
    required this.store,
    required this.isOpen,
    this.isAbroad = false,
  }) : super(key: key);

  final store;
  final bool? isOpen;
  final VoidCallback? press;
  final bool isAbroad;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Container(
        padding: EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(kDefaultPadding),
          border: Border.all(color: kBlackColor.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  ImageContainer(
                    url:
                        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${store['image_url']}",
                    // url: "http://159.65.147.111:8000/${store['image_url']}",
                  ),
                  SizedBox(width: kDefaultPadding * 1.3),
                  StoreInfo(
                    store: store,
                    isOpen: isOpen!,
                    isAbroad: isAbroad,
                  )
                ],
              ),
            ),
            //NavigationArrow(),
          ],
        ),
      ),
    );
  }
  //  TextButton(
  //         style: ButtonStyle(
  //           backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
  //           overlayColor: MaterialStateProperty.all(kWhiteColor),
  //         ),
  // onPressed: press,
}

// import 'package:flutter/material.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/store/components/image_container.dart';
// import 'package:zmall/store/components/navigation_arrow.dart';
// import 'store_info.dart';

// class CustomListTile extends StatelessWidget {
//   const CustomListTile({
//     super.key,
//     required this.press,
//     required this.store,
//     required this.isOpen,
//     this.isAbroad = false,
//   });

//   final store;
//   final bool? isOpen;
//   final VoidCallback? press;
//   final bool isAbroad;

//   @override
//   Widget build(BuildContext context) {
//     return TextButton(
//       style: ButtonStyle(
//         backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
//         overlayColor: WidgetStateProperty.all(kWhiteColor),
//         shape: WidgetStateProperty.all<RoundedRectangleBorder>(
//           RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(kDefaultPadding),
//           ),
//         ),
//       ),
//       onPressed: press,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Row(
//               children: [
//                 ImageContainer(
//                   url: "https://app.zmallapp.com/${store['image_url']}",
//                   // url: "http://159.65.147.111:8000/${store['image_url']}",
//                 ),
//                 SizedBox(width: kDefaultPadding),
//                 StoreInfo(
//                   store: store,
//                   isOpen: isOpen!,
//                   isAbroad: isAbroad,
//                 )
//               ],
//             ),
//           ),
//           NavigationArrow(),
//         ],
//       ),
//     );
//   }
// }

class FavoriteCustomListTile extends StatelessWidget {
  const FavoriteCustomListTile({
    Key? key,
    required this.press,
    @required this.store,
    required this.isOpen,
    this.isAbroad = false,
  }) : super(key: key);

  final store;
  final bool isOpen;
  final Function press;
  final bool isAbroad;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => press,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              children: [
                FavoriteImageContainer(
                  url: "https://app.zmallapp.com/${store['image_url']}",
                ),
                SizedBox(height: kDefaultPadding / 4),
                FavoriteStoreInfo(
                  store: store,
                  isOpen: isOpen,
                  isAbroad: isAbroad,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
