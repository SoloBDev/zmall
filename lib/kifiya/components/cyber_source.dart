import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zmall/constants.dart';

class CyberSource extends StatefulWidget {
  const CyberSource({required this.url});
  final String url;
  @override
  _CyberSourceState createState() => _CyberSourceState();
}

class _CyberSourceState extends State<CyberSource> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "BoA Cybersource",
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
            url: WebUri.uri(Uri.parse(widget.url)),
          ),
        )

        // initialChild: Container(
        //   color: kPrimaryColor,
        //   child: const Center(
        //     child: Text('Waiting.....'),
        //   ),
        // ),
        );
  }
}
