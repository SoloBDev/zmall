import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

import 'update_password.dart';

class VerificationScreen extends StatefulWidget {
  static String id = '/verification';
  VerificationScreen({required this.code, required this.phone, this.login = false});
  final String code;
  final String phone;
  final bool login;

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  TextEditingController controller = TextEditingController(text: "");
  bool hasError = false;
  String? code;
  String? phone;

  @override
  void initState() {
    code = widget.code;
    phone = widget.phone;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Verify Code",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(
          getProportionateScreenHeight(kDefaultPadding),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "An OTP (verification code) has been sent to your phone number. Please enter the code correctly and press 'verify'!",
              style: Theme.of(context)
                  .textTheme
                  .subtitle1
                  ?.copyWith(color: kGreyColor),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
            TextField(
              style: TextStyle(color: kBlackColor),
              keyboardType: TextInputType.number,
              maxLength: 4,
              controller: controller,
              onChanged: (val) {
                setState(() {
                  hasError = false;
                });
              },
              decoration: textFieldInputDecorator.copyWith(labelText: "Code"),
            ),
            Visibility(
              child: Text(
                "INCORRECT! Please try again.",
                style: TextStyle(color: kSecondaryColor),
              ),
              visible: hasError,
            ),
            SizedBox(height: kDefaultPadding),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: <Widget>[
                if (!kIsWeb)
                  MaterialButton(
                    color: kBlackColor,
                    textColor: kPrimaryColor,
                    child: Text("Verify"),
                    onPressed: () {
                      if (controller.text == code) {
                        if(widget.login){

                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdatePasswordScreen(
                                phone: phone!,
                              ),
                            ),
                          );
                        }

                      } else {
                        setState(() {
                          this.hasError = true;
                        });
                      }
                    },
                  ),
                SizedBox(
                  width: kDefaultPadding,
                ),
                MaterialButton(
                  color: kSecondaryColor,
                  textColor: kPrimaryColor,
                  child: Text("Erase"),
                  onPressed: () {
                    controller.clear();
                    setState(() {
                      this.hasError = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
