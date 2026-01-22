// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/custom_widgets/custom_button.dart';
// import 'package:zmall/location/components/provider_location.dart';
// import 'package:zmall/login/login_screen.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/orders/components/order_history_detail.dart';
// import 'package:zmall/product/product_screen.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';

// class OrderDetail extends StatefulWidget {
//   @override
//   _OrderDetailState createState() => _OrderDetailState();

//   const OrderDetail({
//     required this.order,
//     required this.userId,
//     required this.serverToken,
//   });

//   final order;
//   final String userId, serverToken;
// }

// class _OrderDetailState extends State<OrderDetail> {
//   bool _loading = false;
//   var responseData;
//   var orderStatus;
//   late String providerId;
//   String reason = "Changed my mind";

//   @override
//   void initState() {
//     super.initState();
//     orderStatus = widget.order;
//     _getOrderStatus();
//   }

//   void _getOrderStatus() async {
//     var data = await getOrderStatus();
//     if (data != null && data['success']) {
//       if (mounted)
//         setState(() {
//           orderStatus = data;
//           providerId = orderStatus['provider_id'] != null
//               ? orderStatus['provider_id']
//               : "";
//         });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//           Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
//       if (data['error_code'] == 999) {
//         await Service.saveBool('logged', false);
//         await Service.remove('user');
//         Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//       }
//     }
//     await Future.delayed(Duration(seconds: 10), () {
//       if (mounted) _getOrderStatus();
//     });
//   }

//   void _showInvoice() async {
//     setState(() {
//       _loading = true;
//     });
//     var data = await showInvoice();
//     if (data != null && data['success']) {
//       setState(() {
//         _loading = false;
//         responseData = data;
//       });
//       ScaffoldMessenger.of(context)
//           .showSnackBar(Service.showMessage("Order Completed!", false));
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) {
//             return OrderHistoryDetail(
//                 orderId: widget.order['_id'],
//                 userId: widget.userId,
//                 serverToken: widget.serverToken);
//           },
//         ),
//       );
//     } else {
//       setState(() {
//         _loading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//           Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
//       if (data['error_code'] == 999) {
//         await Service.saveBool('logged', false);
//         await Service.remove('user');
//         Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//       }
//     }
//   }

//   void _userCancelOrder() async {
//     debugPrint("Cancel order");
//     setState(() {
//       _loading = true;
//     });
//     var data = await userCancelOrder();
//     if (data != null && data['success']) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         Service.showMessage(
//             "We're sad but you've successfully canceled your order.", false,
//             duration: 5),
//       );
//       Navigator.of(context).pop();
//     } else {
//       if (data['error_code'] == 999) {
//         await Service.saveBool('logged', false);
//         await Service.remove('user');
//         Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//       }
//       setState(() {
//         _loading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text("${errorCodes['${data['error_code']}']}"),
//         backgroundColor: kSecondaryColor,
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             "Order Detail",
//             style: TextStyle(color: kBlackColor),
//           ),
//           elevation: 1.0,
//           bottom: TabBar(
//             indicatorColor: kSecondaryColor,
//             tabs: [
//               Column(
//                 children: [
//                   Tab(
//                     icon: Icon(
//                       Icons.delivery_dining,
//                       color: kSecondaryColor,
//                     ),
//                   ),
//                   Text(
//                     "Order Status",
//                     style: TextStyle(color: kBlackColor),
//                   )
//                 ],
//               ),
//               Column(
//                 children: [
//                   Tab(
//                     icon: Icon(
//                       Icons.shopping_basket_outlined,
//                       color: kSecondaryColor,
//                     ),
//                   ),
//                   Text(
//                     "Cart",
//                     style: TextStyle(color: kBlackColor),
//                   )
//                 ],
//               )
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                           vertical:
//                               getProportionateScreenHeight(kDefaultPadding)),
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: kSecondaryColor,
//                       ),
//                       child: Column(
//                         children: [
//                           Center(
//                             child: Text(
//                               "Total Price : ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.order['total_order_price'].toStringAsFixed(2)}",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleLarge
//                                   ?.copyWith(
//                                       fontWeight: FontWeight.w600,
//                                       color: kPrimaryColor),
//                             ),
//                           ),
//                           SizedBox(
//                             height: kDefaultPadding / 4,
//                           ),
//                           Center(
//                             child: Text(
//                               "Order ID: #${widget.order['unique_id']}",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: kPrimaryColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                           vertical:
//                               getProportionateScreenHeight(kDefaultPadding)),
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: kPrimaryColor,
//                       ),
//                       child: Column(
//                         children: [
//                           Center(
//                             child: Text(
//                               "Store : ${Service.capitalizeFirstLetters(widget.order['store_name'])}",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: kBlackColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                           vertical:
//                               getProportionateScreenHeight(kDefaultPadding)),
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: kSecondaryColor,
//                       ),
//                       child: Column(
//                         children: [
//                           Center(
//                             child: Text(
//                               // "DELIVERY ADDRESS",
//                               "Delivery Address",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: kBlackColor,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           SizedBox(
//                               height: getProportionateScreenHeight(
//                                   kDefaultPadding / 3)),
//                           Center(
//                             child: Text(
//                               "${widget.order['destination_addresses'][0]['address']}",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: kPrimaryColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     orderStatus['order_status'] != 25 &&
//                             orderStatus['delivery_status'] != null &&
//                             orderStatus['delivery_status'] < 100
//                         ? Container(
//                             padding: EdgeInsets.symmetric(
//                                 vertical: getProportionateScreenHeight(
//                                     kDefaultPadding)),
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: kPrimaryColor,
//                             ),
//                             child: Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: getProportionateScreenWidth(
//                                       kDefaultPadding)),
//                               child: Column(
//                                 children: [
//                                   Row(
//                                     children: [
//                                       orderStatus['order_status'] >= 1 &&
//                                               orderStatus['order_status'] <= 100
//                                           ? Icon(
//                                               Icons.check_circle,
//                                               color: kSecondaryColor,
//                                             )
//                                           : Icon(Icons.check_circle_outline),
//                                       SizedBox(
//                                           width: getProportionateScreenWidth(
//                                               kDefaultPadding)),
//                                       Text(
//                                         "${order_status['1']}",
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color: kBlackColor,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   SizedBox(
//                                       height: getProportionateScreenHeight(
//                                           kDefaultPadding / 2)),
//                                   Row(
//                                     children: [
//                                       orderStatus['order_status'] >= 3 &&
//                                               orderStatus['order_status'] <= 100
//                                           ? Icon(
//                                               Icons.check_circle,
//                                               color: kSecondaryColor,
//                                             )
//                                           : Icon(Icons.check_circle_outline),
//                                       SizedBox(
//                                           width: getProportionateScreenWidth(
//                                               kDefaultPadding)),
//                                       Text(
//                                         "${order_status['3']}",
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color: kBlackColor,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   SizedBox(
//                                       height: getProportionateScreenHeight(
//                                           kDefaultPadding / 2)),
//                                   Row(
//                                     children: [
//                                       orderStatus['order_status'] >= 5 &&
//                                               orderStatus['order_status'] <= 100
//                                           ? Icon(
//                                               Icons.check_circle,
//                                               color: kSecondaryColor,
//                                             )
//                                           : Icon(Icons.check_circle_outline),
//                                       SizedBox(
//                                           width: getProportionateScreenWidth(
//                                               kDefaultPadding)),
//                                       Text(
//                                         "${order_status['5']}",
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color: kBlackColor,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   SizedBox(
//                                       height: getProportionateScreenHeight(
//                                           kDefaultPadding / 2)),
//                                   Row(
//                                     children: [
//                                       orderStatus['order_status'] >= 7 &&
//                                               orderStatus['order_status'] <= 100
//                                           ? Icon(
//                                               Icons.check_circle,
//                                               color: kSecondaryColor,
//                                             )
//                                           : Icon(Icons.check_circle_outline),
//                                       SizedBox(
//                                           width: getProportionateScreenWidth(
//                                               kDefaultPadding)),
//                                       Text(
//                                         "${order_status['7']}",
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color: kBlackColor,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   widget.order['destination_addresses'][0]
//                                                   ['address']
//                                               .toString()
//                                               .toLowerCase() !=
//                                           "user pickup"
//                                       ? Column(
//                                           children: [
//                                             /*
//                                             SizedBox(
//                                                 height:
//                                                     getProportionateScreenHeight(
//                                                         kDefaultPadding / 2)),
//                                             Row(
//                                               children: [
//                                                 orderStatus['delivery_status'] >=
//                                                             11 &&
//                                                         orderStatus[
//                                                                 'delivery_status'] <=
//                                                             100
//                                                     ? Icon(
//                                                         Icons.check_circle,
//                                                         color: kSecondaryColor,
//                                                       )
//                                                     : Icon(Icons
//                                                         .check_circle_outline),
//                                                 SizedBox(
//                                                     width:
//                                                         getProportionateScreenWidth(
//                                                             kDefaultPadding)),
//                                                 Text(
//                                                   "${order_status['11']}",
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     color: kBlackColor,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             SizedBox(
//                                                 height:
//                                                     getProportionateScreenHeight(
//                                                         kDefaultPadding / 2)),
//                                             Row(
//                                               children: [
//                                                 orderStatus['delivery_status'] >=
//                                                             13 &&
//                                                         orderStatus[
//                                                                 'delivery_status'] <=
//                                                             100
//                                                     ? Icon(
//                                                         Icons.check_circle,
//                                                         color: kSecondaryColor,
//                                                       )
//                                                     : Icon(Icons
//                                                         .check_circle_outline),
//                                                 SizedBox(
//                                                     width:
//                                                         getProportionateScreenWidth(
//                                                             kDefaultPadding)),
//                                                 Text(
//                                                   "${order_status['13']}",
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     color: kBlackColor,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             SizedBox(
//                                                 height:
//                                                     getProportionateScreenHeight(
//                                                         kDefaultPadding / 2)),
//                                             Row(
//                                               children: [
//                                                 orderStatus['delivery_status'] >=
//                                                             15 &&
//                                                         orderStatus[
//                                                                 'delivery_status'] <=
//                                                             100
//                                                     ? Icon(
//                                                         Icons.check_circle,
//                                                         color: kSecondaryColor,
//                                                       )
//                                                     : Icon(Icons
//                                                         .check_circle_outline),
//                                                 SizedBox(
//                                                     width:
//                                                         getProportionateScreenWidth(
//                                                             kDefaultPadding)),
//                                                 Text(
//                                                   "${order_status['15']}",
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     color: kBlackColor,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             SizedBox(
//                                                 height:
//                                                     getProportionateScreenHeight(
//                                                         kDefaultPadding / 2)),
//                                             Row(
//                                               children: [
//                                                 orderStatus['delivery_status'] >=
//                                                             17 &&
//                                                         orderStatus[
//                                                                 'delivery_status'] <=
//                                                             100
//                                                     ? Icon(
//                                                         Icons.check_circle,
//                                                         color: kSecondaryColor,
//                                                       )
//                                                     : Icon(Icons
//                                                         .check_circle_outline),
//                                                 SizedBox(
//                                                     width:
//                                                         getProportionateScreenWidth(
//                                                             kDefaultPadding)),
//                                                 Text(
//                                                   "${order_status['17']}",
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     color: kBlackColor,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ), */
//                                             SizedBox(
//                                                 height:
//                                                     getProportionateScreenHeight(
//                                                         kDefaultPadding / 2)),
//                                             Row(
//                                               children: [
//                                                 orderStatus['delivery_status'] >=
//                                                             19 &&
//                                                         orderStatus[
//                                                                 'delivery_status'] <=
//                                                             100
//                                                     ? Icon(
//                                                         Icons.check_circle,
//                                                         color: kSecondaryColor,
//                                                       )
//                                                     : Icon(Icons
//                                                         .check_circle_outline),
//                                                 SizedBox(
//                                                     width:
//                                                         getProportionateScreenWidth(
//                                                             kDefaultPadding)),
//                                                 Text(
//                                                   "${order_status['19']}",
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     color: kBlackColor,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             SizedBox(
//                                                 height:
//                                                     getProportionateScreenHeight(
//                                                         kDefaultPadding / 2)),
//                                             /*
//                                             Row(
//                                               children: [
//                                                 orderStatus['delivery_status'] >=
//                                                             21 &&
//                                                         orderStatus[
//                                                                 'delivery_status'] <=
//                                                             100
//                                                     ? Icon(
//                                                         Icons.check_circle,
//                                                         color: kSecondaryColor,
//                                                       )
//                                                     : Icon(Icons
//                                                         .check_circle_outline),
//                                                 SizedBox(
//                                                     width:
//                                                         getProportionateScreenWidth(
//                                                             kDefaultPadding)),
//                                                 Text(
//                                                   "${order_status['21']}",
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     color: kBlackColor,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             SizedBox(
//                                                 height:
//                                                     getProportionateScreenHeight(
//                                                         kDefaultPadding / 2)), */
//                                             Row(
//                                               children: [
//                                                 orderStatus['delivery_status'] >=
//                                                             23 &&
//                                                         orderStatus[
//                                                                 'delivery_status'] <=
//                                                             100
//                                                     ? Icon(
//                                                         Icons.check_circle,
//                                                         color: kSecondaryColor,
//                                                       )
//                                                     : Icon(Icons
//                                                         .check_circle_outline),
//                                                 SizedBox(
//                                                     width:
//                                                         getProportionateScreenWidth(
//                                                             kDefaultPadding)),
//                                                 Text(
//                                                   "${order_status['23']}",
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     color: kBlackColor,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         )
//                                       : Container(),
//                                 ],
//                               ),
//                             ),
//                           )
//                         : Container(
//                             padding: EdgeInsets.symmetric(
//                                 vertical: getProportionateScreenHeight(
//                                     kDefaultPadding),
//                                 horizontal: getProportionateScreenWidth(
//                                     kDefaultPadding)),
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: kPrimaryColor,
//                             ),
//                             child: Column(
//                               children: [
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.check_circle,
//                                       color: kSecondaryColor,
//                                     ),
//                                     SizedBox(
//                                         width: getProportionateScreenWidth(
//                                             kDefaultPadding)),
//                                     Text(
//                                       "${order_status['${orderStatus['order_status']}']}",
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color: kBlackColor,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                     orderStatus['order_status'] != 25 &&
//                             orderStatus['delivery_status'] != null &&
//                             orderStatus['delivery_status'] > 100
//                         ? Container(
//                             padding: EdgeInsets.symmetric(
//                                 vertical: getProportionateScreenHeight(
//                                     kDefaultPadding)),
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: kSecondaryColor,
//                             ),
//                             child: Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: getProportionateScreenWidth(
//                                       kDefaultPadding)),
//                               child: Column(
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Icon(
//                                         Icons.cancel,
//                                         color: kPrimaryColor,
//                                       ),
//                                       SizedBox(
//                                           width: getProportionateScreenWidth(
//                                               kDefaultPadding)),
//                                       Text(
//                                         "${order_status['${orderStatus['delivery_status']}']}",
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color: kPrimaryColor,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           )
//                         : Container(),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     orderStatus['order_status'] == 3
//                         ? TextButton(
//                             onPressed: () {
//                               _showDialog();
//                             },
//                             child: Text(
//                               "Cancel Order",
//                               style: TextStyle(color: kBlackColor),
//                             ),
//                           )
//                         : Container(),
//                     orderStatus != null &&
//                             orderStatus['provider_id'] != null &&
//                             orderStatus['order_status'] != 25 &&
//                             orderStatus['delivery_status'] != null &&
//                             orderStatus['delivery_status'] >= 17 &&
//                             orderStatus['delivery_status'] < 25
//                         ? Padding(
//                             padding: EdgeInsets.only(
//                               bottom:
//                                   getProportionateScreenHeight(kDefaultPadding),
//                               left:
//                                   getProportionateScreenWidth(kDefaultPadding),
//                               right:
//                                   getProportionateScreenWidth(kDefaultPadding),
//                             ),
//                             child: CustomButton(
//                               title: "Track My Order",
//                               press: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) {
//                                       return ProviderLocation(
//                                         providerId: orderStatus['provider_id'],
//                                         providerImage:
//                                             orderStatus['provider_image'],
//                                         providerName:
//                                             orderStatus['provider_first_name'],
//                                         providerPhone:
//                                             orderStatus['provider_phone'],
//                                         destLat:
//                                             orderStatus['destination_addresses']
//                                                 [0]['location'][0],
//                                         destLong:
//                                             orderStatus['destination_addresses']
//                                                 [0]['location'][1],
//                                         userId: widget.userId,
//                                         serverToken: widget.serverToken,
//                                       );
//                                     },
//                                   ),
//                                 );
//                               },
//                               color: kSecondaryColor,
//                             ),
//                           )
//                         : Container(),
//                     orderStatus['order_status'] == 25
//                         ? Padding(
//                             padding: EdgeInsets.only(
//                               bottom:
//                                   getProportionateScreenHeight(kDefaultPadding),
//                               left:
//                                   getProportionateScreenWidth(kDefaultPadding),
//                               right:
//                                   getProportionateScreenWidth(kDefaultPadding),
//                             ),
//                             child: _loading
// //                                ? SpinKitWave(
// //                                    size: getProportionateScreenWidth(
// //                                        kDefaultPadding),
// //                                    color: kBlackColor,
// //                                  )
//                                 ? Container()
//                                 : CustomButton(
//                                     title: "SUBMIT",
//                                     press: () {
//                                       _showInvoice();
//                                     },
//                                     color: kBlackColor,
//                                   ),
//                           )
//                         : Container()
//                   ],
//                 ),
//               ],
//             ),
//             Padding(
//               padding:
//                   EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
//               child: Column(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: widget.order['order_details'].length,
//                       itemBuilder: (context, index) {
//                         String extractProductName(String? noteForItem) {
//                           if (noteForItem == null || noteForItem.isEmpty)
//                             return '';
//                           return noteForItem.split(': ').first;
//                         }

//                         return Column(
//                           children: [
//                             CategoryContainer(
//                                 title: widget.order['order_details'][index]
//                                                 ['product_name']
//                                             .toString()
//                                             .toLowerCase() ==
//                                         "aliexpress"
//                                     ? "${Service.capitalizeFirstLetters(extractProductName(widget.order['order_details'][index]['items'][0]['note_for_item']))}"
//                                     : widget.order['order_details'][index]
//                                                 ['product_name'] !=
//                                             null
//                                         ? Service.capitalizeFirstLetters(
//                                             widget.order['order_details'][index]
//                                                 ['product_name'])
//                                         : "Item"),
//                             SizedBox(
//                                 height: getProportionateScreenHeight(
//                                     kDefaultPadding / 3)),
//                             Container(
//                               width: double.infinity,
//                               decoration: BoxDecoration(
//                                 color: kPrimaryColor,
//                                 // borderRadius: BorderRadius.circular(
//                                 //   getProportionateScreenWidth(kDefaultPadding),
//                                 // ),
//                               ),
//                               child: Padding(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: getProportionateScreenWidth(
//                                       kDefaultPadding / 2),
//                                   vertical: getProportionateScreenHeight(
//                                       kDefaultPadding),
//                                 ),
//                                 child: ListView.builder(
//                                   physics: ClampingScrollPhysics(),
//                                   shrinkWrap: true,
//                                   itemCount: widget
//                                       .order['order_details'][index]['items']
//                                       .length,
//                                   itemBuilder: (context, idx) {
//                                     String extractItemName(
//                                         String? noteForItem) {
//                                       if (noteForItem == null ||
//                                           noteForItem.isEmpty) return '';
//                                       var parts = noteForItem.split(': ');
//                                       return parts.length >= 3
//                                           ? "${parts[2]}:\n${parts[1]}"
//                                           : parts.length >= 2
//                                               ? "${parts[1]}"
//                                               : '';
//                                     }

//                                     return Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 widget.order['order_details']
//                                                                 [index]
//                                                                 ['product_name']
//                                                             .toString()
//                                                             .toLowerCase() ==
//                                                         "aliexpress"
//                                                     ? "${extractItemName(widget.order['order_details'][index]['items'][idx]['note_for_item'])}"
//                                                     : "${Service.capitalizeFirstLetters(widget.order['order_details'][index]['items'][idx]['item_name'])}",
//                                                 softWrap: true,
//                                                 style: Theme.of(context)
//                                                     .textTheme
//                                                     .titleMedium
//                                                     ?.copyWith(
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                     ),
//                                               ),
//                                               Text(
//                                                 "Quantity: ${widget.order['order_details'][index]['items'][idx]['quantity']}",
//                                                 style: Theme.of(context)
//                                                     .textTheme
//                                                     .bodySmall,
//                                               )
//                                             ],
//                                           ),
//                                         ),
//                                         Text(
//                                           "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.order['order_details'][index]['items'][idx]['total_price'].toStringAsFixed(2)}",
//                                           style: TextStyle(
//                                               fontWeight: FontWeight.w700),
//                                         )
//                                       ],
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                             SizedBox(
//                               height: getProportionateScreenHeight(
//                                   kDefaultPadding / 2),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),
//                   Center(
//                     child: Text(
//                       "Total Price : ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.order['total_order_price'].toStringAsFixed(2)}",
//                       style: Theme.of(context)
//                           .textTheme
//                           .titleLarge
//                           ?.copyWith(fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   Container(
//                     width: double.infinity,
//                     height: 0.1,
//                     color: kSecondaryColor,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: kPrimaryColor,
//           title: Text("Keep Order"),
//           content: Text("Are you sure you want to cancel?"),
//           actions: <Widget>[
//             TextButton(
//               child: Text(
//                 "Think about it!",
//                 style: TextStyle(
//                   color: kSecondaryColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(
//                 "Sure",
//                 style: TextStyle(color: kBlackColor),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _showCanceDialog();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showCanceDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: kPrimaryColor,
//           title: Text("Reason ☹"),
//           content: TextField(
//             style: TextStyle(color: kBlackColor),
//             keyboardType: TextInputType.text,
//             onChanged: (val) {
//               reason = val;
//             },
//             decoration: textFieldInputDecorator.copyWith(
//               labelText: "Reason",
//               hintText: "$reason",
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text(
//                 "Think about it!",
//                 style: TextStyle(
//                   color: kSecondaryColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(
//                 "Sure",
//                 style: TextStyle(color: kBlackColor),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _userCancelOrder();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<dynamic> userCancelOrder() async {
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_cancel_order";
//     Map data = {
//       "user_id": widget.userId,
//       "server_token": widget.serverToken,
//       "cancel_reason": reason,
//       "order_id": widget.order['_id'],
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
//           ScaffoldMessenger.of(context)
//               .showSnackBar(Service.showMessage("Network error", true));
//           setState(() {
//             _loading = false;
//           });
//           throw TimeoutException("The connection has timed out!");
//         },
//       );
//       responseData = json.decode(response.body);
//       return json.decode(response.body);
//     } catch (e) {
//       // debugPrint(e);
//       return null;
//     }
//   }

//   Future<dynamic> getOrderStatus() async {
//     setState(() {
//       _loading = true;
//     });
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_order_status";
//     Map data = {
//       "user_id": widget.userId,
//       "server_token": widget.serverToken,
//       "order_id": widget.order['_id'],
//     };

//     var body = json.encode(data);
//     ;
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
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Something went wrong!"),
//               backgroundColor: kSecondaryColor,
//             ),
//           );
//           throw TimeoutException("The connection has timed out!");
//         },
//       );
//       setState(() {
//         this._loading = false;
//         orderStatus = json.decode(response.body);
//       });

//       return json.decode(response.body);
//     } catch (e) {
//       // debugPrint(e);
//       setState(() {
//         this._loading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Your internet connection is bad!"),
//           backgroundColor: kSecondaryColor,
//         ),
//       );
//       return null;
//     }
//   }

//   Future<dynamic> showInvoice() async {
//     setState(() {
//       _loading = true;
//     });
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/show_invoice";
//     Map data = {
//       "user_id": widget.userId,
//       "server_token": widget.serverToken,
//       "order_id": widget.order['_id'],
//       "is_user_show_invoice": true,
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
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Something went wrong!"),
//               backgroundColor: kSecondaryColor,
//             ),
//           );
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
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Your internet connection is bad!"),
//           backgroundColor: kSecondaryColor,
//         ),
//       );
//       return null;
//     }
//   }
// }

// class InfoContainer extends StatelessWidget {
//   const InfoContainer({
//     Key? key,
//     required this.title,
//     required this.header,
//     this.status = false,
//   }) : super(key: key);

//   final String title;
//   final String header;
//   final bool status;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//           vertical: getProportionateScreenHeight(kDefaultPadding / 3)),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: status ? kPrimaryColor : kSecondaryColor,
//         borderRadius: BorderRadius.circular(
//           getProportionateScreenWidth(kDefaultPadding / 2),
//         ),
//       ),
//       child: Column(
//         children: [
//           CategoryContainer(title: header),
//           Center(
//             child: Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: status ? kSecondaryColor : kBlackColor,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   //Placeholder implementation for _buildTimelineItem
//   Widget _buildTimelineNode({
//     required bool isCompleted,
//     required String title,
//     String? date,
//     // bool isFirst = false,
//     bool isLast = false,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Stack(
//               alignment: Alignment.topCenter,
//               children: [
//                 // Divider (positioned below the icon)
//                 if (!isLast)
//                   Container(
//                     margin: EdgeInsets.only(top: 24), // Start at bottom of icon
//                     height: 24, // Adjustable height for spacing
//                     width: 2,
//                     color: isCompleted ? kSecondaryColor : kGreyColor,
//                   ),
//                 // Circular icon
//                 Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: isCompleted ? kSecondaryColor : Colors.grey,
//                     border: Border.all(
//                       color: isCompleted ? kSecondaryColor : Colors.grey,
//                       width: 2,
//                     ),
//                   ),
//                   child: Icon(
//                     isCompleted ? Icons.check : Icons.circle,
//                     color: Colors.white,
//                     size: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: isCompleted ? Colors.black : Colors.grey,
//                 ),
//               ),
//               if (date != null)
//                 Text(
//                   date,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isCompleted ? Colors.black54 : Colors.grey,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

//////////////\\
///

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/location/components/provider_location.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/orders/components/order_history_detail.dart';
import 'package:zmall/widgets/order_status_row.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';

class OrderDetail extends StatefulWidget {
  const OrderDetail({
    super.key,
    required this.order,
    required this.userId,
    required this.serverToken,
  });

  final order;
  final String userId, serverToken;

  @override
  _OrderDetailState createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  bool _loading = false;
  var responseData;
  var orderStatus;
  late String providerId;
  String reason = "Changed my mind";

  @override
  void initState() {
    super.initState();
    orderStatus = widget.order;
    _getOrderStatus();
  }

  void _getOrderStatus() async {
    var data = await getOrderStatus();
    if (data != null && data['success']) {
      if (mounted)
        setState(() {
          orderStatus = data;
          providerId = orderStatus['provider_id'] != null
              ? orderStatus['provider_id']
              : "";
        });
    } else {
      Service.showMessage(
        context: context,
        title: "${errorCodes['${data['error_code']}']}!",
        error: true,
      );
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
    await Future.delayed(Duration(seconds: 10), () {
      if (mounted) _getOrderStatus();
    });
  }

  void _showInvoice() async {
    setState(() {
      _loading = true;
    });
    var data = await showInvoice();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        responseData = data;
      });
      Service.showMessage(
        context: context,
        title: "Order Completed!",
        error: false,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OrderHistoryDetail(
              orderId: widget.order['_id'],
              userId: widget.userId,
              serverToken: widget.serverToken,
            );
          },
        ),
      );
    } else {
      setState(() {
        _loading = false;
      });
      Service.showMessage(
        context: context,
        title: "${errorCodes['${data['error_code']}']}!",
        error: true,
      );
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  void _userCancelOrder() async {
    // debugPrint("Cancel order");
    setState(() {
      _loading = true;
    });
    var data = await userCancelOrder();
    if (data != null && data['success']) {
      Service.showMessage(
        context: context,
        title: "We're sad but you've successfully canceled your order.",
        error: false,
        duration: 5,
      );
      Navigator.of(context).pop();
    } else {
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${errorCodes['${data['error_code']}']}"),
          backgroundColor: kSecondaryColor,
        ),
      );
    }
  }

  // Add _buildTimelineNode widget
  Widget _buildTimelineNode({
    required bool isCompleted,
    required String title,
    String? date,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Container(
                    margin: EdgeInsets.only(
                      top: getProportionateScreenHeight(20),
                    ),
                    height: 24,
                    width: 2,
                    color: isCompleted ? kSecondaryColor : kGreyColor,
                  ),
                Container(
                  width: getProportionateScreenWidth(20),
                  height: getProportionateScreenHeight(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? kSecondaryColor
                        : kGreyColor.withValues(alpha: 0.6),
                    border: Border.all(
                      color: isCompleted
                          ? kSecondaryColor
                          : kGreyColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: getProportionateScreenHeight(kDefaultPadding),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(width: getProportionateScreenWidth(kDefaultPadding)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: getProportionateScreenHeight(12),
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.black : Colors.grey,
                ),
              ),
              if (date != null)
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.black54 : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Order Detail", style: TextStyle(color: kBlackColor)),
          elevation: 1.0,
          bottom: TabBar(
            indicatorColor: kSecondaryColor,
            tabs: [
              Column(
                children: [
                  Tab(
                    icon: Icon(Icons.delivery_dining, color: kSecondaryColor),
                  ),
                  Text("Order Status", style: TextStyle(color: kBlackColor)),
                ],
              ),
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      HeroiconsOutline.shoppingBag,
                      color: kSecondaryColor,
                    ),
                  ),
                  Text("Cart", style: TextStyle(color: kBlackColor)),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            //////Order status Tab section/////
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ////order price section///
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: getProportionateScreenHeight(
                            kDefaultPadding,
                          ),
                          horizontal: getProportionateScreenWidth(
                            kDefaultPadding,
                          ),
                        ),
                        margin: EdgeInsets.symmetric(
                          vertical: getProportionateScreenHeight(
                            kDefaultPadding / 2,
                          ),
                          horizontal: getProportionateScreenWidth(
                            kDefaultPadding,
                          ),
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          border: Border.all(color: kWhiteColor),
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 1.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: getProportionateScreenHeight(
                            kDefaultPadding,
                          ),
                          children: [
                            Text(
                              Provider.of<ZLanguage>(
                                context,
                                listen: false,
                              ).orderDetails,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(
                                    color: kBlackColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: getProportionateScreenHeight(17),
                                  ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: OrderStatusRow(
                                    icon: HeroiconsOutline.banknotes,
                                    value:
                                        "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.order['total_order_price'].toStringAsFixed(2)}",
                                    title: Provider.of<ZLanguage>(
                                      context,
                                      listen: false,
                                    ).totalOrderPrice,
                                  ),
                                ),
                                Flexible(
                                  child: OrderStatusRow(
                                    icon: HeroiconsOutline.hashtag,
                                    value: "${widget.order['unique_id']}",
                                    title: "Order ID",
                                  ),
                                ),
                              ],
                            ),
                            OrderStatusRow(
                              icon: HeroiconsOutline.mapPin,
                              value:
                                  "${widget.order['destination_addresses'][0]['address']}",
                              title: Provider.of<ZLanguage>(
                                context,
                                listen: false,
                              ).deliveryAddress,
                            ),
                            OrderStatusRow(
                              icon: HeroiconsOutline.buildingStorefront,
                              value:
                                  "${Service.capitalizeFirstLetters(widget.order['store_name'])}",
                              title: "Store",
                            ),
                          ],
                        ),
                      ),

                      ////////delivery detail section/////
                      // Container(
                      //   padding: EdgeInsets.symmetric(
                      //       vertical:
                      //           getProportionateScreenHeight(kDefaultPadding),
                      //       horizontal:
                      //           getProportionateScreenWidth(kDefaultPadding)),
                      //   margin: EdgeInsets.symmetric(
                      //       vertical: getProportionateScreenHeight(
                      //           kDefaultPadding / 2),
                      //       horizontal:
                      //           getProportionateScreenWidth(kDefaultPadding)),
                      //   width: double.infinity,
                      //   decoration: BoxDecoration(
                      //       color: kPrimaryColor,
                      //       border: Border.all(color: kWhiteColor),
                      //       borderRadius: BorderRadius.circular(
                      //           getProportionateScreenWidth(
                      //               kDefaultPadding / 1.5))),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     spacing:
                      //         getProportionateScreenHeight(kDefaultPadding),
                      //     children: [
                      //       Text(
                      //         "Delivery Location",
                      //         style: Theme.of(context)
                      //             .textTheme
                      //             .titleLarge!
                      //             .copyWith(
                      //                 color: kBlackColor,
                      //                 fontWeight: FontWeight.bold,
                      //                 fontSize:
                      //                     getProportionateScreenHeight(17)),
                      //       ),
                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Flexible(
                      //             flex: 1,
                      //             child: Column(
                      //               crossAxisAlignment:
                      //                   CrossAxisAlignment.start,
                      //               mainAxisSize: MainAxisSize.min,
                      //               children: [
                      //                 Text(
                      //                   "${Service.capitalizeFirstLetters(widget.order['store_name'])}",
                      //                   style: TextStyle(
                      //                     color: kBlackColor,
                      //                     fontWeight: FontWeight.bold,
                      //                   ),
                      //                   softWrap: true,
                      //                   maxLines: 2,
                      //                   overflow: TextOverflow.ellipsis,
                      //                   textAlign: TextAlign.left,
                      //                 ),
                      //                 SizedBox(
                      //                     height: getProportionateScreenHeight(
                      //                         kDefaultPadding / 4)),
                      //                 Text(
                      //                   "Store",
                      //                   textAlign: TextAlign.left,
                      //                   style: Theme.of(context)
                      //                       .textTheme
                      //                       .bodySmall
                      //                       ?.copyWith(
                      //                         color: Theme.of(context)
                      //                             .colorScheme
                      //                             .onSurface
                      //                             .withValues(alpha: 0.6),
                      //                       ),
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //           SizedBox(
                      //               width: getProportionateScreenWidth(
                      //                   kDefaultPadding / 2)),
                      //           Flexible(
                      //             flex: 1,
                      //             child: Column(
                      //               crossAxisAlignment: CrossAxisAlignment.end,
                      //               mainAxisSize: MainAxisSize.min,
                      //               children: [
                      //                 Text(
                      //                   "${widget.order['destination_addresses'][0]['address']}",
                      //                   style: TextStyle(
                      //                     color: kBlackColor,
                      //                     fontWeight: FontWeight.bold,
                      //                   ),
                      //                   softWrap: true,
                      //                   maxLines: 2,
                      //                   overflow: TextOverflow.ellipsis,
                      //                   textAlign: TextAlign.right,
                      //                 ),
                      //                 SizedBox(
                      //                     height: getProportionateScreenHeight(
                      //                         kDefaultPadding / 4)),
                      //                 Text(
                      //                   "Delivery Address",
                      //                   textAlign: TextAlign.right,
                      //                   style: Theme.of(context)
                      //                       .textTheme
                      //                       .bodySmall
                      //                       ?.copyWith(
                      //                         color: Theme.of(context)
                      //                             .colorScheme
                      //                             .onSurface
                      //                             .withValues(alpha: 0.6),
                      //                       ),
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // SizedBox(
                      //     height: getProportionateScreenHeight(
                      //         kDefaultPadding / 2)),
                      orderStatus['order_status'] != 25 &&
                              orderStatus['delivery_status'] != null &&
                              orderStatus['delivery_status'] < 100
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                  kDefaultPadding,
                                ),
                                horizontal: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              margin: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 2,
                                ),
                                horizontal: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                border: Border.all(color: kWhiteColor),
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                    kDefaultPadding / 1.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order Status",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: kBlackColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              getProportionateScreenHeight(17),
                                        ),
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                      kDefaultPadding * 1.2,
                                    ),
                                  ),
                                  // Order status timeline nodes
                                  _buildTimelineNode(
                                    isCompleted:
                                        orderStatus['order_status'] >= 1,
                                    title: "${order_status['1']}",
                                    isLast: false,
                                  ),

                                  _buildTimelineNode(
                                    isCompleted:
                                        orderStatus['order_status'] >= 3,
                                    title: "${order_status['3']}",
                                    isLast: false,
                                  ),

                                  _buildTimelineNode(
                                    isCompleted:
                                        orderStatus['order_status'] >= 5,
                                    title: "${order_status['5']}",
                                    isLast: false,
                                  ),

                                  _buildTimelineNode(
                                    isCompleted:
                                        orderStatus['order_status'] >= 7,
                                    title: "${order_status['7']}",
                                    isLast:
                                        widget
                                            .order['destination_addresses'][0]['address']
                                            .toString()
                                            .toLowerCase() ==
                                        "user pickup",
                                  ),
                                  // Delivery status timeline nodes
                                  if (widget
                                          .order['destination_addresses'][0]['address']
                                          .toString()
                                          .toLowerCase() !=
                                      "user pickup")
                                    Column(
                                      children: [
                                        _buildTimelineNode(
                                          isCompleted:
                                              orderStatus['delivery_status'] >=
                                              19,
                                          title: "${order_status['19']}",
                                          isLast: false,
                                        ),
                                        _buildTimelineNode(
                                          isCompleted:
                                              orderStatus['delivery_status'] >=
                                              23,
                                          title: "${order_status['23']}",
                                          isLast: true,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            )
                          : Container(
                              padding: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                  kDefaultPadding,
                                ),
                                horizontal: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(color: kPrimaryColor),
                              child: _buildTimelineNode(
                                isCompleted: true,
                                title:
                                    "${order_status['${orderStatus['order_status']}']}",
                                isLast: true,
                              ),
                            ),
                      orderStatus['order_status'] != 25 &&
                              orderStatus['delivery_status'] != null &&
                              orderStatus['delivery_status'] > 100
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                  kDefaultPadding,
                                ),
                                horizontal: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              margin: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 2,
                                ),
                                horizontal: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                border: Border.all(color: kWhiteColor),
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                    kDefaultPadding / 1.5,
                                  ),
                                ),
                              ),
                              child: _buildTimelineNode(
                                isCompleted: true,
                                title:
                                    "${order_status['${orderStatus['delivery_status']}']}",
                                isLast: true,
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  Column(
                    children: [
                      orderStatus['order_status'] == 3
                          ? TextButton(
                              onPressed: () {
                                _showDialog();
                              },
                              child: Text(
                                "Cancel Order",
                                style: TextStyle(color: kBlackColor),
                              ),
                            )
                          : Container(),
                      orderStatus != null &&
                              orderStatus['provider_id'] != null &&
                              orderStatus['order_status'] != 25 &&
                              orderStatus['delivery_status'] != null &&
                              orderStatus['delivery_status'] >= 17 &&
                              orderStatus['delivery_status'] < 25
                          ? Padding(
                              padding: EdgeInsets.only(
                                bottom: getProportionateScreenHeight(
                                  kDefaultPadding,
                                ),
                                left: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                                right: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              child: CustomButton(
                                title: "Track My Order",
                                press: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return ProviderLocation(
                                          providerId:
                                              orderStatus['provider_id'],
                                          providerImage:
                                              orderStatus['provider_image'],
                                          providerName:
                                              orderStatus['provider_first_name'],
                                          providerPhone:
                                              orderStatus['provider_phone'],
                                          destLat:
                                              orderStatus['destination_addresses'][0]['location'][0],
                                          destLong:
                                              orderStatus['destination_addresses'][0]['location'][1],
                                          userId: widget.userId,
                                          serverToken: widget.serverToken,
                                        );
                                      },
                                    ),
                                  );
                                },
                                color: kSecondaryColor,
                              ),
                            )
                          : Container(),
                      orderStatus['order_status'] == 25
                          ? Padding(
                              padding: EdgeInsets.only(
                                bottom: getProportionateScreenHeight(
                                  kDefaultPadding,
                                ),
                                left: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                                right: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              child: _loading
                                  ? Container()
                                  : CustomButton(
                                      title: "SUBMIT",
                                      press: () {
                                        _showInvoice();
                                      },
                                      color: kBlackColor,
                                    ),
                            )
                          : Container(),
                    ],
                  ),
                ],
              ),
            ),

            //////Order cart Tab section/////
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.order['order_details'].length,
                      separatorBuilder: (context, index) => SizedBox(
                        height: getProportionateScreenWidth(
                          kDefaultPadding / 2,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        String extractProductName(String? noteForItem) {
                          if (noteForItem == null || noteForItem.isEmpty)
                            return '';
                          return noteForItem.split(': ').first;
                        }

                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(
                              kDefaultPadding,
                            ),
                            horizontal: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                          ),
                          margin: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(
                              kDefaultPadding / 2,
                            ),
                            horizontal: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(color: kWhiteColor),
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(
                                kDefaultPadding / 1.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CategoryContainer(
                                title:
                                    widget.order['order_details'][index]['product_name']
                                            .toString()
                                            .toLowerCase() ==
                                        "aliexpress"
                                    ? "${Service.capitalizeFirstLetters(extractProductName(widget.order['order_details'][index]['items'][0]['note_for_item']))}"
                                    : widget.order['order_details'][index]['product_name'] !=
                                          null
                                    ? Service.capitalizeFirstLetters(
                                        widget
                                            .order['order_details'][index]['product_name'],
                                      )
                                    : "Item",
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 4,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(color: kPrimaryColor),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(
                                      kDefaultPadding / 2,
                                    ),
                                    vertical: getProportionateScreenHeight(
                                      kDefaultPadding / 2,
                                    ),
                                  ),
                                  child: ListView.separated(
                                    physics: ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: widget
                                        .order['order_details'][index]['items']
                                        .length,
                                    separatorBuilder: (context, index) =>
                                        Divider(color: kWhiteColor),
                                    itemBuilder: (context, idx) {
                                      String extractItemName(
                                        String? noteForItem,
                                      ) {
                                        if (noteForItem == null ||
                                            noteForItem.isEmpty)
                                          return '';
                                        var parts = noteForItem.split(': ');
                                        return parts.length >= 3
                                            ? "${parts[2]}:\n${parts[1]}"
                                            : parts.length >= 2
                                            ? "${parts[1]}"
                                            : '';
                                      }

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  widget.order['order_details'][index]['product_name']
                                                              .toString()
                                                              .toLowerCase() ==
                                                          "aliexpress"
                                                      ? "${extractItemName(widget.order['order_details'][index]['items'][idx]['note_for_item'])}"
                                                      : "${Service.capitalizeFirstLetters(widget.order['order_details'][index]['items'][idx]['item_name'])}",
                                                  softWrap: true,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Text(
                                                  "Quantity: ${widget.order['order_details'][index]['items'][idx]['quantity']}",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.order['order_details'][index]['items'][idx]['total_price'].toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: getProportionateScreenHeight(
                        kDefaultPadding / 2,
                      ),
                      horizontal: getProportionateScreenWidth(
                        kDefaultPadding / 2,
                      ),
                    ),
                    margin: EdgeInsets.symmetric(
                      vertical: getProportionateScreenHeight(
                        kDefaultPadding / 2,
                      ),
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      border: Border.all(color: kWhiteColor),
                      borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding / 1.5),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.order['total_order_price'].toStringAsFixed(2)}",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "Total Price",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: kGreyColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 0.1,
                    color: kSecondaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPrimaryColor,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                kDefaultPadding, // Adjust for keyboard
          ),
          child: SafeArea(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(kDefaultPadding),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding),
                vertical: getProportionateScreenHeight(kDefaultPadding),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: getProportionateScreenHeight(kDefaultPadding / 2),
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: getProportionateScreenWidth(
                          kDefaultPadding / 2,
                        ),
                        children: [
                          Text(
                            "Cancel Order?",
                            style: TextStyle(
                              fontSize: 18,
                              color: kBlackColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            color: kBlackColor,
                            HeroiconsOutline.faceFrown,
                            size: getProportionateScreenHeight(24),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          color: kBlackColor,
                          HeroiconsOutline.xCircle,
                          size: getProportionateScreenHeight(24),
                        ),
                      ),
                    ],
                  ),
                  Text("Are you sure you want to cancel the order?"),
                  Container(
                    constraints: BoxConstraints(minHeight: 120),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kGreyColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      style: TextStyle(color: kBlackColor),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      onChanged: (val) {
                        reason = val;
                      },
                      decoration: InputDecoration.collapsed(
                        hintText: "$reason",
                        hintStyle: TextStyle(color: kGreyColor),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Row(
                          spacing: getProportionateScreenWidth(
                            kDefaultPadding / 2,
                          ),
                          children: [
                            Text(
                              "Sure",
                              style: TextStyle(
                                fontSize: 14,
                                color: kBlackColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              color: kGreyColor,
                              HeroiconsOutline.faceFrown,
                              size: getProportionateScreenHeight(24),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _userCancelOrder();
                        },
                      ),
                      TextButton(
                        child: Row(
                          spacing: getProportionateScreenWidth(
                            kDefaultPadding / 2,
                          ),
                          children: [
                            Text(
                              "Keep It",
                              style: TextStyle(
                                fontSize: 16,
                                color: kSecondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              color: kSecondaryColor,
                              HeroiconsOutline.faceSmile,
                              size: getProportionateScreenHeight(24),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> userCancelOrder() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_cancel_order";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "cancel_reason": reason,
      "order_id": widget.order['_id'],
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
            Duration(seconds: 10),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Network error",
                error: true,
              );
              setState(() {
                _loading = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );
      responseData = json.decode(response.body);
      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getOrderStatus() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_order_status";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "order_id": widget.order['_id'],
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
            Duration(seconds: 10),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Something went wrong!"),
                  backgroundColor: kSecondaryColor,
                ),
              );
              throw TimeoutException("The connection has timed out!");
            },
          );
      setState(() {
        this._loading = false;
        orderStatus = json.decode(response.body);
      });

      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your internet connection is bad!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> showInvoice() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/show_invoice";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "order_id": widget.order['_id'],
      "is_user_show_invoice": true,
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
            Duration(seconds: 10),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Something went wrong!"),
                  backgroundColor: kSecondaryColor,
                ),
              );
              throw TimeoutException("The connection has timed out!");
            },
          );
      setState(() {
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your internet connection is bad!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}

class InfoContainer extends StatelessWidget {
  const InfoContainer({
    Key? key,
    required this.title,
    required this.header,
    this.status = false,
  }) : super(key: key);

  final String title;
  final String header;
  final bool status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: getProportionateScreenHeight(kDefaultPadding / 3),
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: status ? kPrimaryColor : kSecondaryColor,
        borderRadius: BorderRadius.circular(
          getProportionateScreenWidth(kDefaultPadding / 2),
        ),
      ),
      child: Column(
        children: [
          CategoryContainer(title: header),
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: status ? kSecondaryColor : kBlackColor),
            ),
          ),
        ],
      ),
    );
  }
}
