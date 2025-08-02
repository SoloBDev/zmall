import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/aliexpress/model/ali_model_class.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/global/aliexpress/global_ali_item_screen.dart';
import 'package:zmall/global/cart/global_cart.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class GlobalAliProductListScreen extends StatefulWidget {
  const GlobalAliProductListScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<GlobalAliProductListScreen> createState() =>
      _AliProductListScreenState();
}

class _AliProductListScreenState extends State<GlobalAliProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String? selectedCategory = '';
  int defaultCategoryIndex = -1;
  String errorMessage = '';
  double? longitude, latitude;
  List<Product> products = [];
  var categories = [];
  bool isLoading = false;
  String _searchQuery = '';
  var accessToken;
  var userData;
  var itemId;
  var storeId;
  AbroadCart? cart;

  @override
  void initState() {
    super.initState();
    _getAliexpressProducts();
    getCart();
    // isLogged();
    // _doLocationTask();
    // for (String category in categories) {
    //   _keys[category] = GlobalKey();
    // }
  }

  Future<List<Product>> fetchProducts(Map<String, dynamic> productData) async {
    setState(() {
      isLoading = true;
      products = [];
    });
    try {
      if (productData['product'] != null) {
        final pData = productData['product'];
        final resultData = pData['aliexpress_ds_recommend_feed_get_response']
            ['result']['products']['traffic_product_d_t_o'];
        var newProducts = List<Product>.from(
          resultData?.map((item) => Product.fromJson(item)) ?? [],
        );
        if (resultData.isNotEmpty) {
          setState(() {
            products = newProducts;
            isLoading = false;
            errorMessage = '';
            selectedCategory = selectedCategory!.isNotEmpty
                ? selectedCategory
                : categories[defaultCategoryIndex];
          });
        }
        return products;
      } else {
        setState(() {
          isLoading = false;
          selectedCategory = "";
        });
        return [];
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage =
            'No product found for ${formatCategories(selectedCategory!)} category. Please try again!';
        selectedCategory = "";
      });
      return [];
    }
  }

  void getCart() async {
    debugPrint("Fetching data");
    var data = await Service.read('abroad_cart');
    if (data != null) {
      setState(() {
        cart = AbroadCart.fromJson(data);
      });
    }
    // calculatePrice();
  }

  ////////
  Future<void> onRefresh() async {
    if (mounted) {
      setState(() {
        _getAliexpressProducts();
        getCart();
        // isLogged();
        // getUser();
        // _doLocationTask();
      });
    }
  }

// Filter products based on search query
  List<Product> _getFilteredProducts() {
    if (_searchQuery.isEmpty &&
        (selectedCategory == null || selectedCategory!.isEmpty)) {
      return products;
    }

    return products.where((product) {
      // Check if search query matches (if search is active)
      bool matchesSearch = _searchQuery.isEmpty ||
          product.productTitle
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          product.firstLevelCategoryName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          product.secondLevelCategoryName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Return products that match the search
      return matchesSearch;
    }).toList();
  }

///////////
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        appBar: AppBar(
          centerTitle: false,
          title: const Text('AliExpress'),
          backgroundColor: kPrimaryColor,
          surfaceTintColor: kPrimaryColor,
          // flexibleSpace: searchButton(),
          actions: [
            products.isEmpty
                ? SizedBox.shrink()
                : IconButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return GlobalCart();
                      })).then((value) => getCart());
                    },
                    icon: Badge.count(
                      offset: Offset(-12, -8),
                      alignment: Alignment.topLeft,
                      count: cart != null ? cart!.items!.length : 0,
                      backgroundColor: kSecondaryColor,
                      child: Icon(Icons.add_shopping_cart_outlined),
                    ),
                  ),
            SizedBox(
              width: getProportionateScreenWidth(kDefaultPadding / 5),
            )
          ],
          bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                getProportionateScreenHeight(kDefaultPadding * 7),
              ), // Adjust height as needed
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding / 8)),
                child: (products == null ||
                            products.isEmpty ||
                            (isLoading && products.isEmpty)) &&
                        categories.isEmpty
                    ? SizedBox.shrink()
                    : Column(
                        children: [
                          searchButton(),
                          if (categories.isNotEmpty) categoryWidget(categories),
                        ],
                      ),
              )),
        ),
        body: RefreshIndicator(
          color: kPrimaryColor,
          backgroundColor: kSecondaryColor,
          onRefresh: onRefresh,
          child: ModalProgressHUD(
              color: kPrimaryColor,
              progressIndicator: linearProgressIndicator,
              inAsyncCall: isLoading,
              child: isLoading && products.isEmpty
                  ? SizedBox.shrink()
                  : products.isNotEmpty
                      ? Column(
                          children: [
                            Expanded(
                                child: categories.isNotEmpty &&
                                        products.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding / 2)),
                                              child: Text(
                                                  selectedCategory != null &&
                                                          selectedCategory!
                                                              .isNotEmpty
                                                      ? formatCategories(
                                                          selectedCategory!)
                                                      : formatCategories(categories[
                                                          defaultCategoryIndex]),
                                                  style: TextStyle(
                                                      color: kBlackColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding *
                                                                  1.2)))),
                                          SizedBox(
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding / 2)),
                                          Expanded(
                                              child: _buildProductGrid(
                                                  productsList:
                                                      _getFilteredProducts())),
                                        ],
                                      )
                                    : _buildErrorWidget(
                                        errorMessage.isNotEmpty
                                            ? errorMessage
                                            : 'No product found. Please try again!',
                                      )),
                          ],
                        )
                      : _buildErrorWidget(
                          errorMessage.isNotEmpty
                              ? errorMessage
                              : 'No product found for $selectedCategory category. Please try again!',
                        )),
        ),
      ),
    );
  }

  Widget _buildProductGrid({required List<Product> productsList}) {
    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        children: List.generate(productsList.length, (index) {
          final product = productsList[index];
          return StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: _buildProductCard(
                  productId: product.productId,
                  firstLevelCategoryName: product.firstLevelCategoryName,
                  imageUrl: product.productMainImageUrl,
                  productTitle: product.productTitle,
                  secondLevelCategoryName: product.secondLevelCategoryName,
                  imageUrls: product.productSmallImageUrls));
        }),
      ),
    );
  }

  Widget _buildProductCard({
    required int productId,
    required String imageUrl,
    required String productTitle,
    required String secondLevelCategoryName,
    required String firstLevelCategoryName,
    required List<dynamic> imageUrls,
    // required String currency
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => GlobalAliItemScreen(
                  itemId: itemId,
                  storeId: storeId,
                  productTitle: productTitle,
                  itemName: secondLevelCategoryName,
                  productId: productId,
                  category: firstLevelCategoryName,
                  imageUrl: imageUrl,
                  accessToken: accessToken,
                  smallImageUrls: imageUrls,
                )));
      },
      child: Card(
        color: kPrimaryColor,
        elevation: 1,
        child: Padding(
          padding:
              EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                  height: getProportionateScreenHeight(kDefaultPadding * 8),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.fill,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kSecondaryColor),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: kSecondaryColor),
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            Text('Image not available',
                                style: TextStyle(color: kSecondaryColor)),
                          ],
                        ),
                      ),
                    ),
                  )),
              SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 4)),
              Text(
                productTitle,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(color: kGreyColor),
              ),
              Text(secondLevelCategoryName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoryWidget(categories) {
    return Container(
      height: getProportionateScreenHeight(kDefaultPadding * 3),
      margin: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(kDefaultPadding / 1.5),
          horizontal: getProportionateScreenWidth(kDefaultPadding / 2)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          String category = categories[index];
          return InkWell(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
              _getAliexpressProducts().then((_) => setState(() {}));
            },
            child: Chip(
              backgroundColor: categories[index] == selectedCategory
                  ? kBlackColor
                  : kPrimaryColor,
              label: Text(formatCategories(category),
                  style: TextStyle(
                      color: categories[index] == selectedCategory
                          ? kPrimaryColor
                          : kBlackColor,
                      fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: kWhiteColor,
                  width: 1.6,
                ),
                borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding)),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) =>
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
      ),
    );
  }

  Widget searchButton() {
    return Container(
      alignment: Alignment.center,
      height: getProportionateScreenHeight(kDefaultPadding * 2.8),
      width: double.infinity,
      margin: EdgeInsets.only(
        left: getProportionateScreenWidth(kDefaultPadding / 2),
        right: getProportionateScreenWidth(kDefaultPadding / 2),
      ),
      decoration: BoxDecoration(
          color: kWhiteColor,
          border: Border.all(color: kGreyColor.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding / 1.2))),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              focusNode: _focusNode,
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                if (_searchQuery != value) {
                  setState(() {
                    _searchQuery = value;
                  });
                }
              },
              decoration: InputDecoration(
                  hintText: "Search...",
                  border: InputBorder.none,
                  hintStyle:
                      TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  contentPadding: const EdgeInsets.only(
                      left: kDefaultPadding,
                      right: kDefaultPadding / 2,
                      bottom: kDefaultPadding / 5)),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {});
              if (_focusNode.hasFocus) {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _focusNode.unfocus();
                });
              } else {
                _focusNode.requestFocus();
              }
            },
            child: Container(
              height: double.infinity,
              width: getProportionateScreenWidth(kDefaultPadding * 2.6),
              decoration: BoxDecoration(
                  color: kWhiteColor,
                  border: Border.all(color: kGreyColor.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding / 1.2))),
              child: Icon(
                _focusNode.hasFocus
                    ? Icons.clear_outlined
                    : Icons.search_outlined,
                color: kGreyColor,
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<dynamic> _getAliexpressProducts() async {
    var aliexpressResp;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/aliexpress_product";

    Map data = {
      if (selectedCategory!.isNotEmpty) "feed_name": "$selectedCategory"
    };
    // debugPrint("isCategorySelected: ${selectedCategory!.isNotEmpty}");
    // debugPrint("data: $data");
    try {
      http.Response response = await http.post(
        Uri.parse(url),
        body: json.encode(data),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          setState(() {
            this.isLoading = false;
            errorMessage = "The connection has timed out!, place try again.";
          });
          throw TimeoutException(
              "The connection has timed out!, place try again.");
        },
      );

      // debugPrint("response:${json.decode(response.body)}");
      setState(() {
        this.isLoading = false;
        aliexpressResp = json.decode(response.body);
      });
      if (aliexpressResp != null &&
          aliexpressResp.isNotEmpty &&
          aliexpressResp['status'] == 'success' &&
          aliexpressResp.containsKey('product')) {
        if (aliexpressResp['product']['error_response'] == null) {
          //saving access token
          await Service.save(
              "ali_access_token", aliexpressResp['access_token']);
          // debugPrint("Firstcategories: ${aliexpressResp['category']}");
          setState(() {
            isLoading = false;
            accessToken = aliexpressResp['access_token'];
            itemId = aliexpressResp['itemId'];
            storeId = aliexpressResp['storeId'];
            categories = aliexpressResp['category'];
            defaultCategoryIndex = categories.indexWhere(
                (category) => category == aliexpressResp['feed_name']);
          });
          // debugPrint("index: $defaultCategoryIndex");
          products = await fetchProducts(aliexpressResp);
          // debugPrint("Length of $selectedCategory: ${products.length}");
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "Network error, please try again!";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed loading products, please try again!";
        });
      }
    } catch (e) {
      // debugPrint("error:$e");
      setState(() {
        this.isLoading = false;
        errorMessage =
            "Something went wrong. Please check your internet connection!";
      });

      return null;
    }
  }

  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: onRefresh,
              child: Text(
                "Retry",
                style: TextStyle(color: kSecondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatCategories(String category) {
    String formatted = category.replaceAll('Afrine_', '');
    formatted = formatted.replaceAll('_', ' ');
    formatted = formatted.replaceAll('&', ' & ');

    // Special case for 'africomtelebirr'
    if (formatted.toLowerCase() == 'africomtelebirr') {
      return "Exclusive Collections";
    }

    // Special case for 'evernet非BNG'
    if (formatted.contains('evernet非BNG')) {
      return 'Evernet非BNG';
    }

    // Split the string into words
    List<String> words = formatted.split(' ');

    // Capitalize each word
    words = words.map((word) {
      if (word.isEmpty) return word;
      // Handle words like "non-BNG" or hyphenated words
      if (word.contains('-')) {
        return word
            .split('-')
            .map((part) => part.isEmpty
                ? part
                : part[0].toUpperCase() + part.substring(1).toLowerCase())
            .join('-');
      }
      // Regular word capitalization
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return words.join(' ');
  }
}
