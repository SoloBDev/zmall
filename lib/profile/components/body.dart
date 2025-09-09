import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/borsa/borsa_screen.dart';
import 'package:zmall/core_services.dart';
// import 'package:zmall/favorites/favorites_screen.dart';
import 'package:zmall/help/help_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/profile/components/edit_profile.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/profile/components/referral_code.dart';
import 'package:zmall/service.dart';
import 'package:zmall/constants.dart';
import 'package:flutter/material.dart';
import 'package:zmall/size_config.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'package:zmall/widgets/flippable_icon.dart';

class ProfileScreen extends StatefulWidget {
  static String routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<ProfileScreen> {
  var userData;
  var responseData;
  bool isLoading = false;
  late String otp;
  late String verificationCode;
  bool errorFound = false;
  bool otpSent = false;
  // String setUrl = {Provider.of<ZMetaData>(context, listen: false).baseUrl};
  int remainder = 0;
  int quotient = 0;
  bool isRewarded = false;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      // if (userData['user']['country_phone_code'] == "+211") {
      //   setState(() {
      //     setUrl = southSudan;
      //   });
      // } else if (userData['user']['country_phone_code'] == "+251") {
      //   setState(() {
      //     setUrl = {Provider.of<ZMetaData>(context, listen: false).baseUrl};
      //   });
      // }
      var usrData = await userDetails();
      if (usrData != null && usrData['success']) {
        setState(() {
          userData = usrData;
          if (userData['user'] != null &&
              !userData['user']['is_phone_number_verified']) {
            Service.showMessage(
              context: context,
              title: "Please verify your phone number!",
              error: true,
            );
          }
        });
        Service.save('user', userData);
      }
      getData();
    }
  }

  void getData() {
    if (userData['user']['order_count'] > 0) {
      int x = (int.parse(userData['user']['order_count'].toString()) % 10);
      if (x != 0) {
        setState(() {
          quotient =
              (int.parse(userData['user']['order_count'].toString()) ~/ 10);
          remainder = x;
          isRewarded = false;
        });
      } else {
        setState(() {
          quotient =
              (int.parse(userData['user']['order_count'].toString()) ~/ 10);
          remainder = x;
          isRewarded = true;
        });
      }
    }
  }

  void logOut() async {
    setState(() {
      isLoading = true;
    });
    await signOut(userData['user']['_id'], userData['user']['server_token']);

    if (responseData != null && responseData['success']) {
      await Service.saveBool('logged', false);
      await Service.remove('user');
      await Service.remove('cart');
      await Service.remove('aliexpressCart');

      ///newly added for aliexpress
      await Service.remove('images');
      await Service.remove('p_items');
      await Service.remove('s_items');

      Service.showMessage(
        error: false,
        context: context,
        title: "You have successfully logged out!",
      );
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } else {
      if (responseData['error_code'] != null &&
          responseData['error_code'] == 999) {
        await CoreServices.clearCache();
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        isLoading = false;
      });
      Service.showMessage(
        error: true,
        context: context,
        title: "${errorCodes['${responseData['error_code']}']}",
      );
    }
  }

  void deleteUser() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(Duration(seconds: 3));
    http.Response? deleteUserResponse = await Service.deleteUserAccount(
        userData['user']['_id'], true, userData['user']['user_type'], context);
    if (deleteUserResponse != null) {
      if (json.decode(deleteUserResponse.body) != null &&
          json.decode(deleteUserResponse.body)['success']) {
        Service.showMessage(
          context: context,
          title: "User account successfully deleted.",
          error: true,
        );
        await Service.saveBool('logged', false);
        await Service.remove('user');
        await Service.remove('cart');
        await Service.remove('aliexpressCart'); //NEW
        await Service.remove('images');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    } else {
      Service.showMessage(
        context: context,
        title: errorCodes['${responseData['error_code']}'],
        error: true,
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
        // backgroundColor: userData == null ? kPrimaryColor : kWhiteColor,
        backgroundColor: kPrimaryColor,
        // appBar: AppBar(
        //   elevation: 0,
        //   surfaceTintColor: kPrimaryColor,
        //   actions: [
        //     TextButton(
        //         onPressed: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (context) => EditProfile(
        //                 userData: userData,
        //               ),
        //             ),
        //           ).then((value) => getUser());
        //         },
        //         child: Text(
        //           "Edit",
        //           style: textTheme.titleMedium!.copyWith(
        //               color: kSecondaryColor, fontWeight: FontWeight.bold),
        //         ))
        //   ],
        //   title: Text("My ${Provider.of<ZLanguage>(context).profilePage}"),
        // ),
        body:
            // userData != null ?
            SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
                decoration: BoxDecoration(color: kPrimaryColor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "My ${Provider.of<ZLanguage>(context).profilePage}",
                      style: Theme.of(context)
                          .primaryTextTheme
                          .titleLarge!
                          .copyWith(
                              color: kBlackColor, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: userData != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfile(
                                    userData: userData,
                                  ),
                                ),
                              ).then((value) => getUser());
                            }
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(
                                    firstRoute: false,
                                  ),
                                ),
                              ).then((value) => getUser());
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 1.5,
                            vertical: kDefaultPadding / 3),
                        decoration: BoxDecoration(
                            color: kWhiteColor,
                            border: Border.all(color: kWhiteColor),
                            // kBlackColor.withValues(alpha: 0.08)),
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2)),
                        child: Row(
                          spacing: kDefaultPadding / 3,
                          children: [
                            Text(
                              userData != null
                                  ? Provider.of<ZLanguage>(context,
                                          listen: false)
                                      .edit
                                  : Provider.of<ZLanguage>(context,
                                          listen: false)
                                      .login,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Icon(
                              size: 20,
                              color: kBlackColor,
                              userData != null
                                  ? HeroiconsOutline.pencilSquare
                                  : HeroiconsOutline.arrowLeftEndOnRectangle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: getProportionateScreenHeight(kDefaultPadding)),
                  child: Column(
                    children: [
                      /////user info section///
                      SizedBox(
                        width: getProportionateScreenWidth(80),
                        height: getProportionateScreenHeight(80),
                        child: Stack(
                          children: [
                            ImageContainer(
                                width: getProportionateScreenWidth(100),
                                height: getProportionateScreenHeight(100),
                                shape: BoxShape.circle,
                                url: userData == null
                                    ? ''
                                    : "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${userData['user']['image_url']}"),
                            if (userData != null &&
                                userData['user'] != null &&
                                userData['user']['is_phone_number_verified'])
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kWhiteColor,
                                  ),
                                  child: Icon(
                                    HeroiconsSolid.checkBadge,
                                    color: kSecondaryColor,
                                    size: getProportionateScreenHeight(17),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      Text(
                        userData == null
                            ? "Guest User"
                            : "${userData['user']['first_name']} ${userData['user']['last_name']} ",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (userData != null)
                        SizedBox(
                          height: kDefaultPadding,
                        ),

                      /////

                      /////user info section///

                      ///user contact section
                      if (userData != null)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding:
                              EdgeInsets.symmetric(horizontal: kDefaultPadding),
                          child: Row(
                            spacing: kDefaultPadding,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FlippableCircleIcon(
                                radius: 20,
                                frontColor: kGreenColor,
                                icon: HeroiconsSolid.phone,
                                label:
                                    "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${userData['user']['phone']}",
                              ),
                              FlippableCircleIcon(
                                radius: 20,
                                icon: HeroiconsSolid.envelope,
                                label: "${userData['user']['email']}",
                              ),
                              FlippableCircleIcon(
                                radius: 20,
                                frontColor:
                                    kSecondaryColor.withValues(alpha: 0.8),
                                icon: HeroiconsSolid.mapPin,
                                label: userData['user']['address'] ??
                                    "Addis Ababa",
                              ),
                            ],
                          ),
                        ),

                      // SizedBox(
                      //     height: getProportionateScreenHeight(kDefaultPadding)),
                      // //user status section
                      // userInfo(),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding,
                            vertical: kDefaultPadding / 2),
                        child: Column(
                          spacing: kDefaultPadding / 2,
                          children: [
                            userInfo(),
                            LinearPercentIndicator(
                              animation: true,
                              lineHeight: getProportionateScreenHeight(
                                  kDefaultPadding * 0.9),
                              barRadius: Radius.circular(
                                getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              backgroundColor: kWhiteColor,
                              progressColor: kSecondaryColor,
                              leading: Text(
                                userData != null ? "${quotient}0" : "00",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                userData != null ? "${quotient + 1}0" : "10",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              percent:
                                  userData != null ? (remainder / 10) : 0.1,
                            ),
                            Text(
                              userData == null
                                  // ? "Log in now and enjoy delivery cashbacks!"
                                  ? "Log in for your chance to win delivery cashbacks on lucky orders!"
                                  : isRewarded
                                      ? "${Provider.of<ZLanguage>(context, listen: true).youAre} 9 ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                                      : (10 - remainder) != 1
                                          ? "${Provider.of<ZLanguage>(context, listen: true).youAre} ${10 - remainder} ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                                          : Provider.of<ZLanguage>(context,
                                                  listen: true)
                                              .nextOrderCashback,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black),
                            ),
                          ],
                        ),
                      ),

                      //phone verification dection
                      if (userData != null &&
                          userData['user'] != null &&
                          !userData['user']['is_phone_number_verified'])
                        _verifyPhoneWidget(textTheme: textTheme),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 8)),

                      ///////actions section
                      Divider(
                        thickness: 2,
                        height: kDefaultPadding / 2,
                        color: kWhiteColor,
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 4)),

                      if (userData != null)
                        _userActionCard(
                          textTheme: textTheme,
                          title: "Actions",
                          children: [
                            ProfileListTile(
                              borderColor: kWhiteColor,
                              icon: Icon(
                                HeroiconsOutline.wallet,
                              ),
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .wallet,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BorsaScreen(userData: userData),
                                  ),
                                ).then((value) => getUser());
                              },
                            ),
                            // Divider(
                            //   height: 2,
                            //   color: kWhiteColor,
                            // ),
                            ProfileListTile(
                              borderColor: kWhiteColor,
                              icon: Icon(
                                HeroiconsOutline.share,
                              ),
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .referralCode,
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ReferralScreen(
                                            referralCode: userData['user']
                                                ['referral_code'])));
                              },
                            ),
                            // Divider(
                            //   height: 2,
                            //   color: kWhiteColor,
                            // ),
                            ProfileListTile(
                              borderColor: kWhiteColor,
                              icon: Icon(
                                HeroiconsOutline.questionMarkCircle,
                              ),
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .help,
                              onTap: () {
                                Navigator.pushNamed(
                                    context, HelpScreen.routeName);
                              },
                            ),
                          ],
                        ),

                      // ProfileListTile(
                      //   icon: Icon(
                      //     Icons.credit_card,
                      //     color: kSecondaryColor,
                      //   ),
                      //   title: Provider.of<ZLanguage>(context, listen: false).ettaCard,
                      //   press: () {
                      //     Navigator.of(context).push(MaterialPageRoute(builder: (context){
                      //       return LoyaltyCardScreen();
                      //     }));
                      //   },
                      // ),
                      // SizedBox(height: 1),
                      // ProfileListTile(
                      //   icon: Icon(
                      //     Icons.language,
                      //     color: kSecondaryColor,
                      //   ),
                      //   title: Provider.of<ZLanguage>(context, listen: false)
                      //       .language,
                      //   press: () {
                      //     Navigator.pushNamed(context, SubscribeScreen.routeName);
                      //   },
                      // ),
                      if (userData != null)
                        Divider(
                          thickness: 2,
                          height: kDefaultPadding / 2,
                          color: kWhiteColor,
                        ),

                      if (userData != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: kDefaultPadding / 2),
                          child: _userActionCard(
                            title: "Security",
                            textTheme: textTheme,
                            children: [
                              ProfileListTile(
                                showTrailing: false,
                                borderColor: kWhiteColor,
                                icon: Icon(
                                  HeroiconsOutline.arrowLeftStartOnRectangle,
                                ),
                                title: Provider.of<ZLanguage>(context,
                                        listen: false)
                                    .logout,
                                onTap: () {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  _showDialog();
                                },
                              ),
                              ProfileListTile(
                                showTrailing: false,
                                borderColor: kWhiteColor,
                                titleColor: kSecondaryColor,
                                icon: Icon(
                                  HeroiconsOutline.trash,
                                ),
                                title: "Delete Account?",
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: kPrimaryColor,
                                        title: Text("Delete User Account"),
                                        content: Text(
                                            "Are you sure you want to delete your account? Once you delete your account you will be able to reactivate within 30 days."),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text(
                                              "Think about it!",
                                              style: TextStyle(
                                                color: kSecondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              setState(() {
                                                isLoading = false;
                                              });
                                            },
                                          ),
                                          TextButton(
                                            child: Text(
                                              Provider.of<ZLanguage>(context,
                                                      listen: false)
                                                  .submit,
                                              style:
                                                  TextStyle(color: kBlackColor),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              deleteUser();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      if (userData == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding,
                              vertical: kDefaultPadding),
                          child: Column(
                            spacing: kDefaultPadding,
                            children: [
                              // ProfileListTile(
                              //     borderColor: kWhiteColor,
                              //     showTrailing: false,
                              //     icon: Icon(
                              //       HeroiconsOutline.arrowLeftEndOnRectangle,
                              //     ),
                              //     title: Provider.of<ZLanguage>(context,
                              //             listen: false)
                              //         .login,
                              //     onTap: () {
                              //       Navigator.push(
                              //         context,
                              //         MaterialPageRoute(
                              //           builder: (context) => LoginScreen(
                              //             firstRoute: false,
                              //           ),
                              //         ),
                              //       ).then((value) => getUser());
                              //     }),
                              // Divider(
                              //   thickness: 2,
                              //   height: kDefaultPadding / 2,
                              //   color: kWhiteColor,
                              // ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: kDefaultPadding,
                                    vertical: kDefaultPadding / 2),
                                decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    border: Border.all(color: kWhiteColor),
                                    borderRadius:
                                        BorderRadius.circular(kDefaultPadding)),
                                child: Column(
                                  spacing: kDefaultPadding / 4,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Support",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _actionCards(
                                          onTap: () {
                                            launchUrl(Uri(
                                                scheme: 'tel',
                                                path: '+251967575757'));
                                          },
                                          icon: HeroiconsOutline.phone,
                                          title: "Call Now",
                                        ),
                                        _actionCards(
                                          onTap: () {
                                            launchUrl(Uri(
                                                scheme: 'mailto',
                                                path: "info@zmallshop.com"));
                                            // launch("mailto:info@zmallshop.com");
                                          },
                                          icon: HeroiconsOutline.envelope,
                                          title: "E-Mail",
                                        ),
                                        _actionCards(
                                          onTap: () {
                                            // launch("tel:+2518707");
                                            launchUrl(Uri(
                                                scheme: 'tel',
                                                path: '+2518707'));
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
                              //   borderColor: kWhiteColor,
                              //   icon: Icon(
                              //     HeroiconsOutline.questionMarkCircle,
                              //   ),
                              //   title:
                              //       Provider.of<ZLanguage>(context, listen: false)
                              //           .help,
                              //   onTap: () {
                              //     Navigator.pushNamed(
                              //         context, HelpScreen.routeName);
                              //   },
                              // ),

                              ProfileListTile(
                                borderColor: kWhiteColor,
                                icon: Icon(
                                  // Icons.lock,
                                  HeroiconsOutline.shieldCheck,
                                  // color: kSecondaryColor,
                                ),
                                title: "Privacy Policy",
                                onTap: () {
                                  Service.launchInWebViewOrVC(
                                      "https://app.zmallshop.com/terms.html");
                                },
                              ),

                              ProfileListTile(
                                borderColor: kWhiteColor,
                                icon: Icon(
                                  HeroiconsOutline.clipboardDocumentCheck,
                                  // Icons.assignment,
                                  // color: kSecondaryColor,
                                ),
                                title: "Terms and Conditions",
                                onTap: () {
                                  Service.launchInWebViewOrVC(
                                      "https://app.zmallshop.com/terms.html");
                                },
                              ),
                              ProfileListTile(
                                borderColor: kWhiteColor,
                                icon: Icon(
                                  FontAwesomeIcons.instagram,
                                  // color: kSecondaryColor,
                                ),
                                title: "Follow us on Instagram",
                                onTap: () {
                                  Service.launchInWebViewOrVC(
                                      "https://www.instagram.com/zmall_delivery/?hl=en");
                                },
                              ),
                              ProfileListTile(
                                borderColor: kWhiteColor,
                                icon: Icon(
                                  Icons.facebook_outlined,
                                  // color: kSecondaryColor,
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

                      // TextButton(
                      //     onPressed: () {
                      //       showDialog(
                      //         context: context,
                      //         builder: (BuildContext context) {
                      //           return AlertDialog(
                      //             backgroundColor: kPrimaryColor,
                      //             title: Text("Delete User Account"),
                      //             content: Text(
                      //                 "Are you sure you want to delete your account? Once you delete your account you will be able to reactivate within 30 days."),
                      //             actions: <Widget>[
                      //               TextButton(
                      //                 child: Text(
                      //                   "Think about it!",
                      //                   style: TextStyle(
                      //                     color: kSecondaryColor,
                      //                     fontWeight: FontWeight.bold,
                      //                   ),
                      //                 ),
                      //                 onPressed: () {
                      //                   Navigator.of(context).pop();
                      //                   setState(() {
                      //                     isLoading = false;
                      //                   });
                      //                 },
                      //               ),
                      //               TextButton(
                      //                 child: Text(
                      //                   Provider.of<ZLanguage>(context,
                      //                           listen: false)
                      //                       .submit,
                      //                   style: TextStyle(color: kBlackColor),
                      //                 ),
                      //                 onPressed: () {
                      //                   Navigator.of(context).pop();
                      //                   deleteUser();
                      //                 },
                      //               ),
                      //             ],
                      //           );
                      //         },
                      //       );
                      //     },
                      //     child: Text(
                      //       "Delete Account?",
                      //       style:
                      //           Theme.of(context).textTheme.bodySmall?.copyWith(
                      //                 color: kGreyColor,
                      //               ),
                      //     )),
                      // isLoading
                      //     ? SpinKitWave(
                      //         color: kSecondaryColor,
                      //         size: getProportionateScreenWidth(kDefaultPadding),
                      //       )
                      //     : Padding(
                      //         padding: EdgeInsets.symmetric(
                      //             horizontal: getProportionateScreenWidth(
                      //                 kDefaultPadding)),
                      //         child: CustomButton(
                      //           title:
                      //               Provider.of<ZLanguage>(context, listen: false)
                      //                   .logout,
                      //           press: () {
                      //             setState(() {
                      //               isLoading = true;
                      //             });
                      //             _showDialog();
                      //           },
                      //           color: kSecondaryColor,
                      //         ),
                      //       ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        // : Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Spacer(flex: 1),
        //       Container(
        //         child: Center(
        //           child: Image.asset('images/login.png'),
        //         ),
        //       ),
        //       Spacer(flex: 1),
        //       Padding(
        //         padding: EdgeInsets.symmetric(
        //             horizontal: getProportionateScreenWidth(kDefaultPadding)),
        //         child: CustomButton(
        //           title: "LOGIN",
        //           press: () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (context) => LoginScreen(
        //                   firstRoute: false,
        //                 ),
        //               ),
        //             ).then((value) => getUser());
        //           },
        //           color: kSecondaryColor,
        //         ),
        //       ),
        //       Spacer(
        //         flex: 2,
        //       ),
        //     ],
        //   ),
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
              child: Icon(
                icon,
                size: 20,
                color: kBlackColor,
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

  Widget _userActionCard({
    required String title,
    required TextTheme textTheme,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
      child: Column(
        spacing: kDefaultPadding,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
          Column(spacing: kDefaultPadding / 2, children: children),
        ],
      ),
    );
  }

  Widget userInfoCard(
      {required String title, required String value, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
      decoration: BoxDecoration(
          // color: kWhiteColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5)),
      child: Column(
        spacing: kDefaultPadding / 4,
        children: [
          // Icon(
          //   icon,
          //   size: 18,
          //   color: kSecondaryColor,
          // ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget userInfo() {
    return Container(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                userInfoCard(
                  icon: HeroiconsOutline.wallet,
                  value: userData != null
                      ? "${userData['user']['wallet'].toStringAsFixed(2)}"
                      : "0.0",
                  title: Provider.of<ZLanguage>(context, listen: false).wallet,
                ),
                Container(
                  width: 2,
                  height: kDefaultPadding * 2,
                  color: kWhiteColor,
                ),
                userInfoCard(
                    icon: HeroiconsOutline.share,
                    value: userData != null
                        ? userData['user']['order_count'].toString()
                        : "0",
                    title:
                        "${Provider.of<ZLanguage>(context, listen: false).total} Orders"),
                Container(
                  width: 2,
                  height: kDefaultPadding * 2,
                  color: kWhiteColor,
                ),
                userInfoCard(
                  icon: HeroiconsOutline.share,
                  value: userData != null
                      ? "${userData['user']['total_referrals']}"
                      : "0",
                  title:
                      Provider.of<ZLanguage>(context, listen: false).referral,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
              child: Divider(color: kWhiteColor, thickness: 2),
            )
          ],
        ),
      ),
    );
  }

  Widget _verifyPhoneWidget({
    required TextTheme textTheme,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
      // margin: EdgeInsets.only(top: kDefaultPadding),
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
      decoration: BoxDecoration(
        color: kSecondaryColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(color: kSecondaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: kSecondaryColor),
          SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Verification',
                  style: textTheme.labelLarge,
                ),
                Text(
                  'Your phone number is not verified. Verify now to access all features.',
                  style: textTheme.labelSmall,
                ),
              ],
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
          TextButton(
            onPressed: () {
              _verifyBottomSheet();
            },
            style: TextButton.styleFrom(
              backgroundColor: kSecondaryColor.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
                vertical: getProportionateScreenHeight(kDefaultPadding / 4),
              ),
            ),
            child: Text(
              'Verify Now',
              style: textTheme.labelSmall!.copyWith(color: kPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _verifyBottomSheet() {
    var isOTPSend = false;
    String errorMessage = '';
    TextEditingController otpController = TextEditingController();
    var _password;

    showModalBottomSheet(
        context: context,
        backgroundColor: kPrimaryColor,
        builder: (builder) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Container(
              // color: kPrimaryColor,
              padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding * 1.5),
              child: SafeArea(
                  child: Column(
                spacing: kDefaultPadding,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Phone Number Verification",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          // style: IconButton.styleFrom(
                          //     backgroundColor: kWhiteColor),
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: kBlackColor,
                          ))
                    ],
                  ),
                  Text("Please enter your password to continue"),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 4),
                  ),
                  CustomTextField(
                    onChanged: (val) {
                      _password = val;
                      // print("/> $_password");
                    },
                    labelText: "Password",
                    hintText: "Enter your password",
                  ),
                  if (isOTPSend)
                    CustomTextField(
                      controller: otpController,
                      onChanged: (val) {
                        verificationCode = val;
                      },
                      labelText: "OTP",
                      hintText: "Enter the OTP",
                    ),
                  !isOTPSend
                      ? CustomButton(
                          // isLoading: isLoading,
                          title: "Submit",
                          color: kSecondaryColor,
                          press: () async {
                            generateOtpAtLogin(
                                    phone: userData['user']['phone'],
                                    password: _password)
                                .then((result) {
                              if (result == true) {
                                setState(() {
                                  isOTPSend = true;
                                });
                              }
                            });

                            // },
                            // );
                          })
                      : CustomButton(
                          title: "Verify",
                          // isLoading: isLoading,
                          color: kSecondaryColor,
                          press: () async {
                            _verifyOTP(
                              code: verificationCode,
                              phone: userData['user']['phone'],
                            ).then((result) async {
                              if (result == true) {
                                await verificationPhone().then((value) {
                                  if (value != null && value['success']) {
                                    getUser();
                                    Navigator.of(context).pop();
                                    MyApp.analytics
                                        .logEvent(name: 'user_phone_verified');
                                    Service.showMessage(
                                        context: context,
                                        title:
                                            "Phone number verified successfully.",
                                        error: false);
                                  }
                                });

                                ////
                              } else {
                                setState(() {
                                  errorMessage =
                                      "Your OTP is incorrect or no longer valid. Please try again.";
                                });
                              }
                            });
                          }),
                  errorMessage.isNotEmpty ? Text(errorMessage) : Container(),
                ],
              )),
            );
          });
        });
    // },
    // child: Text(
    //   "Verify Phone?",
    //   style: Theme.of(context)
    //       .textTheme
    //       .bodySmall
    //       ?.copyWith(color: kSecondaryColor),
    // ),
    // );
  }
  // Profile header with avatar and verification badge
  // Row(
  //   spacing: kDefaultPadding,
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: [
  //     // Profile avatar with status indicator
  //     Stack(
  //       children: [
  //         Container(
  //           width: screenHeight * 0.08,
  //           height: screenHeight * 0.08,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             border:
  //                 Border.all(color: kWhiteColor, width: 3),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.2),
  //                 blurRadius: 10,
  //                 spreadRadius: 2,
  //               ),
  //             ],
  //           ),
  //           child: ClipRRect(
  //             borderRadius: BorderRadius.circular(100),
  //             child: Container(
  //               color: kWhiteColor,
  //               child: Icon(
  //                 HeroiconsSolid.user,
  //                 size: 50,
  //                 color: kSecondaryColor,
  //               ),
  //             ),
  //           ),
  //         ),
  //         if (pData != null && pData['is_approved'])
  //           Positioned(
  //             bottom: 0,
  //             right: 0,
  //             child: Container(
  //               padding: EdgeInsets.all(2),
  //               decoration: BoxDecoration(
  //                 color: kWhiteColor,
  //                 shape: BoxShape.circle,
  //                 border: Border.all(
  //                     color: kWhiteColor, width: 2),
  //               ),
  //               child: Icon(
  //                 HeroiconsSolid.checkBadge,
  //                 size: 16,
  //                 color: kGreenColor,
  //               ),
  //             ),
  //           ),
  //       ],
  //     ),

  //     // User info
  //     Expanded(
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           if (pData != null)
  //             Row(
  //               mainAxisAlignment:
  //                   MainAxisAlignment.spaceBetween,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Expanded(
  //                   child: Text(
  //                     "${pData['first_name']} ${pData['last_name']}",
  //                     style: TextStyle(
  //                       fontSize: 22,
  //                       fontWeight: FontWeight.bold,
  //                       color: kPrimaryColor,
  //                     ),
  //                   ),
  //                 ),
  //                 Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Container(
  //                       width: 10,
  //                       height: 10,
  //                       decoration: BoxDecoration(
  //                         shape: BoxShape.circle,
  //                         color: pData['is_online']
  //                             ? kGreenColor
  //                             : kErrorColor,
  //                       ),
  //                     ),
  //                     SizedBox(width: 8),
  //                     Text(
  //                       pData['is_online']
  //                           ? "Online"
  //                           : "Offline",
  //                       style: TextStyle(
  //                         color: pData['is_online']
  //                             ? kGreenColor
  //                             : kErrorColor,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           //phoen section
  //           SizedBox(height: 8),
  //           if (pData != null)
  //             Row(
  //               children: [
  //                 Icon(HeroiconsOutline.phone,
  //                     size: 16,
  //                     color:
  //                         kWhiteColor.withValues(alpha: 0.8)),
  //                 SizedBox(width: 4),
  //                 Expanded(
  //                   child: Text(
  //                     "+251 ${pData['phone']}",
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       color: kPrimaryColor.withValues(
  //                           alpha: 0.8),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           SizedBox(height: 5),
  //           //email section
  //           if (pData != null)
  //             Row(
  //               children: [
  //                 Icon(HeroiconsOutline.envelope,
  //                     size: 16,
  //                     color:
  //                         kWhiteColor.withValues(alpha: 0.8)),
  //                 SizedBox(width: 4),
  //                 Expanded(
  //                   child: Text(
  //                     pData['email'],
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       color: kPrimaryColor.withValues(
  //                           alpha: 0.8),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           SizedBox(
  //             height: kDefaultPadding / 2,
  //           ),
  //           // Edit profile button
  //           InkWell(
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                     builder: (context) => const Profile()),
  //               );
  //             },
  //             child: Container(
  //               padding: EdgeInsets.symmetric(
  //                   horizontal: 16, vertical: 8),
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(12),
  //                 color: kWhiteColor,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color:
  //                         Colors.black.withValues(alpha: 0.1),
  //                     blurRadius: 5,
  //                     offset: Offset(0, 2),
  //                   ),
  //                 ],
  //               ),
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Icon(
  //                     HeroiconsOutline.pencilSquare,
  //                     size: 20,
  //                     color: kSecondaryColor,
  //                   ),
  //                   SizedBox(width: kDefaultPadding),
  //                   Text(
  //                     "Edit Profile",
  //                     style: TextStyle(
  //                       color: kSecondaryColor,
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   ],
  // ),
  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kPrimaryColor,
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Think about it!",
                style: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isLoading = false;
                });
              },
            ),
            TextButton(
              child: Text(
                "Sure",
                style: TextStyle(color: kBlackColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                logOut();
              },
            ),
          ],
        );
      },
    );
  }

/////////////////new phone verification///////////////////////
  Future<bool> generateOtpAtLogin(
      {required String phone, required String password}) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/generate_otp_at_login";
    setState(() {
      isLoading = true;
    });
    try {
      Map data = {
        "phone": phone,
        "password": password,
      };
      var body = json.encode(data);
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{"Content-Type": "application/json"},
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      // print("otp??? ${json.decode(response.body)}");
      // return json.decode(response.body);
      var newResponse = json.decode(response.body);
      if (newResponse != null &&
          (newResponse["success"] != null && newResponse["success"])) {
        Service.showMessage(
          context: context,
          title: "OTP code sent to your phone...",
          error: false,
        );
        return true;
      } else {
        Service.showMessage(
          context: context,
          error: true,
          title:
              "Failed to send an OTP. Please check your phone and password and try again.",
        );
        return false;
      }
    } catch (e) {
      // print(e);
      return false;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _verifyOTP({required String phone, required String code}) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/verify_otp";
    // String token = Uuid().v4();

    setState(() {
      isLoading = true;
    });

    Map data = {
      "code": code,
      "phone": phone,
    };
    var body = json.encode(data);

    try {
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      // print(json.decode(response.body));

      setState(() {
        responseData = json.decode(response.body);
      });
      return (responseData["success"] != null && responseData["success"])
          ? true
          : false;
    } catch (e) {
      // print(e);

      Service.showMessage(
        error: true,
        context: context,
        title: "Something went wrong! Please check your internet connection!",
      );
      return false;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  //////////////////////////////////

  Future<dynamic> signOut(String userId, String serverToken) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/logout";
    Map data = {
      "user_id": userId,
      "server_token": serverToken,
    };
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          Service.showMessage(
              context: context, title: "Network error", error: true);
          setState(() {
            isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      responseData = json.decode(response.body);
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  Future<dynamic> userDetails() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_detail";
    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
    };
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          Service.showMessage(
              context: context, title: "Network error", error: true);
          setState(() {
            isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  // Future<bool> sendOTP(phone, otp) async {
  //   // debugPrint("Sending code: $otp to $phone");
  //   http.Response? response = await verificationSms(phone, otp);
  //   if (response != null && response.statusCode == 200) {
  //     setState(() {
  //       otpSent = true;
  //     });
  //   }
  //   return otpSent;
  // }

  // Future<http.Response?> verificationSms(String phone, String otp) async {
  //   var url =
  //       "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/send_sms_with_message";
  //   String token = Uuid().v4();
  //   Map data = {
  //     "code": "${token}_zmall",
  //     "phone": phone,
  //     "message": "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ / OTP : $otp"
  //   };
  //   var body = json.encode(data);

  //   try {
  //     http.Response response = await http
  //         .post(
  //       Uri.parse(url),
  //       headers: <String, String>{"Content-Type": "application/json"},
  //       body: body,
  //     )
  //         .timeout(
  //       Duration(seconds: 10),
  //       onTimeout: () {
  //         throw TimeoutException("The connection has timed out!");
  //       },
  //     );
  //     setState(() {
  //       isLoading = false;
  //     });
  //     return response;
  //   } catch (e) {
  //     // debugPrint(e);
  //     return null;
  //   }
  // }

  Future<dynamic> verificationPhone() async {
    // debugPrint("Updating user data");
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/otp_verification";
    Map data = {
      "email": userData['user']['email'],
      "phone": userData['user']['phone'],
      "is_email_verified": true,
      "is_phone_number_verified": true,
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
    };
    var body = json.encode(data);

    try {
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{"Content-Type": "application/json"},
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        isLoading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }
}
