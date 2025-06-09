import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
import 'package:zmall/random_digits.dart';
import 'package:zmall/service.dart';
import 'package:zmall/constants.dart';
import 'package:flutter/material.dart';
import 'package:zmall/size_config.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:percent_indicator/percent_indicator.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
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
    // TODO: implement initState
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
    return Scaffold(
      backgroundColor: userData == null ? kPrimaryColor : kWhiteColor,
      body: Padding(
        padding: EdgeInsets.symmetric(
            // vertical: getProportionateScreenHeight(kDefaultPadding / 2),
            // horizontal: getProportionateScreenHeight(kDefaultPadding),
            ),
        child: userData != null
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        getProportionateScreenWidth(kDefaultPadding),
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                      ),
                      child: Column(
                        children: [
                          ImageContainer(
                              url:
                                  "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${userData['user']['image_url']}"),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${userData['user']['first_name']} ${userData['user']['last_name']} ",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              userData['user'] != null &&
                                      userData['user']
                                          ['is_phone_number_verified']
                                  ? Icon(
                                      Icons.verified_outlined,
                                      color: kSecondaryColor,
                                      size: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    )
                                  : Container(),
                            ],
                          ),
                          Text(
                            "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${userData['user']['phone']}",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          userData['user'] != null &&
                                  userData['user']['is_phone_number_verified']
                              ? Container()
                              : InkWell(
                                  onTap: () {
                                    if (otpSent) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                                "Phone Number Verification"),
                                            content: Wrap(
                                              children: [
                                                Text(
                                                    "Please enter the one time pin(OTP) sent to your phone.\n"),
                                                SizedBox(
                                                  height:
                                                      getProportionateScreenHeight(
                                                          kDefaultPadding),
                                                ),
                                                TextField(
                                                  style: TextStyle(
                                                      color: kBlackColor),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (val) {
                                                    verificationCode = val;
                                                  },
                                                  decoration:
                                                      textFieldInputDecorator
                                                          .copyWith(
                                                    labelText: "OTP",
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text(
                                                  "Verify",
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  if (otp == verificationCode) {
                                                    await verificationPhone()
                                                        .then((value) {
                                                      if (value != null &&
                                                          value['success']) {
                                                        getUser();
                                                        Navigator.of(context)
                                                            .pop();
                                                      }
                                                    });
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            Service.showMessage(
                                                                "Wrong OTP, please try again!",
                                                                true));
                                                  }
//                                                Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      otp = RandomDigits.getString(4);
                                      sendOTP("${Provider.of<ZMetaData>(context, listen: false).areaCode}${userData['user']['phone']}",
                                              otp)
                                          .then(
                                        (success) {
                                          if (success) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor:
                                                      kPrimaryColor,
                                                  title: Text(
                                                      "Phone Number Verification"),
                                                  content: Wrap(
                                                    children: [
                                                      Text(
                                                          "Please enter the one time pin(OTP) sent to your phone.\n"),
                                                      SizedBox(
                                                        height:
                                                            getProportionateScreenHeight(
                                                                kDefaultPadding),
                                                      ),
                                                      TextField(
                                                        style: TextStyle(
                                                            color: kBlackColor),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        onChanged: (val) {
                                                          verificationCode =
                                                              val;
                                                        },
                                                        decoration:
                                                            textFieldInputDecorator
                                                                .copyWith(
                                                          labelText: "OTP",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: Text(
                                                        "Verify",
                                                        style: TextStyle(
                                                          color:
                                                              kSecondaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        if (otp ==
                                                            verificationCode) {
                                                          await verificationPhone()
                                                              .then((value) {
                                                            if (value != null &&
                                                                value[
                                                                    'success']) {
                                                              getUser();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              MyApp.analytics
                                                                  .logEvent(
                                                                      name:
                                                                          'user_phone_verified');
                                                            }
                                                          });
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(Service
                                                                  .showMessage(
                                                                      "Wrong OTP, please try again!",
                                                                      true));
                                                        }
//                                                Navigator.of(context).pop();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(Service.showMessage(
                                                    "Something went wrong, please try again!",
                                                    true));
                                            setState(
                                              () {
                                                isLoading = false;
                                              },
                                            );
                                          }
                                        },
                                      );
                                    }
//                                    .then((value) => getUser());
                                  },
                                  child: Text(
                                    "Verify Phone?",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: kSecondaryColor),
                                  ),
                                ),
                          Text(
                            "${userData['user']['email']}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          // Text(
                          //   "${userData['user']['city']}",
                          //   style: Theme.of(context).textTheme.bodySmall,
                          // ),
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
                                Provider.of<ZLanguage>(context, listen: false)
                                    .edit),
                          ),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4)),
                          LinearPercentIndicator(
                            animation: true,
                            lineHeight: getProportionateScreenHeight(
                                kDefaultPadding * 0.9),
                            barRadius: Radius.circular(
                              getProportionateScreenWidth(kDefaultPadding / 2),
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
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4)),
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
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding * 0.6)),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      Provider.of<ZLanguage>(context,
                                              listen: false)
                                          .wallet,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      "${userData['user']['wallet'].toStringAsFixed(2)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    )
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      Provider.of<ZLanguage>(context,
                                              listen: false)
                                          .referral,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      "${userData['user']['total_referrals']}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    ProfileListTile(
                      icon: Icon(
                        Icons.assignment,
                        color: kSecondaryColor,
                      ),
                      title: Provider.of<ZLanguage>(context, listen: false)
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
                    SizedBox(height: 1),
                    ProfileListTile(
                      icon: Icon(
                        Icons.wallet,
                        color: kSecondaryColor,
                      ),
                      title:
                          Provider.of<ZLanguage>(context, listen: false).wallet,
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
                    SizedBox(height: 1),
                    ProfileListTile(
                      icon: Icon(
                        Icons.help,
                        color: kSecondaryColor,
                      ),
                      title:
                          Provider.of<ZLanguage>(context, listen: false).help,
                      press: () {
                        Navigator.pushNamed(context, HelpScreen.routeName);
                      },
                    ),
                    SizedBox(height: 1),
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
                    SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding)),
                    TextButton(
                        onPressed: () {
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
                                      style: TextStyle(color: kBlackColor),
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
                        child: Text(
                          "Delete Account?",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: kGreyColor,
                                  ),
                        )),
                    isLoading
                        ? SpinKitWave(
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding)),
                            child: CustomButton(
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .logout,
                              press: () {
                                setState(() {
                                  isLoading = true;
                                });
                                _showDialog();
                              },
                              color: kSecondaryColor,
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
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding)),
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
      ),
    );
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
      // print(e);
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
      // print(e);
      return null;
    }
  }

  Future<bool> sendOTP(phone, otp) async {
    // print("Sending code: $otp to $phone");
    http.Response? response = await verificationSms(phone, otp);
    if (response != null && response.statusCode == 200) {
      setState(() {
        otpSent = true;
      });
    }
    return otpSent;
  }

  Future<http.Response?> verificationSms(String phone, String otp) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/send_sms_with_message";
    String token = Uuid().v4();
    Map data = {
      "code": "${token}_zmall",
      "phone": phone,
      "message": "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ / OTP : $otp"
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
      return response;
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Future<dynamic> verificationPhone() async {
    // print("Updating user data");
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
      // print(e);
      return null;
    }
  }
}
