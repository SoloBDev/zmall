import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class GlobalActiveOrders extends StatefulWidget {
  @override
  _GlobalActiveOrdersState createState() => _GlobalActiveOrdersState();
}

class _GlobalActiveOrdersState extends State<GlobalActiveOrders> {
  AbroadData? userData;

  bool _loading = false;
  var responseData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAbroadUser();
  }

  void _getOrders({phone, loading = true}) async {
    var data = await getOrders(phone);
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        responseData = data;
      });
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${data['error_code']}']}!", true));
      }
    }
    await Future.delayed(Duration(seconds: 7));
    _getOrders(phone: phone, loading: false);
  }

  void getAbroadUser() async {
    setState(() {
      _loading = true;
    });

    var data = await Service.read('abroad_user');
    if (data != null) {
      setState(() {
        userData = AbroadData.fromJson(data);
      });

      _getOrders(phone: userData!.abroadPhone);
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      progressIndicator: linearProgressIndicator,
      color: kPrimaryColor,
      child: userData != null && responseData != null
          ? Padding(
              padding: EdgeInsets.symmetric(
                vertical: getProportionateScreenHeight(kDefaultPadding) / 2,
                horizontal: getProportionateScreenWidth(kDefaultPadding) / 1.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: responseData['order_list'].length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      // print(responseData['order_list'][index]);
//                       if (responseData['order_list'][index]['delivery_type'] ==
//                           2) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) {
//                               return CourierDetail(
//                                   courierData: responseData['order_list']
//                                       [index],
//                                   userId: userData['user']['_id'],
//                                   serverToken: userData['user']
//                                       ['server_token']);
//                             },
//                           ),
//                         ).then((value) => getUser());
//                       } else {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) {
//                               return OrderDetail(
//                                   order: responseData['order_list'][index],
//                                   userId: userData['user']['_id'],
//                                   serverToken: userData['user']
//                                       ['server_token']);
//                             },
//                           ),
//                         ).then((value) => getUser());
//                         print(
//                             responseData['order_list'][index]['order_details']);
//                       }
//
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(kDefaultPadding),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding / 2),
                      ),
                      child: Row(
                        children: [
                          ImageContainer(
                              url:
                                  "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['order_list'][index]['store_image']}"),
                          SizedBox(
                              width: getProportionateScreenWidth(
                                  kDefaultPadding / 4)),
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  responseData['order_list'][index]
                                      ['store_name'],
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(
                                        kDefaultPadding / 1.5),
                                    fontWeight: FontWeight.bold,
                                    color: kBlackColor,
                                  ),
                                  softWrap: true,
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 5)),
                                Text(
                                  "Order No. #${responseData['order_list'][index]['unique_id']}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: kGreyColor,
                                      ),
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 5)),
                                Text(
                                  "${responseData['order_list'][index]['created_at'].split('T')[0].split('-')[1]}/${responseData['order_list'][index]['created_at'].split('T')[0].split('-')[2]}/${responseData['order_list'][index]['created_at'].split('T')[0].split('-')[0]}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: kGreyColor,
                                      ),
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 5)),
//                                  responseData['order_list'][index]
//                                              ['delivery_type'] ==
//                                          1
//                                      ?
                                Text(
                                  "FOR: ${responseData['order_list'][index]['destination_addresses'][0]['user_details']['name'].toString().toUpperCase()}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: kBlackColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 5)),
//                                  responseData['order_list'][index]
//                                              ['delivery_type'] ==
//                                          1
//                                      ?
                                Text(
                                  responseData['order_list'][index]
                                              ['order_status'] ==
                                          7
                                      ? "${order_status['${responseData['order_list'][index]['delivery_status']}']}"
                                      : "${order_status['${responseData['order_list'][index]['order_status']}']}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: kSecondaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Column(
                            children: [
                              Text(
                                "ብር${responseData['order_list'][index]['total_order_price'].toStringAsFixed(2)}",
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
                separatorBuilder: (BuildContext context, int index) => SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 4),
                ),
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
                        Icons.reorder_rounded,
                        size: getProportionateScreenHeight(kDefaultPadding * 3),
                        color: kSecondaryColor,
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 3)),
                      Text(
                        "No Active Orders Found",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      )
                    ],
                  ),
                ),
    );
  }

  Future<dynamic> getOrders(phone) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/get_orders_abroad";
    Map data = {
      "phone": phone,
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
      return json.decode(response.body);
    } catch (e) {
      // print(e);
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
