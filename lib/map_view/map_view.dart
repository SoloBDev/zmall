import 'dart:typed_data';

import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/store/store_screen.dart';

class StoreMapView extends StatefulWidget {
  final isOpen;
  final stores;
  final categoryTitle;
  final storeDeliveryId;
  final cityId;
  final bool isFromProduct;

  const StoreMapView({
    super.key,
    required this.isOpen,
    required this.stores,
    required this.categoryTitle,
    required this.storeDeliveryId,
    required this.cityId,
    this.isFromProduct = false,
  });

  @override
  _StoreMapViewState createState() => _StoreMapViewState();
}

class _StoreMapViewState extends State<StoreMapView> {
  LocationPermission _permissionStatus = LocationPermission.denied;
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Logger logger = Logger();
  bool _loading = false;
  double? latitude, longitude;

  @override
  void initState() {
    super.initState();
    checkLocation();
  }

  void checkLocation() async {
    setState(() {
      _loading = true;
    });
    _doLocationTask();
  }

  void _doLocationTask() async {
    LocationPermission _permissionStatus =
        await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.whileInUse ||
        _permissionStatus == LocationPermission.always) {
      if (await FlLocation.isLocationServicesEnabled) {
        getLocation();
        _addMarkers();
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            _loading = false;
          });
        });
      } else {
        LocationPermission serviceStatus =
            await FlLocation.requestLocationPermission();
        if (serviceStatus == LocationPermission.always ||
            serviceStatus == LocationPermission.whileInUse) {
          getLocation();
          _addMarkers();
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              _loading = false;
            });
          });
        } else {
          Service.showMessage(
            context: context,
            title: "Location service disabled. Please enable and try again",
            error: true,
          );
        }
      }
    } else {
      //request location permission
      _permissionStatus = await FlLocation.checkLocationPermission();
      if (_permissionStatus == LocationPermission.always ||
          _permissionStatus == LocationPermission.whileInUse) {
        // Location permission granted, continue with location-related tasks
        getLocation();
        _addMarkers();
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            _loading = false;
          });
        });
      } else {
        // Handle permission denial
        Service.showMessage(
          context: context,
          title: "Location permission denied. Please enable and try again",
          error: true,
        );
        FlLocation.requestLocationPermission();
      }
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

  Future<Uint8List> getMarker(bool isStore) async {
    ByteData byteData = isStore
        ? await DefaultAssetBundle.of(context).load("images/location_icon.png")
        : await DefaultAssetBundle.of(context).load("images/user_icon.png");
    return byteData.buffer.asUint8List();
  }

  void _addMarkers() async {
    for (int i = 0; i < widget.stores.length; i++) {
      Uint8List storeImageData = await getMarker(true);

      final Marker marker = Marker(
        markerId: MarkerId(widget.stores[i]['_id']),
        position: LatLng(
            double.parse(widget.stores[i]['location'][0].toString()),
            double.parse(widget.stores[i]['location'][1].toString())),
        icon: BitmapDescriptor.fromBytes(storeImageData),
        infoWindow: InfoWindow(
            title: widget.stores[i]['name'],
            snippet: widget.isOpen[i] ? "Open" : "Closed",
            onTap: () {
              _onMarkerTap(widget.stores[i], widget.isOpen[i]);
            }),
      );
      setState(() {
        _markers.add(marker);
      });
    }
  }

  void _onMarkerTap(var store, bool isOpen) {
    if (widget.isFromProduct) {
      Navigator.of(context).pop();
    } else {
      try {
        if (store['store_count'] > 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return StoreScreen(
                  cityId: widget.cityId,
                  storeDeliveryId: widget.storeDeliveryId,
                  category: widget.categoryTitle,
                  latitude: store["location"][0],
                  longitude: store["location"][1],
                  isStore: true,
                  companyId: store['company_id'],
                );
              },
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ProductScreen(
                  latitude: store["location"][0],
                  longitude: store["location"][1],
                  store: store,
                  location: store["location"],
                  isOpen: isOpen,
                );
              },
            ),
          );
        }
      } catch (e) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ProductScreen(
                latitude: store["location"][0],
                longitude: store["location"][1],
                store: store,
                location: store["location"],
                isOpen: isOpen,
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle['delivery_name'],
            style: TextStyle(color: kBlackColor)),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        color: kPrimaryColor,
        progressIndicator: linearProgressIndicator,
        child: Stack(
          children: [
            GoogleMap(
              myLocationEnabled: true,
              rotateGesturesEnabled: true,
              compassEnabled: true,
              myLocationButtonEnabled: true,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  Provider.of<ZMetaData>(context, listen: false).latitude,
                  Provider.of<ZMetaData>(context, listen: false).longitude,
                ), //Current user position
                zoom: 14.4746,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ],
        ),
      ),
    );
  }
}
