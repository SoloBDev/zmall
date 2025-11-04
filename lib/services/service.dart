import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/utils/size_config.dart';

import '../utils/constants.dart';

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
}
