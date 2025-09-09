import 'dart:async';
import 'dart:convert';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
import 'package:zmall/aliexpress/model/ali_model_class.dart';
import 'package:zmall/cart/cart_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class AliItemScreen extends StatefulWidget {
  final int productId;
  final String itemId;
  final String storeId;
  final String category;
  final String imageUrl;
  final String itemName;
  final String accessToken;
  final String productTitle;
  final List<dynamic> smallImageUrls;

  const AliItemScreen({
    Key? key,
    required this.itemId,
    required this.storeId,
    required this.productId,
    required this.accessToken,
    required this.category,
    required this.imageUrl,
    required this.itemName,
    required this.productTitle,
    required this.smallImageUrls,
  }) : super(key: key);

  @override
  State<AliItemScreen> createState() => _AliItemScreenState();
}

class _AliItemScreenState extends State<AliItemScreen> {
  late PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  LocationPermission _permissionStatus = LocationPermission.denied;
  List<AeItemSkuInfoDTO> items = [];
  var productDetail;
  var storeInfo;
  var itemInfo;
  var itemBaseInfo;
  AliExpressCart? aliexpressCart;
  double? longitude, latitude;
  String errorMessage = '';
  String _searchQuery = '';
  bool isLoggedIn = false;
  bool isSearch = false;
  bool isLoading = false;
  var userData;
  Cart? cart;

  @override
  void initState() {
    super.initState();
    isLogged();
    getCart();
    getProductDetail();
    _doLocationTask();
  }

  void getProductDetail() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }
    try {
      var detail = await _getProductDetail();
      if (detail != null && detail['success']) {
        setState(() {
          productDetail = detail['p_detail'];
        });
        if (productDetail != null) {
          // _loadProductDetails();
          final resultData = productDetail['aliexpress_ds_product_get_response']
              ['result']['ae_item_sku_info_dtos']['ae_item_sku_info_d_t_o'];
          final resultData2 =
              productDetail['aliexpress_ds_product_get_response']['result']
                  ['ae_store_info'];
          final resultData3 =
              productDetail['aliexpress_ds_product_get_response']['result']
                  ['ae_item_base_info_dto'];
          final resultData4 =
              productDetail['aliexpress_ds_product_get_response']['result']
                  ['ae_item_properties']['ae_item_property'][0];
          final storeInfoList = AeStoreInfo.fromJson(resultData2);
          final itemBaseInfoList = AeItemBaseInfoDto.fromJson(resultData3);
          final itemInfoList = AeItemProperty.fromJson(resultData4);
          final loadedItems = List<AeItemSkuInfoDTO>.from(
            resultData.map((item) => AeItemSkuInfoDTO.fromJson(item)) ?? [],
          );
          if (mounted) {
            setState(() {
              items = loadedItems;
              itemBaseInfo = itemBaseInfoList;
              itemInfo = itemInfoList;
              storeInfo = storeInfoList;
              isLoading = false;
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });

          Service.showMessage(
              context: context,
              title: "Error loading item detail",
              error: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load products';
          isLoading = false;
        });
      }
      // debugPrint('Error fetching products');
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
    var long = await Service.read('longitude');
    var lat = await Service.read('latitude');
    if (long != null && lat != null) {
      setState(() {
        latitude = lat;
        longitude = long;
      });
    }
  }

////////////////LOCATION//////////////////
  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial
      Service.showMessage(
          context: context,
          title: "Location permission denied. Please enable and try again",
          error: true);
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
          .setLocation(latitude!, longitude!);
    }
  }

  void _doLocationTask() async {
    // debugPrint("checking user location");
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
          Service.showMessage(
              context: context,
              title: "Location service disabled. Please enable and try again",
              error: true);
        }
      }
    } else {
      _requestLocationPermission();
    }
  }

  //////////////////////////////////
  void getCart() async {
    // debugPrint("Fetching data");
    var data = await Service.read('cart');
    var aliCart = await Service.read('aliexpressCart');
    if (data != null) {
      setState(() {
        cart = Cart.fromJson(data);
      });
    }
    if (aliCart != null) {
      setState(() {
        aliexpressCart = AliExpressCart.fromJson(aliCart);
      });
    }
  }

  void addToCart(
      item, destination, storeLocation, storeId, itemIds, productIds) {
    cart = Cart(
      userId: userData['user']['_id'],
      items: [item],
      serverToken: userData['user']['server_token'],
      destinationAddress: destination,
      storeId: storeId,
      storeLocation: storeLocation,
    );
    aliexpressCart = AliExpressCart(
      cart: cart!,
      itemIds: itemIds,
      productIds: productIds,
    );
    Service.save('cart', cart!.toJson());
    Service.save('aliexpressCart', aliexpressCart!.toJson());
    Service.showMessage(
        context: context, title: "Item added to cart!", error: false);
    getCart();
  }

  ////////
  Future<void> onRefresh() async {
    if (mounted) {
      setState(() {
        isLogged();
        getCart();
        getProductDetail();
        _doLocationTask();
      });
    }
  }

// Filter items based on search query
  List<AeItemSkuInfoDTO> _getFilteredItems() {
    if (!isSearch || _searchQuery.isEmpty) {
      return items;
    }

    return items.where((item) {
      return item.aeSkuPropertyDtos.any((skuProperty) {
        if (item.aeSkuPropertyDtos.isEmpty) {
          return false;
        }
        if (skuProperty.propertyValueDefinitionName == null) {
          return false;
        }
        return skuProperty.propertyValueDefinitionName!
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      });
    }).toList();
  }

///////////
  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        centerTitle: false,
        title: Text(widget.itemName),
        backgroundColor: kPrimaryColor,
        actions: [
          !isSearch
              ? IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      isSearch = true;
                    });
                  },
                )
              : _searchWidget(),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, CartScreen.routeName)
                  .then((value) => getCart());
            },
            icon: Badge.count(
              offset: Offset(-12, -8),
              alignment: Alignment.topLeft,
              count: cart != null ? cart!.items!.length : 0,
              backgroundColor: kSecondaryColor,
              child: Icon(Icons.add_shopping_cart_outlined),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: kSecondaryColor,
        onRefresh: onRefresh,
        child: ModalProgressHUD(
          color: kPrimaryColor,
          progressIndicator: linearProgressIndicator,
          inAsyncCall: isLoading,
          child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding / 2)),
              child: isLoading && items.isEmpty
                  ? SizedBox.shrink()
                  : items.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildItemStoreProfile(),
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            Expanded(
                              child: _buildItemGrid(
                                itemList: _getFilteredItems(),
                              ),
                            ),
                          ],
                        )
                      : errorMessage.isNotEmpty
                          ? _buildErrorWidget(errorMessage)
                          : _buildErrorWidget(
                              'No item found. Please try again!')),
        ),
      ),
    );
  }

  Widget _buildItemGrid({required List<AeItemSkuInfoDTO> itemList}) {
    final inStockItems = itemList.where((item) => item.skuStock).toList();
    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        children: List.generate(
            inStockItems.isNotEmpty ? inStockItems.length : 0, (index) {
          final item = inStockItems[index];
          String itemImageUrl = '';
          String itemName = '';
          String itemValue = '';
          String itemValueName = '';
          bool isInStock = item.skuStock;
          int ipmSkuStock = item.ipmSkuStock;

          // Iterate through each SKU property for the current product
          if (item.aeSkuPropertyDtos.isNotEmpty) {
            // Access the first element in the list
            var property = item.aeSkuPropertyDtos.first;
            itemImageUrl =
                property.skuImage != null && property.skuImage!.isNotEmpty
                    ? property.skuImage!
                    : widget.imageUrl;
            // Assign propertyValueDefinitionName if it exists
            if (property.propertyValueDefinitionName != null) {
              itemName = property.propertyValueDefinitionName!;
            } else {
              itemName = widget.itemName;
            }

            // Check if the property relates to color specifically
            if (property.skuPropertyName.isNotEmpty) {
              itemValueName = property.skuPropertyName;
              itemValue = property.skuPropertyValue;
            }

            // // Debugging to check what data is being captured
            // debugPrint('Property Name: ${property.skuPropertyName}');
            // debugPrint('Property Value: ${property.skuPropertyValue}');
            // debugPrint('Property SkuAttr: ${item.skuAttr}');
            // debugPrint('Definition Name: ${property.propertyValueDefinitionName}');
            // debugPrint('image Url : ${property.skuImage}');
            // debugPrint('offerSalePrice : ${item.offerSalePrice}');
            // debugPrint('offerBulkSalePrice : ${item.offerBulkSalePrice}');
            // debugPrint('priceIncludeTax : ${item.priceIncludeTax}');
            // debugPrint('skuPrice : ${item.skuPrice}');
            // debugPrint('---------------------------');
          }

          // Build the product card using the data for the current product
          return StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: _buildItemCard(
                  id: item.skuAttr,
                  isInStock: isInStock,
                  category: widget.category,
                  itemValue: itemValue,
                  price: double.tryParse(item.offerSalePrice)!,
                  currency: item.currencyCode,
                  imageURL: itemImageUrl,
                  name: itemName,
                  itemValueName: itemValueName,
                  ipmSkuStock: ipmSkuStock));
        }),
      ),
    );
  }

  Widget _buildItemCard({
    required String id,
    required String imageURL,
    required String name,
    required bool isInStock,
    required String category,
    required double price,
    required String currency,
    required String itemValue,
    required String itemValueName,
    required int ipmSkuStock,
  }) {
    return Card(
      color: kPrimaryColor,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding / 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                height: getProportionateScreenHeight(kDefaultPadding * 7),
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  child: CachedNetworkImage(
                    imageUrl: imageURL,
                    fit: BoxFit.cover,
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
            Text(name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            itemValueName.isNotEmpty
                ? Text("$itemValueName: $itemValue",
                    style: const TextStyle(
                      fontSize: 14,
                    ))
                : SizedBox.shrink(),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$currency $price',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )),
                addToCartWudget(
                    id: id,
                    price: price,
                    itemName: name,
                    isInStock: isInStock,
                    imageURL: imageURL),
              ],
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 4),
            ),
          ],
        ),
      ),
    );
  }

  List<String> itemIds = [];
  List<int> productIds = [];

  Widget addToCartWudget({
    required String id,
    required double price,
    required String itemName,
    required bool isInStock,
    required String imageURL,
  }) {
    final storeId = widget.storeId;

    return InkWell(
      onTap: () async {
        if (!isInStock) {
          Service.showMessage(
              context: context,
              title: "Sorry, this item is currently out of stock.",
              error: true,
              duration: 5);
          return;
        }

        if (userData == null) {
          // debugPrint("User not logged in...");
          Service.showMessage(
              context: context, title: "Please login in...", error: true);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(firstRoute: false),
            ),
          ).then((value) => getUser());
          return;
        }

        Item item = Item(
          id: widget.itemId,
          quantity: 1,
          specification: [],
          noteForItem: "${widget.itemName}: ${widget.productTitle}: $itemName",
          price: price,
          itemName: itemName,
          imageURL: imageURL,
        );

        StoreLocation storeLocation = StoreLocation(
          long: zmall_longitude,
          lat: zmall_latitude,
        );

        DestinationAddress destination = DestinationAddress(
          long: Provider.of<ZMetaData>(context, listen: false).longitude,
          lat: Provider.of<ZMetaData>(context, listen: false).latitude,
          name: "Current Location",
          note: "User current location",
        );

        // Handle same store case
        setState(() {
          // Ensure cart data is initialized
          if (aliexpressCart == null) {
            aliexpressCart = AliExpressCart(
              cart: Cart(storeId: storeId, items: []),
              itemIds: [],
              productIds: [],
            );
          }
          // debugPrint("ALI CART>>> ${aliexpressCart!.toJson()}");
          // debugPrint("ALI CART ITEM>>> ${aliexpressCart!.toJson()['cart']['items']}");
          // debugPrint("ALI ItemIds ${aliexpressCart!.toJson()['item_ids']}");
          // debugPrint("ALI ProductIds: ${aliexpressCart!.toJson()['product_ids']}");
          // Ensure itemIds and productIds are not null
          itemIds = aliexpressCart!.itemIds ?? [];
          productIds = aliexpressCart!.productIds ?? [];

          // Check if the item already exists
          if (!itemIds.contains(id)) {
            // Add new IDs
            itemIds.add(id);
            productIds.add(widget.productId);

            // Handle empty cart case
            if (cart == null) {
              // debugPrint("Empty cart! Adding new item.");
              addToCart(item, destination, storeLocation, storeId, itemIds,
                  productIds);
              getCart();
              return;
            }
            // Handle different store case
            else if (cart!.storeId != storeId) {
              _showDialog(item, destination, storeLocation, storeId, itemIds,
                  productIds);
              return;
            } else {
              // Add item to cart
              cart!.items!.add(item);
              aliexpressCart!.cart.items!.add(item);
              aliexpressCart!.itemIds = itemIds;
              aliexpressCart!.productIds = productIds;

              // Save updated cart
              Service.save('cart', aliexpressCart!.cart);
              Service.save('aliexpressCart', aliexpressCart!.toJson());

              Service.showMessage(
                  context: context, title: "Item added to cart", error: false);
              getCart();
            }
          } else {
            Service.showMessage(
                context: context,
                title: "Selected item is already in cart",
                error: true);
          }
        });
      },
      child: Container(
          padding:
              EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
          decoration: BoxDecoration(color: kWhiteColor, shape: BoxShape.circle),
          child: Icon(Icons.add_shopping_cart_outlined,
              size: 20, color: kSecondaryColor)),
    );
  }

  void _showDialog(
      item, destination, storeLocation, storeId, itemIds, productIds) {
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
                  itemIds.clear();
                  productIds.clear();
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
                    addToCart(item, destination, storeLocation, storeId,
                        itemIds, productIds);
                  });

                  Navigator.of(alertContext).pop();
                },
              ),
            ],
          );
        });
  }

  // Helper method to build product image carousel
  int _currentIndex = 0;
  bool _isExpanded = false;
  Widget _buildItemStoreProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Carousel
        Container(
          height: getProportionateScreenHeight(kDefaultPadding * 13),
          decoration: BoxDecoration(
            border: Border.all(color: kWhiteColor),
            borderRadius: BorderRadius.circular(kDefaultPadding),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.smallImageUrls.isNotEmpty
                      ? widget.smallImageUrls.length
                      : 1,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      fit: BoxFit.fill,
                      imageUrl: widget.smallImageUrls.isNotEmpty
                          ? widget.smallImageUrls[index]
                          : widget.imageUrl,
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
                    );
                  },
                ),
                // Image counter indicator
                Positioned(
                  right: getProportionateScreenWidth(kDefaultPadding),
                  bottom: getProportionateScreenHeight(kDefaultPadding),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 3),
                    ),
                    decoration: BoxDecoration(
                      color: kGreyColor,
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding)),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.smallImageUrls.length}',
                      style: TextStyle(color: kPrimaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Image dots indicator
        if (widget.smallImageUrls.length > 1)
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: getProportionateScreenHeight(
                    _isExpanded ? kDefaultPadding / 4 : kDefaultPadding / 2)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.smallImageUrls.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding / 4)),
                  width: getProportionateScreenWidth(_currentIndex == index
                      ? kDefaultPadding / 2
                      : kDefaultPadding / 4),
                  height: getProportionateScreenHeight(_currentIndex == index
                      ? kDefaultPadding / 2
                      : kDefaultPadding / 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentIndex == index ? kSecondaryColor : kGreyColor,
                  ),
                ),
              ),
            ),
          ),
        // Product Title
        Container(
          padding: EdgeInsets.symmetric(
            vertical: getProportionateScreenHeight(kDefaultPadding / 8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final titleTextSpan = TextSpan(
                    text: widget.productTitle,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1),
                  );

                  final textPainter = TextPainter(
                      text: titleTextSpan,
                      textDirection: TextDirection.ltr,
                      maxLines: 1)
                    ..layout(maxWidth: constraints.maxWidth);

                  final isTextOverflowed = textPainter.didExceedMaxLines;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnimatedCrossFade(
                          firstChild: Text(widget.productTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                          secondChild: Text(widget.productTitle,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                          crossFadeState: _isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: Duration(milliseconds: 300),
                        ),
                      ),
                      if (isTextOverflowed) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: kSecondaryColor,
                              size: 20),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        /// Item ratings and Sales Info
        if (itemBaseInfo != null)
          Container(
            padding: EdgeInsets.symmetric(
                // horizontal: getProportionateScreenWidth(kDefaultPadding / 4),
                vertical: getProportionateScreenHeight(kDefaultPadding / 4)),
            child: Wrap(
                spacing: getProportionateScreenWidth(kDefaultPadding),
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    SmoothStarRating(
                      rating: double.parse(itemBaseInfo.avgEvaluationRating),
                      size: 12,
                      starCount: 5,
                      color: Colors.orange,
                      borderColor: Colors.orange,
                    ),
                    SizedBox(
                        width:
                            getProportionateScreenWidth(kDefaultPadding / 4)),
                    Text(
                      itemBaseInfo.avgEvaluationRating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      ' (${itemBaseInfo.evaluationCount})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(
                        width: getProportionateScreenWidth(kDefaultPadding)),
                    Icon(Icons.shopping_bag_outlined, size: 17),
                    SizedBox(
                        width:
                            getProportionateScreenWidth(kDefaultPadding / 4)),
                    Text(
                      '${itemBaseInfo.salesCount}+ Sold',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ]),

                  // Brand Information
                  if (itemInfo != null &&
                      !itemInfo.attrValue
                          .toString()
                          .toLowerCase()
                          .contains("null") &&
                      itemInfo.attrName.toString().toLowerCase() ==
                          "brand name")
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 8),
                              horizontal: getProportionateScreenWidth(
                                  kDefaultPadding / 4)),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(
                                    kDefaultPadding / 2)),
                          ),
                          child: Text(
                            "Brand",
                            style: TextStyle(
                              fontSize: 12,
                              color: kSecondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                            width: getProportionateScreenWidth(
                                kDefaultPadding / 4)),
                        Flexible(
                          child: Text(
                            itemInfo.attrName.toString().toLowerCase() ==
                                    "brand name"
                                ? itemInfo.attrValue
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                ]),
          ),

        ///Store info
        if (_isExpanded && storeInfo != null)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(
                left: getProportionateScreenWidth(kDefaultPadding / 4),
                right: getProportionateScreenWidth(kDefaultPadding / 4),
                top: getProportionateScreenHeight(kDefaultPadding / 8)),
            padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
                vertical: getProportionateScreenHeight(kDefaultPadding / 4)),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(
                  getProportionateScreenHeight(kDefaultPadding * 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(Icons.store, color: kSecondaryColor),
                    SizedBox(
                        width:
                            getProportionateScreenWidth(kDefaultPadding / 2)),
                    Expanded(
                      child: Text(
                        storeInfo.storeName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 4)),
                Row(
                  children: [
                    Text(
                      'Store Rating: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SmoothStarRating(
                      rating: double.parse(storeInfo.itemAsDescribedRating),
                      size: 12,
                      starCount: 5,
                      color: Colors.orange,
                      borderColor: Colors.orange,
                    ),
                    SizedBox(
                        width:
                            getProportionateScreenWidth(kDefaultPadding / 2)),
                    Text(
                      storeInfo.itemAsDescribedRating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _searchWidget() {
    return Container(
      alignment: Alignment.center,
      height: getProportionateScreenHeight(kDefaultPadding * 2.6),
      width: getProportionateScreenWidth(kDefaultPadding * 18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        border: Border.all(color: kGreyColor.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding * 1.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
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
          IconButton(
            icon: const Icon(
              Icons.clear_outlined,
              color: kGreyColor,
            ),
            onPressed: () {
              setState(() {
                isSearch = false;
                _searchQuery = '';
                _searchController.clear();
              });
            },
            style: ButtonStyle(
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                  const EdgeInsets.all(kDefaultPadding / kDefaultPadding)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> _getProductDetail() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/aliexpress_product_detail";
    Map data = {
      "access_token": widget.accessToken,
      "product_id": widget.productId,
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
            isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        isLoading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
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
    );
  }
}
