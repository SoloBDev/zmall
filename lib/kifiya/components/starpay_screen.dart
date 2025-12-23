import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';

class StarPayScreen extends StatefulWidget {
  const StarPayScreen({
    required this.url,
    required this.amount,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.isAbroad = false,
    required this.firstName,
    required this.lastName,
    required this.items,
    required this.email,
  });
  final String url;

  final double amount;
  final String phone;
  final String email;
  final String firstName;
  final String lastName;
  final String traceNo;
  final String orderPaymentId;
  final bool isAbroad;
  final List<Item> items;

  @override
  _StarPayScreenState createState() => _StarPayScreenState();
}

class _StarPayScreenState extends State<StarPayScreen> {
  final String title = "StarPay";
  bool _loading = false;
  String initUrl = "";

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

    // debugPrint(
    //   "alicart.items: ${widget.items.map((item) => item.toJson()).toList()}",
    // );
    _initiateUrl();
  }

  void _initiateUrl() async {
    var response = await initiateUrl();
    if (response != null && response['success']
    // && response['data']['data']['status'].toString().toLowerCase() =='success'
    ) {
      Service.showMessage(
        context: context,
        title: "${response['data']['message']}. Loading...",
        // "Invoice initiated successfully. Loading...",
        error: false,
        duration: 6,
      );
      setState(() {
        initUrl = response['data']['data']['payment_url'];
      });
      // debugPrint("initUrl $initUrl");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: kBlackColor)),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitWave(
                      color: kSecondaryColor,
                      size: getProportionateScreenWidth(kDefaultPadding * 2),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    Text(
                      "Connecting to StarPay...",
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
              ),
      ),
    );
  }

  Future<dynamic> initiateUrl() async {
    setState(() {
      _loading = true;
    });
    var url = widget.url;

    // Map items to StarPay format
    List<Map<String, dynamic>> mappedItems = widget.items.map((item) {
      return {
        "productId": item.id,
        "quantity": item.quantity,
        "item_name": item.itemName,
        "unit_price": item.price,
      };
    }).toList();

    Map data = {
      "items": mappedItems,
      "email": widget.email,
      "amount": widget.amount,
      "trace_no": widget.traceNo,
      "last_name": widget.lastName,
      "first_name": widget.firstName,
      "phone": "+251${widget.phone}",
      "description": "Order payment Zmall Food Delivery",
    };
    // debugPrint("data $data");
    // debugPrint("mappedItems $mappedItems");
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );
      // debugPrint("response ${json.decode(response.body)}");

      return json.decode(response.body);
    } catch (e) {
      // debugPrint("error $e");

      Service.showMessage(
        context: context,
        title: "Something went wrong. Please check your internet connection!",
        error: true,
      );
      return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
