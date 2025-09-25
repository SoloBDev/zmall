import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/item/components/photo_viewer.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/notifications/notification_store.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/sliver_appbar_delegate.dart';

class Body extends StatefulWidget {
  const Body({
    super.key,
    required this.item,
    required this.location,
    this.isDineIn = false,
    required this.tableNumber,
    this.isSplashRedirect = false,
  });

  final item;
  final location;
  final isDineIn;
  final tableNumber;
  final isSplashRedirect;

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  var userData;
  List<int>? requiredSpecs = List.empty(growable: true);
  int reqCount = 0;
  int quantity = 1;
  String note = "";
  bool clearedRequired = false;
  Cart? cart;
  double? longitude, latitude;
  double? initialPrice;
  double? price;
  List<Specification>? specification = [];
  List<ListElement> selected = [];
  List count = [];
  //
  bool _isCollapsed = false;
  late ScrollController _pageScrollController;

  void requiredCount() {
    if (widget.item['specifications'].length > 0) {
      for (var index = 0;
          index < widget.item['specifications'].length;
          index++) {
        if (widget.item['specifications'][index]['is_required']) {
          setState(() {
            reqCount += 1;
            requiredSpecs
                ?.add(widget.item['specifications'][index]['unique_id']);
          });
        }
      }
      if (reqCount == 0) {
        setState(() {
          clearedRequired = true;
        });
      }
    } else {
      setState(() {
        clearedRequired = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
    requiredCount();
    getCart();
    initialPrice = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
    price = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
    _pageScrollController = ScrollController()
      ..addListener(() {
        if (_pageScrollController.hasClients) {
          setState(() {
            _isCollapsed = _pageScrollController.offset > kToolbarHeight;
          });
        }
      });
  }

  void updatePrice() {
    double temPrice = 0;
    specification!.forEach((spec) {
      spec.list!.forEach((element) {
        temPrice += element.price!;
      });
    });
    setState(() {
      price = (initialPrice! + temPrice) * quantity;
    });
  }

  void checkRequired() {
    if (reqCount != 0) {
      int count = 0;
      specification!.forEach((element) {
        if (requiredSpecs!.contains(element.uniqueId)) {
          count += 1;
        }
      });
      if (reqCount == count) {
        setState(() {
          clearedRequired = true;
        });
      } else {
        setState(() {
          clearedRequired = false;
        });
      }
    } else {
      setState(() {
        clearedRequired = true;
      });
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

  void getCart() async {
    var data = await Service.read('cart');
    if (data != null) {
      setState(() {
        cart = Cart.fromJson(data);
      });
    }
  }

  void addToCart(item, destination, storeLocation) {
    cart = Cart(
      userId: userData['user']['_id'],
      items: [item],
      serverToken: userData['user']['server_token'],
      destinationAddress: destination,
      storeId: widget.item['store_id'],
      storeLocation: storeLocation,
    );
    Service.save('cart', cart!.toJson());
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    // double width = MediaQuery.sizeOf(context).width;
    TextTheme textTheme = Theme.of(context).textTheme;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // backgroundColor: kWhiteColor,
      bottomNavigationBar: SafeArea(
        child: Container(
          width: double.infinity,
          // height: kDefaultPadding * 4,
          padding: EdgeInsets.symmetric(
            vertical: getProportionateScreenHeight(kDefaultPadding / 2),
            horizontal: getProportionateScreenHeight(kDefaultPadding),
          ),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            border: Border(top: BorderSide(color: kWhiteColor)),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                ),
                child: Row(
                  children: [
                    InkWell(
                      child: Container(
                        child: Padding(
                          padding: EdgeInsets.all(
                            getProportionateScreenWidth(kDefaultPadding / 3),
                          ),
                          child: Icon(
                            Icons.remove,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(kDefaultPadding / 2),
                            bottomLeft: Radius.circular(kDefaultPadding / 2),
                          ),
                        ),
                      ),
                      onTap: quantity != 1
                          ? () {
                              setState(() {
                                quantity -= 1;
                                updatePrice();
                              });
                            }
                          : () {
                              Service.showMessage(
                                  context: context,
                                  title: "Minimum order quantity is 1",
                                  error: true);
                            },
                    ),
                    Container(
                      color: kWhiteColor,
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              getProportionateScreenWidth(kDefaultPadding / 3)),
                      child: Text(
                        quantity.toString(),
                        style: textTheme.titleLarge,
                      ),
                    ),
                    InkWell(
                      child: Container(
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(kDefaultPadding / 2),
                            bottomRight: Radius.circular(kDefaultPadding / 2),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            getProportionateScreenWidth(kDefaultPadding / 3),
                          ),
                          child: Icon(
                            Icons.add,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          quantity += 1;
                          updatePrice();
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(kDefaultPadding)),
              Expanded(
                child: CustomButton(
                  // radius: kDefaultPadding * 2,
                  titleColor: clearedRequired && price != 0
                      ? kPrimaryColor
                      : kBlackColor,
                  // textFontSize: getProportionateScreenWidth(kDefaultPadding),
                  title:
                      "${Provider.of<ZLanguage>(context).addToCart} ${price!.toStringAsFixed(2)} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                  press: clearedRequired && price != 0
                      ? () async {
                          await Service.remove('images');

                          Item item = Item(
                            id: widget.item['_id'],
                            quantity: quantity,
                            specification: specification,
                            noteForItem: note,
                            price: price,
                            itemName: widget.item['name'],
                            imageURL: widget.item['image_url'].length > 0
                                ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.item['image_url'][0]}"
                                : "https://ibb.co/vkhzjd6",
                          );
                          StoreLocation storeLocation = StoreLocation(
                              long: widget.location[1],
                              lat: widget.location[0]);
                          DestinationAddress destination = DestinationAddress(
                            long: Provider.of<ZMetaData>(context, listen: false)
                                .longitude,
                            lat: Provider.of<ZMetaData>(context, listen: false)
                                .latitude,
                            name: "Current Location",
                            note: "User current location",
                          );
                          if (cart != null) {
                            if (userData != null) {
                              if (cart!.storeId == widget.item['store_id']) {
                                setState(() {
                                  cart!.items!.add(item);
                                  Service.save('cart', cart);
                                  Navigator.of(context).pop();
                                });
                              } else {
                                _showDialog(item, destination, storeLocation);
                              }
                            } else {
                              Service.showMessage(
                                  context: context,
                                  title: "Please login in...",
                                  error: true);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LoginScreen(firstRoute: false),
                                ),
                              ).then((value) => getUser());
                            }
                          } else {
                            if (userData != null) {
                              addToCart(item, destination, storeLocation);
                              Navigator.of(context).pop();
                            } else {
                              Service.showMessage(
                                context: context,
                                title: "Please login in...",
                                error: true,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LoginScreen(firstRoute: false),
                                ),
                              ).then((value) => getUser());
                            }
                          }
                        }
                      : () {
                          Service.showMessage(
                              context: context,
                              title:
                                  "Make sure to select all required specifications!",
                              error: true);
                        },
                  color: clearedRequired && price != 0
                      ? kSecondaryColor
                      : Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _pageScrollController,
            slivers: [
              // SliverAppBar with store banner
              SliverAppBar(
                expandedHeight: screenHeight * 0.3,
                floating: false,
                pinned: true,
                leadingWidth: 63,
                backgroundColor:
                    _isCollapsed ? kWhiteColor : Colors.transparent,
                leading: InkWell(
                  onTap: () {
                    if (widget.isSplashRedirect) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, "/start", (Route<dynamic> route) => false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                      padding: EdgeInsets.all(kDefaultPadding / 8),
                      margin: EdgeInsets.only(left: kDefaultPadding),
                      decoration: BoxDecoration(
                          color: kWhiteColor, shape: BoxShape.circle),
                      child: Center(child: Icon(size: 24, Icons.arrow_back))),
                ),
                // leading: ClipOval(
                //   child: Material(
                //     color: Colors.white.withValues(alpha: 0.85),
                //     child: InkWell(
                // onTap: () {
                //   if (widget.isSplashRedirect) {
                //     Navigator.pushNamedAndRemoveUntil(context, "/start",
                //         (Route<dynamic> route) => false);
                //   } else {
                //     Navigator.pop(context);
                //   }
                // },
                //       child: Padding(
                //         padding: const EdgeInsets.all(kDefaultPadding / 2),
                //         child: Icon(Icons.arrow_back,
                //             color: kBlackColor, size: 22),
                //       ),
                //     ),
                //   ),
                // ),
                title: AnimatedOpacity(
                  opacity: _isCollapsed ? 1 : 0,
                  duration: Duration(microseconds: 300),
                  child: Text(
                    Service.capitalizeFirstLetters(widget.item['name']),
                    softWrap: true,
                    maxLines: 3,
                    style: TextStyle(
                      color: _isCollapsed ? kBlackColor : kPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                actions: [
                  if (widget.item['image_url'].length > 0)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return PhotoViewer(
                                imageUrl: widget.item['image_url'][0],
                                itemName: widget.item['name'],
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                          padding: EdgeInsets.all(kDefaultPadding / 1.2),
                          margin: EdgeInsets.only(right: kDefaultPadding),
                          decoration: BoxDecoration(
                              color: kWhiteColor, shape: BoxShape.circle),
                          child: Center(
                              child: Icon(size: 24, Icons.zoom_out_map))),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    height: getProportionateScreenHeight(height * 0.4),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.item['image_url'].length > 0
                              ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.item['image_url'][0]}"
                              : "https://ibb.co/vkhzjd6",
                          imageBuilder: (context, imageProvider) => Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              boxShadow: [boxShadow],
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: imageProvider,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Center(
                            child: Container(
                              width: double.infinity,
                              height:
                                  getProportionateScreenHeight(height * 0.4),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      kSecondaryColor),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Padding(
                            padding: EdgeInsets.only(
                                top: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            child: Container(
                              width: double.infinity,
                              height:
                                  getProportionateScreenHeight(height * 0.4),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                image: DecorationImage(
                                  fit: BoxFit.fitHeight,
                                  image: AssetImage(zmallLogo),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Top blur overlay
                        // Positioned(
                        //   top: 0,
                        //   left: 0,
                        //   right: 0,
                        //   height: getProportionateScreenHeight(
                        //           kDefaultPadding * 20) *
                        //       0.10,
                        //   child: ClipRRect(
                        //     child: BackdropFilter(
                        //       filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        //       child: Container(
                        //         decoration: BoxDecoration(
                        //           gradient: LinearGradient(
                        //             begin: Alignment.topCenter,
                        //             end: Alignment.bottomCenter,
                        //             colors: [
                        //               Colors.black.withValues(alpha: 0.13),
                        //               Colors.transparent,
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // Bottom blur overlay
                        // Positioned(
                        //   bottom: 0,
                        //   left: 0,
                        //   right: 0,
                        //   height: getProportionateScreenHeight(
                        //           kDefaultPadding * 14) *
                        //       0.32,
                        //   child: ClipRRect(
                        //     child: BackdropFilter(
                        //       filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        //       child: Container(
                        //         decoration: BoxDecoration(
                        //             color: kBlackColor.withValues(alpha: 0.7)
                        //             // gradient: LinearGradient(
                        //             //   begin: Alignment.topCenter,
                        //             //   end: Alignment.bottomCenter,
                        //             //   colors: [
                        //             //     Colors.transparent,
                        //             //     kBlackColor.withValues(alpha: 0.3),
                        //             //     kBlackColor.withValues(alpha: 0.7),
                        //             //   ],
                        //             //   stops: [0.0, 0.5, 1.0],
                        //             // ),
                        //             ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // Item name and description
                        //  Positioned(
                        //   left: 0,
                        //   right: 0,
                        //   bottom: getProportionateScreenHeight(
                        //           kDefaultPadding * 7) *
                        //       0.04,
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: double.infinity,
                              color: kBlackColor.withValues(alpha: 0.8),
                              padding: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 3),
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: getProportionateScreenHeight(
                                    kDefaultPadding / 3),
                                children: [
                                  // Container(
                                  //   padding: EdgeInsets.symmetric(
                                  //       horizontal: kDefaultPadding / 2,
                                  //       vertical: kDefaultPadding / 4),
                                  //   decoration: BoxDecoration(
                                  //     borderRadius: BorderRadius.circular(
                                  //         kDefaultPadding / 2),
                                  //     // color: Colors.black.withValues(alpha: 0.28),
                                  //     // color: widget.item['details'] != null &&
                                  //     //     widget.item['details']
                                  //     //         .toString()
                                  //     //         .trim()
                                  //     //         .isNotEmpty
                                  //     // ? kBlackColor.withValues(alpha: 0.6)
                                  //     // : Colors.transparent,
                                  //     // borderRadius: BorderRadius.circular(8),
                                  //   ),
                                  //   child: Text(
                                  //     Service.capitalizeFirstLetters(
                                  //         widget.item['name']),
                                  //     style: textTheme.titleSmall?.copyWith(
                                  //       fontWeight: FontWeight.bold,
                                  //       color: Colors.white,
                                  //     ),
                                  //     maxLines: 2,
                                  //     softWrap: true,
                                  //     overflow: TextOverflow.ellipsis,
                                  //   ),
                                  // ),
                                  // Row(
                                  //   crossAxisAlignment: CrossAxisAlignment.end,
                                  //   children: [
                                  // Expanded(
                                  //   child: Container(
                                  //     padding:
                                  //         EdgeInsets.all(kDefaultPadding / 2),
                                  //     decoration: BoxDecoration(
                                  //       // color: Colors.black.withValues(alpha: 0.28),
                                  //       color: Colors.black
                                  //           .withValues(alpha: 0.35),
                                  //       // borderRadius: BorderRadius.circular(8),
                                  //     ),
                                  //     child: Text(
                                  //       Service.capitalizeFirstLetters(
                                  //           widget.item['name']),
                                  //       style: textTheme.titleSmall?.copyWith(
                                  //         fontWeight: FontWeight.bold,
                                  //         color: Colors.white,
                                  //       ),
                                  //       maxLines: 2,
                                  //       softWrap: true,
                                  //       overflow: TextOverflow.ellipsis,
                                  //     ),
                                  //   ),
                                  // ),

                                  //to be applied for 3D modeled items
                                  // IconButton(
                                  //   onPressed: () {
                                  //     showItem3DModel(
                                  //         context: context,
                                  //         title: Service.capitalizeFirstLetters(
                                  //             widget.item['name']),
                                  //         textTheme: textTheme);
                                  //   },
                                  //   icon: Icon(
                                  //       color: kPrimaryColor,
                                  //       Icons.slow_motion_video_outlined),
                                  //   style: IconButton.styleFrom(
                                  //     backgroundColor:
                                  //         Colors.black.withValues(alpha: 0.35),
                                  //     shape: RoundedRectangleBorder(
                                  //       borderRadius: BorderRadius.circular(10),
                                  //     ),
                                  //   ),
                                  // ),
                                  //   ],
                                  // ),
                                  Text(
                                    Service.capitalizeFirstLetters(
                                        widget.item['name']),
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  if (widget.item['details'] != null &&
                                      widget.item['details']
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                    Text(
                                      widget.item['details']
                                          .toString()
                                          .replaceAll("\n", "")
                                          .trim(),
                                      // "Tender grilled chicken marinated in smoky chipotle spices, tucked into warm corn tortillas and topped with crunchy slaw, fresh cilantro, and a drizzle of tangy lime crema. A fiesta in every bite!",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 1. Image section with dynamic height
              // SliverPersistentHeader(
              //   pinned: true,
              //   delegate: SliverAppBarDelegate(
              //     minHeight: getProportionateScreenHeight(height * 0.25),
              //     maxHeight: getProportionateScreenHeight(height * 0.42),
              //     child: Container(
              //       decoration: BoxDecoration(
              //         color: kPrimaryColor,
              //       ),
              // child: Stack(
              //   children: [
              //     CachedNetworkImage(
              //       imageUrl: widget.item['image_url'].length > 0
              //           ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.item['image_url'][0]}"
              //           : "https://ibb.co/vkhzjd6",
              //       imageBuilder: (context, imageProvider) => Container(
              //         width: double.infinity,
              //         decoration: BoxDecoration(
              //           color: kPrimaryColor,
              //           boxShadow: [boxShadow],
              //           image: DecorationImage(
              //             fit: BoxFit.cover,
              //             image: imageProvider,
              //           ),
              //         ),
              //       ),
              //       placeholder: (context, url) => Center(
              //         child: Container(
              //           width: double.infinity,
              //           height:
              //               getProportionateScreenHeight(height * 0.4),
              //           child: Center(
              //             child: CircularProgressIndicator(
              //               valueColor: AlwaysStoppedAnimation<Color>(
              //                   kSecondaryColor),
              //             ),
              //           ),
              //         ),
              //       ),
              //       errorWidget: (context, url, error) => Padding(
              //         padding: EdgeInsets.only(
              //             top: getProportionateScreenHeight(
              //                 kDefaultPadding / 2)),
              //         child: Container(
              //           width: double.infinity,
              //           height:
              //               getProportionateScreenHeight(height * 0.4),
              //           decoration: BoxDecoration(
              //             color: kPrimaryColor,
              //             image: DecorationImage(
              //               fit: BoxFit.fitHeight,
              //               image: AssetImage(zmallLogo),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //     // Top blur overlay
              //     Positioned(
              //       top: 0,
              //       left: 0,
              //       right: 0,
              //       height: getProportionateScreenHeight(
              //               kDefaultPadding * 20) *
              //           0.18,
              //       child: ClipRRect(
              //         child: BackdropFilter(
              //           filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              //           child: Container(
              //             decoration: BoxDecoration(
              //               gradient: LinearGradient(
              //                 begin: Alignment.topCenter,
              //                 end: Alignment.bottomCenter,
              //                 colors: [
              //                   Colors.black.withValues(alpha: 0.15),
              //                   Colors.transparent,
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //     // Bottom blur overlay
              //     Positioned(
              //       bottom: 0,
              //       left: 0,
              //       right: 0,
              //       height: getProportionateScreenHeight(
              //               kDefaultPadding * 14) *
              //           0.32,
              //       child: ClipRRect(
              //         child: BackdropFilter(
              //           filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              //           child: Container(
              //             decoration: BoxDecoration(
              //               gradient: LinearGradient(
              //                 begin: Alignment.topCenter,
              //                 end: Alignment.bottomCenter,
              //                 colors: [
              //                   Colors.transparent,
              //                   Colors.black.withValues(alpha: 0.25),
              //                   Colors.black.withValues(alpha: 0.45),
              //                 ],
              //                 stops: [0.0, 0.5, 1.0],
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //     // Item name and description
              //     Positioned(
              //       left: 0,
              //       right: 0,
              //       bottom: getProportionateScreenHeight(
              //               kDefaultPadding * 7) *
              //           0.04,
              //       child: Container(
              //         padding: EdgeInsets.symmetric(
              //             horizontal: 10, vertical: 6),
              //         decoration: BoxDecoration(
              //           color: Colors.black.withValues(alpha: 0.28),
              //           // borderRadius: BorderRadius.circular(8),
              //         ),
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Row(
              //               crossAxisAlignment: CrossAxisAlignment.end,
              //               children: [
              //                 Text(
              //                   Service.capitalizeFirstLetters(
              //                       widget.item['name']),
              //                   style: textTheme.titleMedium?.copyWith(
              //                     fontWeight: FontWeight.bold,
              //                     color: Colors.white,
              //                   ),
              //                   maxLines: 1,
              //                   overflow: TextOverflow.ellipsis,
              //                 ),
              //                 Spacer(),
              //                 IconButton(
              //                   onPressed: () {
              //                     showItem3DModel(
              //                         context: context,
              //                         title:
              //                             Service.capitalizeFirstLetters(
              //                                 widget.item['name']),
              //                         textTheme: textTheme);
              //                   },
              //                   icon: Icon(
              //                       color: kPrimaryColor,
              //                       Icons.slow_motion_video_outlined),
              //                   style: IconButton.styleFrom(
              //                     backgroundColor: Colors.black
              //                         .withValues(alpha: 0.35),
              //                     shape: RoundedRectangleBorder(
              //                       borderRadius:
              //                           BorderRadius.circular(10),
              //                     ),
              //                   ),
              //                 ),
              //               ],
              //             ),
              //             SizedBox(height: 6),
              //             if (widget.item['details'] != null &&
              //                 widget.item['details']
              //                     .toString()
              //                     .trim()
              //                     .isNotEmpty)
              //               Text(
              //                 widget.item['details']
              //                     .toString()
              //                     .replaceAll("\n", "")
              //                     .trim(),
              //                 // "Tender grilled chicken marinated in smoky chipotle spices, tucked into warm corn tortillas and topped with crunchy slaw, fresh cilantro, and a drizzle of tangy lime crema. A fiesta in every bite!",
              //                 style: textTheme.bodyMedium?.copyWith(
              //                   color: Colors.white,
              //                   fontWeight: FontWeight.w400,
              //                 ),
              //                 maxLines: 3,
              //                 overflow: TextOverflow.ellipsis,
              //               ),
              //           ],
              //         ),
              //       ),
              //     ),
              //     //           // Top overlay buttons
              //     //           Positioned(
              //     //             top: MediaQuery.of(context).padding.top +
              //     //                 kDefaultPadding * 2.5,
              //     //             left: getProportionateScreenWidth(
              //     //                 kDefaultPadding / 1.5),
              //     //             right: getProportionateScreenWidth(
              //     //                 kDefaultPadding / 1.5),
              //     //             child: Row(
              //     //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     //               children: [
              //     //                 ClipOval(
              //     //                   child: Material(
              //     //                     color: Colors.white.withValues(alpha: 0.85),
              //     //                     child: InkWell(
              //     //                       onTap: () {
              //     //                         if (widget.isSplashRedirect) {
              //     //                           Navigator.pushNamedAndRemoveUntil(
              //     //                               context,
              //     //                               "/start",
              //     //                               (Route<dynamic> route) => false);
              //     //                         } else {
              //     //                           Navigator.pop(context);
              //     //                         }
              //     //                       },
              //     //                       child: Padding(
              //     //                         padding: const EdgeInsets.all(
              //     //                             kDefaultPadding / 2),
              //     //                         child: Icon(Icons.arrow_back,
              //     //                             color: kBlackColor, size: 22),
              //     //                       ),
              //     //                     ),
              //     //                   ),
              //     //                 ),
              //     //                 if (widget.item['image_url'].length > 0)
              //     //                   ClipOval(
              //     //                     child: Material(
              //     //                       color: Colors.white.withValues(alpha: 0.85),
              //     //                       child: InkWell(
              //     //                         onTap: () {
              //     //                           Navigator.push(
              //     //                             context,
              //     //                             MaterialPageRoute(
              //     //                               builder: (context) {
              //     //                                 return PhotoViewer(
              //     //                                   imageUrl:
              //     //                                       widget.item['image_url'][0],
              //     //                                   itemName: widget.item['name'],
              //     //                                 );
              //     //                               },
              //     //                             ),
              //     //                           );
              //     //                         },
              //     //                         child: Padding(
              //     //                           padding: const EdgeInsets.all(8.0),
              //     //                           child: Icon(Icons.zoom_out_map,
              //     //                               color: kBlackColor, size: 22),
              //     //                         ),
              //     //                       ),
              //     //                     ),
              //     //                   ),
              //     //               ],
              //     //             ),
              //     //           ),
              //   ],
              // ),
              //     ),
              //   ),
              // ),
              // 2. Sticky note input and specifications title
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverAppBarDelegate(
                  minHeight: getProportionateScreenHeight(70),
                  maxHeight: getProportionateScreenHeight(70),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              // left: width * 0.75,
                              horizontal: getProportionateScreenWidth(
                                  kDefaultPadding / 2),
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 4)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return NotificationStore(
                                        storeId: widget.item['store_id'],
                                        storeName: "Loading...");
                                  }));
                                },
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: kDefaultPadding / 2,
                                        vertical: kDefaultPadding / 4),
                                    decoration: BoxDecoration(
                                        color: kSecondaryColor.withValues(
                                            alpha: 0.13),
                                        borderRadius: BorderRadius.circular(
                                            kDefaultPadding / 2)),
                                    child: Row(
                                      spacing: kDefaultPadding / 3,
                                      children: [
                                        Icon(
                                          size: 16,
                                          Icons.more_outlined,
                                          color: kSecondaryColor,
                                        ),
                                        Text(
                                          "More items",
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                // fontWeight: FontWeight.w900,
                                                color: kSecondaryColor,
                                              ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    )),
                              ),
                              InkWell(
                                child: Container(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding / 3),
                                      vertical: getProportionateScreenWidth(
                                          kDefaultPadding / 2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: kSecondaryColor,
                                          size: 18,
                                        ),
                                        Text(
                                          "${Provider.of<ZLanguage>(context).note} ",
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                  color: kSecondaryColor,
                                                  fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        kSecondaryColor.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(
                                        kDefaultPadding / 2),
                                  ),
                                ),
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: kPrimaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                    builder: (BuildContext context) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: getProportionateScreenWidth(
                                              kDefaultPadding),
                                          right: getProportionateScreenWidth(
                                              kDefaultPadding),
                                          top: getProportionateScreenHeight(
                                              kDefaultPadding),
                                          bottom: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom +
                                              getProportionateScreenHeight(
                                                  kDefaultPadding * 2),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Add Note",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: kBlackColor,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.close,
                                                      color: kBlackColor),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          kWhiteColor),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            Container(
                                              constraints: BoxConstraints(
                                                  minHeight: 120),
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color:
                                                        kGreyColor.withValues(
                                                            alpha: 0.2)),
                                              ),
                                              child: TextField(
                                                style: TextStyle(
                                                    color: kBlackColor),
                                                maxLines: null,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                onChanged: (val) {
                                                  note = val;
                                                },
                                                decoration:
                                                    InputDecoration.collapsed(
                                                  hintText:
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .note,
                                                  hintStyle: TextStyle(
                                                      color: kGreyColor),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      kSecondaryColor,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                  "Add",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(
                                left: kDefaultPadding / 2,
                                bottom: kDefaultPadding / 4),
                            child: widget.item['specifications'].length > 0
                                ? Text(
                                    "Specifications",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kBlackColor,
                                    ),
                                  )
                                : Text(
                                    Provider.of<ZLanguage>(context).noExtra)),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Specifications list
              if (widget.item['specifications'].length > 0)
                SliverToBoxAdapter(
                    child: Container(
                  decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(30))),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.item['specifications'].length,
                    separatorBuilder: (context, idx) => SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding),
                        vertical:
                            getProportionateScreenHeight(kDefaultPadding)),
                    itemBuilder: (context, index) {
                      final spec = widget.item['specifications'][index];
                      final isRequired = spec['is_required'] == true;
                      final specName = widget.item['specifications'].length > 1
                          ? Service.capitalizeFirstLetters(
                              spec['name'].toString())
                          : "Size";
                      // Provider.of<ZLanguage>(context).size;
                      final options = spec['list'];
                      return Container(
                        padding: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding)),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(kDefaultPadding),
                          border: Border.all(
                            color: isRequired
                                ? kSecondaryColor.withValues(alpha: 0.10)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  specName,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kBlackColor,
                                  ),
                                ),
                                SizedBox(width: 8),
                                if (isRequired)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: kDefaultPadding / 2,
                                        vertical: kDefaultPadding / 4),
                                    decoration: BoxDecoration(
                                      color: kSecondaryColor.withValues(
                                          alpha: 0.13),
                                      borderRadius: BorderRadius.circular(
                                          kDefaultPadding),
                                    ),
                                    child: Text(
                                      "Required",
                                      style: textTheme.labelMedium!.copyWith(
                                        color: kSecondaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: kDefaultPadding / 2),
                            Text(
                              "${Provider.of<ZLanguage>(context).chooseOne}",
                              style: textTheme.labelSmall,
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(options.length, (idx) {
                                final opt = options[idx];
                                final isSelected = selected.any((element) =>
                                    element.uniqueId == opt['unique_id']);
                                final price = opt['price'] ?? 0;
                                return ChoiceChip(
                                  checkmarkColor: kSecondaryColor,
                                  label: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(Service.capitalizeFirstLetters(
                                          opt['name'].toString())),
                                      if (price > 0) ...[
                                        SizedBox(width: 4),
                                        Text(
                                          "${Provider.of<ZMetaData>(context, listen: false).currency} ${price.toStringAsFixed(2)}",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: kSecondaryColor,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ]
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor:
                                      kSecondaryColor.withValues(alpha: 0.13),
                                  backgroundColor: kPrimaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? kSecondaryColor
                                        : kBlackColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected
                                          ? kSecondaryColor.withValues(
                                              alpha: 0.13)
                                          : Colors.transparent,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  onSelected: (_) {
                                    ListElement specItem = ListElement(
                                        uniqueId: opt['unique_id'],
                                        price: price + .0);

                                    if (specification!
                                            .where((element) =>
                                                element.uniqueId ==
                                                spec['unique_id'])
                                            .length >
                                        0) {
                                      var specObj = (specification!.firstWhere(
                                          (element) =>
                                              element.uniqueId ==
                                              spec['unique_id']));
                                      if (specObj.list!
                                              .where((element) =>
                                                  element.uniqueId ==
                                                  specItem.uniqueId)
                                              .length >
                                          0) {
                                        setState(() {
                                          specObj.list!.removeWhere((element) =>
                                              element.uniqueId ==
                                              specItem.uniqueId);
                                          selected.removeWhere((element) =>
                                              element.uniqueId ==
                                              specItem.uniqueId);
                                          if (specObj.list!.length == 0) {
                                            setState(() {
                                              specification!.removeWhere(
                                                  (element) =>
                                                      element.uniqueId ==
                                                      specObj.uniqueId);
                                            });
                                          }
                                        });
                                      } else {
                                        if (spec['type'] == 2) {
                                          if (spec['range'] == 0) {
                                            setState(() {
                                              specObj.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          } else if (specObj.list!.length <
                                              spec['range']) {
                                            setState(() {
                                              specObj.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          }
                                        } else {
                                          try {
                                            setState(() {
                                              selected.removeWhere((element) =>
                                                  element.uniqueId ==
                                                  specObj.list![0].uniqueId);
                                              specObj.list!.removeAt(0);
                                              specObj.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          } catch (e) {
                                            setState(() {
                                              specObj.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          }
                                        }
                                      }
                                    } else {
                                      setState(() {
                                        Specification specNew = Specification(
                                            uniqueId: spec['unique_id'],
                                            list: [specItem]);
                                        specification!.add(specNew);
                                        selected.add(specItem);
                                      });
                                    }
                                    checkRequired();
                                    updatePrice();
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
                    // : Container()
                    // Center(
                    //     child: Text(Provider.of<ZLanguage>(context).noExtra),
                    //   ),
                    ),
            ],
          ),
          // 4. Fixed bottom bar
        ],
      ),
    );
  }

  void _showDialog(item, destination, storeLocation) {
    showDialog(
        context: context,
        builder: (BuildContext alertContext) {
          return AlertDialog(
            backgroundColor: kPrimaryColor,
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
                    addToCart(item, destination, storeLocation);
                  });

                  Navigator.of(alertContext).pop();
                  Future.delayed(Duration(seconds: 2));
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  // Future<String?> showItem3DModel(
  //     {required String title,
  //     required BuildContext context,
  //     required TextTheme textTheme}) async {
  //   return await showModalBottomSheet<String>(
  //     context: context,
  //     showDragHandle: true,
  //     clipBehavior: Clip.hardEdge,
  //     backgroundColor: kPrimaryColor,
  //     builder: (ctx) {
  //       return Padding(
  //         padding: EdgeInsets.symmetric(
  //             horizontal: getProportionateScreenWidth(kDefaultPadding)),
  //         child: SizedBox(
  //           height: MediaQuery.sizeOf(context).height * 0.5,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 title,
  //                 style: textTheme.headlineSmall?.copyWith(
  //                   fontWeight: FontWeight.bold,
  //                   color: kBlackColor,
  //                 ),
  //               ),
  //               SizedBox(
  //                   height: getProportionateScreenHeight(kDefaultPadding / 2)),
  //               Container(
  //                   height: MediaQuery.sizeOf(context).height * 0.4,
  //                   decoration: BoxDecoration(
  //                       color: Colors.grey,
  //                       gradient: RadialGradient(
  //                           colors: [Color(0xffffffff), Colors.grey],
  //                           stops: [0.1, 1.0],
  //                           radius: 0.7,
  //                           center: Alignment.center),
  //                       borderRadius: BorderRadius.circular(kDefaultPadding)),
  //                   child: ModelViewer(
  //                     src:
  //                         'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
  //                     alt: "3d model",
  //                     ar: true,
  //                     autoRotate: true,
  //                     cameraControls: true,
  //                     disableZoom: false,
  //                     autoPlay: true,
  //                     iosSrc:
  //                         'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
  //                     shadowIntensity: 1,
  //                   )),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}

//////old//////////////
// import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/custom_widgets/custom_button.dart';
// import 'package:zmall/item/components/photo_viewer.dart';
// import 'package:zmall/login/login_screen.dart';
// import 'package:zmall/models/cart.dart';
// import 'package:zmall/models/language.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/notifications/notification_store.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';

// class Body extends StatefulWidget {
//   const Body({
//     Key? key,
//     required this.item,
//     required this.location,
//     this.isDineIn = false,
//     required this.tableNumber,
//     this.isSplashRedirect = false,
//   }) : super(key: key);

//   final item;
//   final location;
//   final isDineIn;
//   final tableNumber;
//   final isSplashRedirect;

//   @override
//   _BodyState createState() => _BodyState();
// }

// class _BodyState extends State<Body> {
//   var userData;
//   List<int>? requiredSpecs = List.empty(growable: true);
//   int reqCount = 0;
//   int quantity = 1;
//   String note = "";
//   bool clearedRequired = false;
//   Cart? cart;
//   double? longitude, latitude;
//   double? initialPrice;
//   double? price;
//   List<Specification>? specification = [];
//   List<ListElement> selected = [];
//   List count = [];

//   void requiredCount() {
//     if (widget.item['specifications'].length > 0) {
//       for (var index = 0;
//           index < widget.item['specifications'].length;
//           index++) {
//         if (widget.item['specifications'][index]['is_required']) {
//           setState(() {
//             reqCount += 1;
//             requiredSpecs
//                 ?.add(widget.item['specifications'][index]['unique_id']);
//           });
//         }
//       }
//       if (reqCount == 0) {
//         setState(() {
//           clearedRequired = true;
//         });
//       }
//       // debugPrint("$reqCount required specifications found");
//       // debugPrint(requiredSpecs);
//     } else {
//       setState(() {
//         clearedRequired = true;
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     getUser();
//     // debugPrint("Item: ${widget.item}");
//     // debugPrint("specifications: ${widget.item['specifications']}");
//     requiredCount();
//     getCart();
//     initialPrice = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
//     price = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
//   }

//   void updatePrice() {
//     double temPrice = 0;
//     specification!.forEach((spec) {
//       spec.list!.forEach((element) {
//         temPrice += element.price!;
//         // debugPrint(element.price);
//       });
//     });
//     setState(() {
//       price = (initialPrice! + temPrice) * quantity;
//     });
//   }

//   void checkRequired() {
//     if (reqCount != 0) {
//       int count = 0;
//       specification!.forEach((element) {
//         if (requiredSpecs!.contains(element.uniqueId)) {
//           count += 1;
//         }
//         // debugPrint("$count/$reqCount required specifications added");
//       });
//       if (reqCount == count) {
//         setState(() {
//           clearedRequired = true;
//         });
//       } else {
//         setState(() {
//           clearedRequired = false;
//         });
//       }
//     } else {
//       setState(() {
//         clearedRequired = true;
//       });
//     }
//   }

//   void getUser() async {
//     var data = await Service.read('user');
//     if (data != null) {
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

//   void getCart() async {
//     var data = await Service.read('cart');
//     // debugPrint(data);
//     if (data != null) {
//       setState(() {
//         cart = Cart.fromJson(data);
//       });
//     }
//   }

//   void addToCart(item, destination, storeLocation) {
//     cart = Cart(
//       userId: userData['user']['_id'],
//       items: [item],
//       serverToken: userData['user']['server_token'],
//       destinationAddress: destination,
//       storeId: widget.item['store_id'],
//       storeLocation: storeLocation,
//     );
//     // debugPrint(cart!.toJson());
//     // debugPrint("cart ${cart!.toJson()}");
//     Service.save('cart', cart!.toJson());

//     Service.showMessage(
//         context: context, title: "Item added to cart!", error: false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: SafeArea(
        // child: Container(
        //   width: double.infinity,
        //   // height: kDefaultPadding * 4,
        //   padding: EdgeInsets.symmetric(
        //     vertical: getProportionateScreenHeight(kDefaultPadding / 2),
        //     horizontal: getProportionateScreenHeight(kDefaultPadding),
        //   ),
        //   decoration: BoxDecoration(
        //       color: kPrimaryColor,
        //       border: Border(top: BorderSide(color: kWhiteColor)),
        //       borderRadius: BorderRadius.only(
        //           topLeft: Radius.circular(kDefaultPadding),
        //           topRight: Radius.circular(kDefaultPadding))),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             spacing: kDefaultPadding / 2,
//             children: [
//               ////proce section
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "${Provider.of<ZLanguage>(context).price}: ",
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodyLarge
//                         ?.copyWith(color: kBlackColor),
//                   ),
//                   Text(
//                     "${Provider.of<ZMetaData>(context, listen: false).currency} ${price!.toStringAsFixed(2)}",
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         color: kBlackColor, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),

//               ////
//               ///button section///
//               Container(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     InkWell(
//                       child: Container(
//                         child: Padding(
//                           padding: EdgeInsets.all(
//                             getProportionateScreenWidth(kDefaultPadding / 3),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.add,
//                                 color: kSecondaryColor,
//                                 size: getProportionateScreenWidth(18),
//                               ),
//                               Text(
//                                 Provider.of<ZLanguage>(context).note,
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .labelLarge
//                                     ?.copyWith(
//                                         color: kSecondaryColor,
//                                         fontWeight: FontWeight.bold),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         ),
//                         decoration: BoxDecoration(
//                           color: kSecondaryColor.withValues(alpha: 0.2),
//                           border: Border.all(color: kWhiteColor),
//                           borderRadius:
//                               BorderRadius.circular(kDefaultPadding / 2),
//                         ),
//                       ),
//                       onTap: () {
//                         showAddNoteBottomSheet();
//                         // showDialog(
//                         //   context: context,
//                         //   builder: (BuildContext context) {
//                         //     return AlertDialog(
//                         //       backgroundColor: kPrimaryColor,
//                         //       title: Text(Provider.of<ZLanguage>(context).note),
//                         //       content: TextField(
//                         //         style: TextStyle(color: kBlackColor),
//                         //         maxLines: null,
//                         //         keyboardType: TextInputType.multiline,
//                         //         onChanged: (val) {
//                         //           note = val;
//                         //         },
//                         //         decoration: textFieldInputDecorator.copyWith(
//                         //             labelText:
//                         //                 Provider.of<ZLanguage>(context).note),
//                         //       ),
//                         //       actions: <Widget>[
//                         //         TextButton(
//                         //           child: Text(
//                         //             Provider.of<ZLanguage>(context).note,
//                         //             style: TextStyle(
//                         //               color: kSecondaryColor,
//                         //               fontWeight: FontWeight.bold,
//                         //             ),
//                         //           ),
//                         //           onPressed: () {
//                         //             Navigator.of(context).pop();
//                         //           },
//                         //         ),
//                         //       ],
//                         //     );
//                         //   },
//                         // );
//                       },
//                     ),
//                     SizedBox(
//                       width: getProportionateScreenWidth(kDefaultPadding),
//                     ),
//                     Expanded(
//                       child: CustomButton(
//                         title: Provider.of<ZLanguage>(context).addToCart,
//                         press: clearedRequired && price != 0
//                             ? () async {
//                                 await Service.remove('images');

//                                 Item item = Item(
//                                   id: widget.item['_id'],
//                                   quantity: quantity,
//                                   specification: specification,
//                                   noteForItem: note,
//                                   price: price,
//                                   itemName: widget.item['name'],
//                                   imageURL: widget.item['image_url'].length > 0
//                                       ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.item['image_url'][0]}"
//                                       : "https://ibb.co/vkhzjd6",
//                                 );
//                                 StoreLocation storeLocation = StoreLocation(
//                                     long: widget.location[1],
//                                     lat: widget.location[0]);
//                                 DestinationAddress destination =
//                                     DestinationAddress(
//                                   long: Provider.of<ZMetaData>(context,
//                                           listen: false)
//                                       .longitude,
//                                   lat: Provider.of<ZMetaData>(context,
//                                           listen: false)
//                                       .latitude,
//                                   name: "Current Location",
//                                   note: "User current location",
//                                 );
//                                 if (cart != null) {
//                                   if (userData != null) {
//                                     if (cart!.storeId ==
//                                         widget.item['store_id']) {
//                                       setState(() {
//                                         cart!.items!.add(item);
//                                         Service.save('cart', cart);

//                                         Service.showMessage(
//                                             context: context,
//                                             title: "Item added to cart",
//                                             error: false);
//                                         Navigator.of(context).pop();
//                                       });
//                                       // debugPrint("cart ${cart!.toJson()}");
//                                     } else {
//                                       _showDialog(
//                                           item, destination, storeLocation);
//                                     }
//                                   } else {
//                                     // debugPrint("User not logged in...");

//                                     Service.showMessage(
//                                         context: context,
//                                         title: "Please login in...",
//                                         error: true);
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => LoginScreen(
//                                           firstRoute: false,
//                                         ),
//                                       ),
//                                     ).then((value) => getUser());
//                                   }
//                                 } else {
//                                   if (userData != null) {
//                                     // debugPrint("Empty cart! Adding new item.");
//                                     addToCart(item, destination, storeLocation);
//                                     Navigator.of(context).pop();
//                                   } else {
//                                     // debugPrint("User not logged in...");

//                                     Service.showMessage(
//                                         context: context,
//                                         title: "Please login in...",
//                                         error: true);
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => LoginScreen(
//                                           firstRoute: false,
//                                         ),
//                                       ),
//                                     ).then((value) => getUser());
//                                   }
//                                 }
//                               }
//                             : () {
//                                 Service.showMessage(
//                                     context: context,
//                                     title:
//                                         "Make sure to select required specifications!",
//                                     error: true);
//                               },
//                         color: clearedRequired && price != 0
//                             ? kSecondaryColor
//                             : kGreyColor.withValues(alpha: 0.7),
//                       ),
//                     ),
//                     SizedBox(
//                       width: getProportionateScreenWidth(kDefaultPadding),
//                     ),
//                     Row(
//                       children: [
//                         InkWell(
//                           child: Container(
//                             child: Padding(
//                               padding: EdgeInsets.all(
//                                 getProportionateScreenWidth(
//                                     kDefaultPadding / 3),
//                               ),
//                               child: Icon(
//                                 Icons.remove,
//                                 color: kPrimaryColor,
//                               ),
//                             ),
//                             decoration: BoxDecoration(
//                               color: quantity != 1
//                                   ? kSecondaryColor
//                                   : kGreyColor.withValues(alpha: 0.7),
//                               borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(kDefaultPadding / 2),
//                                 bottomLeft:
//                                     Radius.circular(kDefaultPadding / 2),
//                               ),
//                             ),
//                           ),
//                           onTap: quantity != 1
//                               ? () {
//                                   setState(() {
//                                     quantity -= 1;
//                                     updatePrice();
//                                   });
//                                 }
//                               : () {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                       Service.showMessage1(
//                                           "Minimum order quantity is 1", true));
//                                 },
//                         ),
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: getProportionateScreenWidth(
//                                   kDefaultPadding / 3)),
//                           child: Text(
//                             quantity.toString(),
//                             style: Theme.of(context).textTheme.titleLarge,
//                           ),
//                         ),
//                         InkWell(
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: kSecondaryColor,
//                               borderRadius: BorderRadius.only(
//                                 topRight: Radius.circular(kDefaultPadding / 2),
//                                 bottomRight:
//                                     Radius.circular(kDefaultPadding / 2),
//                               ),
//                             ),
//                             child: Padding(
//                               padding: EdgeInsets.all(
//                                 getProportionateScreenWidth(
//                                     kDefaultPadding / 3),
//                               ),
//                               child: Icon(
//                                 Icons.add,
//                                 color: kPrimaryColor,
//                               ),
//                             ),
//                           ),
//                           onTap: () {
//                             setState(() {
//                               quantity += 1;
//                               updatePrice();
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           //////image section
//           Container(
//             decoration: BoxDecoration(
//               color: kPrimaryColor,
//               // borderRadius: BorderRadius.only(
//               //   bottomLeft:
//               //       Radius.circular(getProportionateScreenWidth(kDefaultPadding)),
//               //   bottomRight:
//               //       Radius.circular(getProportionateScreenWidth(kDefaultPadding)),
//               // ),
//             ),
//             child: Stack(
//               children: [
//                 InkWell(
//                   child: CachedNetworkImage(
//                     imageUrl: widget.item['image_url'].length > 0
//                         ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.item['image_url'][0]}"
//                         : "https://ibb.co/vkhzjd6",
//                     imageBuilder: (context, imageProvider) => Container(
//                       width: double.infinity,
//                       height:
//                           getProportionateScreenHeight(kDefaultPadding * 20),
//                       decoration: BoxDecoration(
//                         color: kPrimaryColor,
//                         boxShadow: [boxShadow],
//                         // borderRadius: BorderRadius.only(
//                         //   bottomLeft: Radius.circular(
//                         //       getProportionateScreenWidth(kDefaultPadding / 2)),
//                         //   bottomRight: Radius.circular(
//                         //       getProportionateScreenWidth(kDefaultPadding / 2)),
//                         // ),
//                         image: DecorationImage(
//                           fit: BoxFit.cover,
//                           image: imageProvider,
//                         ),
//                       ),
//                     ),
//                     placeholder: (context, url) => Center(
//                       child: Container(
//                         width: double.infinity,
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding * 16),
//                         child: Center(
//                           child: CircularProgressIndicator(
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(kSecondaryColor),
//                           ),
//                         ),
//                       ),
//                     ),
//                     errorWidget: (context, url, error) => Padding(
//                       padding: EdgeInsets.only(
//                           top: getProportionateScreenHeight(
//                               kDefaultPadding / 2)),
//                       child: Container(
//                         width: double.infinity,
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding * 16),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.only(
//                             bottomRight: Radius.circular(kDefaultPadding),
//                             bottomLeft: Radius.circular(kDefaultPadding),
//                           ),
//                           color: kPrimaryColor,
//                           image: DecorationImage(
//                             fit: BoxFit.fitHeight,
//                             image: AssetImage(zmallLogo),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   onTap: () {
//                     if (widget.item['image_url'].length > 0) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) {
//                             return PhotoViewer(
//                               imageUrl: widget.item['image_url'][0],
//                               itemName: widget.item['name'],
//                             );
//                           },
//                         ),
//                       );
//                     }
//                   },
//                 ),
//                 widget.item['image_url'].length > 0
//                     ? Align(
//                         alignment: Alignment.centerRight,
//                         child: SafeArea(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(
//                               horizontal:
//                                   getProportionateScreenWidth(kDefaultPadding),
//                               // vertical: getProportionateScreenWidth(
//                               //     kDefaultPadding * 1.5)
//                             ),
//                             child: IconButton(
//                                 icon: Icon(
//                                   Icons.zoom_out_map,
//                                   color: kBlackColor,
//                                 ),
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) {
//                                         return PhotoViewer(
//                                           imageUrl: widget.item['image_url'][0],
//                                           itemName: widget.item['name'],
//                                         );
//                                       },
//                                     ),
//                                   );
//                                 },
//                                 style: IconButton.styleFrom(
//                                     backgroundColor: kWhiteColor)),
//                           ),
//                         ),
//                       )
//                     : Container(),
//                 SizedBox(
//                   height: getProportionateScreenHeight(kDefaultPadding / 4),
//                 ),
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: SafeArea(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal:
//                             getProportionateScreenWidth(kDefaultPadding),
//                         // vertical:
//                         //     getProportionateScreenWidth(kDefaultPadding * 1.5)
//                       ),
//                       child: IconButton(
//                           icon: Icon(
//                             Icons.arrow_back_rounded,
//                             color: kBlackColor,
//                           ),
//                           onPressed: () {
//                             if (widget.isSplashRedirect) {
//                               Navigator.pushNamedAndRemoveUntil(context,
//                                   "/start", (Route<dynamic> route) => false);
//                             } else {
//                               Navigator.pop(context);
//                             }
//                           },
//                           style: IconButton.styleFrom(
//                               backgroundColor: kWhiteColor)),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           /////item name and details section//////
//           Container(
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
//                 vertical: getProportionateScreenWidth(kDefaultPadding / 2),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           Service.capitalizeFirstLetters(widget.item['name']),
//                           style:
//                               Theme.of(context).textTheme.titleMedium?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: kBlackColor,
//                                   ),
//                           textAlign: TextAlign.left,
//                         ),
//                       ),
                  //     InkWell(
                  //       onTap: () {
                  //         Navigator.push(context,
                  //             MaterialPageRoute(builder: (context) {
                  //           return NotificationStore(
                  //               storeId: widget.item['store_id'],
                  //               storeName: "Loading...");
                  //         }));
                  //       },
                  //       child: Container(
                  //           padding: EdgeInsets.symmetric(
                  //               horizontal: kDefaultPadding / 2,
                  //               vertical: kDefaultPadding / 4),
                  //           decoration: BoxDecoration(
                  //               color: kSecondaryColor.withValues(alpha: 0.2),
                  //               borderRadius:
                  //                   BorderRadius.circular(kDefaultPadding / 2)),
                  //           child: Row(
                  //             spacing: kDefaultPadding / 3,
                  //             children: [
                  //               Icon(
                  //                 size: 16,
                  //                 Icons.more_outlined,
                  //                 color: kSecondaryColor,
                  //               ),
                  //               Text(
                  //                 "More items",
                  //                 style: Theme.of(context)
                  //                     .textTheme
                  //                     .labelLarge
                  //                     ?.copyWith(
                  //                       // fontWeight: FontWeight.w900,
                  //                       color: kSecondaryColor,
                  //                     ),
                  //                 textAlign: TextAlign.left,
                  //               ),
                  //             ],
                  //           )),
                  //     )
                  //   ],
                  // ),

//                   Text(
//                     widget.item['details']
//                         .toString()
//                         .replaceAll("\n", "")
//                         .trim(),
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: kGreyColor,
//                           fontWeight: FontWeight.w400,
//                         ),
//                     textAlign: TextAlign.left,
//                   ),
//                   // SizedBox(
//                   //   height: getProportionateScreenHeight(kDefaultPadding / 5),
//                   // ),
//                 ],
//               ),
//             ),
//           ),
//           // Container(
//           //   width: double.infinity,
//           //   height: 0.2,
//           //   color: kGreyColor,
//           // ),
//           ////////specifications section
//           widget.item['specifications'].length == 0
//               ? Spacer()
//               : Expanded(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                         horizontal:
//                             getProportionateScreenWidth(kDefaultPadding / 2)),
//                     child: ListView.separated(
//                       shrinkWrap: true,
//                       itemCount: widget.item['specifications'].length,
//                       itemBuilder: (context, index) {
//                         return Container(
//                           padding: EdgeInsets.all(
//                             kDefaultPadding,
//                           ),
//                           decoration: BoxDecoration(
//                             color: kPrimaryColor,
//                             boxShadow: [kDefaultShadow],
//                             border: Border.all(color: kWhiteColor),
//                             borderRadius:
//                                 BorderRadius.circular(kDefaultPadding),
//                           ),
//                           child: Column(
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     // mainAxisAlignment: MainAxisAlignment.start,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Container(
//                                         padding: EdgeInsets.symmetric(
//                                             horizontal: kDefaultPadding / 2,
//                                             vertical: kDefaultPadding / 4),
//                                         decoration: BoxDecoration(
//                                             borderRadius: BorderRadius.circular(
//                                                 kDefaultPadding / 2),
//                                             color: kBlackColor.withValues(
//                                                 alpha: 0.2)),
//                                         child: Text(
//                                           "${Service.capitalizeFirstLetters(widget.item['specifications'][index]['name'].toString().toUpperCase())}",
//                                           style: TextStyle(
//                                               color: kBlackColor,
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         height: kDefaultPadding / 2,
//                                       ),
//                                       if (widget.item['specifications'][index]
//                                           ['is_required'])
//                                         Text(
//                                           "${Provider.of<ZLanguage>(context).chooseOne} ${widget.item['specifications'][index]['range']}",
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .labelMedium,
//                                         )
//                                     ],
//                                   ),
//                                   if (widget.item['specifications'][index]
//                                       ['is_required'])
//                                     Container(
//                                       padding: EdgeInsets.symmetric(
//                                           horizontal: kDefaultPadding / 2,
//                                           vertical: kDefaultPadding / 4),
//                                       decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.circular(
//                                               kDefaultPadding),
//                                           color: kSecondaryColor.withValues(
//                                               alpha: 0.2)),
//                                       child: Text(
//                                         Provider.of<ZLanguage>(context)
//                                             .required,
//                                         style: Theme.of(context)
//                                             .textTheme
//                                             .labelMedium!
//                                             .copyWith(color: kSecondaryColor),
//                                         // style: TextStyle(color: kSecondaryColor),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                               SizedBox(
//                                   height: getProportionateScreenHeight(
//                                       kDefaultPadding / 2)),
//                               ListView.separated(
//                                 physics: ClampingScrollPhysics(),
//                                 shrinkWrap: true,
//                                 itemCount: widget
//                                     .item['specifications'][index]['list']
//                                     .length,
//                                 itemBuilder: (context, idx) {
//                                   return InkWell(
//                                     onTap: () {
//                                       ListElement specItem = ListElement(
//                                           uniqueId: widget
//                                                   .item['specifications'][index]
//                                               ['list'][idx]['unique_id'],
//                                           price: widget.item['specifications']
//                                                       [index]['list'][idx]
//                                                   ['price'] +
//                                               .0);

//                                       if (specification!
//                                               .where((element) =>
//                                                   element.uniqueId ==
//                                                   widget.item?['specifications']
//                                                       ?[index]['unique_id'])
//                                               .length >
//                                           0) {
//                                         // debugPrint(specification!.first.toJson());
//                                         // debugPrint(specItem.toJson());
//                                         // debugPrint(
//                                         //     "Specification list with sUnqId ${widget.item['specifications'][index]['unique_id']}  found");

//                                         // Found specification with this unique_id
//                                         var spec = (specification!.firstWhere(
//                                             (element) =>
//                                                 element.uniqueId ==
//                                                 widget.item['specifications']
//                                                     [index]['unique_id']));
//                                         if (spec.list!
//                                                 .where((element) =>
//                                                     element.uniqueId ==
//                                                     specItem.uniqueId)
//                                                 .length >
//                                             0) {
//                                           // Item found in specifications
//                                           setState(() {
//                                             spec.list!.removeWhere((element) =>
//                                                 element.uniqueId ==
//                                                 specItem.uniqueId);
//                                             selected.removeWhere((element) =>
//                                                 element.uniqueId ==
//                                                 specItem.uniqueId);
//                                             if (spec.list!.length == 0) {
//                                               setState(() {
//                                                 specification!.removeWhere(
//                                                     (element) =>
//                                                         element.uniqueId ==
//                                                         spec.uniqueId);
//                                               });
//                                             }
//                                           });
//                                         } else {
//                                           // Item not found in specifications...
//                                           if (widget.item['specifications']
//                                                   [index]['type'] ==
//                                               2) {
//                                             if (widget.item['specifications']
//                                                     [index]['range'] ==
//                                                 0) {
//                                               setState(() {
//                                                 spec.list!.add(specItem);
//                                                 selected.add(specItem);
//                                               });
//                                             } else if (spec.list!.length <
//                                                 widget.item['specifications']
//                                                     [index]['range']) {
//                                               setState(() {
//                                                 spec.list!.add(specItem);
//                                                 selected.add(specItem);
//                                               });
//                                             }
//                                           } else {
//                                             try {
//                                               setState(() {
//                                                 selected.removeWhere(
//                                                     (element) =>
//                                                         element.uniqueId ==
//                                                         spec.list![0].uniqueId);
//                                                 spec.list!.removeAt(0);
//                                                 spec.list!.add(specItem);
//                                                 selected.add(specItem);
//                                               });
//                                             } catch (e) {
//                                               // debugPrint(e);
//                                               setState(() {
//                                                 spec.list!.add(specItem);
//                                                 selected.add(specItem);
//                                               });
//                                             }
//                                           }
//                                         }
//                                       } else {
//                                         // Specification with this unique_id not found adding a new one
//                                         // debugPrint(
//                                         //     "Specification with sUnqId ${widget.item['specifications'][index]['unique_id']} not found");
//                                         setState(() {
//                                           Specification spec = Specification(
//                                               uniqueId:
//                                                   widget.item['specifications']
//                                                       [index]['unique_id'],
//                                               list: [specItem]);
//                                           specification!.add(spec);
//                                           selected.add(specItem);
//                                         });
//                                       }

//                                       checkRequired();
//                                       updatePrice();
//                                     },
//                                     child: Container(
//                                       padding: EdgeInsets.all(
//                                           getProportionateScreenWidth(
//                                               kDefaultPadding / 1.5)),
//                                       decoration: BoxDecoration(
//                                         // boxShadow: [kDefaultShadow],
//                                         border: Border.all(
//                                           color: selected
//                                                       .where((element) =>
//                                                           element.uniqueId ==
//                                                           widget.item['specifications']
//                                                                       ?[index]
//                                                                   ['list'][idx]
//                                                               ['unique_id'])
//                                                       .length >
//                                                   0
//                                               ? kSecondaryColor.withValues(
//                                                   alpha: 0.2)
//                                               : kBlackColor.withValues(
//                                                   alpha: 0.1),
//                                         ),
//                                         color: selected
//                                                     .where((element) =>
//                                                         element.uniqueId ==
//                                                         widget.item['specifications']
//                                                                 ?[index]['list']
//                                                             [idx]['unique_id'])
//                                                     .length >
//                                                 0
//                                             ? kSecondaryColor.withValues(
//                                                 alpha: 0.2)
//                                             : kWhiteColor,
//                                         // color: ((selected.firstWhere(
//                                         //           (it) =>
//                                         //               it.uniqueId ==
//                                         //               widget.item['specifications']
//                                         //                       [index]['list'][idx]
//                                         //                   ['unique_id'],
//                                         //           orElse: () => null,
//                                         //         )) !=
//                                         //         null)
//                                         //     ? kSecondaryColor.withValues(alpha: 0.2)
//                                         //     : kWhiteColor,
//                                         borderRadius: BorderRadius.circular(
//                                           getProportionateScreenWidth(
//                                               kDefaultPadding / 4),
//                                         ),
//                                       ),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   "${Service.capitalizeFirstLetters(widget.item['specifications'][index]['list'][idx]['name'])}",
//                                                   softWrap: true,
//                                                   style: TextStyle(
//                                                     color: selected
//                                                                 .where((element) =>
//                                                                     element
//                                                                         .uniqueId ==
//                                                                     widget.item['specifications']
//                                                                             ?[
//                                                                             index]['list'][idx]
//                                                                         [
//                                                                         'unique_id'])
//                                                                 .length >
//                                                             0
//                                                         ? kSecondaryColor
//                                                         : kBlackColor,
//                                                     fontWeight: selected
//                                                                 .where((element) =>
//                                                                     element
//                                                                         .uniqueId ==
//                                                                     widget.item['specifications']
//                                                                             ?[
//                                                                             index]['list'][idx]
//                                                                         [
//                                                                         'unique_id'])
//                                                                 .length >
//                                                             0
//                                                         ? FontWeight.bold
//                                                         : FontWeight.normal,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           Text(
//                                             "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.item['specifications'][index]['list'][idx]['price'].toStringAsFixed(2)}",
//                                             style: TextStyle(
//                                               color: selected
//                                                           .where((element) =>
//                                                               element
//                                                                   .uniqueId ==
//                                                               widget.item['specifications']
//                                                                           ?[
//                                                                           index]
//                                                                       [
//                                                                       'list'][idx]
//                                                                   ['unique_id'])
//                                                           .length >
//                                                       0
//                                                   ? kSecondaryColor
//                                                   : kBlackColor,
//                                               fontWeight: selected
//                                                           .where((element) =>
//                                                               element
//                                                                   .uniqueId ==
//                                                               widget.item['specifications']
//                                                                           ?[
//                                                                           index]
//                                                                       [
//                                                                       'list'][idx]
//                                                                   ['unique_id'])
//                                                           .length >
//                                                       0
//                                                   ? FontWeight.bold
//                                                   : FontWeight.normal,
//                                             ),
//                                           )
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                                 separatorBuilder:
//                                     (BuildContext context, int index) =>
//                                         SizedBox(
//                                   height: getProportionateScreenHeight(
//                                       kDefaultPadding / 2),
//                                 ),
//                               )
//                             ],
//                           ),
//                         );
//                       },
//                       separatorBuilder: (BuildContext context, int index) =>
//                           SizedBox(
//                         height: getProportionateScreenHeight(kDefaultPadding),
//                       ),
//                     ),
//                   ),
//                 ),
//           // widget.item['specifications'].length > 0 ? Container() : Spacer(),

//           //////////price and button section////
//         ],
//       ),
//     );
//   }

//   void _showDialog(item, destination, storeLocation) {
//     showDialog(
//         context: context,
//         builder: (BuildContext alertContext) {
//           return AlertDialog(
//             title: Text(Provider.of<ZLanguage>(context).warning),
//             content: Text(Provider.of<ZLanguage>(context).itemsFound),
//             actions: [
//               TextButton(
//                 child: Text(
//                   Provider.of<ZLanguage>(context).cancel,
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
//                   Provider.of<ZLanguage>(context).clear,
//                   style: TextStyle(
//                     color: kSecondaryColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     cart!.toJson();
//                     Service.remove('cart');
//                     Service.remove('aliexpressCart');
//                     cart = Cart();
//                     addToCart(item, destination, storeLocation);
//                   });

//                   Navigator.of(alertContext).pop();
//                   Future.delayed(Duration(seconds: 2));
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         });
//   }

//   void showAddNoteBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: kPrimaryColor,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (BuildContext context) {
//         return Padding(
//           padding: EdgeInsets.only(
//             left: getProportionateScreenWidth(kDefaultPadding),
//             right: getProportionateScreenWidth(kDefaultPadding),
//             top: getProportionateScreenHeight(kDefaultPadding),
//             bottom: MediaQuery.of(context).viewInsets.bottom +
//                 getProportionateScreenHeight(kDefaultPadding * 2),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Add Note",
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: kBlackColor,
//                         ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.close, color: kBlackColor),
//                     onPressed: () => Navigator.of(context).pop(),
//                     style: IconButton.styleFrom(backgroundColor: kWhiteColor),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12),
//               Container(
//                 constraints: BoxConstraints(minHeight: 120),
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: kGreyColor.withValues(alpha: 0.2)),
//                 ),
//                 child: TextField(
//                   style: TextStyle(color: kBlackColor),
//                   maxLines: null,
//                   keyboardType: TextInputType.multiline,
//                   onChanged: (val) {
//                     note = val;
//                   },
//                   decoration: InputDecoration.collapsed(
//                     hintText: Provider.of<ZLanguage>(context).note,
//                     hintStyle: TextStyle(color: kGreyColor),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kSecondaryColor,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text(
//                     "Add",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
