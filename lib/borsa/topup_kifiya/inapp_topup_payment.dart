import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TopupPaymentInApp extends StatefulWidget {
  const TopupPaymentInApp({
    required this.amount,
    required this.phone,
    required this.traceNo,
    required this.context,
  });
  final double amount;
  final String phone;
  final String traceNo;
  final BuildContext context;

  @override
  _TopupPaymentInAppState createState() => _TopupPaymentInAppState();
}

class _TopupPaymentInAppState extends State<TopupPaymentInApp> {
  static const MethodChannel _channel = MethodChannel(
    'telebirrInAppSdkChannel',
  );

  Future<dynamic> placeOrderIOS({
    required String receiveCode,
    required String appId,
    required String shortCode,
  }) async {
    try {
      final Map<String, dynamic> arguments = {
        'appId': appId,
        'shortCode': shortCode,
        'receiveCode': receiveCode,
      };
      // debugPrint('Invoking native placeOrder method with arguments:>>>> $arguments\n');

      final response = await _channel.invokeMethod('placeOrder', arguments);
      // debugPrint("Native iOS Response:>>>> ${response.toString()}\n");

      // Check if the response is a map and contains status and code
      if (response.isNotEmpty) {
        final int code = int.parse(response['code'].toString());
        // debugPrint("iOS Code:>>>> $code");
        Map<String, dynamic> _paymentResult = {
          "code": code,
          "traceNo": widget.traceNo,
          "status": response['status'].toString(),
          "message": response['errMsg'].toString(),
        };

        ///Confirm payment verification
        if (code == 0) {
          _handlePaymentResponse(code: code);
          Future.delayed(
            Duration(seconds: 2),
            () => Navigator.pop(context, _paymentResult),
          );
        } else {
          _handlePaymentResponse(code: -99);
          Future.delayed(
            Duration(seconds: 2),
            () => Navigator.pop(context, _paymentResult),
          );
        }
      } else {
        // Unexpected response format
        _handlePaymentResponse(code: -1);
        Future.delayed(
          Duration(seconds: 2),
          () => Navigator.pop(context, false),
        );
      }
    } on PlatformException catch (e) {
      _handlePaymentResponse(code: e.details["code"]);
      Future.delayed(Duration(seconds: 2), () => Navigator.pop(context, false));
    }
  }

  Future<dynamic> placeOrder({
    required String receiveCode,
    required String appId,
    required String shortCode,
  }) async {
    try {
      final Map<String, dynamic> arguments = {
        'appId': appId,
        'shortCode': shortCode,
        'receiveCode': receiveCode,
      };

      final Map<Object?, Object?> response = await _channel.invokeMethod(
        'placeOrder',
        arguments,
      );

      // debugPrint("***Response From Native (Android/iOS)***: ${response.toString()}");

      // Check if the response is a map and contains status and code
      if (response.isNotEmpty) {
        final int code = int.parse(response['code'].toString());
        Map<String, dynamic> _paymentResult = {
          "code": code,
          "traceNo": widget.traceNo,
          "status": response['status'].toString(),
          "message": response['errMsg'].toString(),
        };

        ///Confirm payment verification
        if (code == 0) {
          _handlePaymentResponse(code: code);
          Future.delayed(
            Duration(seconds: 2),
            () => Navigator.pop(context, _paymentResult),
          );
        } else {
          Future.delayed(
            Duration(seconds: 2),
            () => Navigator.pop(context, _paymentResult),
          );
        }
      } else {
        // Unexpected response format
        _handlePaymentResponse(code: -1);
        Future.delayed(
          Duration(seconds: 2),
          () => Navigator.pop(context, false),
        );
      }
    } on PlatformException catch (e) {
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

    Service.showMessage(
      context: context,
      title: message,
      error: isError,
      duration: 3,
    );
  }

  @override
  void initState() {
    super.initState();
    getRreceiveCode(
      amount: "${widget.amount}",
      traceNo: widget.traceNo,
      phone: widget.phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TeleBirr InApp", style: TextStyle(color: kBlackColor)),
        centerTitle: true,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Initiating Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: kBlackColor,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 4),
                ),
                Text(
                  'Powered by Ethiotelecom',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: kGreyColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),

            // Telebirr Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(
                getProportionateScreenWidth(kDefaultPadding / 2),
              ),
              child: Image.asset(
                "images/payment/telebirr.png",
                height: getProportionateScreenHeight(kDefaultPadding * 12),
                width: getProportionateScreenWidth(kDefaultPadding * 12),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),

            // Loading Indicator
            SpinKitPouringHourGlassRefined(
              color: kGreyColor,
              size: getProportionateScreenWidth(kDefaultPadding * 3),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),

            // Loading Text
            Text(
              "Waiting for your payment to be confirmed...",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: kBlackColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            Text(
              "Please complete the transaction in the Telebirr app.",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: kGreyColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> getRreceiveCode({
    required String amount,
    required String traceNo,
    required String phone,
  }) async {
    var responseData;
    final deviceType = Platform.isIOS ? "iOS" : "android";
    var url = "https://pgw.shekla.app/telebirrInapp/create_order";

    Map data = {
      "traceNo": traceNo,
      "phone": phone,
      "amount": amount,
      "description": "ZMall wallet topup production",
      "isInapp": true,
    };
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
            Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException("The connection has timed out!");
            },
          );

      setState(() {
        responseData = json.decode(response.body);
      });
      // debugPrint("getRreceiveCode>>> ${json.decode(response.body)}");
      if (responseData != null &&
          responseData['createOrderResult']['result']
                  .toString()
                  .toLowerCase() ==
              'success') {
        //////check platform and call function based on the device placeOrderAndroid or placeOrderIos
        deviceType == "android"
            ? placeOrder(
                appId: responseData["appId"],
                shortCode: responseData["shortCode"],
                receiveCode:
                    responseData['createOrderResult']['biz_content']['receiveCode'],
              )
            : placeOrderIOS(
                appId: responseData["appId"],
                shortCode: responseData["shortCode"],
                receiveCode:
                    responseData['createOrderResult']['biz_content']['receiveCode'],
              );
      } else if (responseData != null &&
          responseData['createOrderResult']['errorCode'] != null) {
        Navigator.pop(context, false);
        Service.showMessage(
          error: true,
          context: context,
          title: 'Faild to initiate payment, please try agin!',
        );
      }
      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }
}



// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as http;
// import 'package:zmall/constants.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';

// class TopupPaymentInApp extends StatefulWidget {
//   const TopupPaymentInApp({
//     super.key,
//     required this.amount,
//     required this.phone,
//     required this.traceNo,
//     required this.context,
//   });
//   final double amount;
//   final String phone;
//   final String traceNo;
//   final BuildContext context;

//   @override
//   _TopupPaymentInAppState createState() => _TopupPaymentInAppState();
// }

// class _TopupPaymentInAppState extends State<TopupPaymentInApp> {
//   static const MethodChannel _channel =
//       MethodChannel('telebirrInAppSdkChannel');

//   Future<dynamic> placeOrderIOS({
//     required String receiveCode,
//     required String appId,
//     required String shortCode,
//   }) async {
//     try {
//       final Map<String, dynamic> arguments = {
//         'receiveCode': receiveCode,
//         'appId': appId,
//         'shortCode': shortCode,
//         // 'returnUrl': returnUrl
//       };
//       // debugPrint('Invoking native placeOrder method with arguments:>>>> $arguments\n');

//       final response = await _channel.invokeMethod('placeOrder', arguments);
//       // debugPrint("Native iOS Response:>>>> ${response.toString()}\n");

//       // Check if the response is a map and contains status and code
//       if (response.isNotEmpty) {
//         final int code = int.parse(response['code'].toString());
//         // debugPrint("iOS Code:>>>> $code");
//         Map<String, dynamic> _paymentResult = {
//           "code": code,
//           "status": response['status'].toString(),
//           "traceNo": widget.traceNo,
//           "message": response['errMsg'].toString(),
//         };

//         ///Confirm payment verification
//         if (code == 0) {
//           _handlePaymentResponse(code: code);
//           Future.delayed(
//             Duration(seconds: 2),
//             () => Navigator.pop(context, _paymentResult),
//           );
//         } else {
//           _handlePaymentResponse(code: code);
//           Future.delayed(Duration(seconds: 2),
//               () => Navigator.pop(context, _paymentResult));
//         }
//       } else {
//         // Unexpected response format
//         _handlePaymentResponse(code: -1);
//         Future.delayed(
//             Duration(seconds: 2), () => Navigator.pop(context, false));
//       }
//     } on PlatformException catch (e) {
//       _handlePaymentResponse(code: e.details["code"]);

//       Future.delayed(Duration(seconds: 2), () {
//         if (mounted) {
//           Navigator.pop(context, false);
//         }
//       });
//     }
//   }

//   Future<dynamic> placeOrder({
//     required String receiveCode,
//     required String appId,
//     required String shortCode,
//   }) async {
//     try {
//       final Map<String, dynamic> arguments = {
//         'appId': appId,
//         'shortCode': shortCode,
//         'receiveCode': receiveCode,
//       };

//       final Map<Object?, Object?> response =
//           await _channel.invokeMethod('placeOrder', arguments);

//       // debugPrint("***Response From Native Android***: ${response.toString()}");

//       // Check if the response is a map and contains status and code
//       if (response.isNotEmpty) {
//         final int code = int.parse(response['code'].toString());
//         Map<String, dynamic> _paymentResult = {
//           "code": code,
//           "status": response['status'].toString(),
//           "traceNo": widget.traceNo,
//           "message": response['errMsg'].toString(),
//         };

//         ///Confirm payment verification
//         if (code == 0) {
//           _handlePaymentResponse(code: code);
//           Future.delayed(
//             Duration(seconds: 2),
//             () => Navigator.pop(context, _paymentResult),
//           );
//         } else {
//           _handlePaymentResponse(code: -99);
//           Future.delayed(
//             Duration(seconds: 2),
//             () => Navigator.pop(
//               context,
//               _paymentResult,
//             ),
//           );
//         }
//       } else {
//         // Unexpected response format
//         _handlePaymentResponse(code: -1);
//         Future.delayed(
//           Duration(seconds: 2),
//           () => Navigator.pop(context, false),
//         );
//       }
//     } on PlatformException catch (e) {
//       _handlePaymentResponse(code: e.details["code"]);
//       Future.delayed(
//         Duration(seconds: 2),
//         () => Navigator.pop(context, false),
//       );
//     }
//   }

//   // Function to handle payment response based on the response code or message
//   void _handlePaymentResponse({required int code, String? errorMessage}) {
//     String message;
//     bool isError = false;
//     if (errorMessage != null) {
//       // If there's an error message, show it
//       message = errorMessage;
//       isError = true;
//     } else {
//       // Handle different response codes
//       switch (code) {
//         case 0:
//           message =
//               "✅ Payment successful! Your transaction has been completed successfully. Thank you for using our service!";
//           isError = false;
//           break;
//         case -1:
//           message = "❌ Unknown error occurred. Please try again.";
//           isError = true;
//           break;
//         case -2:
//           message =
//               "⚠️ There seems to be an issue with your input. Please double-check the parameters you provided and try again.";
//           isError = true;
//           break;
//         case -3:
//           message =
//               "⚠️ Payment was cancelled by the user. If this was not intentional, please try again to complete the payment.";
//           isError = true;
//           break;
//         case -10:
//           message =
//               "⚠️ It looks like Telebirr is not installed on your device. Please install it and try again.";
//           isError = true;
//           break;
//         case -11:
//           message =
//               "⚠️ The current version of Telebirr doesn't support this feature. Please upgrade your Telebirr app to the latest version and try again.";
//           isError = true;
//           break;
//         case -99:
//           message = "⚠️ Payment is not confirmed";
//           isError = true;
//           break;
//         default:
//           message = "❌  Unknown error occurred. Please try again.";
//           isError = true;
//           break;
//       }
//     }
//     // Display the message in the UI

//     Service.showMessage(
//       context: context,
//       title: message,
//       error: isError,
//       duration: 2,
//     );
//   }

//   @override
//   void initState() {
//     super.initState();

//     // Call getRreceiveCode here as it's part of the initial payment process
//     getRreceiveCode(
//       amount: "${widget.amount}",
//       traceNo: widget.traceNo,
//       phone: widget.phone,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Ensure SizeConfig is initialized
//     SizeConfig().init(context);

//     return Scaffold(
//       backgroundColor: kPrimaryColor,
//       appBar: AppBar(
//         elevation: 0,
//         leading: BackButton(
//           color: kBlackColor,
//           onPressed: () {
//             // Provide a clear pop behavior if user cancels from here
//             Navigator.pop(context, false);
//           },
//         ),
//         title: Text(
//           "Telebirr Payment",
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: kBlackColor,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0.5,
//               ),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Text(
//                   'Initiating Payment',
//                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.w900,
//                         color: kBlackColor,
//                         letterSpacing: 0.8,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(
//                     height: getProportionateScreenHeight(kDefaultPadding / 4)),
//                 Text(
//                   'Via Telebirr InApp - Powered by Ethiotelecom',
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w500,
//                         color: kGreyColor,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),

//             // Telebirr Logo
//             ClipRRect(
//               borderRadius: BorderRadius.circular(
//                   getProportionateScreenWidth(kDefaultPadding / 2)),
//               child: Image.asset(
//                 "images/payment/telebirr.png",
//                 height: getProportionateScreenHeight(kDefaultPadding * 12),
//                 width: getProportionateScreenWidth(kDefaultPadding * 12),
//                 fit: BoxFit.contain,
//               ),
//             ),
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),

//             // Loading Indicator
//             SpinKitPouringHourGlassRefined(
//               color: kGreyColor,
//               size: getProportionateScreenWidth(kDefaultPadding * 3),
//             ),
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),

//             // Loading Text
//             Text(
//               "Waiting for your payment to be confirmed...",
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: kBlackColor.withValues(alpha: 0.8),
//                     fontWeight: FontWeight.w600,
//                   ),
//             ),
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
//             Text(
//               "Please complete the transaction in the Telebirr app.",
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: kGreyColor,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<dynamic> getRreceiveCode({
//     required String amount,
//     required String traceNo,
//     required String phone,
//   }) async {
//     final deviceType = Platform.isIOS ? "iOS" : "android";
//     var url =
//         "https://pgw.shekla.app/telebirrInapp/create_order"; //test_create_order
//     var responseData;
//     Map data = {
//       "traceNo": traceNo,
//       "phone": phone,
//       "amount": amount,
//       "description": "ZMall wallet topup",
//       "isInapp": true
//     };
//     var body = json.encode(data);
//     // debugPrint("body>>> $body");
//     try {
//       http.Response response = await http
//           .post(
//         Uri.parse(url),
//         headers: <String, String>{
//           "Content-Type": "application/json",
//           "Accept": "application/json"
//         },
//         body: body,
//       )
//           .timeout(
//         Duration(seconds: 15),
//         onTimeout: () {
//           throw TimeoutException("The connection has timed out!");
//         },
//       );

//       setState(() {
//         responseData = json.decode(response.body);
//       });
//       if (responseData != null &&
//           responseData['createOrderResult']['result']
//                   .toString()
//                   .toLowerCase() ==
//               'success') {
//         //////check platform and call function based on the device placeOrderAndroid or placeOrderIos
//         deviceType == "android"
//             ? placeOrder(
//                 appId: responseData["appId"],
//                 shortCode: responseData["shortCode"],
//                 receiveCode: responseData['createOrderResult']['biz_content']
//                     ['receiveCode'],
//               )
//             : placeOrderIOS(
//                 appId: responseData["appId"],
//                 shortCode: responseData["shortCode"],
//                 receiveCode: responseData['createOrderResult']['biz_content']
//                     ['receiveCode'],
//               );
      // } else if (responseData != null &&
      //     responseData['createOrderResult']['errorCode'] != null) {
      //   Navigator.of(context).pop();
      //   Service.showMessage(
      //     error: true,
      //     context: context,
      //     title: 'Faild to initiate payment, please try agin!',
      //   );
      // }
//       // debugPrint("getRreceiveCode>>> ${json.decode(response.body)}");
//       return json.decode(response.body);
//     } catch (e) {
//       return null;
//     }
//   }
// }



//   // Future<dynamic> confirmPayment({
//   //   required int code,
//   //   required String traceNo,
//   //   required String status,
//   //   required String message,
//   // }) async {
//   //   var url =
//   //       "https://pgw.shekla.app/telebirrInapp/in_app_call_back_for_user_wallet_topup";
//   //   Map data = {
//   //     "code": code,
//   //     "status": status,
//   //     "traceNo": traceNo,
//   //     "message": message
//   //   };
//   //   var body = json.encode(data);
//   //   // debugPrint("body>>> $body");
//   //   try {
//   //     http.Response response = await http
//   //         .post(
//   //       Uri.parse(url),
//   //       headers: <String, String>{
//   //         "Content-Type": "application/json",
//   //         "Accept": "application/json"
//   //       },
//   //       body: body,
//   //     )
//   //         .timeout(
//   //       Duration(seconds: 15),
//   //       onTimeout: () {
//   //         throw TimeoutException("The connection has timed out!");
//   //       },
//   //     );
//   //     // debugPrint("res>>> ${json.decode(response.body)}");
//   //     return json.decode(response.body);
//   //   } catch (e) {
//   //     return null;
//   //   }
//   // }