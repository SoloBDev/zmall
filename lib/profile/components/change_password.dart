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

class ChangePassword extends StatefulWidget {
  const ChangePassword({this.userData});

  final userData;

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  String oldPassword = "";
  String newPassword = "";
  String confirmPassword = "";
  bool _loading = false;

  void _changePassword() async {
    var data = await changePassword();
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(("Password changed successfull"), false));
      setState(() {
        _loading = false;
      });
      Navigator.of(context).pop();
    } else {
      if (data['error_code'] == 999) {
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${data['error_code']}']}!", true));
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${data['error_code']}']}!", true));
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "Change password failed! Please try again", true));
      }
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Change Password",
          style: TextStyle(
            color: kBlackColor,
          ),
        ),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Old Password",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                cursorColor: kSecondaryColor,
                style: TextStyle(color: kBlackColor),
                keyboardType: TextInputType.text,
                obscureText: true,
                onChanged: (val) {
                  oldPassword = val;
                },
                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kBlackColor),
                  ),
                ),
              ),
              SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 2)),
              Text(
                "New Password",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                cursorColor: kSecondaryColor,
                style: TextStyle(color: kBlackColor),
                keyboardType: TextInputType.text,
                obscureText: true,
                onChanged: (val) {
                  setState(() {
                    newPassword = val;
                  });
                },
                decoration: InputDecoration(
                  suffixIcon:
                      newPassword.isNotEmpty && newPassword == confirmPassword
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : Icon(
                              Icons.close,
                              color: kWhiteColor,
                            ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kBlackColor),
                  ),
                ),
              ),
              SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 2)),
              Text(
                "Confirm Password",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                cursorColor: kSecondaryColor,
                style: TextStyle(color: kBlackColor),
                keyboardType: TextInputType.text,
                obscureText: true,
                onChanged: (val) {
                  setState(() {
                    confirmPassword = val;
                  });
                },
                decoration: InputDecoration(
                  suffixIcon:
                      newPassword.isNotEmpty && newPassword == confirmPassword
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : Icon(
                              Icons.close,
                              color: kWhiteColor,
                            ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kBlackColor),
                  ),
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
              _loading
                  ? SpinKitWave(
                      size: getProportionateScreenWidth(kDefaultPadding),
                      color: kSecondaryColor,
                    )
                  : CustomButton(
                      title: "Submit",
                      press: () {
                        if (oldPassword.isNotEmpty &&
                            newPassword.isNotEmpty &&
                            confirmPassword.isNotEmpty &&
                            newPassword == confirmPassword) {
                          _changePassword();
                        }
                      },
                      color: oldPassword.isNotEmpty &&
                              newPassword.isNotEmpty &&
                              confirmPassword.isNotEmpty &&
                              newPassword == confirmPassword
                          ? kSecondaryColor
                          : kGreyColor,
                    )
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> changePassword() async {
    setState(() {
      _loading = true;
    });

    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/update";
    Map data = {
      "user_id": widget.userData['user']['_id'],
      "server_token": widget.userData['user']['server_token'],
      "first_name": widget.userData['user']['first_name'],
      "last_name": widget.userData['user']['last_name'],
      "old_password": oldPassword,
      "new_password": newPassword,
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
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}
