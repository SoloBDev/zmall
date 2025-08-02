import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/checkout/checkout_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/kifiya/global_kifiya.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';

class GlobalCheckout extends StatefulWidget {
  static String routeName = "checkout";

  GlobalCheckout(
      {this.isForOthers = false,
      this.receiverName = "",
      this.receiverPhone = ""});

  final bool isForOthers;
  final String receiverPhone;
  final String receiverName;

  @override
  _GlobalCheckoutState createState() => _GlobalCheckoutState();
}

class _GlobalCheckoutState extends State<GlobalCheckout> {
  AbroadCart? cart;
  bool _loading = true;
  bool _placeOrder = false;
  bool orderAsap = true;
  bool scheduledOrder = false;
  bool selfPickup = false;
  bool promoCodeApplied = false;
  bool onlySelfPickup = false;
  bool? onlyScheduledOrder;
  bool? onlyCashless;
  double? distance, time, tip = 0, tipTemp = 0;
  var cartId;
  var responseData;
  var paymentResponse;
  var promoCodeData;
  var storeDetail;
  static final String androidKey = 'AIzaSyBzMHLnXLbtLMi9rVFOR0eo5pbouBtxyjg';
  static final String iosKey = 'AIzaSyDAgZScAJfUHxahi_n4OpuI8HrTHVlirJk';
  final apiKey = Platform.isAndroid ? androidKey : iosKey;
  DateTime? _scheduledDate;
  String promoCode = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint("Checkout init....");
    getCartId();
  }

  void getCartId() async {
    var data = await Service.read('cart_id');
    if (data != null) {
      setState(() {
        cartId = data;
      });
      getCart();
    }
  }

  void getCart() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('abroad_cart');
    if (data != null) {
      setState(() {
        cart = AbroadCart.fromJson(data);
      });
      _getStoreDetail();
      _getTotalDistance(cart!);
    }
  }

  void _getStoreDetail() async {
    setState(() {
      _loading = true;
    });
    var data = await getStoreDetail();
    if (data != null && data['success']) {
      setState(() {
        storeDetail = data;
        onlyCashless = storeDetail['store']['accept_only_cashless_payment'];
        onlySelfPickup =
            storeDetail['store']['accept_user_pickup_delivery_only'];
        onlyScheduledOrder =
            storeDetail['store']['accept_scheduled_order_only'];
      });
      if (onlyScheduledOrder! || !cart!.isOpen) {
        DateTime dateTime = DateTime.now();
        setState(() {
          orderAsap = false;
          scheduledOrder = true;
          _scheduledDate =
              DateTime(dateTime.year, dateTime.month, dateTime.day, 9, 0, 0)
                  .add(Duration(days: 1));
          onlyScheduledOrder = true;
        });
      } else {
        _scheduledDate = DateTime.now();
      }
      // if (onlySelfPickup) {
      //   setState(() {
      //     selfPickup = onlySelfPickup;
      //   });
      // }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${errorCodes['${promoCodeData['error_code']}']}!", true));
    }
  }

  void _getTotalDistance(AbroadCart cart) async {
    var data = await getTotalDistance(cart);
    if (data != null && data['rows'][0]['elements'][0]['status'] == 'OK') {
      setState(() {
        distance =
            data['rows'][0]['elements'][0]['distance']['value'].toDouble();
        time = data['rows'][0]['elements'][0]['duration']['value'].toDouble();
      });
      _getCartInvoice();
    }
    // if (!cart.isOpen) {
    //   setState(() {
    //     scheduledOrder = true;
    //     _scheduledDate = DateTime.now();
    //     onlyScheduledOrder = true;
    //   });
    // }
  }

  void _applyPromoCode() async {
    setState(() {
      _loading = true;
    });
    var data = await applyPromoCode();
    if (data != null && data['success']) {
      setState(() {
        promoCodeApplied = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${errorCodes['${promoCodeData['error_code']}']}!", true));
    }
  }

  void _getCartInvoice() async {
    setState(() {
      _loading = true;
    });
    await getCartInvoice();
    if (responseData != null && responseData['success']) {
      debugPrint("Cart invoice generated");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${errorCodes['${responseData['error_code']}']}!", true));
      await Future.delayed(Duration(seconds: 2));
      // if (responseData['error_code'] == 999) {
      //   await Service.saveBool('logged', false);
      //   await Service.remove('user');
      //   Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        color: kPrimaryColor,
        progressIndicator: linearProgressIndicator,
        child: SingleChildScrollView(
          child: Padding(
            padding:
                EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
            child: Column(
              children: [
                CustomTag(color: kSecondaryColor, text: "Delivery Options"),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding)),
                    // boxShadow: [boxShadow],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                        getProportionateScreenWidth(kDefaultPadding / 2)),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          secondary: Icon(
                            Icons.timelapse,
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          ),
                          title: const Text('As Soon as Possible'),
                          subtitle: Text('Express Order'),
                          value: this.orderAsap,
                          onChanged: (bool? value) {
                            if (cart!.isOpen) {
                              if (!onlyScheduledOrder!) {
                                if (value!) {
                                  setState(() {
                                    this.orderAsap = value;
                                    this.scheduledOrder = false;
                                  });
                                }
                                getCart();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                    "Store only accepts scheduled orders. Please schedule your order!",
                                    false,
                                    duration: 5,
                                  ),
                                );
                                setState(() {
                                  this.orderAsap = false;
                                  this.scheduledOrder = true;
                                });
                              }
                            }
                          },
                        ),
                        CheckboxListTile(
                          secondary: Icon(
                            Icons.calendar_today,
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          ),
                          title: const Text('Schedule an Order'),
                          subtitle: Text('Pre-order'),
                          value: this.scheduledOrder,
                          onChanged: (bool? value) {
                            if (!onlyScheduledOrder!) {
                              if (value!) {
                                setState(() {
                                  this.scheduledOrder = value;
                                  this.orderAsap = false;
                                });
                              } else {
                                setState(() {
                                  this.scheduledOrder = false;
                                  this.orderAsap = true;
                                });
                              }
                            } else {
                              setState(() {
                                this.scheduledOrder = onlyScheduledOrder!;
                                this.orderAsap = false;
                              });
                            }
                          },
                        ),
                        scheduledOrder
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    child: Text(
                                      cart!.scheduleStart != null
                                          ? cart!.scheduleStart
                                              .toString()
                                              .split('.')[0]
                                          : " Add Date & Time ",
                                      style: TextStyle(
                                        color: kSecondaryColor,
                                      ),
                                    ),
                                    style: ButtonStyle(
                                      elevation: WidgetStateProperty.all(1.0),
                                      backgroundColor: WidgetStateProperty.all(
                                          kPrimaryColor),
                                    ),
                                    onPressed: () async {
                                      if (!cart!.isOpen) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                            "As the store is closed it only allows next day booking",
                                            false,
                                            duration: 5,
                                          ),
                                        );
                                        await Future.delayed(
                                            Duration(seconds: 3));
                                      }

                                      DateTime _now = DateTime.now();
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: !cart!.isOpen
                                            ? _now.add(Duration(days: 1))
                                            : _now,
                                        lastDate: _now.add(
                                          Duration(days: 7),
                                        ),
                                      );
                                      TimeOfDay? time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(
                                              DateTime.now()));

                                      setState(() {
                                        _scheduledDate = pickedDate!.add(
                                            Duration(
                                                hours: time!.hour,
                                                minutes: time!.minute));
                                        cart!.scheduleStart = _scheduledDate;
                                        cart!.isSchedule = true;
                                      });
                                      await Service.save(
                                          'abroad_cart', cart!.toJson());
                                      getCart();
                                    },
                                  ),
                                ],
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
                CustomTag(color: kSecondaryColor, text: "Delivery Details"),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding),
                    ),
                    // boxShadow: [boxShadow],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                        getProportionateScreenHeight(kDefaultPadding)),
                    child: Column(
                      children: [
                        DetailsRow(
                            title: "Name", subtitle: widget.receiverName),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 3)),
                        DetailsRow(
                            title: "Phone",
                            subtitle: "+251${widget.receiverPhone}"),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 3)),
                        DetailsRow(
                          title: "Delivery Address",
                          subtitle: cart != null
                              ? "${cart!.destinationAddress!.name!.split(',')[0]}"
                              : "",
                        ),
                        SizedBox(
                            height:
                                getProportionateScreenHeight(kDefaultPadding)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
                CustomTag(color: kSecondaryColor, text: "Order Details"),
                responseData != null
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                              getProportionateScreenHeight(kDefaultPadding)),
                          child: Column(
                            children: [
                              DetailsRow(
                                title: "Service Price",
                                subtitle: promoCodeApplied
                                    ? "ብር ${promoCodeData['order_payment']['total_delivery_price'].toStringAsFixed(2)}"
                                    : "ብር ${responseData['order_payment']['total_delivery_price'].toStringAsFixed(2)}",
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 3)),
                              DetailsRow(
                                title: "Total Order Price",
                                subtitle: promoCodeApplied
                                    ? "ብር ${promoCodeData['order_payment']['total_order_price'].toStringAsFixed(2)}"
                                    : "ብር ${responseData['order_payment']['total_order_price'].toStringAsFixed(2)}",
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 3)),
                              DetailsRow(
                                title: "Promo Payment",
                                subtitle: promoCodeApplied
                                    ? "ብር -${promoCodeData['order_payment']['promo_payment'].toStringAsFixed(2)}"
                                    : "ብር ${responseData['order_payment']['promo_payment'].toStringAsFixed(2)}",
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 3)),
                              DetailsRow(
                                title: Provider.of<ZLanguage>(context).tip,
                                subtitle:
                                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${tip!.toStringAsFixed(2)}",
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      "Total",
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(
                                            kDefaultPadding * .7),
                                      ),
                                    ),
                                    SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 3)),
                                    Text(
                                      promoCodeApplied
                                          ? "ብር ${promoCodeData['order_payment']['user_pay_payment'].toStringAsFixed(2)}"
                                          : "ብር ${responseData['order_payment']['user_pay_payment'].toStringAsFixed(2)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      if (promoCodeApplied) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                              "Promo Code already applied!",
                                              true),
                                        );
                                        setState(() {});
                                      } else {
                                        showModalBottomSheet<void>(
                                          isScrollControlled: true,
                                          context: context,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(30.0),
                                                topRight:
                                                    Radius.circular(30.0)),
                                          ),
                                          builder: (BuildContext context) {
                                            return Padding(
                                              padding: MediaQuery.of(context)
                                                  .viewInsets,
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding)),
                                                child: Wrap(
                                                  children: <Widget>[
                                                    Text(
                                                      "Apply Promo Code",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineSmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    Container(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding),
                                                    ),

                                                    TextField(
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                      keyboardType:
                                                          TextInputType.text,
                                                      onChanged: (val) {
                                                        promoCode = val;
                                                      },
                                                      decoration:
                                                          textFieldInputDecorator
                                                              .copyWith(
                                                                  labelText:
                                                                      "Promo Code"),
                                                    ),

                                                    Container(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding /
                                                                  2),
                                                    ),
//                                          transferError
//                                              ? Text(
//                                            "Invalid! Please make sure all fields are filled.",
//                                            style: TextStyle(
//                                                color: kSecondaryColor),
//                                          )
//                                              : Container(),
//                                          SizedBox(
//                                              height: getProportionateScreenHeight(
//                                                  kDefaultPadding / 2)),
//                                          transferLoading
//                                              ? SpinKitWave(
//                                            color: kSecondaryColor,
//                                            size: getProportionateScreenWidth(
//                                                kDefaultPadding),
//                                          )
//                                              :
                                                    _loading
                                                        ? SpinKitWave(
                                                            color:
                                                                kSecondaryColor,
                                                            size: getProportionateScreenWidth(
                                                                kDefaultPadding),
                                                          )
                                                        : CustomButton(
                                                            title: "Apply",
                                                            color:
                                                                kSecondaryColor,
                                                            press: () async {
                                                              if (promoCode
                                                                  .isNotEmpty) {
                                                                setState(() {
                                                                  _loading =
                                                                      true;
                                                                });
                                                                _applyPromoCode();
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              } else {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(Service.showMessage(
                                                                        "Promo Code cannot be empty!",
                                                                        false));
                                                              }
                                                            },
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
//                                     showModalBottomSheet<void>(
//                                       backgroundColor: Colors.transparent,
//                                       context: context,
//                                       builder: (context) {
//                                         return StatefulBuilder(builder:
//                                             (BuildContext context,
//                                                 StateSetter setState) {
//                                           return Container(
//                                             decoration: BoxDecoration(
//                                               borderRadius: BorderRadius.only(
//                                                 topLeft: Radius.circular(
//                                                     kDefaultPadding),
//                                                 topRight: Radius.circular(
//                                                     kDefaultPadding),
//                                               ),
//                                               color: kPrimaryColor,
//                                             ),
//                                             padding: EdgeInsets.all(
//                                                 getProportionateScreenHeight(
//                                                     kDefaultPadding)),
//                                             child: SingleChildScrollView(
//                                               child: Column(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.start,
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Text(
//                                                     "Apply Promo Code",
//                                                     style: Theme.of(context)
//                                                         .textTheme
//                                                         .headlineSmall
//                                                         .copyWith(
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                         ),
//                                                   ),
//                                                   SizedBox(
//                                                     height:
//                                                         getProportionateScreenHeight(
//                                                             kDefaultPadding),
//                                                   ),
//
//                                                   TextField(
//                                                     style: TextStyle(
//                                                         color: kBlackColor),
//                                                     keyboardType:
//                                                         TextInputType.text,
//                                                     onChanged: (val) {
//                                                       promoCode = val;
//                                                     },
//                                                     decoration:
//                                                         textFieldInputDecorator
//                                                             .copyWith(
//                                                                 labelText:
//                                                                     "Promo Code"),
//                                                   ),
//                                                   SizedBox(
//                                                     height:
//                                                         getProportionateScreenHeight(
//                                                             kDefaultPadding /
//                                                                 2),
//                                                   ),
//                                                   SizedBox(
//                                                     height:
//                                                         getProportionateScreenHeight(
//                                                             kDefaultPadding /
//                                                                 2),
//                                                   ),
// //                                          transferError
// //                                              ? Text(
// //                                            "Invalid! Please make sure all fields are filled.",
// //                                            style: TextStyle(
// //                                                color: kSecondaryColor),
// //                                          )
// //                                              : Container(),
// //                                          SizedBox(
// //                                              height: getProportionateScreenHeight(
// //                                                  kDefaultPadding / 2)),
// //                                          transferLoading
// //                                              ? SpinKitWave(
// //                                            color: kSecondaryColor,
// //                                            size: getProportionateScreenWidth(
// //                                                kDefaultPadding),
// //                                          )
// //                                              :
//                                                   _loading
//                                                       ? SpinKitWave(
//                                                           color:
//                                                               kSecondaryColor,
//                                                           size: getProportionateScreenWidth(
//                                                               kDefaultPadding),
//                                                         )
//                                                       : CustomButton(
//                                                           title: "Apply",
//                                                           color:
//                                                               kSecondaryColor,
//                                                           press: () async {
//                                                             if (promoCode
//                                                                 .isNotEmpty) {
//                                                               setState(() {
//                                                                 _loading = true;
//                                                               });
//                                                               _applyPromoCode();
//                                                               Navigator.of(
//                                                                       context)
//                                                                   .pop();
//                                                             } else {
//                                                               Navigator.of(
//                                                                       context)
//                                                                   .pop();
//                                                               ScaffoldMessenger
//                                                                       .of(
//                                                                           context)
//                                                                   .showSnackBar(
//                                                                       Service.showMessage(
//                                                                           "Promo Code cannot be empty!",
//                                                                           false));
//                                                             }
//                                                           },
//                                                         ),
//                                                 ],
//                                               ),
//                                             ),
//                                           );
//                                         });
//                                       },
//                                     ).whenComplete(() {
//                                       setState(() {});
//                                     });
                                      }
                                    },
                                    child: Text(
                                      "Apply Promo Code",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: kSecondaryColor,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet<void>(
                                        isScrollControlled: true,
                                        context: context,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(30.0),
                                              topRight: Radius.circular(30.0)),
                                        ),
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(builder:
                                              (BuildContext context,
                                                  StateSetter setState) {
                                            return Padding(
                                              padding: MediaQuery.of(context)
                                                  .viewInsets,
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding)),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    SizedBox(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding),
                                                    ),
                                                    Text(
                                                      Provider.of<ZLanguage>(
                                                              context,
                                                              listen: false)
                                                          .addTip,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding),
                                                    ),
                                                    TextField(
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (val) {
                                                        tipTemp =
                                                            double.parse(val);
                                                      },
                                                      decoration: textFieldInputDecorator
                                                          .copyWith(
                                                              labelText: Provider
                                                                      .of<ZLanguage>(
                                                                          context)
                                                                  .tip),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            tip = 20.00;
                                                            Navigator.pop(
                                                                context);
                                                            _getCartInvoice();
                                                          },
                                                          child: CustomTag(
                                                            text:
                                                                "${Provider.of<ZLanguage>(context, listen: false).addTip} +20 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            tip = 30.00;
                                                            Navigator.pop(
                                                                context);
                                                            _getCartInvoice();
                                                          },
                                                          child: CustomTag(
                                                            text:
                                                                "${Provider.of<ZLanguage>(context, listen: false).addTip} +30 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            tip = 40.00;
                                                            Navigator.pop(
                                                                context);
                                                            _getCartInvoice();
                                                          },
                                                          child: CustomTag(
                                                            text:
                                                                "${Provider.of<ZLanguage>(context, listen: false).addTip} +40 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding),
                                                    ),
                                                    CustomButton(
                                                      title: Provider.of<
                                                                  ZLanguage>(
                                                              context,
                                                              listen: false)
                                                          .submit,
                                                      color: kSecondaryColor,
                                                      press: () async {
                                                        tip = tipTemp;
                                                        Navigator.pop(context);
                                                        _getCartInvoice();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      ).whenComplete(() {
                                        setState(() {});
                                      });
                                      // showModalBottomSheet<void>(
                                      //   isScrollControlled: true,
                                      //   context: context,
                                      //   shape: RoundedRectangleBorder(
                                      //     borderRadius: BorderRadius.only(
                                      //         topLeft: Radius.circular(30.0),
                                      //         topRight: Radius.circular(30.0)),
                                      //   ),
                                      //   builder: (BuildContext context) {
                                      //     return StatefulBuilder(builder:
                                      //         (BuildContext context,
                                      //             StateSetter setState) {
                                      //       return Container(
                                      //         decoration: BoxDecoration(
                                      //           borderRadius: BorderRadius.only(
                                      //             topLeft: Radius.circular(
                                      //                 kDefaultPadding),
                                      //             topRight: Radius.circular(
                                      //                 kDefaultPadding),
                                      //           ),
                                      //           color: kPrimaryColor,
                                      //         ),
                                      //         padding: EdgeInsets.all(
                                      //             getProportionateScreenHeight(
                                      //                 kDefaultPadding)),
                                      //         child: SingleChildScrollView(
                                      //           child: Column(
                                      //             mainAxisAlignment:
                                      //                 MainAxisAlignment.start,
                                      //             crossAxisAlignment:
                                      //                 CrossAxisAlignment.start,
                                      //             mainAxisSize:
                                      //                 MainAxisSize.min,
                                      //             children: [
                                      //               Text(
                                      //                 Provider.of<ZLanguage>(
                                      //                         context)
                                      //                     .addTip,
                                      //                 style: Theme.of(context)
                                      //                     .textTheme
                                      //                     .titleLarge
                                      //                     ?.copyWith(
                                      //                       fontWeight:
                                      //                           FontWeight.bold,
                                      //                     ),
                                      //               ),
                                      //               SizedBox(
                                      //                 height:
                                      //                     getProportionateScreenHeight(
                                      //                         kDefaultPadding),
                                      //               ),
                                      //               TextField(
                                      //                 style: TextStyle(
                                      //                     color: kBlackColor),
                                      //                 keyboardType:
                                      //                     TextInputType.number,
                                      //                 onChanged: (val) {
                                      //                   tip = double.parse(val);
                                      //                 },
                                      //                 decoration: textFieldInputDecorator
                                      //                     .copyWith(
                                      //                         labelText: Provider
                                      //                                 .of<ZLanguage>(
                                      //                                     context)
                                      //                             .tip),
                                      //               ),
                                      //               SizedBox(
                                      //                 height:
                                      //                     getProportionateScreenHeight(
                                      //                         kDefaultPadding /
                                      //                             2),
                                      //               ),
                                      //               SizedBox(
                                      //                 height:
                                      //                     getProportionateScreenHeight(
                                      //                         kDefaultPadding /
                                      //                             2),
                                      //               ),
                                      //               _loading
                                      //                   ? SpinKitWave(
                                      //                       color:
                                      //                           kSecondaryColor,
                                      //                       size: getProportionateScreenWidth(
                                      //                           kDefaultPadding),
                                      //                     )
                                      //                   : CustomButton(
                                      //                       title: Provider.of<
                                      //                                   ZLanguage>(
                                      //                               context)
                                      //                           .apply,
                                      //                       color:
                                      //                           kSecondaryColor,
                                      //                       press: () async {
                                      //                         Navigator.pop(
                                      //                             context);
                                      //                         _getCartInvoice();
                                      //                       },
                                      //                     ),
                                      //             ],
                                      //           ),
                                      //         ),
                                      //       );
                                      //     });
                                      //   },
                                      // ).whenComplete(() {
                                      //   setState(() {});
                                      // });
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          Provider.of<ZLanguage>(context)
                                              .addTip,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: kSecondaryColor,
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          size: getProportionateScreenHeight(
                                              kDefaultPadding * 1.2),
                                          color: kSecondaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(),
                SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
                _placeOrder
                    ? SpinKitWave(
                        color: kSecondaryColor,
                        size: getProportionateScreenWidth(kDefaultPadding),
                      )
                    : CustomButton(
                        title: "Place Order",
                        press: () {
                          if (scheduledOrder) {
                            if (_scheduledDate != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return GlobalKifiya(
                                      price: promoCodeApplied
                                          ? promoCodeData['order_payment']
                                                  ['user_pay_payment']
                                              .toDouble()
                                          : responseData['order_payment']
                                                  ['user_pay_payment']
                                              .toDouble(),
                                      orderPaymentId:
                                          responseData['order_payment']['_id'],
                                      orderPaymentUniqueId:
                                          responseData['order_payment']
                                                  ['unique_id']
                                              .toString(),
                                      onlyCashless: onlyCashless!,
                                    );
                                  },
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                Service.showMessage(
                                  "Please select date & time for schedule",
                                  false,
                                  duration: 5,
                                ),
                              );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return GlobalKifiya(
                                    price: promoCodeApplied
                                        ? promoCodeData['order_payment']
                                                ['user_pay_payment']
                                            .toDouble()
                                        : responseData['order_payment']
                                                ['user_pay_payment']
                                            .toDouble(),
                                    orderPaymentId:
                                        responseData['order_payment']['_id'],
                                    orderPaymentUniqueId:
                                        responseData['order_payment']
                                                ['unique_id']
                                            .toString(),
                                    onlyCashless: onlyCashless!,
                                  );
                                },
                              ),
                            );
                          }
                        },
                        color: kSecondaryColor,
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> getTotalDistance(AbroadCart cart) async {
    var url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=${cart.storeLocation!.lat!.toStringAsFixed(6)},${cart.storeLocation!.long!.toStringAsFixed(6)}&destinations=${cart.destinationAddress!.lat},${cart.destinationAddress!.long}&key=$apiKey";
    try {
      http.Response response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 20),
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

  Future<dynamic> getCartInvoice() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_order_cart_invoice";
    Map data = {
      "user_id": cart!.userId,
      "store_id": cart!.storeId,
      "total_time": selfPickup ? 0 : time,
      "total_distance": selfPickup ? 0 : distance! + 7000,
      "order_type": 7,
      "is_user_pick_up_order": selfPickup,
      "total_item_count": cart!.items!.length,
      "is_user_drop_order": true,
      "express_option": "normal",
      "server_token": cart!.serverToken,
      "tip": tip
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
        Duration(seconds: 20),
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
      debugPrint("Invoice Generated");

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

  Future<dynamic> applyPromoCode() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/apply_promo_code";
    Map data = {
      "user_id": cart!.userId,
      "promo_code_name": promoCode,
      "order_payment_id": responseData['order_payment']['_id'],
      "server_token": cart!.serverToken,
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
        Duration(seconds: 20),
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
        this.promoCodeData = json.decode(response.body);
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

  Future<dynamic> getStoreDetail() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_get_store_product_item_list";
    Map data = {
      "store_id": cart!.storeId,
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
        Duration(seconds: 20),
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
        this.storeDetail = json.decode(response.body);
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
}
