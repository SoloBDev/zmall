import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/random_digits.dart';
import 'package:zmall/register/components/custom_suffix_icon.dart';
import 'package:zmall/service.dart';
import 'package:http/http.dart' as http;
import '../../../constants.dart';
import '../../../size_config.dart';
import 'form_error.dart';

class CompleteProfileForm extends StatefulWidget {
  const CompleteProfileForm({
    Key? key,
    @required this.email,
    @required this.password,
    @required this.confirmPassword,
  }) : super(key: key);

  @override
  _CompleteProfileFormState createState() => _CompleteProfileFormState();

  final String? email, password, confirmPassword;
}

class _CompleteProfileFormState extends State<CompleteProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String> errors = [];
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? address;
  var countries = ['Ethiopia', 'South Sudan'];
  String country = "Ethiopia";
  String city = "Addis Ababa";
  String setUrl = BASE_URL;
  String areaCode = "+251";
  String phoneMessage = "Start phone with 9 or 7";
  bool _loading = false;
  bool success = false;
  final _codeController = TextEditingController();
  String? smsCode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

  Future<bool> sendOTP(phone, email, otp) async {
    var response = await verificationSms(phone, email, otp);
    if (response != null && response['success']) {
      setState(() {
        success = true;
      });
    }
    return success;
  }

  Future<void> verifyUser(String phone, BuildContext context) async {
    setState(() {
      _loading = true;
    });
    FirebaseAuth _auth = FirebaseAuth.instance;

    _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: Duration(seconds: 60),
        verificationCompleted: (AuthCredential credential) async {
          if (_codeController.text.isEmpty) {
            await _register();
          }

          UserCredential result = await _auth.signInWithCredential(credential);
          Navigator.of(context).pop();
          User? user = result.user;
          setState(() {
            _loading = false;
          });
          if (user != null) {
            await _register();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
                "Verification failed...",
                true)); // ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            //     "Something went wrong. Please try to login if you have already registered.",
            //     true));
            Navigator.of(context).pop();
          }
          //This callback would gets called when verification is done automatically
        },
        verificationFailed: (FirebaseAuthException exception) {
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage(exception.message, true));
          setState(() {
            _loading = false;
          });
        },
        codeSent: (verificationId, forceResending) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: kPrimaryColor,
                  title: Text("Phone Number Verification"),
                  content: Wrap(
                    children: [
                      Text(
                          "Please enter the one time pin(OTP) sent to your phone.\n"),
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
                        AuthCredential credential =
                            PhoneAuthProvider.credential(
                                verificationId: verificationId, smsCode: code);

                        UserCredential result =
                            await _auth.signInWithCredential(credential);

                        User? user = result.user;

                        if (user != null) {
                          Navigator.of(context).pop();
                          setState(() {
                            _loading = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  ("Verification successful. Registering user.."),
                                  false));
                          await _register();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  ("Error while verifying phone number. Please try again"),
                                  true));
                          setState(() {
                            _loading = false;
                          });
                          Navigator.of(context).pop();
                        }
                      },
                    )
                  ],
                );
              });
        },
        codeAutoRetrievalTimeout: (String verificationId) {});
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
    });
    var data = await register();
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage(
          "Registration successful. Ready to login!",
          false,
          duration: 3,
        ),
      );
      await MyApp.analytics.logEvent(name: "user_registered");
      Navigator.pushNamedAndRemoveUntil(
          context, LoginScreen.routeName, (Route<dynamic> route) => false);
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      if (data['error_code'] == 503) {
        Navigator.pushNamedAndRemoveUntil(
            context, LoginScreen.routeName, (Route<dynamic> route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          buildFirstNameFormField(),
          SizedBox(height: getProportionateScreenHeight(30)),
          buildLastNameFormField(),
          SizedBox(height: getProportionateScreenHeight(30)),
          buildCountryDropDown(),
          SizedBox(height: getProportionateScreenHeight(30)),
          buildPhoneNumberFormField(),
          FormError(errors: errors),
          SizedBox(height: getProportionateScreenHeight(40)),
          _loading
              ? SpinKitWave(
                  size: getProportionateScreenHeight(kDefaultPadding),
                  color: kSecondaryColor,
                )
              : CustomButton(
                  title: "Verify Phone",
                  color: kSecondaryColor,
                  press: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        smsCode = RandomDigits.getString(4);
                      });
                      sendOTP("${Provider.of<ZMetaData>(context, listen: false).areaCode}$phoneNumber",
                              widget.email, smsCode)
                          .then(
                        (success) {
                          if (success) {
                            _loading = !_loading;
                            // Navigator.pushReplacement(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => VerificationScreen(
                            //       phone: phoneNumber!,
                            //       code: smsCode!,
                            //     ),
                            //   ),
                            // );
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: kPrimaryColor,
                                    title: Text("Phone Number Verification"),
                                    content: Wrap(
                                      children: [
                                        Text(
                                            "Please enter the one time password(OTP) sent to your phone or email.\n"),
                                        SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding),
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
                                          final code =
                                              _codeController.text.trim();

                                          if (code == smsCode) {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              _loading = true;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(Service.showMessage(
                                                    ("Verification successful. Registering user.."),
                                                    false));
                                            await _register();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(Service.showMessage(
                                                    ("Error while verifying phone number. Please try again"),
                                                    true));
                                            setState(() {
                                              _loading = false;
                                            });
                                            Navigator.of(context).pop();
                                          }
                                        },
                                      )
                                    ],
                                  );
                                });
                          } else {
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //     Service.showMessage(
                            //         "ስልክ ቁጥር ተሳስተዋል", true));
                            verifyUser(
                                "${Provider.of<ZMetaData>(context, listen: false).areaCode}$phoneNumber",
                                context);
                          }
                        },
                      );
                    }
                  },
                ),
        ],
      ),
    );
  }

  TextFormField buildAddressFormField() {
    return TextFormField(
      onSaved: (newValue) => address = newValue!,
      onChanged: (value) {
        if (value.isNotEmpty) {
          removeError(error: kAddressNullError);
        }
        return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          addError(error: kAddressNullError);
          return "";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: "Address",
        hintText: "Enter your phone address",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          iconData: Icons.person_pin_circle_rounded,
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
        Provider.of<ZMetaData>(context, listen: false)
            .changeCountrySettings(newValue.toString());
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
      value: country,
    );
  }

  TextFormField buildPhoneNumberFormField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      maxLength: 9,
      onSaved: (newValue) => phoneNumber = newValue!,
      onChanged: (value) {
        phoneNumber = value;
        if (value.isNotEmpty) {
          removeError(error: kPhoneInvalidError);
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
        labelText: "Phone Number",
        prefix: Text(Provider.of<ZMetaData>(context, listen: false).areaCode),
        hintText: "Enter your phone number",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          iconData: Icons.phone,
        ),
      ),
    );
  }

  TextFormField buildLastNameFormField() {
    return TextFormField(
      onSaved: (newValue) => lastName = newValue!,
      onChanged: (value) => lastName = value,
      decoration: InputDecoration(
        labelText: "Last Name",
        hintText: "Enter your last name",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          iconData: Icons.account_circle_rounded,
        ),
      ),
    );
  }

  TextFormField buildFirstNameFormField() {
    return TextFormField(
      onSaved: (newValue) => firstName = newValue!,
      onChanged: (value) {
        firstName = value;
        if (value.isNotEmpty) {
          removeError(error: kNameNullError);
        }
        return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          addError(error: kNameNullError);
          return "";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: "First Name",
        hintText: "Enter your first name",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          iconData: Icons.account_circle_rounded,
        ),
      ),
    );
  }

  Future<dynamic> register() async {
    var url = "$setUrl/api/user/register";
    Map data = {
      "country_id": Provider.of<ZMetaData>(context, listen: false).countryId,
      "email": widget.email,
      "phone": phoneNumber,
      "first_name": firstName,
      "last_name": lastName,
      "password": widget.password,
      "country_phone_code":
          Provider.of<ZMetaData>(context, listen: false).areaCode,
      "city": Provider.of<ZMetaData>(context, listen: false).cityId,
      "referral_code": "referralCode",
      "address": address,
      "is_phone_number_verified": true,
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
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Future<dynamic> verificationSms(
      String phone, String email, String otp) async {
    /*  var message =
        Provider.of<ZMetaData>(context, listen: false).areaCode == "+251"
            ? "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ / OTP"
            : "Verification code valid for 10 minutes / OTP"; */
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/send_sms_with_message";
    String token = Uuid().v4();
    Map data = {
      "code": "${token}_zmall",
      "phone": phone,
      "email": email,
      "message": "ለ 10 ደቂቃ የሚያገለግል ማረጋገጫ ኮድ  : $otp"
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
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      return null;
    }
  }
}
