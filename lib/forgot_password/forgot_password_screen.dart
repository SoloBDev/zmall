import 'dart:async';
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/forgot_password/components/update_password.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/custom_text_field.dart';

class ForgotPassword extends StatefulWidget {
  static const String routeName = '/forgot';

  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool success = false;
  String _phone = '';
  String code = '';
  String _areaCode = "+251";
  String _country = "Ethiopia";
  String _email = '';
  var countries = ['Ethiopia', 'South Sudan'];

  @override
  void initState() {
    super.initState();
    // Initialize local state from ZMetaData
    _areaCode = Provider.of<ZMetaData>(context, listen: false).areaCode;
    _country = Provider.of<ZMetaData>(context, listen: false).country;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        appBar: AppBar(
          elevation: 1.0,
          automaticallyImplyLeading: false,
          leading: IconButton(
              onPressed: () {
                // Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
              },
              icon: Icon(Icons.arrow_back)),
          title: Text(
            "Forgot Password",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding, vertical: kDefaultPadding * 2),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(kDefaultPadding / 1.5),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding),
                            color: kWhiteColor),
                        child: Icon(
                          _areaCode == "+211"
                              ? HeroiconsOutline.envelope
                              : HeroiconsOutline.devicePhoneMobile,
                          size: 40,
                          color: kBlackColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: kDefaultPadding),
                      const Text(
                        "Reset Password",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      Text(
                        _areaCode == "+211"
                            ? "Please enter your phone and email to receive a one-time password (OTP)."
                            : "Please enter your phone number to receive a one-time password (OTP).",
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding * 2)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone number',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                          CustomTextField(
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            cursorColor: kSecondaryColor,
                            style: const TextStyle(color: kBlackColor),
                            onChanged: (value) => _phone = value,
                            isPhoneWithFlag: true,
                            initialSelection:
                                Provider.of<ZMetaData>(context, listen: false)
                                            .areaCode ==
                                        "+251"
                                    ? 'ET'
                                    : 'SS',
                            countryFilter: ['ET', 'SS'],
                            onFlagChanged: (CountryCode code) {
                              setState(() {
                                // debugPrint("code $code");
                                if (code.toString() == "+251") {
                                  _areaCode = "+251";
                                  _country = "Ethiopia";
                                } else {
                                  _areaCode = "+211";
                                  _country = "South Sudan";
                                }
                                // debugPrint("after _country $_country");
                                Provider.of<ZMetaData>(
                                  context,
                                  listen: false,
                                ).changeCountrySettings(_country);
                              });
                            },
                            validator: (value) {
                              if (value == null ||
                                  value.length != 9 ||
                                  !RegExp(r'^[97]').hasMatch(value)) {
                                return "Enter a valid phone number (9 digits, starts with 9)";
                              }
                              return null;
                            },
                            // labelText: 'Phone number',
                            hintText: "Phone start with 9 ...",
                          ),
                          if (_areaCode == "+211") ...[
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            CustomTextField(
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: kSecondaryColor,
                              style: const TextStyle(color: kBlackColor),
                              onChanged: (value) => _email = value,
                              // labelText: 'Email',
                              hintText: 'example@gmail.com',
                              validator: (value) {
                                if (_areaCode == "+211" &&
                                    (value == null ||
                                        !emailValidatorRegExp
                                            .hasMatch(value))) {
                                  return "Enter a valid email address";
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      CustomButton(
                          isLoading: _isLoading,
                          title: "Send Code",
                          color: kSecondaryColor,
                          press: () {
                            if (!_formKey.currentState!.validate()) {
                              Service.showMessage(
                                context: context,
                                title: "Please enter a valid phone number",
                                error: false,
                              );
                            } else {
                              sendOTP(_phone).then(
                                (success) {
                                  if (success) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UpdatePasswordScreen(
                                          phone: _phone,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            }
                            // ScaffoldMessenger.of(context)
                            //           .showSnackBar(Service.showMessage(
                            //               "Invalid phone number. Please check and try again.",
                            //               true));
                          }
                          // press: () {
                          //   if (_formKey.currentState!.validate()) {
                          //     _handleSendCode();
                          //   }
                          // },
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> sendOTP(phone) async {
    var response = await sendPhoneForOtp(phone);
    // print("response $response");
    if (response != null &&
        response["success"] != null &&
        response["success"]) {
      Service.showMessage(
          context: context,
          title: "OTP code sent to your phone...",
          error: false);
      setState(() {
        success = true;
      });
    }
    return success;
  }

  Future<dynamic> sendPhoneForOtp(String phone) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/forgot_password_with_otp";
    setState(() {
      _isLoading = true;
    });

    try {
      // String token = Uuid().v4();
      Map data = {
        "phone": phone,
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
      // print(json.decode(response.body)['message']);
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  ///////////////////////

  // Future<bool> _sendOTP(String phone, String email, String otp) async {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     Service.showMessage(
  //       "OTP code sent to your phone or email...",
  //       false,
  //       duration: 6,
  //     ),
  //   );

  //   final response = await _verificationSms(phone, email, otp);
  //   return response != null && response.statusCode == 200;
  // }

  // Future<http.Response?> _verificationSms(
  //   String phone,
  //   String email,
  //   String otp,
  // ) async {
  //   // debugPrint("otp $otp");
  //   final metaData = Provider.of<ZMetaData>(context, listen: false);
  //   final url = "${metaData.baseUrl}/api/admin/send_sms_with_message";
  //   final token = const Uuid().v4();
  //   final data = _areaCode == "+251"
  //       ? {
  //           "code": "${token}_zmall",
  //           "phone": phone,
  //           "message": "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ / OTP : $otp",
  //         }
  //       : {
  //           "code": "${token}_zmall",
  //           "phone": phone,
  //           "email": email,
  //           "message": "Verification code valid for 10 minutes/ OTP : $otp",
  //         };

  //   try {
  //     final response = await http
  //         .post(
  //           Uri.parse(url),
  //           headers: {"Content-Type": "application/json"},
  //           body: json.encode(data),
  //         )
  //         .timeout(
  //           const Duration(seconds: 10),
  //           onTimeout: () =>
  //               throw TimeoutException("The connection has timed out!"),
  //         );
  //     return response;
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // void _handleSendCode() async {
  //   setState(() => _isLoading = true);

  //   final metaData = Provider.of<ZMetaData>(context, listen: false);
  //   final fullPhone = "${metaData.areaCode}$_phone";

  //   // Validate phone number
  //   if (_phone == null ||
  //       _phone!.length != 9 ||
  //       !RegExp(r'^[97]').hasMatch(_phone!)) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       Service.showMessage("Please enter a valid phone number", true),
  //     );
  //     setState(() => _isLoading = false);
  //     return;
  //   }

  //   // Validate email for South Sudan (+211)
  //   if (_areaCode == "+211" &&
  //       (!_email.isNotEmpty || !emailValidatorRegExp.hasMatch(_email))) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       Service.showMessage("Please enter a valid email address", true),
  //     );
  //     setState(() => _isLoading = false);
  //     return;
  //   }

  //   setState(() => _smsCode = RandomDigits.getString(6));

  //   final success = await _sendOTP(fullPhone, _email, _smsCode!);
  //   setState(() => _isLoading = false);

  //   if (success) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => VerificationScreen(
  //           phone: _phone!,
  //           code: _smsCode!,
  //           areaCode: _areaCode,
  //         ),
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       Service.showMessage("Incorrect phone number", true),
  //     );
  //   }
  // }
  // ///////////////////////
}
// import 'dart:async';
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/custom_widgets/custom_button.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/random_digits.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';
// import 'components/update_password.dart';
// import 'components/verification_screen.dart';

// class ForgotPassword extends StatefulWidget {
//   static String routeName = '/forgot';
//   @override
//   _ForgotPasswordState createState() => _ForgotPasswordState();
// }

// class _ForgotPasswordState extends State<ForgotPassword> {
//   bool _loading = false;
//   String? phone;
//   String? smsCode;
//   bool success = false;

//   BuildContext? dialogueContext;
//   String areaCode = "+251";
//   String phoneMessage = "Start phone with 9 or 7";
//   String country = "Ethiopia";
//   var countries = ['Ethiopia', 'South Sudan'];

//   ///new
//   String email = '';

//   // Future<void> loginUser(String phone, BuildContext context) async {
//   //   debugPrint(phone);
//   //   setState(() {
//   //     _loading = true;
//   //   });
//   //   FirebaseAuth _auth = FirebaseAuth.instance;
//   //
//   //   _auth.verifyPhoneNumber(
//   //       phoneNumber: phone,
//   //       timeout: Duration(seconds: 60),
//   //       verificationCompleted: (AuthCredential credential) async {
//   //         Navigator.of(context).pop();
//   //         UserCredential result = await _auth.signInWithCredential(credential);
//   //         User? user = result!.user;
//   //         setState(() {
//   //           _loading = false;
//   //         });
//   //         if (user != null) {
//   //           Navigator.of(context).pop();
//   //           setState(() {
//   //             _loading = true;
//   //           });
//   //           ScaffoldMessenger.of(context).showSnackBar(
//   //               Service.showMessage(("Verification successful..."), false));
//   //           Navigator.pushReplacement(
//   //             context,
//   //             MaterialPageRoute(
//   //               builder: (context) => UpdatePasswordScreen(
//   //                 phone: phone,
//   //               ),
//   //             ),
//   //           );
//   //         } else {
//   //           debugPrint("Error");
//   //         }
//   //
//   //         //This callback would gets called when verification is done automatically
//   //       },
//   //       verificationFailed: (FirebaseAuthException exception) {
//   //         debugPrint(exception.message);
//   //         ScaffoldMessenger.of(context)
//   //             .showSnackBar(Service.showMessage(exception.message, true));
//   //         setState(() {
//   //           _loading = false;
//   //         });
//   //       },
//   //       codeSent: (String? verificationId, [int? forceResendingToken]) {
//   //         showDialog(
//   //             context: context,
//   //             barrierDismissible: false,
//   //             builder: (context) {
//   //               dialogueContext = context;
//   //               return AlertDialog(
//   //                 backgroundColor: kPrimaryColor,
//   //                 title: Text("Phone Number Verification"),
//   //                 content: Wrap(
//   //                   children: [
//   //                     Text(
//   //                         "Please enter the one time pin(OTP) sent to your phone.\n"),
//   //                     SizedBox(
//   //                       height: getProportionateScreenHeight(kDefaultPadding),
//   //                     ),
//   //                     TextField(
//   //                       controller: _codeController,
//   //                     ),
//   //                   ],
//   //                 ),
//   //                 actions: <Widget>[
//   //                   TextButton(
//   //                     onPressed: () {
//   //                       setState(() {
//   //                         _loading = false;
//   //                       });
//   //                       Navigator.of(context).pop();
//   //                     },
//   //                     child: Text(
//   //                       "Cancel",
//   //                       style: TextStyle(color: kGreyColor),
//   //                     ),
//   //                   ),
//   //                   CustomButton(
//   //                     title: "Confirm",
//   //                     color: kSecondaryColor,
//   //                     press: () async {
//   //                       final code = _codeController.text.trim();
//   //                       AuthCredential credential =
//   //                           PhoneAuthProvider.credential(
//   //                               verificationId: verificationId!, smsCode: code);
//   //
//   //                       UserCredential result =
//   //                           await _auth.signInWithCredential(credential);
//   //
//   //                       User? user = result.user;
//   //
//   //                       if (user != null) {
//   //                         Navigator.of(context).pop();
//   //                         setState(() {
//   //                           _loading = true;
//   //                         });
//   //                         ScaffoldMessenger.of(context).showSnackBar(
//   //                             Service.showMessage(
//   //                                 ("Verification successful..."), false));
//   //                         Navigator.pushReplacement(
//   //                           context,
//   //                           MaterialPageRoute(
//   //                             builder: (context) => UpdatePasswordScreen(
//   //                               phone: phone,
//   //                             ),
//   //                           ),
//   //                         );
//   //                       } else {
//   //                         debugPrint("Error while signing user");
//   //                         ScaffoldMessenger.of(context).showSnackBar(
//   //                             Service.showMessage(
//   //                                 ("Error while verifying phone number. Please try again"),
//   //                                 true));
//   //                         setState(() {
//   //                           _loading = false;
//   //                         });
//   //                         Navigator.of(context).pop();
//   //                       }
//   //                     },
//   //                   )
//   //                 ],
//   //               );
//   //             });
//   //       },
//   //       codeAutoRetrievalTimeout: (String verificationId) {
//   //         ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
//   //             ("Error while verifying phone number. Please try again"), true));
//   //         setState(() {
//   //           _loading = false;
//   //         });
//   //         if (dialogueContext != null) {
//   //           Navigator.of(dialogueContext).pop();
//   //         }
//   //       });
//   // }

//   Future<bool> sendOTP(phone, email, otp) async {
//     ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
//         "OTP code sent to your phone or email...", false,
//         duration: 6));
//     var response = await verificationSms(phone, email, otp);
//     if (response != null && response.statusCode == 200) {
//       setState(() {
//         success = true;
//       });
//     }
//     return success;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Forgot Password",
//           style: new TextStyle(
//             color: kBlackColor,
//           ),
//         ),
//         elevation: 1.0,
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(
//             horizontal: getProportionateScreenWidth(kDefaultPadding)),
//         child: Column(
//           children: [
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
//             // buildCountryDropDown(),
//             DropdownButtonFormField(
//               items: countries.map((String country) {
//                 return new DropdownMenuItem(
//                     value: country,
//                     child: Row(
//                       children: <Widget>[
//                         Text(country),
//                       ],
//                     ));
//               }).toList(),
//               onChanged: (String? newValue) {
//                 // do other stuff with _category
//                 Provider.of<ZMetaData>(context, listen: false)
//                     .changeCountrySettings(newValue!);
//                 setState(() {
//                   country = newValue;
//                   if (country == "Ethiopia") {
//                     // setUrl = testURL;
//                     phoneMessage = "Start phone number with 9 or 7...";
//                     areaCode = "+251";
//                   } else if (country == "South Sudan") {
//                     // setUrl = southSudan;
//                     phoneMessage = "Start phone number with 9...";
//                     areaCode = "+211";
//                   }
//                 });
//               },
//               value: Provider.of<ZMetaData>(context, listen: false).country,
//               decoration: textFieldInputDecorator.copyWith(
//                 labelText: "Country",
//               ),
//             ),
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
//             TextField(
//               keyboardType: TextInputType.phone,
//               maxLength: 9,
//               cursorColor: kSecondaryColor,
//               style: TextStyle(color: kBlackColor),
//               onChanged: (value) {
//                 phone = value;
//               },
//               decoration: InputDecoration(
//                 prefixText:
//                     Provider.of<ZMetaData>(context, listen: false).areaCode,
//                 hintText: 'Phone number',
//                 hintStyle: TextStyle(
//                   color: kGreyColor,
//                 ),
//                 focusedBorder: UnderlineInputBorder(
//                   borderSide: BorderSide(color: kSecondaryColor),
//                 ),
//               ),
//             ),
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
//             Offstage(
//               offstage:
//                   Provider.of<ZMetaData>(context, listen: false).areaCode ==
//                           "+251"
//                       ? true
//                       : false,
//               child: TextField(
//                 keyboardType: TextInputType.emailAddress,
//                 cursorColor: kSecondaryColor,
//                 style: TextStyle(color: kBlackColor),
//                 onChanged: (value) {
//                   setState(
//                     () {
//                       email = value;
//                     },
//                   );
//                 },
//                 decoration: InputDecoration(
//                   hintText: '     Email',
//                   hintStyle: TextStyle(
//                     color: kGreyColor,
//                   ),
//                   focusedBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(color: kSecondaryColor),
//                   ),
//                 ),
//               ),
//             ),
//             Spacer(),
//             Padding(
//               padding: EdgeInsets.symmetric(
//                   vertical: getProportionateScreenHeight(kDefaultPadding)),
//               child: _loading == true
//                   ? SpinKitWave(
//                       color: kSecondaryColor,
//                       size: getProportionateScreenWidth(kDefaultPadding),
//                     )
//                   : CustomButton(
//                       title: "Send Code",
//                       color: kSecondaryColor,
//                       press: () {
//                         setState(
//                           () {
//                             _loading = !_loading;
//                           },
//                         );

//                         if (phone == null ||
//                             phone?.length != 9 ||
//                             int.parse(phone![0]) != 9 &&
//                                 int.parse(phone![0]) != 7) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                               Service.showMessage(
//                                   "Please enter a valid phone number", false));
//                           setState(
//                             () {
//                               _loading = !_loading;
//                             },
//                           );
//                         } else if (Provider.of<ZMetaData>(context,
//                                     listen: false)
//                                 .areaCode !=
//                             "+251") {
//                           if (email == null ||
//                               !emailValidatorRegExp.hasMatch(email)) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                                 Service.showMessage(
//                                     "Please enter a valid email address",
//                                     true));
//                             setState(
//                               () {
//                                 _loading = !_loading;
//                               },
//                             );
//                           }
//                         } else {
//                           // loginUser(
//                           //     "${Provider.of<ZMetaData>(context, listen: false).areaCode}$phone",
//                           //     context);
//                           setState(() {
//                             smsCode = RandomDigits.getString(4);
//                           });
//                           sendOTP("${Provider.of<ZMetaData>(context, listen: false).areaCode}$phone",
//                                   email, smsCode)
//                               .then(
//                             (success) {
//                               if (success) {
//                                 _loading = !_loading;
//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => VerificationScreen(
//                                       phone: phone!,
//                                       code: smsCode!,
//                                       areaCode: areaCode,
//                                     ),
//                                   ),
//                                 );
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                     Service.showMessage(
//                                         "Incorrect phone number",
//                                         true)); // "ስልክ ቁጥር ተሳስተዋል"
//                                 setState(
//                                   () {
//                                     _loading = !_loading;
//                                   },
//                                 );
//                               }
//                             },
//                           );
//                         }
//                       }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<http.Response?> verificationSms(
//       String phone, String email, String otp) async {
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/send_sms_with_message";
//     String token = Uuid().v4();
//     Map data = Provider.of<ZMetaData>(context, listen: false).areaCode == "+251"
//         ? {
//             "code": "${token}_zmall",
//             "phone": phone,
//             "message": "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ / OTP : $otp"
//           }
//         : {
//             "code": "${token}_zmall",
//             "phone": phone,
//             "email": email,
//             "message": "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ / OTP : $otp"
//           };
//     var body = json.encode(data);
//     try {
//       http.Response response = await http
//           .post(
//         Uri.parse(url),
//         headers: <String, String>{"Content-Type": "application/json"},
//         body: body,
//       )
//           .timeout(
//         Duration(seconds: 10),
//         onTimeout: () {
//           throw TimeoutException("The connection has timed out!");
//         },
//       );
//       // debugPrint(json.decode(response.body)['message']);
//       return response;
//     } catch (e) {
//       // debugPrint(e);
//       return null;
//     }
//   }
// }
