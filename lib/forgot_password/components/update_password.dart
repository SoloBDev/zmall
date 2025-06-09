import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
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
  late String phone;
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

  Future<Timer> loading() async {
    return Timer(Duration(seconds: 5), onDoneLoading);
  }

  onDoneLoading() async {
    _loading = !_loading;
  }

  void updatePassword(phone, nPassword) async {
    setState(() {
      _loading = !_loading;
    });
    var data = await updatePass(phone, nPassword);
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage("Password updated", false),
      );

      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage("Failed, please try again later", true),
      );
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Reset Password",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Update your password by entering a new one.",
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding * 2)),
                      CustomTextField(
                        keyboardType: TextInputType.text,
                        cursorColor: kSecondaryColor,
                        obscureText: !_showPassword,
                        style: TextStyle(color: kBlackColor),
                        onChanged: (value) {
                          newPassword = value;
                        },
                        // decoration: InputDecoration(
                        hintText: 'Enter your password',
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(_showPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (!passwordRegex.hasMatch(value)) {
                            return "Password must be at least 8 characters, with uppercase, lowercase, number, and special character (@\$!%*?&)";
                          }
                          return null; // Return null if validation passes
                        },
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding * 1.2)),
                      CustomTextField(
                        keyboardType: TextInputType.text,
                        cursorColor: kSecondaryColor,
                        obscureText: !_showConfirmPassword,
                        style: TextStyle(color: kBlackColor),
                        onChanged: (value) {
                          confirmPassword = value;
                        },
                        labelText: 'Confirm password',
                        hintText: 'Confirm your password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          icon: Icon(_showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != newPassword) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding * 2)),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: _loading
                            ? SpinKitWave(
                                color: kSecondaryColor,
                                size: getProportionateScreenHeight(
                                    kDefaultPadding),
                              )
                            : CustomButton(
                                title: "Update Password",
                                color: kSecondaryColor,
                                press: () {
                                  print("Updating password");
                                  if (_formKey.currentState!.validate()) {
                                    updatePassword(phone, newPassword);
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

  Future<dynamic> updatePass(String phone, String nPassword) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/forgot_password";
    Map data = {
      "phone": phone
      // .split(
      // "${Provider.of<ZMetaData>(context, listen: false).areaCode}")[1]
      ,
      "password": nPassword
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
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}
