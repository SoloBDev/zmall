import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:fl_location/fl_location.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/global/global.dart';
import 'package:zmall/global/home_page/global_home.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:flutter/material.dart';
import 'package:zmall/tab_screen.dart';
import 'package:zmall/size_config.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/login/login_screen.dart';

import 'component/loader.dart';
import 'component/splash_container.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = '/splash';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool logged = false;
  late Uint8List bytes;
  late String urlLink, adId;
  bool loading = true;
  String _projectVersion = '';
  LocationPermission _permissionStatus = LocationPermission.denied;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLang();
    getMetaData();
    initPlatformState();
    isLogged();
    getAd();
    _doLocationTask();
    MyApp.analytics.logAppOpen();
    loader(7);
  }

  void getLang() async {
    var data = await Service.read('lang');
    print("Checking language");
    if (data == null) {
      Provider.of<ZLanguage>(context, listen: false).changeLanguage('en_US');
    } else {
      Provider.of<ZLanguage>(context, listen: false).changeLanguage(data);
    }
  }

  void fetchAd() async {
    await getAd();
  }

  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Location permission denied. Please enable and try again", true));
      FlLocation.requestLocationPermission();
    }
  }

  void getLocation() async {
    var currentLocation = await FlLocation.getLocation();
    print("Checking location.....");
    Provider.of<ZMetaData>(context, listen: false)
        .setLocation(currentLocation.latitude, currentLocation.longitude);
  }

  void _doLocationTask() async {
    LocationPermission _permissionStatus =
        await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.whileInUse ||
        _permissionStatus == LocationPermission.always) {
      if (await FlLocation.isLocationServicesEnabled) {
        getLocation();
      } else {
        LocationPermission serviceStatus =
            await FlLocation.requestLocationPermission();
        if (serviceStatus == LocationPermission.always ||
            serviceStatus == LocationPermission.whileInUse) {
          getLocation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
              "Location service disabled. Please enable and try again", true));
        }
      }
    } else {
      _requestLocationPermission();
    }
  }

  void getMetaData() async {
    String? country = await Service.read("country");

    if (country != null) {
      Provider.of<ZMetaData>(context, listen: false)
          .changeCountrySettings(country);
    } else {
      Provider.of<ZMetaData>(context, listen: false)
          .changeCountrySettings("Ethiopia");
    }
  }

  void _getAppKeys() async {
    var data = await getAppKeys();
    if (data != null && data['success']) {
      print("Saving data....");
      Service.saveBool("is_closed", data['message_flag']);
      Service.save("closed_message", data['message']);
      Service.save("ios_app_version", data['ios_user_app_version_code']);
      Service.saveBool(
          "ios_update_dialog", data['is_ios_user_app_open_update_dialog']);
      Service.saveBool(
          "ios_force_update", data['is_ios_user_app_force_update']);
    }
  }

  initPlatformState() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String projectVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      projectVersion = packageInfo.version;
    } on PlatformException {
      projectVersion = 'Failed to get project version.';
    }

    if (!mounted) return;

    setState(() {
      _projectVersion = projectVersion;
    });
    if (_projectVersion.isNotEmpty) {
      Service.save('version', _projectVersion);
      _getAppKeys();
    }
  }

  Future<Timer> loader(int seconds) async {
    return Timer(Duration(seconds: seconds), onDoneLoading);
  }

  onDoneLoading() async {
    bool? isGlobal = await Service.readBool('is_global');
    var abroadData = await Service.read('abroad_user');
    if (mounted) {
      try {
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(
        //     builder: (context) => FirebaseAuth.instance.currentUser != null
        //         ? GlobalHome(
        //             user: FirebaseAuth.instance.currentUser,
        //           )
        //         : GlobalScreen(),
        //   ),
        // );
        isGlobal != null && isGlobal == true
            ? Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      abroadData != null ? GlobalHome() : GlobalScreen(),
                ),
              )
            : Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      logged ? TabScreen(isLaunched: true) : LoginScreen(),
                ),
              );
      } catch (e) {
        print("Ad skipped...");
      }
    }
  }

  void isLogged() async {
    var data = await Service.readBool('logged');
    if (data != null) {
      setState(() {
        logged = data;
      });
    } else {
      print("No logged user found");
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kSecondaryColor,
      body: Center(
        child: loading
            ? Loader()
            : SplashContainer(
                urlLink: urlLink,
                bytes: bytes,
                adId: adId,
                logged: logged,
              ),
      ),
    );
  }

  Future<String> getAd() async {
    var url = Uri.parse("https://nedajmadeya.com/ad/launch");
    try {
      http.Response response = await http
          .get(url, headers: <String, String>{'Device': 'ios'}).timeout(
              Duration(seconds: 5), onTimeout: () {
        throw TimeoutException("The connection has timed out!");
      });
      var data = json.decode(response.body);

      setState(() {
        bytes = base64Decode(data['image']);
        urlLink = data['url_link'];
        adId = data['ad_id'];
        loading = !loading;
      });
      return "success";
    } catch (e) {
      // print(e);
      loader(5);
      return "failed";
    }
  }

  Future<dynamic> getAppKeys() async {
    var url = Uri.parse(
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_app_keys");

    try {
      http.Response response =
          await http.post(url).timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException("The connection has timed out!");
      });
      if (json.decode(response.body) != null &&
          json.decode(response.body)['success']) {
        var data = {
          "success": json.decode(response.body)['success'],
          "message_flag": json.decode(response.body)['app_keys']
              ['message_flag'],
          "ios_user_app_version_code": json.decode(response.body)['app_keys']
              ['ios_user_app_version_code'],
          "message": json.decode(response.body)['app_keys']['message'],
          "ios_user_app_version_code": json.decode(response.body)['app_keys']
              ['ios_user_app_version_code'],
          "is_ios_user_app_open_update_dialog":
              json.decode(response.body)['app_keys']
                  ['is_ios_user_app_open_update_dialog'],
          "is_ios_user_app_force_update": json.decode(response.body)['app_keys']
              ['is_ios_user_app_force_update']
        };
        return data;
      } else {
        var data = {"success": false};
        return data;
      }
    } catch (e) {
      // print(e);
      return null;
    }
  }
}
