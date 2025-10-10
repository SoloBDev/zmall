import 'dart:async';
import 'dart:convert';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/register/components/custom_suffix_icon.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/custom_text_field.dart';

class UpdatePasswordScreen extends StatefulWidget {
  static String id = '/password';

  UpdatePasswordScreen({required this.phone});
  final String phone;

  @override
  _UpdatePasswordScreenState createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String phone = '';
  String code = '';
  String newPassword = '';
  String confirmPassword = '';
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    phone = widget.phone;
    super.initState();
  }

  // Future<Timer> loading() async {
  //   return Timer(Duration(seconds: 5), onDoneLoading);
  // }

  // onDoneLoading() async {
  //   _loading = !_loading;
  // }

  void updatePassword(code, phone, nPassword) async {
    setState(() {
      _loading = true;
    });
    try {
      var data = await updatePass(code, phone, nPassword);
      // print("data $data");
      // if (data != null && data['success']) {
      if (data != null && data["success"] != null && data["success"]) {
        Service.showMessage(
            context: context,
            title: "Password updated successfully",
            error: false);

        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else {
        Service.showMessage(
            context: context,
            title: "Failed to update password, please try again later",
            error: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      // print("error $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: kPrimaryColor,
        appBar: AppBar(
          title: Text(
            "Update Password",
            style: new TextStyle(
              color: kBlackColor,
            ),
          ),
          elevation: 1.0,
        ),
        body: Padding(
          padding:
              EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(kDefaultPadding),
                    vertical: getProportionateScreenHeight(kDefaultPadding)),
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
                    spacing: kDefaultPadding * 1.5,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(kDefaultPadding / 1.5),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding),
                                color: kWhiteColor),
                            child: Icon(
                              HeroiconsOutline.lockClosed,
                              size: 40,
                              color: kBlackColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: kDefaultPadding / 2),
                          const Text(
                            "Reset Password",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "Update your password by entering a new one.",
                          ),
                        ],
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 4)),
                      buildOtpFormField(),
                      buildPasswordFormField(),
                      buildConformPassFormField(),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 8)),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CustomButton(
                            isLoading: _loading,
                            title: "Update Password",
                            color: kSecondaryColor,
                            press: () {
                              // debugPrint("Updating password");
                              if (_formKey.currentState!.validate()) {
                                updatePassword(code, phone, newPassword);
                              }
                            }),
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

  buildOtpFormField() {
    return CustomTextField(
      // obscureText: !_showPassword,
      onSaved: (newValue) => code = newValue!,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        code = value;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return "An OTP is required";
        }
        if (value.length < 4) {
          return "An OTP must be at least 4 digits long";
        }
        return null;
      },
      // labelText: "OTP",
      hintText: " Enter your OTP",
      prefix: CustomSuffixIcon(
        iconData: HeroiconsOutline.key,
      ),
    );
  }

  buildPasswordFormField() {
    return CustomTextField(
      obscureText: !_showPassword,
      onSaved: (newValue) => newPassword = newValue!,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.visiblePassword,
      onChanged: (value) {
        newPassword = value;
      },
      validator: (value) {
        if (!passwordRegex.hasMatch(value!)) {
          return kPasswordErrorMessage;
        }
        return null;
      },
      // labelText: "New Password",
      hintText: " Enter new password",
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _showPassword = !_showPassword;
          });
        },
        icon: Icon(
            _showPassword ? HeroiconsOutline.eyeSlash : HeroiconsOutline.eye),
      ),
      prefix: CustomSuffixIcon(
        iconData: HeroiconsOutline.lockClosed,
      ),
    );
  }

  buildConformPassFormField() {
    return CustomTextField(
      obscureText: !_showConfirmPassword,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.visiblePassword,
      onSaved: (newValue) => confirmPassword = newValue!,
      onChanged: (value) {
        confirmPassword = value;
      },
      validator: (value) {
        if (newPassword != value) {
          return kMatchPassError;
        }
        return null;
      },
      // labelText: "Confirm Password",
      hintText: " Confirm your password", //Re-enter
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _showConfirmPassword = !_showConfirmPassword;
          });
        },
        icon: Icon(_showConfirmPassword
            ? HeroiconsOutline.eyeSlash
            : HeroiconsOutline.eye),
      ),
      prefix: CustomSuffixIcon(
        iconData: HeroiconsOutline.lockClosed,
      ),
    );
  }

  Future<dynamic> updatePass(
      String code, String phone, String nPassword) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/reset_password";
    // String token = Uuid().v4();

    setState(() {
      _loading = true;
    });

    Map data = {
      "code": code,
      "phone": phone,
      "newPassword": nPassword,
    };
    var body = json.encode(data);
    // print("body $body");
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
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      // print(json.decode(response.body)['message']);
      return json.decode(response.body);
    } catch (e) {
      // print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
////old
  // Future<dynamic> updatePass(String phone, String nPassword) async {
  //   var url =
  //       "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/forgot_password";
  //   Map data = {
  //     "phone": phone
  //     // .split(
  //     // "${Provider.of<ZMetaData>(context, listen: false).areaCode}")[1]
  //     ,
  //     "password": nPassword
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
  //       Duration(seconds: 10),
  //       onTimeout: () {
  //         setState(() {
  //           this._loading = false;
  //         });
  //         throw TimeoutException("The connection has timed out!");
  //       },
  //     );
  //     setState(() {
  //       this._loading = false;
  //     });

  //     return json.decode(response.body);
  //   } catch (e) {
  //     // debugPrint(e);
  //     setState(() {
  //       this._loading = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //             "Something went wrong! Please check your internet connection!"),
  //         backgroundColor: kSecondaryColor,
  //       ),
  //     );
  //     return null;
  //   }
  // }
}
