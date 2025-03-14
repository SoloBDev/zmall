import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/courier/components/locations_list.dart';
import 'package:zmall/courier/components/vehicle_screen.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/location/components/address_search.dart';
import 'package:zmall/location/components/place_service.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/section_title.dart';

class CourierScreen extends StatefulWidget {
  static String routeName = '/courier';

  const CourierScreen({
    this.curLat,
    this.curLon,
  });

  final double? curLon;
  final double? curLat;

  @override
  _CourierScreenState createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final _controller = TextEditingController();
  final _dropOffController = TextEditingController();
  late double latitude, longitude;
  late double destLatitude, destLongitude;
  var userData;
  var vehicleList;
  String senderUser = "", senderPhone = "";
  String receiverName = "", receiverPhone = "";
  String description = "";
  bool _loading = false;
  var orderDetail;

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
        senderUser = userData['user']['first_name'] +
            " " +
            userData['user']['last_name'];
        senderPhone = userData['user']['phone'];
      });
    }
  }

//  void _clearCart() async {
//    setState(() {
//      _loading = true;
//    });
//
//    var data = await clearCart();
//    if (data != null && data['success']) {
//      ScaffoldMessenger.of(context).showSnackBar(
//          Service.showMessage("Please select delivery vehicle!", false));
//    } else {
//      ScaffoldMessenger.of(context).showSnackBar(
//          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
//      await Future.delayed(Duration(seconds: 2));
//      if (data['error_code'] == 999) {
//        await Service.saveBool('logged', false);
//        await Service.remove('user');
//        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//      }
//    }
//  }

  void _addCourierToCart() async {
    setState(() {
      _loading = true;
    });
    var data = await addCourierToCart();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
      });
      // print(data);

      await Service.save('courier', data);
      await Service.save("is_schedule", false);
      await Service.save("schedule_start", null);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return VehicleScreen(
              userData: userData,
              orderDetail: orderDetail,
              pickupAddress: LatLng(latitude, longitude),
              destinationAddress: LatLng(destLatitude, destLongitude),
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      await Future.delayed(Duration(seconds: 2));
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Courier",
          style: TextStyle(color: kPrimaryColor),
        ),
        elevation: 0.0,
        backgroundColor: kSecondaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height * 0.22,
              child: Stack(
                children: [
                  Container(
                    height: size.height * 0.22 -
                        getProportionateScreenHeight(kDefaultPadding),
                    padding: EdgeInsets.symmetric(
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 2),
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(
                          getProportionateScreenWidth(kDefaultPadding),
                        ),
                        bottomLeft: Radius.circular(
                          getProportionateScreenWidth(kDefaultPadding),
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding / 2),
                        ),
                        Row(
                          children: [
                            Text(
                              "Courier Delivery",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.delivery_dining,
                              color: kPrimaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal:
                                  getProportionateScreenWidth(kDefaultPadding)),
                          height:
                              getProportionateScreenHeight(kDefaultPadding * 4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding),
                            ),
                            // boxShadow: [kDefaultShadow],
                          ),
                          child: Center(
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.text,
                              style: TextStyle(color: kBlackColor),
                              readOnly: true,
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LocationsList(
                                      title: "Pickup Address",
                                    ),
                                  ),
                                ).then((dynamic value) {
                                  if (value != null) {
                                    DestinationAddress address = value;
                                    setState(() {
                                      _controller.text = address.name!;
                                      longitude = double.parse(
                                          address.long!.toStringAsFixed(6));
                                      latitude = double.parse(
                                          address.lat!.toStringAsFixed(6));
                                    });
                                  }
                                });
//                                // generate a new token here
//                                final sessionToken = Uuid().v4();
//                                final Suggestion result = await showSearch(
//                                  context: context,
//                                  delegate: AddressSearch(sessionToken),
//                                );
//                                // This will change the text displayed in the TextField
//                                if (result != null) {
//                                  final placeDetails =
//                                      await PlaceApiProvider(sessionToken)
//                                          .getPlaceDetailFromId(result.placeId);
//                                  setState(() {
//                                    _controller.text = result.description;
//                                    longitude = placeDetails.longitude;
//                                    latitude = placeDetails.latitude;
////                              _center = LatLng(latitude, longitude);
//                                  });
////                            _mapController.move(_center, 15);
//                                }
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.pin_drop,
                                  color: kSecondaryColor,
                                ),
                                hintText: "Pick-up Address",
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: kGreyColor),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    EdgeInsets.only(left: 8.0, top: 16.0),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding / 2),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal:
                                  getProportionateScreenWidth(kDefaultPadding)),
                          height:
                              getProportionateScreenHeight(kDefaultPadding * 4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding),
                            ),
                            // boxShadow: [kDefaultShadow],
                          ),
                          child: Center(
                            child: TextField(
                              controller: _dropOffController,
                              keyboardType: TextInputType.text,
                              style: TextStyle(color: kBlackColor),
                              readOnly: true,
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LocationsList(
                                      title: "Dropoff Address",
                                    ),
                                  ),
                                ).then((dynamic value) {
                                  if (value != null) {
                                    DestinationAddress address = value;
                                    setState(() {
                                      _dropOffController.text = address.name!;
                                      destLatitude = double.parse(
                                          address.lat!.toStringAsFixed(6));
                                      destLongitude = double.parse(
                                          address.long!.toStringAsFixed(6));
                                    });
                                  }
                                });
//                                // generate a new token here
//                                final sessionToken = Uuid().v4();
//                                final Suggestion result = await showSearch(
//                                  context: context,
//                                  delegate: AddressSearch(sessionToken),
//                                );
//                                // This will change the text displayed in the TextField
//                                if (result != null) {
//                                  final placeDetails =
//                                      await PlaceApiProvider(sessionToken)
//                                          .getPlaceDetailFromId(result.placeId);
//                                  setState(() {
//                                    _dropOffController.text =
//                                        result.description;
//                                    destLongitude = placeDetails.longitude;
//                                    destLatitude = placeDetails.latitude;
//                                  });
//                                }
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.pin_drop_outlined,
                                  color: kSecondaryColor,
                                ),
                                hintText: "Drop-off Address",
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: kGreyColor),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    EdgeInsets.only(left: 8.0, top: 16.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding)),
              child: SectionTitle(
                sectionTitle: "Sender Information",
                subTitle: " ",
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding)),
              padding: EdgeInsets.all(
                getProportionateScreenWidth(kDefaultPadding),
              ),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                // borderRadius: BorderRadius.circular(
                //   getProportionateScreenWidth(kDefaultPadding),
                // ),
                // boxShadow: [kDefaultShadow],
              ),
              child: Column(
                children: [
                  TextField(
                    cursorColor: kSecondaryColor,
                    style: TextStyle(color: kBlackColor),
                    keyboardType: TextInputType.text,
                    onChanged: (val) {
                      senderUser = val;
                    },
                    decoration: InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kSecondaryColor),
                      ),
                      hintText: "$senderUser",
                    ),
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 4),
                  ),
                  TextField(
                    cursorColor: kSecondaryColor,
                    style: TextStyle(color: kBlackColor),
                    keyboardType: TextInputType.number,
                    maxLength: 9,
                    onChanged: (val) {
                      senderPhone = val;
                    },
                    decoration: InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kSecondaryColor),
                      ),
                      labelText:
                          "${Provider.of<ZMetaData>(context, listen: false).areaCode}$senderPhone",
                      labelStyle: TextStyle(
                        color: kGreyColor,
                      ),
                      prefix: Text(
                        "${Provider.of<ZMetaData>(context, listen: false).areaCode}",
                        style: TextStyle(color: kGreyColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding)),
              child: SectionTitle(
                sectionTitle: "Receiver Information",
                subTitle: " ",
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding)),
              padding: EdgeInsets.all(
                getProportionateScreenWidth(kDefaultPadding),
              ),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                // borderRadius: BorderRadius.circular(
                //   getProportionateScreenWidth(kDefaultPadding),
                // ),
                // boxShadow: [kDefaultShadow],
              ),
              child: Column(
                children: [
                  TextField(
                    cursorColor: kSecondaryColor,
                    style: TextStyle(color: kBlackColor),
                    keyboardType: TextInputType.number,
                    maxLength: 9,
                    onChanged: (val) {
                      receiverPhone = val;
                    },
                    decoration: InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kSecondaryColor),
                      ),
                      labelText: "Receiver Phone",
                      labelStyle: TextStyle(
                        color: kGreyColor,
                      ),
                      prefix: Text(
                          "${Provider.of<ZMetaData>(context, listen: false).areaCode}"),
                    ),
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 4),
                  ),
                  TextField(
                    cursorColor: kSecondaryColor,
                    style: TextStyle(color: kBlackColor),
                    keyboardType: TextInputType.text,
                    onChanged: (val) {
                      receiverName = val;
                    },
                    decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kSecondaryColor),
                        ),
                        labelText: "Receiver Name",
                        labelStyle: TextStyle(
                          color: kGreyColor,
                        )),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding)),
              child: SectionTitle(
                sectionTitle: "Description",
                subTitle: " ",
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding)),
              child: TextField(
                cursorColor: kSecondaryColor,
                style: TextStyle(color: kBlackColor),
                keyboardType: TextInputType.text,
                onChanged: (val) {
                  description = val;
                },
                decoration: InputDecoration(
                  hintText: "document, key, electronics, others...",
                  hintStyle: TextStyle(
                    color: kGreyColor,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding * 1.5),
            ),
            _loading
                ? SpinKitWave(
                    color: kSecondaryColor,
                    size: getProportionateScreenHeight(kDefaultPadding),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding)),
                    child: CustomButton(
                        title: "Continue",
                        press: () {
                          if (_controller.text != null &&
                              _controller.text.isNotEmpty &&
                              _dropOffController.text != null &&
                              _dropOffController.text.isNotEmpty &&
                              senderUser.isNotEmpty &&
                              senderPhone.isNotEmpty &&
                              senderPhone.length == 9 &&
                              receiverName.isNotEmpty &&
                              receiverPhone.isNotEmpty &&
                              receiverPhone.length == 9 &&
                              latitude != null &&
                              longitude != null &&
                              destLatitude != null &&
                              destLongitude != null) {
                            // print(
                            //     "Pickup: ${_controller.text}\nDropoff: ${_dropOffController.text}");
                            if (userData['user']['cart_id'] != null) {
                              print("Courier ready....");
//                              _clearCart();
                            }

                            _addCourierToCart();
                          } else {
                            if (_controller.text == null ||
                                _controller.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please enter pickup address!", true));
                            } else if (_dropOffController.text == null ||
                                _dropOffController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please enter destination address!",
                                      true));
                            } else if (senderPhone.isEmpty ||
                                senderUser.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please enter sender information!",
                                      true));
                            } else if (receiverPhone.isEmpty ||
                                receiverName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please enter receiver information!",
                                      true));
                            } else if (senderPhone.substring(0, 1) !=
                                    9.toString() ||
                                senderPhone.length != 9) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please enter a valid sender phone number",
                                      true));
                            } else if (receiverPhone.substring(0, 1) !=
                                    9.toString() ||
                                receiverPhone.length != 9) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please enter a valid receiver phone number",
                                      true));
                            }
                          }
                        },
                        color: kSecondaryColor),
                  ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding * 2),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> clearCart() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/clear_cart";
    Map data = {
      "user_id": userData['user']['_id'],
      "cart_id": userData['user']['cart_id'],
      "server_token": userData['user']['server_token'],
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
        Duration(seconds: 10),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      print(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> addCourierToCart() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_item_in_cart";
    Map data = {
      "user_id": userData['user']['_id'],
      "user_type": userData['user']['admin_type'],
      "store_id": "",
      "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
      "destination_addresses": [
        {
          "user_type": 7,
          "user_details": {
            "phone": receiverPhone,
            "name": receiverName,
            "email": "",
            "country_phone_code":
                Provider.of<ZMetaData>(context, listen: false).areaCode,
          },
          "note": description,
          "location": [destLatitude, destLongitude],
          "delivery_status": 0,
          "city": userData['user']['city'],
          "address_type": "destination",
          "address": _dropOffController.text,
        }
      ],
      "order_details": [],
      "pickup_addresses": [
        {
          "user_type": userData['user']['admin_type'],
          "user_details": {
            "phone": senderPhone,
            "name": senderUser,
            "country_phone_code":
                Provider.of<ZMetaData>(context, listen: false).areaCode,
          },
          "note": description,
          "location": [
            latitude,
            longitude,
          ],
          "delivery_status": 0,
          "city": userData['user']['city'],
          "address_type": "pickup",
          "address": _controller.text,
        }
      ],
      "total_cart_price": "0",
      "total_item_tax": 0,
      "cart_unique_token": userData['user']['server_token'],
      "server_token": userData['user']['server_token'],
      "delivery_type": 2
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
        Duration(seconds: 20),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Something went wrong!"),
              backgroundColor: kSecondaryColor,
            ),
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this._loading = false;
        orderDetail = data;
      });
      return json.decode(response.body);
    } catch (e) {
      print(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your internet connection is bad!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}
