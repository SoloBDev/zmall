import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/models/metadata.dart';

class ChatService {
  ////get usser data
  static Future<dynamic> userDetails({
    required BuildContext context,
    required String userId,
    required String serverToken,
  }) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_detail";
    Map data = {"user_id": userId, "server_token": serverToken};
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
            const Duration(seconds: 30),
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

  /// Send a message to the chat API and get bot response
  static Future<Map<String, dynamic>?> sendMessage({
    required String message,
    required BuildContext context,
    required String userId,
    String? sessionId,
    String? orderId,
    required String serverToken,
    required List userLocation,
  }) async {
    // Get base URL from metadata provider
    final baseUrl = Provider.of<ZMetaData>(context, listen: false).baseUrl;
    var url = "$baseUrl/chat_test";
    // var url = "https://test.zmallapp.com/chat_test";

    try {
      Map<String, dynamic> data = {
        "message": message,
        "user_id": userId,
        "user_location": userLocation,
        "server_token": serverToken,
      };

      // Add optional parameters if provided
      if (sessionId != null && sessionId.isNotEmpty) {
        data["session_id"] = sessionId;
      }
      if (orderId != null && orderId.isNotEmpty) {
        data["order_id"] = orderId;
      }

      // debugPrint("====Chat API Request: $data");
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
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException("The connection has timed out!");
            },
          );

      // debugPrint("=====Chat API Response Status: ${response.statusCode}");
      // debugPrint("====Chat API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        // debugPrint("====Chat API Error: Status ${response.statusCode}");
        return {
          'error': true,

          'message':
              'Connection timed out. Please try again.', // 'message': 'Failed to get response. Status: ${response.statusCode}',
        };
      }
    } on TimeoutException catch (e) {
      // debugPrint("====Chat API Timeout: $e");
      return {
        'error': true,
        'message': 'Connection timed out. Please try again.',
      };
    } catch (e) {
      // debugPrint("=====Chat API Error: $e");
      return {
        'error': true,
        'message':
            'Something went wrong. Please check your internet connection.',
      };
    }
  }
  ////////////////////get user order///////////////////

  static Future<dynamic> getOrders({
    required String userId,
    required String serverToken,
    required BuildContext context,
  }) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_orders";
    Map data = {"user_id": userId, "server_token": serverToken};
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
              throw TimeoutException("The connection has timed out!");
            },
          );

      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }

  /////////////////////////////////////////////////////////////////////
  /// Send message with full metadata context
  static Future<Map<String, dynamic>?> sendMessageWithContext({
    required String message,
    required BuildContext context,
    Map<String, dynamic>? additionalData,
  }) async {
    // Get base URL from metadata provider
    final baseUrl = Provider.of<ZMetaData>(context, listen: false).baseUrl;
    var url = "$baseUrl/chat_test";

    try {
      Map<String, dynamic> data = {"message": message};

      // Add any additional data
      if (additionalData != null) {
        data.addAll(additionalData);
      }

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
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException("The connection has timed out!");
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'error': true,
          'message': 'Failed to get response. Status: ${response.statusCode}',
        };
      }
    } on TimeoutException catch (e) {
      // debugPrint("Chat API Timeout: $e");
      return {
        'error': true,
        'message': 'Connection timed out. Please try again.',
      };
    } catch (e) {
      // debugPrint("Chat API Error: $e");
      return {
        'error': true,
        'message':
            'Something went wrong. Please check your internet connection.',
      };
    }
  }
}
