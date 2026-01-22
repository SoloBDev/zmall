// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/core_services.dart';
// import 'package:zmall/custom_widgets/custom_button.dart';
// import 'package:zmall/models/cart.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/notifications/notification_store.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';
// import 'package:zmall/store/components/image_container.dart';
// import 'package:zmall/widgets/custom_progress_indicator.dart';
//
// class DineInCartScreen extends StatefulWidget {
//   const DineInCartScreen({Key? key, this.lat, this.long, this.store})
//       : super(key: key);
//   final lat, long;
//   final store;
//
//   @override
//   _DineInCartScreenState createState() => _DineInCartScreenState();
// }
//
// class _DineInCartScreenState extends State<DineInCartScreen> {
//   late Cart cart;
//   double price = 0;
//   var appClose;
//   var appOpen;
//   bool _loading = false;
//   bool isOpen = false;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     getCart();
//     getAppKeys();
//     storeOpen(widget.store);
//   }
//
//   void calculatePrice() {
//     double tempPrice = 0;
//     cart.items!.forEach((item) {
//       tempPrice += item!.price!;
//     });
//     setState(() {
//       price = tempPrice;
//     });
//     debugPrint(cart.toJson());
//   }
//
//   void storeOpen(store) async {
//     DateFormat dateFormat = new DateFormat.Hm();
//     DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
//     if (appOpen == null || appClose == null) {
//       debugPrint("Couldn't find app open-close time...fetching is locally");
//       appOpen = await Service.read('app_open');
//       appClose = await Service.read('app_close');
//     }
//
//     DateTime zmallOpen = dateFormat.parse(appOpen);
//     DateTime zmallClose = dateFormat.parse(appClose);
//
//     zmallOpen = new DateTime(
//         now.year, now.month, now.day, zmallOpen.hour, zmallOpen.minute);
//     zmallClose = new DateTime(
//         now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
//
//     bool isStoreOpen = false;
//     if (store['store_time'] != null && store['store_time'].length != 0) {
//       for (var i = 0; i < store['store_time'].length; i++) {
//         int weekday;
//         if (now.weekday == 7) {
//           weekday = 0;
//         } else {
//           weekday = now.weekday;
//         }
//
//         if (store['store_time'][i]['day'] == weekday) {
//           if (store['store_time'][i]['day_time'].length != 0 &&
//               store['store_time'][i]['is_store_open']) {
//             for (var j = 0;
//                 j < store['store_time'][i]['day_time'].length;
//                 j++) {
//               DateTime open = dateFormat.parse(
//                   store['store_time'][i]['day_time'][j]['store_open_time']);
//               open = new DateTime(
//                   now.year, now.month, now.day, open.hour, open.minute);
//               DateTime close = dateFormat.parse(
//                   store['store_time'][i]['day_time'][j]['store_close_time']);
//               close = new DateTime(
//                   now.year, now.month, now.day, close.hour, close.minute);
//               now =
//                   DateTime(now.year, now.month, now.day, now.hour, now.minute);
//
//               if (now.isAfter(open) &&
//                   now.isAfter(zmallOpen) &&
//                   now.isBefore(close) &&
//                   store['store_time'][i]['is_store_open'] &&
//                   now.isBefore(zmallClose)) {
//                 isStoreOpen = true;
//                 break;
//               } else {
//                 isStoreOpen = false;
//               }
//             }
//           } else {
//             if (now.isAfter(zmallOpen) &&
//                 now.isBefore(zmallClose) &&
//                 store['store_time'][i]['is_store_open']) {
//               isStoreOpen = true;
//             } else {
//               isStoreOpen = false;
//             }
//           }
//         }
//       }
//     } else {
//       DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
//       DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
//       DateFormat dateFormat = DateFormat.Hm();
//       if (appClose != null) {
//         zmallClose = dateFormat.parse(appClose);
//       }
//
//       zmallClose = DateTime(
//           now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
//       now = DateTime(now.year, now.month, now.day, now.hour, now.minute);
//
//       now.isAfter(zmallClose) ? isStoreOpen = false : isStoreOpen = true;
//     }
//     setState(() {
//       isOpen = isStoreOpen;
//     });
//     debugPrint("Is open $isOpen");
//   }
//
//   void getCart() async {
//     try {
//       var userData = await Service.read('user');
//       var data = await Service.read('cart');
//       if (data != null) {
//         setState(() {
//           cart = Cart.fromJson(data);
//           cart.serverToken = userData['user']['server_token'];
//           Service.save('cart', cart);
//         });
//         calculatePrice();
//         debugPrint(cart.isDineIn);
//       }
//     } catch (e) {
//       debugPrint(e);
//     }
//     setState(() {
//       _loading = false;
//     });
//   }
//
//   void getAppKeys() async {
//     var appKeys = await CoreServices.appKeys(context);
//     if (appKeys != null && appKeys['success']) {
//       setState(() {
//         appClose = appKeys['app_close'];
//         appOpen = appKeys['app_open'];
//         Service.save("app_close", appClose);
//         Service.save("app_open", appOpen);
//       });
//     } else {
//       appClose = await Service.read('app_close');
//       appOpen = await Service.read('app_open');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Cart",
//           style: TextStyle(color: kBlackColor),
//         ),
//         elevation: 1.0,
//       ),
//       body: ModalProgressHUD(
//         color: kPrimaryColor,
//         progressIndicator: CustomLinearProgressIndicator(
//           message: "Loading Cart...",
//         ),
//         inAsyncCall: _loading,
//         child: cart != null && cart.items!.length > 0
//             ? Column(
//                 children: [
//                   // SizedBox(
//                   //     height: getProportionateScreenHeight(kDefaultPadding / 2)),
//                   Expanded(
//                     child: ListView.separated(
//                       shrinkWrap: true,
//                       itemCount: cart.toJson()['items'].length,
//                       itemBuilder: (context, index) {
//                         return Padding(
//                           padding: EdgeInsets.symmetric(
//                               // horizontal:
//                               //     getProportionateScreenWidth(kDefaultPadding / 2),
//                               ),
//                           child: Container(
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: kPrimaryColor,
//                               // borderRadius:
//                               //     BorderRadius.circular(kDefaultPadding),
//                             ),
//                             padding: EdgeInsets.symmetric(
//                               vertical: getProportionateScreenHeight(
//                                   kDefaultPadding / 2),
//                               horizontal: getProportionateScreenWidth(
//                                   kDefaultPadding / 2),
//                             ),
//                             child: Row(
//                               children: [
//                                 ImageContainer(
//                                     url: cart.items![index].imageURL!),
//                                 SizedBox(
//                                     width: getProportionateScreenWidth(
//                                         kDefaultPadding / 4)),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         cart.items![index].itemName!,
//                                         style: TextStyle(
//                                           fontSize: getProportionateScreenWidth(
//                                               kDefaultPadding),
//                                           fontWeight: FontWeight.bold,
//                                           color: kBlackColor,
//                                         ),
//                                         softWrap: true,
//                                       ),
//                                       SizedBox(
//                                           height: getProportionateScreenHeight(
//                                               kDefaultPadding / 5)),
//                                       Text(
//                                         "${Provider.of<ZMetaData>(context, listen: false).currency} ${cart.items![index].price!.toStringAsFixed(2)}",
//                                         style: Theme.of(context)
//                                             .textTheme
//                                             .subtitle1
//                                             ?.copyWith(
//                                               color: kGreyColor,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                       ),
//                                       SizedBox(
//                                         height: getProportionateScreenHeight(
//                                             kDefaultPadding / 5),
//                                       ),
//                                       Text(cart.items![index].noteForItem),
//                                     ],
//                                   ),
//                                 ),
//                                 Column(
//                                   children: [
//                                     Row(
//                                       children: [
//                                         IconButton(
//                                             icon: Icon(
//                                               Icons.remove_circle_outline,
//                                               color:
//                                                   cart.items![index].quantity !=
//                                                           1
//                                                       ? kSecondaryColor
//                                                       : kGreyColor,
//                                             ),
//                                             onPressed: cart.items![index]
//                                                         .quantity ==
//                                                     1
//                                                 ? () {
//                                                     ScaffoldMessenger.of(
//                                                             context)
//                                                         .showSnackBar(
//                                                             Service.showMessage(
//                                                                 "Minimum order quantity is 1!",
//                                                                 true));
//                                                   }
//                                                 : () {
//                                                     int? currQty = cart
//                                                         .items![index].quantity;
//                                                     double? unitPrice = cart
//                                                             .items![index]
//                                                             .price! /
//                                                         currQty!;
//                                                     setState(() {
//                                                       cart.items![index]
//                                                               .quantity =
//                                                           currQty - 1;
//                                                       cart.items![index].price =
//                                                           unitPrice *
//                                                               (currQty - 1);
//                                                       Service.save(
//                                                           'cart', cart);
//                                                     });
//                                                     calculatePrice();
//                                                   }),
//                                         Text(
//                                           "${cart.items![index].quantity}",
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .subtitle1
//                                               ?.copyWith(
//                                                 color: kBlackColor,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                         ),
//                                         IconButton(
//                                             icon: Icon(
//                                               Icons.add_circle,
//                                               color: kSecondaryColor,
//                                             ),
//                                             onPressed: () {
//                                               int? currQty =
//                                                   cart.items![index].quantity;
//                                               double? unitPrice =
//                                                   cart.items![index].price! /
//                                                       currQty!;
//                                               setState(() {
//                                                 cart.items![index].quantity =
//                                                     currQty + 1;
//                                                 cart.items![index].price =
//                                                     unitPrice * (currQty + 1);
//                                                 Service.save('cart', cart);
//                                               });
//                                               calculatePrice();
//                                             }),
//                                       ],
//                                     ),
//                                     GestureDetector(
//                                       onTap: () {
//                                         setState(() {
//                                           cart.items!.removeAt(index);
//                                           Service.save('cart', cart);
//                                         });
//                                         calculatePrice();
//                                       },
//                                       child: Text(
//                                         "Remove",
//                                         style: Theme.of(context)
//                                             .textTheme
//                                             .bodyText1
//                                             ?.copyWith(color: kSecondaryColor),
//                                       ),
//                                     )
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                       separatorBuilder: (BuildContext context, int index) =>
//                           SizedBox(
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding / 4),
//                       ),
//                     ),
//                   ),
//
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                         horizontal:
//                             getProportionateScreenWidth(kDefaultPadding)),
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(
//                           vertical: getProportionateScreenHeight(
//                               kDefaultPadding / 3)),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Cart Total: ",
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .bodyText1
//                                 ?.copyWith(color: kBlackColor),
//                           ),
//                           Text(
//                             "${Provider.of<ZMetaData>(context, listen: false).currency} ${price.toStringAsFixed(2)}",
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headline6
//                                 ?.copyWith(
//                                     color: kBlackColor,
//                                     fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     height: getProportionateScreenHeight(kDefaultPadding / 4),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal:
//                           getProportionateScreenWidth(kDefaultPadding * 2),
//                       vertical: getProportionateScreenHeight(kDefaultPadding),
//                     ),
//                     child: CustomButton(
//                       title: "Checkout",
//                       press: () async {
//                         debugPrint(cart.isDineIn);
//                         DateFormat dateFormat = new DateFormat.Hm();
//                         DateTime now =
//                             DateTime.now().toUtc().add(Duration(hours: 3));
//                         var appClose = await Service.read('app_close');
//                         var appOpen = await Service.read('app_open');
//                         debugPrint(appClose);
//                         debugPrint(appOpen);
//                         DateTime zmallClose = dateFormat.parse(appClose);
//                         DateTime zmallOpen = dateFormat.parse(appOpen);
//
//                         now = DateTime(
//                             now.year, now.month, now.day, now.hour, now.minute);
//                         zmallOpen = new DateTime(now.year, now.month, now.day,
//                             zmallOpen.hour, zmallOpen.minute);
//                         zmallClose = new DateTime(now.year, now.month, now.day,
//                             zmallClose.hour, zmallClose.minute);
//                         debugPrint(now.isAfter(zmallOpen));
//                         debugPrint(now);
//                         debugPrint(now.isBefore(zmallClose));
//                         if (now.isAfter(zmallOpen) &&
//                             now.isBefore(zmallClose) &&
//                             isOpen) {
//                           debugPrint("Ready to route...");
//                           // Navigator.of(context)
//                           //     .push(MaterialPageRoute(builder: (context) {
//                           //   return DeliveryScreen();
//                           // }));
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             Service.showMessage(
//                                 "Sorry, we are currently closed. Please comeback soon.",
//                                 false,
//                                 duration: 3),
//                           );
//                         }
//                         // Navigator.pushNamed(context, DeliveryScreen.routeName);
//                       },
//                       color: kSecondaryColor,
//                     ),
//                   ),
//                 ],
//               )
//             : Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.add_shopping_cart_outlined,
//                       size: getProportionateScreenHeight(kDefaultPadding * 3),
//                       color: kSecondaryColor,
//                     ),
//                     SizedBox(
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding / 3)),
//                     Text(
//                       "Empty Basket!",
//                       style: Theme.of(context).textTheme.headline6,
//                     )
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }
