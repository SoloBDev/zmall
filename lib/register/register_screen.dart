import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/register/components/complete_profile_screen.dart';
import 'package:zmall/register/components/custom_suffix_icon.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'components/form_error.dart';

class RegisterScreen extends StatefulWidget {
  static String routeName = '/register';

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String firstName = "";
  String lastName = "";
  String email = "";
  String password = "";
  String confirmPassword = "";
  String country = "Ethiopia";
  String city = "Addis Ababa";
  String phoneNumber = "";
  String address = "";
  String referralCode = "";
  bool termsAndConditions = false;
  late String otp;
  late String verificationCode;
  bool errorFound = false;
  var countries = ['Ethiopia', 'South Sudan'];
  var cities = ["Addis Ababa"];
  var responseData;
  bool _loading = false;
  bool otpSent = false;
  var appVersion;
  String setUrl = BASE_URL;
  String areaCode = "+251";
  String phoneMessage = "Start phone with 9 or 7";
  final _codeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final List<String> errors = [];

  // Future<void> _register() async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   var data = await register();
  //   if (data != null && data['success']) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       Service.showMessage(
  //         "Registration successful. Ready to login!",
  //         false,
  //         duration: 3,
  //       ),
  //     );
  //     await MyApp.analytics.logEvent(name: "user_registered");

  //     // User Login...

  //     var loginResponse = await login(phoneNumber, password);
  //     if (loginResponse != null) {
  //       if (loginResponse['success']) {
  //         Service.save('user', loginResponse);
  //         Service.saveBool('logged', true);
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           Service.showMessage(
  //             "Login Successful!",
  //             false,
  //             duration: 3,
  //           ),
  //         );
  //         Navigator.pushNamedAndRemoveUntil(
  //             context, TabScreen.routeName, (Route<dynamic> route) => false);
  //       }
  //     } else {
  //       setState(() {
  //         _loading = false;
  //         responseData = data;
  //       });

  //       Navigator.pushNamedAndRemoveUntil(
  //           context, "/login", (Route<dynamic> route) => false);
  //     }
  //   } else {
  //     if (data['error_code'] == 503) {
  //       var loginResponse = await login(phoneNumber, password);
  //       if (loginResponse != null) {
  //         if (loginResponse['success']) {
  //           Service.save('user', loginResponse);
  //           Service.saveBool('logged', true);
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             Service.showMessage(
  //               "Login Successful!",
  //               false,
  //               duration: 3,
  //             ),
  //           );
  //           Navigator.pushNamedAndRemoveUntil(
  //               context, TabScreen.routeName, (Route<dynamic> route) => false);
  //         }
  //       } else {
  //         setState(() {
  //           _loading = false;
  //           responseData = data;
  //         });

  //         Navigator.pushNamedAndRemoveUntil(
  //             context, "/login", (Route<dynamic> route) => false);
  //       }
  //     } else {
  //       setState(() {
  //         _loading = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
  //           "${errorCodes['${data['error_code']}']}!", true));
  //     }
  //   }
  // }

  // Future<void> registerUser(String phone, BuildContext context) async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   FirebaseAuth _auth = FirebaseAuth.instance;

  //   _auth.verifyPhoneNumber(
  //       phoneNumber: phone,
  //       timeout: Duration(seconds: 60),
  //       verificationCompleted: (AuthCredential credential) async {
  //         if (_codeController.text.isEmpty) {
  //           await _register();
  //         }

  //         UserCredential result = await _auth.signInWithCredential(credential);
  //         Navigator.of(context).pop();
  //         User user = result.user!;
  //         setState(() {
  //           _loading = false;
  //         });
  //         if (user != null) {
  //           debugPrint("User");
  //         } else {
  //           debugPrint("Error");
  //           ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
  //               "Something went wrong. Please try to login if you have already registered.",
  //               true));
  //           Navigator.of(context).pop();
  //         }
  //         //This callback would gets called when verification is done automatically
  //       },
  //       verificationFailed: (FirebaseAuthException exception) {
  //         ScaffoldMessenger.of(context)
  //             .showSnackBar(Service.showMessage(exception.message, true));
  //         setState(() {
  //           _loading = false;
  //         });
  //       },
  //       codeSent: (String verificationId, forceResendingToken) {
  //         showDialog(
  //             context: context,
  //             barrierDismissible: false,
  //             builder: (context) {
  //               return AlertDialog(
  //                 backgroundColor: kPrimaryColor,
  //                 title: Text("Phone Number Verification"),
  //                 content: Wrap(
  //                   children: [
  //                     Text(
  //                         "Please enter the one time pin(OTP) sent to your phone.\n"),
  //                     SizedBox(
  //                       height: getProportionateScreenHeight(kDefaultPadding),
  //                     ),
  //                     TextField(
  //                       controller: _codeController,
  //                     ),
  //                   ],
  //                 ),
  //                 actions: <Widget>[
  //                   CustomButton(
  //                     title: "Confirm",
  //                     color: kSecondaryColor,
  //                     press: () async {
  //                       final code = _codeController.text.trim();
  //                       AuthCredential credential =
  //                           PhoneAuthProvider.credential(
  //                               verificationId: verificationId, smsCode: code);

  //                       UserCredential result =
  //                           await _auth.signInWithCredential(credential);

  //                       User user = result.user!;

  //                       if (user != null) {
  //                         Navigator.of(context).pop();
  //                         setState(() {
  //                           _loading = true;
  //                         });
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                             Service.showMessage(
  //                                 ("Verification successful. Registering user.."),
  //                                 false));
  //                         await _register();
  //                       } else {
  //                         debugPrint("Error while signing user");
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                             Service.showMessage(
  //                                 ("Error while verifying phone number. Please try again"),
  //                                 true));
  //                         setState(() {
  //                           _loading = false;
  //                         });
  //                         Navigator.of(context).pop();
  //                       }
  //                     },
  //                   )
  //                 ],
  //               );
  //             });
  //       },
  //       codeAutoRetrievalTimeout: ((verificationId) {}));
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getVersion();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          // title: Text(
          //   "Register",
          //   style: TextStyle(color: kBlackColor),
          // ),
          elevation: 0.0,
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(20)),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: SizeConfig.screenHeight! * 0.04), // 4%
                      Text("Register Account", style: headingStyle),
                      // Text(
                      //   "Complete your details or continue \nwith social media",
                      //   textAlign: TextAlign.center,
                      // ),
                      SizedBox(height: SizeConfig.screenHeight! * 0.04),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            buildEmailFormField(),
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding * 2)),
                            buildPasswordFormField(),
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding * 2)),
                            buildConformPassFormField(),
                            // SizedBox(
                            //     height: getProportionateScreenHeight(
                            //         kDefaultPadding * 2)),
                            // buildCountryDropDown(),
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding * 2)),
                            FormError(errors: errors),
                            SizedBox(height: getProportionateScreenHeight(40)),
                            CustomButton(
                              title: "Continue",
                              color: kSecondaryColor,
                              press: () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  // if all are valid then go to success screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return CompleteProfileScreen(
                                          email: email,
                                          password: password,
                                          confirmPassword: confirmPassword,
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     SocalCard(
                      //       icon: "assets/icons/google-icon.svg",
                      //       press: () {},
                      //     ),
                      //     SocalCard(
                      //       icon: "assets/icons/facebook-2.svg",
                      //       press: () {},
                      //     ),
                      //     SocalCard(
                      //       icon: "assets/icons/twitter.svg",
                      //       press: () {},
                      //     ),
                      //   ],
                      // ),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                              "By continuing your confirm that you agree with our",
                              style: Theme.of(context).textTheme.bodySmall),
                          InkWell(
                            onTap: () {
                              Service.launchInWebViewOrVC(
                                  "https://app.zmallshop.com/terms.html");
                            },
                            child: Text(
                              "Terms & Conditions",
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: kSecondaryColor,
                                  ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //         child: Padding(
          //           padding: EdgeInsets.symmetric(
          //             horizontal: getProportionateScreenWidth(kDefaultPadding),
          //             vertical: getProportionateScreenHeight(kDefaultPadding),
          //           ),
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               TextField(
          //                 style: TextStyle(color: kBlackColor),
          //                 keyboardType: TextInputType.text,
          //                 onChanged: (val) {
          //                   firstName = val;
          //                 },
          //                 decoration: textFieldInputDecorator.copyWith(
          //                   labelText: "First Name",
          //                 ),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               TextField(
          //                 style: TextStyle(color: kBlackColor),
          //                 keyboardType: TextInputType.text,
          //                 onChanged: (val) {
          //                   lastName = val;
          //                 },
          //                 decoration: textFieldInputDecorator.copyWith(
          //                   labelText: "Last Name",
          //                 ),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               TextField(
          //                 style: TextStyle(color: kBlackColor),
          //                 keyboardType: TextInputType.emailAddress,
          //                 onChanged: (val) {
          //                   email = val;
          //                 },
          //                 decoration: textFieldInputDecorator.copyWith(
          //                   labelText: "Email",
          //                 ),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               buildCountryDropDown(),
          // //              SizedBox(
          // //                  height: getProportionateScreenHeight(kDefaultPadding / 4)),
          // //              buildCityDropDown(),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               TextField(
          //                 style: TextStyle(color: kBlackColor),
          //                 keyboardType: TextInputType.number,
          //                 maxLength: 9,
          //                 onChanged: (val) {
          //                   phoneNumber = val;
          //                 },
          //                 decoration: textFieldInputDecorator.copyWith(
          //                     prefix: Text(areaCode),
          //                     labelText: "Phone Number",
          //                     helperText: phoneMessage),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               TextField(
          //                 style: TextStyle(color: kBlackColor),
          //                 keyboardType: TextInputType.text,
          //                 obscureText: true,
          //                 onChanged: (val) {
          //                   setState(() {
          //                     password = val;
          //                   });
          //                 },
          //                 decoration: textFieldInputDecorator.copyWith(
          //                   suffixIcon: password.isNotEmpty && password == confirmPassword
          //                       ? Icon(
          //                           Icons.check,
          //                           color: Colors.green,
          //                         )
          //                       : Icon(
          //                           Icons.close,
          //                           color: kWhiteColor,
          //                         ),
          //                   labelText: "Password",
          //                 ),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               TextField(
          //                 style: TextStyle(color: kBlackColor),
          //                 keyboardType: TextInputType.text,
          //                 obscureText: true,
          //                 onChanged: (val) {
          //                   setState(() {
          //                     confirmPassword = val;
          //                   });
          //                 },
          //                 decoration: textFieldInputDecorator.copyWith(
          //                   suffixIcon: password.isNotEmpty && password == confirmPassword
          //                       ? Icon(
          //                           Icons.check,
          //                           color: Colors.green,
          //                         )
          //                       : Icon(
          //                           Icons.close,
          //                           color: kWhiteColor,
          //                         ),
          //                   labelText: "Confirm Password",
          //                 ),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               TextField(
          //                 style: TextStyle(color: kBlackColor),
          //                 keyboardType: TextInputType.text,
          //                 onChanged: (val) {
          //                   address = val;
          //                 },
          //                 decoration: textFieldInputDecorator.copyWith(
          //                   labelText: "Address",
          //                 ),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 2)),
          //               Text(
          //                 "Referral",
          //                 style: TextStyle(color: kBlackColor),
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               Row(
          //                 children: [
          //                   Expanded(
          //                     child: TextField(
          //                       style: TextStyle(color: kBlackColor),
          //                       keyboardType: TextInputType.text,
          //                       onChanged: (val) {
          //                         setState(() {
          //                           referralCode = val;
          //                         });
          //                       },
          //                       decoration: textFieldInputDecorator.copyWith(
          //                         labelText: "Enter Referral Code",
          //                       ),
          //                     ),
          //                   ),
          //                   SizedBox(width: getProportionateScreenWidth(kDefaultPadding)),
          //                   TextButton(
          //                     onPressed: () {},
          //                     child: Text(
          //                       "Apply Code",
          //                       style: TextStyle(
          //                         color: referralCode.isNotEmpty
          //                             ? kSecondaryColor
          //                             : kGreyColor,
          //                       ),
          //                     ),
          //                   )
          //                 ],
          //               ),
          //               SizedBox(
          //                   height: getProportionateScreenHeight(kDefaultPadding / 4)),
          //               Row(
          //                 children: [
          //                   Checkbox(
          //                       activeColor: kSecondaryColor,
          //                       value: termsAndConditions,
          //                       onChanged: (val) {
          //                         setState(() {
          //                           termsAndConditions = val;
          //                         });
          //                       }),
          //                   Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Text("By registering, you agree to our,"),
          //                       InkWell(
          //                         onTap: () {
          //                           Service.launchInWebViewOrVC(
          //                               "https://app.zmallshop.com/terms.html");
          //                         },
          //                         child: Text(
          //                           "Terms & Conditions",
          //                           overflow: TextOverflow.ellipsis,
          //                           style: TextStyle(
          //                             color: kSecondaryColor,
          //                           ),
          //                           softWrap: true,
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                 ],
          //               ),
          //               SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
          //               _loading
          //                   ? SpinKitWave(
          //                       size: getProportionateScreenWidth(kDefaultPadding),
          //                       color: kSecondaryColor,
          //                     )
          //                   : CustomButton(
          //                       title: "Register",
          //                       press: () {
          //                         if (termsAndConditions) {
          //                           if (phoneNumber.isEmpty) {
          //                             ScaffoldMessenger.of(context).showSnackBar(
          //                                 Service.showMessage(
          //                                     "Phone number cannot be empty!", true));
          //                           } else if (phoneNumber.length != 9 ||
          //                               phoneNumber.substring(0, 1) != 9.toString() &&
          //                                   phoneNumber.substring(0, 1) != 7.toString()) {
          //                             ScaffoldMessenger.of(context).showSnackBar(
          //                               Service.showMessage(
          //                                 "Please enter a valid phone number",
          //                                 true,
          //                                 duration: 3,
          //                               ),
          //                             );
          //                           } else if (password != confirmPassword) {
          //                             ScaffoldMessenger.of(context).showSnackBar(
          //                                 Service.showMessage(
          //                                     "Passwords don't match!", true));
          //                           } else if (!validateEmail(email)) {
          //                             ScaffoldMessenger.of(context).showSnackBar(
          //                               Service.showMessage("Invalid email", true,
          //                                   duration: 3),
          //                             );
          //                           } else {
          //                             if (firstName.isNotEmpty &&
          //                                 lastName.isNotEmpty &&
          //                                 email.isNotEmpty &&
          //                                 city.isNotEmpty &&
          //                                 country.isNotEmpty) {
          //                               debugPrint(
          //                                   "Ready to verify and register $areaCode $phoneNumber");
          //                               registerUser("$areaCode$phoneNumber", context);
          //                             } else {
          //                               ScaffoldMessenger.of(context).showSnackBar(
          //                                   Service.showMessage(
          //                                       "Please make sure all fields are filled in properly!",
          //                                       true,
          //                                       duration: 4));
          //                             }
          //                           }
          //                         } else {
          //                           ScaffoldMessenger.of(context).showSnackBar(
          //                               Service.showMessage(
          //                                   "Please enter all fields properly", true,
          //                                   duration: 3));
          //                         }
          //                       },
          //                       color: termsAndConditions ? kSecondaryColor : kGreyColor,
          //                     )
          //             ],
          //           ),
          //         ),
        ),
      ),
    );
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
        setState(() {
          country = newValue.toString();
          if (country == "Ethiopia") {
            setUrl = BASE_URL;
            phoneMessage = "Start phone number with 9 or 7...";
            areaCode = "+251";
            city = "Addis Ababa";
          } else if (country == "South Sudan") {
            setUrl = BASE_URL_JUBA;
            phoneMessage = "Start phone number with 9...";
            areaCode = "+211";
            city = "Juba";
          }
        });
      },
      value: country,
      decoration: InputDecoration(
        labelText: "Country",
        hintText: "Choose your country",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          iconData: Icons.arrow_drop_down_circle_sharp,
        ),
      ),
    );
  }

  Widget buildCityDropDown() {
    return DropdownButtonFormField(
      items: cities.map((String city) {
        return new DropdownMenuItem(
            value: city,
            child: Row(
              children: <Widget>[
                Text(city),
              ],
            ));
      }).toList(),
      onChanged: (newValue) {
        // do other stuff with _category
        setState(() => city = newValue.toString());
      },
      value: city,
      decoration: textFieldInputDecorator.copyWith(
        labelText: "City",
      ),
    );
  }

  // Future<bool> sendOTP(phone, otp) async {
  //   debugPrint("Sending code: $otp to $phone");
  //   http.Response response = await verificationSms(phone, otp);
  //   if (response != null && response.statusCode == 200) {
  //     setState(() {
  //       otpSent = true;
  //     });
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(Service.showMessage("OTP sent to phone $phone", false));
  //   }
  //   return otpSent;
  // }
  //
  // Future<http.Response> verificationSms(String phone, String otp) async {
  //   var url = "$testURL/api/admin/send_sms_with_message";
  //   String token = Uuid().v4();
  //   Map data = {
  //     "code": "${token}_zmall",
  //     "phone": phone,
  //     "message": "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ / OTP : $otp"
  //   };
  //   var body = json.encode(data);
  //
  //   try {
  //     http.Response response = await http
  //         .post(
  //       Uri.parse(url),
  //       headers: <String, String>{"Content-Type": "application/json"},
  //       body: body,
  //     )
  //         .timeout(
  //       Duration(seconds: 30),
  //       onTimeout: () {
  //         throw TimeoutException("The connection has timed out!");
  //       },
  //     );
  //     setState(() {
  //       _loading = false;
  //     });
  //     debugPrint(json.decode(response.body));
  //     return response;
  //   } catch (e) {
  //     // debugPrint(e);
  //     return null;
  //   }
  // }

  // Future<dynamic> register() async {
  //   var url = "$setUrl/api/user/register";
  //   Map data = {
  //     "country_id": country_id['$country'],
  //     "email": email,
  //     "phone": phoneNumber,
  //     "first_name": firstName,
  //     "last_name": lastName,
  //     "password": password,
  //     "country_phone_code": areaCode,
  //     "city": city,
  //     "referral_code": referralCode,
  //     "address": address,
  //     "is_phone_number_verified": true,
  //   };
  //   var body = json.encode(data);
  //   try {
  //     http.Response response = await http
  //         .post(
  //       Uri.parse(url),
  //       headers: <String, String>{
  //         "Content-Type": "application/json",
  //         "Accept": "application/json"
  //       },
  //       body: body,
  //     )
  //         .timeout(
  //       Duration(seconds: 30),
  //       onTimeout: () {
  //         throw TimeoutException("The connection has timed out!");
  //       },
  //     );
  //     setState(() {
  //       this.responseData = json.decode(response.body);
  //     });
  //     return json.decode(response.body);
  //   } catch (e) {
  //     // debugPrint(e);
  //     return null;
  //   }
  // }

  // Future<dynamic> login(String phoneNumber, String password) async {
  //   debugPrint("User login started...");
  //   var url = "$setUrl/api/user/login";
  //   Map data = {
  //     "email": phoneNumber,
  //     "password": password,
  //     "app_version": appVersion,
  //     "device_type": Platform.operatingSystem,
  //   };
  //   var body = json.encode(data);
  //   try {
  //     http.Response response = await http
  //         .post(
  //       Uri.parse(url),
  //       headers: <String, String>{
  //         "Content-Type": "application/json",
  //         "Accept": "application/json"
  //       },
  //       body: body,
  //     )
  //         .timeout(
  //       Duration(seconds: 30),
  //       onTimeout: () {
  //         throw TimeoutException("The connection has timed out!");
  //       },
  //     );
  //     // debugPrint(json.decode(response.body));
  //     return json.decode(response.body);
  //   } catch (e) {
  //     // debugPrint(e);
  //     return null;
  //   }
  // }

  Widget buildConformPassFormField() {
    return CustomTextField(
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      onSaved: (newValue) => confirmPassword = newValue!,
      onChanged: (value) {
        if (value.isNotEmpty) {
          removeError(error: kPassNullError);
        } else if (value.isNotEmpty && password == confirmPassword) {
          removeError(error: kMatchPassError);
        }
        confirmPassword = value;
      },
      validator: (value) {
        if (value!.isEmpty) {
          addError(error: kPassNullError);
          return "";
        } else if ((password != value)) {
          addError(error: kMatchPassError);
          return "";
        }
        return null;
      },
      // decoration: InputDecoration(
      labelText: "Confirm Password",
      hintText: "Re-enter your password",
      // If  you are using latest version of flutter then lable text and hint text shown like this
      // if you r using flutter less then 1.20.* then maybe this is not working properly
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: CustomSuffixIcon(
        iconData: Icons.lock,
      ),
      // ),
    );
  }

  Widget buildPasswordFormField() {
    return CustomTextField(
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
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
      // decoration: InputDecoration(
      labelText: "Password",
      hintText: "Enter your password",
      // If  you are using latest version of flutter then lable text and hint text shown like this
      // if you r using flutter less then 1.20.* then maybe this is not working properly
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: CustomSuffixIcon(
        iconData: Icons.lock,
      ),
      // ),
    );
  }

  Widget buildEmailFormField() {
    return CustomTextField(
      keyboardType: TextInputType.emailAddress,
      onSaved: (newValue) => email = newValue!,
      onChanged: (value) {
        if (value.isNotEmpty) {
          removeError(error: kEmailNullError);
        } else if (emailValidatorRegExp.hasMatch(value)) {
          removeError(error: kInvalidEmailError);
        }
        return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          addError(error: kEmailNullError);
          return "";
        } else if (!emailValidatorRegExp.hasMatch(value)) {
          addError(error: kInvalidEmailError);
          return "";
        }
        return null;
      },
      // decoration: InputDecoration(
      labelText: "Email",
      hintText: "Enter your email",
      // If  you are using latest version of flutter then lable text and hint text shown like this
      // if you r using flutter less then 1.20.* then maybe this is not working properly
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: CustomSuffixIcon(
        iconData: Icons.mail,
      ),
      // ),
    );
  }
}
