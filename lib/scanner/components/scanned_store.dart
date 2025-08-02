// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/cart/cart_screen.dart';
// import 'package:zmall/dine_in/dine_in_cart_screen.dart';
// import 'package:zmall/item/item_screen.dart';
// import 'package:zmall/login/login_screen.dart';
// import 'package:zmall/models/cart.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';
// import 'package:zmall/store/components/image_container.dart';
// import 'package:zmall/widgets/custom_tag.dart';
//
// import '../../constants.dart';
//
// class ScannedStore extends StatefulWidget {
//   const ScannedStore({Key? key, @required this.storeId, this.tableNumber})
//       : super(key: key);
//
//   final String? storeId;
//   final String? tableNumber;
//
//   @override
//   _ScannedStoreState createState() => _ScannedStoreState();
// }
//
// class _ScannedStoreState extends State<ScannedStore> {
//   bool _loading = true;
//   var products;
//   var responseData;
//   late Cart cart;
//   bool isLoggedIn = false;
//   var userData;
//   late double longitude, latitude;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     getUser();
//     getCart();
//     _getStoreProductList();
//   }
//
//   void getCart() async {
//     debugPrint("Fetching data");
//     var data = await Service.read('cart');
//     if (data != null) {
//       setState(() {
//         cart = Cart.fromJson(data);
//       });
//     }
//     getUser();
//   }
//
//   void isLogged() async {
//     var data = await Service.readBool('logged');
//     if (data != null) {
//       setState(() {
//         isLoggedIn = data;
//       });
//       getUser();
//     } else {
//       debugPrint("No logged user found");
//     }
//   }
//
//   void getUser() async {
//     var data = await Service.read('user');
//     if (data != null) {
//       debugPrint("Found user data...");
//       setState(() {
//         userData = data;
//       });
//     }
//     var long = await Service.read('longitude');
//     var lat = await Service.read('latitude');
//     if (long != null && lat != null) {
//       setState(() {
//         latitude = lat;
//         longitude = long;
//       });
//     }
//   }
//
//   void addToCart(item, destination, storeLocation, storeId) {
//     debugPrint("Adding to cart......");
//
//     cart = Cart(
//       userId: userData['user']['_id'],
//       items: [item],
//       serverToken: userData['user']['server_token'],
//       destinationAddress: destination,
//       storeId: storeId,
//       storeLocation: storeLocation,
//       isDineIn: true,
//       tableNumber: widget.tableNumber!,
//     );
//     setState(() {
//       cart.isDineIn = true;
//       cart.tableNumber = widget.tableNumber!;
//     });
//
//     Service.save('cart', cart.toJson());
//     ScaffoldMessenger.of(context)
//         .showSnackBar(Service.showMessage("Item added to cart!", false));
//   }
//
//   // ignore: missing_return
//   String _getPrice(item) {
//     if (item['price'] == null || item['price'] == 0) {
//       for (var i = 0; i < item['specifications'].length; i++) {
//         for (var j = 0; j < item['specifications'][i]['list'].length; j++) {
//           if (item['specifications'][i]['list'][j]['is_default_selected']) {
//             return item['specifications'][i]['list'][j]['price']
//                 .toStringAsFixed(2);
//           }
//         }
//       }
//     } else {
//       return item['price'].toStringAsFixed(2);
//     }
//     return "0";
//   }
//
//   void _getStoreProductList() async {
//     setState(() {
//       _loading = true;
//     });
//     var data = await getStoreProductList();
//
//     if (data != null && data['success']) {
//       responseData = data;
//       products = data['products'];
//       debugPrint(products);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("${errorCodes['${data['error_code']}']}"),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 1.0,
//         title: Text(
//           "Dine-in",
//           style: TextStyle(color: kBlackColor),
//         ),
//         actions: [
//           InkWell(
//             onTap: () {
//               debugPrint(cart.isDineIn);
//               if (cart.isDineIn) {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) {
//                       return DineInCartScreen(
//                         lat: responseData['store']['location'][0],
//                         long: responseData['store']['location'][1],
//                         store: responseData['store'],
//                       );
//                     },
//                   ),
//                 ).then((value) => getCart());
//               }
//             },
//             borderRadius: BorderRadius.circular(
//               getProportionateScreenWidth(kDefaultPadding * 2.5),
//             ),
//             child: Stack(
//               children: [
//                 Padding(
//                   padding: EdgeInsets.only(
//                     left: getProportionateScreenWidth(kDefaultPadding * .75),
//                     right: getProportionateScreenWidth(kDefaultPadding * .75),
//                     top: getProportionateScreenWidth(kDefaultPadding * .75),
//                     bottom: getProportionateScreenWidth(kDefaultPadding * .75),
//                   ),
//                   child: Icon(Icons.add_shopping_cart_rounded),
//                 ),
//                 Positioned(
//                   left: 0,
//                   top: 5,
//                   child: Container(
//                     height: getProportionateScreenWidth(kDefaultPadding * .9),
//                     width: getProportionateScreenWidth(kDefaultPadding * .9),
//                     decoration: BoxDecoration(
//                       color: kSecondaryColor,
//                       shape: BoxShape.circle,
//                       border: Border.all(width: 1.5, color: kWhiteColor),
//                     ),
//                     child: Center(
//                       child: Text(
//                         cart != null ? "${cart.items!.length}" : "0",
//                         style: TextStyle(
//                           fontSize:
//                               getProportionateScreenWidth(kDefaultPadding / 2),
//                           height: 1,
//                           color: kPrimaryColor,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: products != null
//           ? Column(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: kPrimaryColor,
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       vertical:
//                           getProportionateScreenHeight(kDefaultPadding / 2),
//                       horizontal: getProportionateScreenWidth(kDefaultPadding),
//                     ),
//                     child: Row(
//                       children: [
//                         CachedNetworkImage(
//                           imageUrl:
//                               "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['store']['image_url']}",
//                           imageBuilder: (context, imageProvider) => Container(
//                             width: getProportionateScreenWidth(
//                                 kDefaultPadding * 8),
//                             height: getProportionateScreenHeight(
//                                 kDefaultPadding * 8),
//                             decoration: BoxDecoration(
//                               shape: BoxShape.rectangle,
//                               borderRadius: BorderRadius.circular(
//                                 getProportionateScreenWidth(
//                                   kDefaultPadding / 3,
//                                 ),
//                               ),
//                               color: kPrimaryColor,
//                               image: DecorationImage(
//                                 fit: BoxFit.contain,
//                                 image: imageProvider,
//                               ),
//                             ),
//                           ),
//                           placeholder: (context, url) => Center(
//                             child: Container(
//                               width: getProportionateScreenWidth(
//                                   kDefaultPadding * 8),
//                               height: getProportionateScreenHeight(
//                                   kDefaultPadding * 8),
//                               child: CircularProgressIndicator(
//                                 valueColor:
//                                     AlwaysStoppedAnimation<Color>(kWhiteColor),
//                               ),
//                             ),
//                           ),
//                           errorWidget: (context, url, error) => Container(
//                             width: getProportionateScreenWidth(
//                                 kDefaultPadding * 8),
//                             height: getProportionateScreenHeight(
//                                 kDefaultPadding * 8),
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: kWhiteColor,
//                               image: DecorationImage(
//                                 fit: BoxFit.cover,
//                                 image: AssetImage(zmallLogo),
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(
//                           width:
//                               getProportionateScreenWidth(kDefaultPadding / 2),
//                         ),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 responseData['store']['name'],
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .subtitle1
//                                     ?.copyWith(fontWeight: FontWeight.w600),
//                               ),
//                               SizedBox(
//                                 height: getProportionateScreenHeight(
//                                     kDefaultPadding / 2),
//                               ),
//                               GestureDetector(
//                                 onTap: () {
//                                   Service.launchInWebViewOrVC(
//                                       responseData['store']['website_url']);
//                                 },
//                                 child: CustomTag(
//                                   text: "Check Website",
//                                   color: kBlackColor,
//                                 ),
//                               )
//                             ],
//                           ),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 1),
//                 Container(
//                   child: Expanded(
//                     child: ListView.separated(
//                       shrinkWrap: true,
//                       itemCount: products.length,
//                       itemBuilder: (BuildContext context, int index) {
//                         return ExpansionTile(
//                           textColor: kBlackColor,
//                           collapsedBackgroundColor: kPrimaryColor,
//                           backgroundColor: kPrimaryColor,
//                           leading: const Icon(
//                             Icons.dining,
//                             size: kDefaultPadding,
//                             color: kBlackColor,
//                           ),
//                           childrenPadding: EdgeInsets.only(
//                             left: getProportionateScreenWidth(
//                                 kDefaultPadding / 2),
//                             right: getProportionateScreenWidth(
//                                 kDefaultPadding / 2),
//                             bottom: getProportionateScreenWidth(
//                                 kDefaultPadding / 2),
//                           ),
//                           title: Text(
//                             "${products[index]["_id"]["name"]}",
//                             style:
//                                 Theme.of(context).textTheme.headline6?.copyWith(
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                           ),
//                           children: [
//                             ListView.separated(
//                               physics: ClampingScrollPhysics(),
//                               shrinkWrap: true,
//                               itemCount: products[index]['items'].length,
//                               itemBuilder: (BuildContext context, int idx) {
//                                 return GestureDetector(
//                                   onTap: () async {
//                                     // if (isLoggedIn) {
//                                     //   productClicked(products[index]
//                                     //   ['items'][idx]['_id']);
//                                     // }
//
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) {
//                                           return ItemScreen(
//                                             item: products[index]['items'][idx],
//                                             location: responseData['store']
//                                                 ['location'],
//                                             isDineIn: true,
//                                             tableNumber: widget.tableNumber,
//                                           );
//                                         },
//                                       ),
//                                     ).then((value) => getCart());
//                                   },
//                                   child: Column(
//                                     children: [
//                                       Container(
//                                         width: double.infinity,
//                                         decoration: BoxDecoration(
//                                           color: kPrimaryColor,
//                                           borderRadius: BorderRadius.circular(
//                                               kDefaultPadding),
//                                         ),
//                                         padding: EdgeInsets.symmetric(
//                                           vertical:
//                                               getProportionateScreenHeight(
//                                                   kDefaultPadding / 10),
//                                           // horizontal:
//                                           //     getProportionateScreenWidth(
//                                           //         kDefaultPadding / 4),
//                                         ),
//                                         child: Row(
//                                           children: [
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Text(
//                                                     products[index]['items']
//                                                         [idx]['name'],
//                                                     style: TextStyle(
//                                                       fontSize:
//                                                           getProportionateScreenWidth(
//                                                               kDefaultPadding *
//                                                                   .9),
//                                                       color: kBlackColor,
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                     ),
//                                                     softWrap: true,
//                                                   ),
//                                                   SizedBox(
//                                                       height:
//                                                           getProportionateScreenHeight(
//                                                               kDefaultPadding /
//                                                                   5)),
//                                                   products[index]['items'][idx]
//                                                                   ['details'] !=
//                                                               null &&
//                                                           products[index]['items']
//                                                                           [idx][
//                                                                       'details']
//                                                                   .length >
//                                                               0
//                                                       ? Text(
//                                                           products[index]
//                                                                   ['items'][idx]
//                                                               ['details'],
//                                                           style:
//                                                               Theme.of(context)
//                                                                   .textTheme
//                                                                   .caption
//                                                                   ?.copyWith(
//                                                                     color:
//                                                                         kGreyColor,
//                                                                   ),
//                                                         )
//                                                       : SizedBox(height: 0.5),
//                                                   Text(
//                                                     "${_getPrice(products[index]['items'][idx]) != null ? _getPrice(products[index]['items'][idx]) : 0} ${Provider.of<ZMetaData>(context, listen: false).currency}",
//                                                     style: Theme.of(context)
//                                                         .textTheme
//                                                         .button
//                                                         ?.copyWith(
//                                                           color: kBlackColor,
//                                                         ),
//                                                   ),
//                                                   SizedBox(
//                                                       height:
//                                                           getProportionateScreenHeight(
//                                                               kDefaultPadding /
//                                                                   5)),
//                                                   GestureDetector(
//                                                     onTap: () async {
//                                                       if (products[index]['items']
//                                                                       [idx][
//                                                                   'specifications']
//                                                               .length >
//                                                           0) {
//                                                         // if (isLoggedIn) {
//                                                         //   productClicked(products[
//                                                         //   index]
//                                                         //   ['items']
//                                                         //   [idx]['_id']);
//                                                         // }
//
//                                                         Navigator.push(
//                                                           context,
//                                                           MaterialPageRoute(
//                                                             builder: (context) {
//                                                               return ItemScreen(
//                                                                 item: products[
//                                                                         index][
//                                                                     'items'][idx],
//                                                                 location: responseData[
//                                                                         'store']
//                                                                     [
//                                                                     'location'],
//                                                                 tableNumber: widget
//                                                                     .storeId!
//                                                                     .split(
//                                                                         '=')[1]
//                                                                     .split(
//                                                                         '_')[1],
//                                                               );
//                                                             },
//                                                           ),
//                                                         );
//                                                       } else {
//                                                         // TODO: Add to cart.....
//
//                                                         Item item = Item(
//                                                           id: products[index]
//                                                                   ['items'][idx]
//                                                               ['_id'],
//                                                           quantity: 1,
//                                                           specification: [],
//                                                           noteForItem: "",
//                                                           price: _getPrice(products[
//                                                                               index]
//                                                                           [
//                                                                           'items']
//                                                                       [idx]) !=
//                                                                   null
//                                                               ? double.parse(
//                                                                   _getPrice(products[
//                                                                           index]
//                                                                       [
//                                                                       'items'][idx]),
//                                                                 )
//                                                               : 0,
//                                                           itemName:
//                                                               products[index]
//                                                                       ['items']
//                                                                   [idx]['name'],
//                                                           imageURL: products[index]['items']
//                                                                               [
//                                                                               idx]
//                                                                           [
//                                                                           'image_url']
//                                                                       .length >
//                                                                   0
//                                                               ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${products[index]['items'][idx]['image_url'][0]}"
//                                                               : "https://ibb.co/vkhzjd6",
//                                                         );
//                                                         StoreLocation
//                                                             storeLocation =
//                                                             StoreLocation(
//                                                                 long: responseData[
//                                                                             'store']
//                                                                         [
//                                                                         'location']
//                                                                     [1],
//                                                                 lat: responseData[
//                                                                         'store']
//                                                                     [
//                                                                     'location'][0]);
//                                                         DestinationAddress
//                                                             destination =
//                                                             DestinationAddress(
//                                                           long: responseData[
//                                                                   'store']
//                                                               ['location'][1],
//                                                           lat: responseData[
//                                                                   'store']
//                                                               ['location'][0],
//                                                           name:
//                                                               "Current Location",
//                                                           note:
//                                                               "User current location",
//                                                         );
//
//                                                         if (cart != null) {
//                                                           if (userData !=
//                                                               null) {
//                                                             if (cart.storeId ==
//                                                                 products[index][
//                                                                             'items']
//                                                                         [idx][
//                                                                     'store_id']) {
//                                                               setState(() {
//                                                                 cart.items!
//                                                                     .add(item);
//                                                                 Service.save(
//                                                                     'cart',
//                                                                     cart);
//                                                                 ScaffoldMessenger.of(
//                                                                         context)
//                                                                     .showSnackBar(
//                                                                   Service.showMessage(
//                                                                       "Item added to cart",
//                                                                       false),
//                                                                 );
//                                                                 debugPrint(cart
//                                                                     .toJson());
//                                                                 getCart();
//                                                                 // Navigator.of(
//                                                                 //         context)
//                                                                 //     .pop();
//                                                               });
//                                                             } else {
//                                                               _showDialog(
//                                                                   item,
//                                                                   destination,
//                                                                   storeLocation,
//                                                                   products[index]
//                                                                               [
//                                                                               'items']
//                                                                           [idx][
//                                                                       'store_id']);
//                                                             }
//                                                           } else {
//                                                             debugPrint(
//                                                                 "User not logged in...");
//                                                             ScaffoldMessenger
//                                                                     .of(context)
//                                                                 .showSnackBar(Service
//                                                                     .showMessage(
//                                                                         "Please login in...",
//                                                                         true));
//                                                             Navigator.push(
//                                                               context,
//                                                               MaterialPageRoute(
//                                                                 builder:
//                                                                     (context) =>
//                                                                         LoginScreen(
//                                                                   firstRoute:
//                                                                       false,
//                                                                 ),
//                                                               ),
//                                                             ).then((value) =>
//                                                                 getUser());
//                                                           }
//                                                         } else {
//                                                           if (userData !=
//                                                               null) {
//                                                             debugPrint(
//                                                                 "Empty cart! Adding new item.");
//                                                             addToCart(
//                                                                 item,
//                                                                 destination,
//                                                                 storeLocation,
//                                                                 products[index][
//                                                                             'items']
//                                                                         [idx][
//                                                                     'store_id']);
//                                                             getCart();
//                                                             // Navigator.of(
//                                                             //         context)
//                                                             //     .pop();
//                                                           } else {
//                                                             debugPrint(
//                                                                 "User not logged in...");
//                                                             ScaffoldMessenger
//                                                                     .of(context)
//                                                                 .showSnackBar(Service
//                                                                     .showMessage(
//                                                                         "Please login in...",
//                                                                         true));
//                                                             Navigator.push(
//                                                               context,
//                                                               MaterialPageRoute(
//                                                                 builder:
//                                                                     (context) =>
//                                                                         LoginScreen(
//                                                                   firstRoute:
//                                                                       false,
//                                                                 ),
//                                                               ),
//                                                             ).then((value) =>
//                                                                 getUser());
//                                                           }
//                                                         }
//                                                       }
//                                                     },
//                                                     child: Container(
//                                                       decoration: BoxDecoration(
//                                                         color: kBlackColor,
//                                                         // borderRadius:
//                                                         //     BorderRadius
//                                                         //         .circular(
//                                                         //   getProportionateScreenWidth(
//                                                         //       kDefaultPadding /
//                                                         //           10),
//                                                         // ),
//                                                       ),
//                                                       child: Padding(
//                                                         padding: EdgeInsets.all(
//                                                           getProportionateScreenWidth(
//                                                               kDefaultPadding /
//                                                                   4),
//                                                         ),
//                                                         child: Text(
//                                                           "Quick Add >",
//                                                           style:
//                                                               Theme.of(context)
//                                                                   .textTheme
//                                                                   .caption
//                                                                   ?.copyWith(
//                                                                     color:
//                                                                         kPrimaryColor,
//                                                                   ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             products[index]['items'][idx]
//                                                             ['image_url']
//                                                         .length >
//                                                     0
//                                                 ? ImageContainer(
//                                                     url:
//                                                         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${products[index]['items'][idx]['image_url'][0]}",
//                                                   )
//                                                 : Container(),
//                                             // : ImageContainer(
//                                             //     url:
//                                             //         "https://ibb.co/vkhzjd6"),
//                                             SizedBox(
//                                                 width:
//                                                     getProportionateScreenWidth(
//                                                         kDefaultPadding / 4)),
//                                           ],
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         height: getProportionateScreenHeight(
//                                             kDefaultPadding * 0.8),
//                                       ),
//                                       Container(
//                                         height: 0.1,
//                                         width: double.infinity,
//                                         color: kGreyColor.withValues(alpha: 0.5),
//                                       )
//                                     ],
//                                   ),
//                                 );
//                               },
//                               separatorBuilder:
//                                   (BuildContext context, int index) => SizedBox(
//                                 height: getProportionateScreenHeight(
//                                     kDefaultPadding / 4),
//                               ),
//                             )
//                           ],
//                         );
//                         //   Padding(
//                         //   padding: EdgeInsets.symmetric(
//                         //     horizontal: getProportionateScreenWidth(
//                         //         kDefaultPadding / 3),
//                         //     vertical: getProportionateScreenHeight(
//                         //         kDefaultPadding / 4),
//                         //   ),
//                         //   child: Column(
//                         //     children: [
//                         //       CategoryContainer(
//                         //         title: "${products[index]["_id"]["name"]}",
//                         //       ),
//                         //       SizedBox(
//                         //         height: getProportionateScreenHeight(
//                         //             kDefaultPadding / 4),
//                         //       ),
//                         //       ListView.separated(
//                         //         physics: ClampingScrollPhysics(),
//                         //         shrinkWrap: true,
//                         //         itemCount: products[index]['items'].length,
//                         //         itemBuilder:
//                         //             (BuildContext context, int idx) {
//                         //           return TextButton(
//                         //             onPressed: () async {
//                         //               if (isLoggedIn) {
//                         //                 productClicked(products[index]
//                         //                     ['items'][idx]['_id']);
//                         //               }
//                         //
//                         //               widget.isOpen
//                         //                   ? Navigator.push(
//                         //                       context,
//                         //                       MaterialPageRoute(
//                         //                         builder: (context) {
//                         //                           return ItemScreen(
//                         //                             item: products[index]
//                         //                                 ['items'][idx],
//                         //                             location:
//                         //                                 widget.location,
//                         //                           );
//                         //                         },
//                         //                       ),
//                         //                     ).then((value) => getCart())
//                         //                   : ScaffoldMessenger.of(context)
//                         //                       .showSnackBar(Service.showMessage(
//                         //                           "Sorry the store is closed at this time!",
//                         //                           true));
//                         //             },
//                         //             child: Container(
//                         //               width: double.infinity,
//                         //               decoration: BoxDecoration(
//                         //                 color: kPrimaryColor,
//                         //                 borderRadius: BorderRadius.circular(
//                         //                     kDefaultPadding),
//                         //               ),
//                         //               padding: EdgeInsets.symmetric(
//                         //                 vertical:
//                         //                     getProportionateScreenHeight(
//                         //                         kDefaultPadding / 10),
//                         //                 horizontal:
//                         //                     getProportionateScreenWidth(
//                         //                         kDefaultPadding / 3),
//                         //               ),
//                         //               child: Row(
//                         //                 children: [
//                         //                   products[index]['items'][idx]
//                         //                                   ['image_url']
//                         //                               .length >
//                         //                           0
//                         //                       ? ImageContainer(
//                         //                           url:
//                         //                               "https://app.zmallapp.com/${products[index]['items'][idx]['image_url'][0]}",
//                         //                         )
//                         //                       : ImageContainer(
//                         //                           url:
//                         //                               "https://ibb.co/vkhzjd6"),
//                         //                   SizedBox(
//                         //                       width:
//                         //                           getProportionateScreenWidth(
//                         //                               kDefaultPadding / 4)),
//                         //                   Expanded(
//                         //                     child: Column(
//                         //                       crossAxisAlignment:
//                         //                           CrossAxisAlignment.start,
//                         //                       children: [
//                         //                         Text(
//                         //                           products[index]['items']
//                         //                               [idx]['name'],
//                         //                           style: Theme.of(context)
//                         //                               .textTheme
//                         //                               .subtitle1
//                         //                               ?.copyWith(
//                         //                                 fontWeight:
//                         //                                     FontWeight.bold,
//                         //                               ),
//                         //                           softWrap: true,
//                         //                         ),
//                         //                         SizedBox(
//                         //                             height:
//                         //                                 getProportionateScreenHeight(
//                         //                                     kDefaultPadding /
//                         //                                         5)),
//                         //                         products[index]['items']
//                         //                                             [idx][
//                         //                                         'details'] !=
//                         //                                     null &&
//                         //                                 products[index]['items']
//                         //                                                 [
//                         //                                                 idx]
//                         //                                             [
//                         //                                             'details']
//                         //                                         .length >
//                         //                                     0
//                         //                             ? Text(
//                         //                                 products[index]
//                         //                                         ['items'][
//                         //                                     idx]['details'],
//                         //                                 style: Theme.of(
//                         //                                         context)
//                         //                                     .textTheme
//                         //                                     .caption
//                         //                                     ?.copyWith(
//                         //                                       color:
//                         //                                           kGreyColor,
//                         //                                     ),
//                         //                               )
//                         //                             : SizedBox(height: 0.5),
//                         //                         SizedBox(
//                         //                             height:
//                         //                                 getProportionateScreenHeight(
//                         //                                     kDefaultPadding /
//                         //                                         5)),
//                         //                         Text(
//                         //                           "${_getPrice(products[index]['items'][idx]) != null ? _getPrice(products[index]['items'][idx]) : 0} Birr",
//                         //                           style: Theme.of(context)
//                         //                               .textTheme
//                         //                               .subtitle2
//                         //                               ?.copyWith(
//                         //                                 color:
//                         //                                     kSecondaryColor,
//                         //                                 fontWeight:
//                         //                                     FontWeight.bold,
//                         //                               ),
//                         //                         ),
//                         //                       ],
//                         //                     ),
//                         //                   )
//                         //                 ],
//                         //               ),
//                         //             ),
//                         //           );
//                         //         },
//                         //         separatorBuilder:
//                         //             (BuildContext context, int index) =>
//                         //                 SizedBox(
//                         //           height: getProportionateScreenHeight(
//                         //               kDefaultPadding / 4),
//                         //         ),
//                         //       )
//                         //     ],
//                         //   ),
//                         // );
//                       },
//                       separatorBuilder: (BuildContext context, int index) =>
//                           const SizedBox(
//                         height: 1,
//                       ),
//                     ),
//                   ),
//                 )
//               ],
//             )
//           : _loading
//               ? Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     SpinKitWave(
//                       size: getProportionateScreenHeight(kDefaultPadding),
//                       color: kSecondaryColor,
//                     ),
//                     Text("Loading...")
//                   ],
//                 )
//               : Center(
//                   child: Text(
//                     "Invalid QR Code\nRestaurant not found...",
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//     );
//   }
//
//   void _showDialog(item, destination, storeLocation, storeId) {
//     showDialog(
//         context: context,
//         builder: (BuildContext alertContext) {
//           return AlertDialog(
//             title: Text("Warning"),
//             content: Text(
//                 "Item(s) from a different store found in cart! Would you like to clear your cart?"),
//             actions: [
//               TextButton(
//                 child: Text(
//                   "Cancel",
//                   style: TextStyle(
//                     color: kBlackColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.of(alertContext).pop();
//                 },
//               ),
//               TextButton(
//                 child: Text(
//                   "Clear",
//                   style: TextStyle(
//                     color: kSecondaryColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     cart.toJson();
//                     Service.remove('cart');
//                     cart = Cart();
//                     addToCart(item, destination, storeLocation, storeId);
//                     // debugPrint(item.id);
//                     // debugPrint(cart.toJson());
//                   });
//
//                   Navigator.of(alertContext).pop();
//                   // Future.delayed(Duration(seconds: 2));
//                   // Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         });
//   }
//
//   Future<dynamic> getStoreProductList() async {
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_get_store_product_item_list";
//     Map data = {
//       "store_id": widget.storeId,
//     };
//     var body = json.encode(data);
//
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
//           setState(() {
//             _loading = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             Service.showMessage("Something went wrong!", true, duration: 3),
//           );
//           throw TimeoutException("The connection has timed out!");
//         },
//       );
//       setState(() {
//         _loading = false;
//       });
//
//       return json.decode(response.body);
//     } catch (e) {
//       // debugPrint(e);
//       if (mounted) {
//         setState(() {
//           _loading = false;
//         });
//       }
//
//       return null;
//     }
//   }
// }
