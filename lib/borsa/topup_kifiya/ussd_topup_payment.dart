// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';
// import 'package:zmall/widgets/custom_back_button.dart';

// class TopupPaymentUssd extends StatefulWidget {
//   const TopupPaymentUssd({
//     required this.url,
//     required this.amount,
//     required this.phone,
//     required this.traceNo,
//     this.title = "Telebirr",
//     required this.userId,
//     // required this.serverToken,
//     // required this.orderPaymentId,
//   });
//   final String url;
//   final String title;
//   final double amount;
//   final String phone;
//   final String traceNo;
//   final String userId;
//   // final String serverToken;
//   // final String orderPaymentId;

//   @override
//   _TopupPaymentUssdState createState() => _TopupPaymentUssdState();
// }

// class _TopupPaymentUssdState extends State<TopupPaymentUssd> {
//   // bool _loading = false;
//   String telebirrUrl = "";
//   String uuid = "";

//   @override
//   void initState() {
//     super.initState();
//     _initTelebirr();
//   }

//   void _initTelebirr() async {
//     var data = await initTelebirr();
//     if (data != null && data['result']['success']) {
//       Service.showMessage(
//         context: context,
//         title:
//             "${data['result']['message']}. Waiting for payment to be completed",
//         error: false,
//         duration: 6,
//       );
//       // _verifyPayment();
//     }
//   }

//   // void _verifyPayment() async {
//   //   var data = await verifyPayment();
//   //   if (data != null && data['success']) {
//   //     Navigator.pop(context);
//   //   } else {
//   //     await Future.delayed(Duration(seconds: 2))
//   //         .then((value) => _verifyPayment());
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text(
//             widget.title,
//             style: TextStyle(color: kBlackColor),
//           ),
//           leading: CustomBackButton(),
//         ),
//         body: Padding(
//           padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Pay Using Telebirr',
//                     style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//                   ),
//                   Text(
//                     'Powered by Ethiotelecom',
//                     style: TextStyle(fontSize: 21, color: Colors.black45),
//                   ),
//                 ],
//               ),
//               Image.asset(
//                 "images/payment/telebirr.png",
//                 height: getProportionateScreenHeight(kDefaultPadding * 10),
//                 width: getProportionateScreenWidth(kDefaultPadding * 10),
//               ),
//               SizedBox(
//                 height: getProportionateScreenHeight(kDefaultPadding / 2),
//               ),
//               SpinKitPouringHourGlassRefined(color: kBlackColor),
//               SizedBox(
//                 height: getProportionateScreenHeight(kDefaultPadding / 2),
//               ),
//               Text(
//                 "Please complete payment through the USSD prompt. \nWaiting for payment to be completed....",
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ));
//   }

//   Future<dynamic> initTelebirr() async {
//     // setState(() {
//     //   _loading = true;
//     // });
//     var url = widget.url;

//     //New configuration
//     Map data = {
//       "zmall": true,
//       "payerId": "22",
//       "appId": "4321",
//       "amount": widget.amount,
//       "traceNo": widget.traceNo,
//       "phone": "251${widget.phone}",
//       "apiKey": "90e503b019a811ef9bc8005056a4ed36",
//       "description": "ZMall wallet topup",
//     };
//     /*
//     //Old configuration.
//     //  Map data = {
//     //   "trace_no": widget.traceNo,
//     //   "amount": widget.amount,
//     //   "phone": widget.phone,
//     //   "appId": "1234"
//     }; */

//     var body = json.encode(data);
//     // print("body $body");
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
//         Duration(seconds: 20),
//         onTimeout: () {
//           throw TimeoutException(
//               "The connection has timed out!, please try again");
//         },
//       );

//       // print(json.decode(response.body));
//       return json.decode(response.body);
//     } catch (e) {
//       // print(e);

//       Service.showMessage(
//         context: context,
//         title: "Something went wrong. Please check your internet connection!",
//         error: true,
//       );
//       return null;
//     }
//   }

//   // Future<dynamic> verifyPayment() async {
//   //   var url =
//   //       "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";

//   //   Map data = {
//   //     "user_id": widget.userId,
//   //     "server_token": widget.serverToken,
//   //     "order_payment_id": widget.orderPaymentId
//   //   };

//   //   var body = json.encode(data);
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
//   //       Duration(seconds: 10),
//   //       onTimeout: () {
//   //         throw TimeoutException("The connection has timed out!");
//   //       },
//   //     );

//   //     return json.decode(response.body);
//   //   } catch (e) {
//   //     // print(e);

//   //     Service.showMessage(
//   //       context: context,
//   //       title: "Checking if payment is made. Please wait a moment...",
//   //       error: true,
//   //     );
//   //     return null;
//   //   }
//   // }
// }
