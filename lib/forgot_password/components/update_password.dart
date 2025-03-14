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

class UpdatePasswordScreen extends StatefulWidget {
  static String id = '/password';

  UpdatePasswordScreen({required this.phone});
  final String phone;

  @override
  _UpdatePasswordScreenState createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  late String phone;
  late String newPassword;
  late String confirmPassword;
  bool _loading = false;
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
    return Scaffold(
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
        padding: EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              keyboardType: TextInputType.text,
              cursorColor: kSecondaryColor,
              obscureText: true,
              style: TextStyle(color: kBlackColor),
              onChanged: (value) {
                newPassword = value;
              },
              decoration: InputDecoration(
                hintText: 'New password',
                hintStyle: TextStyle(
                  color: kGreyColor,
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kSecondaryColor),
                ),
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding),
            ),
            TextField(
              keyboardType: TextInputType.text,
              cursorColor: kSecondaryColor,
              obscureText: true,
              style: TextStyle(color: kBlackColor),
              onChanged: (value) {
                confirmPassword = value;
              },
              decoration: InputDecoration(
                hintText: 'Confirm password',
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
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: _loading
                  ? SpinKitWave(
                      color: kSecondaryColor,
                      size: getProportionateScreenHeight(kDefaultPadding),
                    )
                  : CustomButton(
                      title: "Update Password",
                      color: kSecondaryColor,
                      press: () {
                        print("Updating password");
                        if (newPassword == confirmPassword) {
                          updatePassword(phone, newPassword);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Password mismatch. Please try again", true));
                          setState(() {
                            _loading = false;
                          });
                        }
                      }),
            ),
          ],
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
      print(e);
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
