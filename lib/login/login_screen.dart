import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/forgot_password/forgot_password_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/register/components/custom_suffix_icon.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/tab_screen.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  static String routeName = "/login";

  const LoginScreen({
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
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Location permission denied. Please enable and try again", true));
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
      Provider.of<ZMetaData>(context, listen: false)
          .setLocation(currentLocation.latitude, currentLocation.longitude);
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
          ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
              "Location service disabled. Please enable and try again", true));
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
        print("App Version: $appVersion");
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
        context: context);
    if (categoriesResponse != null && categoriesResponse['success']) {
      categories = categoriesResponse['deliveries'];
      Service.saveBool('is_global', false);
    } else {
      if (categoriesResponse['error_code'] == 999) {
        await CoreServices.clearCache();
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${categoriesResponse['error_code']}']}", true));
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else if (categoriesResponse['error_code'] == 813) {
        print("Not in Addis Ababa");
        Provider.of<ZMetaData>(context, listen: false)
            .changeCountrySettings('South Sudan');

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
      } else {
        print("${errorCodes['${categoriesResponse['error_code']}']}");
        // ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
        //     "${errorCodes['${categoriesResponse['error_code']}']}", true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: Text(
      //   //   "LOGIN",
      //   //   style: TextStyle(
      //   //     color: kBlackColor,
      //   //     fontFamily: "Nunito",
      //   //     fontWeight: FontWeight.bold,
      //   //   ),
      //   // ),
      //   elevation: 0.0,
      //   automaticallyImplyLeading: false,
      // ),
      body: Stack(
        children: [
          // Positioned(
          //   width: MediaQuery.of(context).size.width * 1.5,
          //   bottom: 200,
          //   left: 100,
          //   child: Image.asset("images/spline.png"),
          // ),
          // Positioned.fill(
          //   child: BackdropFilter(
          //     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          //     child: SizedBox(),
          //   ),
          // ),
          // RiveAnimation.asset(
          //   "images/login.riv",
          //   fit: BoxFit.cover,
          // ),
          // Positioned.fill(
          //   child: BackdropFilter(
          //     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          //     child: SizedBox(),
          //   ),
          // ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding),
                  vertical: getProportionateScreenHeight(kDefaultPadding * 2),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: getProportionateScreenWidth(kDefaultPadding * 5),
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 5),
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
                              kDefaultPadding * 2)),

                      Text(Provider.of<ZLanguage>(context).welcome,
                          style: headingStyle),
                      // Text(
                      //   "Complete your details or continue  \nwith social media",
                      //   textAlign: TextAlign.center,
                      // ),
                      SizedBox(height: SizeConfig.screenHeight! * 0.06),
                      // buildCountryDropDown(),
                      buildCountryDropDown(),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),

                      buildPhoneNumberFormField(),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      buildPasswordFormField(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, ForgotPassword.routeName);
                            },
                            child: Text(
                              Provider.of<ZLanguage>(context).forgotPassword,
                              style: TextStyle(
                                  color: kGreyColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(context,
                                  "/global", (Route<dynamic> route) => false);
                              //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                              Provider.of<ZMetaData>(context, listen: false)
                                  .changeCountrySettings("Ethiopia");
                            },
                            child: Text(
                              Provider.of<ZLanguage>(context).zGlobal,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _isLoading
                          ? SpinKitWave(
                              color: kSecondaryColor,
                              size:
                                  getProportionateScreenWidth(kDefaultPadding),
                            )
                          : CustomButton(
                              title: Provider.of<ZLanguage>(context).login,
                              press: () {
                                Service.isConnected(context).then(
                                  (connected) async {
                                    if (connected) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      if (phoneNumber.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                              "Phone number cannot be empty",
                                              true),
                                        );
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        // ||
                                        // phoneNumber.substring(0, 1) != 9.toString() ||
                                        // phoneNumber.length != 9) {
                                        // }
                                      } else if (password.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                            "Password cannot be empty.",
                                            true,
                                            duration: 3,
                                          ),
                                        );
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      } else if (phoneNumber.substring(0, 1) ==
                                              9.toString() ||
                                          phoneNumber.substring(0, 1) ==
                                                  7.toString() &&
                                              phoneNumber.length == 9) {
                                        print("Ready to login...");

                                        await login(phoneNumber, password);

                                        if (this.responseData != null) {
                                          if (responseData['success']) {
                                            if (responseData['user']
                                                ['is_approved']) {
                                              Service.save(
                                                  'user', responseData);
                                              Service.saveBool('logged', true);

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                  "You have successfully logged in!",
                                                  style: TextStyle(
                                                      color: kBlackColor),
                                                ),
                                                backgroundColor: kPrimaryColor,
                                              ));
                                              _fcm.subscribeToTopic(
                                                  Provider.of<ZMetaData>(
                                                          context,
                                                          listen: false)
                                                      .country
                                                      .replaceAll(' ', ''));
                                              widget.firstRoute
                                                  ? Navigator
                                                      .pushReplacementNamed(
                                                          context,
                                                          TabScreen.routeName)
                                                  : Navigator.of(context).pop();
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(Service.showMessage(
                                                      "Your account has either been deleted or deactivated. Please reach out to our customer service via email or hotline 8707 to reactivate your account!",
                                                      true,
                                                      duration: 8));
                                            }
                                          } else {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              Service.showMessage(
                                                  responseData['error_code'] !=
                                                          null
                                                      ? "${errorCodes['${responseData['error_code']}']}"
                                                      : responseData[
                                                          'error_description'],
                                                  true),
                                            );
                                          }
                                        }
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                            "Phone number invalid.",
                                            true,
                                            duration: 3,
                                          ),
                                        );
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        Service.showMessage(
                                            "Please check your internet connection",
                                            true),
                                      );
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                                );
                              },
                              color: kSecondaryColor,
                            ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(Provider.of<ZLanguage>(context).noAccount),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              Provider.of<ZLanguage>(context).register,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kSecondaryColor,
                                  decoration: TextDecoration.underline),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TabScreen(isLaunched: true),
                            ),
                          );
                        },
                        child: Text(
                          "Continue as a guest>>",
                          style: TextStyle(color: kSecondaryColor),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<http.Response?> login(String phoneNumber, String password) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/login";
    Map data = {
      "email": phoneNumber,
      "password": password,
      "app_version": "3.0.4",
      // TODO: Change the next line before pushing to the App Store
      "device_type": Platform.isIOS ? 'iOS' : "android",
      // "device_type": "android",
      // "device_type": 'iOS',
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
      setState(() {
        this.responseData = json.decode(response.body);
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Widget buildCountryDropDown() {
    return DropdownButtonFormField(
      icon: Icon(
        Icons.brightness_1_outlined,
        color: kWhiteColor,
      ),
      items: countries.map((String country) {
        return new DropdownMenuItem(
            value: country,
            child: Row(
              children: <Widget>[
                Text(country),
              ],
            ));
      }).toList(),
      onChanged: (newValue) {
        // do other stuff with _category
        Provider.of<ZMetaData>(context, listen: false)
            .changeCountrySettings(newValue.toString());
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

  TextFormField buildPhoneNumberFormField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      maxLength: 9,
      onSaved: (newValue) => phoneNumber = newValue!,
      onChanged: (value) {
        if (value.isNotEmpty) {
          removeError(error: kPhoneInvalidError);
          setState(() {
            phoneNumber = value;
          });
        }
        return null;
      },
      validator: (value) {
        if (value!.isEmpty || value.length < 9) {
          addError(error: kPhoneInvalidError);
          return "";
        }
        // else if (value.length != 9 ||
        //     value.substring(0, 1) != 9.toString() &&
        //         value.substring(0, 1) != 7.toString()) {
        //   addError(error: kPhoneInvalidError);
        //   return "";
        // }

        return null;
      },
      decoration: InputDecoration(
        labelText: Provider.of<ZLanguage>(context).phone,
        prefix: Text(Provider.of<ZMetaData>(context, listen: false).areaCode),
        // hintText: "Enter your phone number",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          iconData: Icons.phone,
        ),
      ),
    );
  }

  bool _showPassword = false;
  TextFormField buildPasswordFormField() {
    return TextFormField(
      obscureText: !_showPassword,
      onSaved: (newValue) => password = newValue!,
      onChanged: (value) {
        if (value.isNotEmpty) {
          removeError(error: kPassNullError);
        } else if (value.length >= 8) {
          removeError(error: kShortPassError);
        }
        password = value;
      },
      validator: (value) {
        if (value!.isEmpty) {
          addError(error: kPassNullError);
          return "";
        } else if (value.length < 8) {
          addError(error: kShortPassError);
          return "";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: Provider.of<ZLanguage>(context).password,
        // hintText: "          Enter your password",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
