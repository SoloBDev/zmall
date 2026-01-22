import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class EventSantimPayScreen extends StatefulWidget {
  final String url;
  final String title;
  const EventSantimPayScreen({Key? key, required this.url, required this.title})
    : super(key: key);
  @override
  _EventSantimState createState() => _EventSantimState();
}

class _EventSantimState extends State<EventSantimPayScreen> {
  bool _loading = true;
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
        title: Text(widget.title, style: TextStyle(color: kBlackColor)),
        leadingWidth: getProportionateScreenWidth(75.0),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialSettings: settings,
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW; // Allow all navigations
              },
              onLoadStart: (InAppWebViewController controller, Uri? url) {
                setState(() {
                  _loading = true;
                });
              },
              onLoadStop: (InAppWebViewController controller, Uri? url) {
                setState(() {
                  _loading = false;
                });
              },
            ),
            if (_loading)
              Center(
                child: SpinKitWave(
                  color: kSecondaryColor,
                  size: getProportionateScreenWidth(kDefaultPadding),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
