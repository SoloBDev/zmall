import 'dart:async';
import 'dart:convert';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/orders/components/courier_detail.dart';
import 'package:zmall/orders/components/order_detail.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/shimmer_widget.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  var userData;
  bool _loading = false;
  var responseData;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void _getOrders(userId, serverToken) async {
    setState(() {
      _loading = true;
    });
    var data = await getOrders(userId, serverToken);
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        responseData = data;
      });
    } else {
      setState(() {
        _loading = false;
      });
      // 652
      if (data['error_code'] != null && data['error_code'] != 652) {
        Service.showMessage(
            context: context,
            title: "${errorCodes['${data['error_code']}']}!",
            error: true);
      }

      if (data['error_code'] != null && data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  void getUser() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      _getOrders(userData['user']['_id'], userData['user']['server_token']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading && userData != null,
      progressIndicator: userData != null && responseData != null
          ? LinearLoadingIndicator()
          : ProductListShimmer(),
      color: kPrimaryColor,
      child: userData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    HeroiconsOutline.lockClosed,
                    size: getProportionateScreenHeight(kDefaultPadding * 4),
                    color: kSecondaryColor.withValues(alpha: 0.7),
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  Text(
                    "Access Denied",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: kGreyColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 4),
                  ),
                  Text(
                    "Please log in to view your order history.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kGreyColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : userData != null && responseData != null
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding / 2),
                  ).copyWith(
                    top: getProportionateScreenHeight(kDefaultPadding) / 2,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: responseData['order_list'].length,
                    padding: EdgeInsets.only(
                      bottom: getProportionateScreenHeight(kDefaultPadding) / 2,
                    ),
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          if (responseData['order_list'][index]
                                  ['delivery_type'] ==
                              2) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return CourierDetail(
                                      courierData: responseData['order_list']
                                          [index],
                                      userId: userData['user']['_id'],
                                      serverToken: userData['user']
                                          ['server_token']);
                                },
                              ),
                            ).then((value) => getUser());
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return OrderDetail(
                                      order: responseData['order_list'][index],
                                      userId: userData['user']['_id'],
                                      serverToken: userData['user']
                                          ['server_token']);
                                },
                              ),
                            ).then((value) => getUser());
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            border: Border.all(color: kWhiteColor),
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
                              ImageContainer(
                                  url:
                                      "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['order_list'][index]['store_image']}"),
                              SizedBox(
                                  width: getProportionateScreenWidth(
                                      kDefaultPadding / 1.5)),
                              Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: getProportionateScreenHeight(
                                      kDefaultPadding / 5),
                                  children: [
                                    Text(
                                      responseData['order_list'][index]
                                                  ['store_name'] ==
                                              "Courier"
                                          ? responseData['order_list'][index][
                                                          'destination_addresses']
                                                      [0]['note'] ==
                                                  "Lunch from Home"
                                              ? "Lunch From Home"
                                              : Service.capitalizeFirstLetters(
                                                  responseData['order_list']
                                                      [index]['store_name'])
                                          : Service.capitalizeFirstLetters(
                                              responseData['order_list'][index]
                                                  ['store_name']),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: kBlackColor,
                                          ),
                                      softWrap: true,
                                    ),

                                    Text(
                                      "Order No. #${responseData['order_list'][index]['unique_id']}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: kGreyColor,
                                          ),
                                    ),

                                    Text(
                                      "${responseData['order_list'][index]['created_at'].split('T')[0].split('-')[1]}/${responseData['order_list'][index]['created_at'].split('T')[0].split('-')[2]} ${int.parse(responseData['order_list'][index]['created_at'].split('T')[1].split('.')[0].split(':')[0]) + 3}:${responseData['order_list'][index]['created_at'].split('T')[1].split('.')[0].split(':')[1]}:${responseData['order_list'][index]['created_at'].split('T')[1].split('.')[0].split(':')[2]}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: kGreyColor,
                                          ),
                                    ),

//                                  responseData['order_list'][index]
//                                              ['delivery_type'] ==
//                                          1
//                                      ?
                                    Text(
                                      responseData['order_list'][index]
                                                  ['order_status'] ==
                                              7
                                          ? responseData['order_list'][index]
                                                      ['delivery_status'] !=
                                                  null
                                              ? "${order_status['${responseData['order_list'][index]['delivery_status']}']}"
                                              : "Waiting to accept order"
                                          : "${order_status['${responseData['order_list'][index]['order_status']}']}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: responseData['order_list']
                                                            [index]
                                                        ['order_status'] ==
                                                    25
                                                ? Colors.green
                                                : kSecondaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              Column(
                                children: [
                                  Text(
                                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_list'][index]['total_order_price'].toStringAsFixed(2)}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: kBlackColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : _loading
                  ? Container()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            HeroiconsOutline.shoppingBag,
                            size: getProportionateScreenHeight(
                                kDefaultPadding * 4),
                            color: kSecondaryColor.withValues(alpha: 0.8),
                          ),
                          SizedBox(
                            height:
                                getProportionateScreenHeight(kDefaultPadding),
                          ),
                          Text(
                            "No Active Orders Yet",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: kGreyColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 4),
                          ),
                          Text(
                            "Place an order to see it here!",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: kGreyColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
    );
  }

  Future<dynamic> getOrders(userId, serverToken) async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_orders";
    Map data = {
      "user_id": userId,
      "server_token": serverToken,
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
      // debugPrint(e);
      if (mounted)
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
