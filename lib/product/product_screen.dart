import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/cart/cart_screen.dart';
import 'package:zmall/comments/review_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';
import 'components/store_header.dart';

class ProductScreen extends StatefulWidget {
  static String routeName = "/product";

  const ProductScreen({
    Key? key,
    @required this.store,
    @required this.location,
    @required this.isOpen,
    @required this.longitude,
    @required this.latitude,
  }) : super(key: key);

  final store;
  final location;
  final bool? isOpen;
  final double? longitude;
  final double? latitude;

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _loading = true;
  var responseData;
  var favoriteResponseData;
  var products;
  var price = [];
  Cart? cart;
  TextEditingController controller = TextEditingController();
  TextEditingController customPriceController = TextEditingController();
  List<dynamic> _searchResult = [];
  bool isLoggedIn = false;
  var userData;
  bool isFavorite = false;
  String loadingMessage = "Loading...";

  double? longitude, latitude;
  List<Specification> specification = [];

  String dropDownValue = "Lower than:";

  var items = [
    "Lower than:",
    "Greater than:",
  ];

  @override
  void initState() {
    super.initState();
    isLogged();
    getCart();
    _getStoreProductList();
  }

  void checkFavorite() {
    if (userData != null) {
      bool isFav =
          userData['user']['favourite_stores'].contains(widget.store['_id']);
      setState(() {
        isFavorite = isFav;
      });
    }
  }

  Future<void> _onRefresh() async {
    isLogged();
    getCart();
    _getStoreProductList();
  }

  void getCart() async {
    print("Fetching data");
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
      print("No logged user found");
    }
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      checkFavorite();
    }
    var long = await Service.read('longitude');
    var lat = await Service.read('latitude');
    if (long != null && lat != null) {
      setState(() {
        latitude = lat;
        longitude = long;
      });
    }
  }

  void _getStoreProductList() async {
    setState(() {
      _loading = true;
    });
    await getStoreProductList();

    if (responseData != null && responseData['success']) {
      products = responseData['products'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${errorCodes['${responseData['error_code']}']}"),
        ),
      );
    }
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

  void addToFavorites() async {
    setState(() {
      _loading = true;
    });
    await _addToFavorite(userData['user']['_id'], widget.store['_id'],
        userData['user']['server_token']);
    if (favoriteResponseData != null && favoriteResponseData['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Added to favorite",
        ),
        backgroundColor: kGreyColor,
      ));
      userData['user']['favourite_stores'].add(widget.store['_id']);
      await Service.save('user', userData);
      checkFavorite();
      setState(() {
        _loading = false;
      });
      reSaveFavorites();
    } else {
      if (responseData['error_code'] != null &&
          favoriteResponseData['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        // Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${errorCodes['${favoriteResponseData['error_code']}']}"),
        backgroundColor: kSecondaryColor,
      ));
    }
  }

  void reSaveFavorites() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_favourite_store_list";
    Map data = {
      "user_id": userData['user']['_id'],
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      var val = json.decode(response.body);
      if (val['success']) {
        await Service.save("user_favorite_stores", val);
      }
    } catch (e) {
      // print(e);
      return null;
    }
  }

  void removeFavorites() async {
    setState(() {
      _loading = true;
    });
    await _removeFavorite(userData['user']['_id'], widget.store['_id'],
        userData['user']['server_token']);
    if (favoriteResponseData != null && favoriteResponseData['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Store removed from favorites",
          style: TextStyle(color: kBlackColor),
        ),
        backgroundColor: kSecondaryColor,
      ));
      userData['user']['favourite_stores']
          .removeWhere((item) => item == widget.store['_id']);
      await Service.save('user', userData);
      checkFavorite();
      setState(() {
        _loading = false;
      });
      reSaveFavorites();
    } else {
      if (responseData['error_code'] != null &&
          favoriteResponseData['error_code'] == 999) {
        // print('Server token expired please log user out');
        await Service.saveBool('logged', false);
        await Service.remove('user');
        // Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${errorCodes['${favoriteResponseData['error_code']}']}"),
        backgroundColor: kSecondaryColor,
      ));
    }
  }

  // ignore: missing_return
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Service.capitalizeFirstLetters(widget.store['name']),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: kBlackColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0.0,
        backgroundColor: kPrimaryColor,
        actions: [
          // InkWell(
          //   onTap: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //         builder: (context) => StoreMapView(
          //               isOpen: [widget.isOpen],
          //               categoryTitle: {"delivery_name": widget.store['name']},
          //               stores: [widget.store],
          //               cityId: "",
          //               storeDeliveryId: "",
          //               isFromProduct: true,
          //             )));
          //   },
          //   borderRadius: BorderRadius.circular(
          //     getProportionateScreenWidth(kDefaultPadding * 2.5),
          //   ),
          //   child: Padding(
          //     padding: EdgeInsets.symmetric(
          //       vertical: getProportionateScreenWidth(kDefaultPadding * .75),
          //       horizontal: getProportionateScreenWidth(kDefaultPadding / 4),
          //     ),
          //     child: Icon(
          //       Icons.navigation,
          //       // color: kSecondaryColor,
          //     ),
          //   ),
          // ),
          // userData != null
          //     ? InkWell(
          //         onTap: () {
          //           isFavorite ? removeFavorites() : addToFavorites();
          //         },
          //         borderRadius: BorderRadius.circular(
          //           getProportionateScreenWidth(kDefaultPadding * 2.5),
          //         ),
          //         child: Padding(
          //           padding: EdgeInsets.symmetric(
          //             vertical:
          //                 getProportionateScreenWidth(kDefaultPadding * .75),
          //             horizontal:
          //                 getProportionateScreenWidth(kDefaultPadding / 4),
          //           ),
          //           child: Icon(
          //             isFavorite ? Icons.favorite : Icons.favorite_border,
          //             color: isFavorite ? kSecondaryColor : Colors.black,
          //           ),
          //         ),
          //       )
          //     : Container(),
          InkWell(
            onTap: () async {
              // Check if user is logged in and pass store id and user id
              var userData = await Service.getUser();
              if (userData != null) {
                goToReviews();
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => CommentsScreen(
                //         userId: userData['user']['id'],
                //         storeId: widget.store['_id']),
                //   ),
                // );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
                    "Please login to check the reviews for ${widget.store['name']}",
                    true));
              }
//              Navigator.pushNamed(context, '/cart').then((value) => getCart());
            },
            borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding * 2.5),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: getProportionateScreenWidth(kDefaultPadding * .75),
                horizontal: getProportionateScreenWidth(kDefaultPadding / 4),
              ),
              child: Icon(Icons.comment_outlined),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, CartScreen.routeName)
                  .then((value) => getCart());
            },
            borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding * 2.5),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: getProportionateScreenWidth(kDefaultPadding * .75),
                    right: getProportionateScreenWidth(kDefaultPadding * .15),
                    top: getProportionateScreenWidth(kDefaultPadding * .75),
                    bottom: getProportionateScreenWidth(kDefaultPadding * .75),
                  ),
                  child: Icon(Icons.add_shopping_cart_rounded),
                ),
                Positioned(
                  left: 0,
                  top: 5,
                  child: Container(
                    height: getProportionateScreenWidth(kDefaultPadding * .9),
                    width: getProportionateScreenWidth(kDefaultPadding * .9),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(width: 1.5, color: kWhiteColor),
                    ),
                    child: Center(
                      child: Text(
                        cart != null ? "${cart!.items!.length}" : "0",
                        style: TextStyle(
                          fontSize:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                          height: 1,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          PopupMenuButton<int>(
            tooltip: "Price Filters",
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                    ),
                    SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding * 0.4),
                    ),
                    Text(
                      "Price: Lowest to Highest",
                    ),
                  ],
                ),
                value: 0,
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                    ),
                    SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding * 0.4),
                    ),
                    Text(
                      "Price: Highest to Lowest",
                    ),
                  ],
                ),
                value: 1,
              ),
              // PopupMenuDivider(),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_suggest,
                    ),
                    SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding * 0.4),
                    ),
                    Text(
                      "Custom Price Filter",
                    ),
                  ],
                ),
                value: 2,
              ),
              PopupMenuDivider(),
              // PopupMenuItem(
              //   child: Row(
              //     children: [
              //       Icon(
              //         Icons.comment_outlined,
              //         // color: kSecondaryColor,
              //       ),
              //       SizedBox(
              //         width: getProportionateScreenWidth(kDefaultPadding * 0.4),
              //       ),
              //       Text(
              //         "Store reviews",
              //       ),
              //     ],
              //   ),
              //   value: 4,
              // ),
              // PopupMenuItem(
              //   child: Row(
              //     children: [
              //       Icon(
              //         Icons.navigation,
              //         // color: kSecondaryColor,
              //       ),
              //       SizedBox(
              //         width: getProportionateScreenWidth(kDefaultPadding * 0.4),
              //       ),
              //       Text(
              //         "Navigate to store",
              //       ),
              //     ],
              //   ),
              //   value: 3,
              // ),
            ],
            onSelected: (item) => popUpMenuClicked(context, item),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: kSecondaryColor,
        onRefresh: _onRefresh,
        child: ModalProgressHUD(
          inAsyncCall: _loading,
          color: kPrimaryColor,
          progressIndicator: linearProgressIndicator,
          child: Column(
            children: [
              Container(
                color: kPrimaryColor,
                child: Container(
                  margin: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(kDefaultPadding),
                  ),

                  decoration: BoxDecoration(
                      color: kPrimaryColor,
                      border: Border.all(color: kWhiteColor, width: 2),
                      borderRadius: BorderRadius.circular(kDefaultPadding * 2)),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.search),
                      SizedBox(
                          width: getProportionateScreenWidth(kDefaultPadding)),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: Provider.of<ZLanguage>(context).search,
                            border: InputBorder.none,
                            // prefixIcon: Icon(Icons.search),
                            // suffixIcon: controller.text.isNotEmpty
                            //     ? IconButton(
                            //         icon: Icon(Icons.cancel),
                            //         onPressed: () {
                            //           controller.clear();
                            //           onSearchTextChanged('');
                            //           setState(
                            //             () {
                            //               storeOpen(stores);
                            //             },
                            //           );
                            //         },
                            //       )
                            //     : null,
                          ),
                          onChanged: onSearchTextChanged,
                        ),
                      ),
                      if (controller.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            controller.clear();
                            onSearchTextChanged('');
                          },
                        ),
                    ],
                  ),
                  // ),
                ),
              ),
              // Container(
              //   color: kPrimaryColor,
              //   child: Card(
              //     elevation: 0.1,
              //     child: TextField(
              //       controller: controller,
              //       decoration: InputDecoration(
              //         hintText: Provider.of<ZLanguage>(context).search,
              //         border: InputBorder.none,
              //         prefixIcon: Icon(Icons.search),
              //         suffixIcon: controller.text.isNotEmpty
              //             ? IconButton(
              //                 icon: Icon(Icons.cancel),
              //                 onPressed: () {
              //                   controller.clear();
              //                   onSearchTextChanged('');
              //                 },
              //               )
              //             : null,
              //       ),
              //       onChanged: onSearchTextChanged,
              //     ),
              //   ),
              // ),
              StoreHeader(
                storeName: widget.store['name'],
                distance: widget.store['distance'] != null
                    ? widget.store['distance'].toStringAsFixed(2)
                    : "",
                imageUrl:
                    "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.store['image_url']}",
                rating: widget.store['user_rate'].toString(),
                ratingCount: widget.store['user_rate_count'].toString(),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 4),
              ),
              _searchResult.length != 0 || controller.text.isNotEmpty
                  ? Expanded(
                      child: ListView.separated(
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _searchResult.length,
                        itemBuilder: (BuildContext context, int index) {
                          return InkWell(
                            onTap: () async {
                              if (isLoggedIn) {
                                productClicked(_searchResult[index]['_id']);
                              }

                              widget.isOpen!
                                  ? Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return ItemScreen(
                                            item: _searchResult[index],
                                            location: widget.location,
                                          );
                                        },
                                      ),
                                    ).then((value) => getCart())
                                  : ScaffoldMessenger.of(context).showSnackBar(
                                      Service.showMessage(
                                          "Sorry the store is closed at this time!",
                                          true));
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                // borderRadius:
                                //     BorderRadius.circular(kDefaultPadding),
                              ),
                              // padding: EdgeInsets.symmetric(
                              //     vertical: getProportionateScreenHeight(
                              //         kDefaultPadding / 10),
                              //     horizontal: getProportionateScreenWidth(
                              //         kDefaultPadding / 3),
                              //     ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 8.0, top: 10.0, bottom: 10.0),
                                child: Row(
                                  children: [
                                    _searchResult[index]['image_url'].length > 0
                                        ? ImageContainer(
                                            url:
                                                "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${_searchResult[index]['image_url'][0]}",
                                          )
                                        : ImageContainer(
                                            url: "https://ibb.co/vkhzjd6"),
                                    SizedBox(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding / 2)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Service.capitalizeFirstLetters(
                                                _searchResult[index]['name']),
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * .9),
                                              fontWeight: FontWeight.bold,
                                              color: kBlackColor,
                                            ),
                                            softWrap: true,
                                          ),
                                          SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding / 5)),
                                          _searchResult[index]['details'] !=
                                                      null &&
                                                  _searchResult[index]
                                                              ['details']
                                                          .length >
                                                      0
                                              ? Text(
                                                  _searchResult[index]
                                                      ['details'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: kGreyColor,
                                                      ),
                                                )
                                              : SizedBox(height: 0.5),
                                          SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding / 5)),
                                          Text(
                                            "${_getPrice(_searchResult[index]) != null ? _getPrice(_searchResult[index]) : 0} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: kBlackColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            SizedBox(
                          height: 1,
                        ),
                      ),
                    )
                  : products != null
                      ? Expanded(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: products.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ExpansionTile(
                                textColor: kBlackColor,
                                collapsedBackgroundColor: kPrimaryColor,
                                backgroundColor: kPrimaryColor,
                                leading: const Icon(
                                  Icons.dining,
                                  size: kDefaultPadding,
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
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                children: [
                                  ListView.separated(
                                    physics: ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: products[index]['items'].length,
                                    itemBuilder:
                                        (BuildContext context, int idx) {
                                      return GestureDetector(
                                        onTap: () async {
                                          if (isLoggedIn) {
                                            productClicked(products[index]
                                                ['items'][idx]['_id']);
                                          }

                                          widget.isOpen!
                                              ? Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) {
                                                      return ItemScreen(
                                                        item: products[index]
                                                            ['items'][idx],
                                                        location:
                                                            widget.location,
                                                      );
                                                    },
                                                  ),
                                                ).then((value) => getCart())
                                              : ScaffoldMessenger.of(context)
                                                  .showSnackBar(Service.showMessage(
                                                      "Sorry the store is closed at this time!",
                                                      true));
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: kPrimaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        kDefaultPadding),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical:
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding / 10),
                                                // horizontal:
                                                //     getProportionateScreenWidth(
                                                //         kDefaultPadding / 4),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          Service.capitalizeFirstLetters(
                                                              products[index]
                                                                      ['items'][
                                                                  idx]['name']),
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
                                                            height: getProportionateScreenHeight(
                                                                kDefaultPadding /
                                                                    5)),
                                                        products[index]['items']
                                                                            [
                                                                            idx]
                                                                        [
                                                                        'details'] !=
                                                                    null &&
                                                                products[index]['items'][idx]
                                                                            [
                                                                            'details']
                                                                        .length >
                                                                    0
                                                            ? Text(
                                                                products[index][
                                                                            'items']
                                                                        [idx]
                                                                    ['details'],
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
                                                        Text(
                                                          "${_getPrice(products[index]['items'][idx]) != null ? _getPrice(products[index]['items'][idx]) : 0} ${Provider.of<ZMetaData>(context, listen: false).currency}",
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
                                                        SizedBox(
                                                            height: getProportionateScreenHeight(
                                                                kDefaultPadding /
                                                                    5)),
                                                        GestureDetector(
                                                          onTap: () async {
                                                            if (widget
                                                                .isOpen!) {
                                                              if (products[index]['items']
                                                                              [
                                                                              idx]
                                                                          [
                                                                          'specifications']
                                                                      .length >
                                                                  0) {
                                                                if (isLoggedIn) {
                                                                  productClicked(
                                                                      products[index]
                                                                              [
                                                                              'items'][idx]
                                                                          [
                                                                          '_id']);
                                                                }

                                                                widget.isOpen!
                                                                    ? Navigator
                                                                        .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder:
                                                                              (context) {
                                                                            return ItemScreen(
                                                                              item: products[index]['items'][idx],
                                                                              location: widget.location,
                                                                            );
                                                                          },
                                                                        ),
                                                                      ).then(
                                                                        (value) =>
                                                                            getCart())
                                                                    : ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(Service.showMessage(
                                                                            "Sorry the store is closed at this time!",
                                                                            true));
                                                              } else {
                                                                // TODO: Add to cart.....

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
                                                                              idx]) !=
                                                                          null
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
                                                                        long: widget.location[
                                                                            1],
                                                                        lat: widget
                                                                            .location[0]);
                                                                DestinationAddress
                                                                    destination =
                                                                    DestinationAddress(
                                                                  long: Provider.of<
                                                                              ZMetaData>(
                                                                          context,
                                                                          listen:
                                                                              false)
                                                                      .longitude,
                                                                  lat: Provider.of<
                                                                              ZMetaData>(
                                                                          context,
                                                                          listen:
                                                                              false)
                                                                      .latitude,
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
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          Service.showMessage(
                                                                              "Item added to cart",
                                                                              false),
                                                                        );
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
                                                                    print(
                                                                        "User not logged in...");
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(Service.showMessage(
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
                                                                    print(
                                                                        "Empty cart! Adding new item.");
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
                                                                    print(
                                                                        "User not logged in...");
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(Service.showMessage(
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
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      Service.showMessage(
                                                                          "Sorry the store is closed at this time!",
                                                                          true));
                                                            }
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  kBlackColor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                getProportionateScreenWidth(
                                                                    kDefaultPadding /
                                                                        3),
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                getProportionateScreenWidth(
                                                                    kDefaultPadding /
                                                                        4),
                                                              ),
                                                              child: Text(
                                                                "${Provider.of<ZLanguage>(context).addToCart} >>",
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                      color:
                                                                          kPrimaryColor,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  products[index]['items'][idx]
                                                                  ['image_url']
                                                              .length >
                                                          0
                                                      ? ImageContainer(
                                                          url:
                                                              "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${products[index]['items'][idx]['image_url'][0]}",
                                                        )
                                                      : Container(),
                                                  // : ImageContainer(
                                                  //     url:
                                                  //         "https://ibb.co/vkhzjd6"),
                                                  SizedBox(
                                                      width:
                                                          getProportionateScreenWidth(
                                                              kDefaultPadding /
                                                                  4)),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 0.8),
                                            ),
                                            Container(
                                              height: 0.1,
                                              width: double.infinity,
                                              color: kGreyColor.withValues(
                                                  alpha: 0.5),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            SizedBox(
                                      height: getProportionateScreenHeight(
                                          kDefaultPadding / 4),
                                    ),
                                  )
                                ],
                              );
                              //   Padding(
                              //   padding: EdgeInsets.symmetric(
                              //     horizontal: getProportionateScreenWidth(
                              //         kDefaultPadding / 3),
                              //     vertical: getProportionateScreenHeight(
                              //         kDefaultPadding / 4),
                              //   ),
                              //   child: Column(
                              //     children: [
                              //       CategoryContainer(
                              //         title: "${products[index]["_id"]["name"]}",
                              //       ),
                              //       SizedBox(
                              //         height: getProportionateScreenHeight(
                              //             kDefaultPadding / 4),
                              //       ),
                              //       ListView.separated(
                              //         physics: ClampingScrollPhysics(),
                              //         shrinkWrap: true,
                              //         itemCount: products[index]['items'].length,
                              //         itemBuilder:
                              //             (BuildContext context, int idx) {
                              //           return TextButton(
                              //             onPressed: () async {
                              //               if (isLoggedIn) {
                              //                 productClicked(products[index]
                              //                     ['items'][idx]['_id']);
                              //               }
                              //
                              //               widget.isOpen
                              //                   ? Navigator.push(
                              //                       context,
                              //                       MaterialPageRoute(
                              //                         builder: (context) {
                              //                           return ItemScreen(
                              //                             item: products[index]
                              //                                 ['items'][idx],
                              //                             location:
                              //                                 widget.location,
                              //                           );
                              //                         },
                              //                       ),
                              //                     ).then((value) => getCart())
                              //                   : ScaffoldMessenger.of(context)
                              //                       .showSnackBar(Service.showMessage(
                              //                           "Sorry the store is closed at this time!",
                              //                           true));
                              //             },
                              //             child: Container(
                              //               width: double.infinity,
                              //               decoration: BoxDecoration(
                              //                 color: kPrimaryColor,
                              //                 borderRadius: BorderRadius.circular(
                              //                     kDefaultPadding),
                              //               ),
                              //               padding: EdgeInsets.symmetric(
                              //                 vertical:
                              //                     getProportionateScreenHeight(
                              //                         kDefaultPadding / 10),
                              //                 horizontal:
                              //                     getProportionateScreenWidth(
                              //                         kDefaultPadding / 3),
                              //               ),
                              //               child: Row(
                              //                 children: [
                              //                   products[index]['items'][idx]
                              //                                   ['image_url']
                              //                               .length >
                              //                           0
                              //                       ? ImageContainer(
                              //                           url:
                              //                               "https://app.zmallapp.com/${products[index]['items'][idx]['image_url'][0]}",
                              //                         )
                              //                       : ImageContainer(
                              //                           url:
                              //                               "https://ibb.co/vkhzjd6"),
                              //                   SizedBox(
                              //                       width:
                              //                           getProportionateScreenWidth(
                              //                               kDefaultPadding / 4)),
                              //                   Expanded(
                              //                     child: Column(
                              //                       crossAxisAlignment:
                              //                           CrossAxisAlignment.start,
                              //                       children: [
                              //                         Text(
                              //                           products[index]['items']
                              //                               [idx]['name'],
                              //                           style: Theme.of(context)
                              //                               .textTheme
                              //                               .subtitle1
                              //                               ?.copyWith(
                              //                                 fontWeight:
                              //                                     FontWeight.bold,
                              //                               ),
                              //                           softWrap: true,
                              //                         ),
                              //                         SizedBox(
                              //                             height:
                              //                                 getProportionateScreenHeight(
                              //                                     kDefaultPadding /
                              //                                         5)),
                              //                         products[index]['items']
                              //                                             [idx][
                              //                                         'details'] !=
                              //                                     null &&
                              //                                 products[index]['items']
                              //                                                 [
                              //                                                 idx]
                              //                                             [
                              //                                             'details']
                              //                                         .length >
                              //                                     0
                              //                             ? Text(
                              //                                 products[index]
                              //                                         ['items'][
                              //                                     idx]['details'],
                              //                                 style: Theme.of(
                              //                                         context)
                              //                                     .textTheme
                              //                                     .bodySmall
                              //                                     ?.copyWith(
                              //                                       color:
                              //                                           kGreyColor,
                              //                                     ),
                              //                               )
                              //                             : SizedBox(height: 0.5),
                              //                         SizedBox(
                              //                             height:
                              //                                 getProportionateScreenHeight(
                              //                                     kDefaultPadding /
                              //                                         5)),
                              //                         Text(
                              //                           "${_getPrice(products[index]['items'][idx]) != null ? _getPrice(products[index]['items'][idx]) : 0} Birr",
                              //                           style: Theme.of(context)
                              //                               .textTheme
                              //                               .subtitle2
                              //                               ?.copyWith(
                              //                                 color:
                              //                                     kSecondaryColor,
                              //                                 fontWeight:
                              //                                     FontWeight.bold,
                              //                               ),
                              //                         ),
                              //                       ],
                              //                     ),
                              //                   )
                              //                 ],
                              //               ),
                              //             ),
                              //           );
                              //         },
                              //         separatorBuilder:
                              //             (BuildContext context, int index) =>
                              //                 SizedBox(
                              //           height: getProportionateScreenHeight(
                              //               kDefaultPadding / 4),
                              //         ),
                              //       )
                              //     ],
                              //   ),
                              // );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(
                              height: 1,
                            ),
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
              cart != null && cart!.items!.length > 0
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: getProportionateScreenWidth(kDefaultPadding),
                        right: getProportionateScreenWidth(kDefaultPadding),
                        bottom: getProportionateScreenWidth(kDefaultPadding),
                      ),
                      child: CustomButton(
                        title: Provider.of<ZLanguage>(context).goToCart,
                        press: () {
                          Navigator.pushNamed(context, CartScreen.routeName)
                              .then((value) => getCart());
                        },
                        color: kSecondaryColor,
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }
    for (var i = 0; i < products.length; i++) {
      for (var j = 0; j < products[i]['items'].length; j++)
        if (products[i]['items'][j]['name']
            .toString()
            .toLowerCase()
            .contains(text.toLowerCase())) {
          _searchResult.add(products[i]['items'][j]);
        }
    }
    setState(() {});
  }

  popUpMenuClicked(BuildContext context, int val) {
    if (!_loading && products != null) {
      List textValues = [
        "Price: Lowest to Highest",
        "Price: Highest to Lowest",
        "Price: Custom",
      ];
      List list = [];
      if (_searchResult.isNotEmpty) {
        list = _searchResult;
      } else {
        for (var i = 0; i < products.length; i++) {
          list += products[i]['items'];
        }
      }
      switch (val) {
        case 0:
          doMerge(list, 1);
          _searchResult = list;
          controller.text = textValues[val];
          setState(() {});
          break;
        case 1:
          doMerge(list, 2);
          _searchResult = list;
          controller.text = textValues[val];
          setState(() {});
          break;
        case 2:
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  backgroundColor: kPrimaryColor,
                  title: Text("Custom Price Filter"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          DropdownButton(
                            items: items.map((String item) {
                              return DropdownMenuItem(
                                child: Text(item),
                                value: item,
                              );
                            }).toList(),
                            onChanged: (String? val) {
                              setState(() {
                                dropDownValue = val!;
                              });
                            },
                            value: dropDownValue,
                          ),
                          SizedBox(
                            width: getProportionateScreenWidth(
                                kDefaultPadding / 3),
                          ),
                          Container(
                            width: getProportionateScreenWidth(
                                kDefaultPadding * 6),
                            child: TextField(
                              controller: customPriceController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: InputDecoration(
                                label: Text("Price value"),
                                hintText: 'Price value',
                                // prefixIcon: Icon(Icons.filter_alt),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text(
                        Provider.of<ZLanguage>(context).cancel,
                        style: TextStyle(color: kBlackColor),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text(
                        Provider.of<ZLanguage>(context).submit,
                        style: TextStyle(
                          color: kSecondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        if (customPriceController.text.isNotEmpty &&
                            customPriceController.text.length > 1) {
                          try {
                            double price =
                                double.parse(customPriceController.text);
                            customFilter(list, price);
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Invalid price value"),
                                backgroundColor: kSecondaryColor,
                              ),
                            );
                            // print(e);
                            // print(st);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Price value should be greater than 10 ${Provider.of<ZMetaData>(context, listen: false).currency}"),
                              backgroundColor: kSecondaryColor,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              });
            },
          );
          break;
        // case 3:
        //   Navigator.of(context).push(MaterialPageRoute(
        //       builder: (context) => StoreMapView(
        //             isOpen: [widget.isOpen],
        //             categoryTitle: {"delivery_name": widget.store['name']},
        //             stores: [widget.store],
        //             cityId: "",
        //             storeDeliveryId: "",
        //             isFromProduct: true,
        //           )));
        //   break;
        // case 4:
        //   goToReviews();
        //   break;
      }
    }
  }

  void goToReviews() async {
    var userData = await Service.getUser();
    if (userData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommentsScreen(
            userId: userData['user']['_id'],
            storeId: widget.store['_id'],
            serverToken: userData['user']['server_token'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Please login to check the reviews for ${widget.store['name']}",
          true));
    }
  }

  void customFilter(List list, double price) {
    List filteredList = [];
    for (int i = 0; i < list.length; i++) {
      var valPrice = _getPrice(list[i]) != null ? _getPrice(list[i]) : 0;
      if (dropDownValue.contains("Lower")) {
        if (double.parse(valPrice.toString()) <= price) {
          filteredList.add(list[i]);
        }
      } else {
        if (double.parse(valPrice.toString()) >= price) {
          filteredList.add(list[i]);
        }
      }
    }
    _searchResult = filteredList;
    controller.text =
        "$dropDownValue ${price}0 ${Provider.of<ZMetaData>(context, listen: false).currency}";
    setState(() {});
  }

  void merge(arr, l, m, r, int sortType) {
    var n1 = m - l + 1;
    var n2 = r - m;

    var L = List.filled(n1, {});
    var R = List.filled(n2, {});
    for (int i = 0; i < n1; i++) L[i] = arr[l + i];
    for (int j = 0; j < n2; j++) R[j] = arr[m + 1 + j];

    var i = 0;
    var j = 0;
    var k = l;

    while (i < n1 && j < n2) {
      var lPrice = _getPrice(L[i]) != null ? _getPrice(L[i]) : 0;
      var rPrice = _getPrice(R[j]) != null ? _getPrice(R[j]) : 0;

      if (sortType == 1) {
        if (double.parse(lPrice.toString()) <=
            double.parse(rPrice.toString())) {
          arr[k] = L[i];
          i++;
        } else {
          arr[k] = R[j];
          j++;
        }
      } else {
        if (double.parse(lPrice.toString()) >=
            double.parse(rPrice.toString())) {
          arr[k] = L[i];
          i++;
        } else {
          arr[k] = R[j];
          j++;
        }
      }
      k++;
    }
    while (i < n1) {
      arr[k] = L[i];
      i++;
      k++;
    }
    while (j < n2) {
      arr[k] = R[j];
      j++;
      k++;
    }
  }

  void mergeSort(arr, l, r, int sortType) {
    if (l >= r) {
      return;
    }
    int m = l + ((r - l) ~/ 2);
    mergeSort(arr, l, m, sortType);
    mergeSort(arr, m + 1, r, sortType);
    merge(arr, l, m, r, sortType);
  }

  void doMerge(List list, int sortType) {
    mergeSort(list, 0, list.length - 1, sortType);
  }

  void printList(List list) {
    List p = [];
    for (int i = 0; i < list.length; i++) {
      p.add({"name": list[i]["name"], "price": list[i]['price']});
    }
    // print(p);
  }

  Future<dynamic> getStoreProductList() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_get_store_product_item_list";
    Map data = {
      "store_id": widget.store['_id'],
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
        this.responseData = json.decode(response.body);
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

  void productClicked(String productId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/add_user_and_store";
    Map data = {
      "store_id": widget.store['_id'],
      "product_id": productId,
      "user_id": userData['user']['_id'],
      "latitude": widget.latitude,
      "longitude": widget.longitude,
      "is_promotional": false
    };
    var body = json.encode(data);
    try {
      http.Response response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      );
    } catch (e) {
      // print(e);
    }
  }

  Future<dynamic> _addToFavorite(
      var userId, var storeId, var serverToken) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_favourite_store";
    Map data = {
      "user_id": userId,
      "store_id": storeId,
      "server_token": serverToken
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
          .timeout(Duration(seconds: 10), onTimeout: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(Service.showMessage("Network error", true));
        setState(() {
          _loading = false;
        });
        throw TimeoutException("The connection has timed out!");
      });
      favoriteResponseData = json.decode(response.body);
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Future<dynamic> _removeFavorite(
      var userId, var storeId, var serverToken) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/remove_favourite_store";
    Map data = {
      "user_id": userId,
      "store_id": [storeId],
      "server_token": serverToken
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
          .timeout(Duration(seconds: 10), onTimeout: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(Service.showMessage("Network error", true));
        setState(() {
          _loading = false;
        });
        throw TimeoutException("The connection has timed out!");
      });
      favoriteResponseData = json.decode(response.body);
      return json.decode(response.body);
    } catch (e) {
      // print(e);
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

class CategoryContainer extends StatelessWidget {
  const CategoryContainer({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBlackColor.withValues(alpha: 0.3)),
        // color: kPrimaryColor,
        borderRadius: BorderRadius.circular(
          getProportionateScreenWidth(kDefaultPadding / 2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          getProportionateScreenWidth(kDefaultPadding / 2.5),
        ),
        child: Text(
          title,
          style: TextStyle(color: kBlackColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
