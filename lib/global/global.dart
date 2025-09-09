import 'dart:async';
import 'dart:convert';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'home_page/global_home.dart';

class GlobalScreen extends StatefulWidget {
  static String routeName = '/global';

  @override
  State<GlobalScreen> createState() => _GlobalScreenState();
}

class _GlobalScreenState extends State<GlobalScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  String countryCode = '+1';
  String country = 'Ethiopia';
  String phoneWithCountryCode = '';
  String? smsCode;
  final List<String> errors = [];
  bool success = false;

  onCountryCodeChanged(CountryCode code) {
    // print("code $code");
    setState(() {
      countryCode = code.toString();
      country = code.toCountryStringOnly();
    });
  }

  // void addError({required String error}) {
  //   if (!errors.contains(error))
  //     setState(() {
  //       errors.add(error);
  //     });
  // }

  // void removeError({required String error}) {
  //   if (errors.contains(error))
  //     setState(() {
  //       errors.remove(error);
  //     });
  // }
  //firebase auth
  // Future<bool?> loginUser(String phone, BuildContext context) async {
  //   // debugPrint(phone);
  //   FirebaseAuth _auth = FirebaseAuth.instance;

  //   _auth.verifyPhoneNumber(
  //       phoneNumber: phone,
  //       timeout: Duration(seconds: 60),
  //       verificationCompleted: (AuthCredential credential) async {
  //         Navigator.of(context).pop();
  //         // debugPrint("Verification completed...");
  //         UserCredential result = await _auth.signInWithCredential(credential);
  //         User user = result.user!;
  //         setState(() {
  //           _loading = false;
  //         });
  //         if (user != null) {
  //           // debugPrint(user);
  //           Service.saveBool('is_global', true);
  //           Service.save('global_user_id', user.uid);
  //           Navigator.pushReplacement(
  //               context, MaterialPageRoute(builder: (context) => GlobalHome()));
  //         } else {
  //           Navigator.pushReplacement(context,
  //               MaterialPageRoute(builder: (context) => LoginScreen()));
  //           // debugPrint("Error");
  //         }

  //         //This callback would gets called when verification is done automatically
  //       },
  //       verificationFailed: (FirebaseAuthException exception) {
  //         // debugPrint(exception.message);
  //         ScaffoldMessenger.of(context)
  //             .showSnackBar(Service.showMessage1(exception.message, true));
  //         setState(() {
  //           _loading = false;
  //         });
  //       },
  //       codeSent: (String verificationId, [int? forceResendingToken]) {
  //         showDialog(
  //             context: context,
  //             barrierDismissible: false,
  //             builder: (context) {
  //               return AlertDialog(
  //                 title: Text("OTP?"),
  //                 backgroundColor: kPrimaryColor,
  //                 content: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: <Widget>[
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
  //                         Service.saveBool('is_global', true);
  //                         Service.save('global_user_id', user.uid);
  //                         // bool success =
  //                         //     await FirebaseCoreServices.addDataToUserProfile(
  //                         //         user.uid, {
  //                         //   "phone": phoneWithCountryCode,
  //                         //   "country": country,
  //                         //   "country_phone_code": countryCode,
  //                         //   "wallet": 0,
  //                         //   "order_count": 0,
  //                         //   "full_name": "",
  //                         //   "email": "",
  //                         //   "city": "",
  //                         // });
  //                         // if (success) {
  //                         //   ScaffoldMessenger.of(context).showSnackBar(
  //                         //       Service.showMessage("Data saved", false));
  //                         // } else {
  //                         //   ScaffoldMessenger.of(context).showSnackBar(
  //                         //     Service.showMessage(
  //                         //         "Something went wrong, data wasn't saved",
  //                         //         true),
  //                         //   );
  //                         // }
  //                         Navigator.pushReplacement(
  //                             context,
  //                             MaterialPageRoute(
  //                                 builder: (context) => GlobalHome()));
  //                       } else {
  //                         // debugPrint("Error while signing user");
  //                       }
  //                     },
  //                   )
  //                 ],
  //               );
  //             });
  //       },
  //       codeAutoRetrievalTimeout: ((verificationId) {}));
  // }

  void saveGlobal() async {
    var data = await Service.readBool('is_global');
    if (data == null) {
      await Service.saveBool('is_global', true);
    }
  }

  Future<bool> verifyAndLoginUser(phone, email, firstName, lastName) async {
    var response = await verificationEmail(email);
    if (response != null && response['success']) {
      // debugPrint("<<<<OTP>>>> $response");
      setState(() {
        success = true;
        smsCode = response['otp'];
      });
    }
    return success;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SizedBox(
        height: getProportionateScreenWidth(60),
        child: SafeArea(
          child: Center(
            child: TextButton(
              onPressed: () {
                Service.saveBool('is_global', false);
                Navigator.pushNamedAndRemoveUntil(
                    context, "/login", (Route<dynamic> route) => false);
              },
              child: Text(
                "Change to ZMall Ethiopia?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  //    decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding:
                EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
            child: Form(
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          text: "Z",
                          style: TextStyle(
                            color: kSecondaryColor,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * 1.6),
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: "Mall Global",
                              style: TextStyle(
                                color: kBlackColor,
                                fontSize: getProportionateScreenWidth(
                                    kDefaultPadding * 1.6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 2),
                      ),
                      Text(
                        "Login",
                        style: TextStyle(
                            color: kBlackColor,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * 1.3),
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      Text(
                        "Phone Number",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      CustomTextField(
                        // decoration: textFieldInputDecorator.copyWith(
                        // labelText: "Phone Number",
                        isPhoneWithFlag: true,
                        initialSelection: 'US',
                        favorite: ['US', 'FR'],
                        hideSearch: false,
                        onFlagChanged: onCountryCodeChanged,
                        dialogSize: Size.fromHeight(
                            getProportionateScreenHeight(double.maxFinite)),
                        hintText: "Without country code...",

                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter your phone number";
                          } else if (value.length < 5) {
                            return "Please enter a valid phone number";
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      Text(
                        "Email",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      CustomTextField(
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        hintText: "Enter your email",
                        validator: (value) {
                          if (value!.isEmpty) {
                            return kEmailNullError;
                          } else if (!emailValidatorRegExp.hasMatch(value)) {
                            return kInvalidEmailError;
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      Text(
                        "First name",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      CustomTextField(
                        controller: _firstName,
                        keyboardType: TextInputType.name,
                        hintText: "Enter your name",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }

                          return null;
                        },
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      Text(
                        "Last name",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      CustomTextField(
                        controller: _lastName,
                        keyboardType: TextInputType.name,
                        hintText: "Enter your last name",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last';
                          }

                          return null;
                        },
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 1.5),
                      ),
                      CustomButton(
                        isLoading: _loading,
                        title: "Send Verification Code",
                        color: kSecondaryColor,
                        press: () {
                          if (_formKey.currentState!.validate()) {
                            var phone = _phoneController.text.trim();
                            var email = _emailController.text.trim();
                            var firstName = _firstName.text.trim();
                            var lastName = _lastName.text.trim();
                            setState(() {
                              _loading = true;
                            });
                            if (phone.isNotEmpty &&
                                email.isNotEmpty &&
                                firstName.isNotEmpty &&
                                lastName.isNotEmpty) {
                              phoneWithCountryCode = "$countryCode$phone";
                              // debugPrint(phoneWithCountryCode);
                              // debugPrint("$email $firstName $lastName");
                              verifyAndLoginUser(phoneWithCountryCode, email,
                                      firstName, lastName)
                                  .then(
                                (success) {
                                  if (success) {
                                    _loading = !_loading;
                                    _showOtpBottomSheet(
                                      email: email,
                                      lastName: lastName,
                                      firstName: firstName,
                                    );
                                  }
                                },
                              );
                            }

                            // loginUser(phoneWithCountryCode, context);
                            // } else {
                            //   setState(() {
                            //     _loading = false;
                            //   });
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //       Service.showMessage1(
                            //           "Phone number cannot be empty", true));
                          }
                        },
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

  void _showOtpBottomSheet({
    required String email,
    required String firstName,
    required String lastName,
  }) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: kPrimaryColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(kDefaultPadding)),
        builder: (context) {
          return SafeArea(
            minimum: MediaQuery.of(context).viewInsets,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
              decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadiusGeometry.circular(kDefaultPadding)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Account Verification",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(HeroiconsOutline.xCircle),
                      )
                    ],
                  ),
                  Text(
                    "Please enter the one time pin(OTP) sent to your email.",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding * 2),
                  ),
                  CustomTextField(
                    controller: _codeController,
                    hintText: "Enter an OTP",
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  CustomButton(
                    title: "Confirm",
                    color: kSecondaryColor,
                    press: () async {
                      final code = _codeController.text.trim();

                      if (code == smsCode) {
                        await Service.saveBool('is_global', true);
                        await Service.save(
                            'global_user_id', phoneWithCountryCode);
                        AbroadData abroadData = AbroadData(
                            abroadEmail: email,
                            abroadPhone: phoneWithCountryCode,
                            abroadName: "$firstName $lastName");
                        await Service.save("abroad_user", abroadData);
                        Navigator.of(context).pop();
                        setState(() {
                          _loading = true;
                        });

                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GlobalHome()));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            Service.showMessage1(
                                ("Error while verifying phone number. Please try again"),
                                true));
                        setState(() {
                          _loading = false;
                        });
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<dynamic> verificationEmail(String email) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/simple_email_otp_verification";

    Map data = {
      "email": email,
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
        Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }
}
