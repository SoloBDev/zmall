import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import '../utils/constants.dart';

class CoreServices {
  static Future<dynamic> getCategoryList(
      {required double longitude,
      required double latitude,
      required String countryCode,
      required String countryName,
      required BuildContext context,
      bool? isGlobal}) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_delivery_list_for_nearest_city";
    Map data = {
      "latitude": latitude,
      "longitude": longitude,
      "country": countryName,
      "country_code": countryCode,
      if (isGlobal != null) "isGlobal": isGlobal
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
      await Service.save('categories', json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Connection timeout! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  static Future _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // debugPrint("Got a background message");
    // debugPrint("Handling a background message: ${message.messageId}");
  }

  static void registerNotification(BuildContext context) async {
    Service.isConnected(context).then((connected) async {
      if (connected) {
        // 1. Initialize the Firebase app
        await Firebase.initializeApp();

        // 2. Instantiate Firebase Messaging
        FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
        // 3. On iOS, this helps to take the user permissions
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          provisional: false,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            // TODO: Play sound
            showSimpleNotification(
              Text(
                message.notification!.title!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                message.notification!.body!,
              ),
              background: kSecondaryColor,
              duration: Duration(seconds: 7),
              elevation: 1.0,
              slideDismiss: true,
              slideDismissDirection: DismissDirection.up,
            );
          });
        } else {
          // debugPrint('User declined or has not accepted permission');
        }
      }
    });
  }

  static Future<dynamic> getServicesList(double longitude, double latitude,
      String countryCode, String countryName, BuildContext ctx) async {
    var url =
        "${Provider.of<ZMetaData>(ctx, listen: false).baseUrl}/api/user/get_delivery_list_for_nearest_city";
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
      // debugPrint(e);

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  static Future<dynamic> getPromotionalItems(
      {required String userId,
      required String serverToken,
      required BuildContext ctx,
      required List<double> userLocation,
      bool? isGlobal}) async {
    var url =
        "${Provider.of<ZMetaData>(ctx, listen: false).baseUrl}/api/user/get_promotion_item";
    Map data = {
      "user_id": userId,
      "server_token": serverToken,
      "userLocation": userLocation,
      if (isGlobal != null) "isGlobal": isGlobal,
    };

    var body = json.encode(data);
    // debugPrint("promotionalItems body $body");
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
        Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      await Service.save('p_items', json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  static Future<dynamic> getPromotionalStores(
      {required String userId,
      required String serverToken,
      required BuildContext ctx,
      required double latitude,
      required double longitude}) async {
    var url =
        "${Provider.of<ZMetaData>(ctx, listen: false).baseUrl}/api/user/get_promotion_store";
    Map data = {
      "user_id": userId,
      "server_token": serverToken,
      "latitude": latitude,
      "longitude": longitude
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
        Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      await Service.save('s_items', json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  static Future<dynamic> updateDeviceToken(
      {required String userId,
      required String serverToken,
      required String deviceToken,
      required BuildContext context}) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/update_device_token";
    Map data = {
      "user_id": userId,
      "server_token": serverToken,
      "device_token": deviceToken
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
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  static Future<dynamic> appKeys(context) async {
    var url = Uri.parse(
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_app_keys");

    try {
      http.Response response =
          await http.post(url).timeout(Duration(seconds: 15), onTimeout: () {
        throw TimeoutException("The connection has timed out!");
      });
      if (json.decode(response.body) != null &&
          json.decode(response.body)['success']) {
        // debugPrint(response.body);
        var data = {
          "success": json.decode(response.body)['success'],
          "message_flag": json.decode(response.body)['app_keys']
              ['message_flag'],
          "ios_user_app_version_code": json.decode(response.body)['app_keys']
              ['ios_user_app_version_code'],
          "message": json.decode(response.body)['app_keys']['message'],
          // "ios_user_app_version_code": json.decode(response.body)['app_keys']
          //     ['ios_user_app_version_code'],
          "is_ios_user_app_open_update_dialog":
              json.decode(response.body)['app_keys']
                  ['is_ios_user_app_open_update_dialog'],
          "is_ios_user_app_force_update": json.decode(response.body)['app_keys']
              ['is_ios_user_app_force_update'],
          "app_open": json.decode(response.body)['app_keys']['app_open_time'],
          "app_close": json.decode(response.body)['app_keys']['app_close_time'],
        };
        return data;
      } else {
        var data = {"success": false};
        return data;
      }
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  static Future<Map?> saveAdClick(String adId) async {
    var url = "https://nedajmadeya.com/ad/click/$adId";
    try {
      http.Response response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
      ).timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException(
            "The connection has timed out. Cannot fetch user...");
      });
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  static Future<dynamic> getUserDetail(userId, serverToken, context) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_detail";
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }

  static Future<dynamic> clearCache() async {
    await Service.saveBool('logged', false);
    await Service.remove('user');
    await Service.remove('cart');
    await Service.remove('aliexpressCart'); //
    await Service.remove('images');
    await Service.remove('p_items');
    await Service.remove('s_items');
  }
}
