import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/checkout/checkout_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/delivery/components/location_container.dart';
import 'package:zmall/global/checkout/global_checkout.dart';
import 'package:zmall/location/location_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';
import 'package:zmall/widgets/section_title.dart';

class GlobalDelivery extends StatefulWidget {
  // Delivery location management screen
  static String routeName = '/global_delivery';
  @override
  _GlobalDeliveryState createState() => _GlobalDeliveryState();
}

class _GlobalDeliveryState extends State<GlobalDelivery> {
  DeliveryLocation? deliveryLocation;
  DestinationAddress? destinationAddress;
  String receiverName = "";
  String receiverPhone = "";
  bool isForOthers = false;
  bool receiverError = false;
  var tempPhone;
  var tempName;

  String senderName = "";
  String senderPhone = "";
  String senderEmail = "";

  late AbroadCart cart;
  late AbroadData abroadData;
  var userData;
  bool _loading = false;
  bool currSelected = false;
  int selected = -1;
  var responseData;

  final FirebaseAuth auth = FirebaseAuth.instance;

  Map<String, dynamic> receiverInfo = {};
  Map<String, dynamic> locationInfo = {};
  double? latitude, longitude;
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
    getUser();
    _doLocationTask();
    getLocations();
    getCart();
  }

  void initUser() {
    final User? user = auth.currentUser!;

    if (user != null) {
      setState(() {
        senderPhone = user.phoneNumber!;
        senderName = "";
        senderEmail = "";
        abroadData = AbroadData(
          abroadPhone: senderPhone,
          abroadName: senderName,
          abroadEmail: senderEmail,
        );
      });
      Service.save("abroad_user", abroadData.toJson());
    }
  }

  void getUser() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('abroad_user');
    if (data != null) {
      setState(() {
        abroadData = AbroadData.fromJson(data);
        senderName = abroadData.abroadName!;
        senderPhone = abroadData.abroadPhone!;
      });
    } else {
      initUser();
    }
    setState(() {
      _loading = false;
    });
  }

  void getLocations() async {
    var data = await Service.read('delivery');
    if (data != null) {
      setState(() {
        deliveryLocation = DeliveryLocation.fromJson(data);
        print("Found ${deliveryLocation!.list!.length} locations");
//        for (var i = 0; i < deliveryLocation.list.length; i++) {
//          print(deliveryLocation.list[i].name);
//        }
      });
    }
  }

  void getCart() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('abroad_cart');
    if (data != null) {
      setState(() {
        cart = AbroadCart.fromJson(data);
      });
    }
    setState(() {
      _loading = false;
    });
  }

  // void _clearCart(String cartId) async {
  //   setState(() {
  //     _loading = true;
  //   });
  //
  //   var data = await clearCart(cartId);
  //   if (data != null && data['success']) {
  //     print("Cart cleared");
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
  //     await Future.delayed(Duration(seconds: 2));
  //     if (data['error_code'] == 999) {
  //       await Service.saveBool('logged', false);
  //       await Service.remove('user');
  //       Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  //     }
  //   }
  // }

  void _addToCart() async {
    setState(() {
      _loading = true;
    });
    print("Adding to cart....");
    var data = await addToCart();
    print(data);
    print("++++++++++++++++++++++++++++++++++");
    if (responseData != null && responseData['success']) {
      setState(() {
        cart.userId = responseData['order_payment']['user_id'];
        cart.serverToken = responseData['server_token'];
      });
      print("Cart ID : ${responseData['order_payment']['cart_id']}");
      print("Server Token : ${responseData['server_token']}");
      print("User ID : \t ${cart.userId}");
      print("++++++++++++++++++++++++++++++++++");
      await Service.save('abroad_cart', cart);
      await Service.save('cart_id', responseData['order_payment']['cart_id']);
      // await FirebaseCoreServices.addDataToUserProfileCollection(
      //     FirebaseAuth.instance.currentUser.uid, receiverInfo, "receiver");
      // await FirebaseCoreServices.addDataToUserProfileCollection(
      //     FirebaseAuth.instance.currentUser.uid, locationInfo, "locations");
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return GlobalCheckout(
          isForOthers: isForOthers,
          receiverName: receiverName,
          receiverPhone: receiverPhone,
        );
      }));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${errorCodes['${responseData['error_code']}']}!", true));
      await Future.delayed(Duration(seconds: 2));
      if (responseData['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        title: Text(
          "Delivery Details",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
          color: kPrimaryColor,
          progressIndicator: linearProgressIndicator,
          inAsyncCall: _loading,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding),
                  vertical: getProportionateScreenHeight(kDefaultPadding / 2)),
              child: Column(
                children: [
                  CustomTag(color: kSecondaryColor, text: "Sender Details"),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding),
                      ),
                      // boxShadow: [boxShadow],
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: getProportionateScreenWidth(kDefaultPadding),
                        right: getProportionateScreenWidth(kDefaultPadding),
                        top: getProportionateScreenHeight(kDefaultPadding),
                        bottom:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      child: Column(
                        children: [
                          DetailsRow(
                              title: "Name",
                              subtitle:
                                  senderName.isNotEmpty
                                      ? senderName
                                      : "Sender Name"),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 3)),
                          DetailsRow(
                              title: "Phone",
                              subtitle:
                                 senderPhone.isNotEmpty
                                      ? senderPhone
                                      : "Sender Phone"),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 3)),
                          TextButton(
//                          style: ButtonStyle(
//                            backgroundColor:
//                                MaterialStateProperty.all(kSecondaryColor),
//                          ),
                            onPressed: () {
                              showModalBottomSheet<void>(
                                isScrollControlled: true,
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30.0),
                                      topRight: Radius.circular(30.0)),
                                ),
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: MediaQuery.of(context).viewInsets,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                          getProportionateScreenHeight(
                                              kDefaultPadding)),
                                      child: Wrap(
                                        children: <Widget>[
                                          Text(
                                            "Sender Information",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Container(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding),
                                          ),
                                          TextField(
                                            style:
                                                TextStyle(color: kBlackColor),
                                            keyboardType: TextInputType.text,
                                            onChanged: (val) {
                                              senderName = val;
                                            },
                                            decoration: textFieldInputDecorator
                                                .copyWith(
                                                    labelText:

                                                                senderName
                                                                    .isNotEmpty
                                                            ? senderName
                                                            : "Sender Name"),
                                          ),
                                          Container(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 2),
                                          ),
                                          CustomButton(
                                            title: "Submit",
                                            color: kSecondaryColor,
                                            press: () async {
                                              if (
                                                  senderName.isNotEmpty &&

                                                  senderPhone.isNotEmpty) {
                                                setState(() {
                                                  abroadData.abroadName =
                                                      senderName;
                                                });
                                                // print(abroadData.toJson());
                                                Service.save("abroad_user",
                                                    abroadData.toJson());
                                                Navigator.of(context).pop();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Text(
                              receiverName.isNotEmpty &&
                                      receiverPhone.isNotEmpty
                                  ? "Change Details"
                                  : "Add Details",
                              style: TextStyle(
                                color: kBlackColor,
                                decoration: TextDecoration.underline,
                                fontSize: getProportionateScreenWidth(
                                    kDefaultPadding * .8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding)),
                  CustomTag(color: kSecondaryColor, text: "Receiver Details"),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding),
                      ),
                      // boxShadow: [boxShadow],
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: getProportionateScreenWidth(kDefaultPadding),
                        right: getProportionateScreenWidth(kDefaultPadding),
                        top: getProportionateScreenHeight(kDefaultPadding),
                        bottom:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      child: Column(
                        children: [
                          DetailsRow(
                              title: "Name",
                              subtitle: receiverName.isNotEmpty
                                  ? receiverName
                                  : "Receiver Name"),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 3)),
                          DetailsRow(
                              title: "Phone",
                              subtitle: receiverPhone.isNotEmpty
                                  ? "+251 $receiverPhone"
                                  : "Receiver Phone"),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 3)),
                          TextButton(
//
                            onPressed: () {
                              showModalBottomSheet<void>(
                                isScrollControlled: true,
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30.0),
                                      topRight: Radius.circular(30.0)),
                                ),
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: MediaQuery.of(context).viewInsets,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                          getProportionateScreenHeight(
                                              kDefaultPadding)),
                                      child: Wrap(
                                        children: <Widget>[
                                          Text(
                                            "Order For Others",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Container(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding),
                                          ),
                                          TextField(
                                            style:
                                                TextStyle(color: kBlackColor),
                                            keyboardType: TextInputType.text,
                                            onChanged: (val) {
                                              tempName = val;
                                            },
                                            decoration: textFieldInputDecorator
                                                .copyWith(
                                                    labelText:
                                                        receiverName.isNotEmpty
                                                            ? receiverName
                                                            : "Receiver Name"),
                                          ),
                                          Container(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding),
                                          ),
                                          TextField(
                                            style:
                                                TextStyle(color: kBlackColor),
                                            keyboardType: TextInputType.number,
                                            maxLength: 9,
                                            onChanged: (val) {
                                              tempPhone = val;
                                              print(tempPhone.length);
                                            },
                                            decoration: textFieldInputDecorator
                                                .copyWith(
                                              labelText:
                                                  receiverPhone.isNotEmpty
                                                      ? receiverPhone
                                                      : "Receiver phone number",
                                              helperText:
                                                  "Start phone number with 9..",
                                              prefix: Text("+251"),
                                            ),
                                          ),
                                          Container(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 2),
                                          ),
                                          receiverError
                                              ? Text(
                                                  "Invalid! Please make sure all fields are filled.",
                                                  style: TextStyle(
                                                      color: kSecondaryColor),
                                                )
                                              : Container(),
                                          CustomButton(
                                            title: "Submit",
                                            color: kSecondaryColor,
                                            press: () async {
                                              if (tempPhone.isNotEmpty &&
                                                  tempName.isNotEmpty &&
                                                  tempPhone.substring(0, 1) ==
                                                      9.toString() &&
                                                  tempPhone.length == 9) {
                                                setState(() {
                                                  receiverPhone = tempPhone;
                                                  receiverName = tempName;
                                                  isForOthers = true;
                                                  cart.userName = receiverName;
                                                  cart.phone = receiverPhone;
                                                  cart.isForOthers =
                                                      isForOthers;
                                                });
                                                setState(() {
                                                  receiverError = false;
                                                });
                                                receiverInfo['name'] = tempName;
                                                receiverInfo['phone'] =
                                                    tempPhone;
                                                Navigator.of(context).pop();
                                              } else {
                                                setState(() {
                                                  receiverError = true;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ).whenComplete(() {
                                setState(() {});
                              });
                            },
                            child: Text(
                              receiverName.isNotEmpty &&
                                      receiverPhone.isNotEmpty
                                  ? "Change Details"
                                  : "Add Details",
                              style: TextStyle(
                                color: kBlackColor,
                                decoration: TextDecoration.underline,
                                fontSize: getProportionateScreenWidth(
                                    kDefaultPadding * .8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding)),
                  SectionTitle(
                    sectionTitle: "Delivery Locations",
                    subTitle: "",
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            {
                              return LocationScreen(
                                currLat: 9.004188,
                                currLon: 38.768154,
                              );
                            }
                          },
                        ),
                      ).then((value) {
                        getLocations();
                      });
                    },
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                  deliveryLocation != null && deliveryLocation!.list!.length > 0
                      ? Container()
                      : Center(
                          child: Text(
                            "There aren't any saved locations.\n Please add new delivery location!",
                            textAlign: TextAlign.center,
                          ),
                        ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                  Container(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: deliveryLocation != null &&
                              deliveryLocation!.list!.length > 0
                          ? deliveryLocation!.list!.length
                          : 0,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          child: Dismissible(
                            background: Container(
                              color: kSecondaryColor,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: kPrimaryColor,
                                    size: getProportionateScreenWidth(
                                      kDefaultPadding,
                                    ),
                                  ),
                                  SizedBox(
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding / 2),
                                  ),
                                ],
                              ),
                            ),
                            key: Key(
                                deliveryLocation!.list![index].lat.toString()),
                            onDismissed: (direction) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      '${deliveryLocation!.list![index].name} dismissed')));
                              setState(() {
                                deliveryLocation!.list!.removeAt(index);
                                Service.save(
                                    'delivery', deliveryLocation!.toJson());
                              });
                            },
                            child: LocationContainer(
                              title: deliveryLocation!.list![index].name!
                                  .split(",")[0],
                              note: deliveryLocation!.list![index].note,
                              press: () {
                                setState(() {
                                  currSelected = false;
                                  selected = index;
                                  destinationAddress =
                                      deliveryLocation!.list![index];
                                  destinationAddress!.name = destinationAddress!
                                      .name!;
                                      // .replaceAll(RegExp(r'[^\w\s]+'), '')
                                      // .replaceAll(RegExp('\\s+'), ' ');
                                  destinationAddress!.note = destinationAddress!
                                      .note!;
                                      // .replaceAll(RegExp(r'[^\w\s]+'), '')
                                      // .replaceAll(RegExp('\\s+'), ' ');
                                });
                              },
                              isSelected: index == selected,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  CustomButton(
                    title: "Continue",
                    press: () async {
                      setState(() {
                        _loading = true;
                      });

                      if (destinationAddress != null &&
                          receiverPhone.isNotEmpty &&
                          receiverName.isNotEmpty &&
                          senderName.isNotEmpty) {
                        setState(() {
                          cart.destinationAddress = destinationAddress;
                          cart.abroadData = abroadData;
                          Service.save('abroad_cart', cart);
                        });
                        print(cart.destinationAddress!.toJson());
                        print("Checking if location is in Addis");
                        var categoriesResponse =
                            await CoreServices.getCategoryList(
                                destinationAddress!.long!,
                                destinationAddress!.lat!,
                                "5b3f76f2022985030cd3a437",
                                "Ethiopia",
                                context);

                        if (categoriesResponse != null &&
                            categoriesResponse['success']) {
                          // receiverInfo['location'] = GeoPoint(
                          //     destinationAddress.lat, destinationAddress.long);
                          // receiverInfo['location_name'] =
                          //     destinationAddress.name;
                          // locationInfo['location'] = GeoPoint(
                          //     destinationAddress.lat, destinationAddress.long);
                          // locationInfo['name'] = destinationAddress.name;
                          _addToCart();
                        } else {
                          if (categoriesResponse['error_code'] == 813) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                Service.showMessage(
                                    "Destination address cannot be outside of Addis Ababa",
                                    true,
                                    duration: 4));
                          } else {
                            print(categoriesResponse['error_code']);
                            ScaffoldMessenger.of(context).showSnackBar(
                                Service.showMessage(
                                    "${errorCodes['${categoriesResponse['error_code']}']}",
                                    true));
                          }
                        }
                      } else {
                        if (senderName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please add sender's name", false,
                                  duration: 4));
                        } else if (receiverName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please add receiver's name", false,
                                  duration: 4));
                        } else if (receiverPhone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please add receivers phone number", false,
                                  duration: 4));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please select a delivery address", false,
                                  duration: 4));
                        }
                      }
                      setState(() {
                        _loading = false;
                      });
                    },
                    color: kSecondaryColor,
                  ),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                ],
              ),
            ),
          )),
    );
  }

  Future<dynamic> clearCart(String cartId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/clear_cart";
    Map data = {
      "user_id": userData['user']['_id'],
      "cart_id": cartId,
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
        this.responseData = json.decode(response.body);
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

  Future<dynamic> addToCart() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/create_cart_and_invoice_for_abroad";
    cart.userId = "";
    var body = json.encode(cart.toJson());
    print(body);
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
        this.responseData = json.decode(response.body);
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
