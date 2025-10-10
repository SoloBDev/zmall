import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
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
  String title = "AddisPay";
  String message = "Connecting to AddisPay...";
  bool _loading = false;
  bool _isError = false;
  String initUrl = "";
  // bool isError = false;
  InAppWebViewSettings settings = InAppWebViewSettings(
    //both platforms
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    javaScriptEnabled: true, // Ensure payment JS works
    clearCache: true, // Clear cache for security
    disableDefaultErrorPage: true,
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
    });
    try {
      final data = await initiateUrl();
      if (data != null) {
        setState(() {
          initUrl = "${data['checkout_url']}/${data['uuid']}";
          message = "Invoice initiated successfully. Loading...";
        });
      } else {
        throw Exception('Invalid response from initiateUrl');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          message = "Failed to initiate payment. Please try again.";
        });

        if (_isError || Navigator.canPop(context)) {
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
      body: _loading || _isError || initUrl.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading && !_isError)
                    SpinKitWave(
                      color: kSecondaryColor,
                      size: getProportionateScreenWidth(kDefaultPadding * 2),
                    ),
                  SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding)),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: kBlackColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            )
          : InAppWebView(
              initialSettings: settings,
              initialUrlRequest: URLRequest(url: WebUri(initUrl)),
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW; // Allow all navigations
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  _loading = false;
                  message = "Failed to initiate payment. Please try again.";
                  // Force rebuild to show error message
                  initUrl =
                      ""; // Clear the URL so the error message is shown instead of the webview
                });
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
      setState(() {
        _isError = true;
        message =
            "Something went wrong. Please check your internet connection!";
      });

      return null;
    } finally {
      setState(() {
        this._loading = false;
      });
    }
  }
}
