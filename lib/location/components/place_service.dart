import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

class Place {
  double longitude, latitude;

  Place({
    required this.longitude,
    required this.latitude,
  });

  @override
  String toString() {
    return 'Place(longitude: $longitude, latitude: $latitude)';
  }
}

class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

class PlaceApiProvider {
  final client = Client();

  PlaceApiProvider(this.sessionToken);

  final sessionToken;

  static final String androidKey = 'AIzaSyBzMHLnXLbtLMi9rVFOR0eo5pbouBtxyjg';
  static final String iosKey = 'AIzaSyDAgZScAJfUHxahi_n4OpuI8HrTHVlirJk';
  final apiKey = Platform.isAndroid ? androidKey : iosKey;

  Future<List<Suggestion>> fetchSuggestions(String input, String lang) async {
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&location=9.010618,38.761257&key=$apiKey&sessiontoken=$sessionToken&radius=10000';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // compose suggestions in a list

        return result['predictions']
            .map<Suggestion>((p) => Suggestion(p['place_id'], p['description']))
            .toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<Place> getPlaceDetailFromId(String placeId) async {
    final request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=address_component,geometry&key=$apiKey&sessiontoken=$sessionToken&rankby=distance';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        var components = result['result']['geometry'];
        // build result
        final place = Place(
            latitude: components['location']['lat'],
            longitude: components['location']['lng']);

        return place;
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<dynamic> getPlaceDetailFromLatLng(double lat, double lng) async {
    final request =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&sessiontoken=$sessionToken";
    final response = await client.get(Uri.parse(request));
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        String location = result['results'][0]['formatted_address'];

        if (location.isNotEmpty) {
          return location;
        } else {
          return null;
        }
      } else {
//        throw Exception(result['error_message']);

        return null;
      }
    } else {
//      throw Exception('Failed to fetch suggestion');
      return null;
    }
  }
}
