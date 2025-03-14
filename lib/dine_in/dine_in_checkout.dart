import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

class DineInCheckout extends StatefulWidget {
  const DineInCheckout({Key? key}) : super(key: key);

  @override
  _DineInCheckoutState createState() => _DineInCheckoutState();
}

class _DineInCheckoutState extends State<DineInCheckout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Text("body"),
    );
  }
}
