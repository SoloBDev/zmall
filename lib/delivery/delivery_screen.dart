import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:fl_location/fl_location.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/checkout/checkout_screen.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/delivery/components/vehicle_container.dart';
import 'package:zmall/location/location_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/section_title.dart';

import 'components/location_container.dart';

class DeliveryScreen extends StatefulWidget {
  // Delivery location management screen
  static String routeName = '/delivery';

  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  DeliveryLocation? deliveryLocation;
  DestinationAddress? destinationAddress;
  String receiverName = "";
  String receiverPhone = "";
  bool isForOthers = false;

  Cart? cart;
  AliExpressCart? aliexpressCart;
  var userData;
  bool _loading = false;
  bool currSelected = false;
  bool selfPickup = false;
  int selected = -2;
  int selectedVehicle = -1;
  String vehicleId = "";
  var responseData;
  var vehicleList;

  double? latitude, longitude;
  LocationPermission _permissionStatus = LocationPermission.denied;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    // getLocation();
    getLocations();
  }

  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial
      setState(() {
        currSelected = false;
        selfPickup = false;
        selected = -2;
      });
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Location permission denied. Please enable location service from your phone's settings and try again",
          true,
          duration: 6));
      FlLocation.requestLocationPermission();
    }
  }

  void _getVehicleList() async {
    setState(() {
      _loading = true;
    });
    var data = await getVehicleList();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        vehicleList = data;
      });
    } else {
      setState(() {
        _loading = false;
      });
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

  void getLocation() async {
    var currentLocation = await FlLocation.getLocation();
    if (mounted) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
        cart!.destinationAddress!.lat = latitude;
        cart!.destinationAddress!.long = longitude;
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

  void getUser() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
    }
    await getCart();
    _doLocationTask();
    _getVehicleList();
  }

  void getLocations({bool returned = false}) async {
    var data = await Service.read('delivery');
    if (data != null) {
      setState(() {
        deliveryLocation = DeliveryLocation.fromJson(data);
        if (returned) {
          setState(() {
            currSelected = false;
            selfPickup = false;
            selected = deliveryLocation!.list!.length - 1;

            destinationAddress = deliveryLocation!.list![selected];
          });
        }
//        for (var i = 0; i < deliveryLocation.list.length; i++) {
//          print(deliveryLocation.list[i].name);
//        }
      });
    }
  }

  // void getLocation() async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   // await Future.delayed(Duration(seconds: 2));
  //   // _checkPermission();
  //   if (status == PermissionStatus.granted) {
  //     // setState(() {
  //     //   _loading = true;
  //     // });
  //     try {
  //       Position? position = await Service.getCurrentLocation();
  //       setState(() {
  //         _loading = false;
  //         currSelected = true;
  //         selfPickup = false;
  //         selected = -1;
  //         currPos = position!;
  //         cart.destinationAddress?.long = currPos.longitude;
  //         cart.destinationAddress?.lat = currPos.latitude;
  //       });
  //       await Service.save('cart', cart);
  //     } catch (e) {
  //       setState(() {
  //         _loading = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         Service.showMessage(
  //             "Please check your location settings and restart the App.", true),
  //       );
  //     }
  //   } else {
  //     Location location = Location();
  //     PermissionStatus permission = await location.requestPermission();
  //     setState(() {
  //       status = permission;
  //       getLocation();
  //     });
  //     if (status == PermissionStatus.granted) {
  //       getLocation();
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         Service.showMessage(
  //             "Please check your location settings and restart the App.", true),
  //       );
  //     }
  //   }
  //   setState(() {
  //     _loading = false;
  //   });
  // }

  addLocation() async {
    setState(() {
      _loading = true;
    });
    // await Future.delayed(Duration(seconds: 2));
    _doLocationTask();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          {
            return LocationScreen(
              currLat: Provider.of<ZMetaData>(context, listen: false).latitude,
              currLon: Provider.of<ZMetaData>(context, listen: false).longitude,
            );
          }
        },
      ),
    ).then((value) {
      getLocations(returned: true);
    });
    setState(() {
      _loading = false;
    });
  }

  Future<void> getCart() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('cart');
    var aliCart = await Service.read('aliexpressCart');
    if (data != null) {
      setState(() {
        cart = Cart.fromJson(data);
      });
    }
    if (aliCart != null) {
      setState(() {
        aliexpressCart = AliExpressCart.fromJson(aliCart);
      });
    }

    setState(() {
      _loading = false;
    });
  }

  void _clearCart(String cartId) async {
    setState(() {
      _loading = true;
    });

    var data = await clearCart(cartId);
    if (data != null && data['success']) {
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

  void _addToCart() async {
    setState(() {
      _loading = true;
    });
    var data = await addToCart();
    if (data != null && data['success']) {
      setState(() {
        userData['user']['cart_id'] = data['cart_id'];
      });
      await Service.save('user', userData);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return CheckoutScreen(
          isForOthers: isForOthers,
          receiverName: receiverName,
          receiverPhone: receiverPhone,
          vehicleId: vehicleId,
        );
      }));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "${errorCodes['${responseData['error_code']}']}!", true));
      await Future.delayed(Duration(seconds: 2));
      if (responseData['error_code'] != null &&
          responseData['error_code'] == 999) {
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
          Provider.of<ZLanguage>(context, listen: false).deliveryDetails,
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
        color: kPrimaryColor,
        progressIndicator: linearProgressIndicator,
        inAsyncCall: _loading,
        child: SingleChildScrollView(
          child: userData != null
              ? Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                  child: Column(
                    children: [
                      SectionTitle(
                        sectionTitle:
                            Provider.of<ZLanguage>(context, listen: false)
                                .deliveryDetails,
                        subTitle: " ",
                        press: () {},
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                          boxShadow: [boxShadow],
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: getProportionateScreenWidth(kDefaultPadding),
                            right: getProportionateScreenWidth(kDefaultPadding),
                            top: getProportionateScreenHeight(kDefaultPadding),
                            bottom: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          child: Column(
                            children: [
                              DetailsRow(
                                title: Provider.of<ZLanguage>(context,
                                        listen: false)
                                    .name,
                                subtitle: receiverName.isNotEmpty && isForOthers
                                    ? receiverName
                                    : "${userData['user']['first_name']} ${userData['user']['last_name']} ",
                              ),
                              Container(
                                width: double.infinity,
                                height: 0.5,
                                color: kGreyColor.withValues(alpha: 0.4),
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 3)),
                              DetailsRow(
                                title: Provider.of<ZLanguage>(context,
                                        listen: false)
                                    .phone,
                                subtitle: receiverPhone.isNotEmpty &&
                                        isForOthers
                                    ? "${Provider.of<ZMetaData>(context, listen: false).areaCode} $receiverPhone"
                                    : "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${userData['user']['phone']}",
                              ),
                              Container(
                                width: double.infinity,
                                height: 0.5,
                                color: kGreyColor.withValues(alpha: 0.4),
                              ),
                              SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 3)),
                              TextButton(
                                // style: ButtonStyle(
                                //   backgroundColor:
                                //       MaterialStateProperty.all(kSecondaryColor),
                                // ),
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
                                        padding:
                                            MediaQuery.of(context).viewInsets,
                                        child: Container(
                                          padding: EdgeInsets.all(
                                              getProportionateScreenHeight(
                                                  kDefaultPadding)),
                                          child: Wrap(
                                            children: <Widget>[
                                              Text(
                                                Provider.of<ZLanguage>(context,
                                                        listen: false)
                                                    .orderForOthers,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              SizedBox(
                                                height:
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding),
                                              ),
                                              TextField(
                                                style: TextStyle(
                                                    color: kBlackColor),
                                                keyboardType:
                                                    TextInputType.text,
                                                onChanged: (val) {
                                                  receiverName = val;
                                                },
                                                decoration: textFieldInputDecorator
                                                    .copyWith(
                                                        labelText: Provider.of<
                                                                    ZLanguage>(
                                                                context)
                                                            .name),
                                              ),
                                              SizedBox(
                                                height:
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding / 2),
                                              ),
                                              TextField(
                                                style: TextStyle(
                                                    color: kBlackColor),
                                                keyboardType:
                                                    TextInputType.number,
                                                maxLength: 9,
                                                onChanged: (val) {
                                                  receiverPhone = val;
                                                },
                                                decoration:
                                                    textFieldInputDecorator
                                                        .copyWith(
                                                  labelText:
                                                      Provider.of<ZLanguage>(
                                                              context,
                                                              listen: false)
                                                          .receiverPhone,
                                                  helperText:
                                                      Provider.of<ZLanguage>(
                                                              context,
                                                              listen: false)
                                                          .startPhone,
                                                  prefix: Text(
                                                      "${Provider.of<ZMetaData>(context, listen: false).areaCode}"),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    getProportionateScreenHeight(
                                                        kDefaultPadding / 2),
                                              ),
                                              CustomButton(
                                                title: Provider.of<ZLanguage>(
                                                        context,
                                                        listen: false)
                                                    .submit,
                                                color: kSecondaryColor,
                                                press: () async {
                                                  if (receiverPhone
                                                              .isNotEmpty &&
                                                          receiverName
                                                              .isNotEmpty &&
                                                          receiverPhone
                                                                  .substring(
                                                                      0, 1) ==
                                                              9.toString() ||
                                                      receiverPhone.length ==
                                                          9) {
                                                    setState(() {
                                                      isForOthers = true;
                                                      cart!.userName =
                                                          receiverName;
                                                      cart!.phone =
                                                          receiverPhone;
                                                      cart!.isForOthers =
                                                          isForOthers;
                                                    });

                                                    Navigator.of(context).pop();
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
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .changeDetails,
                                  style: TextStyle(
                                    color: kBlackColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      SectionTitle(
                        sectionTitle:
                            Provider.of<ZLanguage>(context, listen: false)
                                .deliveryOptions,
                        subTitle: " ",
                        press: () {},
                      ),
                      Container(
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 9),
                        child: vehicleList != null
                            ? ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) =>
                                    VehicleContainer(
                                      selected: selectedVehicle == index,
                                      imageUrl: selectedVehicle == index
                                          ? "images/${vehicleList['vehicles'][index]['vehicle_name'].toString().toLowerCase()}_selected.png"
                                          : "images/${vehicleList['vehicles'][index]['vehicle_name'].toString().toLowerCase()}.png",
                                      category: vehicleList['vehicles'][index]
                                          ['vehicle_name'],
                                      press: () {
                                        setState(() {
                                          if (selectedVehicle != index) {
                                            selectedVehicle = index;
                                            vehicleId = vehicleList['vehicles']
                                                [index]['_id'];
                                          } else {
                                            selectedVehicle = -1;
                                          }
                                        });
                                      },
                                    ),
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                              kDefaultPadding / 2),
                                        ),
                                itemCount: vehicleList['vehicles'] != null
                                    ? vehicleList['vehicles'].length
                                    : 0)
                            : SpinKitPianoWave(
                                color: kSecondaryColor,
                              ),
                      ),
                      SizedBox(
                          height:
                              getProportionateScreenHeight(kDefaultPadding)),
                      SectionTitle(
                        sectionTitle:
                            Provider.of<ZLanguage>(context, listen: false)
                                .locations,
                        subTitle: Provider.of<ZLanguage>(context, listen: false)
                            .addLocation,
                        press: () {
                          addLocation();
                        },
                      ),
                      LocationContainer(
                        title: Provider.of<ZLanguage>(context, listen: false)
                            .currentLocation,
                        note: Provider.of<ZLanguage>(context, listen: false)
                            .useCurrentLocation,
                        isSelected: currSelected,
                        press: () async {
                          setState(() {
                            currSelected = true;
                            selfPickup = false;
                            selected = -1;
                          });
                          _doLocationTask();

                          // getLocation();
                        },
                      ),
                      cart!.isLaundryService
                          ? Container()
                          : SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                      cart!.isLaundryService
                          ? Container()
                          : LocationContainer(
                              title:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .selfPickup,
                              note:
                                  Provider.of<ZLanguage>(context, listen: false)
                                      .userPickup,
                              isSelected: selfPickup,
                              press: () async {
                                setState(() {
                                  currSelected = false;
                                  selfPickup = true;
                                  selected = -1;
                                  selectedVehicle = 0;
                                  destinationAddress = DestinationAddress(
                                      name: Provider.of<ZLanguage>(context,
                                              listen: false)
                                          .userPickup,
                                      long: Provider.of<ZMetaData>(context,
                                              listen: false)
                                          .longitude,
                                      lat: Provider.of<ZMetaData>(context,
                                              listen: false)
                                          .latitude);
                                });

                                // getLocation();
                              },
                            ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      ListView.builder(
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
                              key: Key(deliveryLocation!.list![index].lat
                                  .toString()),
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
                                    selfPickup = false;
                                    selected = index;
                                    destinationAddress =
                                        deliveryLocation!.list![index];
                                  });
                                  _getVehicleList();
                                },
                                isSelected: index == selected,
                              ),
                            ),
                          );
                        },
                      ),
                      CustomButton(
                        title:
                            Provider.of<ZLanguage>(context, listen: false).cont,
                        press: () async {
                          if (selected != -2 && selectedVehicle != -1
                              // deliveryLocation == null ||
                              // deliveryLocation.list.length > selected
                              ) {
                            if (currSelected) {
                              destinationAddress = DestinationAddress(
                                  name: "Current location",
                                  long: Provider.of<ZMetaData>(context,
                                          listen: false)
                                      .longitude,
                                  lat: Provider.of<ZMetaData>(context,
                                          listen: false)
                                      .latitude);
                            } else if (selfPickup) {
                              destinationAddress = DestinationAddress(
                                  name: "User Pickup",
                                  long: Provider.of<ZMetaData>(context,
                                          listen: false)
                                      .longitude,
                                  lat: Provider.of<ZMetaData>(context,
                                          listen: false)
                                      .latitude);
                            }
                            if (destinationAddress != null) {
                              double storeToCustomerDistance =
                                  calculateDistance(
                                      cart!.storeLocation!.lat,
                                      cart!.storeLocation!.long,
                                      destinationAddress!.lat,
                                      destinationAddress!.long);

                              if (selectedVehicle != -1 &&
                                  vehicleList['vehicles'][selectedVehicle]
                                              ['vehicle_name']
                                          .toString()
                                          .toLowerCase() ==
                                      "bicycle" &&
                                  storeToCustomerDistance > 5 &&
                                  !selfPickup) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        Provider.of<ZLanguage>(context,
                                                listen: false)
                                            .farDeliveryLocation,
                                        true,
                                        duration: 5));
                              } else {
                                setState(() {
                                  cart!.destinationAddress = destinationAddress;
                                  Service.save('cart', cart);
                                  _loading = true;
                                });
                                var categoriesResponse =
                                    await CoreServices.getCategoryList(
                                        longitude: destinationAddress!.long!,
                                        latitude: destinationAddress!.lat!,
                                        countryCode: Provider.of<ZMetaData>(
                                                context,
                                                listen: false)
                                            .countryId!,
                                        countryName: Provider.of<ZMetaData>(
                                                context,
                                                listen: false)
                                            .country,
                                        context: context);

                                if (categoriesResponse != null &&
                                    categoriesResponse['success']) {
                                  _addToCart();
                                } else {
                                  if (categoriesResponse['error_code'] == 999) {
                                    await Service.saveBool('logged', false);
                                    await Service.remove('user');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        Service.showMessage(
                                            "${errorCodes['${categoriesResponse['error_code']}']}",
                                            true));
                                    Navigator.pushReplacementNamed(
                                        context, LoginScreen.routeName);
                                  } else if (categoriesResponse['error_code'] ==
                                      813) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        Service.showMessage(
                                            "Destination address cannot be outside of Addis Ababa",
                                            true,
                                            duration: 4));
                                    setState(() {
                                      _loading = false;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        Service.showMessage(
                                            "${errorCodes['${categoriesResponse['error_code']}']}",
                                            true));
                                  }
                                  setState(() {
                                    _loading = false;
                                  });
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please select a delivery address", true,
                                      duration: 4));
                            }

                            // _addToCart();
                          } else {
                            if (selectedVehicle == -1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please select a delivery option", true,
                                      duration: 4));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Please select a delivery address", true,
                                      duration: 4));
                            }
                          }
                        },
                        color: kSecondaryColor,
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                    ],
                  ),
                )
              : Container(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitWave(
                          color: kSecondaryColor,
                          size: getProportionateScreenHeight(kDefaultPadding),
                        ),
                        // Padding(
                        //   padding: EdgeInsets.only(
                        //     top:
                        //         getProportionateScreenHeight(kDefaultPadding / 2),
                        //   ),
                        //   child: Text("Locating your current location..."),
                        // ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
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
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Something went wrong! Check your internet and try again", true,
              duration: 3),
        );
      }

      return null;
    }
  }

  Future<dynamic> addToCart() async {
    var url;

    ///if the order is from aliexpress
    if (aliexpressCart != null &&
        aliexpressCart!.cart.storeId == cart!.storeId) {
      url =
          "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_item_in_cart_new_for_aliexpress";

      ///else, it is from local stores
    } else {
      url =
          "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_item_in_cart_new";
    }

    var body = json.encode(cart!.toJson());
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
      setState(() {
        this._loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage(
              "Something went wrong! Check your internet and try again", true,
              duration: 3),
        );
      }
      return null;
    }
  }

  Future<dynamic> getVehicleList() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/store/get_vehicle_list";

    Map data = {
      "store_id": "",
      "type": 7,
      "delivery_type": 1,
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
      "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
      "user_latitude": cart!.storeLocation!.lat,
      "user_longitude": cart!.storeLocation!.long,
      "store_latitude": cart!.destinationAddress!.lat,
      "store_longitude": cart!.destinationAddress!.long,
      "use_calculation": true,
      "is_laundry": cart!.isLaundryService,
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
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}
