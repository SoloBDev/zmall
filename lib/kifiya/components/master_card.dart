// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';

// class MasterCard extends StatefulWidget {
//   const MasterCard({
//     required this.currency,
//     required this.amount,
//     this.title = "MasterCard",
//     this.isAbroad = false,
//   });
//   final String title;
//   final String currency;
//   final double amount;
//   final bool isAbroad;

//   @override
//   _MasterCardState createState() => _MasterCardState();
// }

// class _MasterCardState extends State<MasterCard> {
//   bool _loading = false;
//   String session = '';
//   String currency = '';
//   String MasterCardUrl = "";
//   String uuid = "";
//   InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
//       crossPlatform: InAppWebViewOptions(
//         useShouldOverrideUrlLoading: true,
//         mediaPlaybackRequiresUserGesture: false,
//       ),
//       android: AndroidInAppWebViewOptions(
//         useHybridComposition: true,
//       ),
//       ios: IOSInAppWebViewOptions(
//         allowsInlineMediaPlayback: true,
//       ));

//   @override
//   void initState() {
//     super.initState();
//     _initMasterCard();
//   }

//   void _initMasterCard() async {
//     var data = await initMasterCard();
//     print(data);

//     if (data != null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(Service.showMessage("Loading...", false, duration: 6));

//       print(MasterCardUrl);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _loading
//         ? Scaffold(
//             appBar: AppBar(
//               title: Text(
//                 widget.title,
//                 style: TextStyle(color: kBlackColor),
//               ),
//               leadingWidth: getProportionateScreenWidth(75.0),
//               leading: Align(
//                 alignment: Alignment.centerLeft,
//                 child: TextButton(
//                   child: Text("Done"),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//               ),
//             ),
//             body: Center(
//               child: SpinKitWave(
//                 color: kSecondaryColor,
//                 size: getProportionateScreenWidth(kDefaultPadding),
//               ),
//             ),
//           )
//         : Scaffold(
//             appBar: AppBar(
//               title: Text(
//                 widget.title,
//                 style: TextStyle(color: kBlackColor),
//               ),
//               leadingWidth: getProportionateScreenWidth(75.0),
//               leading: TextButton(
//                 child: Text("Done"),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ),
//             body: InAppWebView(
//               initialOptions: options,
//               initialUrlRequest: URLRequest(
//                 url: Uri.parse(MasterCardUrl),
//               ),
//             ),
//           );
//   }

//   Future<dynamic> initMasterCard() async {
//     // String session = '';
//     String askUrl =
//         "$BASE_URL/admin/mastercard/api/checkout"; //api to get to get session

//     setState(() {
//       _loading = true;
//     });

//     print(askUrl);
//     Map data = {
//       "currency": widget.currency,
//       "amount": widget.amount,
//       "description": "ZMall Order Payment",
//     };
//     var body1 = json.encode(data);
//     print(body1);
//     try {
//       http.Response response = await http
//           .post(
//         Uri.parse(askUrl),
//         headers: <String, String>{
//           "Content-Type": "application/json",
//           "Accept": "application/json"
//         },
//         body: body1,
//       )
//           .timeout(
//         Duration(seconds: 10),
//         onTimeout: () {
//           setState(() {
//             this._loading = false;
//           });
//           throw TimeoutException("The connection has timed out!");
//         },
//       );
//       setState(() {
//         this._loading = false;
//       });
//       print(response.body);
//       var bodyPart = json.decode(response.body);
//       setState(() {
//         _loading = true;
//         session = bodyPart['sessionId'];
//       });
//       print(session);
//       // print(MasterCardUrl);
//       setState(() {
//         this._loading = false;
//       });
//       MasterCardUrl =
//           "https://ap-gateway.mastercard.com/checkout/pay/$session?checkoutVersion=1.0.0";
//       // print(MasterCardUrl);
//       return session;
//     } catch (e) {
//       print(e);
//       setState(() {
//         this._loading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         Service.showMessage(
//             "Something went wrong. Please check your internet connection!",
//             true),
//       );
//       return null;
//     }
//   }
// }
