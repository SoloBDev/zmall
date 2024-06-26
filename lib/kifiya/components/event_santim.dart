import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class EventSantimPayScreen extends StatefulWidget {
  final String url;
  final String title;
  const EventSantimPayScreen({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);
  @override
  _EventSantimState createState() => _EventSantimState();
}

class _EventSantimState extends State<EventSantimPayScreen> {
  bool _loading = true;
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: kBlackColor),
        ),
        leadingWidth: getProportionateScreenWidth(75.0),
      ),
      body: Stack(children: [
        InAppWebView(
          initialOptions: options,
          initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
          // onWebViewCreated: (InAppWebViewController controller) {
          //   controller.addJavaScriptHandler(
          //     handlerName: 'onLoad',
          //     callback: (_) {
          //       setState(() {
          //         _loading = false;
          //       });
          //     },
          //   );
          // },
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
          )
      ]),
    );
  }
}
