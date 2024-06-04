import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

import 'components/body.dart';

class GlobalItem extends StatelessWidget {
  static String routeName = '/item';

  GlobalItem({
    @required this.item,
    @required this.location,
    @required this.isOpen,
  });

  final isOpen;
  final item;
  final location;

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
      body: Body(
        isOpen: isOpen,
        item: item,
        location: location,
      ),
    );
  }
}
