import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zmall/utils/constants.dart';

class CyberSource extends StatefulWidget {
  const CyberSource({required this.url});
  final String url;
  @override
  _CyberSourceState createState() => _CyberSourceState();
}

class _CyberSourceState extends State<CyberSource> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "BoA Cybersource",
          style: TextStyle(color: kBlackColor),
        ),
      ),
      body: InAppWebView(
        initialSettings: settings,
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW; // Allow all navigations
        },
      ),
    );
  }
}
