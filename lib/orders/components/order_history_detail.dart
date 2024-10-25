import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/orders/components/order_rating.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class OrderHistoryDetail extends StatefulWidget {
  static String routeName = '/order_history_detail';

  @override
  _OrderHistoryDetailState createState() => _OrderHistoryDetailState();

  const OrderHistoryDetail({
    @required this.orderId,
    @required this.userId,
    @required this.serverToken,
  });

  final String? orderId, userId, serverToken;
}

class _OrderHistoryDetailState extends State<OrderHistoryDetail> {
  bool _loading = false;
  var responseData;
  var userData;

  RateMyApp _rateMyApp = RateMyApp(
    preferencesPrefix: 'rateMyApp_',
    minLaunches: 5,
    minDays: 7,
    remindLaunches: 5,
    remindDays: 3,
    appStoreIdentifier: 'com.enigma.zmall',
    googlePlayIdentifier: 'com.enigma.zmall',
  );
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    _rateMyApp.init().then((_) => {
          if (_rateMyApp.shouldOpenDialog)
            {
              _rateMyApp.showStarRateDialog(
                context,
                title: "Enjoying ZMall?",
                message: "Please leave a rating!",
                dialogStyle: DialogStyle(
                  titleAlign: TextAlign.center,
                  messageAlign: TextAlign.center,
                  messagePadding: EdgeInsets.only(bottom: 20.0),
                ),
                starRatingOptions: StarRatingOptions(initialRating: 5),
                actionsBuilder: actionsBuilder,
              )
            }
        });
  }

  List<Widget> actionsBuilder(BuildContext context, double? stars) =>
      stars == null
          ? [buildCancelButton()]
          : [buildOkButton(stars), buildCancelButton()];

  Widget buildOkButton(double stars) => TextButton(
        child: Text('OK'),
        onPressed: () async {
          final launchAppStore = stars >= 4;
          ScaffoldMessenger.of(context).showSnackBar(
              Service.showMessage("Thanks for your feedback!", true));
          final event = RateMyAppEventType.rateButtonPressed;
          await _rateMyApp.callEvent(event);

          if (launchAppStore) {
            _rateMyApp.launchStore();
          }

          Navigator.of(context).pop();
        },
      );
  Widget buildCancelButton() => RateMyAppNoButton(_rateMyApp, text: "Cancel");

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      _getDetails();
    }
  }

  void _getDetails() async {
    print("Fetching order detail");
    var data = await getDetail();
    if (data != null) {
      setState(
        () {
          responseData = data;
//          print(responseData['order_list']);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            Provider.of<ZLanguage>(context, listen: false).orderDetails,
            style: TextStyle(color: kBlackColor),
          ),
          elevation: 1.0,
          bottom: TabBar(
            indicatorColor: kSecondaryColor,
            tabs: [
              Tab(
                icon: Column(
                  children: [
                    Icon(
                      Icons.reorder,
                      color: kSecondaryColor,
                    ),
                    Text(
                      Provider.of<ZLanguage>(context, listen: false).details,
                      style: TextStyle(
                        color: kBlackColor,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                icon: Column(
                  children: [
                    Icon(
                      Icons.receipt,
                      color: kSecondaryColor,
                    ),
                    Text(
                      Provider.of<ZLanguage>(context, listen: false).invoice,
                      style: TextStyle(
                        color: kBlackColor,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                icon: Column(
                  children: [
                    Icon(
                      Icons.shopping_basket_rounded,
                      color: kSecondaryColor,
                    ),
                    Text(
                      Provider.of<ZLanguage>(context, listen: false).cart,
                      style: TextStyle(
                        color: kBlackColor,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        body: ModalProgressHUD(
          inAsyncCall: _loading,
          progressIndicator: linearProgressIndicator,
          color: kPrimaryColor,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding:
                  EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
              child: TabBarView(
                children: [
                  responseData != null
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              CategoryContainer(
                                  title: Provider.of<ZLanguage>(context,
                                          listen: false)
                                      .orderDetails),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2),
                              ),
                              Container(
                                decoration: BoxDecoration(color: kPrimaryColor),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      getProportionateScreenWidth(
                                          kDefaultPadding)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding * 5),
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding * 5),
                                        child: ImageContainer(
                                          url:
                                              "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['store_detail']['image_url']}",
                                        ),
                                      ),
                                      SizedBox(
                                          width: getProportionateScreenWidth(
                                              kDefaultPadding)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              responseData['store_detail']
                                                          ['name'] !=
                                                      null
                                                  ? "${responseData['store_detail']['name']}"
                                                  : "${responseData['order_list']['cart_detail']['pickup_addresses'][0]['user_details']['name']}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              softWrap: true,
                                            ),
                                            Text(Provider.of<ZLanguage>(context,
                                                    listen: false)
                                                .receivedBy),
                                            Text(
                                              responseData['order_list']
                                                          ['cart_detail']
                                                      ['destination_addresses']
                                                  [0]['user_details']['name'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            )
                                          ],
                                        ),
                                      ),
                                      responseData['order_list']
                                              ['is_user_rated_to_store']
                                          ? Column(
                                              children: [
                                                IconButton(
                                                    icon: Icon(
                                                      Icons.star,
                                                      color: kSecondaryColor,
                                                    ),
                                                    onPressed: () {}),
                                                Text(
                                                  Provider.of<ZLanguage>(
                                                          context,
                                                          listen: false)
                                                      .thankYou,
                                                  textAlign: TextAlign.center,
                                                )
                                              ],
                                            )
                                          : responseData['store_detail']
                                                          ['name'] !=
                                                      null &&
                                                  responseData['order_list']
                                                          ['order_status'] ==
                                                      25
                                              ? Column(
                                                  children: [
                                                    IconButton(
                                                        icon: Icon(
                                                            Icons.star_border),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) {
                                                                return OrderRating(
                                                                  userId: widget
                                                                      .userId!,
                                                                  orderId: widget
                                                                      .orderId!,
                                                                  serverToken:
                                                                      widget
                                                                          .serverToken!,
                                                                  imageUrl:
                                                                      "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['store_detail']['image_url']}",
                                                                  name:
                                                                      "${responseData['store_detail']['name']}",
                                                                  isStore: true,
                                                                );
                                                              },
                                                            ),
                                                          ).then((value) =>
                                                              getUser());
                                                        }),
                                                    Text(Provider.of<ZLanguage>(
                                                            context,
                                                            listen: false)
                                                        .rateUs),
                                                  ],
                                                )
                                              : Container()
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              CategoryContainer(
                                  title: Provider.of<ZLanguage>(context,
                                          listen: false)
                                      .deliveryDetails),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2),
                              ),
                              responseData['order_list']['order_status'] == 25
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                            getProportionateScreenWidth(
                                                kDefaultPadding)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * 5),
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 5),
                                              child: ImageContainer(
                                                url:
                                                    "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['provider_detail']['image_url']}",
                                              ),
                                            ),
                                            SizedBox(
                                                width:
                                                    getProportionateScreenWidth(
                                                        kDefaultPadding)),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(Provider.of<ZLanguage>(
                                                        context,
                                                        listen: false)
                                                    .deliveredBy),
                                                Text(
                                                  "${responseData['provider_detail']['first_name']}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        color: kBlackColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Spacer(),
                                            responseData['order_list'][
                                                    'is_user_rated_to_provider']
                                                ? Column(
                                                    children: [
                                                      IconButton(
                                                          icon: Icon(
                                                            Icons.star,
                                                            color:
                                                                kSecondaryColor,
                                                          ),
                                                          onPressed: () {}),
                                                      Text(
                                                        Provider.of<ZLanguage>(
                                                                context,
                                                                listen: false)
                                                            .thankYou,
                                                        textAlign:
                                                            TextAlign.center,
                                                      )
                                                    ],
                                                  )
                                                : Column(
                                                    children: [
                                                      IconButton(
                                                          icon: Icon(Icons
                                                              .star_border),
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) {
                                                                  return OrderRating(
                                                                    userId: widget
                                                                        .userId!,
                                                                    orderId: widget
                                                                        .orderId!,
                                                                    serverToken:
                                                                        widget
                                                                            .serverToken!,
                                                                    imageUrl:
                                                                        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['provider_detail']['image_url']}",
                                                                    name:
                                                                        "${responseData['provider_detail']['first_name']} ${responseData['provider_detail']['last_name']}",
                                                                    isStore:
                                                                        false,
                                                                  );
                                                                },
                                                              ),
                                                            ).then((value) =>
                                                                getUser());
                                                          }),
                                                      Text(Provider.of<
                                                                  ZLanguage>(
                                                              context,
                                                              listen: false)
                                                          .rateUs),
                                                    ],
                                                  )
                                          ],
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical:
                                              getProportionateScreenHeight(
                                                  kDefaultPadding / 2)),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          // borderRadius: BorderRadius.circular(
                                          //     getProportionateScreenWidth(
                                          //         kDefaultPadding)),
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding / 2)),
                                            child: Text(
                                              "${order_status['${responseData['order_list']['order_status']}']}",
                                              style: TextStyle(
                                                  color: kSecondaryColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              Container(
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  // borderRadius: BorderRadius.circular(
                                  //   getProportionateScreenWidth(
                                  //       kDefaultPadding),
                                  // ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      getProportionateScreenWidth(
                                          kDefaultPadding)),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.tour_outlined,
                                            size: getProportionateScreenHeight(
                                                kDefaultPadding / .75),
                                            color: kSecondaryColor,
                                          ),
                                          SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 3)),
                                          Expanded(
                                            child: Text(
                                              responseData['order_list']
                                                          ['cart_detail']
                                                      ['pickup_addresses'][0]
                                                  ['address'],
                                              softWrap: true,
                                            ),
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.tour,
                                            size: getProportionateScreenHeight(
                                                kDefaultPadding / .75),
                                          ),
                                          SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 3)),
                                          Expanded(
                                            child: Text(
                                              responseData['order_list']
                                                          ['cart_detail']
                                                      ['destination_addresses']
                                                  [0]['address'],
                                              softWrap: true,
                                            ),
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: getProportionateScreenHeight(
                                                kDefaultPadding / .75),
                                            color: kSecondaryColor,
                                          ),
                                          SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 3)),
                                          Text(
                                            "${responseData['order_list']['order_payment_detail']['total_time'].toStringAsFixed(2)} mins",
                                            softWrap: true,
                                          )
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.delivery_dining,
                                            size: getProportionateScreenHeight(
                                                kDefaultPadding / .75),
                                          ),
                                          SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 3)),
                                          Text(
                                            "${responseData['order_list']['order_payment_detail']['total_distance'].toStringAsFixed(2)} KM",
                                            softWrap: true,
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding)),
                              Container(
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  // borderRadius: BorderRadius.circular(
                                  //     getProportionateScreenWidth(
                                  //         kDefaultPadding)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: getProportionateScreenHeight(
                                          kDefaultPadding),
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding / 2)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Provider.of<ZLanguage>(context,
                                                listen: false)
                                            .enjoyingZmall,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2),
                                      ),
                                      Text(
                                        Provider.of<ZLanguage>(context,
                                                listen: false)
                                            .rateReviewBlock,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                        textAlign: TextAlign.justify,
                                      ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2),
                                      ),
                                      CustomButton(
                                        title: Provider.of<ZLanguage>(context,
                                                listen: false)
                                            .rateUs,
                                        press: () {
                                          _rateMyApp.showStarRateDialog(
                                            context,
                                            title: "Enjoying ZMall?",
                                            message: "Please leave a rating!",
                                            dialogStyle: DialogStyle(
                                              titleAlign: TextAlign.center,
                                              messageAlign: TextAlign.center,
                                              messagePadding:
                                                  EdgeInsets.only(bottom: 20.0),
                                            ),
                                            starRatingOptions:
                                                StarRatingOptions(
                                              initialRating: 5,
                                            ),
                                            actionsBuilder: actionsBuilder,
                                          );
                                        },
                                        color: kSecondaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      : Container(),
                  responseData != null
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    SizedBox(width: kDefaultPadding / 4),
                                    Text(
                                        "${responseData['order_list']['order_payment_detail']['total_time'].toStringAsFixed(2)} mins")
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.delivery_dining,
                                      size: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    SizedBox(width: kDefaultPadding / 4),
                                    Text(
                                        "${responseData['order_list']['order_payment_detail']['total_distance'].toStringAsFixed(2)} KM")
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      size: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    SizedBox(width: kDefaultPadding / 4),
                                    Text(Provider.of<ZLanguage>(context,
                                            listen: false)
                                        .cash)
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding)),
                            Container(
                              width: double.infinity,
                              height: .1,
                              color: kBlackColor,
                            ),
                            SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding)),
                            Container(
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                // borderRadius: BorderRadius.circular(
                                //     getProportionateScreenWidth(
                                //         kDefaultPadding)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: getProportionateScreenHeight(
                                      kDefaultPadding),
                                  horizontal: getProportionateScreenWidth(
                                      kDefaultPadding / 2),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(Provider.of<ZLanguage>(context,
                                                listen: false)
                                            .servicePrice),
                                        Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_service_price'].toStringAsFixed(2)}"),
                                      ],
                                    ),
                                    SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 4)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          Provider.of<ZLanguage>(context,
                                                  listen: false)
                                              .totalServicePrive,
                                          style:
                                              TextStyle(color: kSecondaryColor),
                                        ),
                                        Text(
                                          "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_service_price'].toStringAsFixed(2)}",
                                          style:
                                              TextStyle(color: kSecondaryColor),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 4)),
                                    responseData['order_list']
                                                    ['order_payment_detail']
                                                ['promo_payment'] !=
                                            0
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(Provider.of<ZLanguage>(
                                                      context,
                                                      listen: false)
                                                  .promo),
                                              Text(
                                                  "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['promo_payment'].toStringAsFixed(2)}"),
                                            ],
                                          )
                                        : Container(),
                                    responseData['order_list']
                                                    ['order_payment_detail']
                                                ['promo_payment'] !=
                                            0
                                        ? SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 4))
                                        : Container(),
                                    responseData['order_list']
                                                    ['order_payment_detail']
                                                ['promo_payment'] !=
                                            0
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                Provider.of<ZLanguage>(context,
                                                        listen: false)
                                                    .totalPromo,
                                                style: TextStyle(
                                                    color: kSecondaryColor),
                                              ),
                                              Text(
                                                "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['promo_payment'].toStringAsFixed(2)}",
                                                style: TextStyle(
                                                    color: kSecondaryColor),
                                              ),
                                            ],
                                          )
                                        : Container(),
                                    responseData['order_list']
                                                    ['order_payment_detail']
                                                ['promo_payment'] !=
                                            0
                                        ? SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 4))
                                        : Container(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(Provider.of<ZLanguage>(context,
                                                listen: false)
                                            .cartPrice),
                                        Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_cart_price'].toStringAsFixed(2)}"),
                                      ],
                                    ),
                                    SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 4)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          Provider.of<ZLanguage>(context,
                                                  listen: false)
                                              .totalCartPrice,
                                          style:
                                              TextStyle(color: kSecondaryColor),
                                        ),
                                        Text(
                                          "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_cart_price'].toStringAsFixed(2)}",
                                          style:
                                              TextStyle(color: kSecondaryColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Spacer(),
                            Container(
                              width: double.infinity,
                              height: .1,
                              color: kBlackColor,
                            ),
                            SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding)),
                            Row(
                              mainAxisAlignment: responseData['order_list']
                                              ['order_payment_detail']
                                          ['promo_payment'] !=
                                      0
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    responseData['order_list']
                                                ['order_payment_detail']
                                            ['is_paid_from_wallet']
                                        ? Icon(
                                            Icons
                                                .account_balance_wallet_outlined,
                                            size: getProportionateScreenHeight(
                                                kDefaultPadding),
                                          )
                                        : Icon(
                                            Icons.mobile_friendly,
                                            size: getProportionateScreenHeight(
                                                kDefaultPadding),
                                          ),
                                    SizedBox(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding / 2)),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        responseData['order_list']
                                                    ['order_payment_detail']
                                                ['is_paid_from_wallet']
                                            ? Text(Provider.of<ZLanguage>(
                                                    context,
                                                    listen: false)
                                                .wallet)
                                            : Text(Provider.of<ZLanguage>(
                                                    context,
                                                    listen: false)
                                                .online),
                                        responseData['order_list']
                                                    ['order_payment_detail']
                                                ['is_paid_from_wallet']
                                            ? Text(
                                                "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['wallet_payment'].toStringAsFixed(2)}")
                                            : Text(
                                                "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['card_payment'].toStringAsFixed(2)}"),
                                      ],
                                    )
                                  ],
                                ),
                                responseData['order_list']
                                                ['order_payment_detail']
                                            ['promo_payment'] !=
                                        0
                                    ? Row(
                                        children: [
                                          Icon(
                                            Icons.card_giftcard_outlined,
                                            size: getProportionateScreenHeight(
                                                kDefaultPadding),
                                          ),
                                          SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 2)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(Provider.of<ZLanguage>(
                                                      context,
                                                      listen: false)
                                                  .promo),
                                              Text(
                                                  "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['promo_payment'].toStringAsFixed(2)}"),
                                            ],
                                          )
                                        ],
                                      )
                                    : Container(),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.money_outlined,
                                      size: getProportionateScreenHeight(
                                          kDefaultPadding),
                                    ),
                                    SizedBox(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding / 2)),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(Provider.of<ZLanguage>(context,
                                                listen: false)
                                            .cash),
                                        Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['cash_payment'].toStringAsFixed(2)}"),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                            SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding / 2)),
                            Column(
                              children: [
                                Text(Provider.of<ZLanguage>(context,
                                        listen: false)
                                    .total),
                                Text(
                                  "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total'].toStringAsFixed(2)}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(responseData['payment_gateway_name']
                                    .toString()
                                    .toUpperCase()),
                              ],
                            ),
                            SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding / 2)),
                            responseData['order_list']
                                        ['is_user_show_invoice'] ||
                                    responseData['order_list']
                                            ['order_status'] !=
                                        25
                                ? Container()
                                : CustomButton(
                                    title: Provider.of<ZLanguage>(context,
                                            listen: false)
                                        .submit,
                                    press: () {},
                                    color: kBlackColor,
                                  ),
                            responseData['order_list']
                                        ['is_user_show_invoice'] ||
                                    responseData['order_list']
                                            ['order_status'] !=
                                        25
                                ? Container()
                                : SizedBox(
                                    height: getProportionateScreenWidth(
                                        kDefaultPadding / 2)),
                          ],
                        )
                      : Container(),
                  responseData != null
                      ? Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: responseData['order_list']
                                        ['cart_detail']['order_details']
                                    .length,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      CategoryContainer(
                                          title: responseData['order_list']
                                                              ['cart_detail']
                                                          ['order_details']
                                                      [index]['product_name'] !=
                                                  null
                                              ? responseData['order_list']
                                                          ['cart_detail']
                                                      ['order_details'][index]
                                                  ['product_name']
                                              : responseData['order_list']
                                                          ['cart_detail']
                                                      ['order_details'][index]
                                                  ['product_detail']['name']),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 3)),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          // borderRadius: BorderRadius.circular(
                                          //   getProportionateScreenWidth(
                                          //       kDefaultPadding),
                                          // ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                getProportionateScreenWidth(
                                                    kDefaultPadding / 2),
                                            vertical:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding),
                                          ),
                                          child: ListView.builder(
                                            physics: ClampingScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount:
                                                responseData['order_list']
                                                                ['cart_detail']
                                                            ['order_details']
                                                        [index]['items']
                                                    .length,
                                            itemBuilder: (context, idx) {
                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "${responseData['order_list']['cart_detail']['order_details'][index]['items'][idx]['item_name']}",
                                                          softWrap: true,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                        ),
                                                        Text(
                                                          "${Provider.of<ZLanguage>(context, listen: false).quantity}: ${responseData['order_list']['cart_detail']['order_details'][index]['items'][idx]['quantity']}",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_list']['cart_detail']['order_details'][index]['items'][idx]['total_price'].toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  )
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 2)),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 0.1,
                              color: kSecondaryColor,
                            ),
//                            Spacer(flex: 1),
//                            CustomButton(
//                              title: "REORDER",
//                              press: () {},
//                              color: kSecondaryColor,
//                            )
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> getDetail() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/order_history_detail";

    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "order_id": widget.orderId,
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
      if (json.decode(response.body) != null) {
        setState(() {
          responseData = json.decode(response.body);
        });
      }
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
}
