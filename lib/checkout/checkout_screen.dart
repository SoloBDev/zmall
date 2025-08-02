import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/kifiya/kifiya_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';

class CheckoutScreen extends StatefulWidget {
  static String routeName = "checkout";

  CheckoutScreen(
      {this.isForOthers = false,
      this.receiverName = "",
      this.receiverPhone = "",
      this.vehicleId = ""});

  final bool isForOthers;
  final String receiverPhone;
  final String receiverName;
  final String vehicleId;

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Cart? cart;
  AliExpressCart? aliexpressCart;
  bool _loading = true;
  bool _placeOrder = false;
  bool orderAsap = true;
  bool scheduledOrder = false;
  bool selfPickup = false;
  bool promoCodeApplied = false;
  bool? onlySelfPickup;
  bool? onlyScheduledOrder;
  bool? onlyCashless;
  double? distance, time, tip = 0, tipTemp = 0;
  var userData;
  var responseData;
  var paymentResponse;
  var promoCodeData;
  var storeDetail;
  var etaResponse;
  static final String androidKey = 'AIzaSyBzMHLnXLbtLMi9rVFOR0eo5pbouBtxyjg';
  static final String iosKey = 'AIzaSyDAgZScAJfUHxahi_n4OpuI8HrTHVlirJk';
  final apiKey = Platform.isAndroid ? androidKey : iosKey;
  DateTime? _scheduledDate;
  String promoCode = "";
  DateTime? _etaLow;
  DateTime? _etaHigh;

  bool normalDelivery = true;
  bool halfExpress = false;
  bool nextDay = false;
  bool threeHours = false;

  Widget linearProgressIndicator = Container(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinKitWave(
          color: kSecondaryColor,
          size: getProportionateScreenWidth(kDefaultPadding),
        ),
        SizedBox(height: kDefaultPadding * 0.5),
        Text(
          "Loading...",
          style: TextStyle(color: kBlackColor),
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      getCart();
    }
  }

  void getCart() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('cart');
    var aliCart = await Service.read('aliexpressCart');
    if (data != null) {
      setState(() {
        cart = Cart.fromJson(data);
        // debugPrint("cart ${Cart.fromJson(data)}");
        if (cart!.destinationAddress?.name == "User Pickup") {
          setState(() {
            selfPickup = true;
          });
        }
      });
      if (aliCart != null) {
        setState(() {
          aliexpressCart = AliExpressCart.fromJson(aliCart);
        });
      }
      _getStoreDetail();
      // _getTotalDistance(cart!);
      _getTotalDistanceGeoHash(cart!);
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
      if (onlyScheduledOrder!) {
        setState(() {
          orderAsap = false;
          scheduledOrder = true;
        });
      }
      if (onlySelfPickup!) {
        setState(() {
          selfPickup = onlySelfPickup!;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${errorCodes['${promoCodeData['error_code']}']}!", true));
    }
  }

  void _getTotalDistance(Cart cart) async {
    var data = await getTotalDistance(cart);
    if (data != null && data['rows'][0]['elements'][0]['status'] == 'OK') {
      setState(() {
        distance =
            data['rows'][0]['elements'][0]['distance']['value'].toDouble();
        time = data['rows'][0]['elements'][0]['duration']['value'].toDouble();
      });
      await Future.delayed(Duration(seconds: 1));
      _getCartInvoice();
    }
  }

  void _getTotalDistanceGeoHash(Cart cart) async {
    var data = await getTotalDistanceGeoHash(cart);
    if (data != null && data['success']) {
      setState(() {
        distance = data['results'][0].toDouble() * 1050;
        time = data['results'][0].toDouble() * 500;
      });
      await Future.delayed(Duration(seconds: 1));
      _getCartInvoice();
    } else {
      _getTotalDistance(cart);
    }
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

  void _getETA() async {
    setState(() {
      _loading = true;
    });
    var data = await getETA();
    if (data != null) {
      setState(() {
        etaResponse = data['result'];
        int diff = etaResponse['high'] - etaResponse['low'] > 65
            ? 15
            : etaResponse['high'] - etaResponse['low'] < 65 &&
                    etaResponse['high'] - etaResponse['low'] > 55
                ? 10
                : 0;
        _etaLow =
            DateTime.now().add(Duration(minutes: etaResponse['low'].toInt()));
        _etaHigh = DateTime.now()
            .add(Duration(minutes: etaResponse['high'].toInt() - diff));
      });
    } else {
      _etaLow = DateTime.now().add(Duration(minutes: 30));
      _etaHigh = DateTime.now().add(Duration(minutes: 45));
    }
    setState(() {
      _loading = false;
    });
  }

  void _getCartInvoice() async {
    setState(() {
      _loading = true;
    });
    var data = await getCartInvoice();
    // debugPrint("getCartInvoice data $data");
    if (data != null && data['success']) {
      _getETA();
    } else {
      if (responseData['error_code'] != null &&
          responseData['error_code'] == 999) {
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${responseData['error_code']}']}!", true));
        await CoreServices.clearCache();
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${responseData['message']}']}!", true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: Text(
          Provider.of<ZLanguage>(context).checkout,
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        color: kPrimaryColor,
        progressIndicator: linearProgressIndicator,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding)),
                    child: Column(
                      spacing:
                          getProportionateScreenHeight(kDefaultPadding / 1.5),
                      children: [
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(
                              top: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(color: kWhiteColor),
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding),
                            ),
                            boxShadow: [boxShadow],
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CustomTag(
                                //     color: kSecondaryColor,
                                //     text: Provider.of<ZLanguage>(context)
                                //         .deliveryOptions),
                                CustomContainerTag(
                                  title: Provider.of<ZLanguage>(context)
                                      .deliveryOptions,
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2)),
                                cart!.isLaundryService
                                    ? Container()
                                    : CheckboxListTile(
                                        secondary: Icon(
                                          Icons.timelapse,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                        title: Text(
                                            Provider.of<ZLanguage>(context)
                                                .asSoon),
                                        subtitle: Text(
                                            Provider.of<ZLanguage>(context)
                                                .expressOrder),
                                        activeColor: kSecondaryColor,
                                        value: this.orderAsap,
                                        onChanged: (bool? value) {
                                          if (!onlyScheduledOrder!) {
                                            if (value!) {
                                              setState(() {
                                                this.orderAsap = value;
                                                this.scheduledOrder = false;
                                                cart!.isSchedule = false;
                                                cart!.scheduleStart =
                                                    DateTime.now();
                                              });
                                            }
                                            Service.save(
                                                'cart', cart!.toJson());
                                            getCart();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
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
                                        },
                                      ),
                                CheckboxListTile(
                                  secondary: Icon(
                                    Icons.calendar_today,
                                    color: kSecondaryColor,
                                    size: getProportionateScreenWidth(
                                        kDefaultPadding),
                                  ),
                                  title: Text(Provider.of<ZLanguage>(context)
                                      .scheduleOrder),
                                  subtitle: Text(
                                      Provider.of<ZLanguage>(context).preOrder),
                                  activeColor: kSecondaryColor,
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
                                          cart!.isSchedule = false;
                                        });
                                        Service.save("cart", cart!.toJson());
                                      }
                                    } else {
                                      setState(() {
                                        this.scheduledOrder =
                                            onlyScheduledOrder!;
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
                                              _scheduledDate != null
                                                  ? _scheduledDate
                                                      .toString()
                                                      .split('.')[0]
                                                  : Provider.of<ZLanguage>(
                                                          context)
                                                      .addDate,
                                              style: TextStyle(
                                                color: kSecondaryColor,
                                              ),
                                            ),
                                            style: ButtonStyle(
                                              elevation:
                                                  WidgetStateProperty.all(1.0),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      kPrimaryColor),
                                            ),
                                            onPressed: () async {
                                              DateTime _now = DateTime.now();
                                              DateTime? pickedDate =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: _now,
                                                lastDate: _now.add(
                                                  Duration(days: 7),
                                                ),
                                              );
                                              TimeOfDay? time =
                                                  await showTimePicker(
                                                      context: context,
                                                      initialTime: TimeOfDay
                                                          .fromDateTime(
                                                              DateTime.now()));
                                              setState(() {
                                                _scheduledDate = pickedDate!
                                                    .add(Duration(
                                                        hours: time!.hour,
                                                        minutes: time.minute));
                                                cart!.isSchedule = true;
                                                cart!.scheduleStart =
                                                    _scheduledDate;
                                              });
                                              await Service.save(
                                                  'cart', cart!.toJson());
                                              getCart();
                                            },
                                          ),
                                        ],
                                      )
                                    : Container(),
                                cart!.isLaundryService
                                    ? Container()
                                    : CheckboxListTile(
                                        secondary: Icon(
                                          Icons.perm_identity,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                        title: Text(
                                            Provider.of<ZLanguage>(context)
                                                .selfPickup),
                                        subtitle: Text(
                                            Provider.of<ZLanguage>(context)
                                                .diy),
                                        activeColor: kSecondaryColor,
                                        value: this.selfPickup,
                                        onChanged: (bool? value) {
                                          if (!onlySelfPickup!) {
                                            setState(() {
                                              this.selfPickup = value!;
                                            });
                                            getCart();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              Service.showMessage(
                                                "Store only allows self pickup. No delivery fee",
                                                false,
                                                duration: 5,
                                              ),
                                            );
                                            setState(() {
                                              this.selfPickup = onlySelfPickup!;
                                            });
                                          }
                                        },
                                      ),
                                cart!.isLaundryService
                                    ? CheckboxListTile(
                                        secondary: Icon(
                                          Icons.timer_sharp,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                        title: Text("Normal delivery"),
                                        subtitle: Text("Delivered in 4-5 days"),
                                        activeColor: kSecondaryColor,
                                        value: normalDelivery,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            normalDelivery = true;
                                            halfExpress = false;
                                            nextDay = false;
                                            threeHours = false;
                                          });
                                          getCart();
                                        },
                                      )
                                    : Container(),
                                cart!.isLaundryService
                                    ? CheckboxListTile(
                                        secondary: Icon(
                                          Icons.fast_forward_rounded,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                        title: Text("Half express delivery"),
                                        subtitle:
                                            Text("Delivered within 2 days"),
                                        activeColor: kSecondaryColor,
                                        value: halfExpress,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            normalDelivery = false;
                                            halfExpress = true;
                                            nextDay = false;
                                            threeHours = false;
                                          });
                                          getCart();
                                        },
                                      )
                                    : Container(),
                                cart!.isLaundryService
                                    ? CheckboxListTile(
                                        secondary: Icon(
                                          Icons.today_outlined,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                        title: Text("Next day delivery"),
                                        subtitle:
                                            Text("Delivered the next day"),
                                        activeColor: kSecondaryColor,
                                        value: nextDay,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            normalDelivery = false;
                                            halfExpress = false;
                                            nextDay = true;
                                            threeHours = false;
                                          });
                                          getCart();
                                        },
                                      )
                                    : Container(),
                                cart!.isLaundryService
                                    ? CheckboxListTile(
                                        secondary: Icon(
                                          Icons.timer_3_select_sharp,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                        title: Text("Three hours delivery"),
                                        subtitle:
                                            Text("Delivered within 3 hours"),
                                        activeColor: kSecondaryColor,
                                        value: threeHours,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            normalDelivery = false;
                                            halfExpress = false;
                                            nextDay = false;
                                            threeHours = true;
                                          });
                                          getCart();
                                        },
                                      )
                                    : Container(),
                              ],
                            ),
                          ),
                        ),
                        /////delivery details section//////
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(color: kWhiteColor),
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding),
                            ),
                            boxShadow: [boxShadow],
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding / 1.5),
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 1.5)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CustomTag(
                                //     color: kSecondaryColor,
                                //     text: Provider.of<ZLanguage>(context)
                                //         .deliveryDetails),
                                CustomContainerTag(
                                  title: Provider.of<ZLanguage>(context)
                                      .deliveryDetails,
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding)),
                                DetailsRow(
                                  title: Provider.of<ZLanguage>(context).name,
                                  subtitle: widget.receiverName.isNotEmpty &&
                                          widget.isForOthers
                                      ? widget.receiverName
                                      : userData != null
                                          ? "${userData['user']['first_name']} ${userData['user']['last_name']} "
                                          : "",
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 3)),
                                DetailsRow(
                                  title: Provider.of<ZLanguage>(context).phone,
                                  subtitle: widget.receiverPhone.isNotEmpty &&
                                          widget.isForOthers
                                      ? "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${widget.receiverPhone}"
                                      : userData != null
                                          ? "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${userData['user']['phone']}"
                                          : "",
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 3)),
                                DetailsRow(
                                  title: Provider.of<ZLanguage>(context)
                                      .deliveryAddress,
                                  subtitle: cart != null
                                      ? "${cart!.destinationAddress?.name?.split(',')[0]}"
                                      : "",
                                ),
                              ],
                            ),
                          ),
                        ),

                        //////Order details section//////
                        responseData != null && responseData['success']
                            ? Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  border: Border.all(color: kWhiteColor),
                                  borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding),
                                  ),
                                  boxShadow: [boxShadow],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                      vertical: getProportionateScreenHeight(
                                          kDefaultPadding / 1.5)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // CustomTag(
                                      //     color: kSecondaryColor,
                                      //     text: Provider.of<ZLanguage>(context)
                                      //         .orderDetail),
                                      CustomContainerTag(
                                        title: Provider.of<ZLanguage>(context)
                                            .orderDetail,
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding)),
                                      DetailsRow(
                                        title: Provider.of<ZLanguage>(context)
                                            .servicePrice,
                                        subtitle: promoCodeApplied
                                            ? "${Provider.of<ZMetaData>(context, listen: false).currency} ${promoCodeData['order_payment']['total_delivery_price'].toStringAsFixed(2)}"
                                            : "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_payment']['total_delivery_price'].toStringAsFixed(2)}",
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 3)),
                                      DetailsRow(
                                        title: Provider.of<ZLanguage>(context)
                                            .totalOrderPrice,
                                        subtitle: promoCodeApplied
                                            ? "${Provider.of<ZMetaData>(context, listen: false).currency} ${promoCodeData['order_payment']['total_order_price'].toStringAsFixed(2)}"
                                            : "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_payment']['total_order_price'].toStringAsFixed(2)}",
                                      ),
                                      // SizedBox(
                                      //     height: getProportionateScreenHeight(
                                      //         kDefaultPadding / 3)),
                                      // DetailsRow(
                                      //   title: Provider.of<ZLanguage>(context)
                                      //       .promoPayment,
                                      //   subtitle: promoCodeApplied
                                      //       ? "${Provider.of<ZMetaData>(context, listen: false).currency} -${promoCodeData['order_payment']['promo_payment'].toStringAsFixed(2)}"
                                      //       : "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_payment']['promo_payment'].toStringAsFixed(2)}",
                                      // ),
                                      // SizedBox(
                                      //     height: getProportionateScreenHeight(
                                      //         kDefaultPadding / 3)),
                                      // DetailsRow(
                                      //   title:
                                      //       Provider.of<ZLanguage>(context).tip,
                                      //   subtitle:
                                      //       "${Provider.of<ZMetaData>(context, listen: false).currency} ${tip!.toStringAsFixed(2)}",
                                      // ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 3)),
                                      // aliexpressCart != null &&
                                      //         aliexpressCart!.cart.storeId ==
                                      //             cart!.storeId
                                      //     ? SizedBox.shrink()
                                      //     : Align(
                                      //         alignment: Alignment.center,
                                      //         child: Text(
                                      //           textAlign: TextAlign.center,
                                      //           Provider.of<ZLanguage>(context)
                                      //               .orderTime,
                                      //         ),
                                      //       ),
                                      DetailsRow(
                                        title: Provider.of<ZLanguage>(context)
                                            .promoPayment,
                                        subtitle: promoCodeApplied
                                            ? "${Provider.of<ZMetaData>(context, listen: false).currency} -${promoCodeData['order_payment']['promo_payment'].toStringAsFixed(2)}"
                                            : "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_payment']['promo_payment'].toStringAsFixed(2)}",
                                        onTap: () {
                                          _showApplyPromoCodeWidget();
                                        },
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 3)),

                                      DetailsRow(
                                        title:
                                            Provider.of<ZLanguage>(context).tip,
                                        subtitle:
                                            "${tip!.toStringAsFixed(2)} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                        onTap: () {
                                          _showTipWidget();
                                        },
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 3)),
                                      if (_etaLow != null ||
                                          (aliexpressCart != null &&
                                              aliexpressCart!.cart.storeId !=
                                                  cart!.storeId))
                                        DetailsRow(
                                          title: "Estimated Time",
                                          subtitle:
                                              "${_etaLow.toString().split(" ")[1].split(".")[0]} - ${_etaHigh.toString().split(' ')[1].split('.')[0]}",
                                        ),
                                      // _etaLow == null ||
                                      //         (aliexpressCart != null &&
                                      //             aliexpressCart!
                                      //                     .cart.storeId ==
                                      //                 cart!.storeId)
                                      //     ? SizedBox.shrink()
                                      //     : Align(
                                      //   alignment: Alignment.center,
                                      //   child: Text(
                                      //     "${_etaLow.toString().split(" ")[1].split(".")[0]} - ${_etaHigh.toString().split(' ')[1].split('.')[0]}",
                                      //     style: Theme.of(context)
                                      //         .textTheme
                                      //         .bodyLarge
                                      //         ?.copyWith(
                                      //             fontWeight:
                                      //                 FontWeight.w700),
                                      //   ),
                                      // ),
                                      // : Container(),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 2)),
                                      // Center(
                                      //   child: Row(
                                      //     mainAxisAlignment:
                                      //         MainAxisAlignment.center,
                                      //     children: [
                                      //       Text(
                                      //         "${Provider.of<ZLanguage>(context).total} :",
                                      //         style: TextStyle(
                                      //           fontSize:
                                      //               getProportionateScreenWidth(
                                      //                   kDefaultPadding * .7),
                                      //         ),
                                      //       ),
                                      //       SizedBox(
                                      //           width:
                                      //               getProportionateScreenHeight(
                                      //                   kDefaultPadding / 3)),
                                      //       Text(
                                      //         promoCodeApplied
                                      //             ? "${Provider.of<ZMetaData>(context, listen: false).currency} ${promoCodeData['order_payment']['user_pay_payment'].toStringAsFixed(2)}"
                                      //             : "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_payment']['user_pay_payment'].toStringAsFixed(2)}",
                                      //         style: Theme.of(context)
                                      //             .textTheme
                                      //             .headlineSmall
                                      //             ?.copyWith(
                                      //                 fontWeight:
                                      //                     FontWeight.bold),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      // Center(
                                      //   child: Column(
                                      //     children: [
                                      //       Text(
                                      //         Provider.of<ZLanguage>(context).total,
                                      //         style: TextStyle(
                                      //           fontSize: getProportionateScreenWidth(
                                      //               kDefaultPadding * .7),
                                      //         ),
                                      //       ),
                                      //       SizedBox(
                                      //           height: getProportionateScreenHeight(
                                      //               kDefaultPadding / 3)),
                                      //       Text(
                                      //         promoCodeApplied
                                      //             ? "${Provider.of<ZMetaData>(context, listen: false).currency} ${promoCodeData['order_payment']['user_pay_payment'].toStringAsFixed(2)}"
                                      //             : "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_payment']['user_pay_payment'].toStringAsFixed(2)}",
                                      //         style: Theme.of(context)
                                      //             .textTheme
                                      //             .headlineSmall
                                      //             ?.copyWith(
                                      //                 fontWeight: FontWeight.bold),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      ////////////promo code and tip
                                    ],
                                  ),
                                ),
                              )
                            : _loading
                                ? SpinKitDancingSquare(
                                    color: kSecondaryColor,
                                    size: getProportionateScreenHeight(
                                        kDefaultPadding),
                                  )
                                : Container(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding)),
                                        child: Text(
                                            "${errorCodes['${responseData['message']}']}"),
                                      ),
                                    ),
                                  ),
                        // SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
                      ],
                    ),
                  ),
                ),
              ),

              /////place order button
              Container(
                width: double.infinity,
                // height: kDefaultPadding * 4,
                padding: EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 2,
                    horizontal: kDefaultPadding / 2),
                decoration: BoxDecoration(
                    color: kPrimaryColor,
                    border: Border(top: BorderSide(color: kWhiteColor)),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(kDefaultPadding),
                        topRight: Radius.circular(kDefaultPadding))),
                child: Column(
                  spacing: getProportionateScreenHeight(kDefaultPadding / 2),
                  children: [
                    if (responseData != null && responseData['success'])
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${Provider.of<ZLanguage>(context).total} :",
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(
                                    kDefaultPadding * .7),
                              ),
                            ),
                            SizedBox(
                                width: getProportionateScreenHeight(
                                    kDefaultPadding / 2)),
                            Text(
                              promoCodeApplied
                                  ? "${Provider.of<ZMetaData>(context, listen: false).currency} ${promoCodeData['order_payment']['user_pay_payment'].toStringAsFixed(2)}"
                                  : "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_payment']['user_pay_payment'].toStringAsFixed(2)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    _placeOrder
                        ? SpinKitWave(
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          )
                        : CustomButton(
                            title: Provider.of<ZLanguage>(context).placeOrder,
                            press: () {
                              if (scheduledOrder) {
                                if (_scheduledDate != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return KifiyaScreen(
                                          price: promoCodeApplied
                                              ? promoCodeData['order_payment']
                                                      ['user_pay_payment']
                                                  .toDouble()
                                              : responseData['order_payment']
                                                      ['user_pay_payment']
                                                  .toDouble(),
                                          orderPaymentId:
                                              responseData['order_payment']
                                                  ['_id'],
                                          orderPaymentUniqueId:
                                              responseData['order_payment']
                                                      ['unique_id']
                                                  .toString(),
                                          onlyCashless: onlyCashless,
                                          vehicleId: responseData['vehicles'][0]
                                              ['_id'],
                                          userpickupWithSchedule:
                                              cart!.isSchedule && selfPickup
                                                  ? true
                                                  : false,
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
                                      return KifiyaScreen(
                                        price: promoCodeApplied
                                            ? promoCodeData['order_payment']
                                                    ['user_pay_payment']
                                                .toDouble()
                                            : responseData['order_payment']
                                                    ['user_pay_payment']
                                                .toDouble(),
                                        orderPaymentId:
                                            responseData['order_payment']
                                                ['_id'],
                                        orderPaymentUniqueId:
                                            responseData['order_payment']
                                                    ['unique_id']
                                                .toString(),
                                        onlyCashless: (onlyCashless ??
                                                false) ////new, safest way of old method
                                            ? true
                                            : (selfPickup ? true : false),

                                        // onlyCashless: onlyCashless!  //old
                                        //     ? onlyCashless
                                        //     : selfPickup
                                        //         ? true
                                        //         : false,
                                        vehicleId: responseData['vehicles'][0]
                                            ['_id'],
                                        userpickupWithSchedule:
                                            cart!.isSchedule && selfPickup
                                                ? true
                                                : false,
                                      );
                                    },
                                  ),
                                );
                              }
                            },
                            color: kSecondaryColor,
                          ),
                  ],
                ),
              ),
              // SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
            ],
          ),
        ),
      ),
    );
  }

  Widget CustomContainerTag({
    required String title,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2, vertical: kDefaultPadding / 4),
      decoration: BoxDecoration(
          color: kSecondaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(kDefaultPadding / 2)),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(color: kSecondaryColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<dynamic> getTotalDistance(Cart cart) async {
    setState(() {
      linearProgressIndicator = Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitWave(
              color: kSecondaryColor,
              size: getProportionateScreenWidth(kDefaultPadding),
            ),
            SizedBox(height: kDefaultPadding * 0.5),
            Text(
              "Calculating distance...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=${cart.storeLocation?.lat?.toStringAsFixed(6)},${cart.storeLocation?.long?.toStringAsFixed(6)}&destinations=${cart.destinationAddress?.lat},${cart.destinationAddress?.long}&key=$apiKey";
    try {
      http.Response response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );

      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Something went wrong! Check your internet and try again", true,
              duration: 3),
        );
      }
      return null;
    }
  }

  Future<dynamic> getTotalDistanceGeoHash(Cart cart) async {
    setState(() {
      linearProgressIndicator = Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitWave(
              color: kSecondaryColor,
              size: getProportionateScreenWidth(kDefaultPadding),
            ),
            SizedBox(height: kDefaultPadding * 0.5),
            Text(
              "Calculating geohash distance...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url = "http://167.172.180.220:5331/get_distance";
    Map data = {
      "locations": [
        {
          "pickup": [cart.storeLocation?.lat, cart.storeLocation?.long],
          "destination": [
            cart.destinationAddress?.lat,
            cart.destinationAddress?.long
          ]
        }
      ]
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
        Duration(seconds: 30),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Something went wrong! Check your internet and try again", true,
              duration: 3),
        );
      }
      return null;
    }
  }

  Future<dynamic> getCartInvoice() async {
    setState(() {
      linearProgressIndicator = Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitWave(
              color: kSecondaryColor,
              size: getProportionateScreenWidth(kDefaultPadding),
            ),
            SizedBox(height: kDefaultPadding * 0.5),
            Text(
              "Generating Order Invoice...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_order_cart_invoice";
    Map data = {
      "user_id": cart!.userId,
      "store_id": cart!.storeId,
      "total_time": selfPickup ? 0 : time,
      "total_distance": selfPickup ? 0 : distance,
      "order_type": 7,
      "is_user_pick_up_order": selfPickup,
      "total_item_count": cart!.items?.length,
      "is_user_drop_order": !cart!.isLaundryService,
      "express_option": normalDelivery
          ? "normal"
          : halfExpress
              ? "half_express"
              : nextDay
                  ? "next_day"
                  : threeHours
                      ? "three_hour"
                      : "normal",
      "server_token": cart!.serverToken,
      "vehicle_id": widget.vehicleId,
      "tip": tip,
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
        Duration(seconds: 30),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });

          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.responseData = json.decode(response.body);
        this._loading = false;
      });
      // debugPrint("orderPaymentUniqueId:${responseData['order_payment']['unique_id']}");
      // debugPrint("====================\n");
      // debugPrint("vehicles>>>> ${responseData['vehicles'][0]['_id']}");
      // debugPrint("====================\n");
      // debugPrint("responseData>>> $responseData");
      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Order invoice failed! Check your internet and try again", true,
              duration: 4),
        );
      }
      return null;
    }
  }

  Future<dynamic> applyPromoCode() async {
    setState(() {
      linearProgressIndicator = Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitWave(
              color: kSecondaryColor,
              size: getProportionateScreenWidth(kDefaultPadding),
            ),
            SizedBox(height: kDefaultPadding * 0.5),
            Text(
              "Applying promo code...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.promoCodeData = json.decode(response.body);
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Apply promo code failed! Check your internet and try again",
              true,
              duration: 3),
        );
      }
      return null;
    }
  }

  Future<dynamic> getETA() async {
    linearProgressIndicator = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitWave(
            color: kSecondaryColor,
            size: getProportionateScreenWidth(kDefaultPadding),
          ),
          SizedBox(height: kDefaultPadding * 0.5),
          Text(
            "Calculating delivery time...",
            style: TextStyle(color: kBlackColor),
          ),
        ],
      ),
    );

    var url = "https://ethiopiataxi.com/order/eta_predict";
    Map data = {
      "model_id": 1,
      "cart_total": responseData['order_payment']['total_order_price'],
      "delivery_total": responseData['order_payment']['total_delivery_price'],
      "distance": distance! / 1000,
      "hour": DateTime.now().hour,
      "weekday": DateTime.now().weekday,
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.storeDetail = json.decode(response.body);
      });
      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Couldn't get store detail, check your internet and try again.",
              true,
              duration: 3),
        );
      }
      return null;
    }
  }

  Future<dynamic> getStoreDetail() async {
    linearProgressIndicator = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitWave(
            color: kSecondaryColor,
            size: getProportionateScreenWidth(kDefaultPadding),
          ),
          SizedBox(height: kDefaultPadding * 0.5),
          Text(
            "Fetching merchant detail...",
            style: TextStyle(color: kBlackColor),
          ),
        ],
      ),
    );

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
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.storeDetail = json.decode(response.body);
      });
      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Couldn't get store detail, check your internet and try again.",
              true,
              duration: 3),
        );
      }
      return null;
    }
  }

  ////Promo///////////////
  void _showApplyPromoCodeWidget() {
    showModalBottomSheet<void>(
      backgroundColor: kPrimaryColor,
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SafeArea(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kDefaultPadding),
                  topRight: Radius.circular(kDefaultPadding),
                ),
                color: kPrimaryColor,
              ),
              padding:
                  EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Provider.of<ZLanguage>(context).applyPromoCode,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    TextField(
                      style: TextStyle(color: kBlackColor),
                      keyboardType: TextInputType.text,
                      onChanged: (val) {
                        promoCode = val;
                      },
                      decoration: textFieldInputDecorator.copyWith(
                          labelText: Provider.of<ZLanguage>(context).promoCode),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    _loading
                        ? SpinKitWave(
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          )
                        : CustomButton(
                            title: Provider.of<ZLanguage>(context).apply,
                            color: kSecondaryColor,
                            press: () async {
                              if (promoCode.isNotEmpty) {
                                setState(() {
                                  _loading = true;
                                });
                                _applyPromoCode();
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        "Promo Code cannot be empty!", false));
                              }
                            },
                          ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {});
    });
  }

  ////////////////////Tip////////////////
  void _showTipWidget() {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: kPrimaryColor,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SafeArea(
            child: Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                padding: EdgeInsets.all(
                    getProportionateScreenHeight(kDefaultPadding)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    Text(
                      Provider.of<ZLanguage>(context, listen: false).addTip,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    TextField(
                      style: TextStyle(color: kBlackColor),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        FilteringTextInputFormatter.singleLineFormatter,
                        FilteringTextInputFormatter.deny(RegExp(r'^0')),
                      ],
                      onChanged: (val) {
                        tipTemp = double.parse(val);
                      },
                      decoration: textFieldInputDecorator.copyWith(
                          labelText: Provider.of<ZLanguage>(context).tip),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // InkWell(
                        //   onTap: () {
                        //     tip =
                        //         20.00;
                        //     Navigator.pop(
                        //         context);
                        //     _getCartInvoice();
                        //   },
                        //   child:
                        //       CustomTag(
                        //     text:
                        //         "${Provider.of<ZLanguage>(context, listen: false).addTip} +20 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                        //   ),
                        // ),
                        InkWell(
                          onTap: () {
                            tip = 20.00;
                            Navigator.pop(context);
                            _getCartInvoice();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: kDefaultPadding / 2,
                                vertical: kDefaultPadding / 4),
                            decoration: BoxDecoration(
                                color: kBlackColor,
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding / 2)),
                            child: Text(
                              "${Provider.of<ZLanguage>(context, listen: false).addTip} +20 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(color: kPrimaryColor),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            tip = 30.00;
                            Navigator.pop(context);
                            _getCartInvoice();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: kDefaultPadding / 2,
                                vertical: kDefaultPadding / 4),
                            decoration: BoxDecoration(
                                color: kBlackColor,
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding / 2)),
                            child: Text(
                              "${Provider.of<ZLanguage>(context, listen: false).addTip} +30 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(color: kPrimaryColor),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            tip = 40.00;
                            Navigator.pop(context);
                            _getCartInvoice();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: kDefaultPadding / 2,
                                vertical: kDefaultPadding / 4),
                            decoration: BoxDecoration(
                                color: kBlackColor,
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding / 2)),
                            child: Text(
                              "${Provider.of<ZLanguage>(context, listen: false).addTip} +40 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(color: kPrimaryColor),
                            ),
                          ),
                        ),
                        // InkWell(
                        //   onTap: () {
                        //     tip =
                        //         40.00;
                        //     Navigator.pop(
                        //         context);
                        //     _getCartInvoice();
                        //   },
                        //   child:
                        //       CustomTag(
                        //     text:
                        //         "${Provider.of<ZLanguage>(context, listen: false).addTip} +40 ${Provider.of<ZMetaData>(context, listen: false).currency}",
                        //   ),
                        // ),
                      ],
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    CustomButton(
                      title:
                          Provider.of<ZLanguage>(context, listen: false).submit,
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
            ),
          );
        });
      },
    ).whenComplete(() {
      setState(() {});
    });
  }
}

class DetailsRow extends StatelessWidget {
  const DetailsRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.textColor,
    this.fontWeight,
    this.onTap,
  });
  final String title, subtitle;
  final Color? textColor;
  final FontWeight? fontWeight;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.normal,
          ),
        ),
        onTap != null
            ? Row(
                spacing: kDefaultPadding / 2,
                children: [
                  InkWell(
                    onTap: onTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 2,
                          vertical: kDefaultPadding / 4),
                      decoration: BoxDecoration(
                        color: kSecondaryColor.withValues(alpha: 0.18),
                        borderRadius:
                            BorderRadius.circular(kDefaultPadding / 2),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: kSecondaryColor,
                      ),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: fontWeight ?? FontWeight.normal,
                      color: textColor ?? kBlackColor,
                    ),
                    softWrap: true,
                    textAlign: TextAlign.right,
                  ),
                ],
              )
            : Expanded(
                child: Text(
                  subtitle,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: fontWeight ?? FontWeight.normal,
                    color: textColor ?? kBlackColor,
                  ),
                  softWrap: true,
                  textAlign: TextAlign.right,
                ),
              ),
      ],
    );
  }
}
// class DetailsRow extends StatelessWidget {
//   const DetailsRow({
//     Key? key,
//     required this.title,
//     required this.subtitle,
//   }) : super(key: key);
//   final String title, subtitle;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                 fontWeight: FontWeight.w500,
//               ),
//         ),
//         Expanded(
//           child: Text(
//             subtitle,
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: kSecondaryColor,
//                 ),
//             softWrap: true,
//             textAlign: TextAlign.right,
//           ),
//         ),
//       ],
//     );
//   }
// }
