import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/home_page/global_home.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class GlobalReport extends StatefulWidget {
  const GlobalReport({required this.price, required this.orderPaymentUniqueId});

  final double price;
  final String orderPaymentUniqueId;

  @override
  State<GlobalReport> createState() => _GlobalReportState();
}

class _GlobalReportState extends State<GlobalReport> {

  var abroadData;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Logging ecommerce purchase");
    MyApp.analytics
        .logPurchase(
            currency: 'ETB',
            value: widget.price,
            transactionId: widget.orderPaymentUniqueId)
        .whenComplete(() => print("purchase logged"));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: kDefaultPadding, vertical: kDefaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(flex: 1),
            Icon(
              Icons.verified_user,
              color: kSecondaryColor,
              size: getProportionateScreenWidth(kDefaultPadding * 7),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
            Text(
              "Completed!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 4)),
            Text(
              "Order Created. Thank you for choosing ZMall",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            Spacer(flex: 2),
            CustomButton(
              title: "Done",
              press: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context){
                  // return GlobalHome(user: FirebaseAuth.instance.currentUser!);
                  return GlobalHome();
                }), (route) => false);

              },
              color: kSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
