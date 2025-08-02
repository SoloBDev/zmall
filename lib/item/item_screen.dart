import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

import 'components/body.dart';

class ItemScreen extends StatelessWidget {
  static String routeName = '/item';

  ItemScreen({
    @required this.item,
    @required this.location,
    this.isDineIn = false,
    this.tableNumber = "0",
    this.isSplashRedirect = false,
  });

  final item;
  final location;
  final isDineIn;
  final tableNumber;
  final isSplashRedirect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      // appBar: AppBar(
      //   title: Text(
      //     "Add to Cart",
      //     style: TextStyle(color: kBlackColor),
      //   ),
      //   elevation: 0.0,
      //   backgroundColor: kPrimaryColor,
      // ),
      body: SafeArea(
        top: false,
        child: Body(
          item: item,
          location: location,
          isDineIn: isDineIn,
          tableNumber: tableNumber,
          isSplashRedirect: isSplashRedirect,
        ),
      ),
    );
  }
}
