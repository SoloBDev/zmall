import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/models/metadata.dart';

import 'constants.dart';

class Service {
  static Future<void> launchInWebViewOrVC(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        // forceWebView: true,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static SnackBar showMessage(String? title, bool error, {int duration = 2}) {
    final snackbar = SnackBar(
      backgroundColor: error ? kSecondaryColor : kGreyColor,
      content: Text(
        title!,
        style: TextStyle(
          fontSize: 15,
          color: kPrimaryColor,
        ),
      ),
      duration: Duration(seconds: duration),
      behavior: SnackBarBehavior.floating,
    );
    return snackbar;
  }

  static Future<bool> isConnected(context) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(showMessage("Check your internet connection", true));
      return false;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(showMessage("Check your internet connection", true));
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
          "Accept": "application/json"
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
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double distance = acos(
            sin(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) +
                cos(_degreesToRadians(lat1)) *
                    cos(_degreesToRadians(lat2)) *
                    cos(dLon)) *
        earthRadius;

    // Return the distance in kilometers
    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  /////////////////////////////////////////////////////////
}
