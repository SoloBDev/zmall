import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/item/components/photo_viewer.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';

class Body extends StatefulWidget {
  const Body({
    Key? key,
    required this.item,
    required this.location,
    required this.isOpen,
  }) : super(key: key);

  final isOpen;
  final item;
  final location;

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  var userData;
  List<int> requiredSpecs = [];
  int reqCount = 0;
  int quantity = 1;
  String note = "";
  bool clearedRequired = false;
  AbroadCart? cart;
  double? longitude, latitude;
  double? initialPrice;
  double? price;
  List<Specification> specification = [];
  List<ListElement> selected = [];

  void requiredCount() {
    if (widget.item['specifications'].length > 0) {
      for (var index = 0;
          index < widget.item['specifications'].length;
          index++) {
        if (widget.item['specifications'][index]['is_required']) {
          setState(() {
            reqCount += 1;
            requiredSpecs
                .add(widget.item['specifications'][index]['unique_id']);
          });
        }
      }
      if (reqCount == 0) {
        setState(() {
          clearedRequired = true;
        });
      }
      // debugPrint("$reqCount required specifications found");
    } else {
      setState(() {
        clearedRequired = true;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    requiredCount();
    getCart();
    // debugPrint(widget.item);
    initialPrice = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
    price = widget.item['price'] != null ? widget.item['price'] + .0 : 0;
  }

  void updatePrice() {
    double temPrice = 0;
    specification.forEach((spec) {
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
      specification.forEach((element) {
        if (requiredSpecs.contains(element.uniqueId)) {
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
    var data = await Service.read('abroad_cart');
    if (data != null) {
      setState(() {
        cart = AbroadCart.fromJson(data);
      });
    }
  }

  void addToCart(item, destination, storeLocation) {
    cart = AbroadCart(
      items: [item],
      destinationAddress: destination,
      storeId: widget.item['store_id'],
      storeLocation: storeLocation,
      isOpen: widget.isOpen,
    );

    Service.save('abroad_cart', cart!.toJson());
    ScaffoldMessenger.of(context)
        .showSnackBar(Service.showMessage("Item added to cart!", false));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              GestureDetector(
                child: CachedNetworkImage(
                  imageUrl: widget.item['image_url'].length > 0
                      ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.item['image_url'][0]}"
                      : "https://ibb.co/vkhzjd6",
                  imageBuilder: (context, imageProvider) => Container(
                    width: double.infinity,
                    height: getProportionateScreenHeight(kDefaultPadding * 16),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(
                            getProportionateScreenWidth(kDefaultPadding)),
                        bottomRight: Radius.circular(
                            getProportionateScreenWidth(kDefaultPadding)),
                      ),
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
                          fit: BoxFit.contain,
                          image: AssetImage('images/zmall.jpg'),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding),
                            vertical: getProportionateScreenWidth(
                                kDefaultPadding * 1.5)),
                        child: IconButton(
                          icon: Icon(
                            Icons.zoom_out_map,
                            color: kPrimaryColor,
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
                        ),
                      ),
                    )
                  : Container(),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 4),
              ),
              Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding),
                        vertical:
                            getProportionateScreenWidth(kDefaultPadding * 1.5)),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimaryColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: kBlackColor,
                          ),
                        ),
                      ),
                    ),
                  )),

              // SizedBox(
              //   height: getProportionateScreenHeight(kDefaultPadding / 2),
              // ),
            ],
          ),
        ),
        Container(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
              vertical: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item['name'],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: kBlackColor,
                      ),
                  textAlign: TextAlign.left,
                ),
                Text(
                  widget.item['details'].toString().replaceAll("\n", "").trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kGreyColor,
                        fontWeight: FontWeight.w400,
                      ),
                  textAlign: TextAlign.left,
                ),
                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 5),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 0.2,
          color: kGreyColor,
        ),
        SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
        widget.item['specifications'].length > 0
            ? Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.item['specifications'].length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                // mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTag(
                                    text:
                                        "${widget.item['specifications'][index]['name'].toString().toUpperCase()}",
                                    color: kBlackColor,
                                  ),
                                  widget.item['specifications'][index]
                                          ['is_required']
                                      ? Text(
                                          "Choose ${widget.item['specifications'][index]['range']}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        )
                                      : Container(),
                                ],
                              ),
                              widget.item['specifications'][index]
                                      ['is_required']
                                  ? CustomTag(
                                      text: "Required",
                                      color: kSecondaryColor,
                                    )
                                  : Container(),
                            ],
                          ),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4)),
                          ListView.separated(
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: widget
                                .item['specifications'][index]['list'].length,
                            itemBuilder: (context, idx) {
                              return GestureDetector(
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
                                    // Found specification with this unique_id
                                    var spec = (specification.firstWhere(
                                        (element) =>
                                            element.uniqueId ==
                                            widget.item['specifications'][index]
                                                ['unique_id']));
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
                                            specification.removeWhere(
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
                                        setState(() {
                                          spec.list!.add(specItem);
                                          selected.add(specItem);
                                        });
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
                                    setState(() {
                                      Specification spec = Specification(
                                          uniqueId:
                                              widget.item['specifications']
                                                  [index]['unique_id'],
                                          list: [specItem]);
                                      specification.add(spec);
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
                                    color: selected
                                                .where((element) =>
                                                    element.uniqueId ==
                                                    widget.item['specifications']
                                                            ?[index]['list']
                                                        [idx]['unique_id'])
                                                .length >
                                            0
                                        ? kSecondaryColor.withValues(alpha: 0.2)
                                        : kWhiteColor,
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
                                              "${widget.item['specifications'][index]['list'][idx]['name']}",
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "ብር ${widget.item['specifications'][index]['list'][idx]['price'].toStringAsFixed(2)}",
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
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  Center(child: Text("No Extra Specifications...")),
                ],
              ),
        widget.item['specifications'].length > 0 ? Container() : Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding)),
          decoration: BoxDecoration(
            color: kPrimaryColor,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: getProportionateScreenHeight(kDefaultPadding / 3)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "PRICE:",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: kBlackColor),
                ),
                Text(
                  "ብር ${price!.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kBlackColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kPrimaryColor,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: getProportionateScreenWidth(kDefaultPadding),
              right: getProportionateScreenWidth(kDefaultPadding),
              bottom: getProportionateScreenHeight(kDefaultPadding),
            ),
            child: Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    child: Container(
                      child: Padding(
                        padding: EdgeInsets.all(
                          getProportionateScreenWidth(kDefaultPadding / 3),
                        ),
                        child: Icon(
                          Icons.note,
                          color: kPrimaryColor,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: kSecondaryColor,
                        borderRadius: BorderRadius.circular(kDefaultPadding),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: kPrimaryColor,
                            title: Text("Note"),
                            content: TextField(
                              style: TextStyle(color: kBlackColor),
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              onChanged: (val) {
                                note = val;
                              },
                              decoration: textFieldInputDecorator.copyWith(
                                  labelText: "Note"),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text(
                                  "Add note!",
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
                      title: "Add to Cart",
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
                                long: longitude,
                                lat: latitude,
                                name: "Current Location",
                                note: "User current location",
                              );
                              if (cart != null) {
                                if (cart!.storeId == widget.item['store_id']) {
                                  setState(() {
                                    cart!.items!.add(item);
                                    Service.save('abroad_cart', cart);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      Service.showMessage(
                                          "Item added to cart", false),
                                    );
                                    Navigator.of(context).pop();
                                  });
                                } else {
                                  _showDialog(item, destination, storeLocation);
                                }
                              } else {
                                debugPrint("Empty cart! Adding new item.");
                                addToCart(item, destination, storeLocation);
                                Navigator.of(context).pop();
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
                              getProportionateScreenWidth(kDefaultPadding / 3),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: kPrimaryColor,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: quantity != 1 ? kSecondaryColor : kGreyColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(kDefaultPadding),
                              bottomLeft: Radius.circular(kDefaultPadding),
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
                              topRight: Radius.circular(kDefaultPadding),
                              bottomRight: Radius.circular(kDefaultPadding),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              getProportionateScreenWidth(kDefaultPadding / 3),
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
                    Service.remove('abroad_cart');
                    Service.remove('abroad_aliexpressCart');
                    cart = AbroadCart();
                    addToCart(item, destination, storeLocation);
                    // debugPrint(item.id);
                    // debugPrint(cart.toJson());
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
