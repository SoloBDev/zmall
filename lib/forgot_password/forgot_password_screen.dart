import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/random_digits.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'components/update_password.dart';
import 'components/verification_screen.dart';

class ForgotPassword extends StatefulWidget {
  static String routeName = '/forgot';
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  bool _loading = false;
  String? phone;
  String? smsCode;
  bool success = false;

  BuildContext? dialogueContext;
  String areaCode = "+251";
  String phoneMessage = "Start phone with 9 or 7";
  String country = "Ethiopia";
  var countries = ['Ethiopia', 'South Sudan'];

  ///new
  String email = '';

  // Future<void> loginUser(String phone, BuildContext context) async {
  //   print(phone);
  //   setState(() {
  //     _loading = true;
  //   });
  //   FirebaseAuth _auth = FirebaseAuth.instance;
  //
  //   _auth.verifyPhoneNumber(
  //       phoneNumber: phone,
  //       timeout: Duration(seconds: 60),
  //       verificationCompleted: (AuthCredential credential) async {
  //         Navigator.of(context).pop();
  //         UserCredential result = await _auth.signInWithCredential(credential);
  //         User? user = result!.user;
  //         setState(() {
  //           _loading = false;
  //         });
  //         if (user != null) {
  //           Navigator.of(context).pop();
  //           setState(() {
  //             _loading = true;
  //           });
  //           ScaffoldMessenger.of(context).showSnackBar(
  //               Service.showMessage(("Verification successful..."), false));
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => UpdatePasswordScreen(
  //                 phone: phone,
  //               ),
  //             ),
  //           );
  //         } else {
  //           print("Error");
  //         }
  //
  //         //This callback would gets called when verification is done automatically
  //       },
  //       verificationFailed: (FirebaseAuthException exception) {
  //         print(exception.message);
  //         ScaffoldMessenger.of(context)
  //             .showSnackBar(Service.showMessage(exception.message, true));
  //         setState(() {
  //           _loading = false;
  //         });
  //       },
  //       codeSent: (String? verificationId, [int? forceResendingToken]) {
  //         showDialog(
  //             context: context,
  //             barrierDismissible: false,
  //             builder: (context) {
  //               dialogueContext = context;
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
  //                   TextButton(
  //                     onPressed: () {
  //                       setState(() {
  //                         _loading = false;
  //                       });
  //                       Navigator.of(context).pop();
  //                     },
  //                     child: Text(
  //                       "Cancel",
  //                       style: TextStyle(color: kGreyColor),
  //                     ),
  //                   ),
  //                   CustomButton(
  //                     title: "Confirm",
  //                     color: kSecondaryColor,
  //                     press: () async {
  //                       final code = _codeController.text.trim();
  //                       AuthCredential credential =
  //                           PhoneAuthProvider.credential(
  //                               verificationId: verificationId!, smsCode: code);
  //
  //                       UserCredential result =
  //                           await _auth.signInWithCredential(credential);
  //
  //                       User? user = result.user;
  //
  //                       if (user != null) {
  //                         Navigator.of(context).pop();
  //                         setState(() {
  //                           _loading = true;
  //                         });
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                             Service.showMessage(
  //                                 ("Verification successful..."), false));
  //                         Navigator.pushReplacement(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder: (context) => UpdatePasswordScreen(
  //                               phone: phone,
  //                             ),
  //                           ),
  //                         );
  //                       } else {
  //                         print("Error while signing user");
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
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
  //             ("Error while verifying phone number. Please try again"), true));
  //         setState(() {
  //           _loading = false;
  //         });
  //         if (dialogueContext != null) {
  //           Navigator.of(dialogueContext).pop();
  //         }
  //       });
  // }

  Future<bool> sendOTP(phone, email, otp) async {
    ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
        "OTP code sent to your phone or email...", false,
        duration: 6));
    var response = await verificationSms(phone, email, otp);
    if (response != null && response.statusCode == 200) {
      setState(() {
        success = true;
      });
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Forgot Password",
          style: new TextStyle(
            color: kBlackColor,
          ),
        ),
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding)),
        child: Column(
          children: [
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
            // buildCountryDropDown(),
            DropdownButtonFormField(
              items: countries.map((String country) {
                return new DropdownMenuItem(
                    value: country,
                    child: Row(
                      children: <Widget>[
                        Text(country),
                      ],
                    ));
              }).toList(),
              onChanged: (String? newValue) {
                // do other stuff with _category
                Provider.of<ZMetaData>(context, listen: false)
                    .changeCountrySettings(newValue!);
                setState(() {
                  country = newValue;
                  if (country == "Ethiopia") {
                    // setUrl = testURL;
                    phoneMessage = "Start phone number with 9 or 7...";
                    areaCode = "+251";
                  } else if (country == "South Sudan") {
                    // setUrl = southSudan;
                    phoneMessage = "Start phone number with 9...";
                    areaCode = "+211";
                  }
                });
              },
              value: Provider.of<ZMetaData>(context, listen: false).country,
              decoration: textFieldInputDecorator.copyWith(
                labelText: "Country",
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
            TextField(
              keyboardType: TextInputType.phone,
              maxLength: 9,
              cursorColor: kSecondaryColor,
              style: TextStyle(color: kBlackColor),
              onChanged: (value) {
                phone = value;
              },
              decoration: InputDecoration(
                prefixText:
                    Provider.of<ZMetaData>(context, listen: false).areaCode,
                hintText: 'Phone number',
                hintStyle: TextStyle(
                  color: kGreyColor,
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kSecondaryColor),
                ),
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
            TextField(
              keyboardType: TextInputType.emailAddress,
              cursorColor: kSecondaryColor,
              style: TextStyle(color: kBlackColor),
              onChanged: (value) {
                setState(
                  () {
                    email = value;
                  },
                );
              },
              decoration: InputDecoration(
                hintText: '     Email',
                hintStyle: TextStyle(
                  color: kGreyColor,
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kSecondaryColor),
                ),
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              child: _loading == true
                  ? SpinKitWave(
                      color: kSecondaryColor,
                      size: getProportionateScreenWidth(kDefaultPadding),
                    )
                  : CustomButton(
                      title: "Send Code",
                      color: kSecondaryColor,
                      press: () {
                        setState(
                          () {
                            _loading = !_loading;
                          },
                        );

                        if (phone == null ||
                            phone?.length != 9 ||
                            int.parse(phone![0]) != 9 &&
                                int.parse(phone![0]) != 7) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please enter a valid phone number", false));
                          setState(
                            () {
                              _loading = !_loading;
                            },
                          );
                        } else if (email == null ||
                            !emailValidatorRegExp.hasMatch(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please enter a valid email address", false));
                          setState(
                            () {
                              _loading = !_loading;
                            },
                          );
                        } else {
                          // loginUser(
                          //     "${Provider.of<ZMetaData>(context, listen: false).areaCode}$phone",
                          //     context);
                          setState(() {
                            smsCode = RandomDigits.getString(4);
                          });
                          sendOTP("${Provider.of<ZMetaData>(context, listen: false).areaCode}$phone",
                                  email, smsCode)
                              .then(
                            (success) {
                              if (success) {
                                _loading = !_loading;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VerificationScreen(
                                      phone: phone!,
                                      code: smsCode!,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        "Incorrect phone number",
                                        true)); // "ስልክ ቁጥር ተሳስተዋል"
                                setState(
                                  () {
                                    _loading = !_loading;
                                  },
                                );
                              }
                            },
                          );
                        }
                      }),
            ),
          ],
        ),
      ),
    );
  }

  Future<http.Response?> verificationSms(
      String phone, String email, String otp) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/send_sms_with_message";
    String token = Uuid().v4();
    Map data = {
      "code": "${token}_zmall",
      "phone": phone,
      "email": email,
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
      // print(json.decode(response.body)['message']);
      return response;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
