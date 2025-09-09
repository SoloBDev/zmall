import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/delivery/global_delivery.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  AbroadCart? cart;
  AbroadAliExpressCart? aliexpressCart;
  bool _loading = true;
  double price = 0;

  @override
  void initState() {
    super.initState();
    getCart();
  }

  void calculatePrice() {
    double tempPrice = 0;
    cart!.items!.forEach((item) {
      tempPrice += item.price!;
    });
    setState(() {
      price = tempPrice;
    });
  }

  void getCart() async {
    try {
      var data = await Service.read('abroad_cart');
      var aliCart = await Service.read('abroad_aliexpressCart');
      // debugPrint(data);
      if (data != null) {
        setState(() {
          cart = AbroadCart.fromJson(data);
        });
        // debugPrint(cart);
        calculatePrice();
      }
      // debugPrint("ALI CART>>> ${aliCart != null}");
      if (aliCart != null) {
        setState(() {
          aliexpressCart = AbroadAliExpressCart.fromJson(aliCart);
          Service.save('abroad_aliexpressCart', aliexpressCart);
        });
        // debugPrint("ALI CART>>> ${aliexpressCart!.toJson()}");
        // debugPrint(
        //     "ALI CART ITEM>>> ${aliexpressCart!.toJson()['cart']['items']}");
        // debugPrint("ALI ItemIds ${aliexpressCart!.toJson()['item_ids']}");
        // debugPrint("ALI ProductIds: ${aliexpressCart!.toJson()['product_ids']}");
      }
      // else {
      //   debugPrint("ALI CART NOT FOUND>>>");
      // }
    } catch (e) {
      // debugPrint(e);
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ModalProgressHUD(
        color: kPrimaryColor,
        progressIndicator: linearProgressIndicator,
        inAsyncCall: _loading,
        child: cart != null && cart!.items!.length > 0
            ? Column(
                children: [
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: cart!.toJson()['items'].length,
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 4),
                      ),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(
                                  kDefaultPadding / 2)),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding),
                                border: Border.all(color: kWhiteColor)),
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 2),
                              horizontal: getProportionateScreenWidth(
                                  kDefaultPadding / 2),
                            ),
                            child: Row(
                              children: [
                                ImageContainer(
                                    url: cart!.items![index].imageURL),
                                SizedBox(
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding / 4)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cart!.items![index].itemName!,
                                        style: TextStyle(
                                          fontSize: getProportionateScreenWidth(
                                              kDefaultPadding),
                                          fontWeight: FontWeight.bold,
                                          color: kBlackColor,
                                        ),
                                        softWrap: true,
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 5)),
                                      Text(
                                        "ብር ${cart!.items![index].price!.toStringAsFixed(2)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: kGreyColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 5),
                                      ),
                                      Text(cart!.items![index].noteForItem),
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
                                              color: cart!.items![index]
                                                          .quantity !=
                                                      1
                                                  ? kSecondaryColor
                                                  : kGreyColor,
                                            ),
                                            onPressed: cart!.items![index]
                                                        .quantity ==
                                                    1
                                                ? () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(Service
                                                            .showMessage1(
                                                                "Minimum order quantity is 1!",
                                                                true));
                                                  }
                                                : () {
                                                    int currQty = cart!
                                                        .items![index]
                                                        .quantity!;
                                                    double unitPrice = cart!
                                                            .items![index]
                                                            .price! /
                                                        currQty;
                                                    setState(() {
                                                      cart!.items![index]
                                                              .quantity =
                                                          currQty - 1;
                                                      cart!.items![index]
                                                              .price =
                                                          unitPrice *
                                                              (currQty - 1);
                                                      Service.save(
                                                          'abroad_cart', cart);
                                                      // Update aliexpressCart if applicable
                                                      if (aliexpressCart !=
                                                              null &&
                                                          aliexpressCart!.cart
                                                                  .storeId ==
                                                              cart!.storeId) {
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
                                                                (currQty - 1);
                                                        Service.save(
                                                            'abroad_aliexpressCart',
                                                            aliexpressCart); // Save updated aliexpressCart
                                                      }
                                                    });
                                                    // debugPrint(
                                                    //     "cart ${cart!.toJson()}");
                                                    // debugPrint(
                                                    //     "Alicart ${aliexpressCart!.toJson()}");
                                                    calculatePrice();
                                                  }),
                                        Text(
                                          "${cart!.items![index].quantity}",
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
                                              int? currQty =
                                                  cart!.items![index].quantity;
                                              double unitPrice =
                                                  cart!.items![index].price! /
                                                      currQty!;
                                              setState(() {
                                                cart!.items![index].quantity =
                                                    currQty + 1;
                                                cart!.items![index].price =
                                                    unitPrice * (currQty + 1);
                                                Service.save(
                                                    'abroad_cart', cart);
                                                // Update aliexpressCart if applicable
                                                if (aliexpressCart != null &&
                                                    aliexpressCart!
                                                            .cart.storeId ==
                                                        cart!.storeId) {
                                                  // int aliexpressIndex = aliexpressCart!.productIds!.indexOf(item.productId!);
                                                  aliexpressCart!
                                                      .cart
                                                      .items![index]
                                                      .quantity = currQty + 1;
                                                  aliexpressCart!.cart
                                                          .items![index].price =
                                                      unitPrice * (currQty + 1);
                                                  Service.save(
                                                      'abroad_aliexpressCart',
                                                      aliexpressCart); // Save updated aliexpressCart
                                                }
                                              });
                                              // debugPrint("cart ${cart!.toJson()}");
                                              // debugPrint(
                                              //     "Alicart ${aliexpressCart!.toJson()}");
                                              calculatePrice();
                                            }),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          cart!.items!.removeAt(index);
                                          Service.save('abroad_cart', cart);
                                          if (aliexpressCart != null &&
                                              aliexpressCart!.cart.storeId ==
                                                  cart!.storeId) {
                                            aliexpressCart!.cart.items!
                                                .removeAt(index);
                                            aliexpressCart!.itemIds!
                                                .removeAt(index);
                                            aliexpressCart!.productIds!
                                                .removeAt(index);
                                            Service.save(
                                                'abroad_aliexpressCart',
                                                aliexpressCart); //NEW
                                          }
                                        });
                                        // debugPrint("cart ${cart!.toJson()}");
                                        // debugPrint(
                                        //     "Alicart ${aliexpressCart!.toJson()}");
                                        calculatePrice();
                                      },
                                      child: Text(
                                        "Remove",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(color: kSecondaryColor),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
                            "Cart Total: ",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: kBlackColor),
                          ),
                          Text(
                            "ብር ${price.toStringAsFixed(2)}",
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
                    height: getProportionateScreenHeight(kDefaultPadding / 4),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding * 2),
                      vertical: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    child: CustomButton(
                      title: "Checkout",
                      press: () {
                        Navigator.pushNamed(context, GlobalDelivery.routeName);
                      },
                      color: kSecondaryColor,
                    ),
                  ),
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
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 3)),
                    Text(
                      "Empty Basket",
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
