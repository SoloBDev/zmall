import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:provider/provider.dart';
import 'package:zmall/models/metadata.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({
    required this.referralCode,
  });

  final String referralCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: Text(
          "Referral",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer(),
              Container(
                decoration: BoxDecoration(
                    color: kPrimaryColor,
                    border: Border.all(color: kWhiteColor),
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding),
                    ),
                    boxShadow: [kDefaultShadow]),
                child: Padding(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(kDefaultPadding),
                        decoration: BoxDecoration(
                            color: kWhiteColor,
                            // boxShadow: [boxShadow],
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding)),
                        child: Icon(
                          HeroiconsOutline.share,
                          size:
                              getProportionateScreenWidth(kDefaultPadding * 2),
                        ),
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      Text(
                        "Refer now and earn up to 50 ${Provider.of<ZMetaData>(context, listen: false).currency}.",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      Text(
                        "Send a referral link to your friends and family via SMS / Email / Whatsapp",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      // Text(
                      //   "REFERRAL CODE",
                      //   style:
                      //       Theme.of(context).textTheme.titleMedium?.copyWith(
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      // ),
                      // SizedBox(
                      //     height: getProportionateScreenHeight(
                      //         kDefaultPadding / 2)),
                      Center(
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(
                                    new ClipboardData(text: referralCode))
                                .then((_) {
                              Service.showMessage(
                                  context: context,
                                  title: "Referral code copied to clipboard",
                                  error: false);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  getProportionateScreenWidth(kDefaultPadding),
                              vertical:
                                  getProportionateScreenHeight(kDefaultPadding),
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              border: Border.all(
                                color: kWhiteColor,
                              ),
                              // boxShadow: [boxShadow],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  referralCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                                SizedBox(
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding / 2)),
                                Icon(
                                  Icons.copy,
                                  size: getProportionateScreenWidth(
                                      kDefaultPadding),
                                  color: kBlackColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              //            SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
              // Spacer(),
              // CustomButton(
              //   title: "COPY CODE",
              //   press: () {
              //     Clipboard.setData(new ClipboardData(text: referralCode))
              //         .then((_) {
              //       Service.showMessage(
              //           context: context,
              //           title: "Referral code copied to clipboard",
              //           error: false);
              //     });
              //   },
              //   color: kBlackColor,
              // )
            ],
          ),
        ),
      ),
    );
  }
}
