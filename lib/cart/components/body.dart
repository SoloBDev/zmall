// ignore_for_file: deprecated_member_use, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/aliexpress/ali_product_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/delivery/delivery_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/notifications/notification_store.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> with TickerProviderStateMixin {
  Cart? cart;
  AliExpressCart? aliexpressCart;
  bool _loading = true;
  double price = 0;
  var appClose;
  var appOpen;
  var storeDetail;
  double? latitude, longitude;
  LocationPermission _permissionStatus = LocationPermission.denied;
  //////////////////newly added
  var storeLocations;
  var storeID;
  var storeName;
  var userData;
  var extraItems;
  //double walletBalance = 0.0;
  //String payeePhone = "964345364";
  //String payerPassword = "";
  //bool transferLoading = false;
  //bool isDonation = false;
  //bool isCheckout = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCart();
    _getStoreExtraItemList();
    getAppKeys();
    _loading = false;
    // _getTransactions();
  }

  void calculatePrice() {
    double tempPrice = 0;
    cart?.items?.forEach((item) {
      tempPrice += item.price!;
    });
    setState(() {
      price = tempPrice;
    });
  }

  void getCart() async {
    setState(() {
      _loading = true;
    });
    try {
      userData = await Service.read('user');
      var data = await Service.read('cart');
      var aliCart = await Service.read('aliexpressCart');

      if (data != null) {
        setState(() {
          cart = Cart.fromJson(data);
          cart!.serverToken = userData['user']['server_token'];
          //walletBalance = double.parse(userData['user']['wallet'].toString());
          storeID = cart!.storeId!;
          Service.save('cart', cart);
        });
        // print("ALI CART>>> ${aliCart != null}");
        if (aliCart != null) {
          setState(() {
            aliexpressCart = AliExpressCart.fromJson(aliCart);
            Service.save('aliexpressCart', aliexpressCart);
          });
          // print("ALI CART>>> ${aliexpressCart!.toJson()}");
          // print(
          //     "ALI CART ITEM>>> ${aliexpressCart!.toJson()['cart']['items']}");
          // print("ALI ItemIds ${aliexpressCart!.toJson()['item_ids']}");
          // print("ALI ProductIds: ${aliexpressCart!.toJson()['product_ids']}");
        }
        // else {
        //   print("ALI CART NOT FOUND>>>");
        // }
        _getStoreExtraItemList();

        calculatePrice();
        if (cart!.items!.isNotEmpty) {
          _getStoreDetail();
        } else {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e) {}
  }
  // void getCart() async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   try {
  //     userData = await Service.read('user');
  //     var data = await Service.read('cart');
  //     if (data != null) {
  //       setState(() {
  //         cart = Cart.fromJson(data);
  //         cart!.serverToken = userData['user']['server_token'];
  //         //walletBalance = double.parse(userData['user']['wallet'].toString());
  //         storeID = cart!.storeId!;
  //         Service.save('cart', cart);
  //       });
  //       _getStoreExtraItemList();

  //       calculatePrice();
  //       if (cart != null && cart!.items!.length > 0) {
  //         _getStoreDetail();
  //       } else {
  //         setState(() {
  //           _loading = false;
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }
  void _getStoreDetail() async {
    setState(() {
      _loading = true;
    });
    var data = await getStoreDetail();
    if (data != null && data['success']) {
      setState(() {
        storeDetail = data;
        cart!.isLaundryService =
            storeDetail['store']['is_provide_laundry_service'];
        storeLocations = storeDetail['store']['location'];
        storeName = storeDetail['store']['name'];
        if (aliexpressCart?.cart != null &&
            cart!.storeId == aliexpressCart!.cart.storeId) {
          cart!.storeLocation = aliexpressCart!.cart.storeLocation =
              StoreLocation(long: storeLocations[1], lat: storeLocations[0]);
        }
      });
      Service.save('cart', cart!.toJson());
      Service.save('aliexpressCart', aliexpressCart?.toJson());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
    }
    setState(() {
      _loading = false;
    });
  }
  // void _getStoreDetail() async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   var data = await getStoreDetail();
  //   if (data != null && data['success']) {
  //     setState(() {
  //       storeDetail = data;
  //       cart!.isLaundryService =
  //           storeDetail['store']['is_provide_laundry_service'];
  //       storeLocations = storeDetail['store']['location'];
  //       storeName = storeDetail['store']['name'];
  //     });
  //     Service.save('cart', cart!.toJson());
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
  //   }
  //   setState(() {
  //     _loading = false;
  //   });
  // }

  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Location permission denied. Please enable and try again", true));
      FlLocation.requestLocationPermission();
    }
  }

  void getLocation() async {
    var currentLocation = await FlLocation.getLocation();
    if (mounted) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
      });
      Provider.of<ZMetaData>(context, listen: false)
          .setLocation(currentLocation.latitude, currentLocation.longitude);
    }
  }

  void _doLocationTask() async {
    LocationPermission _permissionStatus =
        await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.whileInUse ||
        _permissionStatus == LocationPermission.always) {
      if (await FlLocation.isLocationServicesEnabled) {
        getLocation();
      } else {
        LocationPermission serviceStatus =
            await FlLocation.requestLocationPermission();
        if (serviceStatus == LocationPermission.always ||
            serviceStatus == LocationPermission.whileInUse) {
          getLocation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
              "Location service disabled. Please enable and try again", true));
        }
      }
    } else {
      _requestLocationPermission();
    }
  }

  Future<bool> storeOpen() async {
    bool isStoreOpen = false;
    DateFormat dateFormat = new DateFormat.Hm();
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
    var appClose = await Service.read('app_close');
    var appOpen = await Service.read('app_open');
    DateTime zmallClose = dateFormat.parse(appClose);
    DateTime zmallOpen = dateFormat.parse(appOpen);

    now = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    zmallOpen = new DateTime(
        now.year, now.month, now.day, zmallOpen.hour, zmallOpen.minute);
    zmallClose = new DateTime(
        now.year, now.month, now.day, zmallClose.hour, zmallOpen.minute);
    if (now.isAfter(zmallOpen) && now.isBefore(zmallClose)) {
      isStoreOpen = true;
    } else {
      isStoreOpen = false;
    }
    return isStoreOpen;
  }

  void getAppKeys() async {
    var appKeys = await CoreServices.appKeys(context);
    if (appKeys != null && appKeys['success']) {
      if (mounted)
        setState(() {
          appClose = appKeys['app_close'];
          appOpen = appKeys['app_open'];
          Service.save("app_close", appClose);
          Service.save("app_open", appOpen);
        });
    } else {
      appClose = await Service.read('app_close');
      appOpen = await Service.read('app_open');
    }
  }

//////////////////////////////////////////////////////////////////newly added
  void _getStoreExtraItemList() async {
    setState(() {
      _loading = true;
    });
    var data = await getStoreExtraItemList();

    if (data != null && data['success']) {
      extraItems = data['items'];
      // print(storeID);
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  String _getPrice(item) {
    if (item['price'] == null || item['price'] == 0) {
      for (var i = 0; i < item['specifications'].length; i++) {
        for (var j = 0; j < item['specifications'][i]['list'].length; j++) {
          if (item['specifications'][i]['list'][j]['is_default_selected']) {
            return item['specifications'][i]['list'][j]['price']
                .toStringAsFixed(2);
          }
        }
      }
    } else {
      return item['price'].toStringAsFixed(2);
    }
    return "0.00";
  }

  void addToCart(item, destination, storeLocation, storeId) {
    cart = Cart(
      userId: userData['user']['_id'],
      items: [item],
      serverToken: userData['user']['server_token'],
      destinationAddress: destination,
      storeId: storeId,
      storeLocation: storeLocation,
    );

    Service.save('cart', cart!.toJson());
    ScaffoldMessenger.of(context)
        .showSnackBar(Service.showMessage("Item added to cart!", false));
  }

//////////////////////////////////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      color: kPrimaryColor,
      progressIndicator: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitWave(
            color: kSecondaryColor,
            size: getProportionateScreenHeight(kDefaultPadding),
          ),
          Text("Checking if items are available..."),
        ],
      ),
      inAsyncCall: _loading,
      child: cart != null && cart!.items!.length > 0
          ? Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(kDefaultPadding),
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(kDefaultPadding),
                        bottomRight: Radius.circular(kDefaultPadding)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          storeName ?? "",
                          softWrap: true,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // storeName.toString().toLowerCase() == "aliexpress"
                      //     ? SizedBox.shrink()
                      //     :
                      TextButton(
                        onPressed:
                            storeName.toString().toLowerCase() == "aliexpress"
                                ? () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) {
                                      return AliProductListScreen();
                                    }));
                                  }
                                : () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) {
                                      return NotificationStore(
                                          storeId: cart!.storeId!);
                                    }));
                                  },
                        child: Text(
                          "Add more?",
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 3)),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cart!.toJson()['items'].length ?? 0,
                    itemBuilder: (context, index) {
                      final item = cart!.items?[index];
                      return item != null
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  // horizontal:
                                  //     getProportionateScreenWidth(kDefaultPadding / 2),
                                  ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  // borderRadius:
                                  //     BorderRadius.circular(kDefaultPadding),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: getProportionateScreenHeight(
                                      kDefaultPadding / 2),
                                  horizontal: getProportionateScreenWidth(
                                      kDefaultPadding / 2),
                                ),
                                child: Row(
                                  children: [
                                    ImageContainer(url: item.imageURL!),
                                    SizedBox(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding / 4)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.itemName!,
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding),
                                              fontWeight: FontWeight.bold,
                                              color: kBlackColor,
                                            ),
                                            softWrap: true,
                                          ),
                                          SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding / 5)),
                                          Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).currency} ${item.price!.toStringAsFixed(2)}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: kGreyColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 5),
                                          ),
                                          Text(item.noteForItem),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                                icon: Icon(
                                                  Icons.remove_circle_outline,
                                                  color: item.quantity != 1
                                                      ? kSecondaryColor
                                                      : kGreyColor,
                                                ),
                                                onPressed: item.quantity == 1
                                                    ? () {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(Service
                                                                .showMessage(
                                                                    "Minimum order quantity is 1!",
                                                                    true));
                                                      }
                                                    : () {
                                                        int? currQty =
                                                            item.quantity;
                                                        double? unitPrice =
                                                            item.price! /
                                                                currQty!;
                                                        setState(() {
                                                          item.quantity =
                                                              currQty - 1;
                                                          item.price =
                                                              unitPrice *
                                                                  (currQty - 1);
                                                          Service.save('cart',
                                                              cart); //old
                                                          // Update aliexpressCart if applicable
                                                          if (aliexpressCart !=
                                                                  null &&
                                                              aliexpressCart!
                                                                      .cart
                                                                      .storeId ==
                                                                  cart!
                                                                      .storeId) {
                                                            // int aliexpressIndex = aliexpressCart!.itemIds!.indexOf(item.id!);
                                                            aliexpressCart!
                                                                    .cart
                                                                    .items![index]
                                                                    .quantity =
                                                                currQty - 1;
                                                            aliexpressCart!
                                                                    .cart
                                                                    .items![index]
                                                                    .price =
                                                                unitPrice *
                                                                    (currQty -
                                                                        1);
                                                            Service.save(
                                                                'aliexpressCart',
                                                                aliexpressCart); // Save updated aliexpressCart
                                                          }
                                                        });
                                                        calculatePrice();
                                                      }),
                                            Text(
                                              "${item.quantity}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            IconButton(
                                                icon: Icon(
                                                  Icons.add_circle,
                                                  color: kSecondaryColor,
                                                ),
                                                onPressed: () {
                                                  int? currQty = item.quantity;
                                                  double? unitPrice =
                                                      item.price! / currQty!;
                                                  setState(() {
                                                    item.quantity = currQty + 1;
                                                    item.price = unitPrice *
                                                        (currQty + 1);
                                                    Service.save(
                                                        'cart', cart); //old
                                                    // Update aliexpressCart if applicable
                                                    if (aliexpressCart !=
                                                            null &&
                                                        aliexpressCart!
                                                                .cart.storeId ==
                                                            cart!.storeId) {
                                                      // int aliexpressIndex = aliexpressCart!.productIds!.indexOf(item.productId!);
                                                      aliexpressCart!
                                                              .cart
                                                              .items![index]
                                                              .quantity =
                                                          currQty + 1;
                                                      aliexpressCart!
                                                              .cart
                                                              .items![index]
                                                              .price =
                                                          unitPrice *
                                                              (currQty + 1);
                                                      Service.save(
                                                          'aliexpressCart',
                                                          aliexpressCart); // Save updated aliexpressCart
                                                    }
                                                  });
                                                  calculatePrice();
                                                }),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              cart?.items?.removeAt(index);
                                              //Service.save('cart', cart);//old
                                              //NEW
                                              Service.save('cart', cart); //old
                                              if (aliexpressCart != null &&
                                                  aliexpressCart!
                                                          .cart.storeId ==
                                                      cart!.storeId) {
                                                aliexpressCart!.cart.items!
                                                    .removeAt(index);
                                                aliexpressCart!.itemIds!
                                                    .removeAt(index);
                                                aliexpressCart!.productIds!
                                                    .removeAt(index);
                                                Service.save('aliexpressCart',
                                                    aliexpressCart); //NEW
                                              }
                                            });
                                            calculatePrice();
                                          },
                                          child: Text(
                                            Provider.of<ZLanguage>(context)
                                                .remove,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    color: kSecondaryColor),
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container();
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                  ),
                ),

///////////////////////////New customization
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(kDefaultPadding * 2),
                          topRight: Radius.circular(kDefaultPadding * 2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.8),
                          spreadRadius: 8,
                          blurRadius: 3,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child:
                        //   isCheckout
                        // ? showDonationView()
                        // :
                        Column(
                      children: [
                        //
                        extraItems != null
                            ? showExtraItems()
                            : SizedBox.shrink(),
                        SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding / 4),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  getProportionateScreenWidth(kDefaultPadding)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 3)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${Provider.of<ZLanguage>(context).cartTotal}: ",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: kBlackColor),
                                ),
                                Text(
                                  "${Provider.of<ZMetaData>(context, listen: false).currency} ${price.toStringAsFixed(2)}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: kBlackColor,
                                          fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding / 4),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(
                                kDefaultPadding * 2),
                            vertical:
                                getProportionateScreenHeight(kDefaultPadding),
                          ),
                          child: CustomButton(
                            title: Provider.of<ZLanguage>(context).checkout,
                            press: () async {
                              //   if (isDonation && !isCheckout) {
                              //   setState(() {
                              //     isCheckout = !isCheckout;
                              //   });
                              // } else {
                              DateFormat dateFormat = new DateFormat.Hm();
                              DateTime now = DateTime.now()
                                  .toUtc()
                                  .add(Duration(hours: 3));
                              var appClose = await Service.read('app_close');
                              var appOpen = await Service.read('app_open');
                              DateTime zmallClose = dateFormat.parse(appClose);
                              DateTime zmallOpen = dateFormat.parse(appOpen);

                              now = DateTime(now.year, now.month, now.day,
                                  now.hour, now.minute);
                              zmallOpen = new DateTime(now.year, now.month,
                                  now.day, zmallOpen.hour, zmallOpen.minute);
                              zmallClose = new DateTime(now.year, now.month,
                                  now.day, zmallClose.hour, zmallClose.minute);

                              if (now.isAfter(zmallOpen) &&
                                  now.isBefore(zmallClose)) {
                                Navigator.pushNamed(
                                    context, DeliveryScreen.routeName);
                                //   if (isDonation) {
                                //   print('***This is Donation***');
                                //   //showDonation();
                                // } else {
                                //   Navigator.pushNamed(
                                //       context, DeliveryScreen.routeName);
                                // }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Sorry, we are currently closed. Please comeback soon.",
                                      false,
                                      duration: 3),
                                );
                              }
                            },
                            // },
                            color: kSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
//////////////////////////////////////////////////
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_shopping_cart_outlined,
                    size: getProportionateScreenHeight(kDefaultPadding * 3),
                    color: kSecondaryColor,
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 3),
                  ),
                  Text(
                    "Empty Basket!",
                    style: Theme.of(context).textTheme.titleLarge,
                  )
                ],
              ),
            ),
    );
  }

  Future<dynamic> getStoreDetail() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_get_store_product_item_list";
    Map data = {
      "store_id": cart!.storeId!,
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
        Duration(seconds: 20),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.storeDetail = json.decode(response.body);
      });
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Couldn't get store detail, check your internet and try again.",
              true,
              duration: 3),
        );
      }
      return null;
    }
  }
  ///////////////////////////////////////////////////////////newly added

  Future<dynamic> getStoreExtraItemList() async {
    print('Store ID ***${storeID}***');
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_get_store_product_item_available";

    Map data = {
      "store_id": storeID,
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
          setState(() {
            this._loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            Service.showMessage("Something went wrong!", true, duration: 3),
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      if (mounted) {
        setState(() {
          this._loading = false;
        });
      }

      return null;
    }
  }

  void _showDialog(item, destination, storeLocation, storeId) {
    showDialog(
        context: context,
        builder: (BuildContext alertContext) {
          return AlertDialog(
            title: Text(Provider.of<ZLanguage>(context).warning),
            content: Text(Provider.of<ZLanguage>(context).itemsFound),
            actions: [
              TextButton(
                child: Text(
                  Provider.of<ZLanguage>(context).cancel,
                  style: TextStyle(
                    color: kBlackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(alertContext).pop();
                },
              ),
              TextButton(
                child: Text(
                  Provider.of<ZLanguage>(context).clear,
                  style: TextStyle(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    cart!.toJson();
                    Service.remove('cart');
                    Service.remove('aliexpressCart'); ////NEW
                    cart = Cart();
                    addToCart(item, destination, storeLocation, storeId);
                  });

                  Navigator.of(alertContext).pop();
                },
              ),
            ],
          );
        });
  }

  Widget showExtraItems() {
    bool isNull = extraItems.every((extraItem) => cart!.items!
        .any((cartItem) => cartItem.toJson()['_id'] == extraItem['_id']));
    return isNull
        ? SizedBox.shrink()
        : Column(
            children: [
              Text(
                'Perfect Paring for Your Order!',
              ),
              const SizedBox(height: kDefaultPadding),
              Container(
                height: getProportionateScreenHeight(kDefaultPadding * 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding)),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: extraItems.length,
                  itemBuilder: (context, index) {
                    bool isAppear = cart!.items!.any((element) =>
                        element.toJson()['_id'] == extraItems[index]['_id']);

                    return isAppear
                        ? SizedBox.shrink()
                        : Column(
                            children: [
                              CachedNetworkImage(
                                imageUrl:
                                    "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${extraItems[index]['image_url']}",
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  width: getProportionateScreenWidth(
                                      kDefaultPadding * 3),
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding * 3),
                                  decoration: BoxDecoration(
                                    color: kWhiteColor,
                                    borderRadius: BorderRadius.circular(
                                        getProportionateScreenHeight(
                                            kDefaultPadding)),
                                    image: DecorationImage(
                                      fit: BoxFit.contain,
                                      image: imageProvider,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) => Center(
                                  child: Container(
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding * 3),
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding * 3),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          kWhiteColor),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: getProportionateScreenWidth(
                                      kDefaultPadding * 3),
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding * 3),
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.contain,
                                      image: AssetImage(zmallLogo),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 3),
                              ),
                              Text(
                                extraItems[index]['name'],
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(
                                      kDefaultPadding * 0.9),
                                  color: kBlackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                softWrap: true,
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 5)),
                              Text(
                                "${_getPrice(extraItems[index]) != null ? _getPrice(extraItems[index]) : 0} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: kBlackColor,
                                    ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  // Add to cart.....

                                  print('id... ${extraItems[index]['_id']}');
                                  Item item = Item(
                                    id: extraItems[index]['_id'],
                                    quantity: 1,
                                    specification: [],
                                    noteForItem: "",
                                    price: _getPrice(extraItems[index]) != null
                                        ? double.parse(
                                            _getPrice(extraItems[index]),
                                          )
                                        : 0,
                                    itemName: extraItems[index]['name'],
                                    imageURL: extraItems[index]['image_url']
                                                .length >
                                            0
                                        ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${extraItems[index]['image_url']}"
                                        : "https://ibb.co/vkhzjd6",
                                  );
                                  print('item... $item');
                                  StoreLocation storeLocation = StoreLocation(
                                      long: storeLocations[1],
                                      lat: storeLocations[0]);
                                  print('sLocation... $storeLocation');
                                  DestinationAddress destination =
                                      DestinationAddress(
                                    long: Provider.of<ZMetaData>(context,
                                            listen: false)
                                        .longitude,
                                    lat: Provider.of<ZMetaData>(context,
                                            listen: false)
                                        .latitude,
                                    name: "Current Location",
                                    note: "User current location",
                                  );
                                  print('DestinationAddress... $destination');
                                  if (cart != null && userData != null) {
                                    if (cart!.storeId! ==
                                        extraItems[index]['store_id']) {
                                      setState(() {
                                        cart!.items!.add(item);
                                        Service.save('cart', cart)
                                            .then((value) => calculatePrice())
                                            .then((value) => ScaffoldMessenger
                                                    .of(context)
                                                .showSnackBar(
                                                    Service.showMessage(
                                                        "Item added to cart",
                                                        false)))
                                            .then((value) => setState(() {}));
                                      });
                                    } else {
                                      _showDialog(
                                          item,
                                          destination,
                                          storeLocation,
                                          extraItems[index]['store_id']);
                                    }
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kBlackColor,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 4),
                                    ),
                                    child: Text(
                                      "${Provider.of<ZLanguage>(context).addToCart}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: kPrimaryColor,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      SizedBox(
                    width: getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                ),
              ),
            ],
          );
  }
}

/* 

  void getUser() async {
    var data = await Service.read('user');

    if (data != null) {
      setState(() {
        userData = data;
        walletBalance = double.parse(userData['user']['wallet'].toString());
      });
      getCart();
    }
  }

 
  

  void _getTransactions() async {
    setState(() {
      _loading = true;
    });
    var data = await transactionHistoryDetails();

    if (data != null && data['success']) {
      setState(() {
        _loading = false;
      });
    } else {
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        _loading = false;
      });
      if (errorCodes['${data['error_code']}'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${errorCodes['${data['error_code']}']}"),
          backgroundColor: kSecondaryColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("No wallet transaction history"),
          backgroundColor: kSecondaryColor,
        ));
      }
    }
  } 
  
  
  
  
  
  
  Future<dynamic> transactionHistoryDetails() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_wallet_history";
    Map data = {
      "id": userData['user']['_id'],
      "type": userData['user']['admin_type'],
      "server_token": userData['user']['server_token'],
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
        Duration(seconds: 10),
        onTimeout: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
          setState(() {
            _loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );

      return json.decode(response.body);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<dynamic> genzebLak() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/transfer_wallet_amount";
    Map data = {
      "user_id": userData['user']['_id'],
      "top_up_user_phone": '964345364', //storeDetail['store']['phone'],
      "password": payerPassword,
      "wallet": price,
      "server_token": userData['user']['server_token'],
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
        Duration(seconds: 10),
        onTimeout: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
          setState(() {
            _loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      print(json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Widget showDonationView() {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding * 2),
              topRight: Radius.circular(kDefaultPadding * 2)),
        ),
        child: Wrap(
          children: <Widget>[
            Center(
              child: Text(
                "Pay ${Provider.of<ZMetaData>(context, listen: false).currency} $price",
                style: Theme.of(context)
                    .textTheme
                    .headline5
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Center(
                child: Text(
              "Wallet - ${Provider.of<ZMetaData>(context, listen: false).currency} ${walletBalance.toStringAsFixed(2)}",
            )),
            Container(
              height: getProportionateScreenHeight(kDefaultPadding),
            ),
            Container(
                height: getProportionateScreenHeight(kDefaultPadding / 2)),
            TextField(
              style: TextStyle(color: kBlackColor),
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              onChanged: (val) {
                payerPassword = val;
              },
              decoration:
                  textFieldInputDecorator.copyWith(labelText: "Password"),
            ),
            Container(
                height: getProportionateScreenHeight(kDefaultPadding / 2)),
            Visibility(
              visible: isCheckout,
              child: CustomButton(
                title: "Send",
                color: kSecondaryColor,
                press: () async {
                  if (price <= walletBalance) {
                    if (payerPassword.isNotEmpty) {
                      setState(() {
                        transferLoading = true;
                      });

                      var data = await genzebLak();
                      if (data != null && data['success']) {
                        setState(() {
                          transferLoading = false;
                          userData['user']['wallet'] -= price;
                        });
                        getUser();
                        _getTransactions();

                        /*     ScaffoldMessenger.of(context).showSnackBar(
                            Service.showMessage(
                                "Donation made successfully!\nThank you for your generous donation! Your support is greatly appreciated and will make a meaningful difference.",
                                false,
                                duration: 5)); */
                        setState(() {
                          transferLoading = false;
                          Service.remove('cart');
                          Service.remove('aliexpressCart');//NEW
                          isCheckout = !isCheckout;
                          walletBalance = double.parse(
                              userData['user']['wallet'].toString());
                          payerPassword = '';
                        });
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  "Donation made successfully!",
                                ),
                                titleTextStyle: TextStyle(
                                    color: kSecondaryColor, fontSize: 20),
                                content: Text(
                                    "You have made donation to ${storeDetail['store']['company_name']}. Thank you for your generous donation, Your support is greatly appreciated and will make a meaningful difference."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        isCheckout = !isCheckout;
                                        walletBalance = double.parse(
                                            userData['user']['wallet']
                                                .toString());
                                        payerPassword = '';
                                        Navigator.of(context).pop();
                                      });
                                    },
                                    child: Text('OK'),
                                  )
                                ],
                              );
                            });
                      } else {
                        if (data['error_code'] == 999) {
                          await Service.saveBool('logged', false);
                          await Service.remove('user');
                          Navigator.pushReplacementNamed(
                              context, LoginScreen.routeName);
                        }
                        setState(() {
                          transferLoading = false;
                          isCheckout = !isCheckout;
                          walletBalance = double.parse(
                              userData['user']['wallet'].toString());
                          payerPassword = '';
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                            Service.showMessage(
                                "${errorCodes['${data['error_code']}']}",
                                true));
                      }
                    } else {
                      setState(() {
                        isCheckout = !isCheckout;
                        walletBalance =
                            double.parse(userData['user']['wallet'].toString());
                        payerPassword = '';
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                          Service.showMessage(
                              "Invalid! Please make sure the fields is filled.",
                              true));
                    }
                  } else {
                    setState(() {
                      isCheckout = !isCheckout;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      Service.showMessage(
                          "Sorry, you have an insufficent balance.", true),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

   */
