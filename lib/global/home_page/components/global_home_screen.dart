import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/aliexpress/global_ali_product_screen.dart';
import 'package:zmall/global/items/global_items.dart';
import 'package:zmall/global/stores/global_stores.dart';
import 'package:zmall/home/components/custom_banner.dart';
import 'package:zmall/home/components/offer_card.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/section_title.dart';

class GlobalHomeScreen extends StatefulWidget {
  // const GlobalHomeScreen({
  //   // required this.user,
  // });

  // final User user;

  @override
  _GlobalHomeScreenState createState() => _GlobalHomeScreenState();
}

class _GlobalHomeScreenState extends State<GlobalHomeScreen> {
  User? user;
  AbroadData? abroadData;
  String username = "";
  String email = "";
  String city = "";

  bool _loading = false;
  var categoriesResponse;
  late double latitude, longitude;
  var responseData;
  var categories;
  var promotionalItems;
  List<bool> isPromotionalItemOpen = [];
  bool _isClosed = false;
  String promptMessage =
      'We are sorry to inform you that we are not operational today';

  LocationPermission _permissionStatus = LocationPermission.denied;

  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial
      Service.showMessage(
        context: context,
        title: "Location permission denied. Please enable and try again",
        error: true,
      );
      FlLocation.requestLocationPermission();
    }
  }

  void getLocation() async {
    var currentLocation = await FlLocation.getLocation();
    if (mounted) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
      });
      Provider.of<ZMetaData>(
        context,
        listen: false,
      ).setLocation(currentLocation.latitude, currentLocation.longitude);
    }
  }

  void _doLocationTask() async {
    LocationPermission _permissionStatus =
        await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.whileInUse ||
        _permissionStatus == LocationPermission.always) {
      if (await FlLocation.isLocationServicesEnabled) {
        getLocation();
      } else {
        LocationPermission serviceStatus =
            await FlLocation.requestLocationPermission();
        if (serviceStatus == LocationPermission.always ||
            serviceStatus == LocationPermission.whileInUse) {
          getLocation();
        } else {
          Service.showMessage(
            context: context,
            title: "Location service disabled. Please enable and try again",
            error: true,
          );
        }
      }
    } else {
      _requestLocationPermission();
    }
  }

  @override
  void initState() {
    super.initState();
    CoreServices.registerNotification(context);
    MyApp.messaging.triggerEvent("at_home");
    FirebaseMessaging.instance.subscribeToTopic("abroad");
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // debugPrint("Opened by notification");
      MyApp.analytics.logEvent(name: "notification_open");
    });
    getAbroadUser();
    _doLocationTask();
    _getPromotionalItems();
    checkAbroad();
  }

  Future<dynamic> getCategoryList(
    double longitude,
    double latitude,
    String countryCode,
    String countryName,
  ) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_delivery_list_for_nearest_city";

    //
    Map data = {
      "latitude": latitude,
      "longitude": longitude,
      "country": countryName,
      "country_code": countryCode,
      "isGlobal": true,
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
            Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException("The connection has timed out!");
            },
          );
      // debugPrint("RES ${json.decode(response.body)}");
      await Service.save('categories', json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Connection timeout! Please check your internet connection!",
          ),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  void checkAbroad() async {
    setState(() {
      _loading = true;
    });
    _getAppKeys();
    var data = await getCategoryList(
      38.768154,
      9.004188,
      "5b3f76f2022985030cd3a437",
      "Ethiopia",
    );
    if (data != null && data['success']) {
      setState(() {
        categories = data['deliveries'];
        responseData = data;
        Service.save('categories', categories);
      });
      // debugPrint("categories $categories");
    }
    setState(() {
      _loading = false;
    });
  }

  void _getPromotionalItems() async {
    setState(() {
      _loading = true;
    });
    isPromotionalItemOpen.clear();
    var data = await CoreServices.getPromotionalItems(
      isGlobal: true,
      userId: "user_id",
      serverToken: "server_token",
      ctx: context,
      userLocation: [
        Provider.of<ZMetaData>(context, listen: false).latitude,
        Provider.of<ZMetaData>(context, listen: false).longitude,
      ],
    );

    if (data != null && data['success']) {
      // debugPrint("Fetched promotional Items....");
      if (mounted) {
        // debugPrint(data);
        Service.save('p_items', data);
        setState(() {
          promotionalItems = data;
        });
        getLocalPromotionalItems();
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
    for (int i = 0; i < promotionalItems['promotional_items'].length; i++) {
      bool isPromolItOpen = await storeOpen(
        promotionalItems['promotional_items'][i],
      );
      isPromotionalItemOpen.add(isPromolItOpen);
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void getLocalPromotionalItems() async {
    var data = await Service.read('p_items');
    if (data != null) {
      setState(() {
        promotionalItems = data;
        _loading = false;
      });
    }
  }

  void getUser() async {
    var data = await Service.read('abroad_user');

    getAbroadUser();
  }

  void getAbroadUser() async {
    var data = await Service.read('abroad_user');
    if (data != null) {
      abroadData = AbroadData.fromJson(data);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: kPrimaryColor,
            title: Text("Dear Esteemed User,"),
            content: Wrap(
              children: [
                Text("Please complete registration..."),
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding / 2),
                ),
                TextField(
                  style: TextStyle(color: kBlackColor),
                  keyboardType: TextInputType.text,
                  onChanged: (val) {
                    username = val;
                  },
                  decoration: textFieldInputDecorator.copyWith(
                    labelText: username.isNotEmpty ? username : "Full Name",
                  ),
                ),
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding),
                ),
                TextField(
                  style: TextStyle(color: kBlackColor),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) {
                    email = val;
                  },
                  decoration: textFieldInputDecorator.copyWith(
                    labelText: email.isNotEmpty ? email : "Email",
                  ),
                ),
                // Container(
                //   height: getProportionateScreenHeight(kDefaultPadding),
                // ),
                // TextField(
                //   style: TextStyle(color: kBlackColor),
                //   keyboardType: TextInputType.text,
                //   onChanged: (val) {
                //     city = val;
                //   },
                //   decoration: textFieldInputDecorator?.copyWith(
                //       labelText: city.isNotEmpty ? city : "City"),
                // ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Save Now",
                  style: TextStyle(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  if (username.isNotEmpty && email.isNotEmpty) {
                    var abroadUser = AbroadData(
                      abroadName: username,
                      abroadEmail: email,
                      abroadPhone: user!.phoneNumber,
                    );
                    setState(() {
                      abroadData = abroadUser;
                    });
                    await Service.save('abroad_user', abroadData!.toJson());
                    Navigator.of(context).pop();
                    // bool success =
                    //     await FirebaseCoreServices.addDataToUserProfile(
                    //         user.uid,
                    //         {
                    //           "full_name": username,
                    //           "email": email,
                    //           "city": city,
                    //         },
                    //         isUpdate: true);
                    // if (success) {
                    //   Navigator.of(context).pop();
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //       Service.showMessage(
                    //           "User data successfully updated", false));
                    // } else {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //       Service.showMessage(
                    //           "Something went wrong, data wasn't saved", true));
                    // }
                  } else {
                    // Navigator.of(context).pop();

                    Service.showMessage(
                      context: context,
                      title: "Please add the necessary information",
                      error: true,
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _getAppKeys() async {
    var data = await CoreServices.appKeys(context);

    if (data != null && data['success']) {
      if (data['message_flag']) {
        Service.showMessage(
          context: context,
          title:
              "${data['message']} We deliver your order once we resume our service.",
          error: false,
          duration: 4,
        );
      }
      Service.saveBool("is_closed", false);
      Service.save("closed_message", data['message']);
      Service.save("ios_app_version", data['ios_user_app_version_code']);
      Service.saveBool(
        "ios_update_dialog",
        data['is_ios_user_app_open_update_dialog'],
      );
      Service.saveBool(
        "ios_force_update",
        data['is_ios_user_app_force_update'],
      );
    }
    getAppKeys();
  }

  void getAppKeys() async {
    var data = await Service.read('ios_app_version');
    var currentVersion = await Service.read('version');
    _isClosed = await Service.readBool('is_closed');
    promptMessage = await Service.read('closed_message');
    var showUpdateDialog = await Service.readBool('ios_update_dialog');
    if (data != null) {
      if (currentVersion != data) {
        if (showUpdateDialog) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: kPrimaryColor,
                title: Text("New Version Update"),
                content: Text(
                  "We have detected an older version on the App on your phone.",
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      "Update Now",
                      style: TextStyle(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Service.launchInWebViewOrVC("http://onelink.to/vnchst");
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
    setState(() {});
  }

  ///////////New Features
  Future<void> _onRefresh() async {
    CoreServices.registerNotification(context);
    MyApp.messaging.triggerEvent("at_home");
    FirebaseMessaging.instance.subscribeToTopic("abroad");
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // debugPrint("Opened by notification");
      MyApp.analytics.logEvent(name: "notification_open");
    });
    getAbroadUser();
    _doLocationTask();
    _getPromotionalItems();
    checkAbroad();
  }

  int getServiceIndex(String serviceName) {
    if (categories == null) {
      return -1;
    }
    int index = categories.indexWhere(
      (service) =>
          service['delivery_name']?.toString().toLowerCase() ==
          serviceName.toLowerCase(),
    );
    return index;
  }

  bool isNetworkImage(String serviceName) {
    if (categories == null) {
      return false;
    }
    bool isNetwork =
        getServiceIndex(serviceName) != -1 &&
        categories[getServiceIndex(serviceName)]['image_url']
            .toString()
            .isNotEmpty;
    return isNetwork;
  }

  ///
  Future<bool> storeOpen(var store) async {
    setState(() {
      _loading = true;
    });
    _getAppKeys();
    setState(() {
      _loading = false;
    });
    bool isStoreOpen = false;
    // store_time
    // store_open_close_timen
    if (store['store_time'] != null && store['store_time'].length != 0) {
      var appClose = await Service.read('app_close');
      var appOpen = await Service.read('app_open');
      for (var i = 0; i < store['store_time'].length; i++) {
        DateFormat dateFormat = new DateFormat.Hm();
        DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
        int weekday;
        if (now.weekday == 7) {
          weekday = 0;
        } else {
          weekday = now.weekday;
        }

        if (store['store_time'][i]['day'] == weekday) {
          if (store['store_time'][i]['day_time'].length != 0 &&
              store['store_time'][i]['is_store_open']) {
            for (
              var j = 0;
              j < store['store_time'][i]['day_time'].length;
              j++
            ) {
              DateTime open = dateFormat.parse(
                store['store_time'][i]['day_time'][j]['store_open_time'],
              );
              open = new DateTime(
                now.year,
                now.month,
                now.day,
                open.hour,
                open.minute,
              );
              DateTime close = dateFormat.parse(
                store['store_time'][i]['day_time'][j]['store_close_time'],
              );
              // DateTime zmallClose =
              //     DateTime(now.year, now.month, now.day, 21, 00);
              // DateTime zmallOpen =
              //     DateTime(now.year, now.month, now.day, 09, 00);
              // if (appOpen != null && appOpen != null) {
              DateTime zmallClose = dateFormat.parse(appClose);
              DateTime zmallOpen = dateFormat.parse(appOpen);
              // }

              close = new DateTime(
                now.year,
                now.month,
                now.day,
                close.hour,
                close.minute,
              );
              now = DateTime(
                now.year,
                now.month,
                now.day,
                now.hour,
                now.minute,
              );

              zmallOpen = new DateTime(
                now.year,
                now.month,
                now.day,
                zmallOpen.hour,
                zmallOpen.minute,
              );
              zmallClose = new DateTime(
                now.year,
                now.month,
                now.day,
                zmallClose.hour,
                zmallClose.minute,
              );

              // debugPrint(zmallOpen);
              // debugPrint(open);
              // debugPrint(now);
              // debugPrint(close);
              // debugPrint(zmallClose);
              if (now.isAfter(open) &&
                  now.isAfter(zmallOpen) &&
                  now.isBefore(close) &&
                  store['store_time'][i]['is_store_open'] &&
                  now.isBefore(zmallClose)) {
                isStoreOpen = true;
                break;
              } else {
                isStoreOpen = false;
              }
            }
          } else {
            isStoreOpen = store['store_time'][i]['is_store_open'];
          }
        }
      }
    } else {
      var appClose = await Service.read('app_close');
      var appOpen = await Service.read('app_open');
      DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
      DateFormat dateFormat = new DateFormat.Hm();
      // DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
      // DateTime zmallOpen = DateTime(now.year, now.month, now.day, 09, 00);
      // if (appOpen != null && appOpen != null) {
      DateTime zmallClose = dateFormat.parse(appClose);
      DateTime zmallOpen = dateFormat.parse(appOpen);
      // }
      zmallClose = DateTime(
        now.year,
        now.month,
        now.day,
        zmallClose.hour,
        zmallClose.minute,
      );
      zmallOpen = DateTime(
        now.year,
        now.month,
        now.day,
        zmallOpen.hour,
        zmallOpen.minute,
      );
      now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      if (now.isAfter(zmallOpen) && now.isBefore(zmallClose)) {
        isStoreOpen = true;
      } else {
        isStoreOpen = false;
      }
    }
    return isStoreOpen;
  }

  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text.rich(
          TextSpan(
            text: "Z",
            style: TextStyle(
              color: kSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: "Mall Global",
                style: TextStyle(
                  color: kBlackColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        elevation: 1.0,
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: kSecondaryColor,
        onRefresh: _onRefresh,
        child: ModalProgressHUD(
          inAsyncCall: _loading,
          color: kPrimaryColor,
          progressIndicator: LinearLoadingIndicator(),
          child: categories != null
              ? SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          color: kPrimaryColor,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: getProportionateScreenWidth(
                                kDefaultPadding,
                              ),
                              right: getProportionateScreenWidth(
                                kDefaultPadding,
                              ),
                              top: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                            ),
                            child: Text(
                              abroadData != null
                                  ? "Welcome, ${abroadData!.abroadName}"
                                  : "Welcome to ZMall Global",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        promotionalItems != null &&
                                promotionalItems['success'] &&
                                promotionalItems['promotional_items'] != null &&
                                promotionalItems['promotional_items']
                                    .isNotEmpty &&
                                promotionalItems['promotional_items'].length > 0
                            ? Container(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding * 11,
                                ),
                                width: double.infinity,

                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getProportionateScreenWidth(
                                          kDefaultPadding,
                                        ),
                                        vertical: getProportionateScreenHeight(
                                          kDefaultPadding / 2,
                                        ),
                                      ),
                                      child: SectionTitle(
                                        sectionTitle:
                                            "Specials for your loved ones",
                                        subTitle: " ",
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        separatorBuilder:
                                            (
                                              BuildContext context,
                                              int index,
                                            ) => SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                    kDefaultPadding / 2,
                                                  ),
                                            ),
                                        padding: EdgeInsets.only(
                                          left: getProportionateScreenWidth(10),
                                        ),
                                        itemCount:
                                            promotionalItems != null &&
                                                isPromotionalItemOpen.isNotEmpty
                                            ? isPromotionalItemOpen.length
                                            : 0,

                                        itemBuilder: (context, index) {
                                          final item =
                                              promotionalItems['promotional_items'][index];
                                          return Row(
                                            // itemBuilder: (context, index) => Row(
                                            children: [
                                              SpecialOfferCard(
                                                isOpen:
                                                    isPromotionalItemOpen[index],
                                                imageUrl:
                                                    promotionalItems != null &&
                                                        item['image_url']
                                                                .length >
                                                            0
                                                    ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${item['image_url'][0]}"
                                                    : "www.google.com",
                                                itemName: "${item['name']}\n",
                                                newPrice:
                                                    "${item['price'].toStringAsFixed(2)}\t",
                                                originalPrice:
                                                    "${item['new_price'].toStringAsFixed(2)}",
                                                isDiscounted: item['discount'],
                                                storeName: item['store_name'],
                                                specialOffer:
                                                    item['special_offer'],
                                                storePress: () {},
                                                press: () async {
                                                  // bool isOp = await storeOpen(
                                                  //     promotionalItems[
                                                  //     'promotional_items'][index]);
                                                  // if (isOp) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return GlobalItem(
                                                          item:
                                                              promotionalItems['promotional_items'][index],
                                                          location:
                                                              promotionalItems['promotional_items'][index]['store_location'],
                                                          isOpen: true,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                  // }
                                                  // else {
                                                  //   if (mounted) {
                                                  //     ScaffoldMessenger.of(context)
                                                  //         .showSnackBar(
                                                  //       Service.showMessage(
                                                  //           "Store is currently closed. We highly recommend you to try other store. We've got them all...",
                                                  //           false,
                                                  //           duration: 3),
                                                  //     );
                                                  //   }
                                                  // }
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                        SizedBox(
                          height: getProportionateScreenHeight(
                            kDefaultPadding / 4,
                          ),
                        ),
                        /////////////////////////////Aliexpress section////////////////
                        categories == null ||
                                (categories.isEmpty ||
                                    !categories.any(
                                      (delivery) =>
                                          delivery['delivery_name']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'aliexpress',
                                    ))
                            ? SizedBox.shrink()
                            : Container(
                                padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                                margin: EdgeInsets.symmetric(
                                  vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 4,
                                  ),
                                  horizontal: getProportionateScreenHeight(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                                decoration: BoxDecoration(color: kPrimaryColor),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getProportionateScreenWidth(
                                          kDefaultPadding,
                                        ),
                                      ),
                                      child: SectionTitle(
                                        sectionTitle: "AliExpress",
                                        subTitle: " ",
                                      ),
                                    ),
                                    CustomBanner(
                                      isNetworkImage: isNetworkImage(
                                        "aliexpress",
                                      ),
                                      imageUrl: isNetworkImage("aliexpress")
                                          ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[getServiceIndex("aliexpress")]['image_url']}"
                                          : "images/aliexpress-banner.png",
                                      title: "AliExpress",
                                      subtitle: "",
                                      press: () async {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GlobalAliProductListScreen(),
                                          ),
                                        ).then((value) {
                                          if (abroadData != null) {
                                            checkAbroad();
                                            _getPromotionalItems();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        categories == null ||
                                (categories.isEmpty ||
                                    !categories.any(
                                      (delivery) =>
                                          delivery['delivery_name']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'aliexpress',
                                    ))
                            ? SizedBox.shrink()
                            : SizedBox(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding / 4,
                                ),
                              ),
                        //////////////finish aliexpress//////////////////
                        Container(
                          color: kPrimaryColor,
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                child: SectionTitle(
                                  sectionTitle: "What would you like to order?",
                                  subTitle: " ",
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                child: GridView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  // itemCount: categories != null
                                  //     ? categories.length
                                  //     : 0,
                                  itemCount:
                                      categories
                                          ?.where(
                                            (delivery) =>
                                                delivery['delivery_name']
                                                    ?.toString()
                                                    .toLowerCase() !=
                                                'aliexpress',
                                          )
                                          .length ??
                                      0,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: kDefaultPadding * .8,
                                        mainAxisSpacing: kDefaultPadding * .8,
                                        childAspectRatio:
                                            MediaQuery.of(context).size.width <
                                                650.0
                                            ? 1.3
                                            : 1,
                                      ),
                                  itemBuilder: (context, index) {
                                    // Get the filtered list and access the item by index
                                    final filteredCategories = categories!
                                        .where(
                                          (delivery) =>
                                              delivery['delivery_name']
                                                  ?.toString()
                                                  .toLowerCase() !=
                                              'aliexpress',
                                        )
                                        .toList();
                                    final category = filteredCategories[index];

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return GlobalStore(
                                                cityId:
                                                    responseData['city']['_id'],
                                                // storeDeliveryId: categories[index]
                                                //     ['_id'],
                                                // category: categories[index],
                                                storeDeliveryId:
                                                    category['_id'],
                                                category: category,
                                                latitude: latitude,
                                                longitude: longitude,
                                                isStore: false,
                                                companyId: null,
                                              );
                                            },
                                          ),
                                        ).then((value) {
                                          checkAbroad();
                                          _getPromotionalItems();
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          getProportionateScreenWidth(
                                            kDefaultPadding / 2,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          border: Border.all(
                                            color: kWhiteColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            kDefaultPadding,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: getProportionateScreenHeight(
                                            kDefaultPadding / 2,
                                          ),
                                          children: [
                                            Expanded(
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${category['image_url']}",
                                                // "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[index]['image_url']}",
                                                imageBuilder:
                                                    (
                                                      context,
                                                      imageProvider,
                                                    ) => Container(
                                                      decoration: BoxDecoration(
                                                        color: kWhiteColor,
                                                        image: DecorationImage(
                                                          fit: BoxFit.contain,
                                                          image: imageProvider,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              kDefaultPadding /
                                                                  1.5,
                                                            ),
                                                      ),
                                                    ),
                                                placeholder: (context, url) => Center(
                                                  child: Container(
                                                    width:
                                                        getProportionateScreenWidth(
                                                          kDefaultPadding * 3.5,
                                                        ),
                                                    height:
                                                        getProportionateScreenHeight(
                                                          kDefaultPadding * 3.5,
                                                        ),
                                                    child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(kWhiteColor),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          fit: BoxFit.cover,
                                                          image: AssetImage(
                                                            'images/zmall.jpg',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              Service.capitalizeFirstLetters(
                                                category['delivery_name'],
                                              ),
                                              // categories[index]['delivery_name'],
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: kBlackColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _loading
              ? Container()
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(
                      kDefaultPadding * 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomButton(
                        title: "Retry",
                        press: () {
                          // debugPrint("retry....");
                          checkAbroad();
                        },
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
