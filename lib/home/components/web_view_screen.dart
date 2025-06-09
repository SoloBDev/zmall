import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_back_button.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  String title = "Web";
  bool _loading = true;
  String initUrl = "";
  bool isError = false;
  String? errorMessage;
  bool _hasLoadError = false; // Track if a load error occurred
  InAppWebViewSettings settings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    javaScriptEnabled: true,
    clearCache: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
    userAgent:
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
    cacheEnabled: false,
    disableDefaultErrorPage: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    allowContentAccess: true,
    javaScriptCanOpenWindowsAutomatically: true,
    // Add these for better JavaScript support
    supportZoom: false,
    builtInZoomControls: false,
    displayZoomControls: false,
    allowsLinkPreview: false,
    allowsBackForwardNavigationGestures: false,
  );

  @override
  void initState() {
    super.initState();
    initUrl = widget.url;
    title = widget.title;
    if (!initUrl.startsWith('http://') && !initUrl.startsWith('https://')) {
      initUrl = 'https://$initUrl';
    }
    // debugPrint('Initial URL: $initUrl');
  }

  Future<bool> _handleBackNavigation() async {
    if (_controller == null) {
      return true; // Allow pop if WebView isn't initialized
    }

    bool canGoBack = await _controller!.canGoBack();
    String? currentUrl = (await _controller!.getUrl())?.toString();

    // If WebView can go back and we're not at the initial URL
    if (canGoBack && currentUrl != initUrl) {
      await _controller!.goBack();
      return false; // Prevent pop, handled by WebView
    }

    // Pop the screen to go back to the previous screen
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _handleBackNavigation();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            Service.capitalizeFirstLetters(title),
            style: TextStyle(color: kBlackColor),
          ),
          leading: CustomBackButton(
            onPressed: () async {
              final shouldPop = await _handleBackNavigation();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialSettings: settings,
              initialUrlRequest: URLRequest(url: WebUri(initUrl)),
              onWebViewCreated: (controller) {
                _controller = controller;
                // debugPrint('WebView created');
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                // debugPrint('Navigating to: ${navigationAction.request.url}');
                final url = navigationAction.request.url?.toString();
                if (url != null) {
                  // Allow the WebView to load the requested URL
                  return NavigationActionPolicy.ALLOW;
                }
                // Prevent the WebView from loading the URL
                return NavigationActionPolicy.CANCEL;
                // return NavigationActionPolicy.ALLOW;
              },
              onLoadStart: (controller, url) {
                // debugPrint('Load started: $url');
                setState(() {
                  _loading = true;
                  isError = false;
                  errorMessage = null;
                  _hasLoadError = false; // Reset error flag
                });
              },
              // onLoadStop: (controller, url) {
              //   debugPrint('Load stopped: $url');
              //   setState(() {
              //     _loading = false;
              //     isError = false; // Clear error state on successful load
              //     errorMessage = null;
              //   });
              // },
              onLoadStop: (controller, url) {
                // debugPrint('Load stopped: $url');
                setState(() {
                  _loading = false;
                  // Only clear error state if no error occurred
                  if (!_hasLoadError) {
                    isError = false;
                    errorMessage = null;
                  }
                  // If loaded about:blank due to error, keep error UI
                  if (url.toString() == 'about:blank' && _hasLoadError) {
                    isError = true;
                    errorMessage = errorMessage ?? 'Failed to load page';
                  }
                });
              },
              onReceivedError: (controller, request, error) {
                // debugPrint( 'Load error: ${error.description}, URL: ${request.url}');
                if (request.url.toString() == initUrl) {
                  setState(() {
                    _loading = false;
                    isError = true;
                    _hasLoadError = true; // Mark error occurred
                    errorMessage = error.description
                            .contains('net::ERR_NAME_NOT_RESOLVED')
                        ? 'No internet connection. Please check your network.'
                        : 'Failed to load page: ${error.description}';
                  });
                }
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                // debugPrint( 'HTTP error: ${errorResponse.statusCode}, ${errorResponse.reasonPhrase}, URL: ${request.url}');
                if (request.url.toString() == initUrl) {
                  setState(() {
                    _loading = false;
                    isError = true;
                    _hasLoadError = true; // Mark error occurred
                    errorMessage =
                        'HTTP Error ${errorResponse.statusCode}: ${errorResponse.reasonPhrase}';
                  });
                }
              },
              onConsoleMessage: (controller, consoleMessage) {
                // debugPrint( 'Console: ${consoleMessage.message} [Level: ${consoleMessage.messageLevel}]');
                if (consoleMessage.message
                    .contains('Minified React error #418')) {
                  // debugPrint('Detected React error #418');
                }
              },
            ),
            if (_loading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitWave(
                      color: kSecondaryColor,
                      size: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    const SizedBox(height: kDefaultPadding),
                    const Text("Loading..."),
                  ],
                ),
              ),
            if (isError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(errorMessage ??
                        "Error loading page, please try again."),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isError = false;
                          _loading = true;
                          errorMessage = null;
                          _hasLoadError = false;
                        });
                        // debugPrint('Retrying URL: $initUrl');
                        _controller?.loadUrl(
                          urlRequest: URLRequest(url: WebUri(initUrl)),
                        );
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
