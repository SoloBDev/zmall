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
  bool _loading = true;
  double price = 0;

  @override
  void initState() {
    // TODO: implement initState
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
      print(data);
      if (data != null) {
        setState(() {
          cart = AbroadCart.fromJson(data);
        });
        print(cart);
        calculatePrice();
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      color: kPrimaryColor,
      progressIndicator: linearProgressIndicator,
      inAsyncCall: _loading,
      child: cart != null && cart!.items!.length > 0
          ? Column(
              children: [
                SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 2)),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cart!.toJson()['items'].length,
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
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                            horizontal: getProportionateScreenWidth(
                                kDefaultPadding / 2),
                          ),
                          child: Row(
                            children: [
                              ImageContainer(url: cart!.items![index].imageURL),
                              SizedBox(
                                  width: getProportionateScreenWidth(
                                      kDefaultPadding / 4)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          .subtitle1
                                          ?.copyWith(
                                            color: kGreyColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
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
                                            color:
                                                cart!.items![index].quantity != 1
                                                    ? kSecondaryColor
                                                    : kGreyColor,
                                          ),
                                          onPressed: cart!
                                                      .items![index].quantity ==
                                                  1
                                              ? () {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                          Service.showMessage(
                                                              "Minimum order quantity is 1!",
                                                              true));
                                                }
                                              : () {
                                                  int currQty = cart!
                                                      .items![index].quantity!;
                                                  double unitPrice = cart!
                                                          .items![index]
                                                          .price! /
                                                      currQty;
                                                  setState(() {
                                                    cart!.items![index]
                                                        .quantity = currQty - 1;
                                                    cart!.items![index].price =
                                                        unitPrice *
                                                            (currQty - 1);
                                                    Service.save(
                                                        'abroad_cart', cart);
                                                  });
                                                  calculatePrice();
                                                }),
                                      Text(
                                        "${cart!.items![index].quantity}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1
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
                                              Service.save('abroad_cart', cart);
                                            });
                                            calculatePrice();
                                          }),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        cart!.items!.removeAt(index);
                                        Service.save('abroad_cart', cart);
                                      });
                                      calculatePrice();
                                    },
                                    child: Text(
                                      "Remove",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText1
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
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical:
                            getProportionateScreenHeight(kDefaultPadding / 3)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Cart Total: ",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: kBlackColor),
                        ),
                        Text(
                          "ብር ${price.toStringAsFixed(2)}",
                          style: Theme.of(context)
                              .textTheme
                              .headline6
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
                    style: Theme.of(context).textTheme.headline6,
                  )
                ],
              ),
            ),
    );
  }
}
