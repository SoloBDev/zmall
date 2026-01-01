import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zmall/home/magazine/models/magazine_model.dart';
import 'package:zmall/models/metadata.dart';

class MagazineService {
  // Fetch magazines from API /api/user/get_magazine_list
  static Future<List<Magazine>> fetchMagazines({
    required String userId,
    required String serverToken,
    required BuildContext context,
    int? year,
  }) async {
    try {
      final currentYear = year ?? DateTime.now().year;
      final response = await getMagazineList(
        year: currentYear,
        userId: userId,
        serverToken: serverToken,
        context: context,
      );

      if (response != null && response['success'] == true) {
        final magazinesData = response['magazines'] as List?;
        if (magazinesData != null) {
          return magazinesData.map((json) => Magazine.fromJson(json)).toList();
        }
      }

      // Return empty list if no data
      return [];
    } catch (e) {
      debugPrint('Error fetching magazines: $e');
      return [];
    }
  }

  static Future<dynamic> getMagazineList({
    required int year,
    required String userId,
    required String serverToken,
    required BuildContext context,
    int maxRetries = 3,
  }) async {
    final baseUrl = Provider.of<ZMetaData>(context, listen: false).baseUrl;
    final url = "$baseUrl/api/user/get_magazine_list";

    Map<String, dynamic> data = {
      "year": "$year",
      "user_id": userId,
      "is_show_recap": true,
      "server_token": serverToken,
      "timestamp": DateTime.now().toIso8601String(),
    };
    // debugPrint('data $data');
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
      // debugPrint('magazin list: $responseData');

      return responseData;
    } catch (e) {
      debugPrint('Error $e');
    }
  }

  static Future<dynamic> updateUserMagazineInteraction({
    required int year,
    required String userId,
    required String magazineId,
    required String serverToken,
    required BuildContext context,
    required String interactionType,
  }) async {
    final baseUrl = Provider.of<ZMetaData>(context, listen: false).baseUrl;
    final url = "$baseUrl/api/user/magazine_interaction";

    Map<String, dynamic> data = {
      "year": "$year",
      "user_id": userId,
      "magazine_id": magazineId,
      "server_token": serverToken,
      "type": interactionType, //view or like
      "timestamp": DateTime.now().toIso8601String(),
    };

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
      debugPrint('magazine tracinteractionking response: $responseData');

      return responseData;
    } catch (e) {
      debugPrint('Error $e');
    }
  }

  // Fetch magazine by ID
  static Future<Magazine?> fetchMagazineById({
    required String id,
    required String userId,
    required String serverToken,
    required BuildContext context,
    int? year,
  }) async {
    try {
      final magazines = await fetchMagazines(
        userId: userId,
        serverToken: serverToken,
        context: context,
        year: year,
      );
      return magazines.firstWhere(
        (mag) => mag.id == id,
        orElse: () => throw Exception('Magazine not found'),
      );
    } catch (e) {
      debugPrint('Error fetching magazine by ID: $e');
      return null;
    }
  }

  // Fetch magazines by category
  static Future<List<Magazine>> fetchMagazinesByCategory({
    required String category,
    required String userId,
    required String serverToken,
    required BuildContext context,
    int? year,
  }) async {
    try {
      final magazines = await fetchMagazines(
        userId: userId,
        serverToken: serverToken,
        context: context,
        year: year,
      );
      return magazines.where((mag) => mag.category == category).toList();
    } catch (e) {
      debugPrint('Error fetching magazines by category: $e');
      return [];
    }
  }
}
