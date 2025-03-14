import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/delivery/components/location_container.dart';
import 'package:zmall/location/location_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/section_title.dart';

class LocationsList extends StatefulWidget {
  const LocationsList({required this.title});

  final String title;

  @override
  _LocationsListState createState() => _LocationsListState();
}

class _LocationsListState extends State<LocationsList> {
  bool _loading = false;
  var userData;
  DeliveryLocation? deliveryLocation;
  DestinationAddress? destinationAddress;


  late Cart cart;
  bool currSelected = false;
  int selected = -2;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getUser();
    // getLocation();
    getLocations();
  }

  void getUser() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
        print(userData);
      });
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
      });
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop(DestinationAddress());
          },
        ),
      ),
      body: ModalProgressHUD(
          color: kPrimaryColor,
          progressIndicator: linearProgressIndicator,
          inAsyncCall: _loading,
          child: !_loading
              ? Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                  child: Column(
                    children: [
                      SectionTitle(
                        sectionTitle: "Locations",
                        subTitle: "",
                        press: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                {
                                  return LocationScreen(
                                    currLat: Provider.of<ZMetaData>(context,
                                            listen: false)
                                        .latitude,
                                    currLon: Provider.of<ZMetaData>(context,
                                            listen: false)
                                        .longitude,
                                  );
                                }
                              },
                            ),
                          ).then((value) => {getLocations()});
                        },
                      ),
                      LocationContainer(
                        title: "Current Location",
                        note: "Use current location",
                        isSelected: currSelected,
                        press: () {
                          setState(() {
                            currSelected = true;
                            selected = -1;
                          });
                          _doLocationTask();

                        },
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: deliveryLocation != null &&
                                  deliveryLocation!.list!.length > 0
                              ? deliveryLocation!.list!.length
                              : 0,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: getProportionateScreenHeight(
                                      kDefaultPadding / 2)),
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
                                  // Remove the item from the data source.
                                  setState(() {
                                    deliveryLocation!.list!.removeAt(index);
                                    Service.save(
                                        'delivery', deliveryLocation!.toJson());
                                  });

                                  // Then show a snackbar.
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(Service.showMessage(
                                    '${deliveryLocation!.list?[index].name} deleted',
                                    true,
                                  ));
                                },
                                child: LocationContainer(
                                  title: deliveryLocation!.list![index].name!
                                      .split(",")[0],
                                  note: deliveryLocation!.list?[index].note,
                                  press: () {
                                    setState(() {
                                      currSelected = false;
                                      selected = index;
                                      destinationAddress =
                                          deliveryLocation!.list![index];
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
                        title: "Select",
                        press: () {
                          if (currSelected) {
                            destinationAddress = DestinationAddress(
                                name: "Current location",
                                long: Provider.of<ZMetaData>(context, listen: false).longitude,
                                lat: Provider.of<ZMetaData>(context, listen: false).latitude);
                          }
                          print(destinationAddress!.toJson());
                          Navigator.of(context).pop(destinationAddress);
                        },
                        color: kSecondaryColor,
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitWave(
                      color: kSecondaryColor,
                      size: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    Text("Loading...")
                  ],
                )),
    );
  }
}
