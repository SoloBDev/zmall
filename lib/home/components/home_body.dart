import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:zmall/aliexpress/ali_product_screen.dart';
import 'package:zmall/cart/cart_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/controllers/controllers.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/courier/courier_screen.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/events/events_screen.dart';
import 'package:zmall/home/components/custom_banner.dart';
import 'package:zmall/home/components/offer_card.dart';
import 'package:zmall/home/components/stores_card.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/lunch_home/lunch_home_screen.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/notifications/notification_store.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/search/search_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/store_screen.dart';
import 'package:zmall/widgets/section_title.dart';
import 'package:zmall/world_cup/world_cup_screen.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({
    Key? key,
    this.isLaunched = false,
  }) : super(key: key);
  final bool isLaunched;

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  var userData;
  var responseData;
  var userResponseData;
  var servicesData;
  var promotionalItems;
  var promotionalStores;
  var categories;
  var services;
  var notificationItem;
  var nearbyStores;
  Controller? controller = Controller();
  late String deviceToken;
  String promptMessage =
      'We are sorry to inform you that we are not operational today!';
  bool _loading = false;
  bool isLaundryActive = false;
  int laundryIndex = 0;
  late double latitude, longitude;
  bool _isClosed = false;
  int remainder = 0;
  int quotient = 0;
  int orderCount = 0;
  bool isRewarded = false;
  List<bool> isOpen = [];
  bool is_abroad = false;
  Cart? cart;
  DateTime predictStart = DateTime(2023, 08, 6);
  DateTime predictEnd = DateTime(2025, 06, 30);
  DateTime euroPredictStart = DateTime(2024, 06, 10);
  DateTime euroPredictEnd = DateTime(2024, 07, 20);
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  LocationPermission _permissionStatus = LocationPermission.denied;

//////////////////newly added
  var userLastOrder;
  var userLocation;
  var userOrderStatus;
  var orderTo;
  var orderFrom;
  Timer? timer;
//////////////////////////////

  @override
  void initState() {
    super.initState();
    getCart();
    isAbroad();
    CoreServices.registerNotification(context);
    MyApp.messaging.triggerEvent("at_home");
    _getToken();
    getUser();
    getLocalPromotionalItems();
    getLocalPromotionalStores();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened by notification open by app");

      MyApp.analytics.logEvent(name: "notification_opened");
      if (message.data != null && !is_abroad) {
        var notificationData = message.data;
        if (notificationData['item_id'] != null) {
          print("Navigate to item screen...");
          _getItemInformation(notificationData['item_id']);
        } else if (notificationData['store_id'] != null) {
          print("Navigate to store...");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return NotificationStore(storeId: notificationData['store_id']);
              },
            ),
          );
        } else if (notificationData['redirect'] != null) {
          launchRedirect(notificationData['redirect']);
        }
      }
    });
    if (widget.isLaunched) {
      print("=> \tChecking for version update");
      getAppKeys();
    }
    getCategories();
    getServices();
    getNearByServices();
    getNearByMerchants();
  }

  ////////////////newly added
  void _startTimer() async {
    if (userLastOrder != null) {
      double distance = Service.calculateDistance(
          userLocation[0], userLocation[1], latitude, longitude);

      if (orderFrom == orderTo && userOrderStatus < 25 && distance > 0.1000) {
        Timer.periodic(const Duration(seconds: 30), (timer) {
          if (timer.tick > 1) {
            timer.cancel();
          } else {
            showDialog(
              context: context,
              barrierDismissible: Platform.isIOS ? true : false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text(
                    'Location Changed !',
                  ),
                  content: Text(
                    "Just to inform you, there has been a change in your location by ${distance.toStringAsFixed(3)} Km since your last order.",
                  ),
                  titleTextStyle:
                      TextStyle(color: kSecondaryColor, fontSize: 20),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _startTimer();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(color: kSecondaryColor),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        });
      }
    } else {
      _getUserOrder();
    }
  }

  void _getUserOrder() async {
    setState(() {
      _loading = true;
    });
    var data = await getOrders();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        userLastOrder = data['order_list'][0];
        userOrderStatus = userLastOrder['order_status'];
        userLocation = userLastOrder['destination_addresses'][0]['location'];
        orderTo =
            userLastOrder['destination_addresses'][0]['user_details']['name'];
        _startTimer();
      });
    } else {
      setState(() {
        _loading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //     Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
    }
  }

////////////////newly added
  Future<void> _onRefresh() async {
    getCart();
    isAbroad();
    CoreServices.registerNotification(context);
    MyApp.messaging.triggerEvent("at_home");
    _getToken();
    getUser();
    getLocalPromotionalItems();
    getLocalPromotionalStores();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened by notification open by app");

      MyApp.analytics.logEvent(name: "notification_opened");
      if (message.data != null && !is_abroad) {
        var notificationData = message.data;
        if (notificationData['item_id'] != null) {
          print("Navigate to item screen...");
          _getItemInformation(notificationData['item_id']);
        } else if (notificationData['store_id'] != null) {
          print("Navigate to store...");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return NotificationStore(storeId: notificationData['store_id']);
              },
            ),
          );
        } else if (notificationData['redirect'] != null) {
          launchRedirect(notificationData['redirect']);
        }
      }
    });
    if (widget.isLaunched) {
      print("=> \tChecking for version update");
      getAppKeys();
    }

    getCategories();
    getServices();
    getNearByServices();
    getNearByMerchants();
  }

//////////////////////////////////
  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Location permission denied. Please enable and try again", true));
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
      Provider.of<ZMetaData>(context, listen: false)
          .setLocation(latitude, longitude);
      _getNearbyStores();
    }
  }

  void _doLocationTask() async {
    print("checking user location");
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
          ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
              "Location service disabled. Please enable and try again", true));
        }
      }
    } else {
      _requestLocationPermission();
    }
  }

  void isAbroad() async {
    var data = await Service.read('is_abroad');
    if (data != null && data) {
      setState(() {
        is_abroad = data;
      });
    }
  }

  void getCart() async {
    print("Fetching data");
    var data = await Service.read('cart');
    if (data != null) {
      setState(() {
        cart = Cart.fromJson(data);
      });
    }
  }

  void launchRedirect(url) async {
    setState(() {
      _loading = true;
    });
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _loading = false;
    });
    Service.launchInWebViewOrVC(url);
  }

  _getToken() {
    _firebaseMessaging.getToken().then((value) {
      if (value != null && userData != null) {
        setState(() {
          deviceToken = value;
          userData['user']['device_token'] = deviceToken;
          Service.save('user', userData);
        });
        CoreServices.updateDeviceToken(
          userId: userData['user']['_id'],
          serverToken: userData['user']['server_token'],
          deviceToken: deviceToken,
          context: context,
        );
      }
    });
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
        orderFrom = userData['user']['first_name'];
        _getToken();
      });
      getUserOrderCount();
      _getPromotionalItems();
      _getUserOrder();
    }
  }

  void _getUserDetails(userId, serverToken) async {
    setState(() {
      _loading = false;
    });
    var data = await CoreServices.getUserDetail(userId, serverToken, context);

    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        userData = data;
        Service.save('user', userData);
      });
    } else {
      setState(() {
        _loading = false;
      });
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${data['error_code']}']}!", true));
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  void getUserOrderCount() {
    _getUserDetails(userData['user']['_id'], userData['user']['server_token']);
    if (userData['user']['order_count'] > 0) {
      setState(() {
        orderCount = int.parse(userData['user']['order_count'].toString());
      });
      int x = orderCount % 10;
      if (x != 0) {
        setState(() {
          quotient =
              (int.parse(userData['user']['order_count'].toString()) ~/ 10);
          remainder = x;
          isRewarded = false;
        });
      } else {
        setState(() {
          quotient =
              (int.parse(userData['user']['order_count'].toString()) ~/ 10);
          remainder = x;
          isRewarded = true;
        });
      }
    }
  }

  void _getAppKeys() async {
    var data = await CoreServices.appKeys(context);
    if (data != null && data['success']) {
      setState(() {
        Service.saveBool("is_closed", data['message_flag']);
        Service.save("closed_message", data['message']);
        Service.save("ios_app_version", data['ios_user_app_version_code']);
        Service.saveBool(
            "ios_update_dialog", data['is_ios_user_app_open_update_dialog']);
        Service.saveBool(
            "ios_force_update", data['is_ios_user_app_force_update']);
        Service.save('app_close', data['app_close']);
        Service.save('app_open', data['app_open']);
      });
      if (data['message_flag']) {
        showSimpleNotification(
          Text(
            "⚠️ NOTICE ⚠️",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "${data['message']}\n",
          ),
          background: kBlackColor,
          duration: Duration(seconds: 7),
          elevation: 2.0,
          autoDismiss: false,
          slideDismiss: true,
          slideDismissDirection: DismissDirection.up,
        );
      }
      getAppKeys();
    } else {
      getAppKeys();
    }
  }

  void getAppKeys() async {
    var data = await Service.read('ios_app_version');
    var currentVersion = await Service.read('version');
    _isClosed = await Service.readBool('is_closed') ??
        await Service.readBool('is_closed');
    promptMessage = await Service.read('closed_message');
    var showUpdateDialog = await Service.readBool('ios_update_dialog');
    print("=====================");
    if (data != null) {
      if (currentVersion.toString() != data.toString()) {
        if (showUpdateDialog) {
          print("\t=> \tShowing update dialog...");
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: kPrimaryColor,
                title: Text("New Version Update"),
                content: Text(
                    "We have detected an older version on the App on your phone."),
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
    if (mounted) {
      setState(() {});
    }
  }

  void _getPromotionalItems() async {
    setState(() {
      _loading = widget.isLaunched;
    });
    getCart();
    var data = await CoreServices.getPromotionalItems(
      userId: userData['user']['_id'],
      serverToken: userData['user']['server_token'],
      ctx: context,
      userLocation: [
        Provider.of<ZMetaData>(context, listen: false).latitude,
        Provider.of<ZMetaData>(context, listen: false).longitude
      ],
    );

    if (data != null && data['success']) {
      if (mounted) {
        Service.save('p_items', data);
        setState(() {
          promotionalItems = data;
          _loading = false;
        });
        getLocalPromotionalItems();
      }
    } else {
      setState(() {
        _loading = false;
        promotionalItems = {"success": false, "promotional_items": []};
      });
      if (data != null && data['error_code'] == 999) {
        await CoreServices.clearCache();
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _getPromotionalStores() async {
    setState(() {
      _loading = widget.isLaunched;
    });
    var data = await CoreServices.getPromotionalStores(
      userId: userData['user']['_id'],
      serverToken: userData['user']['server_token'],
      latitude: Provider.of<ZMetaData>(context, listen: false).latitude,
      longitude: Provider.of<ZMetaData>(context, listen: false).longitude,
      ctx: context,
    );

    if (data != null && data['success']) {
      if (mounted) {
        Service.save('s_items', data);
        setState(() {
          promotionalStores = data;
          _loading = false;
        });
        getLocalPromotionalStores();
      }
    } else {
      setState(() {
        _loading = false;
        promotionalStores = {"success": false, "promotional_items": []};
      });
      if (data != null && data['error_code'] == 999) {
        await CoreServices.clearCache();
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
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
      });
    } else {
      setState(() {
        promotionalItems = {"success": false, "promotional_items": []};
      });
    }
    _getPromotionalStores();
  }

  void getLocalPromotionalStores() async {
    var data = await Service.read('s_items');
    if (data != null) {
      setState(() {
        promotionalStores = data;
      });
    } else {
      setState(() {
        promotionalStores = {"success": false, "promotional_stores": []};
      });
    }
  }

  void _getNearbyStores() async {
    setState(() {
      _loading = true;
    });
    var data = await getNearbyStores();
    if (data != null && data['success']) {
      setState(() {
        nearbyStores = data['stores'];
      });
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Filed to"),
      //   ),
      // );
    }
  }

  void _getItemInformation(String itemId) async {
    setState(() {
      _loading = true;
    });
    await getItemInformation(itemId);
    if (notificationItem != null && notificationItem['success']) {
      bool isOpen = await storeOpen(notificationItem['item']);
      if (isOpen) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ItemScreen(
                  item: notificationItem['item'],
                  location: notificationItem['item']['store_location']);
            },
          ),
        ).then((value) {
          if (userData != null) {
            _getPromotionalItems();
            controller?.getFavorites();
            getUserOrderCount();
            _doLocationTask();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            Service.showMessage(
                "Store is currently closed. We highly recommend you to try other store. We've got them all...",
                false,
                duration: 3),
          );
        }
      }
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Filed to"),
      //   ),
      // );
    }
  }

  Future<bool> storeOpen(var store) async {
    setState(() {
      _loading = true;
    });
    _getAppKeys();
    setState(() {
      _loading = false;
    });
    bool isStoreOpen = false;
    if (store['store_open_close_time'] != null &&
        store['store_open_close_time'].length != 0) {
      var appClose = await Service.read('app_close');
      var appOpen = await Service.read('app_open');
      for (var i = 0; i < store['store_open_close_time'].length; i++) {
        DateFormat dateFormat = new DateFormat.Hm();
        DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
        int weekday;
        if (now.weekday == 7) {
          weekday = 0;
        } else {
          weekday = now.weekday;
        }

        if (store['store_open_close_time'][i]['day'] == weekday) {
          if (store['store_open_close_time'][i]['day_time'].length != 0 &&
              store['store_open_close_time'][i]['is_store_open']) {
            for (var j = 0;
                j < store['store_open_close_time'][i]['day_time'].length;
                j++) {
              DateTime open = dateFormat.parse(store['store_open_close_time'][i]
                  ['day_time'][j]['store_open_time']);
              open = new DateTime(
                  now.year, now.month, now.day, open.hour, open.minute);
              DateTime close = dateFormat.parse(store['store_open_close_time']
                  [i]['day_time'][j]['store_close_time']);
              // DateTime zmallClose =
              //     DateTime(now.year, now.month, now.day, 21, 00);
              // DateTime zmallOpen =
              //     DateTime(now.year, now.month, now.day, 09, 00);
              // if (appOpen != null && appOpen != null) {
              DateTime zmallClose = dateFormat.parse(appClose);
              DateTime zmallOpen = dateFormat.parse(appOpen);
              // }

              close = new DateTime(
                  now.year, now.month, now.day, close.hour, close.minute);
              now =
                  DateTime(now.year, now.month, now.day, now.hour, now.minute);

              zmallOpen = new DateTime(now.year, now.month, now.day,
                  zmallOpen.hour, zmallOpen.minute);
              zmallClose = new DateTime(now.year, now.month, now.day,
                  zmallClose.hour, zmallClose.minute);

              // print(zmallOpen);
              // print(open);
              // print(now);
              // print(close);
              // print(zmallClose);
              if (now.isAfter(open) &&
                  now.isAfter(zmallOpen) &&
                  now.isBefore(close) &&
                  store['store_open_close_time'][i]['is_store_open'] &&
                  now.isBefore(zmallClose)) {
                isStoreOpen = true;
                break;
              } else {
                isStoreOpen = false;
              }
            }
          } else {
            isStoreOpen = store['store_open_close_time'][i]['is_store_open'];
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
          now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
      zmallOpen = DateTime(
          now.year, now.month, now.day, zmallOpen.hour, zmallOpen.minute);
      now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      if (now.isAfter(zmallOpen) && now.isBefore(zmallClose)) {
        isStoreOpen = true;
      } else {
        isStoreOpen = false;
      }
    }

    return isStoreOpen;
  }

  void getCategories() async {
    _getAppKeys();
    var data = await Service.read('categories');
    if (data != null) {
      setState(() {
        responseData = data;
        categories = responseData['deliveries'];
      });
      checkLaundryCategory(categories);
    }
  }

  void getServices() async {
    var data = await Service.read('services');
    if (data != null) {
      setState(() {
        servicesData = data;
        services = servicesData['deliveries'];
      });
    }
  }

  String allWordsCapitilize(String str) {
    return str.toLowerCase().split(' ').map((word) {
      String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
      return word[0].toUpperCase() + leftText;
    }).join(' ');
  }

  void checkLaundryCategory(List categoryList) {
    setState(() {
      laundryIndex = -1;
    });
    for (var i = 0; i < categoryList.length; i++) {
      if (categoryList[i]['delivery_name'].toString().toLowerCase() ==
          "laundry") {
        setState(() {
          isLaundryActive = true;
          laundryIndex = i;
        });
      }
    }
    if (laundryIndex == -1) {
      if (mounted)
        setState(() {
          isLaundryActive = false;
        });
    }
  }

  void getNearByMerchants() async {
    print("Fetching delivery categories...");
    setState(() {
      _loading = true;
    });
    _doLocationTask();
    this.responseData = await getCategoryList(
        Provider.of<ZMetaData>(context, listen: false).longitude,
        Provider.of<ZMetaData>(context, listen: false).latitude,
        Provider.of<ZMetaData>(context, listen: false).countryId!,
        Provider.of<ZMetaData>(context, listen: false).country);
    setState(() {
      _loading = false;
    });
    if (responseData != null && responseData['success']) {
      print("\t=>\tGet Merchants Completed...");
      setState(() {
        categories = responseData['deliveries'];
      });
      checkLaundryCategory(categories);
    } else {
      if (responseData['error_code'] != null &&
          responseData['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else if (responseData['error_code'] != null &&
          responseData['error_code'] == 813) {
        String country = Provider.of<ZMetaData>(context, listen: false).country;
        if (country == "Ethiopia") {
          showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                    title: Text("ZMall Global!"),
                    content: Text(
                        "We have detected that your location is not in Addis Ababa. Please proceed to ZMall Global!"),
                    actions: [
                      CupertinoButton(
                        child: Text('Continue'),
                        onPressed: () async {
                          await Service.saveBool('is_global', true);
                          await Service.saveBool('logged', false);
                          await Service.remove('user');
                          Navigator.pushNamedAndRemoveUntil(context, "/global",
                              (Route<dynamic> route) => false);
                          // Navigator.pop(context);
                        },
                      )
                    ],
                  ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
              "${errorCodes['${responseData['error_code']}']}", true));
        }
      }
    }
  }

  void getNearByServices() async {
    setState(() {
      _loading = true;
    });

    setState(() {
      _loading = servicesData == null;
    });

    _doLocationTask();

    this.servicesData = await getServicesList(
        Provider.of<ZMetaData>(context, listen: false).longitude,
        Provider.of<ZMetaData>(context, listen: false).latitude,
        Provider.of<ZMetaData>(context, listen: false).countryId!,
        Provider.of<ZMetaData>(context, listen: false).country);
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
    if (servicesData != null && servicesData['success']) {
      services = servicesData['deliveries'];
      print("\t=> \tGet Services Completed");
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${errorCodes['${responseData['error_code']}']}", true));
      }
      if (servicesData['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }

    // else if (status.isDenied) {
    //   var status = await Permission.location.request();
    //   if (mounted) {
    //     setState(() {
    //       status = status;
    //       getNearByServices();
    //     });
    //   }
    // }

    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       backgroundColor: kPrimaryColor,
    //       title: Text("Allow Location Permission"),
    //       content: Text(
    //           "You have disabled access to your location. Please update location permission and restart the app!"),
    //       actions: <Widget>[
    //         TextButton(
    //           child: Text(
    //             "Open Settings",
    //             style: TextStyle(
    //               color: kSecondaryColor,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //           onPressed: () {
    //             openAppSettings();
    //             Navigator.of(context).pop();
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  int getServiceIndex(String serviceName) {
    if (services == null) {
      return -1;
    }
    int index = services.indexWhere((service) =>
        service['delivery_name']?.toString().toLowerCase() ==
        serviceName.toLowerCase());
    return index;
  }

  bool isNetworkImage(String serviceName) {
    if (services == null) {
      return false;
    }
    bool isNetwork = getServiceIndex(serviceName) != -1 &&
        services[getServiceIndex(serviceName)]['image_url']
            .toString()
            .isNotEmpty;
    return isNetwork;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: kPrimaryColor,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    text: "ዚ",
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: getProportionateScreenWidth(16),
                    ),
                    children: [
                      TextSpan(
                        text: "ሞል | ",
                        style: TextStyle(
                          color: kBlackColor,
                          fontWeight: FontWeight.bold,
                          fontSize: getProportionateScreenWidth(16),
                        ),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: "Z",
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: "Mall ",
                        style: TextStyle(
                          color: kBlackColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              "D E L I V E R Y",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        leading: InkWell(
          onTap: () {
            // Navigator.pushNamed(context, ScannerScreen.routeName)
            //     .then((value) => getCart());
          },
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding * 2.5),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: getProportionateScreenWidth(kDefaultPadding * .75),
                  right: getProportionateScreenWidth(kDefaultPadding * .75),
                  top: getProportionateScreenWidth(kDefaultPadding * .75),
                  bottom: getProportionateScreenWidth(kDefaultPadding * .75),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, CartScreen.routeName)
                  .then((value) => getCart());
            },
            icon: Badge.count(
              offset: Offset(-12, -8),
              alignment: Alignment.topLeft,
              count: cart != null ? cart!.items!.length : 0,
              backgroundColor: kSecondaryColor,
              child: Icon(Icons.add_shopping_cart_rounded),
            ),
          ),
          // InkWell(
          //   onTap: () {
          //     Navigator.pushNamed(context, CartScreen.routeName)
          //         .then((value) => getCart());
          //   },
          //   borderRadius: BorderRadius.circular(
          //     getProportionateScreenWidth(kDefaultPadding * 2.5),
          //   ),
          //   child: Stack(
          //     children: [
          //       Padding(
          //         padding: EdgeInsets.only(
          //           left: getProportionateScreenWidth(kDefaultPadding * .75),
          //           right: getProportionateScreenWidth(kDefaultPadding * .75),
          //           top: getProportionateScreenWidth(kDefaultPadding * .75),
          //           bottom: getProportionateScreenWidth(kDefaultPadding * .75),
          //         ),
          //         child: Icon(Icons.add_shopping_cart_rounded),
          //       ),
          //       Positioned(
          //         left: 0,
          //         top: 5,
          //         child: Container(
          //           height: getProportionateScreenWidth(kDefaultPadding * .9),
          //           width: getProportionateScreenWidth(kDefaultPadding * .9),
          //           decoration: BoxDecoration(
          //             color: kSecondaryColor,
          //             shape: BoxShape.circle,
          //             border: Border.all(width: 1.5, color: kWhiteColor),
          //           ),
          //           child: Center(
          //             child: Text(
          //               cart != null ? "${cart!.items!.length}" : "0",
          //               style: TextStyle(
          //                 fontSize:
          //                     getProportionateScreenWidth(kDefaultPadding / 2),
          //                 height: 1,
          //                 color: kPrimaryColor,
          //                 fontWeight: FontWeight.w600,
          //               ),
          //             ),
          //           ),
          //         ),
          //       )
          //     ],
          //   ),
          // ),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: kSecondaryColor,
        onRefresh: _onRefresh,
        child: ModalProgressHUD(
          color: kPrimaryColor,
          progressIndicator: linearProgressIndicator,
          inAsyncCall: _loading,
          child: categories != null
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding),
                            vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: getProportionateScreenHeight(
                                        kDefaultPadding / 2)),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return SearchScreen(
                                            cityId: responseData['city']
                                                ['_id']!,
                                            categories: categories!,
                                            latitude: Provider.of<ZMetaData>(
                                                    context,
                                                    listen: false)
                                                .latitude,
                                            longitude: Provider.of<ZMetaData>(
                                                    context,
                                                    listen: false)
                                                .longitude,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: kGreyColor.withValues(
                                              alpha: 0.05)),
                                      borderRadius: BorderRadius.circular(
                                          getProportionateScreenWidth(
                                              kDefaultPadding)),
                                      color: kWhiteColor,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding * 2),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Icon(
                                          FontAwesomeIcons.search,
                                          color: kGreyColor,
                                          size: getProportionateScreenHeight(
                                              kDefaultPadding),
                                        ),
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                        Text(Provider.of<ZLanguage>(context)
                                            .search)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                userData != null
                                    ? "${Provider.of<ZLanguage>(context, listen: true).hello}, ${userData['user']['first_name']}"
                                    : "Delivery Done Right",
                                style: TextStyle(
                                  fontSize: getProportionateScreenHeight(
                                    kDefaultPadding * 1.15,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              userData != null
                                  ? Text(
                                      isRewarded
                                          ? "${Provider.of<ZLanguage>(context, listen: true).youAre} 9 ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                                          : (10 - remainder) != 1
                                              ? "${Provider.of<ZLanguage>(context, listen: true).youAre} ${10 - remainder} ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                                              : Provider.of<ZLanguage>(context,
                                                      listen: true)
                                                  .nextOrderCashback,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(color: kBlackColor),
                                    )
                                  : Container(),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2),
                              ),
                              userData != null
                                  ? SizedBox(
                                      height: getProportionateScreenHeight(
                                          kDefaultPadding / 4))
                                  : Container(),
                              userData != null
                                  ? LinearPercentIndicator(
                                      animation: true,
                                      lineHeight: getProportionateScreenHeight(
                                          kDefaultPadding),
                                      barRadius: Radius.circular(
                                          getProportionateScreenWidth(
                                              kDefaultPadding)),
                                      backgroundColor: kBlackColor,
                                      progressColor: kSecondaryColor,
                                      center: Text(
                                        "$orderCount/${quotient + 1}0",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: kPrimaryColor,
                                            ),
                                      ),
                                      percent: (remainder / 10),
                                    )
                                  : Container(),
                              SizedBox(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding / 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenWidth(kDefaultPadding / 4),
                      ),
                      promotionalItems != null && promotionalItems['success']
                          ? Container(
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle:
                                          Provider.of<ZLanguage>(context)
                                              .specialForYou,
                                      subTitle: " ",
                                    ),
                                  ),
                                  promotionalItems != null
                                      ? Container(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding * 12),
                                          width: double.infinity,
                                          padding: EdgeInsets.only(
                                            right: getProportionateScreenWidth(
                                                kDefaultPadding / 2),
                                          ),
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: promotionalItems != null &&
                                                    promotionalItems
                                                        .isNotEmpty &&
                                                    promotionalItems[
                                                                'promotional_items']
                                                            .length >
                                                        0
                                                ? promotionalItems[
                                                        'promotional_items']
                                                    .length
                                                : 0,
                                            itemBuilder: (context, index) =>
                                                Row(
                                              children: [
                                                index == 0
                                                    ? SizedBox(
                                                        width:
                                                            getProportionateScreenWidth(
                                                                kDefaultPadding),
                                                      )
                                                    : Container(),
                                                SpecialOfferCard(
                                                  imageUrl: promotionalItems !=
                                                              null &&
                                                          promotionalItems['promotional_items']
                                                                          [
                                                                          index]
                                                                      [
                                                                      'image_url']
                                                                  .length >
                                                              0
                                                      ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${promotionalItems['promotional_items'][index]['image_url'][0]}"
                                                      : "www.google.com",
                                                  itemName:
                                                      "${promotionalItems['promotional_items'][index]['name']}\n",
                                                  newPrice:
                                                      "${promotionalItems['promotional_items'][index]['price'].toStringAsFixed(2)}\t",
                                                  originalPrice:
                                                      "${promotionalItems['promotional_items'][index]['new_price'].toStringAsFixed(2)}",
                                                  isDiscounted: promotionalItems[
                                                          'promotional_items']
                                                      [index]['discount'],
                                                  storeName: promotionalItems[
                                                          'promotional_items']
                                                      [index]['store_name'],
                                                  specialOffer: promotionalItems[
                                                          'promotional_items']
                                                      [index]['special_offer'],
                                                  storePress: () async {
                                                    bool isOp = await storeOpen(
                                                        promotionalItems[
                                                                'promotional_items']
                                                            [index]);

                                                    if (isOp) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return NotificationStore(
                                                                storeId: promotionalItems[
                                                                            'promotional_items']
                                                                        [index][
                                                                    'store_id']);
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        getCart();
                                                        _doLocationTask();
                                                        getNearByMerchants();
                                                      });
                                                    }
                                                  },
                                                  press: () async {
                                                    print(
                                                        "Promotional item pressed...");
                                                    bool isOp = await storeOpen(
                                                        promotionalItems[
                                                                'promotional_items']
                                                            [index]);

                                                    if (isOp) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return ItemScreen(
                                                                item: promotionalItems[
                                                                        'promotional_items']
                                                                    [index],
                                                                location: promotionalItems[
                                                                            'promotional_items']
                                                                        [index][
                                                                    'store_location']);
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        getCart();
                                                        _doLocationTask();
                                                        getNearByMerchants();
                                                      });
                                                    } else {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          Service.showMessage(
                                                              "Store is currently closed. We highly recommend you to try other store. We've got them all...",
                                                              false,
                                                              duration: 3),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                            separatorBuilder:
                                                (BuildContext context,
                                                        int index) =>
                                                    SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 2),
                                            ),
                                          ),
                                        )
                                      : userData != null
                                          ? _loading
                                              ? SpinKitWave(
                                                  color: kSecondaryColor,
                                                  size:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding),
                                                )
                                              : Container(
                                                  height:
                                                      getProportionateScreenHeight(
                                                          kDefaultPadding * 6),
                                                  child: Center(
                                                    child: Text(
                                                        "Nothing to show, please try again..."),
                                                  ),
                                                )
                                          : Container(
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 6),
                                              child: Center(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        getProportionateScreenWidth(
                                                            kDefaultPadding),
                                                  ),
                                                  child: Text(
                                                      "Nothing to show, please login..."),
                                                ),
                                              ),
                                            ),
                                ],
                              ),
                            )
                          : Container(),
                      promotionalItems != null && promotionalItems['success']
                          ? SizedBox(
                              height: getProportionateScreenWidth(
                                  kDefaultPadding / 4),
                            )
                          : SizedBox.shrink(),
                      promotionalStores != null && promotionalStores['success']
                          ? Container(
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle:
                                          Provider.of<ZLanguage>(context)
                                              .featuredStores,
                                      subTitle: " ",
                                    ),
                                  ),
                                  promotionalStores != null
                                      ? Container(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding * 12),
                                          width: double.infinity,
                                          padding: EdgeInsets.only(
                                            right: getProportionateScreenWidth(
                                                kDefaultPadding / 2),
                                          ),
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: promotionalStores[
                                                        'success'] &&
                                                    promotionalStores[
                                                                'promotional_stores']
                                                            .length >
                                                        0
                                                ? promotionalStores[
                                                        'promotional_stores']
                                                    .length
                                                : 0,
                                            itemBuilder: (context, index) =>
                                                Row(
                                              children: [
                                                index == 0
                                                    ? SizedBox(
                                                        width:
                                                            getProportionateScreenWidth(
                                                                kDefaultPadding),
                                                      )
                                                    : Container(),
                                                StoresCard(
                                                  imageUrl:
                                                      "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${promotionalStores['promotional_stores'][index]['image_url']}",
                                                  storeName:
                                                      "${promotionalStores['promotional_stores'][index]['name']}\n",
                                                  distance: promotionalStores[
                                                              'promotional_stores']
                                                          [index]['distance']
                                                      .toStringAsFixed(2),
                                                  rating: promotionalStores[
                                                              'promotional_stores']
                                                          [index]['user_rate']
                                                      .toStringAsFixed(2),
                                                  ratingCount: promotionalStores[
                                                              'promotional_stores']
                                                          [
                                                          index]['user_rate_count']
                                                      .toString(),
                                                  deliveryType: promotionalStores[
                                                          'promotional_stores']
                                                      [index]['delivery_type'],
                                                  isFeatured: true,
                                                  featuredTag: promotionalStores[
                                                              'promotional_stores']
                                                          [index]['promo_tags']
                                                      .toString()
                                                      .toLowerCase(),
                                                  press: () async {
                                                    print(
                                                        "Promotional store pressed...");
                                                    bool isOp = await storeOpen(
                                                        promotionalStores[
                                                                'promotional_stores']
                                                            [index]);

                                                    if (isOp) {
                                                      print("Open");
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return ProductScreen(
                                                              store: promotionalStores[
                                                                      'promotional_stores']
                                                                  [index],
                                                              isOpen: isOp,
                                                              location: promotionalStores[
                                                                          'promotional_stores']
                                                                      [index]
                                                                  ['location'],
                                                              longitude: Provider.of<
                                                                          ZMetaData>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .longitude,
                                                              latitude: Provider.of<
                                                                          ZMetaData>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .latitude,
                                                            );
                                                          },
                                                        ),
                                                      ).then((value) {
                                                        getCart();
                                                        _doLocationTask();
                                                        getNearByMerchants();
                                                      });
                                                    } else {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          Service.showMessage(
                                                              "Store is currently closed. We highly recommend you to try other store. We've got them all...",
                                                              false,
                                                              duration: 3),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                            separatorBuilder:
                                                (BuildContext context,
                                                        int index) =>
                                                    SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 2),
                                            ),
                                          ),
                                        )
                                      : userData != null
                                          ? _loading
                                              ? SpinKitWave(
                                                  color: kSecondaryColor,
                                                  size:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding),
                                                )
                                              : Container(
                                                  height:
                                                      getProportionateScreenHeight(
                                                          kDefaultPadding * 6),
                                                  child: Center(
                                                    child: Text(
                                                        "Nothing to show, please try again..."),
                                                  ),
                                                )
                                          : Container(
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 6),
                                              child: Center(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        getProportionateScreenWidth(
                                                            kDefaultPadding),
                                                  ),
                                                  child: Text(
                                                      "Nothing to show, please login..."),
                                                ),
                                              ),
                                            ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                      promotionalStores != null && promotionalStores['success']
                          ? SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4),
                            )
                          : SizedBox.shrink(),

                      Container(
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                        ),
                        padding: EdgeInsets.only(
                          bottom:
                              getProportionateScreenHeight(kDefaultPadding / 2),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding),
                              ),
                              child: SectionTitle(
                                sectionTitle: Provider.of<ZLanguage>(context)
                                    .whatWould, //what would you like to order
                                subTitle: " ",
                              ),
                            ),
                            Container(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding * 8),
                              margin: EdgeInsets.only(
                                  right: getProportionateScreenWidth(
                                      kDefaultPadding / 2)),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    categories != null ? categories.length : 0,
                                itemBuilder: (context, index) => Row(
                                  children: [
                                    index == 0
                                        ? SizedBox(
                                            width: getProportionateScreenWidth(
                                                kDefaultPadding),
                                          )
                                        : Container(),
                                    InkWell(
                                      onTap: () async {
                                        double lat = Provider.of<ZMetaData>(
                                                context,
                                                listen: false)
                                            .latitude;
                                        double long = Provider.of<ZMetaData>(
                                                context,
                                                listen: false)
                                            .longitude;

                                        if (responseData != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return StoreScreen(
                                                  cityId: responseData['city']
                                                      ['_id'],
                                                  storeDeliveryId:
                                                      categories[index]['_id'],
                                                  category: categories[index],
                                                  latitude: lat,
                                                  longitude: long,
                                                  isStore: false,
                                                  companyId: -1,
                                                );
                                              },
                                            ),
                                          ).then((value) {
                                            if (userData != null) {
                                              _getPromotionalItems();
                                              // controller?.getFavorites();
                                              getUserOrderCount();
                                              _doLocationTask();
                                              getNearByMerchants();
                                            }
                                          });
                                        } else {
                                          getCategories();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return StoreScreen(
                                                  cityId: responseData['city']
                                                      ['_id'],
                                                  storeDeliveryId:
                                                      categories[index]['_id'],
                                                  category: categories[index],
                                                  latitude: lat,
                                                  longitude: long,
                                                  isStore: false,
                                                  companyId: -1,
                                                );
                                              },
                                            ),
                                          ).then((value) {
                                            if (userData != null) {
                                              _getPromotionalItems();
                                              controller?.getFavorites();
                                              getUserOrderCount();
                                              _doLocationTask();
                                              getNearByMerchants();
                                            }
                                          });
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl:
                                                "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[index]['image_url']}",
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              // margin: EdgeInsets.all(5),
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * 5),
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 5),
                                              decoration: BoxDecoration(
                                                color: kWhiteColor,
                                                borderRadius: BorderRadius.circular(
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding)),
                                                image: DecorationImage(
                                                  fit: BoxFit.contain,
                                                  image: imageProvider,
                                                ),
                                              ),
                                            ),
                                            placeholder: (context, url) =>
                                                Center(
                                              child: Container(
                                                width:
                                                    getProportionateScreenWidth(
                                                        kDefaultPadding * 4),
                                                height:
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding * 4),
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(kWhiteColor),
                                                ),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * 5),
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 6),
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  fit: BoxFit.contain,
                                                  image: AssetImage(zmallLogo),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 3),
                                          ),
                                          Text(
                                            categories[index]
                                                        ['delivery_name'] ==
                                                    "FOOD DELIVERY"
                                                ? "FOOD"
                                                : categories[index]
                                                    ['delivery_name'],
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
                                  ],
                                ),
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        SizedBox(
                                  width: getProportionateScreenWidth(
                                      kDefaultPadding / 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      !isLaundryActive
                          ? SizedBox.shrink()
                          : SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4),
                            ),

                      !isLaundryActive
                          ? SizedBox.shrink()
                          : Container(
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle: "Laundry Pick & Drop",
                                      subTitle: " ",
                                    ),
                                  ),
                                  CustomBanner(
                                    // imageUrl: 'images/laundry.png',
                                    isNetworkImage:
                                        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[laundryIndex]['image_url']}"
                                                .isNotEmpty
                                            ? true
                                            : false,
                                    imageUrl: isNetworkImage("laundry")
                                        ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[laundryIndex]['image_url']}"
                                        : "images/laundry.png",
                                    title: "Laundry Pick & Drop",
                                    subtitle: "",
                                    press: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => StoreScreen(
                                                  cityId: responseData['city']
                                                      ['_id'],
                                                  storeDeliveryId:
                                                      categories[laundryIndex]
                                                          ['_id'],
                                                  category:
                                                      categories[laundryIndex],
                                                  latitude:
                                                      Provider.of<ZMetaData>(
                                                              context,
                                                              listen: false)
                                                          .latitude,
                                                  longitude:
                                                      Provider.of<ZMetaData>(
                                                              context,
                                                              listen: false)
                                                          .longitude,
                                                  isStore: false,
                                                  companyId: -1,
                                                )),
                                      ).then((value) {
                                        if (userData != null) {
                                          _getPromotionalItems();
                                          getUserOrderCount();
                                          _doLocationTask();
                                          getNearByMerchants();
                                        }
                                      });
                                    },
                                  )
                                ],
                              ),
                            ),
                      !isLaundryActive
                          ? SizedBox.shrink()
                          : SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4),
                            ),
                      /////////////////////////////Aliexpress section////////////////
                      services == null ||
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'aliexpress'))
                          ? SizedBox.shrink()
                          : Container(
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle: "AliExpress",
                                      subTitle: " ",
                                    ),
                                  ),
                                  CustomBanner(
                                    isNetworkImage:
                                        isNetworkImage("aliexpress"),
                                    imageUrl: isNetworkImage("aliexpress")
                                        ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${services[getServiceIndex("aliexpress")]['image_url']}"
                                        : "images/aliexpress-banner.png",
                                    title: "AliExpress",
                                    subtitle: "",
                                    press: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AliProductListScreen(),
                                        ),
                                      ).then((value) {
                                        if (userData != null) {
                                          _getPromotionalItems();
                                          getUserOrderCount();
                                          _doLocationTask();
                                          getNearByMerchants();
                                        }
                                      });
                                    },
                                  )
                                ],
                              ),
                            ),
                      services == null ||
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'aliexpress'))
                          ? SizedBox.shrink()
                          : SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4),
                            ),
                      //////////////finish aliexpress//////////////////
                      nearbyStores != null && nearbyStores.length > 0
                          ? Container(
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle:
                                          Provider.of<ZLanguage>(context)
                                              .nearbyStores, //Nearby stores
                                      subTitle: " ",
                                    ),
                                  ),
                                  Container(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding * 12),
                                    width: double.infinity,
                                    padding: EdgeInsets.only(
                                      right: getProportionateScreenWidth(
                                          kDefaultPadding / 2),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: nearbyStores != null &&
                                              nearbyStores.length > 0
                                          ? nearbyStores.length
                                          : 0,
                                      itemBuilder: (context, index) => Row(
                                        children: [
                                          index == 0
                                              ? SizedBox(
                                                  width:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding),
                                                )
                                              : Container(),
                                          StoresCard(
                                            imageUrl:
                                                "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${nearbyStores[index]['image_url']}",
                                            storeName:
                                                "${nearbyStores[index]['name']}\n",
                                            distance: nearbyStores[index]
                                                    ['distance']
                                                .toStringAsFixed(2),
                                            rating: nearbyStores[index]
                                                    ['user_rate']
                                                .toStringAsFixed(2),
                                            ratingCount: nearbyStores[index]
                                                    ['user_rate_count']
                                                .toString(),
                                            deliveryType: nearbyStores[index]
                                                    ['delivery_type_detail']
                                                ['delivery_name'],
                                            press: () async {
                                              print(
                                                  "Promotional item pressed...");
                                              bool isOp = await storeOpen(
                                                  nearbyStores[index]);

                                              if (isOp) {
                                                print("Open");
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) {
                                                      return ProductScreen(
                                                        store:
                                                            nearbyStores[index],
                                                        isOpen: isOp,
                                                        location:
                                                            nearbyStores[index]
                                                                ['location'],
                                                        longitude: Provider.of<
                                                                    ZMetaData>(
                                                                context,
                                                                listen: false)
                                                            .longitude,
                                                        latitude: Provider.of<
                                                                    ZMetaData>(
                                                                context,
                                                                listen: false)
                                                            .latitude,
                                                      );
                                                    },
                                                  ),
                                                ).then((value) {
                                                  getCart();
                                                  _doLocationTask();
                                                  getNearByMerchants();
                                                });
                                              } else {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    Service.showMessage(
                                                        "Store is currently closed. We highly recommend you to try other store. We've got them all...",
                                                        false,
                                                        duration: 3),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      separatorBuilder:
                                          (BuildContext context, int index) =>
                                              SizedBox(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding / 2),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                      // SizedBox(
                      //   height:
                      //       getProportionateScreenHeight(kDefaultPadding / 4),
                      // ),
                      /////////Pridiction Started
                      Provider.of<ZMetaData>(context, listen: false).country ==
                                      "Ethiopia" &&
                                  DateTime.now().isBefore(predictEnd) &&
                                  DateTime.now().isAfter(predictStart) &&
                                  services == null ||
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'prediction'))
                          ? SizedBox.shrink()
                          : SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4),
                            ),
                      Provider.of<ZMetaData>(context, listen: false).country ==
                                      "Ethiopia" &&
                                  DateTime.now().isBefore(predictEnd) &&
                                  DateTime.now().isAfter(predictStart) &&
                                  services == null ||
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'prediction'))
                          ? SizedBox.shrink()
                          : Container(
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle: DateTime.now()
                                                  .isBefore(euroPredictEnd) &&
                                              DateTime.now()
                                                  .isAfter(euroPredictStart)
                                          ? "UEFA Euro 2024"
                                          : "Predict ${DateTime.now().year % 100}/${(DateTime.now().year + 1) % 100}",
                                      subTitle: " ",
                                    ),
                                  ),
                                  CustomBanner(
                                    isNetworkImage:
                                        isNetworkImage("prediction"),
                                    imageUrl: isNetworkImage("prediction")
                                        ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${services[getServiceIndex("prediction")]['image_url']}"
                                        : DateTime.now()
                                                    .isBefore(euroPredictEnd) &&
                                                DateTime.now()
                                                    .isAfter(euroPredictStart)
                                            ? 'images/pl_logos/game_banner.png'
                                            : 'images/predict_pl.png',
                                    title: "Predict & Win",
                                    subtitle: "",
                                    press: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WorldCupScreen(),
                                        ),
                                      ).then((value) {
                                        if (userData != null) {
                                          _getPromotionalItems();
                                          getUserOrderCount();
                                          _doLocationTask();
                                          getNearByMerchants();
                                        }
                                      });
                                    },
                                  )
                                ],
                              ),
                            ),
                      /////////////// WORLD CUP/////////////////

                      services == null ||
                              // services.length > 1 &&
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'lunch from home'))
                          ? SizedBox.shrink()
                          : SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4),
                            ),
                      services == null ||
                              //  &&services.length > 1 &&
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'lunch from home'))
                          ? SizedBox.shrink()
                          : Container(
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle:
                                          Provider.of<ZLanguage>(context)
                                              .missingHome,
                                      subTitle: " ",
                                    ),
                                  ),
                                  services != null && services.length > 1
                                      ? CustomBanner(
                                          isNetworkImage:
                                              isNetworkImage("lunch from home"),
                                          imageUrl: isNetworkImage(
                                                  "lunch from home")
                                              ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${services[getServiceIndex("lunch from home")]['image_url']}"
                                              : 'images/deal-of-the-day.png',
                                          title: "Let us get your lunch from\n",
                                          subtitle: "HOME",
                                          press: () async {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    LunchHomeScreen(
                                                  curLat:
                                                      Provider.of<ZMetaData>(
                                                              context,
                                                              listen: false)
                                                          .latitude,
                                                  curLon:
                                                      Provider.of<ZMetaData>(
                                                              context,
                                                              listen: false)
                                                          .longitude,
                                                ),
                                              ),
                                            ).then((value) {
                                              if (userData != null) {
                                                _getPromotionalItems();
                                                getUserOrderCount();
                                                _doLocationTask();
                                                getNearByMerchants();
                                              }
                                            });
                                          },
                                        )
                                      : SizedBox.shrink(),
                                ],
                              ),
                            ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 4),
                      ),

                      services == null ||
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'courier'))
                          ? SizedBox.shrink()
                          : Container(
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle:
                                          Provider.of<ZLanguage>(context)
                                              .thinkingOf,
                                      subTitle: " ",
                                    ),
                                  ),
                                  services != null
                                      ? CustomBanner(
                                          isNetworkImage:
                                              isNetworkImage("courier"),
                                          imageUrl: isNetworkImage("courier")
                                              ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${services[getServiceIndex("courier")]['image_url']}"
                                              : 'images/courier_delivery.png',
                                          title: "Send and receive with\n",
                                          subtitle: "COURIER",
                                          press: () async {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CourierScreen(
                                                  curLat:
                                                      Provider.of<ZMetaData>(
                                                              context,
                                                              listen: false)
                                                          .latitude,
                                                  curLon:
                                                      Provider.of<ZMetaData>(
                                                              context,
                                                              listen: false)
                                                          .longitude,
                                                ),
                                              ),
                                            ).then((value) {
                                              if (userData != null) {
                                                _getPromotionalItems();
                                                getUserOrderCount();
                                                _doLocationTask();
                                                getNearByMerchants();
                                              }
                                            });
                                          },
                                        )
                                      : SizedBox.shrink(),
                                ],
                              ),
                            ),
                      // services != null
                      //     ? SizedBox(
                      //         height: getProportionateScreenHeight(
                      //             kDefaultPadding / 4),
                      //       )
                      //     : Container(),
                      // Container(
                      //   padding: EdgeInsets.only(
                      //     bottom: getProportionateScreenHeight(
                      //         kDefaultPadding / 2),
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: kPrimaryColor,
                      //   ),
                      //   child: Column(
                      //     children: [
                      //       Padding(
                      //         padding: EdgeInsets.symmetric(
                      //           horizontal: getProportionateScreenWidth(
                      //               kDefaultPadding),
                      //         ),
                      //         child: SectionTitle(
                      //           sectionTitle: Provider.of<ZLanguage>(context)
                      //               .yourFavorites,
                      //           subTitle: " ",
                      //         ),
                      //       ),
                      //       // SizedBox(
                      //       //   height:
                      //       //       getProportionateScreenHeight(kDefaultPadding / 2),
                      //       // ),
                      //       userData != null
                      //           ? Container(
                      //               height: getProportionateScreenHeight(
                      //                   kDefaultPadding * 10),
                      //               width: double.infinity,
                      //               padding: EdgeInsets.only(
                      //                 right: getProportionateScreenWidth(
                      //                     kDefaultPadding / 2),
                      //               ),
                      //               child: FavoritesScreen(
                      //                 controller: controller,
                      //                 latitude: Provider.of<ZMetaData>(context, listen: false).latitude,
                      //                 longitude: Provider.of<ZMetaData>(context, listen: false).longitude,
                      //               ),
                      //             )
                      //           : Container(
                      //               height: getProportionateScreenHeight(
                      //                   kDefaultPadding * 6),
                      //               child: Center(
                      //                 child: Padding(
                      //                   padding: EdgeInsets.symmetric(
                      //                     horizontal:
                      //                         getProportionateScreenWidth(
                      //                             kDefaultPadding),
                      //                   ),
                      //                   child: Text(
                      //                     "Please login to add all of your favorites...",
                      //                     textAlign: TextAlign.center,
                      //                   ),
                      //                 ),
                      //               ),
                      //             ),
                      //     ],
                      //   ),
                      // ),
                      services == null ||
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'courier'))
                          ? SizedBox.shrink()
                          : SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4),
                            ),
                      services == null ||
                              (services.isEmpty ||
                                  !services.any((delivery) =>
                                      delivery['delivery_name']
                                          ?.toString()
                                          .toLowerCase() ==
                                      'event'))
                          ? SizedBox.shrink()
                          : Container(
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    child: SectionTitle(
                                      sectionTitle:
                                          Provider.of<ZLanguage>(context)
                                              .discover,
                                      subTitle: " ",
                                    ),
                                  ),
                                  services != null
                                      ? CustomBanner(
                                          isNetworkImage:
                                              isNetworkImage("event"),
                                          imageUrl: isNetworkImage("event")
                                              ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${services[getServiceIndex("event")]['image_url']}"
                                              : 'images/events.png',
                                          title: "",
                                          subtitle: "EVENTS",
                                          press: () async {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EventsScreen(),
                                              ),
                                            ).then((value) {
                                              if (userData != null) {
                                                _getPromotionalItems();
                                                getUserOrderCount();
                                                _doLocationTask();
                                                getNearByMerchants();
                                              }
                                            });

                                            // ScaffoldMessenger.of(context)
                                            //     .showSnackBar(Service.showMessage(
                                            //         "COMING SOON", false,
                                            //         duration: 5));
                                          },
                                        )
                                      : SizedBox.shrink(),
                                ],
                              ),
                            ),

                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                    ],
                  ),
                )
              : !_loading
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding * 4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(
                            title: "Retry",
                            press: () {
                              print("Retry...");
                              getNearByMerchants();
                            },
                            color: kSecondaryColor,
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<dynamic> getCategoryList(double longitude, double latitude,
      String countryCode, String countryName) async {
    setState(() {
      _loading = true;
    });

    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_delivery_list_for_nearest_city";
    Map data = {
      "latitude": Provider.of<ZMetaData>(context, listen: false).latitude,
      "longitude": Provider.of<ZMetaData>(context, listen: false).longitude,
      "country": Provider.of<ZMetaData>(context, listen: false).country,
      "country_code": Provider.of<ZMetaData>(context, listen: false).countryId
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _loading = false;
      });
      await Service.save('categories', json.decode(response.body));

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Something went wrong! Please check your internet connection!"),
            backgroundColor: kSecondaryColor,
          ),
        );
      }
      return null;
    }
  }

  Future<dynamic> getServicesList(double longitude, double latitude,
      String countryCode, String countryName) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_delivery_list_for_nearest_city";
    Map data = {
      "country": countryName,
      "country_code": countryCode,
      "longitude": longitude,
      "latitude": latitude,
      "delivery_type": 2
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
          throw TimeoutException("The connection has timed out!");
        },
      );

      await Service.save('services', json.decode(response.body));

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Something went wrong! Please check your internet connection!"),
            backgroundColor: kSecondaryColor,
          ),
        );
      }

      return null;
    }
  }

  Future<dynamic> getItemInformation(itemId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_item_information";
    Map data = {
      "item_id": itemId,
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
            Service.showMessage("Something went wrong!", true, duration: 3),
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.notificationItem = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      if (mounted) {
        setState(() {
          this._loading = false;
        });
      }

      return null;
    }
  }

  Future<dynamic> getNearbyStores() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_company_list_front_page";
    Map data = {
      "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
      "longitude": Provider.of<ZMetaData>(context, listen: false).longitude,
      "latitude": Provider.of<ZMetaData>(context, listen: false).latitude,
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
            Service.showMessage("Something went wrong!", true, duration: 3),
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.notificationItem = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      if (mounted) {
        setState(() {
          this._loading = false;
        });
      }

      return null;
    }
  }

  ////////////////////////////////////////////////////////////////////////////

  Future<dynamic> getOrders() async {
    setState(() {
      _loading = true;
    });
    var userId = userData['user']['_id'];
    var server_token = userData['user']['server_token'];
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_orders";
    Map data = {
      "user_id": userId,
      "server_token": server_token,
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

//////////////////////////////////////////////////////////////////////
}

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    Key? key,
    required this.promotionalItems,
  }) : super(key: key);

  final promotionalItems;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: AspectRatio(
        aspectRatio: 1.81,
        child: Stack(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                PageView.builder(
                  onPageChanged: (value) {
                    setState(() {
                      _currentPage = value;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(kDefaultPadding),
                      child: CachedNetworkImage(
                        imageUrl: widget.promotionalItems != null &&
                                widget
                                        .promotionalItems['promotional_items']
                                            [index]['image_url']
                                        .length >
                                    0
                            ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.promotionalItems['promotional_items'][index]['image_url'][0]}"
                            : "www.google.com",
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              image: imageProvider,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Center(
                          child: Container(
                            width: getProportionateScreenWidth(
                                kDefaultPadding * 3.5),
                            height: getProportionateScreenHeight(
                                kDefaultPadding * 3.5),
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(kWhiteColor),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: AssetImage('images/trending.png'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: widget.promotionalItems != null &&
                          widget.promotionalItems['promotional_items'].length >
                              0
                      ? widget.promotionalItems['promotional_items'].length
                      : 0,
                ),
                Positioned(
                  bottom: getProportionateScreenWidth(kDefaultPadding),
                  right: getProportionateScreenWidth(kDefaultPadding),
                  child: Row(
                    children: List.generate(
                      widget.promotionalItems != null &&
                              widget.promotionalItems['promotional_items']
                                      .length >
                                  0
                          ? widget.promotionalItems['promotional_items'].length
                          : 0,
                      (index) => Padding(
                        padding: EdgeInsets.only(left: kDefaultPadding / 10),
                        child: IndicatorDot(
                          isActive: index == _currentPage,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class IndicatorDot extends StatelessWidget {
  const IndicatorDot({
    Key? key,
    required this.isActive,
  }) : super(key: key);

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getProportionateScreenHeight(kDefaultPadding * .2),
      width: getProportionateScreenWidth(kDefaultPadding * .4),
      decoration: BoxDecoration(
        color: isActive ? kWhiteColor : Colors.white30,
        borderRadius: BorderRadius.circular(kDefaultPadding * .6),
      ),
    );
  }
}
