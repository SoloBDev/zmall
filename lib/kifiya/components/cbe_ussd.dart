import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class CbeUssd extends StatefulWidget {
  const CbeUssd({
    required this.url,
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.title = "CBE USSD",
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
  _CbeUssdState createState() => _CbeUssdState();
}

class _CbeUssdState extends State<CbeUssd> {
  bool _loading = false;
  String initUrl = "";
  String uuid = "";
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initPayment();
  }

  void _initPayment() async {
    var data = await initPayment();
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['message']}. Waiting for payment to be completed", false,
          duration: 6));
      _verifyPayment();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['message']}. Please try other payment methods", true,
          duration: 4));
      await Future.delayed(Duration(seconds: 3)).then((value) => Navigator.pop(context));
    }
  }

  void _verifyPayment()async {

    var data = await verifyPayment();
    if(data != null && data['success']){
      Navigator.pop(context);
    } else {
      await Future.delayed(Duration(seconds: 2)).then((value) => _verifyPayment());
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
          padding:  EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay Using CBE Birr',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Powered by CBE',
                    style: TextStyle(fontSize: 21, color: Colors.black45),
                  ),
                ],
              ),
              Image.asset(
                "images/cbebirr.png",
                height: getProportionateScreenHeight(kDefaultPadding * 10),
                width: getProportionateScreenWidth(kDefaultPadding * 10),
              ),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding/2),),
              SpinKitPouringHourGlassRefined(color: kBlackColor),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding/2),),
              Text("Please complete payment through the USSD prompt. \nWaiting for payment to be completed....", textAlign: TextAlign.center,),
            ],
          ),
        )
    );
  }

  Future<dynamic> initPayment() async {
    setState(() {
      _loading = true;
    });
    var url = widget.url;

    Map data = {
      "trace_no": widget.traceNo,
      "amount": widget.hisab,
      "phone": widget.phone,
      "appId": "1234"
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
        Service.showMessage(
            "Something went wrong. Please check your internet connection!",
            true),
      );
      return null;
    }
  }

  Future<dynamic> verifyPayment() async {
    setState(() {
      _loading = true;
    });
    var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";;

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
        Service.showMessage(
            "Something went wrong. Please check your internet connection!",
            true),
      );
      return null;
    }
  }
}