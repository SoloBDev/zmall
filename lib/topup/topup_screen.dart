// import 'dart:async';
// import 'dart:convert';
// import 'package:heroicons_flutter/heroicons_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/custom_widgets/custom_button.dart';
// import 'package:zmall/login/login_screen.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';
// import 'package:zmall/widgets/custom_text_field.dart';

// class TopUpScreen extends StatefulWidget {
//   const TopUpScreen({@required this.userData});

//   final userData;

//   @override
//   _TopUpScreenState createState() => _TopUpScreenState();
// }

// class _TopUpScreenState extends State<TopUpScreen> {
//   double topUpAmount = 0.0;
//   bool _loading = false;
//   bool _otpSent = false;
//   late String otp;
//   var kifiyaGateway;
//   var userData;

//   @override
//   void initState() {
//     super.initState();
//     userData = widget.userData;
//     _getKifiyaGateway();
//   }

//   void _sendOtp() async {
//     if (topUpAmount == 0.0) {
//       Service.showMessage(
//           context: context, title: "Please enter a valid amount", error: true);
//     } else {
//       var data = await sendOTP();
//       if (data != null && data['success']) {
//         setState(() {
//           _otpSent = true;
//         });

//         Service.showMessage(
//           context: context,
//           title: "OTP successfully sent!",
//           error: false,
//         );
//       }
//     }
//   }

  // void _getKifiyaGateway() async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   debugPrint("Fetching payment gateway");
  //   var data = await getKifiyaGateway();
  //   if (data != null && data['success']) {
  //     setState(() {
  //       _loading = false;
  //       kifiyaGateway = data;
  //     });
  //   } else {
  //     setState(() {
  //       _loading = false;
  //     });
  //     Service.showMessage(
  //       context: context,
  //       title: "${errorCodes['${data['error_code']}']}!",
  //       error: true,
  //     );
  //     await Future.delayed(Duration(seconds: 2));
  //     if (data['error_code'] == 999) {
  //       await Service.saveBool('logged', false);
  //       await Service.remove('user');
  //       Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  //     }
  //   }
  // }

//   void verifyOTP() async {
//     setState(() {
//       _loading = true;
//     });
//     if (otp.isNotEmpty && otp.length == 4) {
//       var data = await amoleAddToBorsa();
//       if (data != null && data['success']) {
//         userData['user']['wallet'] += topUpAmount;
//         Service.save('user', userData);
//         Navigator.of(context).pop();

//         Service.showMessage(
//           context: context,
//           title: "Wallet top-up successfull!",
//           error: false,
//         );
//         setState(() {
//           _loading = false;
//         });
//       } else {
//         Service.showMessage(
//           context: context,
//           title:
//               "Add to wallet failed! Please check if you have sufficient fund or check the OTP again.",
//           error: true,
//           duration: 4,
//         );
//         setState(() {
//           _loading = false;
//         });
//         Navigator.of(context).pop();
//       }
//     } else {
//       setState(() {
//         _loading = false;
//       });

//       Service.showMessage(
//         context: context,
//         title: "Please enter a valid OTP.",
//         error: true,
//         duration: 4,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kPrimaryColor,
//       appBar: AppBar(
//         title: Text(
//           "Top-Up",
//           style: TextStyle(color: kBlackColor),
//         ),
//         elevation: 1.0,
//       ),
//       body: Padding(
//         padding:
//             EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
//         child: Center(
//           child: Container(
//             padding: EdgeInsets.symmetric(
//                 vertical: getProportionateScreenHeight(kDefaultPadding),
//                 horizontal: getProportionateScreenWidth(kDefaultPadding)),
//             decoration: BoxDecoration(
//                 boxShadow: [kDefaultShadow],
//                 color: kPrimaryColor,
//                 border: Border.all(
//                   color: kWhiteColor,
//                 ),
//                 borderRadius: BorderRadius.circular(kDefaultPadding)),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               spacing: getProportionateScreenHeight(kDefaultPadding),
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(kDefaultPadding),
//                         decoration: BoxDecoration(
//                             color: kWhiteColor,
//                             // boxShadow: [kDefaultShadow],
//                             border: Border.all(color: kWhiteColor),
//                             borderRadius:
//                                 BorderRadius.circular(kDefaultPadding)),
//                         child: Icon(
//                           size: 30,
//                           HeroiconsOutline.banknotes,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   "Amount",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 CustomTextField(
//                     // style: TextStyle(color: kBlackColor),
//                     keyboardType:
//                         TextInputType.numberWithOptions(decimal: true),
//                     onChanged: (val) {
//                       try {
//                         topUpAmount = double.parse(val).toDouble();
//                       } catch (e) {
//                         topUpAmount = 0.0;
//                       }
//                     },
//                     // decoration: textFieldInputDecorator.copyWith(
//                     hintText: "Enter the amount to send"
//                     // ),
//                     ),
//                 if (_otpSent)
//                   SizedBox(
//                       height: getProportionateScreenHeight(kDefaultPadding)),
//                 if (_otpSent)
//                   TextField(
//                     style: TextStyle(color: kBlackColor),
//                     keyboardType: TextInputType.number,
//                     onChanged: (val) {
//                       otp = val;
//                     },
//                     decoration:
//                         textFieldInputDecorator.copyWith(labelText: "OTP"),
//                   ),
//                 SizedBox(
//                     height: getProportionateScreenHeight(kDefaultPadding / 4)),
//                 _otpSent
//                     ? CustomButton(
//                         title: "Submit",
//                         isLoading: _loading,
//                         press: () async {
//                           verifyOTP();
//                         },
//                         color: kSecondaryColor,
//                       )
//                     : CustomButton(
//                         isLoading: _loading,
//                         title: "Send Verification Code",
//                         press: () async {
//                           _sendOtp();
//                         },
//                         color: kSecondaryColor,
//                       )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<dynamic> sendOTP() async {
//     setState(() {
//       _loading = true;
//     });
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/send_otp";

//     Map data = {
//       "user_id": widget.userData['user']['_id'],
//       "phone": widget.userData['user']['phone'],
//       "type": widget.userData['user']['admin_type'],
//       "token": widget.userData['user']['server_token'],
//       "country_phone_code": widget.userData['user']['country_phone_code']
//     };

//     var body = json.encode(data);
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

//       return json.decode(response.body);
//     } catch (e) {
//       // debugPrint(e);
//       setState(() {
//         this._loading = false;
//       });
//       Service.showMessage(
//         context: context,
//         title:
//             "Something went wrong, please check your connection and try again!",
//         error: true,
//       );
//       return null;
//     }
//   }

  // Future<dynamic> getKifiyaGateway() async {
  //   var url =
  //       "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_payment_gateway";
  //   Map data = {
  //     "user_id": widget.userData['user']['_id'],
  //     "city_id": "5b406b46d2ddf8062d11b788",
  //     "server_token": widget.userData['user']['server_token'],
  //   };
  //   var body = json.encode(data);
  //   try {
  //     http.Response response = await http
  //         .post(
  //       Uri.parse(url),
  //       headers: <String, String>{
  //         "Content-Type": "application/json",
  //         "Accept": "application/json"
  //       },
  //       body: body,
  //     )
  //         .timeout(
  //       Duration(seconds: 10),
  //       onTimeout: () {
  //         setState(() {
  //           this._loading = false;
  //         });
  //         throw TimeoutException("The connection has timed out!");
  //       },
  //     );

  //     setState(() {
  //       this._loading = false;
  //     });

  //     return json.decode(response.body);
  //   } catch (e) {
  //     // debugPrint(e);
  //     setState(() {
  //       this._loading = false;
  //     });

  //     Service.showMessage(
  //       context: context,
  //       title:
  //           "Something went wrong, please check your connection and try again!",
  //       error: true,
  //     );
  //     return null;
  //   }
  // }

//   Future<dynamic> amoleAddToBorsa() async {
//     setState(() {
//       _loading = true;
//     });
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_wallet_amount";

//     Map data = {
//       "user_id": widget.userData['user']['_id'],
//       "payment_id": kifiyaGateway['payment_gateway'][0]['_id'],
//       "otp": otp,
//       "type": widget.userData['user']['admin_type'],
//       "server_token": widget.userData['user']['server_token'],
//       "wallet": topUpAmount,
//     };

//     var body = json.encode(data);
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

//       return json.decode(response.body);
//     } catch (e) {
//       // debugPrint(e);
//       setState(() {
//         this._loading = false;
//       });

//       Service.showMessage(
//           context: context,
//           title:
//               "Something went wrong, please check your connection and try again!",
//           error: true);
//       return null;
//     }
//   }
// }
