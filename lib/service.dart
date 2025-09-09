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
import 'package:zmall/size_config.dart';

import 'constants.dart';

class Service {
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

  static SnackBar showMessage1(String? title, bool error, {int duration = 2}) {
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

  static void showMessage({
    required BuildContext context,
    String? title,
    bool? error,
    int duration = 2,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error == null
          ? kGreyColor
          : error
              ? kSecondaryColor
              : kGreenColor,
      content: Text(
        title!,
        style: TextStyle(
          fontSize: 15,
          color: kPrimaryColor,
        ),
      ),
      duration: Duration(seconds: duration),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding),
          vertical: getProportionateScreenHeight(kDefaultPadding)),
    ));
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
          error: true);
      return false;
    }
    showMessage(
        context: context, title: "Check your internet connection", error: true);
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
  static String capitalizeFirstLetters(String input) {
    input = input.toLowerCase();
    if (input.contains('[') && input.contains(']')) {
      input = input.replaceAll('[', '').replaceAll(']', '');
    }
    // // Split by commas, preserving spaces within each part
    List<String> parts = input.split(',');

    // Capitalize each part and preserve commas and spaces
    String result = parts.map((part) {
      List<String> words = part.trim().split(RegExp(r'\s+'));
      return words
          .map((word) => word.trim().isEmpty
              ? word.trim()
              : word.trim().substring(0, 1).toUpperCase() +
                  word.trim().substring(1))
          .join(' ');
    }).join(', ');

    // Remove any duplicated values
    result = result.trim().replaceAll(RegExp(r'\s*,+\s*'), ', ');
    List<String> capitalizedWords = result.split(',');
    Set<String> uniqueWords = {};
    capitalizedWords.forEach((word) => uniqueWords.add(word.trim()));
    return uniqueWords.join(', ');
  }
  /////////////////////////////////////////////////////////
}
