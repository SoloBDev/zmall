// ignore_for_file: deprecated_member_use, unused_element

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/kifiya/components/addis_pay.dart';
import 'package:zmall/kifiya/components/amole_screen.dart';
import 'package:zmall/kifiya/components/cbe_ussd.dart';
import 'package:zmall/kifiya/components/chapa_screen.dart';
import 'package:zmall/kifiya/components/cyber_source.dart';
import 'package:zmall/kifiya/components/dashen_master_card.dart';
import 'package:zmall/kifiya/components/ethswitch_screen.dart';
import 'package:zmall/kifiya/components/etta_card_screen.dart';
import 'package:zmall/kifiya/components/santimpay_screen.dart';
import 'package:zmall/kifiya/components/telebirr_inapp.dart';
import 'package:zmall/kifiya/components/telebirr_ussd.dart';
import 'package:zmall/kifiya/kifiya_verification.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/random_digits.dart';
import 'package:zmall/report/report_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'components/kifiya_method_container.dart';
import 'components/telebirr_screen.dart';

class KifiyaScreen extends StatefulWidget {
  static String routeName = '/kifiya';

  const KifiyaScreen({
    this.vehicleId,
    this.onlyCashless = false,
    @required this.price,
    this.isCourier = false,
    @required this.orderPaymentId,
    @required this.orderPaymentUniqueId,
    this.userpickupWithSchedule,
  });
  final double? price;
  final bool? isCourier;
  final String? vehicleId;
  final bool? onlyCashless;
  final String? orderPaymentId;
  final String? orderPaymentUniqueId;
  final bool? userpickupWithSchedule;

  @override
  _KifiyaScreenState createState() => _KifiyaScreenState();
}

class _KifiyaScreenState extends State<KifiyaScreen> {
  bool _loading = true;
  bool _placeOrder = false;
  bool paidBySender = true;
  late Cart cart;
  AliExpressCart? aliexpressCart;
  List<String> itemIds = [];
  List<int> productIds = [];
  var paymentResponse;
  var orderResponse;
  var services;
  var courierCart;
  var imagePath;
  var userData;
  var aliExpressAccessToken;
  int kifiyaMethod = -1;
  double topUpAmount = 0.0;
  double currentBalance = 0.0;
  late String otp;
  late String uuid;
  bool isCourierSchedule = false;
  late String courierScheduleDate;
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
          "Gathering payment options...",
          style: TextStyle(color: kBlackColor),
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    getUser();
    if (widget.onlyCashless!) {
      kifiyaMethod = -1;
    }
    uuid = widget.orderPaymentUniqueId!;
  }

  void _userDetails() async {
    var usrData = await userDetails();
    if (usrData != null && usrData['success']) {
      setState(() {
        userData = usrData;
        currentBalance = double.parse(userData['user']['wallet'].toString());
      });

      Service.save('user', userData);
    }
  }

  // void getUser() async {
  //   var data = await Service.read('user');

  //   if (data != null) {
  //     setState(() {
  //       userData = data;
  //       currentBalance = double.parse(userData['user']['wallet'].toString());
  //     });
  //     getCart();
  //   }
  // }
  void getUser() async {
    var data = await Service.read('user');
    var aliAcct = await Service.read('ali_access_token');
    if (data != null) {
      setState(() {
        userData = data;
        currentBalance = double.parse(userData['user']['wallet'].toString());
        // Only assign aliExpressAccessToken if aliAcct is not null or empty
        if (aliAcct != null && aliAcct.isNotEmpty) {
          aliExpressAccessToken = aliAcct;
        } else {
          // debugPrint("aliExpress Access Token not found>>>");
        }
      });
      getCart();
    }
  }

  // void getCart() async {
  //   if (widget.isCourier!) {
  //     var data = await Service.read('courier');
  //     if (data != null) {
  //       setState(() {
  //         courierCart = data;
  //         _getPaymentGateway();
  //         getServices();
  //         getImages();
  //         getCourierKefay();
  //         getCourierSchedule();
  //         getCourierScheduleDate();
  //       });
  //     }
  //   } else {
  //     var data = await Service.read('cart');
  //     if (data != null) {
  //       setState(() {
  //         cart = Cart.fromJson(data);
  //         _getPaymentGateway();
  //       });
  //     }
  //   }
  // }
  void getCart() async {
    if (widget.isCourier!) {
      var data = await Service.read('courier');

      if (data != null) {
        setState(() {
          courierCart = data;
          _getPaymentGateway();
          getServices();
          getImages();
          getCourierKefay();
          getCourierSchedule();
          getCourierScheduleDate();
        });
      }
    } else {
      var data = await Service.read('cart');
      var aliCart = await Service.read('aliexpressCart');

      if (data != null) {
        setState(() {
          cart = Cart.fromJson(data);
          // Only set values from aliCart if aliCart is not null
          if (aliCart != null) {
            aliexpressCart = AliExpressCart.fromJson(aliCart);
            itemIds = aliexpressCart!.itemIds!;
            productIds = aliexpressCart!.productIds!;
          }
          // debugPrint("ALI CART>>> ${aliexpressCart!.toJson()}");
        });
        _getPaymentGateway();
      }
    }
  }

  void getServices() async {
    var data = await Service.read('services');
    if (data != null) {
      setState(() {
        services = data;
      });
    }
  }

  void getImages() async {
    var data = await Service.read('images');

    if (data != null) {
      setState(() {
        imagePath = data;
      });
    }
  }

  void getCourierSchedule() async {
    var data = await Service.readBool('is_schedule');
    if (data != null) {
      setState(() {
        isCourierSchedule = data;
      });
    }
  }

  void getCourierScheduleDate() async {
    var data = await Service.read('schedule_start');
    if (data != null) {
      setState(() {
        courierScheduleDate = data;
      });
    }
  }

  void getCourierKefay() async {
    var data = await Service.readBool('courier_paid_by_sender');
    if (data != null) {
      setState(() {
        paidBySender = data;
      });
    }
  }

  void _getPaymentGateway() async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    await getPaymentGateway();
    if (paymentResponse != null && paymentResponse['success']) {
      // for (var i = 0; i < paymentResponse['payment_gateway'].length; i++) {
      //   debugPrint(paymentResponse['payment_gateway'][i]['name']);
      //   debugPrint("\t${paymentResponse['payment_gateway'][i]['description']}");
      // }
      for (var i = 0; i < paymentResponse['payment_gateway'].length; i++) {
        debugPrint(paymentResponse['payment_gateway'][i]['name']);
        debugPrint("\t${paymentResponse['payment_gateway'][i]['description']}");
      }
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      await useBorsa();
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      await Future.delayed(Duration(seconds: 2));
      if (paymentResponse['error_code'] != null &&
          paymentResponse['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  void _createCourierOrder() async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    await createCourierOrder();
    setState(() {
      _loading = false;
      _placeOrder = false;
    });
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
        data['data']['aliexpress_ds_order_create_response']['result']
            ['is_success']) {
      List<dynamic>? orderIds = data['data']
              ['aliexpress_ds_order_create_response']['result']['order_list']
          ['number'];
      _createOrder(orderIds: orderIds);
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Faild to create the order! please try again.", true));
    }
  }

  void _createOrder({List<dynamic>? orderIds}) async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await createOrder(orderIds: orderIds);
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(("Order successfully created"), true));
      await Service.remove('cart');
      await Service.remove('aliexpressCart');
      setState(() {
        _loading = false;
        _placeOrder = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ReportScreen(
              price: widget.price!,
              orderPaymentUniqueId: widget.orderPaymentUniqueId!,
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
    }
  }

  // void _payOrderPayment({otp, paymentId = ""}) async {
  //   var pId = "";
  //   if (otp.toString().isNotEmpty) {
  //     pId = paymentId;
  //   } else {
  //     if (!widget.isCourier!) {
  //       pId = "0";
  //     }
  //   }
  //   if (kifiyaMethod != -1) {
  //     setState(() {
  //       _loading = true;
  //       _placeOrder = true;
  //     });
  //     var data = await payOrderPayment(
  //         otp, paymentResponse['payment_gateway'][kifiyaMethod]['_id']);
  //     if (data != null && data['success']) {
  //       widget.isCourier! ? _createCourierOrder() : _createOrder();
  //     } else {
  //       setState(() {
  //         _loading = false;
  //         _placeOrder = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
  //           "${errorCodes['${data['error_code']}']}!", true));
  //       await Future.delayed(Duration(seconds: 2));
  //       if (data['error_code'] == 999) {
  //         await Service.saveBool('logged', false);
  //         await Service.remove('user');
  //         Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  //       }
  //     }
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
  //         "Please select a payment method for your order.", true,
  //         duration: 4));
  //   }
  // }
  void _payOrderPayment({otp, paymentId = ""}) async {
    var pId = "";
    if (otp.toString().isNotEmpty) {
      pId = paymentId;
    } else {
      if (!widget.isCourier!) {
        pId = "0";
      }
    }
    if (kifiyaMethod != -1) {
      setState(() {
        _loading = true;
        _placeOrder = true;
      });
      var data = await payOrderPayment(
          otp, paymentResponse['payment_gateway'][kifiyaMethod]['_id']);
      if (data != null && data['success']) {
        widget.isCourier!
            ? _createCourierOrder()
            : (aliexpressCart != null &&
                    aliexpressCart!.cart.storeId == cart.storeId)
                ? _createAliexpressOrder()
                : _createOrder();
      } else {
        setState(() {
          _loading = false;
          _placeOrder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${data['error_code']}']}!", true));
        await Future.delayed(Duration(seconds: 2));
        if (data['error_code'] == 999) {
          await Service.saveBool('logged', false);
          await Service.remove('user');
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Please select a payment method for your order.", true,
          duration: 4));
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
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Payment verification Successfull!", false,
          duration: 2));
      // if (widget.isCourier!) {
      //   _createCourierOrder();
      // } else {
      //   _createOrder();
      // }
      widget.isCourier!
          ? _createCourierOrder()
          : (aliexpressCart != null &&
                  aliexpressCart!.cart.storeId == cart.storeId)
              ? _createAliexpressOrder()
              : _createOrder();
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
        if (widget.onlyCashless!) {
          kifiyaMethod = -1;
        } else {
          kifiyaMethod = 1;
        }
      });
      await useBorsa();
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['error']}! Please complete your payment!", true));
      await Future.delayed(Duration(seconds: 3));
    }
  }

  void _ethSwitchVerify(String traceNo) async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await ethSwitchVerify(traceNo: traceNo);
    if (data != null && data['success']) {
      _boaVerify();
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
        if (widget.onlyCashless!) {
          kifiyaMethod = -1;
        } else {
          kifiyaMethod = 1;
        }
      });
      await useBorsa();
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Payment was not made or verified! If payment is completed please contact support on 8707!",
          true,
          duration: 6));
      await Future.delayed(Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Provider.of<ZLanguage>(context).payments,
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: _loading,
          progressIndicator: linearProgressIndicator,
          color: kPrimaryColor,
          child: paymentResponse != null
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(kDefaultPadding),
                    vertical: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          "${Provider.of<ZLanguage>(context).howWouldYouPay} ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)}?",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                          // Theme.of(context)
                          //     .textTheme
                          //     .titleLarge
                          //     ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        // SizedBox(
                        //     height: getProportionateScreenHeight(
                        //         kDefaultPadding / 2)),
                        // CategoryContainer(
                        //     title: Provider.of<ZLanguage>(context).balance),
                        // SizedBox(
                        //     height: getProportionateScreenHeight(
                        //         kDefaultPadding / 2)),
                        Container(
                          // height:
                          //     getProportionateScreenHeight(kDefaultPadding * 4),
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  getProportionateScreenWidth(kDefaultPadding),
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                          margin: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(
                                color: kBlackColor.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding / 2),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  "${paymentResponse['wallet'].toStringAsFixed(2)} ${Provider.of<ZMetaData>(context, listen: false).currency} ",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  Provider.of<ZLanguage>(context).balance,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: kGreyColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // SizedBox(
                        //     height: getProportionateScreenHeight(
                        //         kDefaultPadding / 2)),
                        Text(Provider.of<ZLanguage>(context).addFundsInfo),
                        SizedBox(
                          height: getProportionateScreenHeight(kDefaultPadding),
                        ),
                        CategoryContainer(
                            title:
                                Provider.of<ZLanguage>(context).selectPayment),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2)),
                        widget.onlyCashless!
                            ? Text(
                                Provider.of<ZLanguage>(context)
                                    .onlyDigitalPayments,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              )
                            : Container(),
                        widget.onlyCashless!
                            ? SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2))
                            : Container(),
                        Expanded(
                          child: GridView.builder(
                            // physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.only(bottom: kDefaultPadding),
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing:
                                  getProportionateScreenWidth(kDefaultPadding),
                              mainAxisSpacing:
                                  getProportionateScreenWidth(kDefaultPadding),
                            ),
                            itemCount:
                                paymentResponse['payment_gateway'].length,
                            itemBuilder: (BuildContext ctx, index) {
                              String paymentName =
                                  paymentResponse['payment_gateway'][index]
                                          ['name']
                                      .toString()
                                      .toLowerCase();
                              return KifiyaMethodContainer(
                                  selected: kifiyaMethod == index,
                                  title: Service.capitalizeFirstLetters(
                                      paymentName),
                                  // .toUpperCase(),
                                  kifiyaMethod: kifiyaMethod,
                                  imagePath: paymentName == "wallet"
                                      ? 'images/wallet.png'
                                      : paymentName == "cash"
                                          ? 'images/cod.png'

                                          ///******************"dashen mastercard"***********************
                                          : paymentName == "dashen mastercard"
                                              ? 'images/dashenmpgs.png'

                                              ///******************Telebirr InApp***********************
                                              // : paymentResponse['payment_gateway']
                                              //                 [index]['name']
                                              //             .toString()
                                              //             .toLowerCase() ==
                                              //         "telebirr inapp"
                                              //     ? 'images/telebirr.png'
                                              ///******************Addis Pay***********************
                                              : paymentName == "addis pay"
                                                  ? 'images/addispay.png'

                                                  ///******************MOMO***********************
                                                  // /* : paymentResponse['payment_gateway']
                                                  //                 [index]['name']
                                                  //             .toString()
                                                  //             .toLowerCase() ==
                                                  //         "momo"
                                                  //     ? 'images/momo.png'
                                                  ///******************MOMO***********************
                                                  : paymentName == "santimpay"
                                                      ? 'images/santim.png'
                                                      : paymentName ==
                                                              "etta card"
                                                          ? 'images/dashen.png'
                                                          : paymentName ==
                                                                  "cbe birr"
                                                              ? 'images/cbebirr.png'
                                                              : paymentName ==
                                                                      "ethswitch"
                                                                  ? 'images/ethswitch.png'
                                                                  : paymentName ==
                                                                          "chapa"
                                                                      ? 'images/chapa.png'
                                                                      : paymentName ==
                                                                              "amole"
                                                                          ? 'images/amole.png'
                                                                          : paymentName == "boa"
                                                                              ? 'images/boa.png'
                                                                              : paymentName == "zemen"
                                                                                  ? 'images/zemen.png'
                                                                                  : paymentName == "awash"
                                                                                      ? 'images/awash.png'
                                                                                      : paymentName == "etta card"
                                                                                          ? 'images/zmall.jpg'
                                                                                          : paymentName == "dashen"
                                                                                              ? 'images/dashen.png'
                                                                                              : paymentName.contains("telebirr") || paymentName.contains("tele birr")
                                                                                                  ? 'images/telebirr.png'
                                                                                                  : '',
                                  // 'images/telebirr.png',

                                  press: () async {
                                    setState(() {
                                      kifiyaMethod = index;
                                    });
                                    if (paymentName == "cash") {
                                      if (widget.onlyCashless!) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                            Provider.of<ZLanguage>(context,
                                                    listen: false)
                                                .onlyDigitalPayments,
                                            false,
                                            duration: 5,
                                          ),
                                        );
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      } else {
                                        await useBorsa();
                                      }
                                    } else if (paymentName == "wallet") {
                                      if (widget.onlyCashless! &&
                                          paymentResponse != null &&
                                          paymentResponse['wallet'] <
                                              widget.price) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          Service.showMessage(
                                            "Only digital payment accepted and your balance is insufficient!",
                                            false,
                                            duration: 5,
                                          ),
                                        );
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      } else {
                                        await useBorsa();
                                      }
                                    } else if (paymentName ==
                                        "telebirr reference") {
                                      var data = await useBorsa();
                                      if (data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (dialogContext) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using Telebirr App"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Telebirr App?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return KifiyaVerification(
                                                              hisab:
                                                                  widget.price!,
                                                              traceNo: widget
                                                                  .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                            );
                                                          },
                                                        ),
                                                      ).then((success) {
                                                        if (success != null ||
                                                            !success) {
                                                          if (mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(Service
                                                                    .showMessage(
                                                                        "Payment not completed. Please choose your payment method.",
                                                                        true));
                                                          }
                                                        } else {
                                                          /////////old/////
                                                          // if (widget.isCourier!) {
                                                          //   _createCourierOrder();
                                                          // } else {
                                                          //   _createOrder();
                                                          // }
                                                          /////////old/////
                                                          if (widget
                                                              .isCourier!) {
                                                            _createCourierOrder();
                                                          } else if ((aliexpressCart !=
                                                                  null &&
                                                              aliexpressCart!
                                                                      .cart
                                                                      .storeId ==
                                                                  cart.storeId)) {
                                                            _createAliexpressOrder();
                                                          } else {
                                                            _createOrder();
                                                          }
                                                        }
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      }
                                    } else if (paymentName == "boa") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        setState(() {
                                          uuid =
                                              (int.parse(uuid) + 1).toString();
                                        });

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CyberSource(
                                              url:
                                                  "https://pgw.shekla.app/cards/process?total=${widget.price}&stotal=${widget.price}&tax=0&shiping=0&order_id=${uuid}_${widget.orderPaymentUniqueId}&first=${userData['user']['first_name']}&last=${userData['user']['last_name']}&phone=251${userData['user']['phone']}&email=${userData['user']['email']}&appId=1234",
                                            ),
                                          ),
                                        ).then((value) {
                                          _boaVerify();
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                      }
                                    } else if (paymentName == "amole") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) {
                                            return AmoleScreen(
                                              hisab: widget.price!,
                                              userData: userData,
                                            );
                                          }),
                                        ).then((value) {
                                          if (value != null) {
                                            _payOrderPayment(
                                                otp: value,
                                                paymentId: paymentResponse[
                                                        'payment_gateway']
                                                    [index]['_id']);
                                          }
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    } else if (paymentName == "ethswitch") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title:
                                                    Text("Pay Using EthSwitch"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using EthSwitch?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        uuid =
                                                            (int.parse(uuid) +
                                                                    1)
                                                                .toString();
                                                      });
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return EthSwitchScreen(
                                                              title:
                                                                  "EthSwitch Payment Gateway",
                                                              url:
                                                                  "https://pgw.shekla.app/ethioSwitch/initiate",
                                                              hisab:
                                                                  widget.price!,
                                                              traceNo: uuid +
                                                                  '_' +
                                                                  widget
                                                                      .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _ethSwitchVerify(uuid +
                                                            '_' +
                                                            widget
                                                                .orderPaymentUniqueId!);
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    } else if (paymentName == "etta card") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using Loyalty Card"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using ETTA Loyalty Card?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        uuid =
                                                            (int.parse(uuid) +
                                                                    1)
                                                                .toString();
                                                      });
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return EttaCardScreen(
                                                              url:
                                                                  "$BASE_URL/admin/pay_payment_ettacard",
                                                              amount:
                                                                  widget.price!,
                                                              traceNo: uuid +
                                                                  '_' +
                                                                  widget
                                                                      .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    } else if (paymentName == "santimpay") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title:
                                                    Text("Pay Using SantimPay"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using SantimPay?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        uuid =
                                                            (int.parse(uuid) +
                                                                    1)
                                                                .toString();
                                                      });
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return SantimPay(
                                                              title:
                                                                  "SantimPay Payment Gateway",
                                                              url:
                                                                  "$BASE_URL/api/santimpay/generatepaymenturl",
                                                              hisab:
                                                                  widget.price!,
                                                              traceNo: uuid +
                                                                  '_' +
                                                                  widget
                                                                      .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    } else if (paymentName == "chapa") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text("Pay Using Chapa"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Chapa?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        uuid =
                                                            (int.parse(uuid) +
                                                                    1)
                                                                .toString();
                                                      });
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return ChapaScreen(
                                                              title:
                                                                  "Chapa Payment Gateway",
                                                              url:
                                                                  "$BASE_URL/api/chapa/generatepaymenturl",
                                                              hisab:
                                                                  widget.price!,
                                                              traceNo: uuid +
                                                                  '_' +
                                                                  widget
                                                                      .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    } else if (paymentName == "cbe birr") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title:
                                                    Text("Pay Using CBE Birr"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using CBE Birr?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();

                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return CbeUssd(
                                                              userId: userData[
                                                                      'user']
                                                                  ['_id'],
                                                              serverToken: userData[
                                                                      'user'][
                                                                  'server_token'],
                                                              url:
                                                                  "https://pgw.shekla.app/cbe/ussd/request",
                                                              hisab:
                                                                  widget.price!,
                                                              traceNo: widget
                                                                  .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    } else if (paymentName == "tele birr") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (dialogContext) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using TeleBirr USSD"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Telebirr?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      var uniqueId =
                                                          RandomDigits
                                                              .getString(6);
                                                      String uniqueIdString =
                                                          '';
                                                      Navigator.of(context)
                                                          .pop();

                                                      setState(() {
                                                        uniqueIdString =
                                                            uniqueId;
                                                      });

                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return TelebirrUssd(
                                                              userId: userData[
                                                                      'user']
                                                                  ['_id'],
                                                              serverToken: userData[
                                                                      'user'][
                                                                  'server_token'],
                                                              url:
                                                                  "http://196.189.44.60:8069/telebirr/ussd/send_sms", // New configuration
                                                              // "https://pgw.shekla.app/telebirr/ussd/send_sms",

                                                              hisab:
                                                                  widget.price!,
                                                              traceNo:
                                                                  "${uniqueIdString}_${widget.orderPaymentUniqueId!}",
                                                              // widget.orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    }

                                    ///**************************Dashen mastercard***************************************
                                    else if (paymentName ==
                                        "dashen mastercard") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using Mastercard"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Dashen Mastercard?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return DashenMasterCard(
                                                                url:
                                                                    "https://pgw.shekla.app/dashenMpgs/mastercard/api/checkout",
                                                                amount: widget
                                                                    .price!,
                                                                phone: userData[
                                                                        'user']
                                                                    ['phone'],
                                                                traceNo: widget
                                                                    .orderPaymentUniqueId!,
                                                                orderPaymentId:
                                                                    widget
                                                                        .orderPaymentId!,
                                                                currency: Provider.of<
                                                                            ZMetaData>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .currency);
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    }

                                    ///*******************************Dashen mastercard*******************************
                                    ///
                                    ///
                                    ///**************************Telebirr InApp***************************************

                                    else if (paymentName == "telebirr inapp") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (dialogContext) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using Telebirr App"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Telebirr InApp?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                      Navigator.push(context,
                                                          MaterialPageRoute(
                                                        builder: (context) {
                                                          return TelebirrInApp(
                                                            amount:
                                                                widget.price!,
                                                            context: context,
                                                            traceNo: widget
                                                                .orderPaymentUniqueId!,
                                                            phone:
                                                                userData['user']
                                                                    ['phone'],
                                                          );
                                                        },
                                                      )).then((value) {
                                                        // debugPrint("Value: $value");
                                                        if (value != null &&
                                                            value == true) {
                                                          // debugPrint( "Payment Successful>>>");
                                                          widget.isCourier!
                                                              ? _createCourierOrder()
                                                              : (aliexpressCart !=
                                                                          null &&
                                                                      aliexpressCart!
                                                                              .cart
                                                                              .storeId ==
                                                                          cart.storeId)
                                                                  ? _createAliexpressOrder()
                                                                  : _createOrder();
                                                        } else {
                                                          Future.delayed(
                                                              Duration(
                                                                  milliseconds:
                                                                      100), () {
                                                            if (mounted) {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      Service.showMessage(
                                                                          "Payment not completed. Please choose your payment method.",
                                                                          true));
                                                            }
                                                          });
                                                        }
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    }

                                    ///*******************************Telebirr InApp*******************************
                                    ///
                                    ///
                                    ///*******************************Addis Pay*******************************
                                    else if (paymentName == "addis pay") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title:
                                                    Text("Pay Using AddisPay"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Addis Pay?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      var uniqueId =
                                                          RandomDigits
                                                              .getString(6);
                                                      String uniqueIdString =
                                                          '';
                                                      Navigator.of(context)
                                                          .pop();

                                                      setState(() {
                                                        uniqueIdString =
                                                            uniqueId;
                                                      });
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return AddisPay(
                                                              url:
                                                                  "https://pgw.shekla.app/addispay/api/checkout",
                                                              amount:
                                                                  widget.price!,
                                                              traceNo:
                                                                  "${widget.orderPaymentUniqueId!}_${uniqueIdString}",
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              firstName: userData[
                                                                      'user'][
                                                                  "first_name"],
                                                              lastName: userData[
                                                                      'user']
                                                                  ["last_name"],
                                                              email: userData[
                                                                      'user']
                                                                  ["email"],
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    }

                                    ///*******************************Addis Pay*******************************
                                    ///
                                    ///
                                    ///**************************MoMo***************************************

                                    //    else if (paymentResponse['payment_gateway']
                                    //               [index]['name']
                                    //           .toString()
                                    //           .toLowerCase() ==
                                    //       "momo") {
                                    //     var data = await useBorsa();
                                    //     if (data != null && data['success']) {
                                    //       showDialog(
                                    //           context: context,
                                    //           builder: (context) {
                                    //             return AlertDialog(
                                    //               title: Text("Pay Using MoMo"),
                                    //               content: Text(
                                    //                   "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using MoMo?"),
                                    //               actions: [
                                    //                 TextButton(
                                    //                   child: Text(
                                    //                     Provider.of<ZLanguage>(
                                    //                             context)
                                    //                         .cancel,
                                    //                     style: TextStyle(
                                    //                         color: kSecondaryColor),
                                    //                   ),
                                    //                   onPressed: () {
                                    //                     Navigator.of(context).pop();
                                    //                   },
                                    //                 ),
                                    //                 TextButton(
                                    //                   child: Text(
                                    //                     Provider.of<ZLanguage>(
                                    //                             context)
                                    //                         .cont,
                                    //                     style: TextStyle(
                                    //                         color: kBlackColor),
                                    //                   ),
                                    //                   onPressed: () {
                                    //                     Navigator.of(context).pop();
                                    //                     Navigator.push(
                                    //                       context,
                                    //                       MaterialPageRoute(
                                    //                         builder: (context) {
                                    //                           return MoMoUssd(
                                    //                             userId:
                                    //                                 userData['user']
                                    //                                     ['_id'],
                                    //                             serverToken: userData[
                                    //                                     'user'][
                                    //                                 'server_token'],
                                    //                             url:
                                    //                                 'https://pgw.shekla.app/momo/makepayment',
                                    //                             hisab:
                                    //                                 widget.price!,
                                    //                             traceNo: widget
                                    //                                 .orderPaymentUniqueId!,
                                    //                             phone:
                                    //                                 userData['user']
                                    //                                     ['phone'],
                                    //                             orderPaymentId: widget
                                    //                                 .orderPaymentId!,
                                    //                           );
                                    //                         },
                                    //                       ),
                                    //                     ).then((value) {
                                    //                       _boaVerify();
                                    //                     });
                                    //                   },
                                    //                 )
                                    //               ],
                                    //             );
                                    //           });
                                    //     } else {
                                    //       ScaffoldMessenger.of(context)
                                    //           .showSnackBar(Service.showMessage(
                                    //               "Something went wrong! Please try again!",
                                    //               true));
                                    //       setState(() {
                                    //         kifiyaMethod = -1;
                                    //       });
                                    //     }
                                    //   }

                                    ///*******************************MoMo*******************************

                                    else if (paymentName == "zemen") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using International Card"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using International Card?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        uuid =
                                                            (int.parse(uuid) +
                                                                    1)
                                                                .toString();
                                                      });
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return Telebirr(
                                                              url:
                                                                  "https://pgw.shekla.app/zemen/post_bill",
                                                              hisab:
                                                                  widget.price!,
                                                              traceNo: uuid +
                                                                  "_" +
                                                                  widget
                                                                      .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                              title:
                                                                  "Master Card Payment Gateway",
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    } else if (paymentName == "dashen") {
                                      var data = await useBorsa();
                                      if (data != null && data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using International Card"),
                                                content: Text(
                                                    "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using International Card?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cancel,
                                                      style: TextStyle(
                                                          color:
                                                              kSecondaryColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      Provider.of<ZLanguage>(
                                                              context)
                                                          .cont,
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      setState(() {
                                                        uuid =
                                                            (int.parse(uuid) +
                                                                    1)
                                                                .toString();
                                                      });
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return Telebirr(
                                                              url:
                                                                  "https://pgw.shekla.app/dashen/post_bill",
                                                              hisab:
                                                                  widget.price!,
                                                              traceNo: uuid +
                                                                  "_" +
                                                                  widget
                                                                      .orderPaymentUniqueId!,
                                                              phone: userData[
                                                                      'user']
                                                                  ['phone'],
                                                              orderPaymentId: widget
                                                                  .orderPaymentId!,
                                                              title:
                                                                  "Dashen Payment Gateway",
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        _boaVerify();
                                                      });
                                                    },
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                        setState(() {
                                          kifiyaMethod = -1;
                                        });
                                      }
                                    }
                                  });
                            },
                          ),
                        ),
                        // SizedBox(
                        //   height: getProportionateScreenHeight(kDefaultPadding),
                        // ),
                        _placeOrder
                            ? SpinKitWave(
                                color: kSecondaryColor,
                                size: getProportionateScreenWidth(
                                    kDefaultPadding),
                              )
                            : CustomButton(
                                title:
                                    Provider.of<ZLanguage>(context).placeOrder,
                                press: () {
                                  _payOrderPayment(otp: "");
                                },
                                color: kSecondaryColor,
                              )
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
    final deviceType = Platform.isIOS ? "iOS" : "android";
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_payment_gateway";
    Map data = {
      "user_id": userData['user']['_id'],
      "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
      "server_token": userData['user']['server_token'],
      "store_delivery_id": widget.orderPaymentId,
      "is_user_pickup_with_schedule": widget.userpickupWithSchedule,
      "vehicleId": widget.vehicleId,
      "device_type": deviceType
      // "device_type": "android",
      // "device_type": 'iOS',
    };
    var body = json.encode(data);
    // debugdebugPrint("kbody $body");
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
        this.paymentResponse = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> payOrderPayment(otp, paymentId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/pay_order_payment";
    Map data = widget.isCourier!
        ? {
            "user_id": userData['user']['_id'],
            "otp": otp,
            "order_payment_id": widget.orderPaymentId,
            "payment_id": paymentId,
            "order_type": 7,
            "is_payment_mode_cash": kifiyaMethod != -1 &&
                (paymentResponse['payment_gateway'][kifiyaMethod]['name']
                            .toString()
                            .toLowerCase() ==
                        "wallet" ||
                    paymentResponse['payment_gateway'][kifiyaMethod]['name']
                            .toString()
                            .toLowerCase() ==
                        "cash"),
            "server_token": userData['user']['server_token'],
            "store_delivery_id": services['deliveries'][0]['_id'],
          }
        : {
            "user_id": userData['user']['_id'],
            "otp": otp,
            "order_payment_id": widget.orderPaymentId,
            "payment_id": paymentId,
            "is_payment_mode_cash": kifiyaMethod != -1 &&
                (paymentResponse['payment_gateway'][kifiyaMethod]['name']
                            .toString()
                            .toLowerCase() ==
                        "wallet" ||
                    paymentResponse['payment_gateway'][kifiyaMethod]['name']
                            .toString()
                            .toLowerCase() ==
                        "cash"),
            "server_token": userData['user']['server_token'],
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
        Duration(seconds: 40),
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
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong."),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> useBorsa() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/change_user_wallet_status";
    Map data = {
      "user_id": userData['user']['_id'],
      "is_use_wallet": kifiyaMethod != -1 &&
          paymentResponse['payment_gateway'][kifiyaMethod]['name']
                  .toString()
                  .toLowerCase() ==
              "wallet",
      "server_token": userData['user']['server_token']
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
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> sendMaregagecha() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/send_otp";

    Map data = {
      "user_id": userData['user']['_id'],
      "phone": userData['user']['phone'],
      "type": userData['user']['admin_type'],
      "token": userData['user']['server_token'],
      "country_phone_code": userData['user']['country_phone_code']
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
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> amoleAddToBorsa() async {
    setState(() {
      _loading = true;
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
              "Adding fund to wallet...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_wallet_amount";

    Map data = {
      "user_id": userData['user']['_id'],
      "payment_id": paymentResponse['payment_gateway'][0]['_id'],
      "otp": otp,
      "type": userData['user']['admin_type'],
      "server_token": userData['user']['server_token'],
      "wallet": topUpAmount,
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
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> createCourierOrder() async {
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
              "Creating courier order...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/create_order";
    var postUri = Uri.parse(url);
    try {
      http.MultipartRequest request = new http.MultipartRequest("POST", postUri)
        ..fields['user_id'] = userData['user']['_id']
        ..fields['server_token'] = userData['user']['server_token']
        ..fields['cart_id'] = courierCart['cart_id']
        ..fields['delivery_type'] = "2"
        ..fields['paid_by'] = paidBySender ? "1" : "2"
        ..fields['is_schedule_order'] = isCourierSchedule ? "true" : "false"
        ..fields['schedule_order_start_at'] =
            isCourierSchedule ? courierScheduleDate : ""
        ..fields['vehicle_id'] = widget.vehicleId!;
      if (imagePath != null && imagePath.length > 0) {
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
                  "Uploading image...",
                  style: TextStyle(color: kBlackColor),
                ),
              ],
            ),
          );
        });
        for (var i = 0; i < imagePath.length; i++) {
          http.MultipartFile multipartFile =
              await http.MultipartFile.fromPath('file', imagePath[i]);
          request.files.add(multipartFile);
        }
      }
      await request.send().then((response) async {
        http.Response.fromStream(response).then((value) async {
          var data = json.decode(value.body);
          if (data != null && data['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
                Service.showMessage("Order successfully created", false));
            await Service.remove("images");
            setState(() {
              _loading = false;
              _placeOrder = false;
            });
            Navigator.pushReplacementNamed(context, "/report");
          } else {
            setState(() {
              _loading = false;
              _placeOrder = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
                "${errorCodes['${data['error_code']}']}!", true));
            await Future.delayed(Duration(seconds: 2));
            if (data['error_code'] == 999) {
              await Service.saveBool('logged', false);
              await Service.remove('user');
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            }
          }
          return json.decode(value.body);
        });
      }).timeout(Duration(seconds: 40), onTimeout: () {
        setState(() {
          _loading = false;
          this._placeOrder = false;
        });
        throw TimeoutException("The connection has timed out!");
      });
    } catch (e) {
      setState(() {
        this._loading = false;
        this._placeOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> createAliexpressOrder() async {
    // debugPrint("in createAliexpressOrder>>>");
    var aliOrderResponse;
    var mobile_no =
        cart.phone.isNotEmpty ? cart.phone : "${userData['user']['phone']}";
    var full_name = cart.userName.isNotEmpty
        ? cart.userName
        : "${userData['user']['first_name']} ${userData['user']['last_name']}";

    // Extract cart and product details from AliExpressCart
    Cart alicart = aliexpressCart!.cart;
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
          }
        });
      }
      // else {debugPrint("Index $index out of range for productIds or itemIds");}
    });
    // debugPrint("productItems>>> $productItems");
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
              "Creating order...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
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
            "Accept": "application/json"
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
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
            "Failed to create aliexpress order, please check your internet and try again",
            true,
          ),
        );
        return null;
      }
    }
  }

  Future<dynamic> createOrder({List<dynamic>? orderIds}) async {
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
              "Creating order...",
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/create_order";
    try {
      List<dynamic>? filteredOrderIds;
      if (aliexpressCart != null &&
          aliexpressCart!.cart.storeId == cart.storeId) {
        filteredOrderIds = orderIds; // Pass the orderIds
      }
      Map data = {
        "user_id": userData['user']['_id'],
        "cart_id": userData['user']['cart_id'],
        "is_schedule_order": cart.isSchedule != null ? cart.isSchedule : false,
        "schedule_order_start_at": cart.scheduleStart != null &&
                cart.isSchedule != null &&
                cart.isSchedule
            ? cart.scheduleStart?.toUtc().toString()
            : "",
        "server_token": userData['user']['server_token'],
        if (filteredOrderIds != null) "aliexpress_order_ids": filteredOrderIds,
      };
      var body = json.encode(data);
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
        Duration(seconds: 50),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        orderResponse = json.decode(response.body);
      });
      // debugPrint("orderResponse>>> $orderResponse");
      return orderResponse;
    } catch (e) {
      // debugPrint("orderResponse Error>>> $e");
      setState(() {
        this._loading = false;
        this._placeOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage(
          "Failed to create order, please check your internet and try again",
          true,
        ),
      );
      return null;
    }
  }
  ////old createOrder(): which is before aliexpress integration
  // Future<dynamic> createOrder() async {
  //   setState(() {
  //     linearProgressIndicator = Container(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           SpinKitWave(
  //             color: kSecondaryColor,
  //             size: getProportionateScreenWidth(kDefaultPadding),
  //           ),
  //           SizedBox(height: kDefaultPadding * 0.5),
  //           Text(
  //             "Creating order...",
  //             style: TextStyle(color: kBlackColor),
  //           ),
  //         ],
  //       ),
  //     );
  //   });
  //   var url =
  //       "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/create_order";
  //   try {
  //     Map data = {
  //       "user_id": userData['user']['_id'],
  //       "cart_id": userData['user']['cart_id'],
  //       "is_schedule_order": cart.isSchedule != null ? cart.isSchedule : false,
  //       "schedule_order_start_at": cart.scheduleStart != null &&
  //               cart.isSchedule != null &&
  //               cart.isSchedule
  //           ? cart.scheduleStart?.toUtc().toString()
  //           : "",
  //       "server_token": userData['user']['server_token'],
  //     };
  //     var body = json.encode(data);
  //     http.Response response;
  //     response = await http
  //         .post(
  //       Uri.parse(url),
  //       headers: <String, String>{
  //         "Content-Type": "application/json",
  //         "Accept": "application/json"
  //       },
  //       body: body,
  //     )
  //         .timeout(
  //       Duration(seconds: 50),
  //       onTimeout: () {
  //         setState(() {
  //           this._loading = false;
  //         });
  //         throw TimeoutException("The connection has timed out!");
  //       },
  //     );
  //     setState(() {
  //       orderResponse = json.decode(response.body);
  //     });

  //     return orderResponse;
  //   } catch (e) {
  //     setState(() {
  //       this._loading = false;
  //       this._placeOrder = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       Service.showMessage(
  //         "Failed to create order, please check your internet and try again",
  //         true,
  //       ),
  //     );
  //     return null;
  //   }
  // }
//////////////
  Future<dynamic> userDetails() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_detail";
    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
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
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
          setState(() {
            _loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  Future<dynamic> boaVerify({String title = "Verifying payment..."}) async {
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
              title,
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";
    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
      "order_payment_id": widget.orderPaymentId
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
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Failed to verify payment. Check you internet and try again", true,
          duration: 4));
      return null;
    }
  }

  Future<dynamic> ethSwitchVerify(
      {String title = "Verifying payment...", required String traceNo}) async {
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
              title,
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/pay_payment_etswitch";
    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
      "trace_no": traceNo
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
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Failed to verify payment. Check you internet and try again", true,
          duration: 4));
      return null;
    }
  }
}
