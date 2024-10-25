import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/location/components/provider_location.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

import 'order_history_detail.dart';

class CourierDetail extends StatefulWidget {
  const CourierDetail({this.courierData, this.userId, this.serverToken});
  final courierData;
  final String? userId;
  final String? serverToken;

  @override
  _CourierDetailState createState() => _CourierDetailState();
}

class _CourierDetailState extends State<CourierDetail> {
  String reason = "Changed my mind";
  bool _loading = false;
  var orderStatus;
  late String providerId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getOrderStatus();
  }

  void _getOrderStatus() async {
    var data = await getOrderStatus();
    if (data != null && data['success']) {
      setState(() {
        orderStatus = data;
        providerId = orderStatus['provider_id'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  void _userCancelOrder() async {
    setState(() {
      _loading = true;
    });
    var data = await userCancelOrder();
    if (data != null && data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage(
            "We're sad but you've successfully canceled your order.", false,
            duration: 5),
      );
      Navigator.of(context).pop();
    } else {
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${errorCodes['${data['error_code']}']}"),
        backgroundColor: kSecondaryColor,
      ));
    }
  }

  void _showInvoice() async {
    setState(() {
      _loading = true;
    });
    var data = await showInvoice();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(Service.showMessage("Order Completed!", false));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OrderHistoryDetail(
                orderId: widget.courierData['_id'],
                userId: widget.userId!,
                serverToken: widget.serverToken!);
          },
        ),
      );
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courierData['destination_addresses'][0]['note'] ==
                  "Lunch from Home"
              ? "Lunch From Home"
              : "Courier Detail",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kSecondaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "ORDER ID: #${widget.courierData['unique_id']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "PICKUP ADDRESS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kGreyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Center(
                    child: Text(
                      "${widget.courierData['pickup_addresses'][0]['address']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBlackColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kSecondaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "DELIVERY ADDRESS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBlackColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Center(
                    child: Text(
                      "${widget.courierData['destination_addresses'][0]['address']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "RECEIVER",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kGreyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Center(
                    child: Text(
                      "${widget.courierData['destination_addresses'][0]['user_details']['name']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBlackColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kSecondaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "RECEIVER PHONE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBlackColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Center(
                    child: Text(
                      "+251 ${widget.courierData['destination_addresses'][0]['user_details']['phone']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "CONFIRMATION CODE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kGreyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Center(
                    child: Text(
                      "${widget.courierData['confirmation_code_for_complete_delivery']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBlackColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kSecondaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "ITEM DESCRIPTION",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBlackColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Center(
                    child: Text(
                      "${widget.courierData['destination_addresses'][0]['note']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor,
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "STATUS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kGreyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Center(
                    child: widget.courierData['delivery_status'] != null &&
                            widget.courierData['order_status'] == 7
                        ? Text(
                            "${order_status['${widget.courierData['delivery_status']}']}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kBlackColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            "Pending...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kBlackColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            Center(
              child: Column(
                children: [
                  Text(
                    "Total",
                    style: TextStyle(
                      fontSize:
                          getProportionateScreenWidth(kDefaultPadding * .7),
                    ),
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 3)),
                  Text(
                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.courierData['total_order_price'].toStringAsFixed(2)}",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
//            Text("
//            ${widget.courierData
//            ['order_status'] ==
//                7
//                ? "${order_status['${widget.courierData['delivery_status']}']}"
//                : "${order_status['${widget.courierData['order_status']}']},"}),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            orderStatus != null &&
                    orderStatus['provider_id'] != null &&
                    widget.courierData['order_status'] != 25 &&
                    widget.courierData['delivery_status'] != null &&
                    widget.courierData['delivery_status'] >= 9 &&
                    widget.courierData['delivery_status'] < 25
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: getProportionateScreenHeight(kDefaultPadding),
                      left: getProportionateScreenWidth(kDefaultPadding),
                      right: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    child: CustomButton(
                      title: "Track My Order",
                      press: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ProviderLocation(
                                providerId: orderStatus['provider_id'],
                                providerImage: orderStatus['provider_image'],
                                providerName:
                                    orderStatus['provider_first_name'],
                                providerPhone: orderStatus['provider_phone'],
                                destLat: orderStatus['destination_addresses'][0]
                                    ['location'][0],
                                destLong: orderStatus['destination_addresses']
                                    [0]['location'][1],
                                userId: widget.userId!,
                                serverToken: widget.serverToken!,
                              );
                            },
                          ),
                        );
                      },
                      color: kSecondaryColor,
                    ),
                  )
                : Container(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                widget.courierData['order_status'] == 25
                    ? Padding(
                        padding: EdgeInsets.only(
                          bottom: getProportionateScreenHeight(kDefaultPadding),
                          left: getProportionateScreenWidth(kDefaultPadding),
                          right: getProportionateScreenWidth(kDefaultPadding),
                        ),
                        child: _loading
                            ? SpinKitWave(
                                size: getProportionateScreenWidth(
                                    kDefaultPadding),
                                color: kBlackColor,
                              )
                            : CustomButton(
                                title: "SUBMIT",
                                press: () {
                                  _showInvoice();
                                },
                                color: kBlackColor,
                              ),
                      )
                    : Container(),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                widget.courierData['delivery_status'] != null &&
                        widget.courierData['delivery_status'] >= 109
                    ? Center(
                        child: TextButton(
                          onPressed: () {
                            _showDialog();
                          },
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: kBlackColor),
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> showInvoice() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/show_invoice";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "order_id": widget.courierData['_id'],
      "is_user_show_invoice": true,
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
      // print(e);
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

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kPrimaryColor,
          title: Text("Keep Order"),
          content: Text("Are you sure you want to cancel?"),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Think about it!",
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
                "Sure",
                style: TextStyle(color: kBlackColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showCancelDialog();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kPrimaryColor,
          title: Text("Reason ☹"),
          content: TextField(
            style: TextStyle(color: kBlackColor),
            keyboardType: TextInputType.text,
            onChanged: (val) {
              reason = val;
            },
            decoration: textFieldInputDecorator.copyWith(
              labelText: "Reason",
              hintText: "$reason",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Think about it!",
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
                "Sure",
                style: TextStyle(color: kBlackColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _userCancelOrder();
              },
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> getOrderStatus() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_order_status";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "order_id": widget.courierData['_id'],
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
      // print(e);
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

  Future<dynamic> userCancelOrder() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_cancel_order";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "cancel_reason": reason,
      "order_id": widget.courierData['_id'],
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
      // print(e);
      return null;
    }
  }
}
