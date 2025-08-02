import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import "package:flutter/material.dart";
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_progress_indicator.dart';
import 'package:zmall/widgets/custom_tag.dart';

class SubscribeScreen extends StatefulWidget {
  static String routeName = '/subscribe';

  const SubscribeScreen({Key? key}) : super(key: key);

  @override
  _SubscribeScreenState createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? lang;
  bool _isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLang();
  }

  void getLang() async {
    var data = await Service.read('lang');
    if (data != null) {
      setState(() {
        lang = data;
      });
    } else {
      lang = "en_US";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            Provider.of<ZLanguage>(context, listen: false).language,
            style: TextStyle(
              color: kBlackColor,
            ),
          ),
          elevation: 1.0,
        ),
        body: ModalProgressHUD(
          color: Colors.transparent,
          inAsyncCall: _isLoading,
          progressIndicator: CustomLinearProgressIndicator(
            message: "",
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  debugPrint("English selected...");
                  setState(() {
                    _isLoading = true;
                  });
                  // await Future.delayed(Duration(seconds: 3));
                  Provider.of<ZLanguage>(context, listen: false)
                      .changeLanguage('en_US');
                  getLang();
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: SubscribeContainer(
                  iconText: "packages/country_code_picker/flags/us.png",
                  title: Provider.of<ZLanguage>(context, listen: false).english,
                  caption:
                      Provider.of<ZLanguage>(context, listen: false).english,
                  isSubscribed: lang == 'en_US',
                ),
              ),
              GestureDetector(
                onTap: () {
                  debugPrint("Chinese Selected");
                  setState(() {
                    _isLoading = true;
                  });
                  // await Future.delayed(Duration(seconds: 3));
                  Provider.of<ZLanguage>(context, listen: false)
                      .changeLanguage('cn_CN');
                  getLang();
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: SubscribeContainer(
                  iconText: "packages/country_code_picker/flags/cn.png",
                  title: Provider.of<ZLanguage>(context, listen: false).chinese,
                  caption:
                      Provider.of<ZLanguage>(context, listen: false).chinese,
                  isSubscribed: lang == "cn_CN",
                ),
              ),
            ],
          ),
        ));
  }
}

class SubscribeContainer extends StatelessWidget {
  const SubscribeContainer({
    Key? key,
    this.iconText,
    this.caption,
    this.title,
    this.isSubscribed,
  }) : super(key: key);

  final String? iconText, title, caption;
  final bool? isSubscribed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kPrimaryColor,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(kDefaultPadding / 2),
          horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
        ),
        child: Row(
          children: [
            Image.asset(
              iconText!,
              width: getProportionateScreenWidth(kDefaultPadding * 3),
              height: getProportionateScreenHeight(kDefaultPadding * 2),
            ),
            SizedBox(
              width: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: getProportionateScreenWidth(kDefaultPadding / 4),
                  ),
                  Text(
                    caption!,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(
                    height: getProportionateScreenWidth(kDefaultPadding / 4),
                  ),
                ],
              ),
            ),
            Spacer(),
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                color: isSubscribed! ? kSecondaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: kGreyColor),
              ),
            ),
            SizedBox(
              width: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
          ],
        ),
      ),
    );
  }
}
