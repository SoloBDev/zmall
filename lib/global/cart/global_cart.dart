import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'components/body.dart';

class GlobalCart extends StatelessWidget {
  const GlobalCart({this.hasBack = true});

  final bool hasBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Basket",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
        automaticallyImplyLeading: hasBack,
      ),
      body: Body(),
    );
  }
}
