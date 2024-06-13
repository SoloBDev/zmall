import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/items/global_items.dart';
import 'package:zmall/global/stores/global_stores.dart';
import 'package:zmall/home/components/offer_card.dart';
import 'package:zmall/main.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/section_title.dart';

class GlobalHomeScreen extends StatefulWidget {
  // const GlobalHomeScreen({
  //   // required this.user,
  // });

  // final User user;

  @override
  _GlobalHomeScreenState createState() => _GlobalHomeScreenState();
}

class _GlobalHomeScreenState extends State<GlobalHomeScreen> {
  User? user;
  AbroadData? abroadData;
  String username = "";
  String email = "";
  String city = "";

  bool _loading = false;
  var categoriesResponse;
  late double latitude, longitude;
  var responseData;
  var categories;
  var promotionalItems;
  bool _isClosed = false;
  String promptMessage =
      'We are sorry to inform you that we are not operational today';

  LocationPermission _permissionStatus = LocationPermission.denied;

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
    if (mounted) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
      });
      Provider.of<ZMetaData>(context, listen: false)
          .setLocation(currentLocation.latitude, currentLocation.longitude);
    }
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    CoreServices.registerNotification(context);
    MyApp.messaging.triggerEvent("at_home");
    FirebaseMessaging.instance.subscribeToTopic("abroad");
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened by notification");
      MyApp.analytics.logEvent(name: "notification_open");
    });
    getAbroadUser();
    _doLocationTask();
    _getPromotionalItems();
    checkAbroad();
  }


  Future<dynamic> getCategoryList(double longitude, double latitude,
      String countryCode, String countryName) async {
    var url =
        "https://app.zmallapp.com/api/user/get_delivery_list_for_nearest_city";
    Map data = {
      "latitude": latitude,
      "longitude": longitude,
      "country": countryName,
      "country_code": countryCode
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
      print(e);

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

  void checkAbroad() async {
    setState(() {
      _loading = true;
    });
    _getAppKeys();
    var data = await getCategoryList(
        38.768154, 9.004188, "5b3f76f2022985030cd3a437", "Ethiopia");
    if (data != null && data['success']) {
      setState(() {
        categories = data['deliveries'];
        responseData = data;
        Service.save('categories', categories);
      });
    }
    setState(() {
      _loading = false;
    });
  }

  void _getPromotionalItems() async {
    setState(() {
      _loading = true;
    });
    var data = await CoreServices.getPromotionalItems(
      userId: "user_id",
      serverToken: "server_token",
      ctx: context,
    );

    if (data != null && data['success']) {
      // print("Fetched promotional Items....");
      if (mounted) {
        // print(data);
        Service.save('p_items', data);
        setState(() {
          promotionalItems = data;
        });
        getLocalPromotionalItems();
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void getLocalPromotionalItems() async {
    var data = await Service.read('p_items');
    if (data != null) {
      setState(() {
        promotionalItems = data;
        _loading = false;
      });
    }
  }

  void getUser() async {
    var data = await Service.read('abroad_user');


    getAbroadUser();
  }

  void getAbroadUser() async {
    var data = await Service.read('abroad_user');
    if (data != null) {
      abroadData = AbroadData.fromJson(data);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: kPrimaryColor,
            title: Text("Dear Esteemed User,"),
            content: Wrap(
              children: [
                Text("Please complete registration..."),
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding / 2),
                ),
                TextField(
                  style: TextStyle(color: kBlackColor),
                  keyboardType: TextInputType.text,
                  onChanged: (val) {
                    username = val;
                  },
                  decoration: textFieldInputDecorator.copyWith(
                      labelText: username.isNotEmpty ? username : "Full Name"),
                ),
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding),
                ),
                TextField(
                  style: TextStyle(color: kBlackColor),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) {
                    email = val;
                  },
                  decoration: textFieldInputDecorator.copyWith(
                      labelText: email.isNotEmpty ? email : "Email"),
                ),
                // Container(
                //   height: getProportionateScreenHeight(kDefaultPadding),
                // ),
                // TextField(
                //   style: TextStyle(color: kBlackColor),
                //   keyboardType: TextInputType.text,
                //   onChanged: (val) {
                //     city = val;
                //   },
                //   decoration: textFieldInputDecorator?.copyWith(
                //       labelText: city.isNotEmpty ? city : "City"),
                // ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Save Now",
                  style: TextStyle(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  if (username.isNotEmpty && email.isNotEmpty) {
                    var abroadUser = AbroadData(
                        abroadName: username,
                        abroadEmail: email,
                        abroadPhone: user!.phoneNumber);
                    setState(() {
                      abroadData = abroadUser;
                    });
                    await Service.save('abroad_user', abroadData!.toJson());
                    Navigator.of(context).pop();
                    // bool success =
                    //     await FirebaseCoreServices.addDataToUserProfile(
                    //         user.uid,
                    //         {
                    //           "full_name": username,
                    //           "email": email,
                    //           "city": city,
                    //         },
                    //         isUpdate: true);
                    // if (success) {
                    //   Navigator.of(context).pop();
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //       Service.showMessage(
                    //           "User data successfully updated", false));
                    // } else {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //       Service.showMessage(
                    //           "Something went wrong, data wasn't saved", true));
                    // }
                  } else {
                    // Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        Service.showMessage(
                            "Please add the necessary information", true));
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }


  void _getAppKeys() async {
    var data = await CoreServices.appKeys(context);
    if (data['success']) {
      if (data['message_flag']) {
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "${data['message']} We deliver your order once we resume our service.",
            false,
            duration: 4));
      }
      Service.saveBool("is_closed", false);
      Service.save("closed_message", data['message']);
      Service.save("ios_app_version", data['ios_user_app_version_code']);
      Service.saveBool(
          "ios_update_dialog", data['is_ios_user_app_open_update_dialog']);
      Service.saveBool(
          "ios_force_update", data['is_ios_user_app_force_update']);
    }
    getAppKeys();
  }

  void getAppKeys() async {
    var data = await Service.read('ios_app_version');
    var currentVersion = await Service.read('version');
    _isClosed = await Service.readBool('is_closed');
    promptMessage = await Service.read('closed_message');
    var showUpdateDialog = await Service.readBool('ios_update_dialog');
    if (data != null) {
      if (currentVersion != data) {
        if (showUpdateDialog) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: kPrimaryColor,
                title: Text("New Version Update"),
                content: Text(
                    "We have detected an older version on the App on your phone."),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      "Update Now",
                      style: TextStyle(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Service.launchInWebViewOrVC("http://onelink.to/vnchst");
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text.rich(
          TextSpan(
            text: "Z",
            style: TextStyle(
              color: kSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: "Mall Global",
                style: TextStyle(
                  color: kBlackColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        color: kPrimaryColor,
        progressIndicator: linearProgressIndicator,
        child: categories != null
            ? SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: getProportionateScreenHeight(kDefaultPadding)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        color: kPrimaryColor,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left:
                                  getProportionateScreenWidth(kDefaultPadding),
                              right:
                                  getProportionateScreenWidth(kDefaultPadding),
                              top: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                          child: Text(
                            abroadData != null
                                ? "Welcome, ${abroadData!.abroadName}"
                                : "Welcome to ZMall Global",
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      ),
                      Container(
                        color: kPrimaryColor,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding),
                              ),
                              child: SectionTitle(
                                sectionTitle: "Specials for your loved ones",
                                subTitle: " ",
                              ),
                            ),
                            SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 2),
                            ),
                            promotionalItems != null
                                ? Container(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding * 12),
                                    width: double.infinity,
                                    padding: EdgeInsets.only(
                                      right: getProportionateScreenWidth(
                                          kDefaultPadding / 2),
                                    ),
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: promotionalItems != null &&
                                              promotionalItems[
                                                          'promotional_items']
                                                      .length >
                                                  0
                                          ? promotionalItems[
                                                  'promotional_items']
                                              .length
                                          : 0,
                                      itemBuilder: (context, index) => Row(
                                        children: [
                                          index == 0
                                              ? SizedBox(
                                                  width:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding),
                                                )
                                              : Container(),
                                          SpecialOfferCard(
                                            imageUrl: promotionalItems !=
                                                        null &&
                                                    promotionalItems['promotional_items']
                                                                    [index]
                                                                ['image_url']
                                                            .length >
                                                        0
                                                ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${promotionalItems['promotional_items'][index]['image_url'][0]}"
                                                : "www.google.com",
                                            itemName:
                                                "${promotionalItems['promotional_items'][index]['name']}\n",
                                            newPrice:
                                                "${promotionalItems['promotional_items'][index]['price'].toStringAsFixed(2)}\t",
                                            originalPrice:
                                                "${promotionalItems['promotional_items'][index]['new_price'].toStringAsFixed(2)}",
                                            isDiscounted: promotionalItems[
                                                    'promotional_items'][index]
                                                ['discount'],
                                            storeName: promotionalItems[
                                                    'promotional_items'][index]
                                                ['store_name'],
                                            storePress: (){},
                                            press: () async {
                                              // bool isOp = await storeOpen(
                                              //     promotionalItems[
                                              //     'promotional_items'][index]);
                                              // if (isOp) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return GlobalItem(
                                                      item: promotionalItems[
                                                              'promotional_items']
                                                          [index],
                                                      location: promotionalItems[
                                                              'promotional_items']
                                                          [
                                                          index]['store_location'],
                                                      isOpen: true,
                                                    );
                                                  },
                                                ),
                                              );
                                              // }
                                              // else {
                                              //   if (mounted) {
                                              //     ScaffoldMessenger.of(context)
                                              //         .showSnackBar(
                                              //       Service.showMessage(
                                              //           "Store is currently closed. We highly recommend you to try other store. We've got them all...",
                                              //           false,
                                              //           duration: 3),
                                              //     );
                                              //   }
                                              // }
                                            },
                                          ),
                                        ],
                                      ),
                                      separatorBuilder:
                                          (BuildContext context, int index) =>
                                              SizedBox(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding / 2),
                                      ),
                                    ),
                                  )
                                : _loading
                                    ? Container(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding * 12),
                                        width: double.infinity,
                                        child: SpinKitWave(
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                      )
                                    : Container(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding * 12),
                                        child: Center(
                                          child: Text(
                                              "Nothing to show, please try again..."),
                                        ),
                                      ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      Container(
                        color: kPrimaryColor,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding),
                              ),
                              child: SectionTitle(
                                sectionTitle: "What would you like to order?",
                                subTitle: " ",
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                      kDefaultPadding)),
                              child: GridView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount:
                                    categories != null ? categories.length : 0,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: kDefaultPadding * .8,
                                  mainAxisSpacing: kDefaultPadding * .8,
                                  childAspectRatio:
                                      MediaQuery.of(context).size.width < 650.0
                                          ? 1.3
                                          : 1,
                                ),
                                itemBuilder: (context, index) =>
                                    GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return GlobalStore(
                                            cityId: responseData['city']['_id'],
                                            storeDeliveryId: categories[index]
                                                ['_id'],
                                            category: categories[index],
                                            latitude: latitude,
                                            longitude: longitude,
                                            isStore: false,
                                            companyId: null,
                                          );
                                        },
                                      ),
                                    ).then((value) {
                                      checkAbroad();
                                      _getPromotionalItems();
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${categories[index]['image_url']}",
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            decoration: BoxDecoration(
                                              color: kWhiteColor,
                                              image: DecorationImage(
                                                fit: BoxFit.contain,
                                                image: imageProvider,
                                              ),
                                            ),
                                          ),
                                          placeholder: (context, url) => Center(
                                            child: Container(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * 3.5),
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 3.5),
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(kWhiteColor),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image: AssetImage(
                                                    'images/zmall.jpg'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        categories[index]['delivery_name'],
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: kBlackColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _loading
                ? Container()
                : Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding * 4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          title: "Retry",
                          press: () {
                            print("retry....");
                            checkAbroad();
                          },
                          color: kSecondaryColor,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
