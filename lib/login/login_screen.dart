import 'dart:async';
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/forgot_password/forgot_password_screen.dart';
import 'package:zmall/login/otp_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/register/components/custom_suffix_icon.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/tab_screen.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = "/login";

  const LoginScreen({
    super.key,
    this.firstRoute = true,
  });

  final bool firstRoute;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String phoneNumber = "";
  String password = "";
  bool _isLoading = false;
  var responseData;
  late String appVersion;
  late double longitude, latitude;
  bool _loading = false;
  var categories;
  var categoriesResponse;
  var isAbroad = false;
  // String setUrl = testURL;
  String areaCode = "+251";
  String phoneMessage = "Start phone with 9 or 7";
  String country = "Ethiopia";
  var countries = ['Ethiopia', 'South Sudan'];
  final _formKey = GlobalKey<FormState>();
  final List<String> errors = [];
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  LocationPermission _permissionStatus = LocationPermission.denied;

  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial

      Service.showMessage(
        context: context,
        title: "Location permission denied. Please enable and try again",
        error: true,
      );
      FlLocation.requestLocationPermission();
    }
  }

  void getLocation() async {
    var currentLocation = await FlLocation.getLocation();
    if (mounted) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
      });
      Provider.of<ZMetaData>(
        context,
        listen: false,
      ).setLocation(currentLocation.latitude, currentLocation.longitude);
    }
  }

  void _doLocationTask() async {
    LocationPermission _permissionStatus =
        await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.whileInUse ||
        _permissionStatus == LocationPermission.always) {
      if (await FlLocation.isLocationServicesEnabled) {
        getLocation();
      } else {
        LocationPermission serviceStatus =
            await FlLocation.requestLocationPermission();
        if (serviceStatus == LocationPermission.always ||
            serviceStatus == LocationPermission.whileInUse) {
          getLocation();
        } else {
          Service.showMessage(
            context: context,
            title: "Location service disabled. Please enable and try again",
            error: true,
          );
        }
      }
    } else {
      _requestLocationPermission();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getVersion();
    _doLocationTask();
    getNearByMerchants();
  }

  // void alert() async {
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         if (Platform.isIOS) {
  //           return showCupertinoDialog(
  //                 context: context,
  //                 builder: (_) => CupertinoAlertDialog(
  //                       title: Text("Welcome!"),
  //                       content: Text("Are you in Addis Ababa, Ethiopia?"),
  //                       actions: [
  //                         CupertinoButton(
  //                           child: Text('Yes'),
  //                           onPressed: () {
  //                             Navigator.of(context).pop();
  //                           },
  //                         ),
  //                         CupertinoButton(
  //                           child: Text('No'),
  //                           onPressed: () {
  //                             Navigator.pushNamedAndRemoveUntil(context,
  //                                 "/global", (Route<dynamic> route) => false);
  //                           },
  //                         )
  //                       ],
  //                     ));
  //         } else {
  //           return AlertDialog(
  //                 title: Text("Welcome!"),
  //                 content: Text("Are you in Addis Ababa?"),
  //                 actions: [
  //                   TextButton(
  //                       onPressed: () {
  //                         Navigator.of(context).pop();
  //                       },
  //                       child: Text("Yes")),
  //                   TextButton(
  //                       onPressed: () {
  //                         Navigator.pushNamedAndRemoveUntil(context, "/global",
  //                             (Route<dynamic> route) => false);
  //                       },
  //                       child: Text("No")),
  //                 ],
  //               );
  //         }
  //       });
  // }

  void getVersion() async {
    var data = await Service.read('version');
    if (data != null) {
      setState(() {
        appVersion = data;
        debugPrint("App Version: $appVersion");
      });
    }
  }

  void addError({required String error}) {
    if (!errors.contains(error))
      setState(() {
        errors.add(error);
      });
  }

  void removeError({required String error}) {
    if (errors.contains(error))
      setState(() {
        errors.remove(error);
      });
  }

  void getNearByMerchants() async {
    // _doLocationTask();
    categoriesResponse = await CoreServices.getCategoryList(
      longitude: Provider.of<ZMetaData>(context, listen: false).longitude,
      latitude: Provider.of<ZMetaData>(context, listen: false).latitude,
      countryCode: "5b3f76f2022985030cd3a437",
      countryName: "Ethiopia",
      context: context,
    );
    if (categoriesResponse != null && categoriesResponse['success']) {
      categories = categoriesResponse['deliveries'];
      Service.saveBool('is_global', false);
    } else {
      if (categoriesResponse != null &&
          categoriesResponse['error_code'] == 999) {
        await CoreServices.clearCache();

        Service.showMessage(
          context: context,
          title: "${errorCodes['${categoriesResponse['error_code']}']}",
          error: true,
        );
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else if (categoriesResponse != null &&
          categoriesResponse['error_code'] == 813) {
        debugPrint("Not in Addis Ababa");
        Provider.of<ZMetaData>(
          context,
          listen: false,
        ).changeCountrySettings('South Sudan');

        // showCupertinoDialog(
        //     context: context,
        //     builder: (_) => CupertinoAlertDialog(
        //           title: Text("ZMall Global!"),
        //           content: Text(
        //               "We have detected that your location is not in Addis Ababa. Please proceed to ZMall Global!"),
        //           actions: [
        //             CupertinoButton(
        //               child: Text('Continue'),
        //               onPressed: () {
        //                 Service.saveBool('is_global', true);
        //                 Navigator.pushNamedAndRemoveUntil(context, "/global",
        //                     (Route<dynamic> route) => false);
        //               },
        //             )
        //           ],
        //         ));
      }
      // else {
      // debugPrint("${errorCodes['${categoriesResponse['error_code']}']}");
      // ScaffoldMessenger.of(context).showSnackBar(Service.showMessage1(
      //     "${errorCodes['${categoriesResponse['error_code']}']}", true));
      // }
    }
  }

//  body: Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: getProportionateScreenWidth(kDefaultPadding),
//           ),
//           child: Center(
//             child: SingleChildScrollView(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: kDefaultPadding, vertical: kDefaultPadding * 2),
//                 decoration: BoxDecoration(
//                   color: kPrimaryColor,
//                   borderRadius: BorderRadius.circular(kDefaultPadding),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withValues(alpha: 0.1),
//                       spreadRadius: 1,
//                       blurRadius: 3,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        bottomNavigationBar: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Provider.of<ZLanguage>(context).noAccount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  Provider.of<ZLanguage>(context).register,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                    // decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding * 2)),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ////header///
                    Center(
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: getProportionateScreenWidth(
                                kDefaultPadding * 5),
                            height: getProportionateScreenHeight(
                              kDefaultPadding * 5,
                            ),
                            margin: EdgeInsets.only(top: kDefaultPadding * 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // boxShadow: [kDefaultShadow],
                              image: DecorationImage(
                                image: AssetImage(zmallLogo),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: getProportionateScreenHeight(
                              kDefaultPadding,
                            ),
                          ),
                          Text(
                            Provider.of<ZLanguage>(context).welcome,
                            // "ZMall Delivery"
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                            // headingStyle,
                          ),
                          Text(
                            "Delivery Done Right!",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: kGreyColor),
                            // headingStyle,
                          ),
                        ],
                      ),
                    ),

                    /////form filds//
                    SizedBox(height: SizeConfig.screenHeight! * 0.06),

                    buildPhoneNumberFormField(),
                    SizedBox(height: kDefaultPadding),
                    buildPasswordFormField(),
                    // SizedBox(height: kDefaultPadding),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ForgotPassword.routeName,
                          );
                        },
                        child: Text(
                          "${Provider.of<ZLanguage>(context).forgotPassword}?",
                          style: TextStyle(
                            color: kBlackColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     TextButton(
                    //       onPressed: () {
                    //         Navigator.pushNamed(
                    //           context,
                    //           ForgotPassword.routeName,
                    //         );
                    //       },
                    //       child: Text(
                    //         Provider.of<ZLanguage>(context).forgotPassword,
                    //         style: TextStyle(
                    //           color: kGreyColor,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ),
                    //     TextButton(
                    //       onPressed: () {
                    //         Navigator.pushNamedAndRemoveUntil(
                    //           context,
                    //           "/global",
                    //           (Route<dynamic> route) => false,
                    //         );
                    //         //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                    //         Provider.of<ZMetaData>(
                    //           context,
                    //           listen: false,
                    //         ).changeCountrySettings("Ethiopia");
                    //       },
                    //       child: Text(
                    //         Provider.of<ZLanguage>(context).zGlobal,
                    //         style: TextStyle(
                    //           fontWeight: FontWeight.bold,
                    //           decoration: TextDecoration.underline,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: kDefaultPadding * 2),
                    ////////////login button////
                    CustomButton(
                      isLoading: _isLoading,
                      title: Provider.of<ZLanguage>(context).login,
                      child: Text(
                        Provider.of<ZLanguage>(context)
                            .login
                            .toString()
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              wordSpacing: 3,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      press: () {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          Service.isConnected(context).then((
                            connected,
                          ) async {
                            if (_formKey.currentState!.validate()) {
                              if (connected) {
                                // Navigator.of(context).push(MaterialPageRoute(
                                //     builder: (context) => OtpScreen(
                                //         password: password,
                                //         phone: phoneNumber,
                                //         areaCode: areaCode)));
                                // await login(phoneNumber, password);
                                bool isGeneratOtp = await generateOtpAtLogin(
                                    phone: phoneNumber, password: password);
                                if (isGeneratOtp) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => OtpScreen(
                                          password: password,
                                          phone: phoneNumber,
                                          areaCode: areaCode)));
                                  // print("after otp auth");
                                }
                              } else {
                                Service.showMessage(
                                  context: context,
                                  title:
                                      "No internet connection. Check your network and try again.",
                                  error: true,
                                );
                              }
                            }
                          });
                        } catch (e) {
                          Service.showMessage(
                            context: context,
                            title:
                                "Connection unavailable. Check your internet and try again.",
                            // "Please check your internet connection",
                            error: true,
                          );
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      color: kSecondaryColor,
                    ),

                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding * 2),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: kGreyColor.withValues(alpha: 0.5),
                            thickness: 1,
                            endIndent: 10,
                          ),
                        ),
                        Text(
                          "Continue with",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: kGreyColor,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: kGreyColor.withValues(alpha: 0.5),
                            thickness: 1,
                            indent: 10,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding)),
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                          vertical:
                              getProportionateScreenHeight(kDefaultPadding / 2),
                          horizontal:
                              getProportionateScreenWidth(kDefaultPadding)),
                      decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(kDefaultPadding)),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TabScreen(isLaunched: true),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: getProportionateScreenWidth(kDefaultPadding),
                          children: [
                            Icon(HeroiconsOutline.user),
                            Text(
                              "Continue as a Guest",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kBlackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding)),
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                          vertical:
                              getProportionateScreenHeight(kDefaultPadding / 2),
                          horizontal:
                              getProportionateScreenWidth(kDefaultPadding)),
                      decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(kDefaultPadding)),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            "/global",
                            (Route<dynamic> route) => false,
                          );
                          //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                          Provider.of<ZMetaData>(
                            context,
                            listen: false,
                          ).changeCountrySettings("Ethiopia");
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: getProportionateScreenWidth(kDefaultPadding),
                          children: [
                            Icon(HeroiconsOutline.globeEuropeAfrica),
                            Text(
                              // "ZMall Global",
                              Provider.of<ZLanguage>(context).zGlobal,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kBlackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   spacing: getProportionateScreenWidth(kDefaultPadding),
                    //   children: [
                    //     Flexible(
                    //       child: Container(
                    //         height: 50,
                    //         alignment: Alignment.center,
                    //         padding: EdgeInsets.symmetric(
                    //             vertical: getProportionateScreenHeight(
                    //                 kDefaultPadding / 2),
                    //             horizontal: getProportionateScreenWidth(
                    //                 kDefaultPadding)),
                    //         decoration: BoxDecoration(
                    //             color: kWhiteColor,
                    //             borderRadius:
                    //                 BorderRadius.circular(kDefaultPadding)),
                    //         child: InkWell(
                    //           onTap: () {
                    //             Navigator.pushReplacement(
                    //               context,
                    //               MaterialPageRoute(
                    //                 builder: (context) =>
                    //                     TabScreen(isLaunched: true),
                    //               ),
                    //             );
                    //           },
                    //           child: Row(
                    //             mainAxisAlignment: MainAxisAlignment.center,
                    //             spacing: getProportionateScreenWidth(
                    //                 kDefaultPadding),
                    //             children: [
                    //               Icon(HeroiconsOutline.user),
                    //               Text(
                    //                 "Guest",
                    //                 style: TextStyle(
                    //                   fontWeight: FontWeight.bold,
                    //                   color: kBlackColor,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     Flexible(
                    //       child: Container(
                    //         height: 50,
                    //         alignment: Alignment.center,
                    //         padding: EdgeInsets.symmetric(
                    //             vertical: getProportionateScreenHeight(
                    //                 kDefaultPadding / 2),
                    //             horizontal: getProportionateScreenWidth(
                    //                 kDefaultPadding)),
                    //         decoration: BoxDecoration(
                    //             color: kWhiteColor,
                    //             borderRadius:
                    //                 BorderRadius.circular(kDefaultPadding)),
                    //         child: InkWell(
                    //           onTap: () {
                    //             Navigator.pushNamedAndRemoveUntil(
                    //               context,
                    //               "/global",
                    //               (Route<dynamic> route) => false,
                    //             );
                    //             //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                    //             Provider.of<ZMetaData>(
                    //               context,
                    //               listen: false,
                    //             ).changeCountrySettings("Ethiopia");
                    //           },
                    //           child: Row(
                    //             mainAxisAlignment: MainAxisAlignment.center,
                    //             spacing: getProportionateScreenWidth(
                    //                 kDefaultPadding),
                    //             children: [
                    //               Icon(HeroiconsOutline.globeEuropeAfrica),
                    //               Text(
                    //                 "ZMall Global",
                    //                 // Provider.of<ZLanguage>(context).zGlobal,
                    //                 style: TextStyle(
                    //                   fontWeight: FontWeight.bold,
                    //                   color: kBlackColor,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),

                    //     // TextButton(
                    //     //   onPressed: () {
                    //     //     Navigator.pushReplacement(
                    //     //       context,
                    //     //       MaterialPageRoute(
                    //     //         builder: (context) =>
                    //     //             TabScreen(isLaunched: true),
                    //     //       ),
                    //     //     );
                    //     //   },
                    //     //   child: Text(
                    //     //     "Continue as a Guest",
                    //     //     style: TextStyle(
                    //     //       color: kSecondaryColor,
                    //     //       fontWeight: FontWeight.bold,
                    //     //     ),
                    //     //   ),
                    //     // ),
                    //     // TextButton(
                    //     //   onPressed: () {
                    //     //     Navigator.pushNamedAndRemoveUntil(
                    //     //       context,
                    //     //       "/global",
                    //     //       (Route<dynamic> route) => false,
                    //     //     );
                    //     //     //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                    //     //     Provider.of<ZMetaData>(
                    //     //       context,
                    //     //       listen: false,
                    //     //     ).changeCountrySettings("Ethiopia");
                    //     //   },
                    //     //   child: Text(
                    //     //     Provider.of<ZLanguage>(context).zGlobal,
                    //     //     style: TextStyle(
                    //     //       fontWeight: FontWeight.bold,
                    //     //       // decoration: TextDecoration.underline,
                    //     //     ),
                    //     //   ),
                    //     // ),
                    //   ],
                    // ),
                    // SizedBox(
                    //   height: getProportionateScreenHeight(kDefaultPadding),
                    // ),
                    // Spacer(),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text(Provider.of<ZLanguage>(context).noAccount),
                    //     TextButton(
                    //       onPressed: () {
                    //         Navigator.pushNamed(context, '/register');
                    //       },
                    //       child: Text(
                    //         Provider.of<ZLanguage>(context).register,
                    //         style: TextStyle(
                    //           fontWeight: FontWeight.bold,
                    //           color: kSecondaryColor,
                    //           decoration: TextDecoration.underline,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

////////////////otp authentication/////

  Future<dynamic> generateOtpAtLogin({
    required String phone,
    required String password,
  }) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/generate_otp_at_login";
    setState(() {
      _isLoading = true;
    });
    try {
      Map data = {
        "phone": phone,
        "password": password,
      };
      var body = json.encode(data);
      // debugPrint("body??? $body}");
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
      // debugPrint("otp??? ${json.decode(response.body)}");
      // return json.decode(response.body);
      var newResponse = json.decode(response.body);
      if (newResponse != null &&
          (newResponse["success"] != null && newResponse["success"])) {
        return true;
      } else {
        Service.showMessage(
            context: context,
            title:
                "Failed to send an OTP. Please check your phone and password and try again.",
            error: true);
        return false;
      }
    } catch (e) {
      // print(e);
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ///
  ///////////////////////////////////////

  Widget buildCountryDropDown() {
    return DropdownButtonFormField(
      icon: Icon(Icons.brightness_1_outlined, color: kWhiteColor),
      items: countries.map((String country) {
        return new DropdownMenuItem(
          value: country,
          child: Row(children: <Widget>[Text(country)]),
        );
      }).toList(),
      onChanged: (newValue) {
        // do other stuff with _category
        Provider.of<ZMetaData>(
          context,
          listen: false,
        ).changeCountrySettings(newValue.toString());
        setState(() {
          country = newValue.toString();

          if (country == "Ethiopia") {
            phoneMessage = "Start phone number with 9 or 7...";
            areaCode = "+251";
          } else if (country == "South Sudan") {
            phoneMessage = "Start phone number with 9...";
            areaCode = "+211";
          }
        });
      },
      decoration: InputDecoration(
        labelText: Provider.of<ZLanguage>(context).country,
        hintText: "Choose your country",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          iconData: Icons.arrow_drop_down_circle_sharp,
        ),
      ),
      value: Provider.of<ZMetaData>(context, listen: false).country,
    );
  }

  // TextFormField
  Widget buildPhoneNumberFormField() {
    return CustomTextField(
      keyboardType: TextInputType.number,
      maxLength: 9,
      onSaved: (newValue) => phoneNumber = newValue!,
      onChanged: (value) {
        if (value.isNotEmpty) {
          // removeError(error: kPhoneInvalidError);
          setState(() {
            phoneNumber = value;
          });
        }
        return null;
      },
      // validator: (value) {
      // if (value!.isEmpty || value.length < 9) {
      //   addError(error: kPhoneInvalidError);
      //   return "";
      // }
      // // else if (value.length != 9 ||
      // //     value.substring(0, 1) != 9.toString() &&
      // //         value.substring(0, 1) != 7.toString()) {
      // //   addError(error: kPhoneInvalidError);
      // //   return "";
      // // }

      // return null;
      // },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        if (!RegExp(r'^[97][0-9]{8}$').hasMatch(value)) {
          return 'Phone number must be 9 digits and start with 9 or 7';
        }
        return null; // Return null if validation passes
      },
      // decoration: InputDecoration(
      // labelText: Provider.of<ZLanguage>(context).phone,
      // prefix: Text(Provider.of<ZMetaData>(context, listen: false).areaCode),
      hintText: "$areaCode...",
      // "Enter your phone number",
      // If  you are using latest version of flutter then lable text and hint text shown like this
      // if you r using flutter less then 1.20.* then maybe this is not working properly
      floatingLabelBehavior: FloatingLabelBehavior.always,
      // suffixIcon: CustomSuffixIcon(iconData: Icons.phone),
      isPhoneWithFlag: true,
      initialSelection:
          Provider.of<ZMetaData>(context, listen: false).areaCode == "+251"
              ? 'ET'
              : 'SS',
      countryFilter: ['ET', 'SS'],
      onFlagChanged: (CountryCode code) {
        setState(() {
          // debugPrint("code $code");
          if (code.toString() == "+251") {
            areaCode = "+251";
            country = "Ethiopia";
          } else {
            areaCode = "+211";
            country = "South Sudan";
          }
          // debugPrint("after _country $_country");
          Provider.of<ZMetaData>(
            context,
            listen: false,
          ).changeCountrySettings(country);
        });
      },
      // ),
    );
  }

  bool _showPassword = false;
  Widget buildPasswordFormField() {
    return CustomTextField(
      obscureText: !_showPassword,
      onSaved: (newValue) => password = newValue!,
      keyboardType: TextInputType.visiblePassword,
      onChanged: (value) {
        // if (value.isNotEmpty) {
        //   removeError(error: kPassNullError);
        // } else if (value.length >= 8) {
        //   removeError(error: kShortPassError);
        // }
        password = value;
      },
      // validator: (value) {
      //   if (value!.isEmpty) {
      //     addError(error: kPassNullError);
      //     return "";
      //   } else if (value.length < 8) {
      // addError(error: kShortPassError);
      //     return "";
      //   }
      //   return null;
      // },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 8) {
          return "Password is too short";
        }
        return null; // Return null if validation passes
      },
      // decoration: InputDecoration(
      // labelText: Provider.of<ZLanguage>(context).password,
      hintText: " Enter your password",
      // If  you are using latest version of flutter then lable text and hint text shown like this
      // if you r using flutter less then 1.20.* then maybe this is not working properly
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _showPassword = !_showPassword;
          });
        },
        icon: Icon(
            _showPassword ? HeroiconsOutline.eyeSlash : HeroiconsOutline.eye),
      ),
      // ),
    );
  }
}
