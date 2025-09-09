import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/shimmer_widget.dart';

class NotificationStore extends StatefulWidget {
  const NotificationStore({
    super.key,
    required this.storeId,
    this.storeName = "",
  });

  final String storeId;
  final String storeName;

  @override
  _NotificationStoreState createState() => _NotificationStoreState();
}

class _NotificationStoreState extends State<NotificationStore> {
  bool _loading = true;
  var responseData;
  var products;
  Cart? cart;
  bool isLoggedIn = false;
  bool isOpen = false;
  var userData;
  String storeName = "";
  var store;

  @override
  void initState() {
    super.initState();
    storeName = widget.storeName;
    isLogged();
    getCart();
    _getStoreProductList();
  }

  void getCart() async {
    // debugPrint("Fetching data");
    var data = await Service.read('cart');
    if (data != null) {
      setState(() {
        cart = Cart.fromJson(data);
      });
    }
  }

  void isLogged() async {
    var data = await Service.readBool('logged');
    if (data != null) {
      setState(() {
        isLoggedIn = data;
      });
      getUser();
    } else {
      // debugPrint("No logged user found");
    }
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
    }
  }

  void _getStoreProductList() async {
    await getStoreProductList();
    if (responseData != null && responseData['success']) {
      isOpen = await storeOpen(responseData['store']);
      if (mounted) {
        setState(() {
          store = responseData['store'];
          products = responseData['products'];
          storeName = responseData['store']['name'];
        });
      }
      // debugPrint("Is open : $isOpen");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${errorCodes['${responseData['error_code']}']}"),
        ),
      );
    }
  }

  void _getAppKeys() async {
    var data = await CoreServices.appKeys(context);
    if (data != null && data['success']) {
      // debugPrint("=> \tIs Closed : ${data['message_flag']}");
      // debugPrint("=> \tCurrent Version : ${data['ios_user_app_version_code']}");
      setState(() {
        Service.saveBool("is_closed", data['message_flag']);
        Service.save("closed_message", data['message']);
        Service.save("ios_app_version", data['ios_user_app_version_code']);
        Service.saveBool(
            "ios_update_dialog", data['is_ios_user_app_open_update_dialog']);
        Service.saveBool(
            "ios_force_update", data['is_ios_user_app_force_update']);
        Service.save('app_close', data['app_close']);
        Service.save('app_open', data['app_open']);
      });
    }
  }

  Future<bool> storeOpen(var store) async {
    setState(() {
      _loading = true;
    });
    _getAppKeys();
    setState(() {
      _loading = false;
    });
    bool isStoreOpen = false;

    if (store['store_time'] != null && store['store_time'].length != 0) {
      var appClose = await Service.read('app_close');
      var appOpen = await Service.read('app_open');
      for (var i = 0; i < store['store_time'].length; i++) {
        DateFormat dateFormat = new DateFormat.Hm();
        // DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
        DateTime now = DateTime.now().toUtc();
        int weekday;
        if (now.weekday == 7) {
          weekday = 0;
        } else {
          weekday = now.weekday;
        }

        if (store['store_time'][i]['day'] == weekday) {
          if (store['store_time'][i]['day_time'].length != 0 &&
              store['store_time'][i]['is_store_open']) {
            for (var j = 0;
                j < store['store_time'][i]['day_time'].length;
                j++) {
              DateTime open = dateFormat.parse(
                  store['store_time'][i]['day_time'][j]['store_open_time']);
              open = new DateTime(
                  now.year, now.month, now.day, open.hour, open.minute);
              DateTime close = dateFormat.parse(
                  store['store_time'][i]['day_time'][j]['store_close_time']);

              DateTime zmallClose = dateFormat.parse(appClose);
              DateTime zmallOpen = dateFormat.parse(appOpen);

              close = new DateTime(
                  now.year, now.month, now.day, close.hour, close.minute);
              now =
                  DateTime(now.year, now.month, now.day, now.hour, now.minute);

              zmallOpen = new DateTime(now.year, now.month, now.day,
                  zmallOpen.hour, zmallOpen.minute);
              zmallClose = new DateTime(now.year, now.month, now.day,
                  zmallClose.hour, zmallClose.minute);

              if (now.isAfter(open) &&
                  now.isAfter(zmallOpen) &&
                  now.isBefore(close) &&
                  store['store_time'][i]['is_store_open'] &&
                  now.isBefore(zmallClose)) {
                isStoreOpen = true;
                break;
              } else {
                isStoreOpen = false;
              }
            }
          } else {
            isStoreOpen = store['store_time'][i]['is_store_open'];
          }
        }
      }
    } else {
      var appClose = await Service.read('app_close');
      var appOpen = await Service.read('app_open');
      // DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
      DateTime now = DateTime.now().toUtc();
      DateFormat dateFormat = new DateFormat.Hm();
      DateTime zmallClose = dateFormat.parse(appClose);
      DateTime zmallOpen = dateFormat.parse(appOpen);
      zmallClose = DateTime(
          now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
      zmallOpen = DateTime(
          now.year, now.month, now.day, zmallOpen.hour, zmallOpen.minute);
      now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      if (now.isAfter(zmallOpen) && now.isBefore(zmallClose)) {
        isStoreOpen = true;
      } else {
        isStoreOpen = false;
      }
    }

    return isStoreOpen;
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
    // Service.showMessage(
    //     context: context, title: "Item added to cart!", error: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: Text(
          Service.capitalizeFirstLetters(
            storeName.isNotEmpty ? storeName : "Loading..",
          ),

          // storeName == "" ? "Loading.." : storeName,
          style: TextStyle(
            color: kBlackColor,
          ),
        ),
        leading: BackButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, "/start", (Route<dynamic> route) => false);
          },
          color: kBlackColor,
        ),
      ),
      bottomNavigationBar:
          !_loading && (cart != null && cart!.items!.length > 0)
              ? SafeArea(
                  child: Container(
                  width: double.infinity,
                  // height: kDefaultPadding * 4,
                  padding: EdgeInsets.symmetric(
                    vertical: getProportionateScreenHeight(kDefaultPadding),
                    horizontal: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    border: Border(top: BorderSide(color: kWhiteColor)),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(kDefaultPadding),
                      topRight: Radius.circular(kDefaultPadding),
                    ),
                  ),

                  child: CustomButton(
                    title: "Go to Cart",
                    press: () {
                      Navigator.pushNamed(context, '/cart')
                          .then((value) => getCart());
                    },
                    color: kSecondaryColor,
                  ),
                ))
              : SizedBox.shrink(),
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: _loading,
          color: kPrimaryColor,
          // progressIndicator:
          //     CustomLinearProgressIndicator(message: "Loading store.."),
          progressIndicator: products != null
              ? LinearLoadingIndicator()
              : ProductListShimmer(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
              vertical: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                products != null
                    ? Expanded(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: products.length,
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 2),
                            );
                          },
                          itemBuilder: (BuildContext context, int index) {
                            return ExpansionTile(
                              textColor: kBlackColor,
                              backgroundColor: kPrimaryColor,
                              collapsedBackgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: kWhiteColor),
                                borderRadius: BorderRadiusGeometry.circular(
                                    kDefaultPadding),
                              ),
                              collapsedShape: RoundedRectangleBorder(
                                side: BorderSide(color: kWhiteColor),
                                borderRadius: BorderRadiusGeometry.circular(
                                    kDefaultPadding),
                              ),
                              leading: const Icon(
                                Icons.dining,
                                size: 20,
                                color: kBlackColor,
                              ),
                              childrenPadding: EdgeInsets.only(
                                left: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                right: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                bottom: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              title: Text(
                                "${Service.capitalizeFirstLetters(products[index]["_id"]["name"])}",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              children: [
                                ListView.separated(
                                  physics: ClampingScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: products[index]['items'].length,
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  itemBuilder: (BuildContext context, int idx) {
                                    return GestureDetector(
                                      onTap: () async {
                                        // if (isLoggedIn) {
                                        //   productClicked(
                                        //       products[index]['items'][idx]['_id']);
                                        // }

                                        isOpen
                                            ? Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return ItemScreen(
                                                      item: products[index]
                                                          ['items'][idx],
                                                      location:
                                                          store['location'],
                                                    );
                                                  },
                                                ),
                                              ).then((value) => getCart())
                                            : ScaffoldMessenger.of(context)
                                                .showSnackBar(Service.showMessage1(
                                                    "Sorry the store is closed at this time!",
                                                    true));
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 2),
                                              vertical:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding / 2),
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kWhiteColor),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      kDefaultPadding),
                                            ),
                                            child: Row(
                                              spacing: kDefaultPadding,
                                              children: [
                                                /////////item image section//////////
                                                products[index]['items'][idx]
                                                                ['image_url']
                                                            .length >
                                                        0
                                                    ? ImageContainer(
                                                        url:
                                                            "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${products[index]['items'][idx]['image_url'][0]}")
                                                    : ImageContainer(
                                                        url:
                                                            "https://ibb.co/vkhzjd6",
                                                      ),

                                                /////////item detail section//////////
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        Service.capitalizeFirstLetters(
                                                            products[index]
                                                                    ['items']
                                                                [idx]['name']),
                                                        style: TextStyle(
                                                          fontSize:
                                                              getProportionateScreenWidth(
                                                                  kDefaultPadding *
                                                                      .9),
                                                          color: kBlackColor,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        softWrap: true,
                                                      ),
                                                      SizedBox(
                                                          height:
                                                              getProportionateScreenHeight(
                                                                  kDefaultPadding /
                                                                      5)),
                                                      products[index]['items']
                                                                          [idx][
                                                                      'details'] !=
                                                                  null &&
                                                              products[index]['items']
                                                                              [
                                                                              idx]
                                                                          [
                                                                          'details']
                                                                      .length >
                                                                  0
                                                          ? Text(
                                                              products[index]
                                                                      ['items'][
                                                                  idx]['details'],
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color:
                                                                        kGreyColor,
                                                                  ),
                                                            )
                                                          : SizedBox(
                                                              height: 0.5),

                                                      ////price and button section//
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            "${_getPrice(products[index]['items'][idx]).isNotEmpty ? _getPrice(products[index]['items'][idx]) : 0} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelLarge
                                                                ?.copyWith(
                                                                    color:
                                                                        kBlackColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                          ),
                                                          //// button section//
                                                          GestureDetector(
                                                            onTap: () async {
                                                              if (products[index]['items']
                                                                              [
                                                                              idx]
                                                                          [
                                                                          'specifications']
                                                                      .length >
                                                                  0) {
                                                                // if (isLoggedIn) {
                                                                //   productClicked(
                                                                //       products[index]
                                                                //               ['items']
                                                                //           [idx]['_id']);
                                                                // }

                                                                isOpen
                                                                    ? Navigator
                                                                        .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder:
                                                                              (context) {
                                                                            return ItemScreen(
                                                                              item: products[index]['items'][idx],
                                                                              location: store['location'],
                                                                            );
                                                                          },
                                                                        ),
                                                                      ).then(
                                                                        (value) =>
                                                                            getCart())
                                                                    : ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(Service.showMessage1(
                                                                            "Sorry the store is closed at this time!",
                                                                            true));
                                                              } else {
                                                                //TD: Add to cart.....

                                                                Item item =
                                                                    Item(
                                                                  id: products[
                                                                              index]
                                                                          [
                                                                          'items']
                                                                      [
                                                                      idx]['_id'],
                                                                  quantity: 1,
                                                                  specification: [],
                                                                  noteForItem:
                                                                      "",
                                                                  price: _getPrice(products[index]['items']
                                                                              [
                                                                              idx])
                                                                          .isNotEmpty
                                                                      ? double
                                                                          .parse(
                                                                          _getPrice(products[index]['items']
                                                                              [
                                                                              idx]),
                                                                        )
                                                                      : 0,
                                                                  itemName: products[
                                                                              index]
                                                                          [
                                                                          'items']
                                                                      [
                                                                      idx]['name'],
                                                                  imageURL: products[index]['items'][idx]['image_url']
                                                                              .length >
                                                                          0
                                                                      ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${products[index]['items'][idx]['image_url'][0]}"
                                                                      : "https://ibb.co/vkhzjd6",
                                                                );
                                                                StoreLocation
                                                                    storeLocation =
                                                                    StoreLocation(
                                                                        long: store['location']
                                                                            [1],
                                                                        lat: store['location']
                                                                            [
                                                                            0]);
                                                                DestinationAddress
                                                                    destination =
                                                                    DestinationAddress(
                                                                  long: store[
                                                                      'location'][1],
                                                                  lat: store[
                                                                      'location'][0],
                                                                  name:
                                                                      "Current Location",
                                                                  note:
                                                                      "User current location",
                                                                );

                                                                if (cart !=
                                                                    null) {
                                                                  if (userData !=
                                                                      null) {
                                                                    if (cart!
                                                                            .storeId ==
                                                                        products[index]['items'][idx]
                                                                            [
                                                                            'store_id']) {
                                                                      setState(
                                                                          () {
                                                                        cart!
                                                                            .items!
                                                                            .add(item);
                                                                        Service.save(
                                                                            'cart',
                                                                            cart);

                                                                        // Service
                                                                        //     .showMessage(
                                                                        //   context:
                                                                        //       context,
                                                                        //   title:
                                                                        //       "Item added to cart",
                                                                        //   error:
                                                                        //       false,
                                                                        // );
                                                                        // Navigator.of(
                                                                        //         context)
                                                                        //     .pop();
                                                                      });
                                                                    } else {
                                                                      _showDialog(
                                                                          item,
                                                                          destination,
                                                                          storeLocation,
                                                                          products[index]['items'][idx]
                                                                              [
                                                                              'store_id']);
                                                                    }
                                                                  } else {
                                                                    // debugPrint( "User not logged in...");
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(Service.showMessage1(
                                                                            "Please login in...",
                                                                            true));
                                                                    Navigator
                                                                        .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                LoginScreen(
                                                                          firstRoute:
                                                                              false,
                                                                        ),
                                                                      ),
                                                                    ).then((value) =>
                                                                        getUser());
                                                                  }
                                                                } else {
                                                                  if (userData !=
                                                                      null) {
                                                                    // debugPrint(  "Empty cart! Adding new item.");
                                                                    addToCart(
                                                                        item,
                                                                        destination,
                                                                        storeLocation,
                                                                        products[index]['items'][idx]
                                                                            [
                                                                            'store_id']);
                                                                    getCart();
                                                                    // Navigator.of(
                                                                    //         context)
                                                                    //     .pop();
                                                                  } else {
                                                                    // debugPrint( "User not logged in...");
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(Service.showMessage1(
                                                                            "Please login in...",
                                                                            true));
                                                                    Navigator
                                                                        .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                LoginScreen(
                                                                          firstRoute:
                                                                              false,
                                                                        ),
                                                                      ),
                                                                    ).then((value) =>
                                                                        getUser());
                                                                  }
                                                                }
                                                              }
                                                            },
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          kDefaultPadding /
                                                                              2,
                                                                      vertical:
                                                                          kDefaultPadding /
                                                                              3),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: kSecondaryColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.1),
                                                                border:
                                                                    Border.all(
                                                                  color: kSecondaryColor
                                                                      .withValues(
                                                                          alpha:
                                                                              0.1),
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  getProportionateScreenWidth(
                                                                      kDefaultPadding /
                                                                          2),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    size: 18,
                                                                    Icons
                                                                        .add_shopping_cart_outlined,
                                                                    color:
                                                                        kSecondaryColor,
                                                                  ),
                                                                  Text(
                                                                    "Add",
                                                                    // "${Provider.of<ZLanguage>(context).addToCart} >>",
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color:
                                                                          kSecondaryColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ],
                            );
                          },
                        ),
                      )
                    : !_loading
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(
                                  kDefaultPadding * 4),
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding * 4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomButton(
                                  title: "Retry",
                                  press: () {
                                    _getStoreProductList();
                                  },
                                  color: kSecondaryColor,
                                ),
                              ],
                            ),
                          )
                        : Container(),
                // !_loading && (cart != null && cart!.items!.length > 0)
                //     ? Padding(
                //         padding: EdgeInsets.only(
                //           left: getProportionateScreenWidth(kDefaultPadding),
                //           right: getProportionateScreenWidth(kDefaultPadding),
                //           bottom: getProportionateScreenWidth(kDefaultPadding),
                //         ),
                //         child: CustomButton(
                //           title: "Go to Cart",
                //           press: () {
                //             Navigator.pushNamed(context, '/cart')
                //                 .then((value) => getCart());
                //           },
                //           color: kSecondaryColor,
                //         ),
                //       )
                //     : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> getStoreProductList() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_get_store_product_item_list";
    Map data = {
      "store_id": widget.storeId,
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
            Service.showMessage1("Something went wrong!", true, duration: 3),
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.responseData = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
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
            backgroundColor: kPrimaryColor,
            title: Text("Warning"),
            content: Text(
                "Item(s) from a different store found in cart! Would you like to clear your cart?"),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
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
                  "Clear",
                  style: TextStyle(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    cart!.toJson();
                    Service.remove('cart');
                    Service.remove('aliexpressCart');
                    cart = Cart();
                    addToCart(item, destination, storeLocation, storeId);
                  });

                  Navigator.of(alertContext).pop();
                  // Future.delayed(Duration(seconds: 2));
                  // Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
