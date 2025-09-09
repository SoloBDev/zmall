import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class DashenMasterCard extends StatefulWidget {
  const DashenMasterCard({
    required this.url,
    required this.phone,
    required this.amount,
    required this.traceNo,
    required this.currency,
    required this.orderPaymentId,
    this.title = "MasterCard",
    this.isAbroad = false,
  });
  final String url;
  final String phone;
  final String traceNo;
  final String orderPaymentId;
  final String title;
  final String currency;
  final double amount;
  final bool isAbroad;

  @override
  _DashenMasterCardState createState() => _DashenMasterCardState();
}

class _DashenMasterCardState extends State<DashenMasterCard> {
  bool _loading = false;
  String masterCardUrl = "";
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
    _initDashenMasterCard();
  }

  void _initDashenMasterCard() async {
    var data = await initDashenMasterCard();
    if (data != null && data['success']) {
      Service.showMessage(
          context: context, title: "Loading...", error: false, duration: 6);
      setState(() {
        masterCardUrl = data['mastercardUrl'];
      });
    } else {
      Service.showMessage(
        context: context,
        title: "Something went wrong. Please check your internet connection!",
        error: true,
        duration: 3,
      );
      Future.delayed(Duration(seconds: 7), () {
        Navigator.of(context).pop();
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
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(
                    getProportionateScreenHeight(kDefaultPadding * 2)),
                child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding / 2),
                        vertical:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Press here after completing payment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kWhiteColor,
                          fontWeight: FontWeight.w800,
                          fontSize: kDefaultPadding * 1.2,
                        ),
                      ),
                    )),
              ),
            ),
            body: InAppWebView(
              initialSettings: settings,
              initialUrlRequest: URLRequest(
                url: WebUri(masterCardUrl),
              ),
              // onWebViewCreated: (controller) {
              //   _webViewController = controller; // Store controller if needed
              // },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW; // Allow all navigations
              },
            ),
          );
  }

  Future<dynamic> initDashenMasterCard() async {
    var responseData;
    setState(() {
      _loading = true;
    });

    Map data = {
      "amount": widget.amount,
      "currency": widget.currency,
      "phone": widget.isAbroad ? widget.phone : "+251${widget.phone}",
      "trace_no": widget.traceNo,
      "orderPaymentId": widget.orderPaymentId,
      "appId": "1234",
      "description": "ZMall Order Payment",
    };
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
        Uri.parse(widget.url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 15),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        responseData = json.decode(response.body);
        this._loading = false;
      });
      return responseData;
    } catch (e) {
      setState(() {
        this._loading = false;
      });

      Service.showMessage(
        context: context,
        title: "Something went wrong. Please check your internet connection!",
        error: true,
      );
      return null;
    }
  }
}
