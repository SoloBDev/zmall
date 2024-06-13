import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/checkout/checkout_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/report/global_report.dart';
import 'package:zmall/kifiya/components/cyber_source.dart';
import 'package:zmall/kifiya/components/kifiya_method_container.dart';
import 'package:zmall/kifiya/components/telebirr_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';

import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';

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
    print(widget.price);
    getUser();
    getCart();
    if (widget.onlyCashless) {
      kifiyaMethod = -1;
    }
    uuid = widget.orderPaymentUniqueId;
  }

  void getUser() async {
    var data = await Service.read('abroad_user');
    if (data != null) {
      abroadData = AbroadData.fromJson(data);
      try {
        var fullName = abroadData!.abroadName!.split(" ");
        if (fullName.length > 1) {
          setState(() {
            firstName = fullName.first;
            lastName = fullName.last;
          });
        }
      } catch (e) {
        print(e);
      }
    } else {
      //
    }
  }

  void getCart() async {
    print("Fetching cart");
    var data = await Service.read('abroad_cart');
    if (data != null) {
      setState(() {
        cart = AbroadCart.fromJson(data);
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
        print(paymentResponse['payment_gateway'][i]['name']);
        print("\t${paymentResponse['payment_gateway'][i]['description']}");
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
      print("Payment response error");
      await Future.delayed(Duration(seconds: 2));
      print("Payment Gateway : Server token error...");
    }
  }

  void _createOrder() async {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });
    var data = await createOrder();
    if (data != null && data['success']) {
      print("Order created successfully");
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(("Order successfully created"), true));
      await Service.remove('abroad_cart');
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return GlobalReport(
          price: widget.price,
          orderPaymentUniqueId: widget.orderPaymentUniqueId,
        );
      }));
    } else {
      print("\t\t- Create Order Response");
      print(data);
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
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
      print("Order payment successfull! Creating order");
      // widget.isCourier ? _createCourierOrder() : _createOrder();
      _createOrder();
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      await Future.delayed(Duration(seconds: 1));
      // print("Pay Order Payment : Server token error....");
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
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Payment verification successful!", false,
          duration: 2));
      // _payOrderPayment();
      _createOrder();
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
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['error']}! Please complete your payment!", true));
      await Future.delayed(Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Payments",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        progressIndicator: linearProgressIndicator,
        color: kPrimaryColor,
        child: paymentResponse != null
            ? SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          "How would you like to pay ብር ${widget.price}?",
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                            height:
                                getProportionateScreenHeight(kDefaultPadding)),
                        CustomTag(
                            color: kSecondaryColor,
                            text: "Payment Information"),
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
                            padding: EdgeInsets.only(
                              left:
                                  getProportionateScreenWidth(kDefaultPadding),
                              right:
                                  getProportionateScreenWidth(kDefaultPadding),
                              top:
                                  getProportionateScreenHeight(kDefaultPadding),
                              bottom: getProportionateScreenHeight(
                                  kDefaultPadding / 2),
                            ),
                            child: Column(
                              children: [
                                DetailsRow(
                                    title: "Name",
                                    subtitle: abroadData != null &&
                                            abroadData!.abroadName!.isNotEmpty
                                        ? abroadData!.abroadName!
                                        : "N/A"),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 3)),
                                DetailsRow(
                                    title: "Phone",
                                    subtitle: abroadData != null &&
                                            abroadData!.abroadPhone!.isNotEmpty
                                        ? abroadData!.abroadPhone!
                                        : "N/A"),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 3)),
                                DetailsRow(
                                    title: "Email",
                                    subtitle: abroadData != null &&
                                            abroadData!.abroadEmail!.isNotEmpty
                                        ? abroadData!.abroadEmail!
                                        : "N/A"),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 3)),
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
//                                                       // print(abroadData.toJson());
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
                        ),
                        SizedBox(
                            height:
                                getProportionateScreenHeight(kDefaultPadding)),
                        CustomTag(
                            color: kSecondaryColor,
                            text: "Select Payment Method"),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2)),
                        widget.onlyCashless
                            ? Text(
                                "Store only allows digital payments.",
                                style: Theme.of(context).textTheme.titleMedium,
                              )
                            : Container(),
                        widget.onlyCashless
                            ? SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2))
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
                            separatorBuilder: (context, index){
                              return Container(height: 4,);
                            },
                            itemCount:
                                paymentResponse['payment_gateway'].length,
                            itemBuilder: (BuildContext ctx, index) {
                              if (paymentResponse['payment_gateway'][index]
                                          ['name']
                                      .toString()
                                      .toLowerCase() ==
                                  'boa') {
                                print(paymentResponse['payment_gateway'][index]
                                    ['name']);
                                return KifiyaMethodContainer(
                                    selected: kifiyaMethod == index + 4,
                                    title: paymentResponse['payment_gateway']
                                            [index]['description']
                                        .toString()
                                        .toUpperCase(),
                                    kifiyaMethod: kifiyaMethod,
                                    imagePath: "images/boa.png",
                                    press: () async {
                                      setState(() {
                                        kifiyaMethod = index + 4;
                                        paymentGatewayId =
                                            paymentResponse['payment_gateway']
                                                [index]['_id'];
                                      });
                                      var cartId =
                                          await Service.read("cart_id");
                                      print(
                                          "Order payment unique ID : ${widget.orderPaymentUniqueId}");
                                      print(
                                          "Order payment ID : ${widget.orderPaymentId}");
                                      print(
                                          "Payment Gateway ID : $paymentGatewayId");
                                      print("User ID : ${cart!.userId}");
                                      print(
                                          "Server Token : ${cart!.serverToken}");
                                      print("Cart ID : $cartId");
                                      var data = await useBorsa();
                                      if (data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using International Card"),
                                                content: Wrap(
                                                  children: [
                                                    Text(
                                                        "Proceed to pay ብር ${widget.price.toStringAsFixed(2)} using International Card?"),
                                                    Container(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding /
                                                                  2),
                                                    ),
                                                    TextField(
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                      keyboardType:
                                                          TextInputType.text,
                                                      onChanged: (val) {
                                                        firstName = val;
                                                      },
                                                      decoration: textFieldInputDecorator.copyWith(
                                                          labelText:
                                                                  firstName
                                                                      .isNotEmpty
                                                              ? firstName
                                                              : "First Name"),
                                                    ),
                                                    Container(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding /
                                                                  2),
                                                    ),
                                                    TextField(
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                      keyboardType:
                                                          TextInputType.text,
                                                      onChanged: (val) {
                                                        lastName = val;
                                                      },
                                                      decoration: textFieldInputDecorator.copyWith(
                                                          labelText:
                                                                  lastName
                                                                      .isNotEmpty
                                                              ? lastName
                                                              : "Last Name"),
                                                    ),
                                                    Container(
                                                      height:
                                                          getProportionateScreenHeight(
                                                              kDefaultPadding /
                                                                  2),
                                                    ),
                                                    TextField(
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                      enabled: true,
                                                      keyboardType:
                                                          TextInputType.text,
                                                      onChanged: (val) {},
                                                      decoration: textFieldInputDecorator
                                                          .copyWith(
                                                              labelText: abroadData!
                                                                      .abroadEmail!
                                                                      .isNotEmpty
                                                                  ? abroadData!
                                                                      .abroadEmail
                                                                  : "Email"),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      "Cancel",
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
                                                      "Continue",
                                                      style: TextStyle(
                                                          color: kBlackColor),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        uuid =
                                                            (int.parse(uuid) +
                                                                    1)
                                                                .toString();
                                                      });

                                                      if (abroadData != null &&
                                                          abroadData!
                                                              .abroadEmail!
                                                              .isNotEmpty &&
                                                          abroadData!.abroadName!
                                                              .isNotEmpty &&
                                                          abroadData!
                                                              .abroadPhone!
                                                              .isNotEmpty) {
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
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
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                      }
                                    });
                              } else if (paymentResponse['payment_gateway']
                                          [index]['name']
                                      .toString()
                                      .toLowerCase() ==
                                  "zemen") {
                                return KifiyaMethodContainer(
                                    selected: kifiyaMethod == index + 4,
                                    title: paymentResponse['payment_gateway']
                                            [index]['description']
                                        .toString()
                                        .toUpperCase(),
                                    kifiyaMethod: kifiyaMethod,
                                    imagePath: "images/zemen.png",
                                    press: () async {
                                      setState(() {
                                        kifiyaMethod = index + 4;
                                        paymentGatewayId =
                                            paymentResponse['payment_gateway']
                                                [index]['_id'];
                                      });
                                      var cartId =
                                          await Service.read("cart_id");
                                      print(
                                          "Order payment unique ID : ${widget.orderPaymentUniqueId}");
                                      print(
                                          "Order payment ID : ${widget.orderPaymentId}");
                                      print(
                                          "Payment Gateway ID : $paymentGatewayId");
                                      print("User ID : ${cart!.userId}");
                                      print(
                                          "Server Token : ${cart!.serverToken}");
                                      print("Cart ID : $cartId");
                                      var data = await useBorsa();
                                      if (data['success']) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Pay Using International Card"),
                                                content: Text(
                                                    "Proceed to pay ብር ${widget.price.toStringAsFixed(2)} using International Card?"),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      "Cancel",
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
                                                      "Continue",
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
                                                              isAbroad: true,
                                                              url:
                                                                  "https://pgw.shekla.app/zemen/post_bill",
                                                              hisab:
                                                                  widget.price,
                                                              traceNo: uuid +
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
                                                  )
                                                ],
                                              );
                                            });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(Service.showMessage(
                                                "Something went wrong! Please try again!",
                                                true));
                                      }
                                    });
                              } else {
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
                                    kDefaultPadding),
                              )
                            : CustomButton(
                                title: "Place Order",
                                press: () async {
                                  // var data = await Service.read("cart_id");
                                  // print(data);
                                  if (paymentGatewayId != null) {
                                    _payOrderPayment(
                                        otp: "",
                                        paymentId: widget.orderPaymentId);
                                  } else {}
                                },
                                color: paymentGatewayId != null
                                    ? kSecondaryColor
                                    : kGreyColor,
                              )
                      ],
                    ),
                  ),
                ),
              )
            : Container(),
      ),
    );
  }

  Future<dynamic> getPaymentGateway() async {
    print("- Fetching payment gatway");
    print("\t-> server_token ${cart!.serverToken}");
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_payment_gateway";
    Map data = {
      "user_id": cart!.userId,
      "city_id": "5b406b46d2ddf8062d11b788",
      "server_token": cart!.serverToken,
    };
    var body = json.encode(data);
    print(body);
    print("Fetching payment gateway...");
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
      print(paymentResponse);
      return json.decode(response.body);
    } catch (e) {
      print(e);
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
    print(cart!.userId);
    print(cart!.serverToken);
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
    print(body);
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
      print("=========Pay Order Payment Done=========");
      print(json.decode(response.body));
      setState(() {
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      print(e);
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

  Future<dynamic> useBorsa() async {
    print("Changing wallet status");
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/change_user_wallet_status";
    Map data = {
      "user_id": cart!.userId,
      "is_use_wallet": false,
      "server_token": cart!.serverToken
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
      print(e);
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

  Future<dynamic> createOrder() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/create_order";
    print("Getting ready to create order");
    var cart_id = await Service.read('cart_id');
    print("\t Cart Id : ");
    print("\t\t$cart_id");
    try {
      Map data = {
        "user_id": cart!.userId,
        "cart_id": cart_id,
        "is_schedule_order": cart!.isSchedule != null ? cart!.isSchedule : false,
        "schedule_order_start_at": cart!.scheduleStart != null &&
                cart!.isSchedule != null &&
                cart!.isSchedule
            ? cart!.scheduleStart!.toUtc().toString()
            : "",
        "server_token": cart!.serverToken,
      };
      print(data);
      var body = json.encode(data);
      http.Response response;
      response = await http
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
      print("==========Create Order Done==========");
      print(json.decode(response.body));
      setState(() {
        orderResponse = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      print("\t- $e");
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

  Future<dynamic> boaVerify() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";
    Map data = {
      "user_id": cart!.userId,
      "server_token": cart!.serverToken,
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
      print(e);
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
}
