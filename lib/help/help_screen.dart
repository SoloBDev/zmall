import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class HelpScreen extends StatelessWidget {
  static String routeName = '/help';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Help",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
        child: Column(
          children: [
            ProfileListTile(
              icon: Icon(
                Icons.call,
                color: kSecondaryColor,
              ),
              title: "Call Now",
              press: () {
                // launch("tel:+251967575757");
                launchUrl(Uri(scheme: 'tel', path: '+251967575757'));
              },
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            ProfileListTile(
              icon: Icon(
                Icons.email,
                color: kSecondaryColor,
              ),
              title: "Mail",
              press: () {
                launchUrl(Uri(scheme: 'mailto', path: "info@zmallshop.com"));
                // launch("mailto:info@zmallshop.com");
              },
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            ProfileListTile(
              icon: Icon(
                Icons.assignment,
                color: kSecondaryColor,
              ),
              title: "Terms and Conditions",
              press: () {
                Service.launchInWebViewOrVC(
                    "https://app.zmallshop.com/terms.html");
              },
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            ProfileListTile(
              icon: Icon(
                Icons.lock,
                color: kSecondaryColor,
              ),
              title: "Privacy Policy",
              press: () {
                Service.launchInWebViewOrVC(
                    "https://app.zmallshop.com/terms.html");
              },
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            ProfileListTile(
              icon: Icon(
                Icons.call,
                color: kSecondaryColor,
              ),
              title: "Call HOTLINE",
              press: () {
                // launch("tel:+2518707");
                launchUrl(Uri(scheme: 'tel', path: '+2518707'));
              },
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            ProfileListTile(
              icon: Icon(
                FontAwesomeIcons.instagram,
                color: kSecondaryColor,
              ),
              title: "Follow us on Instagram",
              press: () {
                Service.launchInWebViewOrVC(
                    "https://www.instagram.com/zmall_delivery/?hl=en");
              },
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            ProfileListTile(
              icon: Icon(
                Icons.facebook,
                color: kSecondaryColor,
              ),
              title: "Follow us on Facebook",
              press: () {
                Service.launchInWebViewOrVC(
                    "https://www.facebook.com/Zmallshop/");
              },
            ),
          ],
        ),
      ),
    );
  }
}
