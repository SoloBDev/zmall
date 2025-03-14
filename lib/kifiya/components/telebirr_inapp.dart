import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class TelebirrInApp extends StatefulWidget {
  const TelebirrInApp(
      {required this.amount,
      required this.phone,
      required this.traceNo,
      required this.context});
  final double amount;
  final String phone;
  final String traceNo;
  final BuildContext context;

  @override
  _TelebirrInAppState createState() => _TelebirrInAppState();
}

class _TelebirrInAppState extends State<TelebirrInApp> {
  static const MethodChannel _channel =
      MethodChannel('telebirrInAppSdkChannel');

  Future<dynamic> placeOrder({
    required String receiveCode,
    required String appId,
    required String shortCode,
  }) async {
    try {
      final Map<String, dynamic> arguments = {
        'receiveCode': receiveCode,
        'appId': appId,
        'shortCode': shortCode,
      };

      final Map<Object?, Object?> response =
          await _channel.invokeMethod('placeOrder', arguments);

      // print("***Response From Native (Android/iOS)***: ${response.toString()}");

      // Check if the response is a map and contains status and code
      if (response.isNotEmpty) {
        final int code = int.parse(response['code'].toString());

        ///Confirm payment verification
        if (code == 0) {
          var confirmPaymentResponce = await confirmPayment(
              code: code,
              status: response['status'].toString(),
              traceNo: widget.traceNo,
              message: response['errMsg'].toString());
          if (confirmPaymentResponce != null &&
              confirmPaymentResponce["success"]) {
            _handlePaymentResponse(code: code);
            Future.delayed(
                Duration(seconds: 2), () => Navigator.pop(context, true));
          } else {
            Future.delayed(
                Duration(seconds: 2), () => Navigator.pop(context, false));
          }
        } else {
          _handlePaymentResponse(code: -99);
          Future.delayed(
              Duration(seconds: 2), () => Navigator.pop(context, false));
        }
      } else {
        // Unexpected response format
        _handlePaymentResponse(code: -1);
        Future.delayed(
            Duration(seconds: 2), () => Navigator.pop(context, false));
      }
    } on PlatformException catch (e) {
      // print('Error details: ${e.details}');
      // print('Error message: ${e.message}');
      // print('Error code: ${e.details["code"]}');
      _handlePaymentResponse(code: e.details["code"]);
      Future.delayed(Duration(seconds: 2), () => Navigator.pop(context, false));
    }
  }

  // Function to handle payment response based on the response code or message
  void _handlePaymentResponse({required int code, String? errorMessage}) {
    String message;
    bool isError = false;
    if (errorMessage != null) {
      // If there's an error message, show it
      message = errorMessage;
      isError = true;
    } else {
      // Handle different response codes
      switch (code) {
        case 0:
          message =
              "✅ Payment successful! Your transaction has been completed successfully. Thank you for using our service!";
          isError = false;
          break;
        case -1:
          message = "❌ Unknown error occurred. Please try again.";
          isError = true;
          break;
        case -2:
          message =
              "⚠️ There seems to be an issue with your input. Please double-check the parameters you provided and try again.";
          isError = true;
          break;
        case -3:
          message =
              "⚠️ Payment was cancelled by the user. If this was not intentional, please try again to complete the payment.";
          isError = true;
          break;
        case -10:
          message =
              "⚠️ It looks like Telebirr is not installed on your device. Please install it and try again.";
          isError = true;
          break;
        case -11:
          message =
              "⚠️ The current version of Telebirr doesn't support this feature. Please upgrade your Telebirr app to the latest version and try again.";
          isError = true;
          break;
        case -99:
          message = "⚠️ Payment is not confirmed";
          isError = true;
          break;
        default:
          message = "❌  Unknown error occurred. Please try again.";
          isError = true;
          break;
      }
    }
    // Display the message in the UI
    ScaffoldMessenger.of(context).showSnackBar(
      Service.showMessage(message, isError, duration: 4),
    );
  }

  @override
  void initState() {
    super.initState();
    getRreceiveCode(
        amount: "${widget.amount}",
        traceNo: widget.traceNo,
        phone: widget.phone,
        description: "ZMall_Telebirr_InApp");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "TeleBirr InApp",
            style: TextStyle(color: kBlackColor),
          ),
          leading: BackButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay Using Telebirr',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Powered by Ethiotelecom',
                    style: TextStyle(fontSize: 21, color: Colors.black45),
                  ),
                ],
              ),
              Image.asset(
                "images/telebirr.png",
                height: getProportionateScreenHeight(kDefaultPadding * 10),
                width: getProportionateScreenWidth(kDefaultPadding * 10),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              SpinKitPouringHourGlassRefined(color: kBlackColor),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              Text(
                "Waiting for payment to be completed....",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ));
  }

  Future<dynamic> confirmPayment(
      {required int code,
      required String traceNo,
      required String status,
      required String message}) async {
    var url = "https://pgw.shekla.app/telebirrInapp/in_app_call_back";
    Map data = {
      "code": code,
      "status": status,
      "traceNo": traceNo,
      "message": message
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
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getRreceiveCode(
      {required String amount,
      required String traceNo,
      required String phone,
      required String description}) async {
    var responseData;
    var url = "https://pgw.shekla.app/telebirrInapp/create_order";
    Map data = {
      "traceNo": traceNo, // "traceNo": "1234567890",
      "phone": phone,
      "amount": amount,
      "description": description,
      "isInapp": true
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
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );

      setState(() {
        responseData = json.decode(response.body);
      });
      if (responseData != null &&
          responseData['createOrderResult']['result']
                  .toString()
                  .toLowerCase() ==
              'success') {
        //////TODO: check platform and call function based on the device placeOrderAndroid or placeOrderIos
        placeOrder(
          receiveCode: responseData['createOrderResult']['biz_content']
              ['receiveCode'],
          appId: responseData["appId"],
          shortCode: responseData["shortCode"],
        );
      }
      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }
}
