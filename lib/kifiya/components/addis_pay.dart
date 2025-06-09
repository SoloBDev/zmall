import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_back_button.dart';

class AddisPay extends StatefulWidget {
  const AddisPay({
    required this.url,
    required this.phone,
    required this.email,
    required this.amount,
    required this.traceNo,
    required this.firstName,
    required this.lastName,
  });
  final String url;
  final String phone;
  final String email;
  final double amount;
  final String traceNo;
  final String firstName;
  final String lastName;

  @override
  _AddisPayState createState() => _AddisPayState();
}

class _AddisPayState extends State<AddisPay> {
  String title = "AddisPay Payment Gateway";
  bool _loading = false;
  String initUrl = "";
  bool isError = false;
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
    if (!mounted) return;

    setState(() {
      _loading = true;
      isError = false;
    });
    try {
      final data = await initiateUrl();
      if (data != null) {
        setState(() {
          initUrl = "${data['checkout_url']}/${data['uuid']}";
        });
      } else {
        throw Exception('Invalid response from initiateUrl');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
            "Something went wrong. Please check your internet connection!",
            true,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      setState(() {
        this._loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: kBlackColor),
        ),
        leading: CustomBackButton(),
      ),
      body: _loading
          ? Center(
              child: Column(
                spacing: kDefaultPadding,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitWave(
                    color: kSecondaryColor,
                    size: getProportionateScreenWidth(kDefaultPadding),
                  ),
                  Text("Loading...")
                ],
              ),
            )
          : isError
              ? Center(
                  child: Column(
                    spacing: kDefaultPadding,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Error initializing payment, please try again."),
                      TextButton(
                          onPressed: () {
                            _initiateUrl();
                          },
                          child: Text("Retry"))
                    ],
                  ),
                )
              : InAppWebView(
                  initialSettings: settings,
                  initialUrlRequest: URLRequest(url: WebUri(initUrl)),
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    return NavigationActionPolicy
                        .ALLOW; // Allow all navigations
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
      "appId": "123456",
      "amount": "${widget.amount}",
      "trace_no": widget.traceNo,
      "phone": widget.phone,
      "email": widget.email,
      "first_name": widget.firstName,
      "last_name": widget.lastName,
      "description": "ZMall Order payment",
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
}
