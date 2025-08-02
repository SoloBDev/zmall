import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/comments/review_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/cart/global_cart.dart';
import 'package:zmall/global/items/global_items.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class GlobalProduct extends StatefulWidget {
  static String routeName = "/product";

  const GlobalProduct({
    Key? key,
    required this.store,
    required this.location,
    required this.isOpen,
    required this.longitude,
    required this.latitude,
  }) : super(key: key);

  final store;
  final location;
  final bool isOpen;
  final double longitude;
  final double latitude;

  @override
  _GlobalProductState createState() => _GlobalProductState();
}

class _GlobalProductState extends State<GlobalProduct> {
  bool _loading = true;
  var responseData;
  var products;
  var price = [];
  AbroadCart? cart;
  TextEditingController controller = TextEditingController();
  List<dynamic> _searchResult = [];
  bool isLoggedIn = false;
  var userData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // isLogged();
    getCart();
    _getStoreProductList();
  }

  void getCart() async {
    debugPrint("Fetching data");
    var data = await Service.read('abroad_cart');

    if (data != null) {
      // debugPrint(data);
      setState(() {
        cart = AbroadCart.fromJson(data);
      });
    }
  }

  // void isLogged() async {
  //   var data = await Service.readBool('logged');
  //   if (data != null) {
  //     debugPrint("Logged in: $data");
  //     setState(() {
  //       isLoggedIn = data;
  //     });
  //     getUser();
  //   } else {
  //     debugPrint("No logged user found");
  //   }
  // }

  // void getUser() async {
  //   var data = await Service.read('user');
  //   if (data != null) {
  //     setState(() {
  //       userData = data;
  //     });
  //   }
  // }

  void _getStoreProductList() async {
    await getStoreProductList();
    // debugPrint(responseData);
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
          widget.store['name'],
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 0.0,
        backgroundColor: kPrimaryColor,
        actions: [
          InkWell(
            onTap: () async {
              debugPrint(
                  "=======================COMMENTS=======================");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommentsScreen(
                    userId: "5e2c19606d5f9e6f08626e9e",
                    storeId: widget.store['_id'],
                    serverToken: "",
                    isLocal: false,
                  ),
                ),
              );
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return GlobalCart();
                  },
                ),
              ).then((value) => getCart());
            },
            borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding * 2.5),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding * .75),
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
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        color: kPrimaryColor,
        progressIndicator: linearProgressIndicator,
        child: Column(
          children: [
            Container(
              color: kPrimaryColor,
              child: Card(
                  elevation: 0.3,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.cancel),
                              onPressed: () {
                                controller.clear();
                                onSearchTextChanged('');
                              },
                            )
                          : null,
                    ),
                    onChanged: onSearchTextChanged,
                  )),
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 5),
            ),
            _searchResult.length != 0 || controller.text.isNotEmpty
                ? Expanded(
                    child: ListView.separated(
                      physics: ClampingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _searchResult.length,
                      itemBuilder: (BuildContext context, int index) {
                        return TextButton(
                          onPressed: () async {
                            productClicked(_searchResult[index]['_id']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return GlobalItem(
                                    isOpen: widget.isOpen,
                                    item: _searchResult[index],
                                    location: widget.location,
                                  );
                                },
                              ),
                            ).then((value) => getCart());
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius:
                                  BorderRadius.circular(kDefaultPadding),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 10),
                              horizontal: getProportionateScreenWidth(
                                  kDefaultPadding / 3),
                            ),
                            child: Row(
                              children: [
                                _searchResult[index]['image_url'].length > 0
                                    ? ImageContainer(
                                        url:
                                            "https://app.zmallapp.com/${_searchResult[index]['image_url'][0]}",
                                        // "http://159.65.147.111:8000/${_searchResult[index]['image_url'][0]}",
                                      )
                                    : ImageContainer(
                                        url: "https://ibb.co/vkhzjd6"),
                                SizedBox(
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding / 4)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _searchResult[index]['name'],
                                        style: TextStyle(
                                          fontSize: getProportionateScreenWidth(
                                              kDefaultPadding / 1.5),
                                          fontWeight: FontWeight.bold,
                                          color: kBlackColor,
                                        ),
                                        softWrap: true,
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 5)),
                                      _searchResult[index]['details'] != null &&
                                              _searchResult[index]['details']
                                                      .length >
                                                  0
                                          ? Text(
                                              _searchResult[index]['details'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                    color: kGreyColor,
                                                  ),
                                            )
                                          : SizedBox(height: 0.5),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 5)),
                                      Text(
                                        "${_getPrice(_searchResult[index]) != null ? _getPrice(_searchResult[index]) : 0} Birr",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                              color: kSecondaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 4),
                      ),
                    ),
                  )
                : products != null
                    ? Expanded(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: products.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding / 3),
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 4),
                              ),
                              child: Column(
                                children: [
                                  CategoryContainer(
                                    title: "${products[index]["_id"]["name"]}",
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 4),
                                  ),
                                  ListView.separated(
                                    physics: ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: products[index]['items'].length,
                                    itemBuilder:
                                        (BuildContext context, int idx) {
                                      return TextButton(
                                        onPressed: () async {
                                          productClicked(products[index]
                                              ['items'][idx]['_id']);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return GlobalItem(
                                                  isOpen: widget.isOpen,
                                                  item: products[index]['items']
                                                      [idx],
                                                  location: widget.location,
                                                );
                                              },
                                            ),
                                          ).then((value) => getCart());
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor,
                                            borderRadius: BorderRadius.circular(
                                                kDefaultPadding),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 10),
                                            horizontal:
                                                getProportionateScreenWidth(
                                                    kDefaultPadding / 3),
                                          ),
                                          child: Row(
                                            children: [
                                              products[index]['items'][idx]
                                                              ['image_url']
                                                          .length >
                                                      0
                                                  ? ImageContainer(
                                                      url:
                                                          "https://app.zmallapp.com/${products[index]['items'][idx]['image_url'][0]}",
                                                    )
                                                  : ImageContainer(
                                                      url:
                                                          "https://ibb.co/vkhzjd6"),
                                              SizedBox(
                                                  width:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding / 4)),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      products[index]['items']
                                                          [idx]['name'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium!
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                                .bodySmall!
                                                                .copyWith(
                                                                  color:
                                                                      kGreyColor,
                                                                ),
                                                          )
                                                        : SizedBox(height: 0.5),
                                                    SizedBox(
                                                        height:
                                                            getProportionateScreenHeight(
                                                                kDefaultPadding /
                                                                    5)),
                                                    Text(
                                                      "${_getPrice(products[index]['items'][idx]) != null ? _getPrice(products[index]['items'][idx]) : 0} Birr",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall!
                                                          .copyWith(
                                                            color:
                                                                kSecondaryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
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
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(
                            height: 2,
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
                      title: "Go to Cart>>",
                      press: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return GlobalCart();
                            },
                          ),
                        ).then((value) => getCart());
                      },
                      color: kSecondaryColor,
                    ),
                  )
                : Container(),
          ],
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
        this.responseData = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
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

  void productClicked(String productId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/add_user_and_store";
    Map data = {
      "store_id": widget.store['_id'],
      "product_id": productId,
      "user_id": "zm_abroad_user",
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
      debugPrint("Product clicked");
      // debugPrint(json.decode(response.body));
    } catch (e) {
      // debugPrint(e);
    }
  }
}
