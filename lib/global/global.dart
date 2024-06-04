import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/firebase_core_services.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/random_digits.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'home_page/global_home.dart';

class GlobalScreen extends StatefulWidget {
  static String routeName = '/global';

  @override
  State<GlobalScreen> createState() => _GlobalScreenState();
}

class _GlobalScreenState extends State<GlobalScreen> {
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
    setState(() {
      countryCode = code.toString();
      country = code.toCountryStringOnly();
    });
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

  Future<bool?> loginUser(String phone, BuildContext context) async {
    print(phone);
    FirebaseAuth _auth = FirebaseAuth.instance;

    _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: Duration(seconds: 60),
        verificationCompleted: (AuthCredential credential) async {
          Navigator.of(context).pop();
          print("Verification completed...");
          UserCredential result = await _auth.signInWithCredential(credential);
          User user = result.user!;
          setState(() {
            _loading = false;
          });
          if (user != null) {
            print(user);
            Service.saveBool('is_global', true);
            Service.save('global_user_id', user.uid);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => GlobalHome()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => LoginScreen()));
            print("Error");
          }

          //This callback would gets called when verification is done automatically
        },
        verificationFailed: (FirebaseAuthException exception) {
          print(exception.message);
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage(exception.message, true));
          setState(() {
            _loading = false;
          });
        },
        codeSent: (String verificationId, [int? forceResendingToken]) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: Text("OTP?"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: _codeController,
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    CustomButton(
                      title: "Confirm",
                      color: kSecondaryColor,
                      press: () async {
                        final code = _codeController.text.trim();
                        AuthCredential credential =
                            PhoneAuthProvider.credential(
                                verificationId: verificationId, smsCode: code);

                        UserCredential result =
                            await _auth.signInWithCredential(credential);

                        User user = result.user!;

                        if (user != null) {
                          Service.saveBool('is_global', true);
                          Service.save('global_user_id', user.uid);
                          // bool success =
                          //     await FirebaseCoreServices.addDataToUserProfile(
                          //         user.uid, {
                          //   "phone": phoneWithCountryCode,
                          //   "country": country,
                          //   "country_phone_code": countryCode,
                          //   "wallet": 0,
                          //   "order_count": 0,
                          //   "full_name": "",
                          //   "email": "",
                          //   "city": "",
                          // });
                          // if (success) {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //       Service.showMessage("Data saved", false));
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     Service.showMessage(
                          //         "Something went wrong, data wasn't saved",
                          //         true),
                          //   );
                          // }
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      GlobalHome()));
                        } else {
                          print("Error while signing user");
                        }
                      },
                    )
                  ],
                );
              });
        },
        codeAutoRetrievalTimeout: ((verificationId) {}));
  }

  void saveGlobal() async {
    var data = await Service.readBool('is_global');
    if (data == null) {
      await Service.saveBool('is_global', true);
    }
  }

  Future<bool> verifyAndLoginUser(phone,email,firstName,lastName) async {
    var response = await verificationEmail(email);
    if (response != null && response['success']) {
      print(response);
      setState(() {
        success = true;
        smsCode = response['otp'];
      });
    }
    return success;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        title: Text.rich(
          TextSpan(
            text: "Z",
            style: TextStyle(
              color: kSecondaryColor,
              fontSize:
              getProportionateScreenWidth(kDefaultPadding * 1.8),
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: "Mall Global",
                style: TextStyle(
                  color: kBlackColor,
                  fontSize: getProportionateScreenWidth(
                      kDefaultPadding * 1.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Form(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  Text(
                    "LOGIN",
                    style: TextStyle(
                        color: kBlackColor,
                        fontSize:
                            getProportionateScreenWidth(kDefaultPadding * 1.8),
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding * 0.75),
                  ),
                  Container(
                    child: Row(
                      children: [
                        CountryCodePicker(
                          onChanged: onCountryCodeChanged,
                          // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
                          initialSelection: 'US',
                          favorite: ['US', 'FR'],
                          // optional. Shows only country name and flag
                          showCountryOnly: false,
                          // optional. Shows only country name and flag when popup is closed.
                          showOnlyCountryWhenClosed: false,
                          // optional. aligns the flag and the Text left
                          alignLeft: false,
                        ),
                        Text("Please choose your country code..."),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding * 0.75),
                  ),
                  TextFormField(
                    decoration: textFieldInputDecorator.copyWith(
                      labelText: "Phone Number",
                      hintText: "Without country code...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                        ),
                        borderSide:
                            BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        borderSide:
                            BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    controller: _phoneController,
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding * 0.75),
                  ),
                  TextFormField(
                    decoration: textFieldInputDecorator.copyWith(
                      labelText: "Email",
                      filled: true,
                      fillColor: Colors.grey[100],

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                        ),
                        borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,

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
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding * 0.75),
                  ),
                  TextFormField(
                    decoration: textFieldInputDecorator.copyWith(
                      labelText: "First Name",
                      filled: true,
                      fillColor: Colors.grey[100],
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                        ),
                        borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    controller: _firstName,
                    keyboardType: TextInputType.name,
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding * 0.75),
                  ),
                  TextFormField(
                    decoration: textFieldInputDecorator.copyWith(
                      labelText: "Last Name",
                      filled: true,
                      fillColor: Colors.grey[100],
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                        ),
                        borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        borderSide:
                        BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    controller: _lastName,
                    keyboardType: TextInputType.name,
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  _loading
                      ? SpinKitWave(
                          size: getProportionateScreenHeight(kDefaultPadding),
                          color: kSecondaryColor,
                        )
                      : CustomButton(
                          title: "Send Verification Code",
                          color: kSecondaryColor,
                          press: () {
                            var phone = _phoneController.text.trim();
                            var email = _emailController.text.trim();
                            var firstName = _firstName.text.trim();
                            var lastName = _lastName.text.trim();
                            setState(() {
                              _loading = true;
                            });
                            if (phone.isNotEmpty && email.isNotEmpty && firstName.isNotEmpty && lastName.isNotEmpty) {
                              phoneWithCountryCode = "$countryCode$phone";
                              print(phoneWithCountryCode);
                              print("$email $firstName $lastName");
                              verifyAndLoginUser(phoneWithCountryCode, email, firstName, lastName).then(
                                    (success) {
                                  if (success) {
                                    _loading = !_loading;
                                    showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Account Verification"),
                                            content: Wrap(
                                              children: [
                                                Text(
                                                    "Please enter the one time pin(OTP) sent to your email.\n"),
                                                SizedBox(
                                                  height: getProportionateScreenHeight(kDefaultPadding),
                                                ),
                                                TextField(
                                                  controller: _codeController,
                                                ),
                                              ],
                                            ),
                                            actions: <Widget>[
                                              CustomButton(
                                                title: "Confirm",
                                                color: kSecondaryColor,
                                                press: () async {
                                                  final code = _codeController.text.trim();


                                                  if (code == smsCode) {
                                                    await Service.saveBool('is_global', true);
                                                    await Service.save('global_user_id',phoneWithCountryCode);
                                                    AbroadData abroadData = AbroadData(abroadEmail: email, abroadPhone: phoneWithCountryCode, abroadName: "$firstName $lastName");
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
                                                        Service.showMessage(
                                                            ("Error while verifying phone number. Please try again"),
                                                            true));
                                                    setState(() {
                                                      _loading = false;
                                                    });
                                                    Navigator.of(context).pop();
                                                    Navigator.pushReplacement(context,
                                                        MaterialPageRoute(builder: (context) => LoginScreen()));
                                                  }
                                                },
                                              )
                                            ],
                                          );
                                        });
                                  }
                                },
                              );

                              // loginUser(phoneWithCountryCode, context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Phone number cannot be empty", true));
                            }
                          },
                        ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Service.saveBool('is_global', false);
                        Navigator.pushNamedAndRemoveUntil(
                            context, "/login", (Route<dynamic> route) => false);
                      },
                      child: Text(
                        "Change to ZMall Ethiopia?",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> verificationEmail(String email) async {
    var url =
        "https://app.zmallapp.com/api/admin/simple_email_otp_verification";
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
      print(e);
      return null;
    }
  }
}
