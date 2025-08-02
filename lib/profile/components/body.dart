import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
                Service.showMessage("Please verify your phone number!", true));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "You have successfully logged out!",
          style: TextStyle(color: kBlackColor),
        ),
        backgroundColor: kPrimaryColor,
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${errorCodes['${responseData['error_code']}']}"),
        backgroundColor: kSecondaryColor,
      ));
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
        ScaffoldMessenger.of(context).showSnackBar(
            Service.showMessage("User account successfully deleted.", true));
        await Service.saveBool('logged', false);
        await Service.remove('user');
        await Service.remove('cart');
        await Service.remove('aliexpressCart'); //NEW
        await Service.remove('images');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          errorCodes['${responseData['error_code']}'], true));
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
      body: userData != null
          ? SafeArea(
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
                                  color: kBlackColor,
                                  fontWeight: FontWeight.bold),
                        ),

                        //  textTheme.headlineSmall
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfile(
                                  userData: userData,
                                ),
                              ),
                            ).then((value) => getUser());
                          },
                          child: Text(
                            "Edit",
                            style: textTheme.titleMedium!.copyWith(
                                color: kSecondaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                  /////user info section///
                  Stack(children: [
                    ImageContainer(
                        width: 100,
                        height: 100,
                        url:
                            "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${userData['user']['image_url']}"),
                    if (userData['user'] != null &&
                        userData['user']['is_phone_number_verified'])
                      Positioned(
                        right: 2,
                        bottom: 4,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryColor,
                              border: BoxBorder.all(color: kWhiteColor)),
                          child: Icon(
                            Icons.verified_outlined,
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          ),
                        ),
                      )
                  ]),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                  Text(
                    "${userData['user']['first_name']} ${userData['user']['last_name']} ",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: kDefaultPadding,
                  ),

                  ///user contact section
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
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
                          frontColor: kSecondaryColor.withValues(alpha: 0.8),
                          icon: HeroiconsSolid.mapPin,
                          label: userData['user']['address'] ?? "Addis Ababa",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding)),
                  //user status section
                  userInfo(),
                  // SizedBox(
                  //     height:
                  //         getProportionateScreenHeight(kDefaultPadding / 2)),

                  /////
                  Expanded(
                    child: ListView(
                      children: [
                        /////user info section///
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding,
                              vertical: kDefaultPadding / 2),
                          child: Column(
                            spacing: kDefaultPadding / 2,
                            children: [
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
                                  "${quotient}0",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Text(
                                  "${quotient + 1}0",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                percent: (remainder / 10),
                              ),
                              Text(
                                isRewarded
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
                        if (userData['user'] != null &&
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kDefaultPadding,
                                  vertical: kDefaultPadding / 2),
                              child: Text(
                                "Actions",
                                style: textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ProfileListTile(
                              icon: Icon(
                                HeroiconsOutline.wallet,
                              ),
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .wallet,
                              press: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BorsaScreen(userData: userData),
                                  ),
                                ).then((value) => getUser());
                              },
                            ),
                            Divider(
                              height: 2,
                              color: kWhiteColor,
                            ),
                            ProfileListTile(
                              icon: Icon(
                                HeroiconsOutline.share,
                              ),
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .referralCode,
                              press: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ReferralScreen(
                                            referralCode: userData['user']
                                                ['referral_code'])));
                              },
                            ),
                            Divider(
                              height: 2,
                              color: kWhiteColor,
                            ),
                            ProfileListTile(
                              icon: Icon(
                                HeroiconsOutline.questionMarkCircle,
                              ),
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .help,
                              press: () {
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
                        Divider(
                          thickness: 2,
                          height: kDefaultPadding / 2,
                          color: kWhiteColor,
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: kDefaultPadding / 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: kDefaultPadding),
                                child: Text(
                                  "Security",
                                  style: textTheme.titleMedium!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ProfileListTile(
                                icon: Icon(
                                  HeroiconsOutline.arrowLeftStartOnRectangle,
                                ),
                                title: Provider.of<ZLanguage>(context,
                                        listen: false)
                                    .logout,
                                press: () {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  _showDialog();
                                },
                              ),
                              Divider(
                                height: 2,
                                color: kWhiteColor,
                              ),
                              ProfileListTile(
                                titleColor: kSecondaryColor,
                                icon: Icon(
                                  HeroiconsOutline.trash,
                                ),
                                title: "Delete Account?",
                                press: () {
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
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 1),
                Container(
                  child: Center(
                    child: Image.asset('images/login.png'),
                  ),
                ),
                Spacer(flex: 1),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding)),
                  child: CustomButton(
                    title: "LOGIN",
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(
                            firstRoute: false,
                          ),
                        ),
                      ).then((value) => getUser());
                    },
                    color: kSecondaryColor,
                  ),
                ),
                Spacer(
                  flex: 2,
                ),
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
                  value: "${userData['user']['wallet'].toStringAsFixed(2)}",
                  title: Provider.of<ZLanguage>(context, listen: false).wallet,
                ),
                Container(
                  width: 2,
                  height: kDefaultPadding * 2,
                  color: kWhiteColor,
                ),
                userInfoCard(
                    icon: HeroiconsOutline.share,
                    value: userData['user']['order_count'].toString(),
                    title:
                        "${Provider.of<ZLanguage>(context, listen: false).total} Orders"),
                Container(
                  width: 2,
                  height: kDefaultPadding * 2,
                  color: kWhiteColor,
                ),
                userInfoCard(
                  icon: HeroiconsOutline.share,
                  value: "${userData['user']['total_referrals']}",
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
                          style: IconButton.styleFrom(
                              backgroundColor: kWhiteColor),
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: kSecondaryColor,
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
                  isLoading
                      ? SpinKitThreeInOut()
                      : !isOTPSend
                          ? CustomButton(
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
                                        MyApp.analytics.logEvent(
                                            name: 'user_phone_verified');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Phone number verified successfully.",
                                                false));
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
        ScaffoldMessenger.of(context).showSnackBar(
            Service.showMessage("OTP code sent to your phone...", false));
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "Failed to send an OTP. Please check your phone and password and try again.",
            true));
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
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
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
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
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
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
