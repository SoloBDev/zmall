import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/help/components/help_action_cards.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/services/service.dart';
// import 'package:zmall/help/support_chat/support_chat_screen.dart';
import 'package:zmall/help/faq/faq_screen.dart';
import 'package:zmall/utils/size_config.dart';

class HelpScreen extends StatelessWidget {
  static String routeName = '/help';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: Text("Help & Support")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            getProportionateScreenHeight(kDefaultPadding),
          ),
          child: Column(
            spacing: getProportionateScreenHeight(kDefaultPadding),
            children: [
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
                        HelpActionCards(
                          onTap: () {
                            launchUrl(
                              Uri(scheme: 'tel', path: '+251967575757'),
                            );
                          },
                          title: "Call Now",
                          iconColor: kGreenColor,
                          icon: HeroiconsSolid.phone,
                        ),
                        HelpActionCards(
                          onTap: () {
                            launchUrl(
                              Uri(scheme: 'mailto', path: "info@zmallshop.com"),
                            );
                            // launch("mailto:info@zmallshop.com");
                          },
                          title: "E-Mail",
                          iconColor: Colors.redAccent,
                          icon: HeroiconsSolid.envelope,
                        ),
                        HelpActionCards(
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
              // // Chat Support Button
              // InkWell(
              //   onTap: () {
              //     Navigator.pushNamed(context, SupportChatScreen.routeName);
              //   },
              //   borderRadius: BorderRadius.circular(kDefaultPadding),
              //   child: Container(
              //     padding: EdgeInsets.symmetric(
              //       horizontal: getProportionateScreenWidth(kDefaultPadding),
              //       vertical: getProportionateScreenHeight(kDefaultPadding),
              //     ),
              //     decoration: BoxDecoration(
              //       gradient: LinearGradient(
              //         colors: [
              //           kSecondaryColor,
              //           kSecondaryColor.withValues(alpha: 0.8),
              //         ],
              //         begin: Alignment.topLeft,
              //         end: Alignment.bottomRight,
              //       ),
              //       borderRadius: BorderRadius.circular(kDefaultPadding),
              //       boxShadow: [
              //         BoxShadow(
              //           color: kSecondaryColor.withValues(alpha: 0.3),
              //           blurRadius: 12,
              //           offset: Offset(0, 4),
              //         ),
              //       ],
              //     ),
              //     child: Row(
              //       children: [
              //         Container(
              //           padding: EdgeInsets.all(
              //             getProportionateScreenWidth(kDefaultPadding / 1.2),
              //           ),
              //           decoration: BoxDecoration(
              //             color: kPrimaryColor.withValues(alpha: 0.2),
              //             shape: BoxShape.circle,
              //           ),
              //           child: Icon(
              //             Icons.support_agent_rounded,
              //             color: kPrimaryColor,
              //             size: getProportionateScreenWidth(28),
              //           ),
              //         ),
              //         SizedBox(
              //           width: getProportionateScreenWidth(kDefaultPadding),
              //         ),
              //         Expanded(
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text(
              //                 "Chat with Support",
              //                 style: TextStyle(
              //                   fontSize: getProportionateScreenWidth(16),
              //                   fontWeight: FontWeight.bold,
              //                   color: kPrimaryColor,
              //                 ),
              //               ),
              //               SizedBox(height: 2),
              //               Text(
              //                 "Get instant help • Online now",
              //                 style: TextStyle(
              //                   fontSize: getProportionateScreenWidth(12),
              //                   color: kPrimaryColor.withValues(alpha: 0.9),
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //         Icon(
              //           HeroiconsSolid.chevronRight,
              //           color: kPrimaryColor,
              //           size: getProportionateScreenWidth(20),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
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
                        HelpActionCards(
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
                        // HelpActionCards(
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
                        HelpActionCards(
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
                        HelpActionCards(
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
                        HelpActionCards(
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
                        HelpActionCards(
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
                        HelpActionCards(
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
                  HeroiconsOutline.questionMarkCircle,
                  color: kBlackColor,
                ),
                title: "FAQ",
                onTap: () {
                  Navigator.pushNamed(context, FAQScreen.routeName);
                },
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
                    "https://app.zmall.et/privacy.html",
                  );
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
                    "https://app.zmall.et/terms.html",
                  );
                },
              ),
            ],
          ),
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