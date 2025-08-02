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


class Body extends StatefulWidget {
  const Body({
    Key? key,
    required this.item,
    required this.location,
    this.isDineIn = false,
    required this.tableNumber,
    this.isSplashRedirect = false,
  }) : super(key: key);

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
      // debugPrint("$reqCount required specifications found");
      // debugPrint(requiredSpecs);
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
    // debugPrint("Item: ${widget.item}");
    // debugPrint("specifications: ${widget.item['specifications']}");
    requiredCount();
    getCart();
    initialPrice = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
    price = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
  }

  void updatePrice() {
    double temPrice = 0;
    specification!.forEach((spec) {
      spec.list!.forEach((element) {
        temPrice += element.price!;
        // debugPrint(element.price);
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
        // debugPrint("$count/$reqCount required specifications added");
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
    // debugPrint(data);
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
    // debugPrint(cart!.toJson());
    // debugPrint("cart ${cart!.toJson()}");
    Service.save('cart', cart!.toJson());
    ScaffoldMessenger.of(context)
        .showSnackBar(Service.showMessage("Item added to cart!", false));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //////image section
        Container(
          decoration: BoxDecoration(
            color: kPrimaryColor,
            // borderRadius: BorderRadius.only(
            //   bottomLeft:
            //       Radius.circular(getProportionateScreenWidth(kDefaultPadding)),
            //   bottomRight:
            //       Radius.circular(getProportionateScreenWidth(kDefaultPadding)),
            // ),
          ),
          child: Stack(
            children: [
              InkWell(
                child: CachedNetworkImage(
                  imageUrl: widget.item['image_url'].length > 0
                      ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.item['image_url'][0]}"
                      : "https://ibb.co/vkhzjd6",
                  imageBuilder: (context, imageProvider) => Container(
                    width: double.infinity,
                    height: getProportionateScreenHeight(kDefaultPadding * 20),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      boxShadow: [boxShadow],
                      // borderRadius: BorderRadius.only(
                      //   bottomLeft: Radius.circular(
                      //       getProportionateScreenWidth(kDefaultPadding / 2)),
                      //   bottomRight: Radius.circular(
                      //       getProportionateScreenWidth(kDefaultPadding / 2)),
                      // ),
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
                          getProportionateScreenHeight(kDefaultPadding * 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kSecondaryColor),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Padding(
                    padding: EdgeInsets.only(
                        top: getProportionateScreenHeight(kDefaultPadding / 2)),
                    child: Container(
                      width: double.infinity,
                      height:
                          getProportionateScreenHeight(kDefaultPadding * 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(kDefaultPadding),
                          bottomLeft: Radius.circular(kDefaultPadding),
                        ),
                        color: kPrimaryColor,
                        image: DecorationImage(
                          fit: BoxFit.fitHeight,
                          image: AssetImage(zmallLogo),
                        ),
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  if (widget.item['image_url'].length > 0) {
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
                  }
                },
              ),
              widget.item['image_url'].length > 0
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding),
                            // vertical: getProportionateScreenWidth(
                            //     kDefaultPadding * 1.5)
                          ),
                          child: IconButton(
                              icon: Icon(
                                Icons.zoom_out_map,
                                color: kBlackColor,
                              ),
                              onPressed: () {
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
                              style: IconButton.styleFrom(
                                  backgroundColor: kWhiteColor)),
                        ),
                      ),
                    )
                  : Container(),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 4),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                      // vertical:
                      //     getProportionateScreenWidth(kDefaultPadding * 1.5)
                    ),
                    child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: kBlackColor,
                        ),
                        onPressed: () {
                          if (widget.isSplashRedirect) {
                            Navigator.pushNamedAndRemoveUntil(context, "/start",
                                (Route<dynamic> route) => false);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style:
                            IconButton.styleFrom(backgroundColor: kWhiteColor)),
                  ),
                ),
              ),
            ],
          ),
        ),

        /////item name and details section//////
        Container(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
              vertical: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Service.capitalizeFirstLetters(widget.item['name']),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kBlackColor,
                                ),
                        textAlign: TextAlign.left,
                      ),
                    ),
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
                              color: kSecondaryColor.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(kDefaultPadding / 2)),
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
                    )
                  ],
                ),

                Text(
                  widget.item['details'].toString().replaceAll("\n", "").trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kGreyColor,
                        fontWeight: FontWeight.w400,
                      ),
                  textAlign: TextAlign.left,
                ),
                // SizedBox(
                //   height: getProportionateScreenHeight(kDefaultPadding / 5),
                // ),
              ],
            ),
          ),
        ),
        // Container(
        //   width: double.infinity,
        //   height: 0.2,
        //   color: kGreyColor,
        // ),
        ////////specifications section
        widget.item['specifications'].length == 0
            ? Spacer()
            : Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.item['specifications'].length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: EdgeInsets.all(
                          kDefaultPadding,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          boxShadow: [kDefaultShadow],
                          border: Border.all(color: kWhiteColor),
                          borderRadius: BorderRadius.circular(kDefaultPadding),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  // mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: kDefaultPadding / 2,
                                          vertical: kDefaultPadding / 4),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              kDefaultPadding / 2),
                                          color: kBlackColor.withValues(
                                              alpha: 0.2)),
                                      child: Text(
                                        "${Service.capitalizeFirstLetters(widget.item['specifications'][index]['name'].toString().toUpperCase())}",
                                        style: TextStyle(
                                            color: kBlackColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(
                                      height: kDefaultPadding / 2,
                                    ),
                                    if (widget.item['specifications'][index]
                                        ['is_required'])
                                      Text(
                                        "${Provider.of<ZLanguage>(context).chooseOne} ${widget.item['specifications'][index]['range']}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      )
                                  ],
                                ),
                                if (widget.item['specifications'][index]
                                    ['is_required'])
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: kDefaultPadding / 2,
                                        vertical: kDefaultPadding / 4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            kDefaultPadding),
                                        color: kSecondaryColor.withValues(
                                            alpha: 0.2)),
                                    child: Text(
                                      Provider.of<ZLanguage>(context).required,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .copyWith(color: kSecondaryColor),
                                      // style: TextStyle(color: kSecondaryColor),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            ListView.separated(
                              physics: ClampingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: widget
                                  .item['specifications'][index]['list'].length,
                              itemBuilder: (context, idx) {
                                return InkWell(
                                  onTap: () {
                                    ListElement specItem = ListElement(
                                        uniqueId: widget.item['specifications']
                                            [index]['list'][idx]['unique_id'],
                                        price: widget.item['specifications']
                                                [index]['list'][idx]['price'] +
                                            .0);

                                    if (specification!
                                            .where((element) =>
                                                element.uniqueId ==
                                                widget.item?['specifications']
                                                    ?[index]['unique_id'])
                                            .length >
                                        0) {
                                      // debugPrint(specification!.first.toJson());
                                      // debugPrint(specItem.toJson());
                                      // debugPrint(
                                      //     "Specification list with sUnqId ${widget.item['specifications'][index]['unique_id']}  found");

                                      // Found specification with this unique_id
                                      var spec = (specification!.firstWhere(
                                          (element) =>
                                              element.uniqueId ==
                                              widget.item['specifications']
                                                  [index]['unique_id']));
                                      if (spec.list!
                                              .where((element) =>
                                                  element.uniqueId ==
                                                  specItem.uniqueId)
                                              .length >
                                          0) {
                                        // Item found in specifications
                                        setState(() {
                                          spec.list!.removeWhere((element) =>
                                              element.uniqueId ==
                                              specItem.uniqueId);
                                          selected.removeWhere((element) =>
                                              element.uniqueId ==
                                              specItem.uniqueId);
                                          if (spec.list!.length == 0) {
                                            setState(() {
                                              specification!.removeWhere(
                                                  (element) =>
                                                      element.uniqueId ==
                                                      spec.uniqueId);
                                            });
                                          }
                                        });
                                      } else {
                                        // Item not found in specifications...
                                        if (widget.item['specifications'][index]
                                                ['type'] ==
                                            2) {
                                          if (widget.item['specifications']
                                                  [index]['range'] ==
                                              0) {
                                            setState(() {
                                              spec.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          } else if (spec.list!.length <
                                              widget.item['specifications']
                                                  [index]['range']) {
                                            setState(() {
                                              spec.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          }
                                        } else {
                                          try {
                                            setState(() {
                                              selected.removeWhere((element) =>
                                                  element.uniqueId ==
                                                  spec.list![0].uniqueId);
                                              spec.list!.removeAt(0);
                                              spec.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          } catch (e) {
                                            // debugPrint(e);
                                            setState(() {
                                              spec.list!.add(specItem);
                                              selected.add(specItem);
                                            });
                                          }
                                        }
                                      }
                                    } else {
                                      // Specification with this unique_id not found adding a new one
                                      // debugPrint(
                                      //     "Specification with sUnqId ${widget.item['specifications'][index]['unique_id']} not found");
                                      setState(() {
                                        Specification spec = Specification(
                                            uniqueId:
                                                widget.item['specifications']
                                                    [index]['unique_id'],
                                            list: [specItem]);
                                        specification!.add(spec);
                                        selected.add(specItem);
                                      });
                                    }

                                    checkRequired();
                                    updatePrice();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(
                                        getProportionateScreenWidth(
                                            kDefaultPadding / 1.5)),
                                    decoration: BoxDecoration(
                                      // boxShadow: [kDefaultShadow],
                                      border: Border.all(
                                        color: selected
                                                    .where((element) =>
                                                        element.uniqueId ==
                                                        widget.item['specifications']
                                                                ?[index]['list']
                                                            [idx]['unique_id'])
                                                    .length >
                                                0
                                            ? kSecondaryColor.withValues(
                                                alpha: 0.2)
                                            : kBlackColor.withValues(
                                                alpha: 0.1),
                                      ),
                                      color: selected
                                                  .where((element) =>
                                                      element.uniqueId ==
                                                      widget.item['specifications']
                                                              ?[index]['list']
                                                          [idx]['unique_id'])
                                                  .length >
                                              0
                                          ? kSecondaryColor.withValues(
                                              alpha: 0.2)
                                          : kWhiteColor,
                                      // color: ((selected.firstWhere(
                                      //           (it) =>
                                      //               it.uniqueId ==
                                      //               widget.item['specifications']
                                      //                       [index]['list'][idx]
                                      //                   ['unique_id'],
                                      //           orElse: () => null,
                                      //         )) !=
                                      //         null)
                                      //     ? kSecondaryColor.withValues(alpha: 0.2)
                                      //     : kWhiteColor,
                                      borderRadius: BorderRadius.circular(
                                        getProportionateScreenWidth(
                                            kDefaultPadding / 4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${Service.capitalizeFirstLetters(widget.item['specifications'][index]['list'][idx]['name'])}",
                                                softWrap: true,
                                                style: TextStyle(
                                                  color: selected
                                                              .where((element) =>
                                                                  element
                                                                      .uniqueId ==
                                                                  widget.item['specifications']
                                                                              ?[
                                                                              index]
                                                                          [
                                                                          'list'][idx]
                                                                      [
                                                                      'unique_id'])
                                                              .length >
                                                          0
                                                      ? kSecondaryColor
                                                      : kBlackColor,
                                                  fontWeight: selected
                                                              .where((element) =>
                                                                  element
                                                                      .uniqueId ==
                                                                  widget.item['specifications']
                                                                              ?[
                                                                              index]
                                                                          [
                                                                          'list'][idx]
                                                                      [
                                                                      'unique_id'])
                                                              .length >
                                                          0
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.item['specifications'][index]['list'][idx]['price'].toStringAsFixed(2)}",
                                          style: TextStyle(
                                            color: selected
                                                        .where((element) =>
                                                            element.uniqueId ==
                                                            widget.item['specifications']
                                                                        ?[index]
                                                                    [
                                                                    'list'][idx]
                                                                ['unique_id'])
                                                        .length >
                                                    0
                                                ? kSecondaryColor
                                                : kBlackColor,
                                            fontWeight: selected
                                                        .where((element) =>
                                                            element.uniqueId ==
                                                            widget.item['specifications']
                                                                        ?[index]
                                                                    [
                                                                    'list'][idx]
                                                                ['unique_id'])
                                                        .length >
                                                    0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) => SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                  ),
                ),
              ),
        // widget.item['specifications'].length > 0 ? Container() : Spacer(),

        //////////price and button section////
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding),
              vertical: getProportionateScreenHeight(kDefaultPadding)),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            border: Border(top: BorderSide(color: kWhiteColor)),
            borderRadius: BorderRadius.only(
              topLeft:
                  Radius.circular(getProportionateScreenWidth(kDefaultPadding)),
              topRight:
                  Radius.circular(getProportionateScreenWidth(kDefaultPadding)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: kDefaultPadding / 2,
            children: [
              ////proce section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${Provider.of<ZLanguage>(context).price}: ",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: kBlackColor),
                  ),
                  Text(
                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${price!.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kBlackColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              ////
              ///button section///
              Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      child: Container(
                        child: Padding(
                          padding: EdgeInsets.all(
                            getProportionateScreenWidth(kDefaultPadding / 3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: kPrimaryColor,
                                size: getProportionateScreenWidth(
                                  kDefaultPadding / 1.5,
                                ),
                              ),
                              Text(
                                Provider.of<ZLanguage>(context).note,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: kPrimaryColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: kBlackColor,
                          borderRadius:
                              BorderRadius.circular(kDefaultPadding / 2),
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: kPrimaryColor,
                              title: Text(Provider.of<ZLanguage>(context).note),
                              content: TextField(
                                style: TextStyle(color: kBlackColor),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                onChanged: (val) {
                                  note = val;
                                },
                                decoration: textFieldInputDecorator.copyWith(
                                    labelText:
                                        Provider.of<ZLanguage>(context).note),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(
                                    Provider.of<ZLanguage>(context).note,
                                    style: TextStyle(
                                      color: kSecondaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    Expanded(
                      child: CustomButton(
                        title: Provider.of<ZLanguage>(context).addToCart,
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
                                if (cart != null) {
                                  if (userData != null) {
                                    if (cart!.storeId ==
                                        widget.item['store_id']) {
                                      setState(() {
                                        cart!.items!.add(item);
                                        Service.save('cart', cart);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                              "Item added to cart", false),
                                        );
                                        Navigator.of(context).pop();
                                      });
                                      // debugPrint("cart ${cart!.toJson()}");
                                    } else {
                                      _showDialog(
                                          item, destination, storeLocation);
                                    }
                                  } else {
                                    // debugPrint("User not logged in...");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        Service.showMessage(
                                            "Please login in...", true));
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(
                                          firstRoute: false,
                                        ),
                                      ),
                                    ).then((value) => getUser());
                                  }
                                } else {
                                  if (userData != null) {
                                    // debugPrint("Empty cart! Adding new item.");
                                    addToCart(item, destination, storeLocation);
                                    Navigator.of(context).pop();
                                  } else {
                                    // debugPrint("User not logged in...");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        Service.showMessage(
                                            "Please login in...", true));
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(
                                          firstRoute: false,
                                        ),
                                      ),
                                    ).then((value) => getUser());
                                  }
                                }
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        "Make sure to select required specifications!",
                                        true));
                              },
                        color: clearedRequired && price != 0
                            ? kSecondaryColor
                            : kGreyColor,
                      ),
                    ),
                    SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    Row(
                      children: [
                        InkWell(
                          child: Container(
                            child: Padding(
                              padding: EdgeInsets.all(
                                getProportionateScreenWidth(
                                    kDefaultPadding / 3),
                              ),
                              child: Icon(
                                Icons.remove,
                                color: kPrimaryColor,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color:
                                  quantity != 1 ? kSecondaryColor : kGreyColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(kDefaultPadding / 2),
                                bottomLeft:
                                    Radius.circular(kDefaultPadding / 2),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      Service.showMessage(
                                          "Minimum order quantity is 1", true));
                                },
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(
                                  kDefaultPadding / 3)),
                          child: Text(
                            quantity.toString(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        InkWell(
                          child: Container(
                            decoration: BoxDecoration(
                              color: kSecondaryColor,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(kDefaultPadding / 2),
                                bottomRight:
                                    Radius.circular(kDefaultPadding / 2),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                getProportionateScreenWidth(
                                    kDefaultPadding / 3),
                              ),
                              child: Icon(
                                Icons.add,
                                color: kPrimaryColor,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDialog(item, destination, storeLocation) {
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
}
