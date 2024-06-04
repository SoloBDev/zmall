import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({
    required this.referralCode,
  });

  final String referralCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Referral",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Container(
              decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  boxShadow: [boxShadow]),
              child: Padding(
                padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: getProportionateScreenWidth(kDefaultPadding * 3),
                    ),
                    Text(
                      "Refer now and earn up to ETB 50.",
                      style: Theme.of(context).textTheme.headline6?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding)),
                    Text(
                      "Send a referral link to your friends and family via SMS / Email / Whatsapp",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.caption,
                    ),
                    SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding)),
                    Text(
                      "REFERRAL CODE",
                      style: Theme.of(context).textTheme.subtitle1?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    Container(
                      width: getProportionateScreenWidth(kDefaultPadding * 10),
                      height: getProportionateScreenHeight(kDefaultPadding * 3),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        border: Border.all(
                          color: kSecondaryColor,
                        ),
                        boxShadow: [boxShadow],
                      ),
                      child: Center(
                        child: Text(
                          referralCode,
                          style:
                              Theme.of(context).textTheme.headline6?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
//            SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
            Spacer(),
            CustomButton(
              title: "COPY CODE",
              press: () {
                Clipboard.setData(new ClipboardData(text: referralCode))
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      Service.showMessage(
                          "Referral code copied to clipboard", false));
                });
              },
              color: kBlackColor,
            )
          ],
        ),
      ),
    );
  }
}
