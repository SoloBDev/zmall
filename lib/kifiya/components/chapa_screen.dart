import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class ChapaScreen extends StatefulWidget {
  const ChapaScreen({
    required this.url,
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.title = "Chapa Payment Gateway",
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
  _ChapaScreenState createState() => _ChapaScreenState();
}

class _ChapaScreenState extends State<ChapaScreen> {
  bool _loading = false;
  String initUrl = "";
  InAppWebViewSettings settings = InAppWebViewSettings(
    //both platforms
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    javaScriptEnabled: true, // Ensure payment JS works
    clearCache: true, // Clear cache for security
    //android
    useHybridComposition: true,
    //ios
    allowsInlineMediaPlayback: true,
  );

  @override
  void initState() {
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
        initUrl = data['data']['data']['checkout_url'];
      });
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
            ),
            body: InAppWebView(
              initialSettings: settings,
              initialUrlRequest: URLRequest(url: WebUri(initUrl)),
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW; // Allow all navigations
              },
            ),
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
      "customization": {
        "title": "ZMall Delivery Payment",
        "description": "Order Payment to ZMall Delivery",
        "logo": null
      }
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
      // debugPrint(e);
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
