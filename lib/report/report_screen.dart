import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/size_config.dart';

class ReportScreen extends StatefulWidget {
  static String routeName = '/report';

  const ReportScreen({
    super.key,
    @required this.price,
    @required this.orderPaymentUniqueId,
  });

  final double? price;
  final String? orderPaymentUniqueId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  @override
  void initState() {
    super.initState();
    // debugPrint("Logging ecommerce purchase");
    MyApp.analytics
        .logPurchase(
            currency: Provider.of<ZMetaData>(context, listen: false).country,
            value: widget.price,
            transactionId: widget.orderPaymentUniqueId)
        .whenComplete(
          () => debugPrint(""),
          // debugPrint("purchase logged"),
        );
    _fcm.subscribeToTopic(
        Provider.of<ZMetaData>(context, listen: false).country);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        minimum: EdgeInsets.only(
          left: kDefaultPadding,
          right: kDefaultPadding,
          bottom: kDefaultPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kSecondaryColor.withValues(
                            alpha: 0.1), // Subtle background for the icon
                        border: Border.all(
                          color: kSecondaryColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kSecondaryColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        HeroiconsSolid.shieldCheck,
                        color: kSecondaryColor,
                        size: getProportionateScreenWidth(kDefaultPadding * 8),
                      ),
                    ),
                    SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding)),
                    Text(
                      "Order Confirmed!", // "Completed!",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: kSecondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 4)),
                    Text(
                      "Your order has been successfully placed.\nThank you for choosing ZMall!",
                      // "Order Created. Thank you for choosing ZMall",
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: getProportionateScreenHeight(kDefaultPadding),
                left: getProportionateScreenHeight(kDefaultPadding),
                bottom: getProportionateScreenHeight(kDefaultPadding),
              ),
              child: CustomButton(
                title: "Explore More",

                ///"Done",
                press: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/start", (Route<dynamic> route) => false);
                },
                color: kSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
