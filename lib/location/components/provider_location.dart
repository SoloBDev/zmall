import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/size_config.dart';
import 'package:http/http.dart' as http;

class ProviderLocation extends StatefulWidget {
  static String routeName = '/provider_location';

  const ProviderLocation({
    @required this.destLat,
    @required this.destLong,
    @required this.providerId,
    @required this.providerPhone,
    @required this.providerImage,
    @required this.providerName,
    @required this.serverToken,
    @required this.userId,
  });

  final double? destLat;
  final double? destLong;
  final String? providerId;
  final String? providerPhone;
  final String? providerImage;
  final String? providerName;
  final String? serverToken;
  final String? userId;

  @override
  _ProviderLocationState createState() => _ProviderLocationState();
}

class _ProviderLocationState extends State<ProviderLocation> {
  late Marker marker;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  late GoogleMapController _controller;
  late CameraPosition initialLocation;
  late double initLat;
  late double initLong;
  var providerLocationData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialLocation = CameraPosition(
      target: LatLng(widget.destLat!, widget.destLong!),
      zoom: 14.4746,
    );
    loc(LatLng(widget.destLat!, widget.destLong!));
    getCurrentLocation();
  }

  Future<Uint8List> getMarker(bool isProvider) async {
    ByteData byteData = isProvider
        ? await DefaultAssetBundle.of(context).load("images/car_icon.png")
        : await DefaultAssetBundle.of(context).load("images/user_icon.png");
    return byteData.buffer.asUint8List();
  }

  void loc(LatLng a) async {
    Uint8List imageData = await getMarker(false);
    final Marker marker = Marker(
      markerId: MarkerId('user'),
      position: a,
      icon: BitmapDescriptor.fromBytes(imageData),
      draggable: false,
      zIndex: 1,
      flat: true,
      anchor: Offset(0.5, 0.5),
    );
    setState(() {
      markers[MarkerId('user')] = marker;
    });
  }

  void updateMarkerAndCircle(LatLng latLng, Uint8List imageData) async {
    this.setState(() {

      marker = Marker(
        markerId: MarkerId("provider"),
        position: latLng,
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: Offset(0.5, 0.5),
        icon: BitmapDescriptor.fromBytes(imageData),
      );
    });
    setState(() {
      markers[MarkerId('provider')] = marker;
    });
  }

  double? getZoomLevel(double radius) {
    double? zoomLevel = 11;
    if (radius > 0) {
      double radiusElevated = radius + radius / 2;
      double scale = radiusElevated / 500;
      zoomLevel = 13.4746 - math.log(scale) / math.log(2);
    }
    zoomLevel = num.parse(zoomLevel.toStringAsFixed(2)) as double?;
    return zoomLevel;
  }

  void getCurrentLocation() async {
    try {
      print("getting provider location....");
      var location = await getProviderLocation();
      if (location != null && location['success']) {
        Uint8List imageData = await getMarker(true);
        if (_controller != null) {
          double zoomLevel = await _controller.getZoomLevel();
          _controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(location['provider_location'][0],
                    location['provider_location'][1]),
                tilt: 0,
                zoom: zoomLevel,
              ),
            ),
          );
        }
        updateMarkerAndCircle(
            LatLng(location['provider_location'][0],
                location['provider_location'][1]),
            imageData);
      }
      await Future.delayed(Duration(seconds: 6), () => getCurrentLocation());
    } on PlatformException catch (e) {
      print(e);
      await Future.delayed(Duration(seconds: 10), () => getCurrentLocation());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Order Tracker",
          style: TextStyle(color: kBlackColor),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GoogleMap(
              rotateGesturesEnabled: false,
              compassEnabled: false,
              myLocationButtonEnabled: false,
              initialCameraPosition: initialLocation,
              markers: Set<Marker>.of(markers.values),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
          ),
          Container(
            color: kPrimaryColor,
            padding: EdgeInsets.symmetric(
              vertical: getProportionateScreenHeight(kDefaultPadding),
              horizontal: getProportionateScreenWidth(kDefaultPadding),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.providerName!,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text(
                      "+251 ${widget.providerPhone}",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.call,
                        color: kSecondaryColor,
                      ),
                      onPressed: () {
                        launch("tel:+251${widget.providerPhone}");
                      },
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: kSecondaryColor,
          child: Icon(
            Icons.delivery_dining,
            color: kPrimaryColor,
            size: getProportionateScreenWidth(kDefaultPadding),
          ),
          onPressed: () {
            getCurrentLocation();
          }),
    );
  }

  Future<dynamic> getProviderLocation() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_provider_location";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "provider_id": widget.providerId,
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
        providerLocationData = json.decode(response.body);
      });

      return json.decode(response.body);
    } catch (e) {
      print(e);

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
