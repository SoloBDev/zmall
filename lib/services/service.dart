import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/services/core_services.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/utils/constants.dart';

class Service {
  // Secure storage instance for sensitive data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys for biometric authentication
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedPhoneKey = 'saved_phone';
  static const String _savedPasswordKey = 'saved_password';

  static Future<void> launchInWebViewOrVC(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        // forceSafariVC: true,
        // forceWebView: true,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static void showMessage({
    required BuildContext context,
    String? title,
    bool? error,
    int duration = 2,
  }) {
    // Check if the context is still mounted and valid before showing SnackBar
    if (!context.mounted) {
      return; // Don't show message if context is not mounted
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error == null
              ? kGreyColor
              : error
              ? kSecondaryColor
              : kGreenColor,
          content: Text(
            title!,
            style: TextStyle(fontSize: 15, color: kPrimaryColor),
          ),
          duration: Duration(seconds: duration),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultPadding),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding),
            vertical: getProportionateScreenHeight(kDefaultPadding),
          ),
        ),
      );
    } catch (e) {
      // Silently fail if the widget is deactivated
      // This prevents the app from crashing
    }
  }

  static Future<bool> isConnected(context) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      showMessage(
        context: context,
        title: "Check your internet connection",
        error: true,
      );
      return false;
    }
    showMessage(
      context: context,
      title: "Check your internet connection",
      error: true,
    );
    return false;
  }

  static Future<Future> isLogged() async {
    return readBool('logged');
  }

  static Future<dynamic> getUser() async {
    return read('user');
  }

  static Future<dynamic> read(String? key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stringValue = prefs.getString(key!);

    return stringValue != null ? json.decode(stringValue) : null;
  }

  static Future<dynamic> readBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? null;
  }

  static Future<dynamic> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  static Future<dynamic> save(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(value));
  }

  static Future<dynamic> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  // ignore: missing_return

  static Future<http.Response?> deleteUserAccount(
    String userId,
    bool deleteUser,
    int userType,
    BuildContext context,
  ) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/approve_decline_user";
    Map data = {
      "user_id": userId,
      "is_approved": deleteUser,
      "user_page_type": userType,
    };
    var body = json.encode(data);
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException("The connection has timed out!");
            },
          );
      return response;
    } catch (e) {
      return null;
    }
  }
  /////////////////////newly added

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double distance =
        acos(
          sin(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) +
              cos(_degreesToRadians(lat1)) *
                  cos(_degreesToRadians(lat2)) *
                  cos(dLon),
        ) *
        earthRadius;

    // Return the distance in kilometers
    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /////////////////////////////////////////////////////////
  static String capitalizeFirstLetters(String input) {
    input = input.toLowerCase();
    if (input.contains('[') && input.contains(']')) {
      input = input.replaceAll('[', '').replaceAll(']', '');
    }
    // // Split by commas, preserving spaces within each part
    List<String> parts = input.split(',');

    // Capitalize each part and preserve commas and spaces
    String result = parts
        .map((part) {
          List<String> words = part.trim().split(RegExp(r'\s+'));
          return words
              .map(
                (word) => word.trim().isEmpty
                    ? word.trim()
                    : word.trim().substring(0, 1).toUpperCase() +
                          word.trim().substring(1),
              )
              .join(' ');
        })
        .join(', ');

    // Remove any duplicated values
    result = result.trim().replaceAll(RegExp(r'\s*,+\s*'), ', ');
    List<String> capitalizedWords = result.split(',');
    Set<String> uniqueWords = {};
    capitalizedWords.forEach((word) => uniqueWords.add(word.trim()));
    return uniqueWords.join(', ');
  }
  /////////////////////////////////////////////////////////

  // ============= Biometric Authentication Methods =============

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    return await readBool(_biometricEnabledKey) ?? false;
  }

  /// Enable biometric authentication
  static Future<void> enableBiometric() async {
    await saveBool(_biometricEnabledKey, true);
  }

  /// Disable biometric authentication
  static Future<void> disableBiometric() async {
    await saveBool(_biometricEnabledKey, false);
    // Clear saved credentials
    await clearBiometricCredentials();
  }

  /// Save user credentials for biometric login
  static Future<void> saveBiometricCredentials({
    required String phone,
    required String password,
  }) async {
    await _secureStorage.write(key: _savedPhoneKey, value: phone);
    await _secureStorage.write(key: _savedPasswordKey, value: password);
  }

  /// Get saved phone number
  static Future<String?> getSavedPhone() async {
    return await _secureStorage.read(key: _savedPhoneKey);
  }

  /// Get saved password
  static Future<String?> getSavedPassword() async {
    return await _secureStorage.read(key: _savedPasswordKey);
  }

  /// Clear all biometric stored credentials
  static Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _savedPhoneKey);
    await _secureStorage.delete(key: _savedPasswordKey);
  }

  /// Check if credentials are saved
  static Future<bool> hasBiometricCredentials() async {
    final phone = await getSavedPhone();
    final password = await getSavedPassword();
    return phone != null && password != null;
  }

  /// Biometric login - Direct login without OTP
  static Future<Map<String, dynamic>?> biometricLogin({
    required String phoneNumber,
    required String password,
    required BuildContext context,
    required String appVersion,
  }) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/login";
    String deviceType = Platform.isIOS ? 'iOS' : "android";

    try {
      Map data = {
        "email": phoneNumber,
        "password": password,
        "app_version": appVersion,
        "device_type": deviceType,
      };
      var body = json.encode(data);
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
              throw TimeoutException("The connection has timed out!");
            },
          );

      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }

  // ============= Cart Helper Methods =============

  /// Check if two cart items are identical
  ///
  /// Items are considered the same if they have:
  /// - Same item ID
  /// - Same specifications (same spec unique_ids and selected options)
  ///
  /// This is useful for preventing duplicate items in the cart and
  /// instead updating the quantity of existing items.
  ///
  /// Example usage:
  /// ```dart
  /// if (Service.isSameItem(existingItem, newItem)) {
  ///   // Update quantity instead of adding duplicate
  ///   existingItem.quantity += newItem.quantity;
  /// } else {
  ///   // Add as new item
  ///   cart.items.add(newItem);
  /// }
  /// ```
  static bool isSameItem(Item existingItem, Item newItem) {
    // Check if item IDs match
    if (existingItem.id != newItem.id) {
      return false;
    }

    // Check if specifications match
    if (existingItem.specification == null && newItem.specification == null) {
      return true;
    }

    if (existingItem.specification == null || newItem.specification == null) {
      return false;
    }

    if (existingItem.specification!.length != newItem.specification!.length) {
      return false;
    }

    // Compare each specification
    for (var newSpec in newItem.specification!) {
      bool found = false;
      for (var existingSpec in existingItem.specification!) {
        if (existingSpec.uniqueId == newSpec.uniqueId) {
          // Check if the selected options within this spec are the same
          if (existingSpec.list!.length != newSpec.list!.length) {
            return false;
          }

          // Compare each option in the specification
          for (var newOption in newSpec.list!) {
            bool optionFound = false;
            for (var existingOption in existingSpec.list!) {
              if (existingOption.uniqueId == newOption.uniqueId) {
                optionFound = true;
                break;
              }
            }
            if (!optionFound) {
              return false;
            }
          }
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }

    return true;
  }

  /// Add or merge an item into the cart
  ///
  /// If an identical item already exists in the cart (same ID and specifications),
  /// this method will merge them by updating the quantity and recalculating the price.
  /// Otherwise, it will add the item as a new entry.
  ///
  /// Parameters:
  /// - [cart]: The current cart object
  /// - [newItem]: The item to add or merge
  ///
  /// Returns: `true` if the item was merged with an existing item, `false` if added as new
  ///
  /// Example usage:
  /// ```dart
  /// Cart cart = await Service.read('cart');
  /// Item newItem = Item(id: '123', quantity: 1, price: 275.0);
  ///
  /// bool wasMerged = Service.addOrMergeCartItem(cart, newItem);
  /// await Service.save('cart', cart.toJson());
  ///
  /// if (wasMerged) {
  ///   print('Item quantity updated');
  /// } else {
  ///   print('New item added to cart');
  /// }
  /// ```
  static bool addOrMergeCartItem(Cart cart, Item newItem) {
    // Check if the same item with same specifications exists
    int existingItemIndex = -1;
    for (int i = 0; i < (cart.items?.length ?? 0); i++) {
      if (isSameItem(cart.items![i], newItem)) {
        existingItemIndex = i;
        break;
      }
    }

    if (existingItemIndex != -1) {
      // Item found - merge by updating quantity and price
      int oldQuantity = cart.items![existingItemIndex].quantity ?? 0;
      int newQuantity = oldQuantity + (newItem.quantity ?? 0);

      // Calculate unit price from the existing item
      // If old quantity is 0, calculate from new item to avoid division by zero
      double unitPrice = oldQuantity > 0
          ? (cart.items![existingItemIndex].price ?? 0) / oldQuantity
          : (newItem.price ?? 0) / (newItem.quantity ?? 1);

      // Update quantity and recalculate total price
      cart.items![existingItemIndex].quantity = newQuantity;
      cart.items![existingItemIndex].price = unitPrice * newQuantity;

      return true; // Item was merged
    } else {
      // Item not found - add as new
      cart.items ??= [];
      cart.items!.add(newItem);

      return false; // Item was added as new
    }
  }

  ///Get product Price
  static getPrice(item) {
    var price = item['price'] ?? item['item_price'] ?? item['new_price'] ?? 0;
    if (price == 0) {
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
      var price = item['price'] ?? item['item_price'] ?? item['new_price'] ?? 0;
      return price.toStringAsFixed(2);
    }

    return "0.00";
  }
  // static String getPrice(item) {
  //   if (item['price'] == null || item['price'] == 0) {
  //     // look for a default-selected spec
  //     for (var i = 0; i < item['specifications'].length; i++) {
  //       for (var j = 0; j < item['specifications'][i]['list'].length; j++) {
  //         final spec = item['specifications'][i]['list'][j];
  //         if (spec['is_default_selected'] == true) {
  //           return spec['price'].toStringAsFixed(2);
  //         }
  //       }
  //     }

  //     // fallback to first available price if none are default-selected
  //     if (item['specifications'].isNotEmpty &&
  //         item['specifications'][0]['list'].isNotEmpty) {
  //       final firstSpecPrice = item['specifications'][0]['list'][0]['price'];
  //       return firstSpecPrice.toStringAsFixed(2);
  //     }
  //   } else {
  //     return item['price'].toStringAsFixed(2);
  //   }

  //   return "0.00";
  // }
  //Previous implementation: returns 0.00 if the specification has a default selected/ not required
  // String _getPrice(item) {
  //   print(item['specifications']);

  //   if (item['price'] == null || item['price'] == 0) {
  //     for (var i = 0; i < item['specifications'].length; i++) {
  //       for (var j = 0; j < item['specifications'][i]['list'].length; j++) {
  //         if (item['specifications'][i]['list'][j]['is_default_selected']) {
  //           return item['specifications'][i]['list'][j]['price']
  //               .toStringAsFixed(2);
  //         }
  //       }
  //     }
  //   } else {
  //     return item['price'].toStringAsFixed(2);
  //   }
  //   return "0.00";
  // }

  // ============= Store Helper Methods =============

  /// Check if a single store is currently open (Pattern 1)
  ///
  /// This method checks if a single store is open based on:
  /// - App-wide open/close times (appOpen and appClose)
  /// - Store-specific schedules with weekday support
  /// - UTC+3 timezone (for Ethiopia and South Sudan)
  ///
  /// Parameters:
  /// - [store]: Store object containing store_time schedule
  ///
  /// Returns: true if the store is currently open, false otherwise
  ///
  /// Example usage:
  /// ```dart
  /// bool isOpen = await Service.isStoreOpen(store);
  /// if (isOpen) {
  ///   print('Store is open');
  /// }
  /// ```
  static Future<bool> isStoreOpen(var store) async {
    List<bool> result = await storeOpen([store]);
    return result.isNotEmpty ? result[0] : false;
  }

  /// Determine which stores are currently open based on their schedules (Pattern 2)
  ///
  /// This method checks if stores are open based on:
  /// - App-wide open/close times (appOpen and appClose)
  /// - Store-specific schedules with weekday support
  /// - UTC+3 timezone (for Ethiopia and South Sudan)
  ///
  /// Parameters:
  /// - [stores]: List of store objects containing store_time schedules
  ///
  /// Returns: List<bool> where each boolean indicates if the corresponding store is open
  ///
  /// Example usage:
  /// ```dart
  /// List<bool> isOpen = await Service.storeOpen(stores);
  /// if (isOpen[0]) {
  ///   print('First store is open');
  /// }
  /// ```
  static Future<List<bool>> storeOpen(List stores) async {
    List<bool> isOpen = [];
    DateFormat dateFormat = DateFormat.Hm();
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));

    // Read app open/close times from storage if not provided

    var appOpen = await read('app_open');
    var appClose = await read('app_close');

    DateTime zmallOpen = dateFormat.parse(appOpen!);
    DateTime zmallClose = dateFormat.parse(appClose!);

    zmallOpen = DateTime(
      now.year,
      now.month,
      now.day,
      zmallOpen.hour,
      zmallOpen.minute,
    );
    zmallClose = DateTime(
      now.year,
      now.month,
      now.day,
      zmallClose.hour,
      zmallClose.minute,
    );

    stores.forEach((store) {
      bool isStoreOpen = false;
      if (store['store_time'] != null && store['store_time'].length != 0) {
        for (var i = 0; i < store['store_time'].length; i++) {
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
                open = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  open.hour,
                  open.minute,
                );
                DateTime close = dateFormat.parse(
                  store['store_time'][i]['day_time'][j]['store_close_time'],
                );
                close = DateTime(
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
              if (now.isAfter(zmallOpen) &&
                  now.isBefore(zmallClose) &&
                  store['store_time'][i]['is_store_open']) {
                isStoreOpen = true;
              } else {
                isStoreOpen = false;
              }
            }
          }
        }
      } else {
        DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
        DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
        DateFormat dateFormat = DateFormat.Hm();
        if (appClose != null) {
          zmallClose = dateFormat.parse(appClose);
        }

        zmallClose = DateTime(
          now.year,
          now.month,
          now.day,
          zmallClose.hour,
          zmallClose.minute,
        );
        now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

        now.isAfter(zmallClose) ? isStoreOpen = false : isStoreOpen = true;
      }
      isOpen.add(isStoreOpen);
    });

    return isOpen;
  }
  // ============= Proximity Order Methods =============

  /// Fetch proximity order items using get_recent_orders endpoint
  /// Returns list of individual items from orders within specified radius from user location
  static Future<List<Map<String, dynamic>>> getProximityOrders({
    required BuildContext context,
    required double userLatitude,
    required double userLongitude,
    double radius = 5.0,
    required String serverToken,
    required String userId,
  }) async {
    try {
      // Get user data from storage
      // var userData = await Service.getUser();
      // if (userData == null) {
      //   return [];
      // }

      // String userId = userData['user']['_id'];
      // String serverToken = userData['user']['server_token'];

      var response = await CoreServices.getProximityOrders(
        userId: userId,
        serverToken: serverToken,
        context: context,
      );
      if (response != null && response['success'] == true) {
        List ordersList = response['orders'] ?? [];
        List<Map<String, dynamic>> proximityItems = [];
        var radiusKm = response['radiusKm'] ?? radius;
        // debugPrint("respose: $response");
        for (var order in ordersList) {
          // Get destination location
          var cartDetail = order['cart_detail'];
          if (cartDetail == null) {
            continue;
          }

          var destAddresses = cartDetail['destination_addresses'] as List?;
          if (destAddresses == null || destAddresses.isEmpty) {
            continue;
          }

          var destLocation = destAddresses[0]['location'] as List?;
          if (destLocation == null || destLocation.length < 2) {
            continue;
          }

          double destLat = destLocation[0].toDouble();
          double destLong = destLocation[1].toDouble();

          // Calculate distance from user to delivery destination
          double distance = calculateDistance(
            userLatitude,
            userLongitude,
            destLat,
            destLong,
          );

          // Filter by radius
          if (distance <= radiusKm) {
            // Check if urgent (created less than 10 minutes ago)
            // DateTime createdAt = DateTime.parse(order['created_at']);
            // Duration timeSinceCreation = DateTime.now().difference(createdAt);
            // bool isUrgent = timeSinceCreation.inMinutes < 10;

            // Extract items from order
            var orderDetails = cartDetail['order_details'] as List? ?? [];
            var storeDetail = order['store_detail'] ?? {};
            var storeLocation = storeDetail['location'] as List? ?? [];

            for (var orderDetail in orderDetails) {
              var items = orderDetail['items'] as List? ?? [];

              for (var item in items) {
                // Create enriched item object with store and order info
                Map<String, dynamic> enrichedItem = {
                  // Item details
                  'item_id': item['item_id'],
                  'item_name': item['item_name'],
                  'item_price': item['item_price'],
                  'image_url': item['image_url'],
                  'quantity': item['quantity'],
                  'unique_id': item['unique_id'],
                  'details': item['details'],
                  'max_item_quantity': item['max_item_quantity'],
                  'specifications': item['specifications'],
                  'note_for_item': item['note_for_item'],

                  // Store details
                  'store_detail': storeDetail,
                  'store_id': storeDetail['_id'],
                  'store_name': storeDetail['name'],
                  'store_location': storeLocation,

                  // Order details
                  'order_id': order['_id'],
                  'order_unique_id': order['unique_id'],
                  'distance_from_user': distance,
                  // 'is_urgent': isUrgent,
                };

                // if (isUrgent) {
                proximityItems.add(enrichedItem);
                // }
              }
            }
          }
        }

        // Sort by distance (closest first)
        proximityItems.sort((a, b) {
          double distA = a['distance_from_user'] ?? double.infinity;
          double distB = b['distance_from_user'] ?? double.infinity;
          return distA.compareTo(distB);
        });
        // debugPrint("proximityItems: $proximityItems");
        return proximityItems;
      }

      return [];
    } catch (e) {
      // print("Error fetching proximity orders: $e");
      return [];
    }
  }

  ///////////////////////////Proximity Order Methods old Closed ==////////////////////
  // ============= Proximity Order Methods =============

  /// Fetch proximity order items using existing orders_list endpoint
  /// Returns list of individual items from orders within specified radius from user location
  // static Future<List<Map<String, dynamic>>> getProximityOrders({
  //   required BuildContext context,
  //   required double userLatitude,
  //   required double userLongitude,
  //   double radiusKm = 5.0,
  // }) async {
  //   try {
  //     // Fetch all active delivery orders
  //     var response = await CoreServices.getOrdersList(
  //       context: context,
  //       orderStatus: "all", // All statuses
  //       paymentStatus: "all",
  //       page: 1,
  //       pickupType: "both",
  //       createdBy: "both",
  //       orderType: "both",
  //       searchField: "user_detail.first_name",
  //       searchValue: "",
  //     );

  //     if (response != null && response['success'] == true) {
  //       List ordersList = response['orders'] ?? [];
  //       List<Map<String, dynamic>> proximityItems = [];

  //       for (var order in ordersList) {
  //         // Get destination location
  //         var cartDetail = order['cart_detail'];
  //         if (cartDetail == null) {
  //           continue;
  //         }

  //         var destAddresses = cartDetail['destination_addresses'] as List?;
  //         if (destAddresses == null || destAddresses.isEmpty) {
  //           continue;
  //         }

  //         var destLocation = destAddresses[0]['location'] as List?;
  //         if (destLocation == null || destLocation.length < 2) {
  //           continue;
  //         }

  //         double destLat = destLocation[0].toDouble();
  //         double destLong = destLocation[1].toDouble();

  //         // Calculate distance from user to delivery destination
  //         double distance = calculateDistance(
  //           userLatitude,
  //           userLongitude,
  //           destLat,
  //           destLong,
  //         );

  //         // Filter by radius
  //         if (distance <= radiusKm) {
  //           // Check if urgent (created more than 30 minutes ago)
  //           DateTime createdAt = DateTime.parse(order['created_at']);
  //           Duration timeSinceCreation = DateTime.now().difference(createdAt);
  //           // bool isUrgent = timeSinceCreation.inMinutes > 30;
  //           bool isUrgent = timeSinceCreation.inMinutes < 10;
  //           // 20000; //2*24*60 = 2880 minutes
  //           // Extract items from order
  //           var orderDetails = cartDetail['order_details'] as List? ?? [];
  //           var storeDetail = order['store_detail'] ?? {};
  //           var storeLocation = storeDetail['location'] as List? ?? [];

  //           for (var orderDetail in orderDetails) {
  //             var items = orderDetail['items'] as List? ?? [];

  //             for (var item in items) {
  //               // Create enriched item object with store and order info
  //               Map<String, dynamic> enrichedItem = {
  //                 // Item details
  //                 'item_id': item['item_id'],
  //                 'item_name': item['item_name'],
  //                 'item_price': item['item_price'],
  //                 'image_url': item['image_url'],
  //                 'quantity': item['quantity'],
  //                 'unique_id': item['unique_id'],
  //                 'details': item['details'],
  //                 'max_item_quantity': item['max_item_quantity'],
  //                 'specifications': item['specifications'],
  //                 'note_for_item': item['note_for_item'],

  //                 // Store details
  //                 'store_detail': storeDetail,
  //                 'store_id': storeDetail['_id'],
  //                 'store_name': storeDetail['name'],
  //                 'store_location': storeLocation,

  //                 // Order details
  //                 'order_id': order['_id'],
  //                 'order_unique_id': order['unique_id'],
  //                 'distance_from_user': distance,
  //                 'is_urgent': isUrgent,
  //               };
  //               if (isUrgent) {
  //                 proximityItems.add(enrichedItem);
  //               }
  //             }
  //           }
  //         }
  //       }

  //       // Sort by distance (closest first)
  //       proximityItems.sort((a, b) {
  //         double distA = a['distance_from_user'] ?? double.infinity;
  //         double distB = b['distance_from_user'] ?? double.infinity;
  //         return distA.compareTo(distB);
  //       });

  //       return proximityItems;
  //     }

  //     return [];
  //   } catch (e) {
  //     // print("Error fetching proximity orders: $e");
  //     return [];
  //   }
  // }

  ///////////////////////////Proximity Order Methods Closed ==////////////////////
}
