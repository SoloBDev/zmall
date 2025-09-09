import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
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
        elevation: 0,
        title: Text("Help"),
      ),
      body: Padding(
        padding: EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
        child: Column(
          spacing: kDefaultPadding / 2,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
              decoration: BoxDecoration(
                  color: kPrimaryColor,
                  border: Border.all(color: kWhiteColor),
                  borderRadius: BorderRadius.circular(kDefaultPadding)),
              child: Column(
                spacing: kDefaultPadding / 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Support",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionCards(
                        onTap: () {
                          launchUrl(Uri(scheme: 'tel', path: '+251967575757'));
                        },
                        icon: HeroiconsOutline.phone,
                        title: "Call Now",
                      ),
                      _actionCards(
                        onTap: () {
                          launchUrl(Uri(
                              scheme: 'mailto', path: "info@zmallshop.com"));
                          // launch("mailto:info@zmallshop.com");
                        },
                        icon: HeroiconsOutline.envelope,
                        title: "E-Mail",
                      ),
                      _actionCards(
                        onTap: () {
                          // launch("tel:+2518707");
                          launchUrl(Uri(scheme: 'tel', path: '+2518707'));
                        },
                        icon: Icons.support_agent,
                        title: "Call HOTLINE",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ProfileListTile(
            //   icon: Icon(
            //     // Icons.call,
            //     HeroiconsOutline.phone,
            //     color: kSecondaryColor,
            //   ),
            //   title: "Call Now",
            //   onTap: () {
            //     // launch("tel:+251967575757");
            //     launchUrl(Uri(scheme: 'tel', path: '+251967575757'));
            //   },
            // ),
            // ProfileListTile(
            //   icon: Icon(
            //     // Icons.email,
            //     HeroiconsOutline.envelope,
            //     color: kSecondaryColor,
            //   ),
            //   title: "E-Mail",
            //   onTap: () {
            //     launchUrl(Uri(scheme: 'mailto', path: "info@zmallshop.com"));
            //     // launch("mailto:info@zmallshop.com");
            //   },
            // ),
            // ProfileListTile(
            //   icon: Icon(
            //     Icons.support_agent,
            //     color: kSecondaryColor,
            //   ),
            //   title: "Call HOTLINE",
            //   onTap: () {
            //     // launch("tel:+2518707");
            //     launchUrl(Uri(scheme: 'tel', path: '+2518707'));
            //   },
            // ),
            ProfileListTile(
              icon: Icon(
                // Icons.lock,
                HeroiconsOutline.shieldCheck,
                color: kSecondaryColor,
              ),
              title: "Privacy Policy",
              onTap: () {
                Service.launchInWebViewOrVC(
                    "https://app.zmallshop.com/terms.html");
              },
            ),
            ProfileListTile(
              icon: Icon(
                HeroiconsOutline.clipboardDocumentCheck,
                // Icons.assignment,
                color: kSecondaryColor,
              ),
              title: "Terms and Conditions",
              onTap: () {
                Service.launchInWebViewOrVC(
                    "https://app.zmallshop.com/terms.html");
              },
            ),
            ProfileListTile(
              icon: Icon(
                FontAwesomeIcons.instagram,
                color: kSecondaryColor,
              ),
              title: "Follow us on Instagram",
              onTap: () {
                Service.launchInWebViewOrVC(
                    "https://www.instagram.com/zmall_delivery/?hl=en");
              },
            ),
            ProfileListTile(
              icon: Icon(
                Icons.facebook_outlined,
                color: kSecondaryColor,
              ),
              title: "Follow us on Facebook",
              onTap: () {
                Service.launchInWebViewOrVC(
                    "https://www.facebook.com/Zmallshop/");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCards({
    required String title,
    required IconData icon,
    void Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kDefaultPadding / 1.6),
      splashColor: kBlackColor.withValues(alpha: 0.1),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: kDefaultPadding, vertical: kDefaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kWhiteColor,
                //  kBlackColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: kSecondaryColor
                  //  kBlackColor,
                  ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kBlackColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
