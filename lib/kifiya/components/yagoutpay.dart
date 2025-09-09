import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_back_button.dart';

class YagoutPay extends StatefulWidget {
  const YagoutPay({
    super.key,
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
  _YagoutPayState createState() => _YagoutPayState();
}

class _YagoutPayState extends State<YagoutPay> {
  // Get tomorrow's date
  DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
  InAppWebViewSettings settings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    javaScriptEnabled: true,
    clearCache: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,

    ///

    javaScriptCanOpenWindowsAutomatically: true, domStorageEnabled: true,
    // Consider adding a userAgent for better compatibility
    userAgent:
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Mobile Safari/537.36",
    preferredContentMode:
        UserPreferredContentMode.RECOMMENDED, // Optimize content mode
  );
  String initUrl = "";
  String message = "Connecting to YagoutPay...";
  bool _loading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initiateUrl();
  }

  void _initiateUrl() async {
    setState(() {
      _loading = true;
    });
    var response = await initiateUrl();
    try {
      if (response != null) {
        setState(() {
          initUrl = response;
          message = "Invoice initiated successfully. Loading...";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        message = "Failed to initiate payment. Please try again.";
      });
      if (_isError && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CustomBackButton(),
        title: Text(
          "YagoutPay",
          style: TextStyle(color: kBlackColor),
        ),
      ),
      body: _loading || initUrl.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading || _isError || initUrl.isEmpty)
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
          : SafeArea(
              child: InAppWebView(
                initialSettings: settings,
                initialUrlRequest: URLRequest(url: WebUri(initUrl)),
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return NavigationActionPolicy.ALLOW;
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
            ),
    );
  }

  String? extractPaymentLink(String raw) {
    final regex = RegExp(r'"PaymentLink"\s*:\s*"([^"]+)"');
    final match = regex.firstMatch(raw);
    return match != null ? match.group(1) : null;
  }

  Future<dynamic> initiateUrl() async {
    setState(() {
      _loading = true;
    });
    var url = widget.url;
    // print("url>>> $url");

    Map data = {
      "phone": widget.phone,
      "amount": widget.amount,
      "trace_no": widget.traceNo,
      "first_name": widget.firstName,
      "last_name": widget.lastName,
      "appId": "123456",
      "description": "ZMall YgoutPay order payment",
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
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );

      // print("Raw response>>> ${response.body}");

      String? paymentLink = extractPaymentLink(response.body);

      // if (paymentLink != null) {
      //   print('Payment Link: $paymentLink');
      // } else {
      //   print('Payment Link not found.');
      // }
      return paymentLink;
    } catch (e) {
      print("Error>> $e");
      setState(() {
        _isError = true;
        message =
            "Something went wrong. Please check your internet connection!";
      });

      // Service.showMessage(
      //   context: context,
      //   title: "Something went wrong. Please check your internet connection!",
      //   error: true,
      // );
      return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}

  // Format the date as YYYY-MM-DD
    // String formattedDate = DateFormat('yyyy-MM-dd').format(tomorrow);
  // Map data = {
    //   "req_user_id": "akshay007",
    //   "me_id": "202505060003",
    //   "amount": 1,
    //   // widget.amount,
    //   "customer_email": widget.email,
    //   "mobile_no": widget.phone,
    //   "expiry_date": formattedDate, //"2025-08-19",j
    //   "media_type": ["API"],
    //   "order_id": widget.traceNo,
    //   "first_name": widget.firstName,
    //   "last_name": widget.lastName,
    //   "reminder1": "",
    //   "product": "product1",
    //   "dial_code": "+251",
    //   "reminder2": "",
    //   "failure_url": "",
    //   "success_url": "https://test.zmallapp.com/yagout/get_callback",
    //   "country": "ETH",
    //   "currency": "ETB"
    // };
