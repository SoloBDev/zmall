import 'dart:typed_data';

import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/store/store_screen.dart';

class StoreMapView extends StatefulWidget {
  final isOpen;
  final stores;
  final categoryTitle;
  final storeDeliveryId;
  final cityId;
  final bool isFromProduct;

  const StoreMapView(
      {Key? key,
      required this.isOpen,
      required this.stores,
      required this.categoryTitle,
      required this.storeDeliveryId,
      required this.cityId,
      this.isFromProduct = false})
      : super(key: key);

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
          ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
              "Location service disabled. Please enable and try again", true));
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
        ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
            "Location permission denied. Please enable and try again", true));
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
/* 
import 'dart:typed_data';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/store/store_screen.dart';

class StoreMapView extends StatefulWidget {
  final isOpen;
  final stores;
  final categoryTitle;
  final storeDeliveryId;
  final cityId;
  final bool isFromProduct;

  const StoreMapView(
      {Key? key,
      required this.isOpen,
      required this.stores,
      required this.categoryTitle,
      required this.storeDeliveryId,
      required this.cityId,
      this.isFromProduct = false})
      : super(key: key);

  @override
  _StoreMapViewState createState() => _StoreMapViewState();
}

class _StoreMapViewState extends State<StoreMapView> {
  Marker? marker;
  double zoom = 11;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  GoogleMapController? _mapController;
  CameraPosition cameraPosition = CameraPosition(
    target: LatLng(9.011115, 38.758768),
    zoom: 14.4746,
  );
  late LatLng curLoc;

  bool _loading = false;

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
    super.initState();
    checkLocation();
  }

  setBoundsFromMarkers(Map<MarkerId, Marker> markerList) {
    LatLng a = markerList.values.first.position;
    LatLng b = markerList.values.last.position;
    setBounds(a, b);
  }

  setBounds(LatLng a, LatLng b) {
    LatLngBounds bound;
    if (b.latitude > a.latitude && b.longitude > a.longitude) {
      bound = LatLngBounds(southwest: a, northeast: b);
    } else if (b.longitude > a.longitude) {
      bound = LatLngBounds(
          southwest: LatLng(b.latitude, a.longitude),
          northeast: LatLng(a.latitude, b.longitude));
    } else if (b.latitude > a.latitude) {
      bound = LatLngBounds(
          southwest: LatLng(a.latitude, b.longitude),
          northeast: LatLng(b.latitude, a.longitude));
    } else {
      bound = LatLngBounds(southwest: b, northeast: a);
    }
    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
    _mapController!.animateCamera(u2).then((void v) {
      check(u2, _mapController!);
    });
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    _mapController!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  void checkLocation() async {
    setState(() {
      _loading = true;
    });
    _doLocationTask();
    double x = await _mapController!.getZoomLevel();
    setState(() {
      zoom = x;
    });

    loc(LatLng(Provider.of<ZMetaData>(context, listen: false).latitude,
        Provider.of<ZMetaData>(context, listen: false).longitude));
    // updateLocation(position.latitude, position.longitude);

    setState(() {
      _loading = false;
    });
  }

  void loc(LatLng a) async {
    Map<MarkerId, Marker> markers_list = <MarkerId, Marker>{};
    // Uint8List imageData = await getMarker(false);
    Uint8List storeImageData = await getMarker(true);
    // final Marker marker = Marker(
    //   markerId: MarkerId('user'),
    //   position: a,
    //   icon: BitmapDescriptor.fromBytes(imageData),
    //   draggable: false,
    //   zIndex: 1,
    //   flat: true,
    //   anchor: Offset(0.5, 0.5),
    // );
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(a.latitude, a.longitude),
    );
    // markers_list[MarkerId('user')] = marker;

    for (int i = 0; i < widget.stores.length; i++) {
      final Marker storeMarker = Marker(
        markerId: MarkerId(widget.stores[i]['_id']),
        position: LatLng(
            double.parse(widget.stores[i]['location'][0].toString()),
            double.parse(widget.stores[i]['location'][1].toString())),
        icon: BitmapDescriptor.fromBytes(storeImageData),
        infoWindow: InfoWindow(
            title: widget.stores[i]['name'],
            snippet: widget.isOpen[i] ? "Open" : "Closed",
            onTap: () {
              markerOnTap(widget.stores[i], widget.isOpen[i]);
            }),
        draggable: false,
        zIndex: 1,
        flat: true,
        anchor: Offset(0.5, 0.5),
      );
      markers_list[MarkerId(widget.stores[i]['_id'])] = storeMarker;
    }

    setState(() {
      markers = markers_list;
      cameraPosition = cameraPosition;
      curLoc = a;
    });
  }

  void markerOnTap(var store, bool isOpen) {
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
                  latitude: curLoc.latitude,
                  longitude: curLoc.longitude,
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
                  latitude: curLoc.latitude,
                  longitude: curLoc.longitude,
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
                latitude: curLoc.latitude,
                longitude: curLoc.longitude,
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

  Future<Uint8List> getMarker(bool isStore) async {
    ByteData byteData = isStore
        ? await DefaultAssetBundle.of(context).load("images/location_icon.png")
        : await DefaultAssetBundle.of(context).load("images/user_icon.png");
    return byteData.buffer.asUint8List();
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
                    Provider.of<ZMetaData>(context, listen: false).longitude),
                zoom: 14.4746,
              ),
              markers: Set<Marker>.of(markers.values),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              // onCameraMove: ((_position) {
              //   loc(LatLng(
              //       _position.target.latitude, _position.target.longitude));
              //   setState(() {});
              // }),
            ),
          ],
        ),
      ),
    );
  }
} */
