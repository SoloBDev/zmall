import 'dart:async';
import 'dart:convert';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/orders/components/order_rating.dart';
import 'package:zmall/widgets/order_status_row.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';

class OrderHistoryDetail extends StatefulWidget {
  static String routeName = '/order_history_detail';

  @override
  _OrderHistoryDetailState createState() => _OrderHistoryDetailState();

  const OrderHistoryDetail({
    super.key,
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
    minLaunches: 3, //5
    minDays: 0, //7
    remindLaunches: 3, //5
    remindDays: 2, //3
    appStoreIdentifier: 'com.enigma.zmall',
    googlePlayIdentifier: 'com.enigma.zmall',
  );
  @override
  void initState() {
    super.initState();
    getUser();
    _rateMyApp.init().then(
      (_) => {
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
            ),
          },
      },
    );
  }

  List<Widget> actionsBuilder(BuildContext context, double? stars) =>
      stars == null
      ? [buildCancelButton()]
      : [buildOkButton(stars), buildCancelButton()];

  Widget buildOkButton(double stars) => TextButton(
    child: Text('OK'),
    onPressed: () async {
      final launchAppStore = stars >= 4;

      Service.showMessage(
        context: context,
        title: "Thanks for your feedback!",
        error: true,
      );
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
    // debugPrint("Fetching order detail");
    var data = await getDetail();
    if (data != null) {
      setState(() {
        responseData = data;
      });
      // debugPrint(
      //     "fdsa??? ${responseData['order_list']['cart_detail']['destination_addresses'][0]['user_details']}");
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
                      HeroiconsOutline.bars3BottomLeft,
                      color: kSecondaryColor,
                    ),
                    Text(
                      Provider.of<ZLanguage>(context, listen: false).details,
                      style: TextStyle(color: kBlackColor),
                    ),
                  ],
                ),
              ),
              Tab(
                icon: Column(
                  children: [
                    Icon(HeroiconsOutline.documentText, color: kSecondaryColor),
                    Text(
                      Provider.of<ZLanguage>(context, listen: false).invoice,
                      style: TextStyle(color: kBlackColor),
                    ),
                  ],
                ),
              ),
              Tab(
                icon: Column(
                  children: [
                    Icon(HeroiconsOutline.shoppingBag, color: kSecondaryColor),
                    Text(
                      Provider.of<ZLanguage>(context, listen: false).cart,
                      style: TextStyle(color: kBlackColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: ModalProgressHUD(
            inAsyncCall: _loading,

            progressIndicator: LinearLoadingIndicator(),
            // progressIndicator: userData != null && responseData != null
            //     ? LinearLoadingIndicator()
            //     : ProductListShimmer(),
            color: kPrimaryColor,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: EdgeInsets.all(
                  getProportionateScreenWidth(kDefaultPadding / 2),
                ),
                child: TabBarView(
                  children: [
                    /////order histry detail
                    responseData != null
                        ? SingleChildScrollView(
                            child: Column(
                              spacing: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                              children: [
                                ///////Order Details section/////
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: getProportionateScreenHeight(
                                      kDefaultPadding / 1.5,
                                    ),
                                    horizontal: getProportionateScreenWidth(
                                      kDefaultPadding,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    border: Border.all(color: kWhiteColor),
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(
                                        kDefaultPadding,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: getProportionateScreenHeight(
                                      kDefaultPadding,
                                    ),
                                    children: [
                                      Row(
                                        spacing: getProportionateScreenWidth(
                                          kDefaultPadding / 2,
                                        ),
                                        children: [
                                          Icon(
                                            HeroiconsOutline
                                                .clipboardDocumentCheck,
                                            color: kBlackColor,
                                          ),
                                          Text(
                                            Provider.of<ZLanguage>(
                                              context,
                                              listen: false,
                                            ).orderDetails,
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenHeight(
                                                    kDefaultPadding,
                                                  ),
                                              color: kBlackColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (responseData['store_detail']['name'] ==
                                              null)
                                            Flexible(
                                              child: OrderStatusRow(
                                                icon: HeroiconsOutline.user,
                                                value:
                                                    "${Service.capitalizeFirstLetters(responseData['order_list']['cart_detail']['pickup_addresses'][0]['user_details']['name'])}",
                                                title: "From",
                                              ),
                                            ),
                                          Flexible(
                                            child: OrderStatusRow(
                                              icon: HeroiconsOutline.user,
                                              value: Service.capitalizeFirstLetters(
                                                responseData['order_list']['cart_detail']['destination_addresses'][0]['user_details']['name'],
                                              ),
                                              title: Provider.of<ZLanguage>(
                                                context,
                                                listen: false,
                                              ).receivedBy,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (responseData['store_detail']['name'] !=
                                          null)
                                        orderDetailRow(
                                          isStore: true,
                                          isRated:
                                              responseData['order_list']['is_user_rated_to_store'],
                                          isCompleted:
                                              responseData['order_list']['order_status'] ==
                                              25,
                                          value:
                                              responseData['store_detail']['name'] !=
                                                  null
                                              ? "${Service.capitalizeFirstLetters(responseData['store_detail']['name'])}"
                                              : "${Service.capitalizeFirstLetters(responseData['order_list']['cart_detail']['pickup_addresses'][0]['user_details']['name'])}",
                                          imageUrl:
                                              "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['store_detail']['image_url']}",
                                          onRatePressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  return OrderRating(
                                                    userId: widget.userId!,
                                                    orderId: widget.orderId!,
                                                    serverToken:
                                                        widget.serverToken!,
                                                    imageUrl:
                                                        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['store_detail']['image_url']}",
                                                    name:
                                                        "${responseData['store_detail']['name']}",
                                                    isStore: true,
                                                  );
                                                },
                                              ),
                                            ).then((value) => getUser());
                                          },
                                        ),
                                    ],
                                  ),
                                ),

                                ///////Delivery Details section/////
                                Container(
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    border: Border.all(color: kWhiteColor),
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(
                                        kDefaultPadding,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: getProportionateScreenHeight(
                                        kDefaultPadding / 1.5,
                                      ),
                                      horizontal: getProportionateScreenWidth(
                                        kDefaultPadding,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: getProportionateScreenHeight(
                                        kDefaultPadding,
                                      ),
                                      children: [
                                        Row(
                                          spacing: getProportionateScreenWidth(
                                            kDefaultPadding / 2,
                                          ),
                                          children: [
                                            Icon(
                                              HeroiconsOutline.truck,
                                              color: kBlackColor,
                                            ),
                                            Text(
                                              Provider.of<ZLanguage>(
                                                context,
                                                listen: false,
                                              ).deliveryDetails,
                                              style: TextStyle(
                                                fontSize:
                                                    getProportionateScreenHeight(
                                                      kDefaultPadding,
                                                    ),
                                                color: kBlackColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (responseData['order_list']['order_status'] ==
                                            25)
                                          orderDetailRow(
                                            isStore: false,
                                            isCompleted:
                                                responseData['order_list']['order_status'] ==
                                                25,
                                            value:
                                                "${responseData['provider_detail']['first_name']} ${responseData['provider_detail']['last_name']}",
                                            isRated:
                                                responseData['order_list']['is_user_rated_to_provider'],
                                            imageUrl:
                                                "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['provider_detail']['image_url']}",
                                            onRatePressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return OrderRating(
                                                      userId: widget.userId!,
                                                      orderId: widget.orderId!,
                                                      serverToken:
                                                          widget.serverToken!,
                                                      imageUrl:
                                                          "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${responseData['provider_detail']['image_url']}",
                                                      name:
                                                          "${responseData['provider_detail']['first_name']} ${responseData['provider_detail']['last_name']}",
                                                      isStore: false,
                                                    );
                                                  },
                                                ),
                                              ).then((value) => getUser());
                                            },
                                          ),
                                        // Padding(
                                        //     padding: EdgeInsets.symmetric(
                                        //         vertical:
                                        //             getProportionateScreenHeight(
                                        //                 kDefaultPadding /
                                        //                     2)),
                                        //     child: OrderStatusRow(
                                        //       icon:
                                        //           HeroiconsOutline.xCircle,
                                        //       value:
                                        //           "${order_status['${responseData['order_list']['order_status']}']}",
                                        //       title: "Order Status",
                                        //     ),
                                        //  Row(
                                        //   spacing:
                                        //       getProportionateScreenWidth(
                                        //           kDefaultPadding / 2),
                                        //   children: [
                                        //     Icon(
                                        //       HeroiconsOutline.xCircle,
                                        //       color: kSecondaryColor,
                                        //       size:
                                        //           getProportionateScreenWidth(
                                        //         17,
                                        //       ),
                                        //     ),
                                        //     Text(
                                        //       "${order_status['${responseData['order_list']['order_status']}']}",
                                        //       style: TextStyle(
                                        //           color:
                                        //               kSecondaryColor),
                                        //     ),
                                        //   ],
                                        // ),
                                        // ),
                                        ////////Address Section
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: getProportionateScreenHeight(
                                            kDefaultPadding,
                                          ),
                                          children: [
                                            if (responseData['order_list']['order_status'] !=
                                                25)
                                              OrderStatusRow(
                                                icon: HeroiconsOutline.xCircle,
                                                value:
                                                    "${order_status['${responseData['order_list']['order_status']}']}",
                                                title: "Order Status",
                                              ),
                                            OrderStatusRow(
                                              icon: HeroiconsOutline.mapPin,
                                              value:
                                                  responseData['order_list']['cart_detail']['destination_addresses'][0]['address'],
                                              title: "Delivery Address",
                                            ),
                                            OrderStatusRow(
                                              icon: HeroiconsOutline.mapPin,
                                              value:
                                                  responseData['order_list']['cart_detail']['pickup_addresses'][0]['address'],
                                              title: "Pickup address",
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: OrderStatusRow(
                                                    icon:
                                                        HeroiconsOutline.clock,
                                                    value:
                                                        "${responseData['order_list']['order_payment_detail']['total_time'].toStringAsFixed(2)} mins",
                                                    title: "Time",
                                                  ),
                                                ),
                                                Flexible(
                                                  child: OrderStatusRow(
                                                    icon:
                                                        HeroiconsOutline.truck,
                                                    value:
                                                        "${responseData['order_list']['order_payment_detail']['total_distance'].toStringAsFixed(2)} KM",
                                                    title: "Distance",
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // addressDetailRow(
                                            //   icon: HeroiconsOutline.mapPin,
                                            //   iconColor: kBlackColor,
                                            //   title: responseData['order_list']
                                            //               ['cart_detail']
                                            //           ['pickup_addresses'][0]
                                            //       ['address'],
                                            // ),
                                            // Container(
                                            //   margin: EdgeInsets.only(
                                            //       left:
                                            //           getProportionateScreenWidth(
                                            //               kDefaultPadding /
                                            //                   1.5)),
                                            //   color: kSecondaryColor,
                                            //   height:
                                            //       getProportionateScreenHeight(
                                            //           kDefaultPadding),
                                            //   width:
                                            //       getProportionateScreenHeight(
                                            //           1),
                                            // ),
                                            // addressDetailRow(
                                            //   icon: HeroiconsOutline.mapPin,
                                            //   iconColor: kSecondaryColor,
                                            // title: responseData['order_list']
                                            //             ['cart_detail']
                                            //         ['destination_addresses']
                                            //     [0]['address'],
                                            // ),
                                            // addressDetailRow(
                                            //   icon: HeroiconsOutline.clock,
                                            //   iconColor: kSecondaryColor,
                                            //   title:
                                            //       "${responseData['order_list']['order_payment_detail']['total_time'].toStringAsFixed(2)} mins",
                                            // ),
                                            // addressDetailRow(
                                            //   icon: HeroiconsOutline.truck,
                                            //   title:
                                            //       "${responseData['order_list']['order_payment_detail']['total_distance'].toStringAsFixed(2)} KM",
                                            // )
                                          ],
                                          // ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                ////Rate ZMall App section/////
                                Container(
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    border: Border.all(color: kWhiteColor),
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(
                                        kDefaultPadding,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: getProportionateScreenHeight(
                                        kDefaultPadding / 1.5,
                                      ),
                                      horizontal: getProportionateScreenWidth(
                                        kDefaultPadding,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: getProportionateScreenHeight(
                                        kDefaultPadding / 2,
                                      ),
                                      children: [
                                        Text(
                                          Provider.of<ZLanguage>(
                                            context,
                                            listen: false,
                                          ).enjoyingZmall,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          Provider.of<ZLanguage>(
                                            context,
                                            listen: false,
                                          ).rateReviewBlock,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                          textAlign: TextAlign.justify,
                                        ),
                                        CustomButton(
                                          title: Provider.of<ZLanguage>(
                                            context,
                                            listen: false,
                                          ).rateUs,
                                          press: () {
                                            _rateMyApp.showStarRateDialog(
                                              context,
                                              title: "Enjoying ZMall?",
                                              message: "Please leave a rating!",
                                              dialogStyle: DialogStyle(
                                                titleAlign: TextAlign.center,
                                                messageAlign: TextAlign.center,
                                                messagePadding: EdgeInsets.only(
                                                  bottom: 20.0,
                                                ),
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
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    ////////////////Invoice Tab section/////////////////
                    if (responseData != null)
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                kDefaultPadding,
                              ),
                              horizontal: getProportionateScreenWidth(
                                kDefaultPadding / 2,
                              ),
                            ),
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
                              spacing: getProportionateScreenWidth(
                                kDefaultPadding / 2,
                              ),
                              children: [
                                Flexible(
                                  child: OrderStatusRow(
                                    icon: HeroiconsOutline.clock,
                                    value:
                                        "${responseData['order_list']['order_payment_detail']['total_time'].toStringAsFixed(2)}min",
                                    title: "Time",
                                  ),
                                ),
                                Flexible(
                                  child: OrderStatusRow(
                                    icon: HeroiconsOutline.truck,
                                    value:
                                        "${responseData['order_list']['order_payment_detail']['total_distance'].toStringAsFixed(2)} KM",
                                    title: "Distance",
                                  ),
                                ),
                                Flexible(
                                  child: OrderStatusRow(
                                    icon: HeroiconsOutline.creditCard,
                                    value: Service.capitalizeFirstLetters(
                                      Provider.of<ZLanguage>(
                                        context,
                                        listen: false,
                                      ).cash,
                                    ),
                                    title: Provider.of<ZLanguage>(
                                      context,
                                      listen: false,
                                    ).payments,
                                  ),
                                ),
                                // Row(
                                //   children: [
                                //     Icon(
                                //       Icons.access_time,
                                //       size: getProportionateScreenWidth(
                                //           kDefaultPadding),
                                //     ),
                                //     SizedBox(width: kDefaultPadding / 4),
                                //     Text(
                                //         "${responseData['order_list']['order_payment_detail']['total_time'].toStringAsFixed(2)} mins")
                                //   ],
                                // ),
                                // Row(
                                //   children: [
                                //     Icon(
                                //       Icons.delivery_dining,
                                //       size: getProportionateScreenWidth(
                                //           kDefaultPadding),
                                //     ),
                                //     SizedBox(width: kDefaultPadding / 4),
                                //     Text(
                                //         "${responseData['order_list']['order_payment_detail']['total_distance'].toStringAsFixed(2)} KM")
                                //   ],
                                // ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                          ),

                          ///total prices///
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                kDefaultPadding,
                              ),
                              horizontal: getProportionateScreenWidth(
                                kDefaultPadding,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              border: Border.all(color: kWhiteColor),
                              borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(
                                  kDefaultPadding / 1.5,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Provider.of<ZLanguage>(
                                        context,
                                        listen: false,
                                      ).servicePrice,
                                    ),
                                    Text(
                                      "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_service_price'].toStringAsFixed(2)}",
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding / 4,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Provider.of<ZLanguage>(
                                        context,
                                        listen: false,
                                      ).totalServicePrive,
                                      style: TextStyle(color: kSecondaryColor),
                                    ),
                                    Text(
                                      "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_service_price'].toStringAsFixed(2)}",
                                      style: TextStyle(color: kSecondaryColor),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding / 4,
                                  ),
                                ),
                                responseData['order_list']['order_payment_detail']['promo_payment'] !=
                                        0
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            Provider.of<ZLanguage>(
                                              context,
                                              listen: false,
                                            ).promo,
                                          ),
                                          Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['promo_payment'].toStringAsFixed(2)}",
                                          ),
                                        ],
                                      )
                                    : Container(),
                                responseData['order_list']['order_payment_detail']['promo_payment'] !=
                                        0
                                    ? SizedBox(
                                        height: getProportionateScreenHeight(
                                          kDefaultPadding / 4,
                                        ),
                                      )
                                    : Container(),
                                responseData['order_list']['order_payment_detail']['promo_payment'] !=
                                        0
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            Provider.of<ZLanguage>(
                                              context,
                                              listen: false,
                                            ).totalPromo,
                                            style: TextStyle(
                                              color: kSecondaryColor,
                                            ),
                                          ),
                                          Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['promo_payment'].toStringAsFixed(2)}",
                                            style: TextStyle(
                                              color: kSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(),
                                responseData['order_list']['order_payment_detail']['promo_payment'] !=
                                        0
                                    ? SizedBox(
                                        height: getProportionateScreenHeight(
                                          kDefaultPadding / 4,
                                        ),
                                      )
                                    : Container(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Provider.of<ZLanguage>(
                                        context,
                                        listen: false,
                                      ).cartPrice,
                                    ),
                                    Text(
                                      "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_cart_price'].toStringAsFixed(2)}",
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding / 4,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Provider.of<ZLanguage>(
                                        context,
                                        listen: false,
                                      ).totalCartPrice,
                                      style: TextStyle(color: kSecondaryColor),
                                    ),
                                    Text(
                                      "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total_cart_price'].toStringAsFixed(2)}",
                                      style: TextStyle(color: kSecondaryColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Spacer(),

                          ///////payments and total price////
                          SizedBox(
                            height: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                kDefaultPadding,
                              ),
                              horizontal: getProportionateScreenWidth(
                                kDefaultPadding,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              border: Border.all(color: kWhiteColor),
                              borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(
                                  kDefaultPadding / 1.5,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      responseData['order_list']['order_payment_detail']['promo_payment'] !=
                                          0
                                      ? MainAxisAlignment.spaceBetween
                                      : MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ////degital payment section
                                    Row(
                                      children: [
                                        responseData['order_list']['order_payment_detail']['is_paid_from_wallet']
                                            ? Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                                size:
                                                    getProportionateScreenHeight(
                                                      kDefaultPadding,
                                                    ),
                                              )
                                            : Icon(
                                                HeroiconsOutline
                                                    .devicePhoneMobile,
                                                size:
                                                    getProportionateScreenHeight(
                                                      kDefaultPadding,
                                                    ),
                                              ),
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                            kDefaultPadding / 2,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            responseData['order_list']['order_payment_detail']['is_paid_from_wallet']
                                                ? Text(
                                                    Provider.of<ZLanguage>(
                                                      context,
                                                      listen: false,
                                                    ).wallet,
                                                  )
                                                : Text(
                                                    Provider.of<ZLanguage>(
                                                      context,
                                                      listen: false,
                                                    ).online,
                                                  ),
                                            responseData['order_list']['order_payment_detail']['is_paid_from_wallet']
                                                ? Text(
                                                    "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['wallet_payment'].toStringAsFixed(2)}",
                                                  )
                                                : Text(
                                                    "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['card_payment'].toStringAsFixed(2)}",
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    /////Promo payment section
                                    responseData['order_list']['order_payment_detail']['promo_payment'] !=
                                            0
                                        ? Row(
                                            children: [
                                              Icon(
                                                HeroiconsOutline.gift,
                                                size:
                                                    getProportionateScreenHeight(
                                                      kDefaultPadding,
                                                    ),
                                              ),
                                              SizedBox(
                                                width:
                                                    getProportionateScreenWidth(
                                                      kDefaultPadding / 2,
                                                    ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    Provider.of<ZLanguage>(
                                                      context,
                                                      listen: false,
                                                    ).promo,
                                                  ),
                                                  Text(
                                                    "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['promo_payment'].toStringAsFixed(2)}",
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : Container(),
                                    ////cash payment section
                                    Row(
                                      children: [
                                        Icon(
                                          HeroiconsOutline.banknotes,
                                          size: getProportionateScreenHeight(
                                            kDefaultPadding,
                                          ),
                                        ),
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                            kDefaultPadding / 2,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              Service.capitalizeFirstLetters(
                                                Provider.of<ZLanguage>(
                                                  context,
                                                  listen: false,
                                                ).cash,
                                              ),
                                            ),
                                            Text(
                                              "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['cash_payment'].toStringAsFixed(2)}",
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: getProportionateScreenWidth(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      Service.capitalizeFirstLetters(
                                        responseData['payment_gateway_name']
                                            .toString(),
                                      ),
                                    ),
                                    Text(
                                      "${Provider.of<ZMetaData>(context, listen: false).currency}  ${responseData['order_list']['order_payment_detail']['total'].toStringAsFixed(2)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      Provider.of<ZLanguage>(
                                        context,
                                        listen: false,
                                      ).total,
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: getProportionateScreenWidth(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                                responseData['order_list']['is_user_show_invoice'] ||
                                        responseData['order_list']['order_status'] !=
                                            25
                                    ? Container()
                                    : Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: getProportionateScreenWidth(
                                            kDefaultPadding / 2,
                                          ),
                                        ),
                                        child: CustomButton(
                                          title: Provider.of<ZLanguage>(
                                            context,
                                            listen: false,
                                          ).submit,
                                          press: () {},
                                          color: kBlackColor,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    ////////////////Cart Tab section/////////////////
                    responseData != null
                        ? Column(
                            children: [
                              //      padding: EdgeInsets.symmetric(
                              //   vertical:
                              //       getProportionateScreenHeight(kDefaultPadding),
                              //   horizontal:
                              //       getProportionateScreenWidth(kDefaultPadding),
                              // ),
                              // decoration: BoxDecoration(
                              //     color: kPrimaryColor,
                              //     border: Border.all(color: kWhiteColor),
                              //     borderRadius: BorderRadius.circular(
                              //         getProportionateScreenWidth(
                              //             kDefaultPadding / 1.5))),
                              Expanded(
                                flex: 3,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount:
                                      responseData['order_list']['cart_detail']['order_details']
                                          .length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                          kDefaultPadding / 2,
                                        ),
                                      ),
                                  itemBuilder: (context, index) {
                                    String extractProductName(
                                      String? noteForItem,
                                    ) {
                                      if (noteForItem == null ||
                                          noteForItem.isEmpty)
                                        return '';
                                      return noteForItem.split(': ').first;
                                    }

                                    return Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: getProportionateScreenHeight(
                                          kDefaultPadding,
                                        ),
                                        horizontal: getProportionateScreenWidth(
                                          kDefaultPadding,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor,
                                        border: Border.all(color: kWhiteColor),
                                        borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(
                                            kDefaultPadding,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: getProportionateScreenHeight(
                                          kDefaultPadding / 3,
                                        ),
                                        children: [
                                          CategoryContainer(
                                            title:
                                                responseData['order_list']['cart_detail']['order_details'][index]['product_name']
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "aliexpress"
                                                ? "${Service.capitalizeFirstLetters(extractProductName(responseData['order_list']['cart_detail']['order_details'][index]['items'][0]['note_for_item']))}"
                                                : responseData['order_list']['cart_detail']['order_details'][index]['product_name'] !=
                                                      null
                                                ? Service.capitalizeFirstLetters(
                                                    responseData['order_list']['cart_detail']['order_details'][index]['product_name'],
                                                  )
                                                : Service.capitalizeFirstLetters(
                                                    responseData['order_list']['cart_detail']['order_details'][index]['product_detail']['name'],
                                                  ),
                                          ),
                                          // title: responseData['order_list']
                                          //                     ['cart_detail']
                                          //                 ['order_details']
                                          //             [index]['product_name'] !=
                                          //         null
                                          //     ? responseData['order_list']
                                          //                 ['cart_detail']
                                          //             ['order_details'][index]
                                          //         ['product_name']
                                          //     : responseData['order_list']
                                          //                 ['cart_detail']
                                          //             ['order_details'][index]
                                          //         ['product_detail']['name']),
                                          // SizedBox(
                                          //     height:
                                          //         getProportionateScreenHeight(
                                          //             kDefaultPadding / 3)),
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    getProportionateScreenWidth(
                                                      kDefaultPadding,
                                                    ),
                                                  ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    getProportionateScreenWidth(
                                                      kDefaultPadding / 2,
                                                    ),
                                                vertical:
                                                    getProportionateScreenHeight(
                                                      kDefaultPadding,
                                                    ),
                                              ),
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                physics:
                                                    ClampingScrollPhysics(),
                                                separatorBuilder:
                                                    (context, index) => Divider(
                                                      color: kWhiteColor,
                                                    ),
                                                itemCount:
                                                    responseData['order_list']['cart_detail']['order_details'][index]['items']
                                                        .length,
                                                itemBuilder: (context, idx) {
                                                  String extractItemName(
                                                    String? noteForItem,
                                                  ) {
                                                    if (noteForItem == null ||
                                                        noteForItem.isEmpty)
                                                      return '';
                                                    var parts = noteForItem
                                                        .split(': ');
                                                    return parts.length >= 3
                                                        ? "${parts[2]}:\n${parts[1]}"
                                                        : parts.length >= 2
                                                        ? "${parts[1]}"
                                                        : '';
                                                  }

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
                                                              responseData['order_list']['cart_detail']['order_details'][index]['product_name']
                                                                          .toString()
                                                                          .toLowerCase() ==
                                                                      "aliexpress"
                                                                  ? "${extractItemName(responseData['order_list']['cart_detail']['order_details'][index]['items'][idx]['note_for_item'])}"
                                                                  : "${Service.capitalizeFirstLetters(responseData['order_list']['cart_detail']['order_details'][index]['items'][idx]['item_name'])}",
                                                              softWrap: true,
                                                              style: Theme.of(context)
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
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .bodySmall,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        "${Provider.of<ZMetaData>(context, listen: false).currency} ${responseData['order_list']['cart_detail']['order_details'][index]['items'][idx]['total_price'].toStringAsFixed(2)}",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          // SizedBox(
                                          //     height:
                                          //         getProportionateScreenHeight(
                                          //             kDefaultPadding / 2)),
                                        ],
                                      ),
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
              "Accept": "application/json",
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

  Widget addressDetailRow({
    required IconData icon,
    required String title,
    Color? iconColor,
  }) {
    return Row(
      spacing: getProportionateScreenWidth(kDefaultPadding / 2),
      children: [
        Icon(
          icon,
          size: getProportionateScreenHeight(kDefaultPadding / .75),
          color: iconColor ?? kBlackColor,
        ),
        Expanded(child: Text(title, softWrap: true)),
      ],
    );
  }

  Widget orderDetailRow({
    required bool isRated,
    required bool isStore,
    required String imageUrl,
    // required String userName,
    required String value,
    required bool isCompleted,
    required void Function() onRatePressed,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: getProportionateScreenHeight(kDefaultPadding / 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: getProportionateScreenWidth(kDefaultPadding / 2),
        children: [
          ImageContainer(
            fit: BoxFit.fill,
            url: imageUrl,
            shape: BoxShape.rectangle,
            border: Border.all(color: kWhiteColor),
            borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding / 1.2),
            ),
            width: getProportionateScreenWidth(kDefaultPadding * 3.5),
            height: getProportionateScreenHeight(kDefaultPadding * 3.5),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: kBlackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isStore
                      ? "Store"
                      : Provider.of<ZLanguage>(
                          context,
                          listen: false,
                        ).deliveredBy,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: kGreyColor),
                ),
              ],
            ),
          ),
          if (isCompleted == true)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isRated ? null : onRatePressed,
                  child: Icon(
                    isRated ? Icons.star : Icons.star_border,
                    color: isRated ? kSecondaryColor : null,
                    size: 24,
                  ),
                ),
                SizedBox(height: 4),
                Flexible(
                  child: Text(
                    isRated
                        ? Provider.of<ZLanguage>(
                            context,
                            listen: false,
                          ).thankYou
                        : Provider.of<ZLanguage>(context, listen: false).rateUs,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isRated ? kGreyColor : kBlackColor,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
