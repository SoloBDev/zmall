import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zmall/constants.dart';

class YagoutPay extends StatefulWidget {
  const YagoutPay({super.key});
  // final String url;
  @override
  _YagoutPayState createState() => _YagoutPayState();
}

class _YagoutPayState extends State<YagoutPay> {
  String url =
      "https://uatcheckout.yagoutpay.com/ms-transaction-core-1-0/staticQRRedirection/defaultstaticQRGatewayPage/7274763184";
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
    url =
        "https://uatcheckout.yagoutpay.com/ms-transaction-core-1-0/staticQRRedirection/defaultstaticQRGatewayPage/7274763184";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "YagoutPay",
          style: TextStyle(color: kBlackColor),
        ),
      ),
      body: InAppWebView(
        initialSettings: settings,
        initialUrlRequest: URLRequest(url: WebUri(url)),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW; // Allow all navigations
        },
      ),
    );
  }
}
