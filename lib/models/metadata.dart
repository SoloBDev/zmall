import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';

class ZMetaData extends ChangeNotifier {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String baseUrl = BASE_URL;
  String? countryId = country_id['Ethiopia'];
  String cityId = "5b406b46d2ddf8062d11b788";
  String areaCode = "+251";
  String country = "Ethiopia";
  double longitude = 38.768154;
  double latitude = 9.004188;
  String currency = "ብር";

  void setLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  void changeCountrySettings(String newString) {
    if (newString == "Ethiopia") {
      baseUrl = BASE_URL;
      countryId = country_id['Ethiopia'];
      cityId = "5b406b46d2ddf8062d11b788";
      areaCode = "+251";
      country = "Ethiopia";
      longitude = 38.768154;
      latitude = 9.004188;
      currency = "ብር";

      Service.save("country", "Ethiopia");
    } else if (newString == "South Sudan") {
      baseUrl = BASE_URL_JUBA;
      countryId = country_id['South Sudan'];
      cityId = "62fef290ae93d51e87b468ab";
      areaCode = "+211";
      country = "South Sudan";
      longitude = 31.583369;
      latitude = 4.861544;
      currency = "SSP";
      Service.save("country", "South Sudan");
    }
    notifyListeners();
  }

  void changeUserLocation(double lat, double long) {
    latitude = lat;
    longitude = long;
    Service.save('latitude', lat);
    Service.save('longitude', long);
    notifyListeners();
  }
}
