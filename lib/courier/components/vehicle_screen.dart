import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zmall/courier_checkout/courier_checkout_screen.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/size_config.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:zmall/home/components/category_card.dart';
import 'package:zmall/widgets/section_title.dart';

class VehicleScreen extends StatefulWidget {
  static String routeName = '/vehicle';

  const VehicleScreen({
    @required this.userData,
    @required this.orderDetail,
    @required this.pickupAddress,
    @required this.destinationAddress,
  });

  final userData, orderDetail;
  final LatLng? pickupAddress;
  final LatLng? destinationAddress;

  @override
  _VehicleScreenState createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  bool? _loading = false;
  bool canAddImage = true;
  bool paidBySender = true;
  bool isRoundTrip = false;
  var vehicleList;
  int selected = 0;
  int quantity = 1;
  List<String> imagePath = [];
  List<File> imageList = [];
  double? distance, time;
  File? _image;
  final imagePicker = ImagePicker();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getVehicleList();
  }

  void _getVehicleList() async {
    await Service.remove('images');
    setState(() {
      _loading = true;
    });
    var data = await getVehicleList();
    print("fetched vehicle list");
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        vehicleList = data;
      });
    } else {
      setState(() {
        _loading = false;
      });
      print(data);
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

  Future getImage() async {
    // final image = await imagePicker.getImage(source: ImageSource.camera); change getImage to pickImage
    final image = await imagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = File(image!.path);
      imageList.add(_image!);
      imagePath.add(image!.path);
      imageList.length == 2 ? canAddImage = false : canAddImage = true;
    });
  }

  void _getTotalDistance() async {
    setState(() {
      _loading = true;
    });
    var data = await getTotalDistance();
    if (data != null && data['rows'][0]['elements'][0]['status'] == 'OK') {
      setState(() {
        distance =
            data['rows'][0]['elements'][0]['distance']['value'].toDouble();
        time = data['rows'][0]['elements'][0]['duration']['value'].toDouble();
      });
      _getCourierInvoice();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _getCourierInvoice() async {
    print("Fetching invoice.....");
    setState(() {
      _loading = true;
    });
    var data = await getCourierInvoice();
    // print(data);
    if (data != null && data['success']) {
//      setState(() {
//        _loading = false;
//      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return CourierCheckout(
                orderDetail: widget.orderDetail,
                userData: widget.userData,
                cartInvoice: data);
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
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Vehicle",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenHeight(kDefaultPadding),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                sectionTitle: "Please Choose Vehicle",
                subTitle: " ",
              ),
              vehicleList != null && vehicleList['vehicles'].length > 0
                  ? Container(
                      height: getProportionateScreenHeight(kDefaultPadding * 9),
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => CategoryCard(
                                selected: selected == index,
                                imageUrl: vehicleList['vehicles'][index]
                                            ['image_url'] !=
                                        null
                                    ? "http://159.65.147.111:8000/${vehicleList['vehicles'][index]['image_url']}"
                                    : "https://google.com",
                                category: vehicleList['vehicles'][index]
                                    ['vehicle_name'],
                                press: () {
                                  setState(() {
                                    selected = index;
                                  });
                                },
                              ),
                          separatorBuilder: (BuildContext context, int index) =>
                              SizedBox(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                          itemCount: vehicleList['vehicles'] != null
                              ? vehicleList['vehicles'].length
                              : 0),
                    )
                  : _loading!
                      ? Center(
                          child: SpinKitWave(
                            color: kSecondaryColor,
                            size: getProportionateScreenWidth(kDefaultPadding),
                          ),
                        )
                      : Center(
                          child: Text(
                            "All our vehicles are busy to complete this order.\nPlease try again later...",
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.caption?.copyWith(),
                          ),
                        ),
              SectionTitle(
                sectionTitle: "Item Quantity",
                subTitle: " ",
              ),
              TextField(
                cursorColor: kSecondaryColor,
                style: TextStyle(color: kBlackColor),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (val) {
                  quantity = int.parse(val);
                },
                decoration: InputDecoration(
                  hintText: "$quantity",
                  hintStyle: TextStyle(
                    color: kGreyColor,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kSecondaryColor),
                  ),
                ),
              ),
              SectionTitle(
                sectionTitle: "Round Trip?",
                subTitle: " ",
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      // borderRadius: BorderRadius.circular(
                      //   getProportionateScreenWidth(kDefaultPadding / 1.2),
                      // ),
                      onTap: () {
                        setState(() {
                          isRoundTrip = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                          color: kPrimaryColor,
                          border: Border.all(
                              color:
                                  !isRoundTrip ? kSecondaryColor : kGreyColor),
                          boxShadow: [boxShadow],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding),
                            vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: kDefaultPadding,
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                decoration: BoxDecoration(
                                  color: !isRoundTrip
                                      ? kSecondaryColor
                                      : kPrimaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      width: 1,
                                      color: !isRoundTrip
                                          ? kGreyColor
                                          : kBlackColor),
                                ),
                              ),
                              SizedBox(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              Text(
                                "No",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                      fontWeight: !isRoundTrip
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding / 2)),
                  Expanded(
                    child: GestureDetector(
                      // borderRadius: BorderRadius.circular(
                      //   getProportionateScreenWidth(kDefaultPadding / 2),
                      // ),
                      onTap: () {
                        setState(() {
                          isRoundTrip = true;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                          color: kPrimaryColor,
                          boxShadow: [boxShadow],
                          border: Border.all(
                              color:
                                  isRoundTrip ? kSecondaryColor : kGreyColor),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding),
                            vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: kDefaultPadding,
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                decoration: BoxDecoration(
                                  color: isRoundTrip
                                      ? kSecondaryColor
                                      : kPrimaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      width: 1,
                                      color: isRoundTrip
                                          ? kGreyColor
                                          : kBlackColor),
                                ),
                              ),
                              SizedBox(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              Text(
                                "Yes",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                      fontWeight: isRoundTrip
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SectionTitle(
                sectionTitle: "Images",
                subTitle: " ",
              ),
              imageList.length > 0
                  ? Container(
                      height: getProportionateScreenHeight(kDefaultPadding * 9),
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => Stack(
                                children: [
                                  Container(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding * 9),
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding * 7),
                                    child: Image.file(imageList[index]),
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: GestureDetector(
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal:
                                              getProportionateScreenWidth(
                                                  kDefaultPadding / 3),
                                          vertical: getProportionateScreenWidth(
                                              kDefaultPadding / 4),
                                        ),
                                        child: Icon(
                                          Icons.cancel,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          imageList.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          separatorBuilder: (BuildContext context, int index) =>
                              SizedBox(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                          itemCount: imageList.length),
                    )
                  : GestureDetector(
                      onTap: getImage,
                      child: Container(
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 9),
                        width: getProportionateScreenWidth(kDefaultPadding * 7),
                        decoration: BoxDecoration(
                          color: kGreyColor.withOpacity(.3),
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: kGreyColor,
                                size: getProportionateScreenWidth(
                                    kDefaultPadding * 2),
                              ),
                              Text("Add Image")
                            ],
                          ),
                        ),
                      ),
                    ),
              // SizedBox(
              //   height: getProportionateScreenHeight(kDefaultPadding / 2),
              // ),
              imageList.length > 0 && imageList.length < 2
                  ? Center(
                      child: TextButton(
                          onPressed: getImage,
                          child: Text(
                            "Add More Images",
                            style: TextStyle(color: kSecondaryColor),
                          )),
                    )
                  : Container(),

              SectionTitle(
                sectionTitle: "Paid by",
                subTitle: " ",
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding / 2),
                      ),
                      onTap: () {
                        setState(() {
                          paidBySender = true;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 2),
                          ),
                          border: Border.all(
                              color:
                                  paidBySender ? kSecondaryColor : kBlackColor),
                          boxShadow: [boxShadow],
                          color: kPrimaryColor,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding),
                            vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: kDefaultPadding,
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                decoration: BoxDecoration(
                                  color: paidBySender
                                      ? kSecondaryColor
                                      : kPrimaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      width: 1,
                                      color: paidBySender
                                          ? kGreyColor
                                          : kBlackColor),
                                ),
                              ),
                              SizedBox(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              Text(
                                "Sender",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                      fontWeight: paidBySender
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding / 2)),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding / 2),
                      ),
                      onTap: () {
                        setState(() {
                          paidBySender = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          border: Border.all(
                              color: paidBySender
                                  ? kGreyColor.withOpacity(0.4)
                                  : kSecondaryColor),
                          borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(kDefaultPadding / 2)),
                          boxShadow: [boxShadow],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                getProportionateScreenWidth(kDefaultPadding),
                            vertical: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: kDefaultPadding,
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                decoration: BoxDecoration(
                                  color: !paidBySender
                                      ? kSecondaryColor
                                      : kPrimaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      width: 1,
                                      color: !paidBySender
                                          ? kGreyColor
                                          : kBlackColor),
                                ),
                              ),
                              SizedBox(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              Text(
                                "Receiver",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(
                                      fontWeight: !paidBySender
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              _loading!
                  ? SpinKitWave(
                      color: kSecondaryColor,
                      size: getProportionateScreenWidth(kDefaultPadding),
                    )
                  : CustomButton(
                      title: "Checkout",
                      press: () async {
                        if (imagePath.length > 0) {
                          print("Saving images");
                          await Service.save('images', imagePath);
                          print("Images saved....");
                        }
                        await Service.saveBool(
                            'courier_paid_by_sender', paidBySender);
                        _getTotalDistance();
                      },
                      color: kSecondaryColor,
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

  Future<dynamic> getVehicleList() async {
    print("getting vehicle list");
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/store/get_vehicle_list";

    Map data = {
      "store_id": "",
      "type": 7,
      "delivery_type": 2,
      "user_id": widget.userData['user']['_id'],
      "server_token": widget.userData['user']['server_token'],
      "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
    };

    print(url);

    var body = json.encode(data);
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
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> getTotalDistance() async {
    print("getting total distance");
    var url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=${widget.pickupAddress!.latitude.toStringAsFixed(6)},${widget.pickupAddress!.longitude.toStringAsFixed(6)}&destinations=${widget.destinationAddress!.latitude.toStringAsFixed(6)},${widget.destinationAddress!.longitude}&key=$apiKey";

    try {
      http.Response response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      print(json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      print(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connectin"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> getCourierInvoice() async {
    print("getting courier invoice");
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_courier_order_invoice";

    Map data = {
      "user_id": widget.userData['user']['_id'],
      "total_time": time,
      "total_distance": distance,
      "is_user_pickup_order": false,
      "total_item_count": quantity,
      "is_user_drop_order": true,
      "server_token": widget.userData['user']['server_token'],
      "vehicle_id": vehicleList['vehicles'][selected]['_id'],
      "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
      "country_id": widget.userData['user']['country_id'],
      "is_round_trip": isRoundTrip,
    };
    var body = json.encode(data);
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
        Service.showMessage("Please check your internet connection", true),
      );
      return null;
    }
  }
}
