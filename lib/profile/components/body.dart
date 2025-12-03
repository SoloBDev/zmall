import 'dart:async';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/borsa/borsa_screen.dart';
import 'package:zmall/services/core_services.dart';
import 'package:zmall/help/help_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/profile/components/edit_profile.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/profile/components/referral_code.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/services/biometric_services/biometric_service.dart';
import 'package:zmall/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:zmall/models/biometric_credential.dart';
import 'package:zmall/services/biometric_services/biometric_credentials_manager.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/login/components/saved_accounts_bottom_sheet.dart';
import 'package:zmall/utils/tab_screen.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';

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

  // Biometric state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';

  // Saved accounts state
  int _savedAccountsCount = 0;

  @override
  void initState() {
    super.initState();
    getUser();
    _checkBiometricStatus();
    _loadSavedAccountsCount();
  }

  /// Load saved accounts count (excluding current account)
  Future<void> _loadSavedAccountsCount() async {
    final accounts = await BiometricCredentialsManager.getSavedAccounts();
    final currentPhone = userData != null ? userData['user']['phone'] : null;

    // Count only accounts that are NOT the current account
    final otherAccountsCount = currentPhone != null
        ? accounts.where((acc) => acc.phone != currentPhone).length
        : accounts.length;

    if (mounted) {
      setState(() {
        _savedAccountsCount = otherAccountsCount;
      });
    }
  }

  /// Check biometric availability and status
  void _checkBiometricStatus() async {
    final isAvailable = await BiometricService.isBiometricAvailable();
    final biometricName = await BiometricService.getBiometricTypeName();

    // Check if current user has biometric enabled in multi-account system
    bool isEnabled = false;
    if (userData != null && userData['user'] != null) {
      final phone = userData['user']['phone'];
      final account = await BiometricCredentialsManager.getAccount(phone);
      isEnabled = account?.biometricEnabled ?? false;
    }

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
        _biometricType = biometricName;
      });
    }
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null && mounted) {
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
        if (mounted) {
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

      // Clear biometric credentials and disable biometric on logout
      await Service.disableBiometric();

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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      userData['user']['_id'],
      true,
      userData['user']['user_type'],
      context,
    );
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
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Toggle biometric authentication
  Future<void> _toggleBiometric(bool value) async {
    final phone = userData['user']['phone'];
    final userName = userData['user']['name'];

    final result = await BiometricService.authenticate(
      localizedReason: 'Authenticate to disable $_biometricType login',
    );

    if (result.success) {
      await BiometricCredentialsManager.updateBiometricStatus(phone, value);
      // final account = await BiometricCredentialsManager.getAccount(phone);
      if (mounted) {
        setState(() {
          _isBiometricEnabled = value;
        });

        if (_isBiometricEnabled) {
          await BiometricCredentialsManager.updateUserName(phone, userName);
          await BiometricCredentialsManager.updateLastUsed(phone);
        }
      }
    }
  }

  /// Show switch account bottom sheet
  Future<void> _showSwitchAccountSheet() async {
    final currentPhone = userData != null ? userData['user']['phone'] : null;

    await showSavedAccountsBottomSheet(
      context: context,
      onAccountSelected: _switchToAccount,
      currentUserPhone: currentPhone,
    );

    // Reload account count in case user deleted an account
    await _loadSavedAccountsCount();
  }

  /// Switch to selected account
  Future<void> _switchToAccount(BiometricCredential account) async {
    try {
      // Check if switching to same account
      if (userData != null && userData['user']['phone'] == account.phone) {
        Navigator.of(context).pop(); // Dismiss bottom sheet
        Service.showMessage(
          context: context,
          title: "Already logged in as ${account.displayName}",
          error: false,
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: LinearLoadingIndicator(
              title: 'Switching account...',
              fontSize: 12,
            ),
          );
        },
      );

      // Step 1: Logout current user
      if (userData != null) {
        await signOut(
          userData['user']['_id'],
          userData['user']['server_token'],
        );
      }

      // Step 2: Clear current session data
      await Service.saveBool('logged', false);
      await Service.remove('user');
      await Service.remove('cart');
      await Service.remove('aliexpressCart');
      await Service.remove('images');
      await Service.remove('p_items');
      await Service.remove('s_items');

      // Step 3: Authenticate with biometric if enabled
      if (account.biometricEnabled) {
        final authResult = await BiometricService.authenticate(
          localizedReason: 'Authenticate to login as ${account.displayName}',
        );

        if (!authResult.success) {
          // Dismiss loading dialog
          if (mounted && context.mounted) {
            Navigator.of(context).pop();
          }

          if (authResult.errorMessage != null) {
            Service.showMessage(
              context: context,
              title: authResult.errorMessage!,
              error: true,
            );
          }

          // Navigate back to login screen
          if (mounted && context.mounted) {
            Navigator.pushReplacementNamed(context, LoginScreen.routeName);
          }
          return;
        }
      }

      // Step 4: Login to selected account
      final loginResponse = await Service.biometricLogin(
        phoneNumber: account.phone,
        password: account.password,
        context: context,
        appVersion: appVersion,
      );

      if (loginResponse != null && loginResponse['success']) {
        // Update last used timestamp
        await BiometricCredentialsManager.updateLastUsed(account.phone);

        // Save user data (Service.save will encode it)
        await Service.save('user', loginResponse);
        await Service.saveBool('logged', true);

        // Dismiss loading dialog and show success dialog
        if (mounted && context.mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog

          // Auto-dismiss after 1.5 seconds and navigate
          Future.delayed(Duration(milliseconds: 1000), () {
            if (mounted && context.mounted) {
              Navigator.of(context).pop(); // Dismiss success dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                TabScreen.routeName,
                (Route<dynamic> route) => false,
              );
            }
          });
          // Show success dialog (non-blocking)
          Service.showMessage(
            context: context,
            title: "Successfully Switched to ${account.displayName}!",
            error: false,
          );
        }
      } else {
        // Dismiss loading dialog
        if (mounted && context.mounted) {
          Navigator.of(context).pop();
        }

        Service.showMessage(
          context: context,
          title: "Failed to login. Please try again.",
          error: true,
        );

        // Navigate back to login screen
        if (mounted && context.mounted) {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      }
    } catch (e) {
      // print('Error switching account: $e');

      // Dismiss loading dialog
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }

      Service.showMessage(
        context: context,
        title: "Failed to switch account. Please try again.",
        error: true,
      );

      // Navigate back to login screen
      if (mounted && context.mounted) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      // backgroundColor: userData == null ? kPrimaryColor : kWhiteColor,
      backgroundColor: kPrimaryColor,
      body:
          // userData != null ?
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: getProportionateScreenHeight(kDefaultPadding),
              top: MediaQuery.of(context).padding.top + kDefaultPadding,
            ),
            child: Column(
              spacing: getProportionateScreenHeight(kDefaultPadding / 2),
              children: [
                //profile image
                // SizedBox(
                //   width: getProportionateScreenWidth(80),
                //   height: getProportionateScreenHeight(80),
                //   child: Stack(
                //     children: [
                //       ImageContainer(
                //         width: getProportionateScreenWidth(100),
                //         height: getProportionateScreenHeight(100),
                //         shape: BoxShape.circle,
                //         url: userData == null
                //             ? ''
                //             : "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${userData['user']['image_url']}",
                //       ),
                //       // if (userData != null &&
                //       //     userData['user'] != null &&
                //       //     userData['user']['is_phone_number_verified'])
                //       //   Positioned(
                //       //     right: 4,
                //       //     bottom: 4,
                //       //     child: Container(
                //       //       decoration: BoxDecoration(
                //       //         shape: BoxShape.circle,
                //       //         color: kWhiteColor,
                //       //       ),
                //       //       child: Icon(
                //       //         HeroiconsSolid.checkBadge,
                //       //         color: kSecondaryColor,
                //       //         size: getProportionateScreenHeight(17),
                //       //       ),
                //       //     ),
                //       //   ),
                //     ],
                //   ),
                // ),
                ImageContainer(
                  width: getProportionateScreenWidth(90),
                  height: getProportionateScreenHeight(90),
                  shape: BoxShape.circle,
                  url: userData == null
                      ? ''
                      : "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${userData['user']['image_url']}",
                ),
                //user profile and edit icon
                userData != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: getProportionateScreenWidth(kDefaultPadding),
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${userData['user']['first_name']} ${userData['user']['last_name']} ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (userData != null &&
                                      userData['user'] != null &&
                                      userData['user']['is_phone_number_verified'])
                                    Icon(
                                      HeroiconsSolid.checkBadge,
                                      color: kSecondaryColor,
                                      size: getProportionateScreenHeight(17),
                                    ),
                                ],
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 4,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                spacing: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${userData['user']['phone']}",
                                      ),
                                      Text(
                                        "${userData['user']['email']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfile(userData: userData),
                                        ),
                                      ).then((value) => getUser());
                                    },
                                    child: Icon(
                                      size: 20,
                                      color: kBlackColor,
                                      HeroiconsOutline.pencilSquare,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(
                        "Guest User",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                //user info card
                Column(
                  children: [
                    userInfo(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(
                          kDefaultPadding,
                        ),
                        vertical: getProportionateScreenHeight(
                          kDefaultPadding / 2,
                        ),
                      ),
                      child: LinearPercentIndicator(
                        animation: true,
                        lineHeight: getProportionateScreenHeight(
                          kDefaultPadding * 0.9,
                        ),
                        barRadius: Radius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        backgroundColor: kWhiteColor,
                        progressColor: kSecondaryColor,
                        leading: Text(
                          userData != null ? "${quotient}0" : "00",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          userData != null ? "${quotient + 1}0" : "10",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        percent: userData != null ? (remainder / 10) : 0.1,
                      ),
                    ),
                    Text(
                      userData == null
                          // ? "Log in now and enjoy delivery cashbacks!"
                          ? "Log in for your chance to win delivery cashbacks on lucky orders!"
                          : isRewarded
                          ? "${Provider.of<ZLanguage>(context, listen: true).youAre} 9 ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                          : (10 - remainder) != 1
                          ? "${Provider.of<ZLanguage>(context, listen: true).youAre} ${10 - remainder} ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                          : Provider.of<ZLanguage>(
                              context,
                              listen: true,
                            ).nextOrderCashback,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black),
                    ),
                  ],
                ),

                //phone verification dection
                if (userData != null &&
                    userData['user'] != null &&
                    !userData['user']['is_phone_number_verified'])
                  _verifyPhoneWidget(textTheme: textTheme),

                if (userData != null)
                  _userActionCard(
                    textTheme: textTheme,
                    title: "Account",
                    children: [
                      // 1. Financial Section
                      ProfileListTile(
                        borderColor: kWhiteColor,
                        icon: Icon(HeroiconsOutline.wallet),
                        title: Provider.of<ZLanguage>(
                          context,
                          listen: false,
                        ).wallet,
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

                      // 2. Security Section
                      if (_isBiometricAvailable)
                        ProfileListTile(
                          borderColor: kWhiteColor,
                          icon: const Icon(HeroiconsOutline.fingerPrint),
                          title: "Biometric Login",
                          onTap: () {},
                          trailing: Switch(
                            value: _isBiometricEnabled,
                            onChanged: (value) async {
                              await _toggleBiometric(value);
                            },
                            activeTrackColor: kSecondaryColor,
                          ),
                          margin: EdgeInsets.only(
                            top: getProportionateScreenHeight(
                              kDefaultPadding / 2,
                            ),
                            bottom: getProportionateScreenHeight(
                              // _savedAccountsCount > 0 ? kDefaultPadding / 2 : 0),
                              _savedAccountsCount > 0 ? 0 : kDefaultPadding / 2,
                            ),
                          ),
                        ),
                      if (_savedAccountsCount > 0)
                        ProfileListTile(
                          borderColor: kWhiteColor,
                          icon: Icon(HeroiconsOutline.arrowsRightLeft),
                          margin: EdgeInsets.only(
                            bottom: getProportionateScreenHeight(
                              kDefaultPadding / 2,
                            ),
                          ),
                          title: "Switch Account",
                          onTap: _showSwitchAccountSheet,
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kSecondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_savedAccountsCount',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kWhiteColor,
                              ),
                            ),
                          ),
                        ),

                      // 3. Promotional Section
                      ProfileListTile(
                        borderColor: kWhiteColor,
                        icon: Icon(HeroiconsOutline.share),
                        title: Provider.of<ZLanguage>(
                          context,
                          listen: false,
                        ).referralCode,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReferralScreen(
                                referralCode: userData['user']['referral_code'],
                              ),
                            ),
                          );
                        },
                      ),

                      // 4. Support Section
                      ProfileListTile(
                        borderColor: kWhiteColor,
                        icon: Icon(HeroiconsOutline.questionMarkCircle),
                        title:
                            "${Provider.of<ZLanguage>(context, listen: false).help} & Support",
                        onTap: () {
                          Navigator.pushNamed(context, HelpScreen.routeName);
                        },
                        // margin: EdgeInsets.only(
                        //   bottom: getProportionateScreenHeight(kDefaultPadding),
                        // ),
                      ),
                      // Chat bot
                      // chatBot(
                      //   userId: userData["user"]["_id"],
                      //   serverToken: userData["user"]["server_token"],
                      // ),
                      // 5. Account Management Section
                      ProfileListTile(
                        showTrailing: false,
                        borderColor: kWhiteColor,
                        icon: Icon(HeroiconsOutline.arrowLeftStartOnRectangle),
                        title: Provider.of<ZLanguage>(
                          context,
                          listen: false,
                        ).logout,
                        onTap: () {
                          setState(() {
                            isLoading = true;
                          });
                          _showDialog();
                        },
                        margin: EdgeInsets.only(
                          top: getProportionateScreenHeight(kDefaultPadding),
                        ),
                      ),
                      ProfileListTile(
                        showTrailing: false,
                        borderColor: kWhiteColor,
                        titleColor: kSecondaryColor,
                        icon: Icon(HeroiconsOutline.trash),
                        title: "Delete Account?",
                        margin: EdgeInsets.only(
                          bottom: getProportionateScreenHeight(
                            kDefaultPadding / 2,
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: kPrimaryColor,
                                title: Text("Delete User Account"),
                                content: Text(
                                  "Are you sure you want to delete your account? Once you delete your account you will be able to reactivate within 30 days.",
                                ),
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
                                      Provider.of<ZLanguage>(
                                        context,
                                        listen: false,
                                      ).submit,
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
                      ),
                    ],
                  ),

                //Guest user section
                if (userData == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding,
                      vertical: kDefaultPadding,
                    ),
                    child: Column(
                      spacing: kDefaultPadding,
                      children: [
                        // 1. Authentication Section
                        ProfileListTile(
                          borderColor: kWhiteColor,
                          icon: Icon(HeroiconsOutline.arrowLeftEndOnRectangle),
                          title: Provider.of<ZLanguage>(
                            context,
                            listen: false,
                          ).login,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LoginScreen(firstRoute: false),
                              ),
                            ).then((value) => getUser());
                          },
                        ),

                        // 2. Support Section
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: kDefaultPadding,
                            vertical: kDefaultPadding / 2,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(color: kWhiteColor),
                            borderRadius: BorderRadius.circular(
                              kDefaultPadding,
                            ),
                          ),
                          child: Column(
                            spacing: kDefaultPadding / 4,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quick Support",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _actionCards(
                                    onTap: () {
                                      launchUrl(
                                        Uri(
                                          scheme: 'tel',
                                          path: '+251967575757',
                                        ),
                                      );
                                    },
                                    icon: HeroiconsOutline.phone,
                                    title: "Call Now",
                                  ),
                                  _actionCards(
                                    onTap: () {
                                      launchUrl(
                                        Uri(
                                          scheme: 'mailto',
                                          path: "info@zmallshop.com",
                                        ),
                                      );
                                    },
                                    icon: HeroiconsOutline.envelope,
                                    title: "E-Mail",
                                  ),
                                  _actionCards(
                                    onTap: () {
                                      launchUrl(
                                        Uri(scheme: 'tel', path: '+2518707'),
                                      );
                                    },
                                    icon: Icons.support_agent,
                                    title: "Call HOTLINE",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 3. Support Section
                        ProfileListTile(
                          borderColor: kWhiteColor,
                          icon: Icon(HeroiconsOutline.questionMarkCircle),
                          title:
                              "${Provider.of<ZLanguage>(context, listen: false).help} & Support",
                          onTap: () {
                            Navigator.pushNamed(context, HelpScreen.routeName);
                          },
                        ),
                        // // Legal Section
                        // ProfileListTile(
                        //   borderColor: kWhiteColor,
                        //   icon: Icon(HeroiconsOutline.shieldCheck),
                        //   title: "Privacy Policy",
                        //   onTap: () {
                        //     Service.launchInWebViewOrVC(
                        //         "https://app.zmallshop.com/terms.html");
                        //   },
                        // ),
                        // ProfileListTile(
                        //   borderColor: kWhiteColor,
                        //   icon: Icon(HeroiconsOutline.clipboardDocumentCheck),
                        //   title: "Terms and Conditions",
                        //   onTap: () {
                        //     Service.launchInWebViewOrVC(
                        //         "https://app.zmallshop.com/terms.html");
                        //   },
                        // ),

                        // // Social Media Section
                        // ProfileListTile(
                        //   borderColor: kWhiteColor,
                        //   icon: Icon(FontAwesomeIcons.instagram),
                        //   title: "Follow us on Instagram",
                        //   onTap: () {
                        //     Service.launchInWebViewOrVC(
                        //         "https://www.instagram.com/zmall_delivery/?hl=en");
                        //   },
                        // ),
                        // ProfileListTile(
                        //   borderColor: kWhiteColor,
                        //   icon: Icon(Icons.facebook_outlined),
                        //   title: "Follow us on Facebook",
                        //   onTap: () {
                        //     Service.launchInWebViewOrVC(
                        //         "https://www.facebook.com/Zmallshop/");
                        //   },
                        // ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  // Chat Support Button
  Widget chatBot({
    required String userId,
    required String serverToken,
    // required String orderId,
    // required List userLocation,
  }) {
    final userLat = Provider.of<ZMetaData>(context, listen: false).latitude;
    final userLng = Provider.of<ZMetaData>(context, listen: false).longitude;
    return InkWell(
      onTap: () {
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) {
        //       return SupportChatScreen(
        //         userId: userId,
        //         userData: userData,
        //         serverToken: serverToken,
        //         userLocation: ["$userLat", "$userLng"],
        //       );
        //     },
        //   ),
        // );
        // Navigator.pushNamed(context, SupportChatScreen.routeName);
      },
      borderRadius: BorderRadius.circular(kDefaultPadding),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding),
          vertical: getProportionateScreenHeight(kDefaultPadding),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kSecondaryColor, kSecondaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(kDefaultPadding),
          // boxShadow: [
          //   BoxShadow(
          //     color: kSecondaryColor.withValues(alpha: 0.3),
          //     blurRadius: 12,
          //     offset: Offset(0, 4),
          //   ),
          // ],
        ),
        child: Row(
          children: [
            Container(
              width: getProportionateScreenWidth(50),
              height: getProportionateScreenWidth(50),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.robot,
                  color: kPrimaryColor,
                  size: getProportionateScreenWidth(24),
                ),
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Chatbot Assistant",
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(16),
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "24/7 AI support • Always available",
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(12),
                      color: kPrimaryColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              HeroiconsSolid.chevronRight,
              color: kPrimaryColor,
              size: getProportionateScreenWidth(20),
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
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding,
        ),
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
              child: Icon(icon, size: 20, color: kBlackColor),
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
    double? spacing,
  }) {
    return Container(
      // margin: EdgeInsets.symmetric(
      //     horizontal: getProportionateScreenWidth(kDefaultPadding),
      //     vertical: getProportionateScreenHeight(kDefaultPadding / 4)),
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
        vertical: getProportionateScreenHeight(kDefaultPadding / 2),
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        // border: Border.all(color: kWhiteColor),
        // borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Column(
        spacing: spacing ?? getProportionateScreenHeight(kDefaultPadding / 2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
        // children: [
        //   // Text(
        //   //   title,
        //   //   style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        //   // ),
        //   ...children,
        // ],
      ),
    );
  }

  Widget userInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        // color: kWhiteColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      ),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget userInfo() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      "${Provider.of<ZLanguage>(context, listen: false).total} Orders",
                ),
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
                  title: Provider.of<ZLanguage>(
                    context,
                    listen: false,
                  ).referral,
                ),
              ],
            ),
            Divider(color: kWhiteColor, thickness: 2),
          ],
        ),
      ),
    );
  }

  Widget _verifyPhoneWidget({required TextTheme textTheme}) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
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
                Text('Phone Verification', style: textTheme.labelLarge),
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
      isScrollControlled: true,
      backgroundColor: kPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (builder) {
        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: getProportionateScreenWidth(kDefaultPadding),
                right: getProportionateScreenWidth(kDefaultPadding),
                top: getProportionateScreenHeight(kDefaultPadding / 2),
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    kDefaultPadding, // Adjust for keyboard
              ),
              child: SafeArea(
                child: Column(
                  spacing: kDefaultPadding,
                  mainAxisSize: MainAxisSize.min,
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
                          icon: Icon(Icons.cancel_outlined, color: kBlackColor),
                        ),
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
                                password: _password,
                              ).then((result) {
                                if (result == true) {
                                  setState(() {
                                    isOTPSend = true;
                                  });
                                }
                              });

                              // },
                              // );
                            },
                          )
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
                                      MyApp.analytics.logEvent(
                                        name: 'user_phone_verified',
                                      );
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Phone number verified successfully.",
                                        error: false,
                                      );
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
                            },
                          ),
                    errorMessage.isNotEmpty ? Text(errorMessage) : Container(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              child: Text("Sure", style: TextStyle(color: kBlackColor)),
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
  Future<bool> generateOtpAtLogin({
    required String phone,
    required String password,
  }) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/generate_otp_at_login";
    setState(() {
      isLoading = true;
    });
    try {
      Map data = {"phone": phone, "password": password};
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

    Map data = {"code": code, "phone": phone};
    var body = json.encode(data);

    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
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
    Map data = {"user_id": userId, "server_token": serverToken};
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Network error",
                error: true,
              );
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
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Network error",
                error: true,
              );
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
// if (enable) {
    //   // Enable biometric
    //   if (userData == null) {
    //     Service.showMessage(
    //       context: context,
    //       title: "Please login first to enable $_biometricType",
    //       error: true,
    //     );
    //     return;
    //   }

    //   final result = await BiometricService.authenticate(
    //     localizedReason: 'Authenticate to enable $_biometricType login',
    //   );

    //   if (result.success) {
    //     final phone = userData['user']['phone'];
    //     final userName = userData['user']['name'];

    //     await BiometricCredentialsManager.updateBiometricStatus(phone, true);
    //     await BiometricCredentialsManager.updateUserName(phone, userName);
    //     await BiometricCredentialsManager.updateLastUsed(phone);
    //     // final account = await BiometricCredentialsManager.getAccount(phone);

    //     if (mounted) {
    //       // setState(() => _isBiometricEnabled = true);
    //       setState(() {
    //         _isBiometricEnabled = true;
    //         // _isBiometricEnabled = account?.biometricEnabled ?? true;
    //       });

    //       Service.showMessage(
    //         context: context,
    //         title: "$_biometricType login enabled successfully!",
    //         error: false,
    //       );
    //     }
    //   } else if (result.errorMessage != null) {
    //     if (mounted) {
    //       Service.showMessage(
    //         context: context,
    //         title: result.errorMessage!,
    //         error: true,
    //       );
    //     }
    //   }
    // } else {
    //   // Disable biometric
    //   final phone = userData['user']['phone'];
    //   final result = await BiometricService.authenticate(
    //     localizedReason: 'Authenticate to disable $_biometricType login',
    //   );

    //   if (result.success) {
    //     await BiometricCredentialsManager.updateBiometricStatus(phone, false);
    //     final account = await BiometricCredentialsManager.getAccount(phone);

    //     if (mounted) {
    //       setState(() {
    //         _isBiometricEnabled = account?.biometricEnabled ?? false;
    //       });

    //       if (!_isBiometricEnabled) {
    //         Service.showMessage(
    //           context: context,
    //           title: "$_biometricType login disabled",
    //           error: false,
    //         );
    //       }
    //     }
    //   }
    // }