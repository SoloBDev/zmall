import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class KifiyaVerification extends StatefulWidget {
  const KifiyaVerification({
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
  });

  final double hisab;
  final String phone;
  final String traceNo;
  final String orderPaymentId;

  @override
  _KifiyaVerificationState createState() => _KifiyaVerificationState();
}

class _KifiyaVerificationState extends State<KifiyaVerification> {
  bool copied = false;
  bool _loading = false;
  var userData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      _telebirrPostBill();
    }
  }

  void _telebirrPostBill() async {
    setState(() {
      _loading = true;
    });
    var data = await telebirrPostBill();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['message']}! Please complete your payment using Tele Birr App",
          false,
          duration: 4));
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(Service.showMessage("${data['message']}", true));
      await Future.delayed(Duration(seconds: 2));
    }
  }

  void _telebirrVerifyBill() async {
    setState(() {
      _loading = true;
    });
    await Future.delayed(Duration(seconds: 3));
    var data = await telebirrVerifyBill();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("Payment successfull!", false, duration: 4));
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${data['error']}! Please complete your payment using Tele Birr App",
          true));
      await Future.delayed(Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tele Birr",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        progressIndicator: linearProgressIndicator,
        color: kWhiteColor,
        child: SingleChildScrollView(
          child: Padding(
            padding:
                EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding)),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pay ብር ${widget.hisab.toStringAsFixed(2)} with Tele Birr",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      Text(
                        "Please use the bottom reference number to complete your payment using Tele Birr App or USSD.",
                        style: TextStyle(color: kGreyColor),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding / 2),
                            ),
                          ),
                          padding: EdgeInsets.all(
                              getProportionateScreenWidth(kDefaultPadding / 2)),
                          child: Text(
                            "${widget.traceNo}",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Clipboard.setData(
                                    new ClipboardData(text: widget.traceNo))
                                .then((_) {
                              setState(() {
                                copied = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Reference number copied to clipboard! Please complete your payment using Tele Birr App",
                                      false));
                            });
                          },
                          child: Text(
                            "Copy Reference Number",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: kSecondaryColor),
                          ),
                        ),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Press',
                          style: TextStyle(
                            color: kGreyColor,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: ' VERIFY',
                              style: TextStyle(
                                  color: kBlackColor,
                                  fontSize: getProportionateScreenWidth(
                                      kDefaultPadding * .75),
                                  fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' once you\'re done paying...',
                              style: TextStyle(
                                color: kGreyColor,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding),
                ),
                CustomButton(
                  title: "Verify",
                  press: () {
                    if (!copied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          Service.showMessage(
                              "Please copy the reference number and make payment on Tele Birr application.",
                              true));
                    } else {
                      _telebirrVerifyBill();
                    }
                  },
                  color: copied ? kSecondaryColor : kGreyColor,
                ),
                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding),
                ),
                Container(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenWidth(kDefaultPadding))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "How to pay with Telebirr?",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      Text(
                        "1. Copy the reference number above ☝🏾",
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      Text(
                        "2. Open Telebirr App and Login",
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      RichText(
                        text: TextSpan(
                            text: '3. Press ',
                            style: Theme.of(context).textTheme.titleMedium,
                            children: <TextSpan>[
                              TextSpan(
                                text: '"Pay with Telebirr"',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              )
                            ]),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      RichText(
                        text: TextSpan(
                            text: '4. Press ',
                            style: Theme.of(context).textTheme.titleMedium,
                            children: <TextSpan>[
                              TextSpan(
                                text: '"Utility Payment"',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              )
                            ]),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      RichText(
                        text: TextSpan(
                            text: '5. Press ',
                            style: Theme.of(context).textTheme.titleMedium,
                            children: <TextSpan>[
                              TextSpan(
                                text: '"ZMALL"',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              )
                            ]),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      Text(
                        "6. Paste the reference number and proceed with payment",
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.start,
                      ),
                      Text(
                        "7. Press Verify to complete verification and create order.",
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.start,
                      ),
                      Text(
                        "8. In case payment verification fails please send your payment screenshot to our Telegram using the link below and place your order using CASH payment method.",
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.start,
                      ),
                      GestureDetector(
                        onTap: () {
                          Service.launchInWebViewOrVC(
                              "https://t.me/zmall_delivery");
                        },
                        child: Text(
                          "9. ZMall Delivery Telegram",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    color: kSecondaryColor,
                                  ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> telebirrPostBill() async {
    var url = "https://pgw.shekla.app/telebirr/post_bill";
    Map data = {
      "phone":
          "${Provider.of<ZMetaData>(context, listen: false).areaCode}${widget.phone}",
      "description": "ZMall Delivery Order Payment",
      "code": "0005",
      "trace_no": widget.traceNo,
      "amount": "${widget.hisab}",
      "appId": "1234"
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
        Duration(seconds: 10),
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
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> telebirrVerifyBill() async {
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
        Duration(seconds: 10),
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
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}
