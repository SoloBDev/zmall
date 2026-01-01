import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:zmall/aliexpress/ali_product_screen.dart';
import 'package:zmall/cart/cart_screen.dart';
import 'package:zmall/home/magazine/screens/magazine_list_screen.dart';
import 'package:zmall/home/yearly_recap/screens/recap_screen.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/controllers/controllers.dart';
import 'package:zmall/services/core_services.dart';
import 'package:zmall/courier/courier_screen.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/events/events_screen.dart';
import 'package:zmall/home/components/category_card_widget.dart';
import 'package:zmall/home/components/custom_banner.dart';
import 'package:zmall/home/components/featured_nearby_stores.dart.dart';
import 'package:zmall/home/components/offer_card.dart';
import 'package:zmall/home/components/stores_card.dart';
import 'package:zmall/home/components/web_view_screen.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/lunch_home/lunch_home_screen.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/notifications/notification_store.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/profile/components/edit_profile.dart';
import 'package:zmall/search/search_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/store/components/custom_list_tile.dart';
import 'package:zmall/store/store_screen.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/section_title.dart';
import 'package:zmall/widgets/sliver_appbar_delegate.dart';
import 'package:zmall/world_cup/prediction_home.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key, this.isLaunched = false});
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
  double? latitude, longitude;
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
  Timer? _locationTimer;
  var orderTo;
  var orderFrom;
  Timer? timer;
  bool _isLocationDialogShown = false;
  // bool _isUpdateScreenShown = false;
  bool _isUpdateDialogShown = false;
  bool _isMessageDialogShown = false;
  List<bool> isPromotionalItemOpen = [];
  List<bool> isProximitylItemOpen = [];
  List<bool> isNearbyStoreOpen = [];
  // late ScrollController _scrollController;
  // bool _isCollapsed = false;

  // Proximity Orders
  List<Map<String, dynamic>> proximityOrdersList = [];
  Timer? _proximityOrderTimer;
  String proximityOrderName = '';
  bool isProximityActive = false;
  // bool isProximityOrder = false;
  int proximityIndex = 0;
  // Recap or Holiday splash
  Map<String, dynamic> recapData = {};
  String holidaySplashServiceName = '';
  bool isHolidaySplashActive = false;
  int holidaySplashIndex = 0;
  bool isRecap = false;
  bool isHolidaySplash = false;

  // Holiday celebration dialog
  bool _hasShownHolidayDialog = false;
  Timer? _holidayDialogTimer;
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  //////////////////////////////

  @override
  void initState() {
    super.initState();

    // Initialize confetti controllers
    _confettiControllerLeft = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiControllerRight = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    getCart();
    isAbroad();
    CoreServices.registerNotification(context);
    MyApp.messaging.triggerEvent("at_home");
    _getToken();
    getUser();
    getLocalPromotionalItems();
    getLocalPromotionalStores();

    // Show holiday celebration dialog
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _showHolidayCelebration();
    // });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // debugPrint("Opened by notification open by app");

      MyApp.analytics.logEvent(name: "notification_opened");
      if (message.data.isNotEmpty && !is_abroad) {
        var notificationData = message.data;
        if (notificationData['item_id'] != null) {
          // debugPrint("Navigate to item screen...");
          _getItemInformation(notificationData['item_id']);
        } else if (notificationData['store_id'] != null) {
          // debugPrint("Navigate to store...");
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
      // debugPrint("=> \tChecking for version update");
      getAppKeys();
    }
    getCategories();
    getServices();
    getNearByServices();
    getNearByMerchants();
  }

  @override
  void dispose() {
    timer?.cancel();
    _locationTimer?.cancel();
    _proximityOrderTimer?.cancel();
    _holidayDialogTimer?.cancel();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    // _scrollController.dispose();
    super.dispose();
  }

  ////////////////newly added
  void _startTimer() async {
    if (userLastOrder != null && latitude != null && longitude != null) {
      double distance = Service.calculateDistance(
        userLocation[0],
        userLocation[1],
        latitude!,
        longitude!,
      );

      if (orderFrom == orderTo &&
          userOrderStatus < 25 &&
          distance > 0.1000 &&
          !_isLocationDialogShown) {
        _isLocationDialogShown = true;

        _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
          if (timer.tick > 1) {
            timer.cancel();
          } else {
            if (!mounted) {
              timer.cancel();
              return;
            }
            showDialog(
              context: context,
              barrierDismissible: Platform.isIOS ? true : false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: kPrimaryColor,
                  title: const Text('Location Changed !'),
                  content: Text(
                    "Just to inform you, there has been a change in your location by ${distance.toStringAsFixed(3)} Km since your last order.",
                  ),
                  titleTextStyle: TextStyle(
                    color: kSecondaryColor,
                    fontSize: 20,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startTimer();
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
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    try {
      var data = await getOrders();
      if (data != null && data['success']) {
        if (mounted) {
          setState(() {
            _loading = false;
            userLastOrder = data['order_list'][0];
            userOrderStatus = userLastOrder['order_status'];
            userLocation =
                userLastOrder['destination_addresses'][0]['location'];
            orderTo =
                userLastOrder['destination_addresses'][0]['user_details']['name'];
            _startTimer();
          });
        }
      }
      // else {
      //   // ScaffoldMessenger.of(context).showSnackBar(
      //   //     Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      // }
    } catch (e) {
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Fetch proximity orders
  void _getProximityOrders() async {
    if (userData == null || latitude == null || longitude == null) {
      return;
    }
    try {
      List<Map<String, dynamic>> orders = await Service.getProximityOrders(
        context: context,
        userLatitude: latitude!,
        userLongitude: longitude!,
        radiusKm: 5.0,
      );

      if (mounted) {
        isProximitylItemOpen.clear();
        setState(() {
          proximityOrdersList = orders; // Now contains items, not orders
        });
        // Check store open status for each item
        for (int i = 0; i < proximityOrdersList.length; i++) {
          bool isProxItemOpen = await Service.isStoreOpen(
            proximityOrdersList[i]['store_detail'],
          );
          isProximitylItemOpen.add(isProxItemOpen);
        }
      }
    } catch (e) {
      // debugPrint("Error: $e");
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
      // debugPrint("Opened by notification open by app");

      MyApp.analytics.logEvent(name: "notification_opened");
      if (message.data.isNotEmpty && !is_abroad) {
        var notificationData = message.data;
        if (notificationData['item_id'] != null) {
          // debugPrint("Navigate to item screen...");
          _getItemInformation(notificationData['item_id']);
        } else if (notificationData['store_id'] != null) {
          // debugPrint("Navigate to store...");
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
      // debugPrint("=> \tChecking for version update");
      getAppKeys();
    }

    getCategories();
    getServices();
    getNearByServices();
    getNearByMerchants();
  }

  //////////////////////////////////
  void _requestLocationPermission() async {
    // First, check if location services are enabled
    bool isLocationServicesEnabled = await FlLocation.isLocationServicesEnabled;
    // debugPrint("is location on in permition $isLocationServicesEnabled");

    if (isLocationServicesEnabled == true) {
      // Then check permissions
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
    } else {
      // Location services are disabled
      Service.showMessage(
        context: context,
        title:
            "Location services are turned off. Please enable them in your device settings.",
        error: true,
      );
      // Exit the function since we can't proceed without location services
      return;
    }
  }

  void getLocation() async {
    // debugPrint("\t=> \ in getLocation>>>>>");
    var currentLocation = await FlLocation.getLocation();
    if (mounted) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
      });
      if (latitude != null && longitude != null) {
        Provider.of<ZMetaData>(
          context,
          listen: false,
        ).setLocation(latitude!, longitude!);
        // debugPrint( "\t=> \ in getLocation>>>>> latitude $latitude-longitude $longitude");
        _getNearbyStores();
      }
    }
  }

  void _doLocationTask() async {
    // debugPrint("checking user location");
    LocationPermission _permissionStatus =
        await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.whileInUse ||
        _permissionStatus == LocationPermission.always) {
      bool isLocationServicesEnabled =
          await FlLocation.isLocationServicesEnabled;
      if (isLocationServicesEnabled == true) {
        getLocation();
      } else {
        Service.showMessage(
          context: context,
          title:
              "Location services are turned off. Please enable them in your device settings.",
          error: true,
        );
        _requestLocationPermission();

        // LocationPermission serviceStatus =
        //     await FlLocation.requestLocationPermission();
        // if (serviceStatus == LocationPermission.always ||
        //     serviceStatus == LocationPermission.whileInUse) {
        //   getLocation();
        // } else {
        //   ScaffoldMessenger.of(context).showSnackBar(Service.showMessage1(
        //       "Location service disabled. Please enable and try again", true));
        // }
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
    // debugPrint("Fetching data");
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

      // Check if date_of_birth is missing and show dialog
      if (userData['user']['date_of_birth'] == null ||
          userData['user']['date_of_birth'].toString().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUpdateProfileDialog();
        });
      }
    }
  }

  void _showUpdateProfileDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFED2437), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kBlackColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Please update your date of birth to complete your profile and enjoy personalized features.',
            style: TextStyle(
              fontSize: 14,
              color: kBlackColor.withValues(alpha: 0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Later',
                style: TextStyle(color: kBlackColor, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to edit profile page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfile(userData: userData),
                  ),
                ).then((_) {
                  // Refresh user data when returning from edit profile
                  getUser();
                });
              },
              child: Text(
                'Update Profile',
                style: TextStyle(
                  color: kSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _getUserDetails(userId, serverToken) async {
    setState(() {
      _loading = false;
    });
    var data = await CoreServices.getUserDetail(userId, serverToken, context);

    if (data != null && data['success']) {
      if (mounted) {
        setState(() {
          _loading = false;
          userData = data;
          Service.save('user', userData);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      if (data != null && data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Service.showMessage(
          context: context,
          title: "${errorCodes['${data['error_code']}']}!",
          error: true,
        );
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
      if (mounted) {
        setState(() {
          Service.saveBool("is_closed", data['message_flag']);
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
          Service.save('app_close', data['app_close']);
          Service.save('app_open', data['app_open']);
        });
      }
      if (data['message_flag'] && !_isMessageDialogShown) {
        _isMessageDialogShown = true;
        showSimpleNotification(
          Text("⚠️ NOTICE ⚠️", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${data['message']}\n"),
          background: kBlackColor,
          duration: Duration(seconds: 7),
          elevation: 2.0,
          autoDismiss: false,
          // slideDismiss: true,
          slideDismissDirection: DismissDirection.up,
        );
      }
      getAppKeys();
    } else {
      getAppKeys();
    }
  }

  Future<void> getAppKeys() async {
    try {
      // Read backend values
      var data = await Service.read('ios_app_version');
      var currentVersion = await Service.read('version');
      // var isClosed = await Service.readBool('is_closed') ?? await Service.readBool('is_closed');
      // var promptMessage = await Service.read('closed_message');
      var showUpdateDialog = await Service.readBool('ios_update_dialog');

      // debugPrint("=====================");
      // debugPrint("Backend version: $data, Current version: $currentVersion");

      if (data != null &&
          currentVersion.toString() != data.toString() &&
          showUpdateDialog == true &&
          !_isUpdateDialogShown) {
        _isUpdateDialogShown = true;

        // debugPrint("\t=> \tShowing update dialog...");

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, // cannot dismiss by tapping outside
            builder: (BuildContext ctx) {
              return PopScope(
                canPop: false, // disable back button
                child: AlertDialog(
                  backgroundColor: kPrimaryColor,
                  title: const Text(
                    "New Version Update",
                    style: TextStyle(color: kBlackColor),
                  ),
                  content: const Text(
                    "Looks like you’re using an older version of the app 🚀. Update now to enjoy the latest features and improvements!",
                    style: TextStyle(color: kBlackColor),
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
                        Navigator.of(ctx).pop();
                        _isUpdateDialogShown = false; // allow again if needed
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
      }

      // If you need UI refresh after the check
      if (context.mounted) {
        (context as Element).markNeedsBuild();
      }
    } catch (e) {
      // debugPrint("Error while checking for update: $e\n$st");
    }
  }

  // void getAppKeys() async {
  //   var data = await Service.read('ios_app_version');
  //   var currentVersion = await Service.read('version');
  //   _isClosed = await Service.readBool('is_closed') ??
  //       await Service.readBool('is_closed');
  //   promptMessage = await Service.read('closed_message');
  //   var showUpdateDialog = await Service.readBool('ios_update_dialog');
  //   debugPrint("=====================");
  //   if (data != null) {
  //     if (currentVersion.toString() != data.toString()) {
  //       // if (showUpdateDialog && !_isUpdateDialogShown) {
  //       //   _isUpdateDialogShown = true;
  //       if (showUpdateDialog) {
  //         debugPrint("\t=> \tShowing update dialog...");
  //         showDialog(
  //           barrierDismissible: false,
  //           context: context,
  //           builder: (BuildContext context) {
  //             return AlertDialog(
  //               backgroundColor: kPrimaryColor,
  //               title: Text("New Version Update"),
  //               content: Text(
  //                   "We have detected an older version on the App on your phone."),
  //               actions: <Widget>[
  //                 TextButton(
  //                   child: Text(
  //                     "Update Now",
  //                     style: TextStyle(
  //                       color: kSecondaryColor,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   onPressed: () {
  //                     Service.launchInWebViewOrVC("http://onelink.to/vnchst");
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       }
  //     }
  //   }
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

  //function before sorting items based on current user to store location distance
  // void _getPromotionalItems() async {
  //   setState(() {
  //     _loading = widget.isLaunched;
  //   });
  //   getCart();
  //   var data = await CoreServices.getPromotionalItems(
  //     userId: userData['user']['_id'],
  //     serverToken: userData['user']['server_token'],
  //     ctx: context,
  //     userLocation: [
  //       Provider.of<ZMetaData>(context, listen: false).latitude,
  //       Provider.of<ZMetaData>(context, listen: false).longitude,
  //     ],
  //   );

  //   if (data != null && data['success']) {
  //     if (mounted) {
  //       Service.save('p_items', data);
  //       setState(() {
  //         promotionalItems = data;
  //         _loading = false;
  //       });
  //       // debugPrint("promotionalItems $promotionalItems");
  //       getLocalPromotionalItems();
  //     }
  //   } else {
  //     setState(() {
  //       _loading = false;
  //       promotionalItems = {"success": false, "promotional_items": []};
  //     });
  //     if (data != null && data['error_code'] == 999) {
  //       await CoreServices.clearCache();
  //       Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  //     }
  //   }
  //   if (mounted) {
  //     setState(() {
  //       _loading = false;
  //     });
  //   }
  // }

  // Sorted promotional items by distance to store
  void _getPromotionalItems() async {
    setState(() {
      _loading = widget.isLaunched;
    });
    try {
      getCart();

      var data = await CoreServices.getPromotionalItems(
        userId: userData['user']['_id'],
        serverToken: userData['user']['server_token'],
        ctx: context,
        userLocation: [
          Provider.of<ZMetaData>(context, listen: false).latitude,
          Provider.of<ZMetaData>(context, listen: false).longitude,
        ],
      );
      // debugPrint("Promotional Items ${data["promotional_items"][0]}");
      if (data != null && data['success']) {
        if (mounted) {
          // Sort promotional items by distance to store
          final userLat = Provider.of<ZMetaData>(
            context,
            listen: false,
          ).latitude;
          final userLng = Provider.of<ZMetaData>(
            context,
            listen: false,
          ).longitude;

          List<dynamic> items = List.from(data['promotional_items']);

          items.sort((a, b) {
            final storeALoc = a['store_location'];
            final storeBLoc = b['store_location'];

            final distanceA = Service.calculateDistance(
              userLat,
              userLng,
              storeALoc[0],
              storeALoc[1],
            );

            final distanceB = Service.calculateDistance(
              userLat,
              userLng,
              storeBLoc[0],
              storeBLoc[1],
            );

            return distanceA.compareTo(distanceB);
          });

          data['promotional_items'] = items;

          Service.save('p_items', data);
          setState(() {
            promotionalItems = data;
          });

          getLocalPromotionalItems();
        }
      } else {
        setState(() {
          promotionalItems = {"success": false, "promotional_items": []};
        });

        if (data != null && data['error_code'] == 999) {
          await CoreServices.clearCache();
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      }

      // if (mounted) {}
    } catch (e) {
    } finally {
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
      // debugPrint( "promotionalStores ${promotionalStores["promotional_stores"][1]}");
      // 24_7 , discount, exclusive, healthy_option, healthy, holiday_special, limited_offer, local_cuisine, most_popular, new_on_zmall, seasonal, store_closed, top_rated, top_selling, trending
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
  //before is opedned implemented
  // void getLocalPromotionalItems() async {
  //   var data = await Service.read('p_items');
  //   if (data != null) {
  //     setState(() {
  //       promotionalItems = data;
  //     });
  //   } else {
  //     setState(() {
  //       promotionalItems = {"success": false, "promotional_items": []};
  //     });
  //   }
  //   _getPromotionalStores();
  // }

  void getLocalPromotionalItems() async {
    if (userData == null) {
      return;
    }
    isPromotionalItemOpen.clear();
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

    for (int i = 0; i < promotionalItems['promotional_items'].length; i++) {
      bool isPromolItOpen = await Service.isStoreOpen(
        promotionalItems['promotional_items'][i],
      );
      isPromotionalItemOpen.add(isPromolItOpen);
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
    // debugPrint("\t=> \in nearbyStores>>>>>");
    isNearbyStoreOpen.clear();
    setState(() {
      _loading = true;
    });
    var data = await getNearbyStores();
    if (data != null && data['success']) {
      setState(() {
        nearbyStores = data['stores'];
      });
      // debugPrint("\t=> \tGet nearbyStores>>>>> $nearbyStores");
    } // Convert the result of storeOpen to Future<bool> explicitly
    if (nearbyStores != null && isNearbyStoreOpen.isEmpty) {
      for (int i = 0; i < nearbyStores.length; i++) {
        bool isNearbyStOpen = await Service.isStoreOpen(nearbyStores[i]);

        isNearbyStoreOpen.add(isNearbyStOpen);
      }
    } else {
      return;
    }
  }

  void _getItemInformation(String itemId) async {
    setState(() {
      _loading = true;
    });
    try {
      await getItemInformation(itemId);
      if (notificationItem != null && notificationItem['success']) {
        bool isOpen = await Service.isStoreOpen(notificationItem['item']);
        if (isOpen) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ItemScreen(
                  item: notificationItem['item'],
                  location: notificationItem['item']['store_location'],
                );
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
            Service.showMessage(
              context: context,
              title:
                  "Store is currently closed. We highly recommend you to try other store. We've got them all...",
              error: false,
              duration: 3,
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
    } catch (e) {
    } finally {
      setState(() {
        _loading = false;
      });
    }
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
      if (userData != null && userData['user'] != null) {
        // debugPrint( "====>\Current User ${userData['user']['first_name']}\n=======>",);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHolidayCelebration();
        });
        checkProximityService(services);
        checkHolidaySplashService(services);
      }
    }
  }

  String allWordsCapitilize(String str) {
    return str
        .toLowerCase()
        .split(' ')
        .map((word) {
          String leftText = (word.length > 1)
              ? word.substring(1, word.length)
              : '';
          return word[0].toUpperCase() + leftText;
        })
        .join(' ');
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

  void checkProximityService(List serviceList) {
    setState(() {
      proximityIndex = -1;
      isProximityActive = false; // reset first
      _proximityOrderTimer?.cancel(); // cancel any old timer
    });

    for (var i = 0; i < serviceList.length; i++) {
      final tags = serviceList[i]['famous_products_tags'] as List?;

      // Check if service has proximity tags
      bool hasProximityTag =
          tags?.any(
            (tag) =>
                tag.toString().toLowerCase() == 'proximity' ||
                tag.toString().toLowerCase() == 'nearby' ||
                tag.toString().toLowerCase() == 'nearby orders' ||
                tag.toString().toLowerCase() == 'orders near you',
          ) ??
          false;

      if (hasProximityTag) {
        setState(() {
          isProximityActive = true;
          proximityIndex = i;
          proximityOrderName = serviceList[i]['delivery_name']
              .toString()
              .toLowerCase();
        });

        // Cancel any existing timer
        _proximityOrderTimer?.cancel();

        // Initial fetch
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) _getProximityOrders();
        });

        // Start periodic refresh
        _proximityOrderTimer = Timer.periodic(Duration(seconds: 30), (timer) {
          if (mounted) {
            _getProximityOrders();
          }
        });

        break; // Exit loop early since we found it
      }
    }

    if (proximityIndex == -1) {
      if (mounted)
        setState(() {
          isProximityActive = false;
        });

      _proximityOrderTimer?.cancel();
    }
  }

  //Recap service
  void checkHolidaySplashService(List serviceList) async {
    setState(() {
      holidaySplashIndex = -1;
      isHolidaySplashActive = false; // reset first
    });

    for (var i = 0; i < serviceList.length; i++) {
      final tags = serviceList[i]['famous_products_tags'] as List?;

      // Check if service has recap or holiday splash tags
      bool isRecapLocal =
          tags?.any(
            (tag) =>
                tag.toString().toLowerCase() == 'recap' ||
                tag.toString().toLowerCase() == 'wrapped' ||
                tag.toString().toLowerCase() == 'yearly_recap',
          ) ??
          false;

      bool isHolidaySplashLocal =
          tags?.any(
            (tag) =>
                tag.toString().toLowerCase() == 'holiday_splash' ||
                tag.toString().toLowerCase() == 'holiday' ||
                tag.toString().toLowerCase() == 'splash' ||
                tag.toString().toLowerCase() == 'promotion',
          ) ??
          false;

      if (isRecapLocal || isHolidaySplashLocal) {
        setState(() {
          isHolidaySplashActive = true;
          holidaySplashIndex = i;
          holidaySplashServiceName = serviceList[i]['delivery_name']
              .toString()
              .toLowerCase();
          // Prioritize recap if both tags exist
          isRecap = isRecapLocal;
          isHolidaySplash = isHolidaySplashLocal && !isRecapLocal;
        });
        if (isHolidaySplashActive && isRecapLocal) {
          // call API to get user recap data
          var recapResponseData = await CoreServices.getRecapServices(
            userId: userData['user']['_id'],
            serverToken: userData['user']['server_token'],
            context: context,
          );
          if (recapResponseData != null && recapResponseData['success']) {
            if (!mounted) return;
            setState(() {
              recapData = recapResponseData['recap'];
            });
          }
        }
        break; // Found the special service, no need to continue
      }
    }

    if (holidaySplashIndex == -1) {
      if (mounted)
        setState(() {
          isHolidaySplashActive = false;
        });
    }
  }

  int getRecapYear() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final currentDay = now.day;

    // If we're in late December (Dec 15-31), show current year
    if (currentMonth == 12 && currentDay >= 15) {
      return currentYear + 1;
    }
    // If we're in early January (Jan 1-31), show previous year
    else if (currentMonth >= 1) {
      return currentYear;
    }
    // For all other months (Feb-Nov), show previous year
    else {
      return currentYear;
    }
  }

  void _showHolidayCelebration() {
    if (_hasShownHolidayDialog || !mounted) return;

    // Check if there's a service with celebration tag
    Map<String, dynamic>? celebrationService;
    if (services != null && services is List) {
      for (var service in services) {
        final tags = service['famous_products_tags'] as List?;
        final hasCelebration =
            tags?.any(
              (tag) =>
                  tag.toString().toLowerCase() == 'celebration' ||
                  tag.toString().toLowerCase() == 'new year' ||
                  tag.toString().toLowerCase() == 'confetti' ||
                  tag.toString().toLowerCase() == 'new year celebration',
            ) ??
            false;

        if (hasCelebration) {
          celebrationService = service;
          break;
        }
      }
    }

    // Don't show if no celebration tag found in services
    if (celebrationService == null) {
      return;
    }

    // Check if current date is within celebration period (until Jan 3, 2026)
    // final now = DateTime.now();
    // final celebrationEndDate = DateTime(2026,1,3,23,59,59,); // January 3, 2026 at 23:59:59

    // Don't show if past the celebration period
    // if (now.isAfter(celebrationEndDate)) {
    //   return;
    // }

    _hasShownHolidayDialog = true;

    // Show after a short delay to ensure UI is ready
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (BuildContext context) {
          final imageUrl = celebrationService!['image_url'];
          final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main dialog container
                Container(
                  padding: hasImage
                      ? EdgeInsets.zero
                      : EdgeInsets.all(kDefaultPadding * 2),
                  decoration: BoxDecoration(
                    image: hasImage
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/$imageUrl",
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: !hasImage
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFF6B6B),
                              Color(0xFFFF6B6B),
                              Color(0xFFFFD700),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(kDefaultPadding * 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            kDefaultPadding * 2,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(), // Just show the image
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Celebration emoji/icon
                            Text('🎉', style: TextStyle(fontSize: 80)),
                            SizedBox(height: kDefaultPadding),

                            // Service name
                            Text(
                              celebrationService['delivery_name']?.toString() ??
                                  'Happy New Year!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: kDefaultPadding / 2),

                            // Service description
                            if (celebrationService['description'] != null &&
                                celebrationService['description']
                                    .toString()
                                    .isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: kDefaultPadding,
                                ),
                                child: Text(
                                  celebrationService['description'].toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            SizedBox(height: kDefaultPadding),

                            // Decorative emojis
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('✨', style: TextStyle(fontSize: 24)),
                                SizedBox(width: kDefaultPadding / 2),
                                Text('🎊', style: TextStyle(fontSize: 24)),
                                SizedBox(width: kDefaultPadding / 2),
                                Text('🎆', style: TextStyle(fontSize: 24)),
                                SizedBox(width: kDefaultPadding / 2),
                                Text('🎁', style: TextStyle(fontSize: 24)),
                              ],
                            ),
                          ],
                        ),
                ),

                // Left confetti - positioned at top-left corner of dialog
                Positioned(
                  top: 0,
                  left: 0,
                  child: ConfettiWidget(
                    confettiController: _confettiControllerLeft,
                    blastDirection: -3.14 / 4, // radians - DOWN-RIGHT
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    maxBlastForce: 100,
                    minBlastForce: 50,
                    gravity: 0.1,
                    colors: const [
                      Colors.red,
                      Colors.red,
                      Colors.orange,
                      Colors.red,
                    ],
                  ),
                ),

                // Right confetti - positioned at top-right corner of dialog
                Positioned(
                  top: 0,
                  right: 0,
                  child: ConfettiWidget(
                    confettiController: _confettiControllerRight,
                    blastDirection: -3 * 3.14 / 4, // radians - DOWN-LEFT
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    maxBlastForce: 100,
                    minBlastForce: 50,
                    gravity: 0.1,
                    colors: const [
                      Colors.red,
                      Colors.red,
                      Colors.orange,
                      Colors.red,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Start confetti animations
      _confettiControllerLeft.play();
      _confettiControllerRight.play();

      // Auto-dismiss after 7 seconds (between 5-10)
      _holidayDialogTimer = Timer(Duration(seconds: 7), () {
        if (mounted) {
          _confettiControllerLeft.stop();
          _confettiControllerRight.stop();
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    });
  }

  void getNearByMerchants() async {
    // debugPrint("Fetching delivery categories...");
    if (!mounted) return;
    setState(() {
      _loading = true;
    });
    _doLocationTask();
    this.responseData = await getCategoryList(
      Provider.of<ZMetaData>(context, listen: false).longitude,
      Provider.of<ZMetaData>(context, listen: false).latitude,
      Provider.of<ZMetaData>(context, listen: false).countryId!,
      Provider.of<ZMetaData>(context, listen: false).country,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    if (responseData != null && responseData['success']) {
      // debugPrint("\t=>\tGet Merchants Completed...");
      if (!mounted) return;
      setState(() {
        categories = responseData['deliveries'];
      });
      checkLaundryCategory(categories);
    } else {
      if (responseData != null &&
          responseData['error_code'] != null &&
          responseData['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else if (responseData != null &&
          responseData['error_code'] != null &&
          responseData['error_code'] == 813) {
        String country = Provider.of<ZMetaData>(context, listen: false).country;
        if (country == "Ethiopia") {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: Text("ZMall Global!"),
              content: Text(
                "We have detected that your location is not in Addis Ababa. Please proceed to ZMall Global!",
              ),
              actions: [
                CupertinoButton(
                  child: Text('Continue'),
                  onPressed: () async {
                    await Service.saveBool('is_global', true);
                    await Service.saveBool('logged', false);
                    await Service.remove('user');
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/global",
                      (Route<dynamic> route) => false,
                    );
                    // Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted && responseData != null) {
          Service.showMessage(
            context: context,
            title: "${errorCodes['${responseData['error_code']}']}",
            error: true,
          );
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
      Provider.of<ZMetaData>(context, listen: false).country,
    );
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
    if (servicesData != null && servicesData['success']) {
      services = servicesData['deliveries'];
      // debugPrint("\t=> \tGet Services Completed");
      if (userData != null && userData['user'] != null) {
        // debugPrint(  "====>\Current User ${userData['user']['first_name']}\n=======>", );
        _showHolidayCelebration();
        checkProximityService(services);
        checkHolidaySplashService(services);
      }
    } else {
      if (mounted && responseData != null) {
        Service.showMessage(
          context: context,
          title: "${errorCodes['${responseData['error_code']}']}",
          error: true,
        );
      }
      if (servicesData != null && servicesData['error_code'] == 999) {
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

  int getServiceIndex(String serviceName) {
    if (services == null) {
      return -1;
    }
    int index = services.indexWhere(
      (service) =>
          service['delivery_name']?.toString().toLowerCase() ==
          serviceName.toLowerCase(),
    );
    return index;
  }

  bool isNetworkImage(String serviceName) {
    if (services == null) {
      return false;
    }
    bool isNetwork =
        getServiceIndex(serviceName) != -1 &&
        services[getServiceIndex(serviceName)]['image_url']
            .toString()
            .isNotEmpty;
    return isNetwork;
  }

  //Get promotiona items price
  // If no default spec exists, use the first spec’s first price as a fallback.
  String _getPromotionalItemPrice(item) {
    if (item['new_price'] != null && item['new_price'] == 0) {
      // look for a default-selected spec
      for (var i = 0; i < item['specifications'].length; i++) {
        for (var j = 0; j < item['specifications'][i]['list'].length; j++) {
          final spec = item['specifications'][i]['list'][j];
          if (spec['is_default_selected'] == true) {
            return spec['price'].toStringAsFixed(2);
          }
        }
      }

      // fallback to first available price if none are default-selected
      if (item['specifications'].isNotEmpty &&
          item['specifications'][0]['list'].isNotEmpty) {
        final firstSpecPrice = item['specifications'][0]['list'][0]['price'];
        return firstSpecPrice.toStringAsFixed(2);
      }
    } else {
      return item['new_price'] != null
          ? item['new_price'].toStringAsFixed(2)
          : "0.00";
    }

    return "0.00";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: kPrimaryColor,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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

        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: getProportionateScreenWidth(kDefaultPadding),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  CartScreen.routeName,
                ).then((value) => getCart());
              },
              style: IconButton.styleFrom(
                padding: EdgeInsets.all(
                  getProportionateScreenWidth(kDefaultPadding / 1.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 1.5),
                  ),
                ),
              ),
              icon: Badge.count(
                offset: Offset(8, -6),
                alignment: Alignment.topRight,
                count: cart != null ? cart!.items!.length : 0,
                backgroundColor: kSecondaryColor,
                child: Icon(HeroiconsOutline.shoppingCart),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: kSecondaryColor,
        onRefresh: _onRefresh,
        child: ModalProgressHUD(
          color: kPrimaryColor,
          progressIndicator: LinearLoadingIndicator(),

          inAsyncCall: _loading,
          child: categories != null
              ? CustomScrollView(
                  // controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(
                            kDefaultPadding,
                          ),
                          vertical: getProportionateScreenHeight(
                            kDefaultPadding / 2,
                          ),
                        ),
                        decoration: BoxDecoration(color: kPrimaryColor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: getProportionateScreenHeight(
                            kDefaultPadding / 3,
                          ),
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData != null
                                      ? "${Provider.of<ZLanguage>(context, listen: true).hello}, ${userData['user']['first_name']}"
                                      : "${Provider.of<ZLanguage>(context, listen: true).hello}, ${Provider.of<ZLanguage>(context, listen: true).guest}",
                                  // "Delivery Done Right",
                                  style: Theme.of(context).textTheme.labelLarge!
                                      .copyWith(
                                        color: kBlackColor,
                                        fontSize: getProportionateScreenHeight(
                                          kDefaultPadding,
                                        ),
                                        fontWeight: Platform.isIOS
                                            ? FontWeight.bold
                                            : FontWeight.w800,
                                      ),
                                ),
                                userData != null
                                    ? Text(
                                        isRewarded
                                            ? "${Provider.of<ZLanguage>(context, listen: true).youAre} 9 ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                                            : (10 - remainder) != 1
                                            ? "${Provider.of<ZLanguage>(context, listen: true).youAre} ${10 - remainder} ${Provider.of<ZLanguage>(context, listen: true).ordersAway}"
                                            : Provider.of<ZLanguage>(
                                                context,
                                                listen: true,
                                              ).nextOrderCashback,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: kBlackColor.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                      )
                                    : Text(
                                        "Log in for your chance to win delivery cashbacks!",
                                      ),
                              ],
                            ),

                            LinearPercentIndicator(
                              animation: true,
                              lineHeight: getProportionateScreenHeight(
                                kDefaultPadding,
                              ),
                              barRadius: Radius.circular(
                                getProportionateScreenWidth(kDefaultPadding),
                              ),
                              backgroundColor: kBlackColor,
                              progressColor: kSecondaryColor,
                              center: Text(
                                userData != null
                                    ? "$orderCount/${quotient + 1}0"
                                    : "0/10",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: kPrimaryColor,
                                    ),
                              ),
                              percent: userData != null
                                  ? (remainder / 10)
                                  : 0.1,
                            ),

                            /////search section
                            Padding(
                              padding: EdgeInsets.only(
                                top: getProportionateScreenHeight(
                                  kDefaultPadding / 2,
                                ),
                                bottom: getProportionateScreenHeight(
                                  kDefaultPadding / 2,
                                  // userData != null
                                  //     ? kDefaultPadding / 4
                                  //     : kDefaultFontSize / 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return SearchScreen(
                                          cityId: responseData['city']['_id']!,
                                          categories: categories!,
                                          latitude: Provider.of<ZMetaData>(
                                            context,
                                            listen: false,
                                          ).latitude,
                                          longitude: Provider.of<ZMetaData>(
                                            context,
                                            listen: false,
                                          ).longitude,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(20),
                                    ),
                                    // borderRadius: BorderRadius.circular(
                                    //     getProportionateScreenWidth(
                                    //         kDefaultPadding / 1.3)),
                                    color: kWhiteColor,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(20),
                                  ),
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding * 2.8,
                                  ),
                                  // getProportionateScreenHeight(
                                  // kDefaultPadding * 3),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    spacing: getProportionateScreenWidth(
                                      kDefaultPadding,
                                    ),
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.magnifyingGlass,
                                        color: kGreyColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        size: getProportionateScreenHeight(
                                          kDefaultPadding,
                                        ),
                                      ),
                                      Text(
                                        "Looking for something?",
                                        // Provider.of<ZLanguage>(context) .search,
                                        style: TextStyle(
                                          color: kGreyColor.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //////////////Holiday splash Section///////////////////
                    if (services != null &&
                        services != '' &&
                        isHolidaySplashActive &&
                        (isHolidaySplash || (isRecap && recapData.isNotEmpty)))
                      SliverToBoxAdapter(
                        child: GestureDetector(
                          onTap: !isRecap
                              ? null
                              : () {
                                  if (isRecap) {
                                    // Navigate to recap screen
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => RecapScreen(
                                          recapData: recapData,
                                          userId: userData['user']['_id'],
                                          serverToken:
                                              userData['user']['server_token'],
                                        ),
                                      ),
                                    );
                                  }
                                  // else if (isHolidaySplash) {
                                  //   // Navigate to holiday promotion (you can customize this)
                                  //   // For now, could be a web view, custom screen, etc.
                                  //   final url =
                                  //       services[holidaySplashIndex]['description']
                                  //           ?.split('webUrl-')
                                  //           .last;
                                  //   if (url != null && url.isNotEmpty) {
                                  //     Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //         builder: (context) => WebViewScreen(
                                  //           url: url,
                                  //           title:
                                  //               services[holidaySplashIndex]['delivery_name'],
                                  //         ),
                                  //       ),
                                  //     );
                                  //   }
                                  // }
                                },
                          child: recapHolidayWidget(
                            isRecap: isRecap,
                            imageUrl:
                                services[holidaySplashIndex]['image_url'] !=
                                        null &&
                                    services[holidaySplashIndex]['image_url']
                                        .toString()
                                        .isNotEmpty
                                ? services[holidaySplashIndex]['image_url']
                                : null,
                          ),
                        ),
                      ),

                    ///
                    //////////////Categories Section///////////////////
                    SliverToBoxAdapter(
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: getProportionateScreenHeight(
                            kDefaultPadding / 4,
                          ),
                          children: [
                            // if (userData != null)
                            //   Padding(
                            //     padding: EdgeInsets.symmetric(
                            //       horizontal: getProportionateScreenWidth(
                            //         kDefaultPadding,
                            //       ),
                            //     ),
                            //     child: SectionTitle(
                            //       sectionTitle: Provider.of<ZLanguage>(
                            //         context,
                            //       ).whatWould, //what would you like to order
                            //       subTitle: " ",
                            //     ),
                            //   ),
                            Container(
                              height: getProportionateScreenHeight(
                                kDefaultPadding * 5,
                              ),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                itemCount: categories != null
                                    ? categories.length
                                    : 0,
                                itemBuilder: (context, index) => Row(
                                  children: [
                                    CategoryCardWidget(
                                      imageUrl:
                                          "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[index]['image_url']}",
                                      category:
                                          categories[index]['delivery_name'] ==
                                              "FOOD DELIVERY"
                                          ? "Food"
                                          : Service.capitalizeFirstLetters(
                                              categories[index]['delivery_name'],
                                            ),
                                      // selected: null,
                                      onPressed: () {
                                        double lat = Provider.of<ZMetaData>(
                                          context,
                                          listen: false,
                                        ).latitude;
                                        double long = Provider.of<ZMetaData>(
                                          context,
                                          listen: false,
                                        ).longitude;

                                        if (responseData != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return StoreScreen(
                                                  cityId:
                                                      responseData['city']['_id'],
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
                                                  cityId:
                                                      responseData['city']['_id'],
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
                                    ),
                                  ],
                                ),
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                            kDefaultPadding / 4,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /////////////Promotional Items Section///////////////////
                    // promotionalItems != null && promotionalItems['success']
                    if (promotionalItems != null &&
                        promotionalItems['success'] &&
                        promotionalItems['promotional_items'] != null &&
                        promotionalItems['promotional_items'].isNotEmpty &&
                        promotionalItems['promotional_items'].length > 0)
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(color: kPrimaryColor),
                          margin: EdgeInsets.only(
                            bottom: getProportionateScreenWidth(
                              kDefaultPadding / 2,
                            ),
                          ),
                          child: Column(
                            spacing: getProportionateScreenHeight(
                              kDefaultPadding / 2,
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                child: SectionTitle(
                                  sectionTitle: Provider.of<ZLanguage>(
                                    context,
                                  ).specialForYou,
                                  subTitle: " ",
                                ),
                              ),
                              Container(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding * 9,
                                ),
                                width: double.infinity,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(
                                      kDefaultPadding,
                                    ),
                                  ),
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          SizedBox(
                                            width: getProportionateScreenWidth(
                                              kDefaultPadding / 2,
                                            ),
                                          ),
                                  //befor is store closed implemented
                                  // itemCount: promotionalItems != null &&
                                  //         promotionalItems
                                  //             .isNotEmpty &&
                                  //         promotionalItems[
                                  //                     'promotional_items']
                                  //                 .length >
                                  //             0
                                  //     ? promotionalItems[
                                  //             'promotional_items']
                                  //         .length
                                  //     : 0,
                                  itemCount:
                                      promotionalItems != null &&
                                          isPromotionalItemOpen.isNotEmpty
                                      ? isPromotionalItemOpen.length
                                      : 0,
                                  itemBuilder: (context, index) {
                                    final item =
                                        promotionalItems['promotional_items'][index];
                                    return Row(
                                      children: [
                                        SpecialOfferCard(
                                          isOpen:
                                              isPromotionalItemOpen[index], // to check if store is closed
                                          imageUrl:
                                              promotionalItems != null &&
                                                  (item['image_url'] != null &&
                                                      item['image_url'].length >
                                                          0)
                                              ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${item['image_url'][0]}"
                                              : "www.google.com",
                                          itemName: item['name'] ?? '',
                                          newPrice:
                                              "${item['price'] != null ? item['price'].toStringAsFixed(2) : 0}\t",
                                          originalPrice:
                                              // item['new_price'] != null &&
                                              //     item['new_price'] != 0
                                              // ? "${item['new_price'].toStringAsFixed(2)}"
                                              // :
                                              _getPromotionalItemPrice(item),

                                          isDiscounted:
                                              item['discount'] ?? false,
                                          storeName: item['store_name'] ?? '',
                                          specialOffer:
                                              item['special_offer'] ?? '',
                                          storePress: () async {
                                            bool isOp =
                                                isPromotionalItemOpen[index];
                                            // await Service.isStoreOpen(item);

                                            if (isOp) {
                                              // debugPrint( "================>>>>>>>>");
                                              // debugPrint("object isOp $isOp");
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return NotificationStore(
                                                      storeId: item['store_id'],
                                                    );
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
                                            // debugPrint("Promotional item pressed...");
                                            bool isOp =
                                                await Service.isStoreOpen(item);

                                            if (isOp) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return ItemScreen(
                                                      item: item,
                                                      location:
                                                          item['store_location'],
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
                                                Service.showMessage(
                                                  context: context,
                                                  title:
                                                      "Store closed. Try another one!",
                                                  error: true,
                                                  duration: 3,
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // : SliverToBoxAdapter(child: Container()),

                    ////////////////////Featured Stores Section///////////////////
                    if (promotionalStores != null &&
                        promotionalStores['success'] &&
                        promotionalStores['promotional_stores'] != null &&
                        promotionalStores['promotional_stores'].isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: getProportionateScreenWidth(
                              kDefaultPadding / 2,
                            ),
                          ),
                          child: Column(
                            spacing: getProportionateScreenHeight(
                              kDefaultPadding / 4,
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                child: SectionTitle(
                                  sectionTitle: Provider.of<ZLanguage>(
                                    context,
                                  ).featuredStores,
                                  // subTitle: " ",
                                  subTitle: "See More",
                                  onSubTitlePress: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return NearbyStoresScreen(
                                            isPromotional: true,
                                            longitude: Provider.of<ZMetaData>(
                                              context,
                                              listen: false,
                                            ).longitude,
                                            latitude: Provider.of<ZMetaData>(
                                              context,
                                              listen: false,
                                            ).latitude,
                                            storesList:
                                                promotionalStores['promotional_stores'],
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding * 8,
                                ),
                                width: double.infinity,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(
                                      kDefaultPadding,
                                    ),
                                  ),
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          SizedBox(
                                            width: getProportionateScreenWidth(
                                              kDefaultPadding / 2,
                                            ),
                                          ),
                                  itemCount:
                                      promotionalStores['success'] &&
                                          promotionalStores['promotional_stores']
                                                  .length >
                                              0
                                      ? promotionalStores['promotional_stores']
                                            .length
                                      : 0,
                                  itemBuilder: (context, index) => Row(
                                    children: [
                                      StoresCard(
                                        imageUrl:
                                            "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${promotionalStores['promotional_stores'][index]['image_url']}",
                                        storeName:
                                            "${promotionalStores['promotional_stores'][index]['name']}\n",
                                        distance:
                                            promotionalStores['promotional_stores'][index]['distance']
                                                .toStringAsFixed(2),
                                        rating:
                                            promotionalStores['promotional_stores'][index]['user_rate']
                                                .toStringAsFixed(2),
                                        ratingCount:
                                            promotionalStores['promotional_stores'][index]['user_rate_count']
                                                .toString(),
                                        deliveryType:
                                            promotionalStores['promotional_stores'][index]['delivery_type'],
                                        isFeatured: true,
                                        featuredTag:
                                            promotionalStores['promotional_stores'][index]['promo_tags']
                                                .toString()
                                                .toLowerCase(),
                                        press: () async {
                                          var store =
                                              promotionalStores['promotional_stores'][index];
                                          // debugPrint(  "Promotional store pressed...");
                                          bool isOp = await Service.isStoreOpen(
                                            store,
                                          );

                                          if (isOp) {
                                            // debugPrint("Open");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  return ProductScreen(
                                                    store:
                                                        promotionalStores['promotional_stores'][index],
                                                    isOpen: isOp,
                                                    location:
                                                        promotionalStores['promotional_stores'][index]['location'],
                                                    longitude:
                                                        Provider.of<ZMetaData>(
                                                          context,
                                                          listen: false,
                                                        ).longitude,
                                                    latitude:
                                                        Provider.of<ZMetaData>(
                                                          context,
                                                          listen: false,
                                                        ).latitude,
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
                                              Service.showMessage(
                                                context: context,
                                                title:
                                                    "Store closed. Try another one!",
                                                error: true,
                                                duration: 3,
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // : SliverToBoxAdapter(child: SizedBox.shrink()),
                    //////////////Proximity Orders section/////////////////
                    if (services != null &&
                        services != '' &&
                        isProximityActive &&
                        proximityOrdersList.isNotEmpty &&
                        proximityOrdersList.length > 0)
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(color: kPrimaryColor),
                          margin: EdgeInsets.only(
                            bottom: getProportionateScreenWidth(
                              kDefaultPadding / 2,
                            ),
                          ),
                          child: Column(
                            spacing: getProportionateScreenHeight(
                              kDefaultPadding / 2,
                            ),

                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Title
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionTitle(
                                      sectionTitle:
                                          Service.capitalizeFirstLetters(
                                            proximityOrderName,
                                          ),
                                      //  "Nearby Orders",
                                      subTitle: " ",
                                      // "${proximityOrdersList.length} available",
                                      // onSubTitlePress: null,
                                    ),
                                    if (services[proximityIndex]['description'] !=
                                            null &&
                                        services[proximityIndex]['description']
                                            .isNotEmpty)
                                      Text(
                                        services[proximityIndex]['description'],
                                      ),
                                  ],
                                ),
                              ),
                              // Horizontal Item List
                              Container(
                                height: getProportionateScreenHeight(
                                  kDefaultPadding * 9,
                                ),
                                margin: EdgeInsets.only(
                                  top: getProportionateScreenHeight(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(
                                      kDefaultPadding,
                                    ),
                                  ),
                                  itemCount:
                                      proximityOrdersList.isNotEmpty &&
                                          isProximitylItemOpen.isNotEmpty
                                      ? isProximitylItemOpen.length
                                      : 0,
                                  // proximityOrdersList.length,
                                  itemBuilder: (context, itemIndex) {
                                    // proximityOrdersList now contains individual items
                                    final item = proximityOrdersList[itemIndex];

                                    // Extract data (already enriched in Service)
                                    final String itemName = item['item_name'];
                                    final List imageUrls = item['image_url'];
                                    final String imageUrl = imageUrls.isNotEmpty
                                        ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${imageUrls[0]}"
                                        : "";

                                    // final double price = (item['item_price']).toDouble();
                                    final String storeName = item['store_name'];
                                    final storeDetail = item['store_detail'];
                                    final storeLocation =
                                        item['store_location'];

                                    return Row(
                                      children: [
                                        SpecialOfferCard(
                                          isOpen:
                                              isProximitylItemOpen[itemIndex],
                                          imageUrl: imageUrl,
                                          itemName: itemName,
                                          newPrice: Service.getPrice(item),
                                          // "${price.toStringAsFixed(2)}\t",
                                          originalPrice: "",
                                          isDiscounted: false,
                                          storeName: storeName,
                                          specialOffer: "",
                                          storePress: () async {
                                            bool isOp =
                                                await Service.isStoreOpen(
                                                  storeDetail,
                                                );

                                            if (isOp) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return NotificationStore(
                                                      storeId:
                                                          storeDetail['_id'],
                                                    );
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
                                            // Build item object compatible with ItemScreen
                                            Map<String, dynamic>
                                            itemForScreen = {
                                              'name': item['item_name'],
                                              'price': item['item_price'],
                                              'image_url': item['image_url'],
                                              'store_location': storeLocation,
                                              'store_name': storeName,
                                              'store_id': storeDetail['_id'],
                                              '_id': item['item_id'],
                                              'unique_id': item['unique_id'],
                                              'details': item['details'],
                                              'quantity': item['quantity'],
                                              'max_item_quantity':
                                                  item['max_item_quantity'],
                                              'specifications':
                                                  item['specifications'],
                                              'note_for_item':
                                                  item['note_for_item'],
                                            };
                                            bool isOp =
                                                isProximitylItemOpen[itemIndex];
                                            // await Service.isStoreOpen(item);
                                            if (isOp) {
                                              // Navigate to ItemScreen with formatted item
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return ItemScreen(
                                                      item: itemForScreen,
                                                      location: storeLocation,
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
                                                Service.showMessage(
                                                  context: context,
                                                  title:
                                                      "Store closed. Try another one!",
                                                  error: true,
                                                  duration: 3,
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                            kDefaultPadding / 2,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    //////////////Categories Section///////////////////
                    // SliverToBoxAdapter(
                    //   child: Container(
                    //     child: Column(
                    //       mainAxisSize: MainAxisSize.min,
                    //       spacing: getProportionateScreenHeight(
                    //         kDefaultPadding / 4,
                    //       ),
                    //       children: [
                    //         if (userData != null)
                    //           Padding(
                    //             padding: EdgeInsets.symmetric(
                    //               horizontal: getProportionateScreenWidth(
                    //                 kDefaultPadding,
                    //               ),
                    //             ),
                    //             child: SectionTitle(
                    //               sectionTitle: Provider.of<ZLanguage>(
                    //                 context,
                    //               ).whatWould, //what would you like to order
                    //               subTitle: " ",
                    //             ),
                    //           ),
                    //         Container(
                    //           height: getProportionateScreenHeight(
                    //             kDefaultPadding * 5,
                    //           ),
                    //           child: ListView.separated(
                    //             scrollDirection: Axis.horizontal,
                    //             padding: EdgeInsets.symmetric(
                    //               horizontal: getProportionateScreenWidth(
                    //                 kDefaultPadding,
                    //               ),
                    //             ),
                    //             itemCount: categories != null
                    //                 ? categories.length
                    //                 : 0,
                    //             itemBuilder: (context, index) => Row(
                    //               children: [
                    //                 CategoryCardWidget(
                    //                   imageUrl:
                    //                       "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[index]['image_url']}",
                    //                   category:
                    //                       categories[index]['delivery_name'] ==
                    //                           "FOOD DELIVERY"
                    //                       ? "Food"
                    //                       : Service.capitalizeFirstLetters(
                    //                           categories[index]['delivery_name'],
                    //                         ),
                    //                   // selected: null,
                    //                   onPressed: () {
                    //                     double lat = Provider.of<ZMetaData>(
                    //                       context,
                    //                       listen: false,
                    //                     ).latitude;
                    //                     double long = Provider.of<ZMetaData>(
                    //                       context,
                    //                       listen: false,
                    //                     ).longitude;

                    //                     if (responseData != null) {
                    //                       Navigator.push(
                    //                         context,
                    //                         MaterialPageRoute(
                    //                           builder: (context) {
                    //                             return StoreScreen(
                    //                               cityId:
                    //                                   responseData['city']['_id'],
                    //                               storeDeliveryId:
                    //                                   categories[index]['_id'],
                    //                               category: categories[index],
                    //                               latitude: lat,
                    //                               longitude: long,
                    //                               isStore: false,
                    //                               companyId: -1,
                    //                             );
                    //                           },
                    //                         ),
                    //                       ).then((value) {
                    //                         if (userData != null) {
                    //                           _getPromotionalItems();
                    //                           // controller?.getFavorites();
                    //                           getUserOrderCount();
                    //                           _doLocationTask();
                    //                           getNearByMerchants();
                    //                         }
                    //                       });
                    //                     } else {
                    //                       getCategories();
                    //                       Navigator.push(
                    //                         context,
                    //                         MaterialPageRoute(
                    //                           builder: (context) {
                    //                             return StoreScreen(
                    //                               cityId:
                    //                                   responseData['city']['_id'],
                    //                               storeDeliveryId:
                    //                                   categories[index]['_id'],
                    //                               category: categories[index],
                    //                               latitude: lat,
                    //                               longitude: long,
                    //                               isStore: false,
                    //                               companyId: -1,
                    //                             );
                    //                           },
                    //                         ),
                    //                       ).then((value) {
                    //                         if (userData != null) {
                    //                           _getPromotionalItems();
                    //                           controller?.getFavorites();
                    //                           getUserOrderCount();
                    //                           _doLocationTask();
                    //                           getNearByMerchants();
                    //                         }
                    //                       });
                    //                     }
                    //                   },
                    //                 ),
                    //               ],
                    //             ),
                    //             separatorBuilder:
                    //                 (BuildContext context, int index) =>
                    //                     SizedBox(
                    //                       width: getProportionateScreenWidth(
                    //                         kDefaultPadding / 4,
                    //                       ),
                    //                     ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                    /////////////////////Laundry Section/////////////////////////////
                    !isLaundryActive
                        ? SliverToBoxAdapter(child: SizedBox.shrink())
                        : SliverToBoxAdapter(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                  kDefaultPadding,
                                ),
                              ),
                              margin: EdgeInsets.only(
                                bottom: getProportionateScreenWidth(
                                  kDefaultPadding / 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: getProportionateScreenHeight(
                                  kDefaultPadding / 2,
                                ),
                                children: [
                                  SectionTitle(
                                    sectionTitle: "Laundry Pick & Drop",
                                    subTitle: " ",
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
                                            cityId: responseData['city']['_id'],
                                            storeDeliveryId:
                                                categories[laundryIndex]['_id'],
                                            category: categories[laundryIndex],
                                            latitude: Provider.of<ZMetaData>(
                                              context,
                                              listen: false,
                                            ).latitude,
                                            longitude: Provider.of<ZMetaData>(
                                              context,
                                              listen: false,
                                            ).longitude,
                                            isStore: false,
                                            companyId: -1,
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
                                  ),
                                ],
                              ),
                            ),
                          ),

                    /////////////////////Other category services/////////////////////////////
                    // Dynamic Services Section
                    services == null || services.isEmpty
                        ? SliverToBoxAdapter(child: SizedBox.shrink())
                        : SliverToBoxAdapter(
                            child: Container(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: services.length,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                  // vertical: getProportionateScreenWidth(
                                  //     kDefaultPadding / 2),
                                ),
                                separatorBuilder: (context, index) => Container(
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding / 1.5,
                                  ),
                                  // decoration: BoxDecoration(color: kWhiteColor),
                                ),
                                itemBuilder: (context, index) {
                                  final service = services[index];
                                  var serviceName = service['delivery_name']
                                      ?.toString()
                                      .toLowerCase();

                                  // Check tags to identify special services
                                  final tags =
                                      service['famous_products_tags'] as List?;
                                  bool isMagazine =
                                      tags?.any(
                                        (tag) =>
                                            tag.toString().toLowerCase() ==
                                                'magazine' ||
                                            tag
                                                .toString()
                                                .toLowerCase()
                                                .contains("magazine"),
                                      ) ??
                                      false;
                                  serviceName = isMagazine
                                      ? "magazine"
                                      : serviceName;

                                  // Check tags to identify special services
                                  bool isProximityOrder =
                                      tags?.any(
                                        (tag) =>
                                            tag.toString().toLowerCase() ==
                                                'proximity' ||
                                            tag.toString().toLowerCase() ==
                                                'nearby' ||
                                            tag.toString().toLowerCase() ==
                                                'nearby orders' ||
                                            tag.toString().toLowerCase() ==
                                                'orders near you',
                                      ) ??
                                      false;

                                  bool isRecapService =
                                      tags?.any(
                                        (tag) =>
                                            tag.toString().toLowerCase() ==
                                                'recap' ||
                                            tag.toString().toLowerCase() ==
                                                'wrapped' ||
                                            tag.toString().toLowerCase() ==
                                                'yearly_recap',
                                      ) ??
                                      false;

                                  bool isHolidaySplashService =
                                      tags?.any(
                                        (tag) =>
                                            tag.toString().toLowerCase() ==
                                                'holiday_splash' ||
                                            tag.toString().toLowerCase() ==
                                                'holiday' ||
                                            tag.toString().toLowerCase() ==
                                                'splash' ||
                                            tag.toString().toLowerCase() ==
                                                'promotion',
                                      ) ??
                                      false;
                                  bool isCconfetti =
                                      tags?.any(
                                        (tag) =>
                                            tag.toString().toLowerCase() ==
                                                'celebration' ||
                                            tag.toString().toLowerCase() ==
                                                'new year' ||
                                            tag.toString().toLowerCase() ==
                                                'confetti' ||
                                            tag.toString().toLowerCase() ==
                                                'new year celebration',
                                      ) ??
                                      false;
                                  // Skip services that are handled elsewhere (e.g., Laundry in categories)
                                  if (serviceName == 'laundry' ||
                                      isProximityOrder ||
                                      isRecapService ||
                                      isCconfetti ||
                                      isHolidaySplashService) {
                                    return SizedBox.shrink();
                                  }
                                  // serviceName = serviceName.contains('magazin')
                                  //     ? "Magazin"
                                  //     : serviceName;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: getProportionateScreenHeight(
                                      kDefaultPadding / 2,
                                    ),
                                    children: [
                                      SectionTitle(
                                        sectionTitle: serviceName == 'courier'
                                            ? Provider.of<ZLanguage>(
                                                context,
                                              ).thinkingOf
                                            : serviceName == 'event'
                                            ? Provider.of<ZLanguage>(
                                                context,
                                              ).discover
                                            : serviceName == 'lunch from home'
                                            ? Provider.of<ZLanguage>(
                                                context,
                                              ).missingHome
                                            : serviceName == 'prediction'
                                            ? Provider.of<ZLanguage>(
                                                context,
                                              ).predictAndwin
                                            : service['delivery_name'],
                                        subTitle: " ",
                                      ),
                                      CustomBanner(
                                        isNetworkImage:
                                            service['image_url']?.isNotEmpty ??
                                            false,
                                        imageUrl:
                                            service['image_url']?.isNotEmpty ??
                                                false
                                            ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${service['image_url']}"
                                            : "images/$serviceName.png", // Ensure you have a default image in assets
                                        title: service['delivery_name'],
                                        subtitle: "",
                                        press: () {
                                          String? url = service['description']
                                              .split('webUrl-')
                                              .last;
                                          // debugPrint(url);

                                          Widget? screen;

                                          switch (serviceName) {
                                            case 'lottery':
                                              screen = WebViewScreen(
                                                url: url!,
                                                title: service['delivery_name'],
                                              );
                                              // 'https://www.ethiolottery.et/am?affiliate=68308ad291bef6c92f841c8b');
                                              break;
                                            case 'magazine':
                                              // Navigate to magazine list screen
                                              if (userData != null) {
                                                screen = MagazineListScreen(
                                                  userData: userData,
                                                  userId:
                                                      userData['user']['_id'],
                                                  serverToken:
                                                      userData['user']['server_token'],
                                                  title:
                                                      service['delivery_name'],
                                                );
                                              }
                                              break;
                                            case 'aliexpress':
                                              screen = AliProductListScreen();
                                              break;
                                            case 'prediction':
                                              screen = WorldCupScreen();
                                              break;
                                            case 'lunch from home':
                                              screen = LunchHomeScreen(
                                                curLat: Provider.of<ZMetaData>(
                                                  context,
                                                  listen: false,
                                                ).latitude,
                                                curLon: Provider.of<ZMetaData>(
                                                  context,
                                                  listen: false,
                                                ).longitude,
                                              );
                                              break;
                                            case 'courier':
                                              screen = CourierScreen(
                                                curLat: Provider.of<ZMetaData>(
                                                  context,
                                                  listen: false,
                                                ).latitude,
                                                curLon: Provider.of<ZMetaData>(
                                                  context,
                                                  listen: false,
                                                ).longitude,
                                              );
                                              break;
                                            case 'event':
                                              screen = EventsScreen();
                                              break;
                                          }
                                          if (screen != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => screen!,
                                              ),
                                            ).then((value) {
                                              if (userData != null) {
                                                _getPromotionalItems();
                                                getUserOrderCount();
                                                _doLocationTask();
                                                getNearByMerchants();
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                    //////////////nearbyStores section/////////////////
                    ///  if (nearbyStores != null && nearbyStores.isNotEmpty)
                    if (nearbyStores != null && nearbyStores.length > 0)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: SliverAppBarDelegate(
                          minHeight: 60,
                          maxHeight: 60,
                          child: Container(
                            color: kPrimaryColor,
                            child: _nearbyHeader(),
                          ),
                        ),
                      ),
                    if (nearbyStores != null && nearbyStores.length > 0)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(childCount: 1, (
                          BuildContext context,
                          int index,
                        ) {
                          return ListView.separated(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            physics: NeverScrollableScrollPhysics(),
                            separatorBuilder:
                                (BuildContext context, int index) => Container(
                                  // color: kBlackColor,
                                  height: getProportionateScreenHeight(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                            padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(
                                kDefaultPadding,
                              ),
                              vertical: getProportionateScreenWidth(
                                kDefaultPadding / 2,
                              ),
                            ),
                            itemCount:
                                nearbyStores != null && nearbyStores.length > 0
                                ? nearbyStores.length
                                : 0,
                            itemBuilder: (context, index) => Container(
                              child: CustomListTile(
                                press: () async {
                                  // debugPrint(  "Promotional item pressed...");
                                  bool isOp = await Service.isStoreOpen(
                                    nearbyStores[index],
                                  );

                                  if (isOp) {
                                    // debugPrint("Open");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return ProductScreen(
                                            store: nearbyStores[index],
                                            isOpen: isOp,
                                            location:
                                                nearbyStores[index]['location'],
                                            longitude: Provider.of<ZMetaData>(
                                              context,
                                              listen: false,
                                            ).longitude,
                                            latitude: Provider.of<ZMetaData>(
                                              context,
                                              listen: false,
                                            ).latitude,
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
                                      Service.showMessage(
                                        context: context,
                                        title:
                                            "Store is currently closed. We highly recommend you to try other store. We've got them all...",
                                        error: true,
                                        duration: 3,
                                      );
                                    }
                                  }
                                },
                                store: nearbyStores[index],
                                isOpen:
                                    nearbyStores.length ==
                                        isNearbyStoreOpen.length
                                    ? isNearbyStoreOpen[index]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                )
              : !_loading
              ? Padding(
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

  Widget _nearbyHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
      ),
      child: SectionTitle(
        sectionTitle: Provider.of<ZLanguage>(
          context,
        ).nearbyStores, //Nearby stores
        subTitle: "See More",
        onSubTitlePress: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return NearbyStoresScreen(
                  longitude: Provider.of<ZMetaData>(
                    context,
                    listen: false,
                  ).longitude,
                  latitude: Provider.of<ZMetaData>(
                    context,
                    listen: false,
                  ).latitude,
                  storesList: nearbyStores,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget recapHolidayWidget({String? imageUrl, required bool isRecap}) {
    return Container(
      width: double.infinity,
      height: imageUrl != null ? 88 : null,
      margin: EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        image: imageUrl != null
            //  && !isRecap
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${services[holidaySplashIndex]['image_url']}",
                ),
                fit: BoxFit.contain,
              )
            : null,
        gradient: imageUrl == null
            // || isRecap
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFED2437), const Color(0xFFc91f2f)],
              )
            : null,
        border: Border.all(color: kWhiteColor),
        borderRadius: BorderRadius.circular(kDefaultPadding * 1.1),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: imageUrl != null
          // && !isRecap
          ? ClipRRect(
              borderRadius: BorderRadius.circular(kDefaultPadding * 2),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(), // Just show the image
              ),
            )
          : Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(kDefaultPadding * 1.3),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: EdgeInsets.all(kDefaultPadding / 2),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            kDefaultPadding / 1.3,
                          ),
                          border: Border.all(
                            color: kPrimaryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: kPrimaryColor,
                          size: 30,
                        ),
                      ),

                      SizedBox(width: kDefaultPadding),

                      // Text content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Only show title for recap
                            if (isRecap)
                              Text(
                                "Your ${services[holidaySplashIndex]['delivery_name']}",
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            if (isRecap) SizedBox(height: kDefaultPadding / 5),
                            Text(
                              isRecap
                                  ? "See your year in review ✨"
                                  : (services[holidaySplashIndex]['description']
                                            ?.toString()
                                            .split('webUrl-')
                                            .first ??
                                        "Tap to view"),
                              style: TextStyle(
                                color: kPrimaryColor.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Arrow icon
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: kPrimaryColor,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<dynamic> getCategoryList(
    double longitude,
    double latitude,
    String countryCode,
    String countryName,
  ) async {
    setState(() {
      _loading = true;
    });

    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_delivery_list_for_nearest_city";
    Map data = {
      "latitude": Provider.of<ZMetaData>(context, listen: false).latitude,
      "longitude": Provider.of<ZMetaData>(context, listen: false).longitude,
      "country": Provider.of<ZMetaData>(context, listen: false).country,
      "country_code": Provider.of<ZMetaData>(context, listen: false).countryId,
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

      await Service.save('categories', json.decode(response.body));

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);

      Service.showMessage(
        context: context,
        title: "Something went wrong! Please check your internet connection!",
        error: true,
      );

      return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<dynamic> getServicesList(
    double longitude,
    double latitude,
    String countryCode,
    String countryName,
  ) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_delivery_list_for_nearest_city";
    Map data = {
      "country": countryName,
      "country_code": countryCode,
      "longitude": longitude,
      "latitude": latitude,
      "delivery_type": 2,
    };
    // debugPrint("body $data");
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

      await Service.save('services', json.decode(response.body));

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);

      Service.showMessage(
        context: context,
        title: "Something went wrong! Please check your internet connection!",
        error: true,
      );

      return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<dynamic> getItemInformation(itemId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_item_information";
    Map data = {"item_id": itemId};
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
              Service.showMessage(
                context: context,
                title: "Something went wrong!",
                error: true,
                duration: 3,
              );
              throw TimeoutException("The connection has timed out!");
            },
          );
      setState(() {
        this.notificationItem = json.decode(response.body);
      });

      return json.decode(response.body);
    } catch (e) {
      return null;
    } finally {
      setState(() {
        _loading = false;
      });
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
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Something went wrong!",
                error: true,
                duration: 3,
              );
              throw TimeoutException("The connection has timed out!");
            },
          );
      setState(() {
        this.notificationItem = json.decode(response.body);
      });

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);

      return null;
    } finally {
      setState(() {
        _loading = false;
      });
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
    Map data = {"user_id": userId, "server_token": server_token};

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

      Service.showMessage(
        context: context,
        title: "Your internet connection is bad!",
        error: true,
      );

      return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  //////////////////////////////////////////////////////////////////////
}

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key, required this.promotionalItems});

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
                        imageUrl:
                            widget.promotionalItems != null &&
                                widget
                                        .promotionalItems['promotional_items'][index]['image_url']
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
                              kDefaultPadding * 3.5,
                            ),
                            height: getProportionateScreenHeight(
                              kDefaultPadding * 3.5,
                            ),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kWhiteColor,
                              ),
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
                  itemCount:
                      widget.promotionalItems != null &&
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
                              widget
                                      .promotionalItems['promotional_items']
                                      .length >
                                  0
                          ? widget.promotionalItems['promotional_items'].length
                          : 0,
                      (index) => Padding(
                        padding: EdgeInsets.only(left: kDefaultPadding / 10),
                        child: IndicatorDot(isActive: index == _currentPage),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IndicatorDot extends StatelessWidget {
  const IndicatorDot({Key? key, required this.isActive}) : super(key: key);

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


  // Future<bool> storeOpen(var store) async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   _getAppKeys();
  //   setState(() {
  //     _loading = false;
  //   });
  //   bool isStoreOpen = false;
  //   // store_time
  //   // store_open_close_timen
  //   if (store['store_time'] != null && store['store_time'].length != 0) {
  //     var appClose = await Service.read('app_close');
  //     var appOpen = await Service.read('app_open');
  //     for (var i = 0; i < store['store_time'].length; i++) {
  //       DateFormat dateFormat = new DateFormat.Hm();
  //       DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
  //       int weekday;
  //       if (now.weekday == 7) {
  //         weekday = 0;
  //       } else {
  //         weekday = now.weekday;
  //       }

  //       if (store['store_time'][i]['day'] == weekday) {
  //         if (store['store_time'][i]['day_time'].length != 0 &&
  //             store['store_time'][i]['is_store_open']) {
  //           for (
  //             var j = 0;
  //             j < store['store_time'][i]['day_time'].length;
  //             j++
  //           ) {
  //             DateTime open = dateFormat.parse(
  //               store['store_time'][i]['day_time'][j]['store_open_time'],
  //             );
  //             open = new DateTime(
  //               now.year,
  //               now.month,
  //               now.day,
  //               open.hour,
  //               open.minute,
  //             );
  //             DateTime close = dateFormat.parse(
  //               store['store_time'][i]['day_time'][j]['store_close_time'],
  //             );
  //             // DateTime zmallClose =
  //             //     DateTime(now.year, now.month, now.day, 21, 00);
  //             // DateTime zmallOpen =
  //             //     DateTime(now.year, now.month, now.day, 09, 00);
  //             // if (appOpen != null && appOpen != null) {
  //             DateTime zmallClose = dateFormat.parse(appClose);
  //             DateTime zmallOpen = dateFormat.parse(appOpen);
  //             // }

  //             close = new DateTime(
  //               now.year,
  //               now.month,
  //               now.day,
  //               close.hour,
  //               close.minute,
  //             );
  //             now = DateTime(
  //               now.year,
  //               now.month,
  //               now.day,
  //               now.hour,
  //               now.minute,
  //             );

  //             zmallOpen = new DateTime(
  //               now.year,
  //               now.month,
  //               now.day,
  //               zmallOpen.hour,
  //               zmallOpen.minute,
  //             );
  //             zmallClose = new DateTime(
  //               now.year,
  //               now.month,
  //               now.day,
  //               zmallClose.hour,
  //               zmallClose.minute,
  //             );

  //             // debugPrint(zmallOpen);
  //             // debugPrint(open);
  //             // debugPrint(now);
  //             // debugPrint(close);
  //             // debugPrint(zmallClose);
  //             if (now.isAfter(open) &&
  //                 now.isAfter(zmallOpen) &&
  //                 now.isBefore(close) &&
  //                 store['store_time'][i]['is_store_open'] &&
  //                 now.isBefore(zmallClose)) {
  //               isStoreOpen = true;
  //               break;
  //             } else {
  //               isStoreOpen = false;
  //             }
  //           }
  //         } else {
  //           isStoreOpen = store['store_time'][i]['is_store_open'];
  //         }
  //       }
  //     }
  //   } else {
  //     var appClose = await Service.read('app_close');
  //     var appOpen = await Service.read('app_open');
  //     DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
  //     DateFormat dateFormat = new DateFormat.Hm();
  //     // DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
  //     // DateTime zmallOpen = DateTime(now.year, now.month, now.day, 09, 00);
  //     // if (appOpen != null && appOpen != null) {
  //     DateTime zmallClose = dateFormat.parse(appClose);
  //     DateTime zmallOpen = dateFormat.parse(appOpen);
  //     // }
  //     zmallClose = DateTime(
  //       now.year,
  //       now.month,
  //       now.day,
  //       zmallClose.hour,
  //       zmallClose.minute,
  //     );
  //     zmallOpen = DateTime(
  //       now.year,
  //       now.month,
  //       now.day,
  //       zmallOpen.hour,
  //       zmallOpen.minute,
  //     );
  //     now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

  //     if (now.isAfter(zmallOpen) && now.isBefore(zmallClose)) {
  //       isStoreOpen = true;
  //     } else {
  //       isStoreOpen = false;
  //     }
  //   }
  //   return isStoreOpen;
  // }