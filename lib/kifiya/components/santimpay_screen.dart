import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class SantimPay extends StatefulWidget {
  const SantimPay({
    required this.url,
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.title = "SantimPay Payment Gateway",
    this.isAbroad = false,
  });
  final String url;
  final String title;
  final double hisab;
  final String phone;
  final String traceNo;
  final String orderPaymentId;
  final bool isAbroad;

  @override
  _SantimPayState createState() => _SantimPayState();
}

class _SantimPayState extends State<SantimPay> {
  bool _loading = false;
  String initUrl = "";
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
    _initiateUrl();
  }

  void _initiateUrl() async {
    var data = await initiateUrl();
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Invoice initiated successfully. Loading...", false,
          duration: 6));
      setState(() {
        initUrl = data['url'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Error while initiating payment. Please try again.", true,
          duration: 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title,
                style: TextStyle(color: kBlackColor),
              ),
              leading: TextButton(
                child: Text("Done"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: SpinKitWave(
                color: kSecondaryColor,
                size: getProportionateScreenWidth(kDefaultPadding),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title,
                style: TextStyle(color: kBlackColor),
              ),
              leading: TextButton(
                child: Text("Done"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: InAppWebView(
              initialOptions: options,
              initialUrlRequest: URLRequest(
                url: Uri.parse(initUrl),
              ),
            ),
            // withZoom: true,
            // displayZoomControls: true,
            // initialChild: Container(
            //   color: kPrimaryColor,
            //   child: const Center(
            //     child: Text('Waiting.....'),
            //   ),
            // ),
          );
  }

  Future<dynamic> initiateUrl() async {
    setState(() {
      _loading = true;
    });
    var url = widget.url;

    Map data = {
      "id": widget.traceNo,
      "amount": widget.hisab,
      "reason": "ZMall Delivery Order Payment",
      "phone_number": "+251${widget.phone}"
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
