import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:uuid/uuid.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class Telebirr extends StatefulWidget {
  const Telebirr({
    required this.url,
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.title = "Telebirr",
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
  _TelebirrState createState() => _TelebirrState();
}

class _TelebirrState extends State<Telebirr> {
  bool _loading = false;
  String telebirrUrl = "";
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
    _initTelebirr();
  }

  void _initTelebirr() async {
    var data = await initTelebirr();
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['message']}. Loading...", false,
          duration: 6));
      setState(() {
        telebirrUrl = data['data']['data']['toPayUrl'];
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
                url: WebUri.uri(Uri.parse(telebirrUrl)),
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

  Future<dynamic> initTelebirr() async {
    setState(() {
      _loading = true;
    });
    var url = widget.url;

    Map data = {
      "phone": widget.isAbroad ? widget.phone : "+251${widget.phone}",
      "description": "ZMall Order Payment",
      "amount": widget.hisab,
      "trace_no": widget.traceNo,
      "appId": "1234",
      "returnUrl": "/"
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
