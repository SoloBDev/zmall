import 'dart:async';
import 'dart:convert';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/shimmer_widget.dart';

import 'order_history_detail.dart';

class OrderHistory extends StatefulWidget {
  @override
  _OrderHistoryState createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
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
      if (data['error_code'] != null && data['error_code'] != 652) {
        Service.showMessage(
            context: context,
            title: "${errorCodes['${data['error_code']}']}!",
            error: true);
      }
      if (data['error_code'] == 999) {
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
                    HeroiconsOutline
                        .lockClosed, // A lock icon to signify login is required
                    size: getProportionateScreenHeight(kDefaultPadding * 4),
                    color: kSecondaryColor.withValues(
                        alpha: 0.7), // Subtle but noticeable secondary color
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(
                        kDefaultPadding), // Increased spacing
                  ),
                  Text(
                    "Access Denied", // A more direct and attention-grabbing headline
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: kGreyColor, // Main text color
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(
                        kDefaultPadding / 4), // Spacing
                  ),
                  Text(
                    "Please log in to view your order history.", // Clear instruction
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kGreyColor, // Softer color for supporting text
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
                        getProportionateScreenWidth(kDefaultPadding / 1.5),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return OrderHistoryDetail(
                                    orderId: responseData['order_list'][index]
                                        ['_id'],
                                    userId: userData['user']['_id'],
                                    serverToken: userData['user']
                                        ['server_token']);
                              },
                            ),
                          ).then((value) => getUser());
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
                                      "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['order_list'][index]['store_detail']['image_url']}"),
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
                                      Service.capitalizeFirstLetters(
                                          responseData['order_list'][index]
                                              ['store_detail']['name']),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: responseData['order_list']
                                                        [index]['total'] ==
                                                    0
                                                ? kSecondaryColor
                                                : kBlackColor,
                                          ),
                                      softWrap: true,
                                    ),
                                    Text(
                                      "Order No. #${responseData['order_list'][index]['unique_id']}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: kGreyColor,
                                          ),
                                    ),
                                    Text(
                                      "${responseData['order_list'][index]['created_at'].split('T')[0].split('-')[1]}/${responseData['order_list'][index]['created_at'].split('T')[0].split('-')[2]} ${responseData['order_list'][index]['created_at'].split('T')[1].split('.')[0]}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: kGreyColor,
                                          ),
                                    ),
                                    Text(
                                      responseData['order_list'][index]
                                                  ['order_status'] ==
                                              7
                                          ? "${order_status['${responseData['order_list'][index]['delivery_status']}']}"
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
                                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_list'][index]['total'].toStringAsFixed(2)}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: responseData['order_list']
                                                      [index]['total'] ==
                                                  0
                                              ? kSecondaryColor
                                              : kBlackColor,
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              getProportionateScreenWidth(kDefaultPadding),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              HeroiconsOutline
                                  .clock, // A more thematic icon for order lists
                              size: getProportionateScreenHeight(
                                  kDefaultPadding * 4), // Slightly larger icon
                              color: kSecondaryColor.withValues(
                                  alpha:
                                      0.8), // A slightly muted secondary color
                            ),
                            SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding), // Increased spacing
                            ),
                            Text(
                              "No Orders Found", // Clearer and more direct message
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700, // Bolder
                                    color: kGreyColor, // Main text color
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding /
                                      4), // Spacing between messages
                            ),
                            Text(
                              "Your order list appears empty. Explore products and place your first order!", // Guiding message
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        kGreyColor, // Softer color for supporting text
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Future<dynamic> getOrders(userId, serverToken) async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/order_history";
    Map data = {
      "user_id": userId,
      "server_token": serverToken,
      "end_date": "",
      "start_date": "",
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
        Duration(seconds: 15),
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
