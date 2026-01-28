// ignore_for_file: deprecated_member_use, unused_element

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/kifiya/components/starpay_screen.dart';
import 'package:zmall/utils/constants.dart';
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
import 'package:zmall/kifiya/components/yagoutpay.dart';
import 'package:zmall/kifiya/kifiya_verification.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/widgets/order_status_row.dart';
import 'package:zmall/utils/random_digits.dart';
import 'package:zmall/report/report_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
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

    // _loadPackageInfo();
    getUser();
    if (widget.onlyCashless != null && widget.onlyCashless == true) {
      kifiyaMethod = -1;
    }
    uuid = widget.orderPaymentUniqueId!;
  }

  // Future<void> _loadPackageInfo() async {
  //   final packageInfo = await PackageInfo.fromPlatform();
  //   setState(() {
  //     _appVersion = packageInfo.version;
  //     // _buildNumber = packageInfo.buildNumber;
  //   });
  // }

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
    if (widget.isCourier != null && widget.isCourier == true) {
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
        debugPrint("courierCart CART>>> ${courierCart!}");
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
    debugPrint("image path  in kifiya $data");
    if (data != null) {
      setState(() {
        imagePath = data;
      });
    }
  }

  void getCourierSchedule() async {
    var data = await Service.readBool('is_schedule');
    debugPrint("getCourierSchedule  in kifiya $data");
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

  /// SECURITY FIX: Validates that all courier images exist before payment
  /// Returns true if validation passes, false if any image is missing
  /// This prevents payment from being processed when images will fail to upload
  Future<bool> _validateCourierImagesBeforePayment() async {
    // Skip validation for non-courier orders
    if (widget.isCourier != true) {
      return true;
    }

    // If no images attached, validation passes (images are optional)
    if (imagePath == null || imagePath.length == 0) {
      return true;
    }

    List<String> invalidPaths = [];
    
    for (var path in imagePath) {
      File imageFile = File(path);
      if (!await imageFile.exists()) {
        invalidPaths.add(path);
      }
    }

    if (invalidPaths.isNotEmpty) {
      // Clear invalid images from storage
      await Service.remove('images');
      
      // Show user-friendly error
      Service.showMessage(
        context: context,
        title: "Some images are missing or deleted. Please go back to the vehicle selection screen and re-select your images.",
        error: true,
        duration: 5,
      );
      
      return false;
    }

    return true;
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
      Service.showMessage(
        context: context,
        title: "Order successfully created",
        error: true,
      );
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
  //       Service.showMessage(  context: context,
  // title:
  //           "${errorCodes['${data['error_code']}']}!", true));
  //       await Future.delayed(Duration(seconds: 2));
  //       if (data['error_code'] == 999) {
  //         await Service.saveBool('logged', false);
  //         await Service.remove('user');
  //         Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  //       }
  //     }
  //   } else {
  //     Service.showMessage(  context: context,
  // title:
  //         "Please select a payment method for your order.", true,
  //         duration: 4));
  //   }
  // }
  void _payOrderPayment({otp, paymentId = ""}) async {
    // SECURITY FIX: Validate images exist BEFORE processing payment
    // This prevents payment deduction when image upload will fail
    bool imagesValid = await _validateCourierImagesBeforePayment();
    if (!imagesValid) {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      return; // Stop payment - images are invalid
    }

    var pId = "";
    if (otp.toString().isNotEmpty) {
      pId = paymentId;
    } else {
      if (widget.isCourier != null && widget.isCourier == false) {
        pId = "0";
      }
    }
    if (kifiyaMethod != -1) {
      setState(() {
        _loading = true;
        _placeOrder = true;
      });
      var data = await payOrderPayment(
        otp,
        paymentResponse['payment_gateway'][kifiyaMethod]['_id'],
      );
      // debugPrint("payOrderPayment>>>$data");
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
        Service.showMessage(
          context: context,
          title: "${errorCodes['${data['error_code']}']}!",
          error: true,
        );
        await Future.delayed(Duration(seconds: 2));
        if (data['error_code'] == 999) {
          await Service.saveBool('logged', false);
          await Service.remove('user');
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      }
    } else {
      Service.showMessage(
        context: context,
        title: "Please select a payment method for your order.",
        error: true,
        duration: 4,
      );
    }
  }

  void _boaVerify() async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await boaVerify();
    if (data != null && data['success']) {
      // SECURITY FIX: Validate images before creating order after payment verification
      bool imagesValid = await _validateCourierImagesBeforePayment();
      if (!imagesValid) {
        setState(() {
          _loading = false;
          _placeOrder = false;
        });
        // Payment was verified but images are invalid - log for potential refund
        Service.showMessage(
          context: context,
          title: "Payment verified but order could not be created due to missing images. Please contact support at 8707 for assistance.",
          error: true,
          duration: 5,
        );
        return;
      }

      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      Service.showMessage(
        context: context,
        title: "Payment verification Successful!",
        error: false,
        duration: 2,
      );
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
      Service.showMessage(
        context: context,
        title: "${data['error']}! Please complete your payment!",
        error: true,
      );
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
      Service.showMessage(
        context: context,
        title:
            "Payment was not made or verified! If payment is completed please contact support on 8707!",
        error: true,
        duration: 6,
      );
      await Future.delayed(Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        // surfaceTintColor: kPrimaryColor,
        title: Text(
          Provider.of<ZLanguage>(context).payments,
          style: TextStyle(color: kBlackColor),
        ),
        // elevation: 1.0,
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
                  ),
                  child: Center(
                    child: Column(
                      // mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(
                              kDefaultPadding,
                            ),
                            horizontal: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                          ),
                          margin: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(
                              kDefaultPadding / 2,
                            ),
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(color: kWhiteColor),
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(
                                kDefaultPadding / 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: OrderStatusRow(
                                  title: "Total Price",
                                  icon: HeroiconsOutline.banknotes,
                                  fontSize: getProportionateScreenHeight(16),
                                  value:
                                      "${widget.price!.toStringAsFixed(2)} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                ),
                              ),
                              Flexible(
                                child: OrderStatusRow(
                                  icon: HeroiconsOutline.creditCard,
                                  title: Provider.of<ZLanguage>(
                                    context,
                                  ).balance,
                                  fontSize: getProportionateScreenHeight(16),
                                  value:
                                      "${paymentResponse['wallet'].toStringAsFixed(2)} ${Provider.of<ZMetaData>(context, listen: false).currency} ",
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Text(
                        //   "${Provider.of<ZLanguage>(context).howWouldYouPay} ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)}?",
                        //   style: TextStyle(
                        //       fontSize: 20, fontWeight: FontWeight.w600),
                        //   // Theme.of(context)
                        //   //     .textTheme
                        //   //     .titleLarge
                        //   //     ?.copyWith(fontWeight: FontWeight.w600),
                        //   textAlign: TextAlign.center,
                        // ),
                        // // SizedBox(
                        // //     height: getProportionateScreenHeight(
                        // //         kDefaultPadding / 2)),
                        // // CategoryContainer(
                        // //     title: Provider.of<ZLanguage>(context).balance),
                        // // SizedBox(
                        // //     height: getProportionateScreenHeight(
                        // //         kDefaultPadding / 2)),
                        // Container(
                        //   // height:
                        //   //     getProportionateScreenHeight(kDefaultPadding * 4),
                        //   width: double.infinity,
                        //   padding: EdgeInsets.symmetric(
                        //       horizontal:
                        //           getProportionateScreenWidth(kDefaultPadding),
                        //       vertical: getProportionateScreenHeight(
                        //           kDefaultPadding / 2)),
                        //   margin: EdgeInsets.symmetric(
                        //       vertical: getProportionateScreenHeight(
                        //           kDefaultPadding / 2)),
                        //   decoration: BoxDecoration(
                        //     color: kPrimaryColor,
                        //     border: Border.all(
                        //         color: kBlackColor.withValues(alpha: 0.2)),
                        //     borderRadius: BorderRadius.circular(
                        //       getProportionateScreenWidth(kDefaultPadding / 2),
                        //     ),
                        //   ),
                        //   child: Center(
                        //     child: Column(
                        //       children: [
                        //         Text(
                        //           "${paymentResponse['wallet'].toStringAsFixed(2)} ${Provider.of<ZMetaData>(context, listen: false).currency} ",
                        //           style: Theme.of(context)
                        //               .textTheme
                        //               .titleLarge
                        //               ?.copyWith(fontWeight: FontWeight.w600),
                        //         ),
                        //         Text(
                        //           Provider.of<ZLanguage>(context).balance,
                        //           style: TextStyle(
                        //               fontWeight: FontWeight.w600,
                        //               color: kGreyColor),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(
                        //     height: getProportionateScreenHeight(
                        //         kDefaultPadding / 2)),
                        // Text(
                        //   Provider.of<ZLanguage>(context).addFundsInfo,
                        //   style:
                        //       Theme.of(context).textTheme.bodySmall?.copyWith(
                        //             color: Theme.of(context)
                        //                 .colorScheme
                        //                 .onSurface
                        //                 .withValues(alpha: 0.6),
                        //           ),
                        // ),
                        // SizedBox(
                        //   height: getProportionateScreenHeight(kDefaultPadding),
                        // ),

                        // Show attached images preview for courier orders
                        if (widget.isCourier == true &&
                            imagePath != null &&
                            imagePath.length > 0)
                          Container(
                            margin: EdgeInsets.only(
                              top: getProportionateScreenHeight(
                                kDefaultPadding / 8,
                              ),
                              bottom: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                              horizontal: getProportionateScreenWidth(
                                kDefaultPadding,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF667EEA).withValues(alpha: 0.1),
                              //  kSecondaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(
                                  kDefaultPadding / 2,
                                ),
                              ),
                              border: Border.all(
                                color: kWhiteColor,
                                //  kSecondaryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with icon and count
                                Row(
                                  spacing: getProportionateScreenWidth(
                                    kDefaultPadding / 2,
                                  ),
                                  children: [
                                    Icon(
                                      HeroiconsOutline.paperClip,
                                      color: kBlackColor,
                                      size: getProportionateScreenWidth(
                                        kDefaultPadding,
                                      ),
                                    ),

                                    Text(
                                      "${imagePath.length} image(s) attached",
                                      style: TextStyle(
                                        color: kBlackColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: getProportionateScreenWidth(
                                          kDefaultPadding * 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                                // Image thumbnails preview
                                SizedBox(
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding * 4,
                                  ),
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imagePath.length,
                                    padding: EdgeInsets.only(
                                      right: getProportionateScreenWidth(
                                        kDefaultPadding / 2,
                                      ),
                                    ),
                                    separatorBuilder: (context, index) =>
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                            kDefaultPadding / 3,
                                          ),
                                        ),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width: getProportionateScreenWidth(
                                          kDefaultPadding * 3,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            getProportionateScreenWidth(
                                              kDefaultPadding / 3,
                                            ),
                                          ),
                                          // border: Border.all(
                                          //   color: kGreyColor.withValues(
                                          //     alpha: 0.5,
                                          //   ),
                                          //   width: 1.5,
                                          // ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            getProportionateScreenWidth(
                                              kDefaultPadding / 3,
                                            ),
                                          ),
                                          child: Image.file(
                                            File(imagePath[index]),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              // Show error icon if image can't be loaded
                                              return Container(
                                                color: Color(
                                                  0xFF667EEA,
                                                ).withValues(alpha: 0.1),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      HeroiconsOutline
                                                          .exclamationTriangle,
                                                      color: kSecondaryColor,
                                                      size:
                                                          getProportionateScreenWidth(
                                                            kDefaultPadding *
                                                                1.5,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          getProportionateScreenHeight(
                                                            kDefaultPadding / 4,
                                                          ),
                                                    ),
                                                    Text(
                                                      "Missing",
                                                      style: TextStyle(
                                                        color: kSecondaryColor,
                                                        fontSize:
                                                            getProportionateScreenWidth(
                                                              kDefaultPadding *
                                                                  0.6,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          Provider.of<ZLanguage>(context).selectPayment,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.onlyCashless!)
                          Text(
                            Provider.of<ZLanguage>(context).onlyDigitalPayments,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),

                        ///list of payment methods///
                        Expanded(
                          child: GridView.builder(
                            shrinkWrap: true,
                            itemCount:
                                paymentResponse['payment_gateway'].length,
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                  mainAxisSpacing: getProportionateScreenWidth(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                            itemBuilder: (BuildContext ctx, index) {
                              String paymentName =
                                  paymentResponse['payment_gateway'][index]['name']
                                      .toString()
                                      .toLowerCase();
                              return KifiyaMethodContainer(
                                selected: kifiyaMethod == index,
                                title: paymentName,
                                // .toUpperCase(),
                                kifiyaMethod: kifiyaMethod,
                                imagePath: paymentName == "wallet"
                                    ? 'images/payment/wallet.png'
                                    : paymentName == "cash"
                                    ? 'images/payment/cod.png'
                                    : paymentName == "dashen mastercard"
                                    ? 'images/payment/dashenmpgs.png'
                                    : paymentName == "addis pay"
                                    ? 'images/payment/addispay.png'
                                    : paymentName == "santimpay"
                                    ? 'images/payment/santimpay.png'
                                    : paymentName == "etta card"
                                    ? 'images/payment/dashen.png'
                                    : paymentName == "cbe birr"
                                    ? 'images/payment/cbebirr.png'
                                    : paymentName == "ethswitch"
                                    ? 'images/payment/ethswitch.png'
                                    : paymentName == "chapa"
                                    ? 'images/payment/chapa.png'
                                    : paymentName == "amole"
                                    ? 'images/payment/amole.png'
                                    : paymentName == "boa"
                                    ? 'images/payment/boa.png'
                                    : paymentName == "zemen"
                                    ? 'images/payment/zemen.png'
                                    : paymentName == "awash"
                                    ? 'images/payment/awash.png'
                                    : paymentName == "etta card"
                                    ? 'images/payment/zmall.jpg'
                                    : paymentName == "dashen"
                                    ? 'images/payment/dashen.png'
                                    : paymentName == "yagoutpay"
                                    ? 'images/payment/yagoutpay.png'
                                    : paymentName == "starpay"
                                    ? 'images/payment/starpay.png'
                                    : paymentName.contains("telebirr") ||
                                          paymentName.contains("tele birr")
                                    ? 'images/payment/telebirr.png'
                                    : '',

                                // 'images/payment/telebirr.png',
                                press: () async {
                                  setState(() {
                                    kifiyaMethod = index;
                                  });
                                  if (paymentName == "cash") {
                                    if (widget.onlyCashless!) {
                                      Service.showMessage(
                                        context: context,
                                        title: Provider.of<ZLanguage>(
                                          context,
                                          listen: false,
                                        ).onlyDigitalPayments,
                                        // error: false,
                                        duration: 5,
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
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Only digital payment accepted and your balance is insufficient!",
                                        // error: false,
                                        duration: 5,
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using Telebirr App",
                                            ),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Telebirr App?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return KifiyaVerification(
                                                          hisab: widget.price!,
                                                          traceNo: widget
                                                              .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
                                                        );
                                                      },
                                                    ),
                                                  ).then((success) {
                                                    if (success != null ||
                                                        !success) {
                                                      if (mounted) {
                                                        Service.showMessage(
                                                          context: context,
                                                          title:
                                                              "Payment not completed. Please choose your payment method.",
                                                          error: true,
                                                        );
                                                      }
                                                    } else {
                                                      /////////old/////
                                                      // if (widget.isCourier!) {
                                                      //   _createCourierOrder();
                                                      // } else {
                                                      //   _createOrder();
                                                      // }
                                                      /////////old/////
                                                      if (widget.isCourier!) {
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
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  } else if (paymentName == "boa") {
                                    var data = await useBorsa();
                                    if (data != null && data['success']) {
                                      setState(() {
                                        uuid = (int.parse(uuid) + 1).toString();
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
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Something went wrong! Please try again!",
                                        error: true,
                                      );
                                    }
                                  } else if (paymentName == "amole") {
                                    var data = await useBorsa();
                                    if (data != null && data['success']) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return AmoleScreen(
                                              hisab: widget.price!,
                                              userData: userData,
                                            );
                                          },
                                        ),
                                      ).then((value) {
                                        if (value != null) {
                                          _payOrderPayment(
                                            otp: value,
                                            paymentId:
                                                paymentResponse['payment_gateway'][index]['_id'],
                                          );
                                        }
                                      });
                                    } else {
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Something went wrong! Please try again!",
                                        error: true,
                                      );
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using EthSwitch"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using EthSwitch?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
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
                                                        return EthSwitchScreen(
                                                          title:
                                                              "EthSwitch Payment Gateway",
                                                          url:
                                                              "https://pgw.shekla.app/ethioSwitch/initiate",
                                                          hisab: widget.price!,
                                                          traceNo:
                                                              uuid +
                                                              '_' +
                                                              widget
                                                                  .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
                                                        );
                                                      },
                                                    ),
                                                  ).then((value) {
                                                    _ethSwitchVerify(
                                                      uuid +
                                                          '_' +
                                                          widget
                                                              .orderPaymentUniqueId!,
                                                    );
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using Loyalty Card",
                                            ),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using ETTA Loyalty Card?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
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
                                                        return EttaCardScreen(
                                                          url:
                                                              "$BASE_URL/admin/pay_payment_ettacard",
                                                          amount: widget.price!,
                                                          traceNo:
                                                              uuid +
                                                              '_' +
                                                              widget
                                                                  .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using SantimPay"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using SantimPay?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
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
                                                        return SantimPay(
                                                          title:
                                                              "SantimPay Payment",
                                                          url:
                                                              "$BASE_URL/api/santimpay/generatepaymenturl",
                                                          hisab: widget.price!,
                                                          traceNo:
                                                              uuid +
                                                              '_' +
                                                              widget
                                                                  .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using Chapa"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Chapa?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
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
                                                        return ChapaScreen(
                                                          title:
                                                              "Chapa Payment Gateway",
                                                          url:
                                                              "$BASE_URL/api/chapa/generatepaymenturl",
                                                          hisab: widget.price!,
                                                          traceNo:
                                                              uuid +
                                                              '_' +
                                                              widget
                                                                  .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using CBE Birr"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using CBE Birr?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return CbeUssd(
                                                          userId:
                                                              userData['user']['_id'],
                                                          serverToken:
                                                              userData['user']['server_token'],
                                                          url:
                                                              "https://pgw.shekla.app/cbe/ussd/request",
                                                          hisab: widget.price!,
                                                          traceNo: widget
                                                              .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using TeleBirr USSD",
                                            ),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Telebirr?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  var uniqueId =
                                                      RandomDigits.getString(6);
                                                  String uniqueIdString = '';
                                                  Navigator.of(context).pop();

                                                  setState(() {
                                                    uniqueIdString = uniqueId;
                                                  });

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return TelebirrUssd(
                                                          userId:
                                                              userData['user']['_id'],
                                                          serverToken:
                                                              userData['user']['server_token'],
                                                          url:
                                                              "http://196.189.44.60:8069/telebirr/ussd/send_sms", // New configuration
                                                          // "https://pgw.shekla.app/telebirr/ussd/send_sms",
                                                          hisab: widget.price!,
                                                          traceNo:
                                                              "${uniqueIdString}_${widget.orderPaymentUniqueId!}",
                                                          // widget.orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
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
                                      setState(() {
                                        kifiyaMethod = -1;
                                      });
                                    }
                                  }
                                  ///**************************Dashen mastercard***************************************
                                  else if (paymentName == "dashen mastercard") {
                                    var data = await useBorsa();
                                    if (data != null && data['success']) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using Mastercard"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Dashen Mastercard?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
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
                                                          amount: widget.price!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          traceNo: widget
                                                              .orderPaymentUniqueId!,
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
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
                                      setState(() {
                                        kifiyaMethod = -1;
                                      });
                                    }
                                  }
                                  ///*******************************Dashen mastercard*******************************
                                  ///////////***********************Star Pay*************************************///
                                  else if (paymentName == "starpay") {
                                    var data = await useBorsa();
                                    if (data != null && data['success']) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using StarPay"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using StarPay?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return StarPayScreen(
                                                          url:
                                                              "https://pgw.shekla.app/star_pay/pay/payment",
                                                          amount: widget.price!,
                                                          phone:
                                                              userData['user']['phone'],
                                                          email:
                                                              userData['user']['email'],
                                                          firstName:
                                                              userData['user']['first_name'],
                                                          lastName:
                                                              userData['user']['last_name'],
                                                          traceNo: widget
                                                              .orderPaymentUniqueId!,
                                                          items: cart.items!,
                                                          orderPaymentId: widget
                                                              .orderPaymentId!,
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
                                      setState(() {
                                        kifiyaMethod = -1;
                                      });
                                    }
                                  }
                                  //********************************Star Pay end******************************************///
                                  ///**************************Telebirr InApp***************************************
                                  else if (paymentName == "telebirr inapp") {
                                    var data = await useBorsa();
                                    if (data != null && data['success']) {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using Telebirr App",
                                            ),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Telebirr InApp?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return TelebirrInApp(
                                                          context: context,
                                                          amount: widget.price!,
                                                          traceNo: widget
                                                              .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
                                                        );
                                                      },
                                                    ),
                                                  ).then((value) async {
                                                    // debugPrint( "Value: $value");
                                                    if (value != null) {
                                                      if (value == false) {
                                                        Service.showMessage(
                                                          context: context,
                                                          title:
                                                              "Payment was not completed. Please choose your payment method and try again!.",
                                                          error: true,
                                                        );
                                                      } else if ((value['code'] !=
                                                                  null &&
                                                              value['code'] ==
                                                                  0) ||
                                                          (value['status'] !=
                                                                  null &&
                                                              value['status']
                                                                      .toString()
                                                                      .toLowerCase() ==
                                                                  "success")) {
                                                        // debugPrint( "Payment Successful>>>");
                                                        // SECURITY FIX: Validate images before creating courier order
                                                        if (widget.isCourier!) {
                                                          bool imagesValid = await _validateCourierImagesBeforePayment();
                                                          if (!imagesValid) {
                                                            Service.showMessage(
                                                              context: context,
                                                              title: "Payment successful but images are missing. Please contact support at 8707 for refund assistance.",
                                                              error: true,
                                                              duration: 5,
                                                            );
                                                            return;
                                                          }
                                                          _createCourierOrder();
                                                        } else if (aliexpressCart != null &&
                                                                  aliexpressCart!
                                                                          .cart
                                                                          .storeId ==
                                                                      cart.storeId) {
                                                          _createAliexpressOrder();
                                                        } else {
                                                          _createOrder();
                                                        }
                                                      }
                                                    } else {
                                                      // _boaVerify();
                                                      Future.delayed(
                                                        Duration(
                                                          milliseconds: 100,
                                                        ),
                                                        () {
                                                          if (mounted) {
                                                            Service.showMessage(
                                                              context: context,
                                                              title:
                                                                  "Payment was not completed. Please choose your payment method and try again!.",
                                                              error: true,
                                                            );
                                                          }
                                                        },
                                                      );
                                                    }
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using AddisPay"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using Addis Pay?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  var uniqueId =
                                                      RandomDigits.getString(6);
                                                  String uniqueIdString = '';
                                                  Navigator.of(context).pop();

                                                  setState(() {
                                                    uniqueIdString = uniqueId;
                                                  });
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return AddisPay(
                                                          url:
                                                              "https://pgw.shekla.app/addispay/api/checkout",
                                                          amount: widget.price!,
                                                          traceNo:
                                                              "${widget.orderPaymentUniqueId!}_${uniqueIdString}",
                                                          phone:
                                                              userData['user']['phone'],
                                                          firstName:
                                                              userData['user']["first_name"],
                                                          lastName:
                                                              userData['user']["last_name"],
                                                          email:
                                                              userData['user']["email"],
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
                                      setState(() {
                                        kifiyaMethod = -1;
                                      });
                                    }
                                  }
                                  ///*******************************Addis Pay*******************************
                                  ///
                                  ///
                                  //////
                                  ///*******************************Yagout Pay*******************************
                                  else if (paymentResponse['payment_gateway'][index]['name']
                                          .toString()
                                          .toLowerCase() ==
                                      "yagoutpay") {
                                    var data = await useBorsa();
                                    if (data != null && data['success']) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: kPrimaryColor,
                                            title: Text("Pay Using YagoutPay"),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using YagoutPay?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  var uniqueId =
                                                      RandomDigits.getString(6);
                                                  String uniqueIdString = '';
                                                  Navigator.of(context).pop();

                                                  setState(() {
                                                    uniqueIdString = uniqueId;
                                                  });
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return YagoutPay(
                                                          url:
                                                              "https://pgw.shekla.app/yagout/payment_link",
                                                          amount: widget.price!,
                                                          traceNo:
                                                              "${widget.orderPaymentUniqueId!}_${uniqueIdString}",
                                                          phone:
                                                              userData['user']['phone'],
                                                          firstName:
                                                              userData['user']["first_name"],
                                                          lastName:
                                                              userData['user']["last_name"],
                                                          email:
                                                              userData['user']["email"],
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
                                      setState(() {
                                        kifiyaMethod = -1;
                                      });
                                    }
                                  }
                                  //////////////////////////////// Yagout Pay ///////////////////////////////////////
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
                                  //             return AlertDialog(  backgroundColor: kPrimaryColor,
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
                                  //           .showSnackBar(Service.showMessage1(
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using International Card",
                                            ),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using International Card?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
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
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
                                                  style: TextStyle(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
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
                                                          url:
                                                              "https://pgw.shekla.app/zemen/post_bill",
                                                          hisab: widget.price!,
                                                          traceNo:
                                                              uuid +
                                                              "_" +
                                                              widget
                                                                  .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
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
                                            backgroundColor: kPrimaryColor,
                                            title: Text(
                                              "Pay Using International Card",
                                            ),
                                            content: Text(
                                              "Proceed to pay ${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.price!.toStringAsFixed(2)} using International Card?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cancel,
                                                  style: TextStyle(
                                                    color: kSecondaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  Provider.of<ZLanguage>(
                                                    context,
                                                  ).cont,
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
                                                          url:
                                                              "https://pgw.shekla.app/dashen/post_bill",
                                                          hisab: widget.price!,
                                                          traceNo:
                                                              uuid +
                                                              "_" +
                                                              widget
                                                                  .orderPaymentUniqueId!,
                                                          phone:
                                                              userData['user']['phone'],
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
                                      setState(() {
                                        kifiyaMethod = -1;
                                      });
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        // SizedBox(
                        //   height: getProportionateScreenHeight(kDefaultPadding),
                        // ),
                      ],
                    ),
                  ),
                )
              : Container(),
        ),
      ),
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
              topRight: Radius.circular(kDefaultPadding),
            ),
          ),

          child: CustomButton(
            isLoading: paymentResponse != null && _placeOrder,
            title: Provider.of<ZLanguage>(context).placeOrder,
            press: () {
              _payOrderPayment(otp: "");
            },
            color: kSecondaryColor,
          ),
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
      "device_type": deviceType,
      "app_version": appVersion,
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

      return json.decode(response.body);
    } catch (e) {
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
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/pay_order_payment";
    Map data = widget.isCourier!
        ? {
            "user_id": userData['user']['_id'],
            "otp": otp,
            "order_payment_id": widget.orderPaymentId,
            "payment_id": paymentId,
            "order_type": 7,
            "is_payment_mode_cash":
                kifiyaMethod != -1 &&
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
            "is_payment_mode_cash":
                kifiyaMethod != -1 &&
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
              "Accept": "application/json",
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
      "is_use_wallet":
          kifiyaMethod != -1 &&
          paymentResponse['payment_gateway'][kifiyaMethod]['name']
                  .toString()
                  .toLowerCase() ==
              "wallet",
      "server_token": userData['user']['server_token'],
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
      "country_phone_code": userData['user']['country_phone_code'],
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

  /// SECURITY: Log failed order after successful payment for support team to process refund
  Future<void> _logFailedOrderAfterPayment({
    required String reason,
    required String paymentId,
    required double amount,
  }) async {
    try {
      // Store failed order info locally for user reference
      Map<String, dynamic> failedOrder = {
        'timestamp': DateTime.now().toIso8601String(),
        'order_payment_id': widget.orderPaymentId,
        'order_payment_unique_id': widget.orderPaymentUniqueId,
        'amount': amount,
        'user_id': userData['user']['_id'],
        'user_phone': userData['user']['phone'],
        'reason': reason,
        'payment_id': paymentId,
        'is_courier': true,
      };
      
      // Store in local storage for user to reference when contacting support
      List<dynamic> failedOrders = await Service.read('failed_orders') ?? [];
      failedOrders.add(failedOrder);
      await Service.save('failed_orders', failedOrders);
      
      // Try to notify backend about the failed order (best effort)
      try {
        var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/log_failed_order";
        await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: json.encode(failedOrder),
        ).timeout(Duration(seconds: 5));
      } catch (_) {
        // Silent fail - local log is primary
      }
      
      debugPrint("SECURITY: Logged failed order after payment - ID: ${widget.orderPaymentId}, Amount: $amount, Reason: $reason");
    } catch (e) {
      debugPrint("Error logging failed order: $e");
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
        ..fields['schedule_order_start_at'] = isCourierSchedule
            ? courierScheduleDate
            : ""
        ..fields['vehicle_id'] = widget.vehicleId!;
      if (imagePath != null && imagePath.length > 0) {
        // Validate files exist before showing upload UI
        List<String> validPaths = [];
        List<String> invalidPaths = [];

        for (var path in imagePath) {
          File imageFile = File(path);
          if (await imageFile.exists()) {
            validPaths.add(path);
          } else {
            invalidPaths.add(path);
          }
        }

        // If some files are missing, alert user and stop
        if (invalidPaths.length > 0) {
          setState(() {
            _loading = false;
            _placeOrder = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Some images are missing or deleted. Please go back and select images again.",
                style: TextStyle(color: kPrimaryColor),
              ),
              backgroundColor: kSecondaryColor,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: "OK",
                textColor: kPrimaryColor,
                onPressed: () {},
              ),
            ),
          );

          return null;
        }

        // Only show "Uploading..." if we have valid files
        if (validPaths.length > 0) {
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
                    "Uploading ${validPaths.length} image(s)...",
                    style: TextStyle(color: kBlackColor),
                  ),
                ],
              ),
            );
          });

          for (var i = 0; i < validPaths.length; i++) {
            http.MultipartFile multipartFile =
                await http.MultipartFile.fromPath('file', validPaths[i]);
            request.files.add(multipartFile);
            // print("current multipartFile $multipartFile");
          }
        }
      }
      await request
          .send()
          .then((response) async {
            http.Response.fromStream(response).then((value) async {
              var data = json.decode(value.body);
              if (data != null && data['success']) {
                // print("after send reps>>> $data");
                Service.showMessage(
                  context: context,
                  title: "Order successfully created",
                  error: false,
                );
                await Service.remove("images");
                setState(() {
                  _loading = false;
                  _placeOrder = false;
                });
                // Navigate to report screen with isCourier flag for proper back navigation
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      price: widget.price,
                      orderPaymentUniqueId: widget.orderPaymentUniqueId,
                      isCourier: true,
                    ),
                  ),
                );
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
                print("else error>>> ${data['error_code']}");
                
                // SECURITY: Log failed order when API returns error
                await _logFailedOrderAfterPayment(
                  reason: "API error: ${data['error_code']} - ${errorCodes['${data['error_code']}']}",
                  paymentId: kifiyaMethod != -1 
                      ? paymentResponse['payment_gateway'][kifiyaMethod]['_id'] ?? ''
                      : '',
                  amount: widget.price ?? 0.0,
                );
                
                await Future.delayed(Duration(seconds: 2));
                if (data['error_code'] == 999) {
                  await Service.saveBool('logged', false);
                  await Service.remove('user');
                  Navigator.pushReplacementNamed(
                    context,
                    LoginScreen.routeName,
                  );
                } else {
                  // Show support message for non-auth errors
                  Service.showMessage(
                    context: context,
                    title: "If payment was deducted, contact support at 8707. Ref: ${widget.orderPaymentUniqueId}",
                    error: true,
                    duration: 8,
                  );
                }
              }
              return json.decode(value.body);
            });
          })
          .timeout(
            Duration(seconds: 40),
            onTimeout: () {
              setState(() {
                _loading = false;
                this._placeOrder = false;
              });
              throw TimeoutException("The connection has timed out!");
            },
          );
    } catch (e) {
      print("catch error>>> $e");

      String errorMessage =
          "Something went wrong. Please check your internet connection!";
      bool clearImages = false;

      // Detect file-related errors
      if (e.toString().contains('FileSystemException') ||
          e.toString().contains('No such file') ||
          e.toString().contains('Cannot open file')) {
        errorMessage =
            "Image upload failed. Some images may be missing. "
            "Please go back and re-select your images, then try again.";
        clearImages = true;
      } else if (e is TimeoutException) {
        errorMessage =
            "Request timed out. Please check your internet connection and try again.";
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        errorMessage =
            "Network error. Please check your internet connection and try again.";
      }

      setState(() {
        this._loading = false;
        this._placeOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: kSecondaryColor,
          duration: Duration(seconds: 5),
        ),
      );

      // Only clear images if they're actually invalid (not network errors)
      if (clearImages) {
        await Service.remove("images");
      }

      // SECURITY: Log failed order after payment was already processed
      // This helps support team track orders that need refunds
      await _logFailedOrderAfterPayment(
        reason: "Order creation failed after payment: $e",
        paymentId: kifiyaMethod != -1 
            ? paymentResponse['payment_gateway'][kifiyaMethod]['_id'] ?? ''
            : '',
        amount: widget.price ?? 0.0,
      );

      // Show additional message about contacting support
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Service.showMessage(
            context: context,
            title: "If payment was deducted, please contact support at 8707 with reference: ${widget.orderPaymentUniqueId}",
            error: true,
            duration: 5,
          );
        }
      });

      return null;
    }
  }

  Future<dynamic> createAliexpressOrder() async {
    // debugPrint("in createAliexpressOrder>>>");
    var aliOrderResponse;
    var mobile_no = cart.phone.isNotEmpty
        ? cart.phone
        : "${userData['user']['phone']}";
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
          },
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
            Text("Creating order...", style: TextStyle(color: kBlackColor)),
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
            Text("Creating order...", style: TextStyle(color: kBlackColor)),
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
        "schedule_order_start_at":
            cart.scheduleStart != null &&
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

      Service.showMessage(
        context: context,
        title:
            "Failed to create order, please check your internet and try again",
        error: true,
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
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Network error",
                error: true,
              );
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
            Text(title, style: TextStyle(color: kBlackColor)),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";
    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
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
      Service.showMessage(
        context: context,
        title: "Failed to verify payment. Check you internet and try again",
        error: true,
        duration: 4,
      );
      return null;
    }
  }

  Future<dynamic> ethSwitchVerify({
    String title = "Verifying payment...",
    required String traceNo,
  }) async {
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
            Text(title, style: TextStyle(color: kBlackColor)),
          ],
        ),
      );
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/pay_payment_etswitch";
    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
      "trace_no": traceNo,
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
      Service.showMessage(
        context: context,
        title: "Failed to verify payment. Check you internet and try again",
        error: true,
        duration: 4,
      );
      return null;
    }
  }
}
