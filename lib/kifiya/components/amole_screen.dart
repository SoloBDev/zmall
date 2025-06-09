import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class AmoleScreen extends StatefulWidget {
  const AmoleScreen({
    required this.hisab,
    required this.userData,
  });

  final double hisab;
  final userData;

  @override
  _AmoleScreenState createState() => _AmoleScreenState();
}

class _AmoleScreenState extends State<AmoleScreen> {
  late String otp;
  bool _loading = false;
  bool _otpSent = false;
  var kifiyaGateway;

  void _sendOtp() async {
    if (widget.hisab != null && widget.hisab == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("Please enter a valid amount", true));
    } else {
      var data = await sendOTP();
      if (data != null && data['success']) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(Service.showMessage("OTP successfully sent!", false));
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _sendOtp();
  }

  void verifyOTP() async {
    setState(() {
      _loading = true;
    });
    if (otp != null && otp.length == 4) {
      Navigator.pop(context, otp);
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("Please enter a valid OTP.", true, duration: 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pay with Amole",
          style: TextStyle(color: kBlackColor),
        ),
        leading: BackButton(
          color: kBlackColor,
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(
            getProportionateScreenWidth(kDefaultPadding),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding)),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pay ብር ${widget.hisab.toStringAsFixed(2)} with Amole",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    Text(
                      "Please enter the verification pin sent from Amole.",
                      style: TextStyle(color: kGreyColor),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    TextField(
                      style: TextStyle(color: kBlackColor),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        otp = val;
                      },
                      decoration:
                          textFieldInputDecorator.copyWith(labelText: "OTP"),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    _loading
                        ? SpinKitWave(
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          )
                        : CustomButton(
                            title: "Submit",
                            press: () async {
                              verifyOTP();
                            },
                            color: kSecondaryColor,
                          )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> sendOTP() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/send_otp";

    Map data = {
      "user_id": widget.userData['user']['_id'],
      "phone": widget.userData['user']['phone'],
      "type": widget.userData['user']['admin_type'],
      "token": widget.userData['user']['server_token'],
      "country_phone_code": widget.userData['user']['country_phone_code']
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
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Something went wrong, please check your connection and try again!",
          true));
      return null;
    }
  }

  Future<dynamic> getKifiyaGateway() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_payment_gateway";
    Map data = {
      "user_id": widget.userData['user']['_id'],
      "city_id": "5b406b46d2ddf8062d11b788",
      "server_token": widget.userData['user']['server_token'],
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
        Service.showMessage(
            "Something went wrong, please check your connection and try again!",
            true),
      );
      return null;
    }
  }
}
