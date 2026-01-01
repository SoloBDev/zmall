import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zmall/models/metadata.dart';

class RecapService {
  static Future<dynamic> trackRecapOpened({
    required int year,
    required String userId,
    required String serverToken,
    required BuildContext context,
    int maxRetries = 3,
  }) async {
    final baseUrl = Provider.of<ZMetaData>(context, listen: false).baseUrl;
    final url = "$baseUrl/api/user/save_recap_info";

    Map<String, dynamic> data = {
      "year": "$year",
      "user_id": userId,
      "is_show_recap": true,
      "server_token": serverToken,
      "timestamp": DateTime.now().toIso8601String(),
    };

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // debugPrint( 'Tracking recap opened - Attempt ${attempt + 1}/$maxRetries', );

        http.Response response = await http
            .post(
              Uri.parse(url),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Accept": "application/json",
              },
              body: json.encode(data),
            )
            .timeout(
              Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException("The connection has timed out!");
              },
            );

        final responseData = json.decode(response.body);
        // debugPrint('Recap tracking response: $responseData');

        // Check if response is successful
        if (responseData is Map && responseData['success'] == true) {
          // debugPrint('Recap tracking successful on attempt ${attempt + 1}');
          return responseData;
        } else {
          // Response received but not successful
          // debugPrint( 'Recap tracking failed - Response not successful: $responseData', );

          // If this is not the last attempt, wait before retrying
          if (attempt < maxRetries - 1) {
            final waitTime = Duration(
              seconds: (attempt + 1) * 2,
            ); // 2s, 4s, 6s...
            // debugPrint('Retrying in ${waitTime.inSeconds} seconds...');
            await Future.delayed(waitTime);
          }
        }
      } catch (e) {
        // debugPrint('Error tracking recap opened (attempt ${attempt + 1}): $e');

        // If this is not the last attempt, wait before retrying
        if (attempt < maxRetries - 1) {
          final waitTime = Duration(
            seconds: (attempt + 1) * 2,
          ); // 2s, 4s, 6s...
          // debugPrint('Retrying in ${waitTime.inSeconds} seconds...');
          await Future.delayed(waitTime);
        }
      }
    }

    // All retries exhausted
    // debugPrint('Failed to track recap after $maxRetries attempts');
    return null;
  }
}
