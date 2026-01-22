import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/checkout/checkout_screen.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/report/global_report.dart';
import 'package:zmall/kifiya/components/cyber_source.dart';
import 'package:zmall/kifiya/components/dashen_master_card.dart';
import 'package:zmall/kifiya/components/kifiya_method_container.dart';
import 'package:zmall/kifiya/components/telebirr_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/order_status_row.dart';

class GlobalKifiya extends StatefulWidget {
  static String routeName = '/kifiya';

  const GlobalKifiya({
    required this.price,
    required this.orderPaymentId,
    required this.orderPaymentUniqueId,
    this.isCourier = false,
    this.vehicleId,
    this.onlyCashless = false,
  });
  final double price;
  final String orderPaymentId;
  final String orderPaymentUniqueId;
  final bool isCourier;
  final String? vehicleId;
  final bool onlyCashless;

  @override
  _GlobalKifiyaState createState() => _GlobalKifiyaState();
}

class _GlobalKifiyaState extends State<GlobalKifiya> {
  bool _loading = true;
  bool _placeOrder = false;
  bool paidBySender = true;
  AbroadCart? cart;
  AbroadAliExpressCart? aliexpressCart;
  var aliExpressAccessToken;
  List<String> itemIds = [];
  List<int> productIds = [];
  AbroadData? abroadData;
  var paymentResponse;
  var orderResponse;
  var services;
  var courierCart;
  var imagePath;
  var userData;
  int kifiyaMethod = 1;
  double topUpAmount = 0.0;
  double currentBalance = 0.0;
  String? otp;
  String? paymentGatewayId;
  String firstName = "";
  String lastName = "";
  late String uuid;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // debugPrint(widget.price);
    getUser();
    getCart();
    if (widget.onlyCashless) {
      kifiyaMethod = -1;
    }
    uuid = widget.orderPaymentUniqueId;
  }

  void getUser() async {
    var data = await Service.read('abroad_user');
    var aliAcct = await Service.read('ali_access_token');
    if (data != null) {
      abroadData = AbroadData.fromJson(data);
      try {
        var fullName = abroadData!.abroadName!.split(" ");
        if (fullName.length > 1) {
          setState(() {
            firstName = fullName.first;
            lastName = fullName.last;
            // Only assign aliExpressAccessToken if aliAcct is not null or empty
            if (aliAcct != null && aliAcct.isNotEmpty) {
              aliExpressAccessToken = aliAcct;
            } else {
              // debugPrint("aliExpress Access Token not found>>>");
            }
          });
        }
      } catch (e) {
        // debugPrint(e);
      }
    } else {
      //
    }
  }

  void getCart() async {
    // debugPrint("Fetching cart");
    var data = await Service.read('abroad_cart');
    var aliCart = await Service.read('abroad_aliexpressCart');
    if (data != null) {
      setState(() {
        cart = AbroadCart.fromJson(data);
        // Only set values from aliCart if aliCart is not null
        if (aliCart != null) {
          aliexpressCart = AbroadAliExpressCart.fromJson(aliCart);
          itemIds = aliexpressCart!.itemIds!;
          productIds = aliexpressCart!.productIds!;
        }
        // debugPrint("ALI CART>>> ${aliexpressCart!.toJson()}");
        _getPaymentGateway();
      });
      await useBorsa();
    }
    setState(() {
      _loading = false;
    });
  }

  void _getPaymentGateway() async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    await getPaymentGateway();
    if (paymentResponse != null && paymentResponse['success']) {
      for (var i = 0; i < paymentResponse['payment_gateway'].length; i++) {
        // debugPrint(paymentResponse['payment_gateway'][i]['name']);
        // debugPrint("\t${paymentResponse['payment_gateway'][i]['description']}");
      }
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      // debugPrint("Payment response error");
      await Future.delayed(Duration(seconds: 2));
      // debugPrint("Payment Gateway : Server token error...");
    }
  }

  void _createAliexpressOrder() async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await createAliexpressOrder();
    if (data != null &&
        data['success'] &&
        data['data']['error_response'] == null &&
        data['data']['aliexpress_ds_order_create_response']['result']['is_success']) {
      List<dynamic>? orderIds =
          data['data']['aliexpress_ds_order_create_response']['result']['order_list']['number'];
      _createOrder(orderIds: orderIds);
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      Service.showMessage(
        context: context,
        title: "Faild to create the order! please try again.",
        error: true,
      );
    }
  }

  void _createOrder({List<dynamic>? orderIds}) async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await createOrder(orderIds: orderIds);
    if (data != null && data['success']) {
      // debugPrint("Order created successfully");
      Service.showMessage(
        context: context,
        title: "Order successfully created",
        error: true,
      );
      await Service.remove('abroad_cart');
      await Service.remove('abroad_aliexpressCart');
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return GlobalReport(
              price: widget.price,
              orderPaymentUniqueId: widget.orderPaymentUniqueId,
            );
          },
        ),
      );
    } else {
      // debugPrint("\t\t- Create Order Response");
      // debugPrint(data);
      Service.showMessage(
        context: context,
        title: "${errorCodes['${data['error_code']}']}!",
        error: true,
      );
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
    }
  }

  void _payOrderPayment({otp, paymentId = ""}) async {
    var pId = "";
    if (otp.toString().isNotEmpty) {
      pId = paymentId;
    } else {
      if (!widget.isCourier) {
        pId = "0";
      }
    }

    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await payOrderPayment(otp, paymentGatewayId);
    if (data != null && data['success']) {
      // debugPrint("Order payment successfull! Creating order");
      // widget.isCourier ? _createCourierOrder() : _createOrder();
      // _createOrder();//this was before aliexpress
      aliexpressCart != null && aliexpressCart!.cart.storeId == cart!.storeId
          ? _createAliexpressOrder()
          : _createOrder();
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      Service.showMessage(
        context: context,
        title: "${errorCodes['${data['error_code']}']}!",
        error: true,
      );
      await Future.delayed(Duration(seconds: 1));
      // debugPrint("Pay Order Payment : Server token error....");
      // if (data['error_code'] == 999) {
      //   await Service.saveBool('logged', false);
      //   await Service.remove('user');
      //   Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      // }
    }
  }

  void _boaVerify() async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await boaVerify();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      Service.showMessage(
        context: context,
        title: "Payment verification successful!",
        error: false,
        duration: 2,
      );
      // _payOrderPayment();
      // _createOrder(); //this was before aliexpress
      aliexpressCart != null && aliexpressCart!.cart.storeId == cart!.storeId
          ? _createAliexpressOrder()
          : _createOrder();
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
        if (widget.onlyCashless) {
          kifiyaMethod = -1;
        } else {
          kifiyaMethod = 1;
        }
      });
      await useBorsa();
      Service.showMessage(
        context: context,
        title: "${data['error']}! Please complete your payment!",
        error: true,
      );
      await Future.delayed(Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payments", style: TextStyle(color: kBlackColor)),
        elevation: 1.0,
      ),
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: _loading,
          progressIndicator: LinearLoadingIndicator(),
          color: kPrimaryColor,
          child: paymentResponse != null
              ? SingleChildScrollView(
                  padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrderStatusRow(
                          title: "Order Price",
                          value:
                              "${widget.price} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                          icon: HeroiconsOutline
                              .banknotes, // Replace with appropriate icon if needed
                        ),
                        SizedBox(
                          height: getProportionateScreenHeight(kDefaultPadding),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(color: kWhiteColor),
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding),
                            ),
                            // boxShadow: [boxShadow],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                            vertical: getProportionateScreenHeight(
                              kDefaultPadding / 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment Information",
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(
                                      color: kBlackColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 2,
                                ),
                              ),
                              DetailsRow(
                                title: "Name",
                                subtitle:
                                    abroadData != null &&
                                        abroadData!.abroadName!.isNotEmpty
                                    ? abroadData!.abroadName!
                                    : "N/A",
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 3,
                                ),
                              ),
                              DetailsRow(
                                title: "Phone",
                                subtitle:
                                    abroadData != null &&
                                        abroadData!.abroadPhone!.isNotEmpty
                                    ? abroadData!.abroadPhone!
                                    : "N/A",
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 3,
                                ),
                              ),
                              DetailsRow(
                                title: "Email",
                                subtitle:
                                    abroadData != null &&
                                        abroadData!.abroadEmail!.isNotEmpty
                                    ? abroadData!.abroadEmail!
                                    : "N/A",
                              ),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 3,
                                ),
                              ),
                              //                                 TextButton(
                              // //                          style: ButtonStyle(
                              // //                            backgroundColor:
                              // //                                MaterialStateProperty.all(kSecondaryColor),
                              // //                          ),
                              //                                   onPressed: () {
                              //                                     showModalBottomSheet<void>(
                              //                                       isScrollControlled: true,
                              //                                       context: context,
                              //                                       shape: RoundedRectangleBorder(
                              //                                         borderRadius: BorderRadius.only(
                              //                                             topLeft: Radius.circular(30.0),
                              //                                             topRight: Radius.circular(30.0)),
                              //                                       ),
                              //                                       builder: (BuildContext context) {
                              //                                         return Padding(
                              //                                           padding:
                              //                                               MediaQuery.of(context).viewInsets,
                              //                                           child: Container(
                              //                                             padding: EdgeInsets.all(
                              //                                                 getProportionateScreenHeight(
                              //                                                     kDefaultPadding)),
                              //                                             child: Wrap(
                              //                                               children: <Widget>[
                              //                                                 Text(
                              //                                                   "Sender Information",
                              //                                                   style: Theme.of(context)
                              //                                                       .textTheme
                              //                                                       .headline5
                              //                                                       .copyWith(
                              //                                                         fontWeight:
                              //                                                             FontWeight.bold,
                              //                                                       ),
                              //                                                 ),
                              //                                                 Container(
                              //                                                   height:
                              //                                                       getProportionateScreenHeight(
                              //                                                           kDefaultPadding),
                              //                                                 ),
                              //                                                 TextField(
                              //                                                   style: TextStyle(
                              //                                                       color: kBlackColor),
                              //                                                   keyboardType:
                              //                                                       TextInputType.text,
                              //                                                   onChanged: (val) {
                              //                                                     senderName = val;
                              //                                                   },
                              //                                                   decoration: textFieldInputDecorator
                              //                                                       .copyWith(
                              //                                                           labelText: senderName !=
                              //                                                                       null &&
                              //                                                                   senderName
                              //                                                                       .isNotEmpty
                              //                                                               ? senderName
                              //                                                               : "Sender Name"),
                              //                                                 ),
                              //                                                 Container(
                              //                                                   height:
                              //                                                       getProportionateScreenHeight(
                              //                                                           kDefaultPadding / 2),
                              //                                                 ),
                              //                                                 CustomButton(
                              //                                                   title: "Submit",
                              //                                                   color: kSecondaryColor,
                              //                                                   press: () async {
                              //                                                     if (senderName != null &&
                              //                                                         senderName.isNotEmpty &&
                              //                                                         senderPhone != null &&
                              //                                                         senderPhone
                              //                                                             .isNotEmpty) {
                              //                                                       setState(() {
                              //                                                         abroadData.abroadName =
                              //                                                             senderName;
                              //                                                       });
                              //                                                       // debugPrint(abroadData.toJson());
                              //                                                       Service.save(
                              //                                                           "abroad_user",
                              //                                                           abroadData.toJson());
                              //                                                       Navigator.of(context)
                              //                                                           .pop();
                              //                                                     }
                              //                                                   },
                              //                                                 ),
                              //                                               ],
                              //                                             ),
                              //                                           ),
                              //                                         );
                              //                                       },
                              //                                     );
                              //                                   },
                              //                                   child: Text(
                              //                                     receiverName.isNotEmpty &&
                              //                                             receiverPhone.isNotEmpty
                              //                                         ? "Change Details"
                              //                                         : "Add Details",
                              //                                     style: TextStyle(
                              //                                       color: kBlackColor,
                              //                                       decoration: TextDecoration.underline,
                              //                                       fontSize: getProportionateScreenWidth(
                              //                                           kDefaultPadding * .8),
                              //                                       fontWeight: FontWeight.w700,
                              //                                     ),
                              //                                   ),
                              //                                 ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: getProportionateScreenHeight(kDefaultPadding),
                        ),
                        Text(
                          "Payment Information",
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                color: kBlackColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(
                          height: getProportionateScreenHeight(
                            kDefaultPadding / 2,
                          ),
                        ),
                        widget.onlyCashless
                            ? Text(
                                "Store only allows digital payments.",
                                style: Theme.of(context).textTheme.titleMedium,
                              )
                            : Container(),
                        widget.onlyCashless
                            ? SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 2,
                                ),
                              )
                            : Container(),
                        Container(
                          child: ListView.separated(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            // gridDelegate:
                            //     SliverGridDelegateWithFixedCrossAxisCount(
                            //   crossAxisCount: 3,
                            //   crossAxisSpacing:
                            //       getProportionateScreenWidth(kDefaultPadding),
                            // ),
                            separatorBuilder: (context, index) {
                              return Container(height: 4);
                            },
                            itemCount:
                                paymentResponse['payment_gateway'].length,
                            itemBuilder: (BuildContext ctx, index) {
                              if (paymentResponse['payment_gateway'][index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  'boa') {
                                // debugPrint(paymentResponse['payment_gateway'][index]['name']);
                                return KifiyaMethodContainer(
                                  selected: kifiyaMethod == index + 4,
                                  title:
                                      paymentResponse['payment_gateway'][index]['description']
                                          .toString()
                                          .toUpperCase(),
                                  kifiyaMethod: kifiyaMethod,
                                  imagePath: "images/payment/boa.png",
                                  press: () async {
                                    setState(() {
                                      kifiyaMethod = index + 4;
                                      paymentGatewayId =
                                          paymentResponse['payment_gateway'][index]['_id'];
                                    });
                                    // var cartId =  await Service.read("cart_id");
                                    // debugPrint(
                                    //     "Order payment unique ID : ${widget.orderPaymentUniqueId}");
                                    // debugPrint(
                                    //     "Order payment ID : ${widget.orderPaymentId}");
                                    // debugPrint(
                                    //     "Payment Gateway ID : $paymentGatewayId");
                                    // debugPrint("User ID : ${cart!.userId}");
                                    // debugPrint(
                                    //     "Server Token : ${cart!.serverToken}");
                                    // debugPrint("Cart ID : $cartId");
                                    var data = await useBorsa();
                                    if (data['success']) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using International Card",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            content: Wrap(
                                              children: [
                                                Text(
                                                  "Proceed to pay ብር ${widget.price.toStringAsFixed(2)} using International Card?",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                        color: kBlackColor,
                                                      ),
                                                ),
                                                Container(
                                                  height:
                                                      getProportionateScreenHeight(
                                                        kDefaultPadding / 2,
                                                      ),
                                                ),
                                                CustomTextField(
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                  ),
                                                  keyboardType:
                                                      TextInputType.text,
                                                  onChanged: (val) {
                                                    firstName = val;
                                                  },
                                                  hintText: firstName.isNotEmpty
                                                      ? firstName
                                                      : "First Name",
                                                ),
                                                Container(
                                                  height:
                                                      getProportionateScreenHeight(
                                                        kDefaultPadding / 2,
                                                      ),
                                                ),
                                                CustomTextField(
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                  ),
                                                  keyboardType:
                                                      TextInputType.text,
                                                  onChanged: (val) {
                                                    lastName = val;
                                                  },
                                                  hintText: lastName.isNotEmpty
                                                      ? lastName
                                                      : "Last Name",
                                                ),
                                                Container(
                                                  height:
                                                      getProportionateScreenHeight(
                                                        kDefaultPadding / 2,
                                                      ),
                                                ),
                                                CustomTextField(
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                  ),
                                                  enabled: true,
                                                  keyboardType:
                                                      TextInputType.text,
                                                  onChanged: (val) {},
                                                  hintText:
                                                      abroadData!
                                                          .abroadEmail!
                                                          .isNotEmpty
                                                      ? abroadData!.abroadEmail
                                                      : "Email",
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  "Continue",
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    uuid = (int.parse(uuid) + 1)
                                                        .toString();
                                                  });

                                                  if (abroadData != null &&
                                                      abroadData!
                                                          .abroadEmail!
                                                          .isNotEmpty &&
                                                      abroadData!
                                                          .abroadName!
                                                          .isNotEmpty &&
                                                      abroadData!
                                                          .abroadPhone!
                                                          .isNotEmpty) {
                                                    Navigator.of(context).pop();
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            CyberSource(
                                                              url:
                                                                  "https://pgw.shekla.app/cards/process?total=${widget.price}&stotal=${widget.price}&tax=0&shiping=0&order_id=${uuid}_${widget.orderPaymentUniqueId}&first=$firstName&last=$lastName&phone=${abroadData!.abroadPhone}&email=${abroadData!.abroadEmail}&appId=1234",
                                                            ),
                                                      ),
                                                    ).then((value) {
                                                      _boaVerify();
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Something went wrong! Please try again!",
                                        error: true,
                                      );
                                    }
                                  },
                                );
                              } else if (paymentResponse['payment_gateway'][index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "zemen") {
                                return KifiyaMethodContainer(
                                  selected: kifiyaMethod == index + 4,
                                  title:
                                      paymentResponse['payment_gateway'][index]['description']
                                          .toString()
                                          .toUpperCase(),
                                  kifiyaMethod: kifiyaMethod,
                                  imagePath: "images/payment/zemen.png",
                                  press: () async {
                                    setState(() {
                                      kifiyaMethod = index + 4;
                                      paymentGatewayId =
                                          paymentResponse['payment_gateway'][index]['_id'];
                                    });
                                    // var cartId =  await Service.read("cart_id");
                                    // debugPrint(
                                    //     "Order payment unique ID : ${widget.orderPaymentUniqueId}");
                                    // debugPrint(
                                    //     "Order payment ID : ${widget.orderPaymentId}");
                                    // debugPrint(
                                    //     "Payment Gateway ID : $paymentGatewayId");
                                    // debugPrint("User ID : ${cart!.userId}");
                                    // debugPrint(
                                    //     "Server Token : ${cart!.serverToken}");
                                    // debugPrint("Cart ID : $cartId");
                                    var data = await useBorsa();
                                    if (data['success']) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using International Card",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            content: Text(
                                              "Proceed to pay ብር ${widget.price.toStringAsFixed(2)} using International Card?",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(color: kBlackColor),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  "Continue",
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  setState(() {
                                                    uuid = (int.parse(uuid) + 1)
                                                        .toString();
                                                  });
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return Telebirr(
                                                          isAbroad: true,
                                                          url:
                                                              "https://pgw.shekla.app/zemen/post_bill",
                                                          hisab: widget.price,
                                                          traceNo:
                                                              uuid +
                                                              "_" +
                                                              widget
                                                                  .orderPaymentUniqueId,
                                                          phone: cart!
                                                              .abroadData!
                                                              .abroadPhone!,
                                                          orderPaymentId: widget
                                                              .orderPaymentId,
                                                          title:
                                                              "Master Card Payment Gateway",
                                                        );
                                                      },
                                                    ),
                                                  ).then((value) {
                                                    _boaVerify();
                                                  });
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Something went wrong! Please try again!",
                                        error: true,
                                      );
                                    }
                                  },
                                );
                              }
                              ///**************************Dashen mastercard***************************************
                              else if (paymentResponse['payment_gateway'][index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "dashen mastercard") {
                                return KifiyaMethodContainer(
                                  selected: kifiyaMethod == index + 4,
                                  title:
                                      paymentResponse['payment_gateway'][index]['description']
                                          .toString()
                                          .toUpperCase(),
                                  kifiyaMethod: kifiyaMethod,
                                  imagePath: "images/payment/dashenmpgs.png",
                                  press: () async {
                                    setState(() {
                                      kifiyaMethod = index + 4;
                                      paymentGatewayId =
                                          paymentResponse['payment_gateway'][index]['_id'];
                                    });
                                    // var cartId = await Service.read("cart_id");
                                    // debugPrint(
                                    //     "Order payment unique ID : ${widget.orderPaymentUniqueId}");
                                    // debugPrint(
                                    //     "Order payment ID : ${widget.orderPaymentId}");
                                    // debugPrint(
                                    //     "Payment Gateway ID : $paymentGatewayId");
                                    // debugPrint("User ID : ${cart!.userId}");
                                    // debugPrint(
                                    //     "Server Token : ${cart!.serverToken}");
                                    // debugPrint("Cart ID : $cartId");

                                    var data = await useBorsa();
                                    if (data['success']) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using Mastercard",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price.toStringAsFixed(2)} using Dashen Mastercard?",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(color: kBlackColor),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  "Continue",
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return DashenMasterCard(
                                                          url:
                                                              "https://pgw.shekla.app/dashenMpgs/mastercard/api/checkout",
                                                          amount: widget.price,
                                                          phone: abroadData!
                                                              .abroadPhone!,
                                                          traceNo: widget
                                                              .orderPaymentUniqueId,
                                                          orderPaymentId: widget
                                                              .orderPaymentId,
                                                          currency:
                                                              Provider.of<
                                                                    ZMetaData
                                                                  >(
                                                                    context,
                                                                    listen:
                                                                        false,
                                                                  )
                                                                  .currency,
                                                        );
                                                      },
                                                    ),
                                                  ).then((value) {
                                                    _boaVerify();
                                                  });
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Something went wrong! Please try again!",
                                        error: true,
                                      );
                                    }
                                  },
                                );
                              }
                              ///*******************************Dashen mastercard*******************************
                              else {
                                return SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          height: getProportionateScreenHeight(kDefaultPadding),
                        ),
                        _placeOrder
                            ? SpinKitWave(
                                color: kSecondaryColor,
                                size: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              )
                            : CustomButton(
                                title: "Place Order",
                                press: () async {
                                  // var data = await Service.read("cart_id");
                                  // debugPrint(data);
                                  if (paymentGatewayId != null) {
                                    _payOrderPayment(
                                      otp: "",
                                      paymentId: widget.orderPaymentId,
                                    );
                                  } else {}
                                },
                                color: paymentGatewayId != null
                                    ? kSecondaryColor
                                    : kGreyColor,
                              ),
                      ],
                    ),
                  ),
                )
              : Container(),
        ),
      ),
    );
  }

  Future<dynamic> getPaymentGateway() async {
    // debugPrint("- Fetching payment gatway");
    // debugPrint("\t-> server_token ${cart!.serverToken}");
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_payment_gateway";
    Map data = {
      "user_id": cart!.userId,
      "city_id": "5b406b46d2ddf8062d11b788",
      "server_token": cart!.serverToken,
    };
    var body = json.encode(data);
    // debugPrint(body);
    // debugPrint("Fetching payment gateway...");
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );

      setState(() {
        this.paymentResponse = json.decode(response.body);
        this._loading = false;
      });
      // debugPrint(paymentResponse);
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong. Please check your internet connection!",
          ),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> payOrderPayment(otp, paymentId) async {
    // debugPrint(cart!.userId);
    // debugPrint(cart!.serverToken);
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/pay_order_payment";
    Map data = {
      "user_id": cart!.userId,
      "otp": otp,
      "order_payment_id": widget.orderPaymentId,
      "payment_id": paymentId,
      "is_payment_mode_cash": false,
      "server_token": cart!.serverToken,
    };

    var body = json.encode(data);
    // debugPrint(body);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );
      // debugPrint("=========Pay Order Payment Done=========");
      // debugPrint(json.decode(response.body));
      setState(() {
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
          content: Text(
            "Something went wrong. Please check your internet connection!",
          ),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> useBorsa() async {
    // debugPrint("Changing wallet status");
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/change_user_wallet_status";
    Map data = {
      "user_id": cart!.userId,
      "is_use_wallet": false,
      "server_token": cart!.serverToken,
    };

    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );

      setState(() {
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
          content: Text(
            "Something went wrong. Please check your internet connection!",
          ),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> createOrder({List<dynamic>? orderIds}) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/create_order";
    // debugPrint("Getting ready to create order");
    var cart_id = await Service.read('cart_id');
    // debugPrint("\t Cart Id : ");
    // debugPrint("\t\t$cart_id");
    try {
      List<dynamic>? filteredOrderIds;
      if (aliexpressCart != null &&
          aliexpressCart!.cart.storeId == cart!.storeId) {
        filteredOrderIds = orderIds; // Pass the orderIds
      }
      Map data = {
        "user_id": cart!.userId,
        "cart_id": cart_id,
        "is_schedule_order": cart!.isSchedule != null
            ? cart!.isSchedule
            : false,
        "schedule_order_start_at":
            cart!.scheduleStart != null &&
                cart!.isSchedule != null &&
                cart!.isSchedule
            ? cart!.scheduleStart!.toUtc().toString()
            : "",
        "server_token": cart!.serverToken,
        if (filteredOrderIds != null) "aliexpress_order_ids": filteredOrderIds,
      };
      // debugPrint(data);
      var body = json.encode(data);
      http.Response response;
      response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );
      // debugPrint("==========Create Order Done==========");
      // debugPrint(json.decode(response.body));
      setState(() {
        orderResponse = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // debugPrint("\t- $e");
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong. Please check your internet connection!",
          ),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> createAliexpressOrder() async {
    // debugPrint("in createAliexpressOrder>>>");
    var aliOrderResponse;
    var mobile_no = cart!.phone.isNotEmpty
        ? cart!.phone
        : "${userData['user']['phone']}";
    var full_name = cart!.userName.isNotEmpty
        ? cart!.userName
        : "${userData['user']['first_name']} ${userData['user']['last_name']}";
    // Extract cart and product details from AliExpressCart
    AbroadCart alicart = aliexpressCart!.cart;
    List<String>? itemIds = aliexpressCart!.itemIds;
    List<int>? productIds = aliexpressCart!.productIds;
    // debugPrint("alicart.items: ${alicart.items!.map((item) => item.toJson()).toList()}");
    // debugPrint("alicart.items length: ${alicart.items!.length}");
    // debugPrint("productIds:${productIds!} length: ${productIds.length}");
    // debugPrint("itemIds: ${itemIds} length: ${itemIds!.length}");

    List<Map<String, dynamic>> productItems = [];
    alicart.items!.asMap().forEach((index, item) {
      if (index < productIds!.length && index < itemIds!.length) {
        productItems.add({
          "product_count": item.quantity,
          "product_id": productIds[index],
          "sku_attr": itemIds[index],
          "product_price": {
            // "currency_code": "ETB",
            "price": item.price,
          },
        });
      }
      // else {debugPrint("Index $index out of range for productIds or itemIds");}
    });
    // debugPrint("productItems>>> $productItems");
    // debugPrint('Cart items: ${aliexpressCart!.cart.items}');
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/aliexpress_creat_order";
    if (productItems.isNotEmpty) {
      try {
        Map data = {
          "access_token": aliExpressAccessToken,
          "full_name": full_name,
          "mobile_no": mobile_no,
          "product_items": productItems,
        };
        var body = json.encode(data);
        // debugPrint("body $body");
        http.Response response = await http
            .post(
              Uri.parse(url),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Accept": "application/json",
              },
              body: body,
            )
            .timeout(
              Duration(seconds: 50),
              onTimeout: () {
                setState(() {
                  this._loading = false;
                });
                throw TimeoutException("The connection has timed out!");
              },
            );
        setState(() {
          aliOrderResponse = json.decode(response.body);
        });
        // debugPrint("ALi orderResponse $aliOrderResponse");
        return aliOrderResponse;
      } catch (e) {
        // debugPrint("ALi orderResponse error $e");
        setState(() {
          this._loading = false;
        });
        Service.showMessage(
          context: context,
          title:
              "Failed to create aliexpress order, please check your internet and try again",
          error: true,
        );
        return null;
      }
    }
  }

  Future<dynamic> boaVerify() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";
    Map data = {
      "user_id": cart!.userId,
      "server_token": cart!.serverToken,
      "order_payment_id": widget.orderPaymentId,
    };
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              setState(() {
                this._loading = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );

      setState(() {
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
          content: Text(
            "Something went wrong. Please check your internet connection!",
          ),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}
