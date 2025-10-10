import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';

class HelpScreen extends StatelessWidget {
  static String routeName = '/help';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Help & Support",
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
        child: Column(
          spacing: getProportionateScreenHeight(kDefaultPadding),
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding),
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
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
                        title: "Call Now",
                        iconColor: kGreenColor,
                        icon: HeroiconsSolid.phone,
                      ),
                      _actionCards(
                        onTap: () {
                          launchUrl(Uri(
                              scheme: 'mailto', path: "info@zmallshop.com"));
                          // launch("mailto:info@zmallshop.com");
                        },
                        title: "E-Mail",
                        iconColor: Colors.redAccent,
                        icon: HeroiconsSolid.envelope,
                      ),
                      _actionCards(
                        onTap: () {
                          launchUrl(Uri(scheme: 'tel', path: '+2518707'));
                        },
                        icon: Icons.support_agent_rounded,
                        title: "HOTLINE",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding),
                vertical: getProportionateScreenHeight(kDefaultPadding),
              ),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                border: Border.all(color: kWhiteColor),
                borderRadius: BorderRadius.circular(kDefaultPadding),
              ),
              child: Column(
                spacing: getProportionateScreenHeight(kDefaultPadding),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Social Media",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // spacing: getProportionateScreenWidth(kDefaultPadding / 4),
                    children: [
                      //Instagram
                      _actionCards(
                        icon: FontAwesomeIcons.instagram,
                        iconColor: Colors.redAccent,
                        title: "Instagram",
                        onTap: () {
                          Service.launchInWebViewOrVC(
                            "https://www.instagram.com/zmall_delivery/?hl=en",
                          );
                        },
                      ),

                      //YouTube
                      // _actionCards(
                      //   icon: FontAwesomeIcons.youtube,
                      //   iconColor: Colors.redAccent,
                      //   title: "YouTube",
                      //   onTap: () {
                      //     Service.launchInWebViewOrVC(
                      //       "https://www.youtube.com/@zoorya_et",
                      //     );
                      //   },
                      // ),https://www.zmalldelivery.com
                      //Tiktok
                      _actionCards(
                        icon: FontAwesomeIcons.tiktok,
                        iconColor: kBlackColor,
                        title: "Tiktok",
                        onTap: () {
                          Service.launchInWebViewOrVC(
                            "https://www.tiktok.com/@zmall_delivery",
                          );
                        },
                      ),
                      //Facebook
                      _actionCards(
                        icon: FontAwesomeIcons.facebookF,
                        iconColor: Colors.blue,
                        title: "Facebook",
                        onTap: () {
                          Service.launchInWebViewOrVC(
                            "https://www.facebook.com/Zmallshop/",
                          );
                        },
                      ),
                    ],
                  ),

                  //
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // spacing: getProportionateScreenWidth(kDefaultPadding / 4),
                    children: [
                      //LinkedIn
                      _actionCards(
                        icon: FontAwesomeIcons.linkedin,
                        iconColor: Colors.blue,
                        title: "LinkedIn",
                        onTap: () {
                          Service.launchInWebViewOrVC(
                            "https://www.linkedin.com/company/zmall/",
                          );
                        },
                      ),
                      //X
                      //Follow us on
                      _actionCards(
                        icon: FontAwesomeIcons.xTwitter,
                        iconColor: kBlackColor,
                        title: "X",
                        onTap: () {
                          Service.launchInWebViewOrVC(
                            "https://x.com/Zmall_Delivery",
                          );
                        },
                      ),
                      //Website
                      _actionCards(
                        icon: HeroiconsOutline.globeAlt,
                        iconColor: Colors.blue,
                        title: "Website",
                        onTap: () {
                          Service.launchInWebViewOrVC(
                            "https://www.zmalldelivery.com",
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ProfileListTile(
              icon: Icon(
                // Icons.lock,
                HeroiconsOutline.shieldCheck,
                color: kBlackColor,
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
                color: kBlackColor,
              ),
              title: "Terms and Conditions",
              onTap: () {
                Service.launchInWebViewOrVC(
                    "https://app.zmallshop.com/terms.html");
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
    Color iconColor = kBlackColor,
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
              child: Icon(icon, size: 20, color: iconColor
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
 // Container(
            //   padding: EdgeInsets.symmetric(
            //       horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
            //   decoration: BoxDecoration(
            //       color: kPrimaryColor,
            //       border: Border.all(color: kWhiteColor),
            //       borderRadius: BorderRadius.circular(kDefaultPadding)),
            //   child: Column(
            //     spacing: getProportionateScreenHeight(kDefaultPadding),
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         "Social Media",
            //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //               fontWeight: FontWeight.bold,
            //             ),
            //       ),
            //       ProfileListTile(
            //         icon: Icon(
            //           FontAwesomeIcons.instagram,
            //           color: kBlackColor,
            //         ),
            //         title: "Follow us on Instagram",
            //         onTap: () {
            //           Service.launchInWebViewOrVC(
            //               "https://www.instagram.com/zmall_delivery/?hl=en");
            //         },
            //       ),
            //       ProfileListTile(
            //         icon: Icon(
            //           Icons.facebook_outlined,
            //           color: kBlackColor,
            //         ),
            //         title: "Follow us on Facebook",
            //         onTap: () {
            //           Service.launchInWebViewOrVC(
            //               "https://www.facebook.com/Zmallshop/");
            //         },
            //       ),
            //     ],
            //   ),
            // ),