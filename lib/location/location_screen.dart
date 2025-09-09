import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/location/components/network_utility.dart';
import 'package:zmall/models/auto_complete_prediction.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/place_auto_complete_response.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'components/place_service.dart';

class LocationScreen extends StatefulWidget {
  static String routeName = '/location';

  @override
  _LocationScreenState createState() => _LocationScreenState();

  const LocationScreen({
    @required this.currLat,
    @required this.currLon,
  });

  final double? currLon, currLat;
}

class _LocationScreenState extends State<LocationScreen> {
  DeliveryLocation? deliveryLocation;
  String locationName = '', locationNote = 'Location';
  double? latitude, longitude;

//  MapController _mapController;
//  LatLng _center = LatLng(9.010618, 38.761257);
  String map1 =
      "https://api.mapbox.com/styles/v1/josisoll/cknrk875y0rtt17o1xjd7lhdo/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoiam9zaXNvbGwiLCJhIjoiY2tucmhoZ2R6MG9rZjMwcGZqZHpqaTllNyJ9.HTS3eDPekYqVn-7skpTf_g";
  String map2 =
      "https://api.mapbox.com/styles/v1/josisoll/cknrj3n140ts017qij869ijne/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoiam9zaXNvbGwiLCJhIjoiY2tucmhoZ2R6MG9rZjMwcGZqZHpqaTllNyJ9.HTS3eDPekYqVn-7skpTf_g";

  Marker? marker;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  GoogleMapController? _mapController;
  CameraPosition? cameraPosition;
  bool cameraMoving = false;
  bool _loading = false;
  bool selected = true;
  final client = Client();
  List<AutocompletePrediction> placePrediction = [];

  final apiKey = Platform.isAndroid ? deviceKey : iosKey;

  bool isAM() {
    if (DateTime.now().hour > 6 && DateTime.now().hour <= 18) {
      return true;
    }
    return false;
  }

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getLocations() async {
    var data = await Service.read('delivery');
    if (data != null) {
      setState(() {
        deliveryLocation = DeliveryLocation.fromJson(data);
      });
    }
  }

  void placeAutocomplete(String query) async {
    // String sessionToken = Uuid().v4();
    Uri uri =
        Uri.https("maps.googleapis.com", 'maps/api/place/autocomplete/json', {
      "input": query,
      "location": "9.010618,38.761257",
      "key": apiKey,
      // "sessiontoken" : sessionToken,
      "radius": "10000"
    });
    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutocompleteResponse result =
          PlaceAutocompleteResponse.parseAutocompleteResult(response);
      if (result.predictions != null) {
        setState(() {
          placePrediction = result.predictions!;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getLocations();

    loc(LatLng(widget.currLat!, widget.currLon!));
  }

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("images/user_icon.png");
    return byteData.buffer.asUint8List();
  }

  void loc(LatLng a) async {
    setState(() {
      cameraMoving = true;
      cameraPosition = CameraPosition(
        target: LatLng(a.latitude, a.longitude),
        zoom: 17.3495,
      );
    });

    Uint8List imageData = await getMarker();
    final Marker marker = Marker(
      flat: true,
      position: a,
      zIndexInt: 1,
      draggable: false,
      anchor: Offset(0.5, 0.5),
      markerId: MarkerId('user'),
      icon: BitmapDescriptor.bytes(imageData),
    );
    setState(() {
      markers[MarkerId('user')] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Location",
          style: TextStyle(color: kBlackColor),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: getProportionateScreenHeight(kDefaultPadding / 2),
            horizontal: getProportionateScreenHeight(kDefaultPadding),
          ),
          decoration: BoxDecoration(
              color: kPrimaryColor,
              border: Border(top: BorderSide(color: kWhiteColor)),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kDefaultPadding),
                  topRight: Radius.circular(kDefaultPadding))),
          child: CustomButton(
            isLoading: _loading,
            color: kSecondaryColor,
            title: _controller.text.isEmpty
                // || cameraMoving
                ? "Pin On Map"
                : "Add Location",
            press: () async {
              if (_controller.text.isNotEmpty) {
                DestinationAddress _destinationAddress = DestinationAddress(
                  name: _controller.text,
                  long: cameraPosition!.target.longitude,
                  lat: cameraPosition!.target.latitude,
                  note: locationNote,
                );
                if (deliveryLocation != null) {
                  deliveryLocation!.list!.add(_destinationAddress);
                  Service.save('delivery', deliveryLocation!.toJson());
                } else {
                  deliveryLocation = DeliveryLocation(
                    list: [_destinationAddress],
                  );

                  Service.save('delivery', deliveryLocation!.toJson());

                  Service.showMessage(
                      context: context, title: "Location added!", error: false);
                }
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _loading = true;
                });
                //
                if (cameraPosition!.target.longitude != null &&
                    cameraPosition!.target.latitude != null) {
                  final sessionToken = Uuid().v4();
                  final location = await PlaceApiProvider(sessionToken)
                      .getPlaceDetailFromLatLng(cameraPosition!.target.latitude,
                          cameraPosition!.target.longitude);
                  setState(() {
                    _controller.text = location;
                    _loading = false;
                    longitude = cameraPosition!.target.longitude;
                    latitude = cameraPosition!.target.latitude;
                    loc(LatLng(latitude!, longitude!));
                  });
                }
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            children: [
              CustomTextField(
                controller: _controller,
                keyboardType: TextInputType.text,
                style: TextStyle(color: kBlackColor),
                onChanged: (value) {
                  setState(() {
                    selected = false;
                  });
                  placeAutocomplete(value);
                },
                // readOnly: true,
                // onTap: () async {
                //   // generate a new token here
                //   final sessionToken = Uuid().v4();
                //   final Suggestion? result = await showSearch(
                //     context: context,
                //     delegate: AddressSearch(sessionToken),
                //   );
                //   if (result != null) {
                //     final placeDetails = await PlaceApiProvider(sessionToken)
                //         .getPlaceDetailFromId(result.placeId);
                //     setState(() {
                //       _controller.text = result.description;
                //       longitude = placeDetails.longitude;
                //       latitude = placeDetails.latitude;
                //       loc(LatLng(latitude, longitude));
                //       cameraMoving = false;
                //     });
                //     _mapController.moveCamera(
                //         CameraUpdate.newCameraPosition(cameraPosition));
                //   }
                // },

                hintText: "Enter your delivery address",
                helperText: "Search or drag and pin on map",
              ),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
              CustomTextField(
                keyboardType: TextInputType.text,
                style: TextStyle(color: kBlackColor),
                onChanged: (value) {
                  locationNote = value;
                },
                hintText: "Note: e.g Home, Office",
              ),
              SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 4)),
              if (!selected)
                Divider(
                  color: kWhiteColor,
                ),
              if (!selected)
                SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 4)),
              if (!selected)
                Expanded(
                  child: ListView.separated(
                      itemCount: placePrediction.length,
                      separatorBuilder: (context, index) => SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: kWhiteColor),
                              borderRadius:
                                  BorderRadius.circular(kDefaultPadding)),
                          child: ListTile(
                            onTap: () async {
                              setState(() {
                                selected = true;
                              });
                              String sessionToken = Uuid().v4();
                              final placeDetails =
                                  await PlaceApiProvider(sessionToken)
                                      .getPlaceDetailFromId(
                                          placePrediction[index].placeId!);
                              setState(() {
                                _controller.text =
                                    placePrediction[index].description!;
                                longitude = placeDetails.longitude;
                                latitude = placeDetails.latitude;
                                loc(LatLng(latitude!, longitude!));
                                cameraMoving = false;
                              });
                              _mapController!.moveCamera(
                                  CameraUpdate.newCameraPosition(
                                      cameraPosition!));
                            },
                            leading: Icon(
                              HeroiconsOutline.mapPin,
                              color: kSecondaryColor,
                              size:
                                  getProportionateScreenWidth(kDefaultPadding),
                            ),
                            title: Text(
                              placePrediction[index].description!,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        );
                      }),
                ),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
              if (selected)
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    rotateGesturesEnabled: false,
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    initialCameraPosition: cameraPosition!,
                    markers: Set<Marker>.of(markers.values),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    onCameraMove: ((_position) {
                      loc(LatLng(_position.target.latitude,
                          _position.target.longitude));
                      setState(() {});
                    }),
                  ),
                ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }

//  List<Marker> _buildMarker() {
//    List<Marker> markers = [];
//
//    Marker marker = Marker(
//      width: 100,
//      height: 100,
//      point: _center,
//      builder: (context) => Icon(
//        Icons.location_on,
//        color: kSecondaryColor,
//        size: getProportionateScreenHeight(kDefaultPadding * 2.5),
//      ),
//    );
//    markers.add(marker);
//    return markers;
//  }
}
