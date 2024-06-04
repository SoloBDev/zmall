import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/size_config.dart';

class ReportScreen extends StatefulWidget {
  static String routeName = '/report';

  const ReportScreen(
      {@required this.price, @required this.orderPaymentUniqueId});

  final double? price;
  final String? orderPaymentUniqueId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Logging ecommerce purchase");
    MyApp.analytics
        .logPurchase(
            currency: Provider.of<ZMetaData>(context, listen: false).country,
            value: widget.price,
            transactionId: widget.orderPaymentUniqueId)
        .whenComplete(() => print("purchase logged"));
    /*    _fcm.subscribeToTopic(
        Provider.of<ZMetaData>(context, listen: false).country); */
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
              style: Theme.of(context).textTheme.headline5?.copyWith(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 4)),
            Text(
              "Order Created. Thank you for choosing ZMall",
              style: Theme.of(context).textTheme.subtitle1,
              textAlign: TextAlign.center,
            ),
            Spacer(flex: 2),
            CustomButton(
              title: "Done",
              press: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, "/start", (Route<dynamic> route) => false);
              },
              color: kSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
