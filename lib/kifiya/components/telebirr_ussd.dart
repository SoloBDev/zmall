import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class TelebirrUssd extends StatefulWidget {
  const TelebirrUssd({
    required this.url,
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.title = "Telebirr",
    this.isAbroad = false,
    required this.serverToken,
    required this.userId,
  });
  final String url;
  final String title;
  final double hisab;
  final String phone;
  final String traceNo;
  final String orderPaymentId;
  final bool isAbroad;
  final String userId;
  final String serverToken;

  @override
  _TelebirrUssdState createState() => _TelebirrUssdState();
}

class _TelebirrUssdState extends State<TelebirrUssd> {
  bool _loading = false;
  String telebirrUrl = "";
  String uuid = "";

  @override
  void initState() {
    super.initState();
    _initTelebirr();
  }

  void _initTelebirr() async {
    var data = await initTelebirr();
    if (data != null && data['result']['success']) {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['result']['message']}. Waiting for payment to be completed",
          false,
          duration: 6));
      _verifyPayment();
    }
  }

  void _verifyPayment() async {
    var data = await verifyPayment();
    if (data != null && data['success']) {
      Navigator.pop(context);
    } else {
      await Future.delayed(Duration(seconds: 2))
          .then((value) => _verifyPayment());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: kBlackColor),
          ),
          elevation: 1.0,
          // leading: TextButton(
          //   child: Text("Done"),
          //   onPressed: () => Navigator.of(context).pop(),
          // ),
        ),
        body: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay Using Telebirr',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Powered by Ethiotelecom',
                    style: TextStyle(fontSize: 21, color: Colors.black45),
                  ),
                ],
              ),
              Image.asset(
                "images/telebirr.png",
                height: getProportionateScreenHeight(kDefaultPadding * 10),
                width: getProportionateScreenWidth(kDefaultPadding * 10),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              SpinKitPouringHourGlassRefined(color: kBlackColor),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              Text(
                "Please complete payment through the USSD prompt. \nWaiting for payment to be completed....",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ));
  }

  Future<dynamic> initTelebirr() async {
    setState(() {
      _loading = true;
    });
    var url = widget.url;

    //New configuration
    Map data = {
      "traceNo": widget.traceNo,
      "amount": widget.hisab,
      "phone": "251${widget.phone}",
      "payerId": "22",
      "appId": "1234",
      "apiKey": "90e503b019a811ef9bc8005056a4ed36",
      "zmall": true
    };
    /*  
    //Old configuration.
    //  Map data = {
    //   "trace_no": widget.traceNo,
    //   "amount": widget.hisab,
    //   "phone": widget.phone,
    //   "appId": "1234"
    }; */

    var body = json.encode(data);
    print("body $body");
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      // print(json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage(
            "Something went wrong. Please check your internet connection!",
            true),
      );
      return null;
    } finally {
      setState(() {
        this._loading = false;
      });
    }
  }

  Future<dynamic> verifyPayment() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";

    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "order_payment_id": widget.orderPaymentId
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
          throw TimeoutException("The connection has timed out!");
        },
      );

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage(
            "Checking if payment is made. Please wait a moment...", true),
      );
      return null;
    } finally {
      setState(() {
        this._loading = false;
      });
    }
  }
}
