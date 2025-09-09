import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
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
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/courier/components/category_card.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/order_status_row.dart';
import 'package:zmall/widgets/shimmer_widget.dart';

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
  bool _loading = false;
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
    super.initState();
    _getVehicleList();
  }

  void _getVehicleList() async {
    await Service.remove('images');
    setState(() {
      _loading = true;
    });
    var data = await getVehicleList();
    // debugPrint("fetched vehicle list");
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        vehicleList = data;
      });
    } else {
      setState(() {
        _loading = false;
      });

      Service.showMessage(
          context: context,
          title: "${errorCodes['${data['error_code']}']}!",
          error: true);
      await Future.delayed(Duration(seconds: 2));
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

//from gallery
  Future getImage() async {
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(image!.path);
      imageList.add(_image!);
      imagePath.add(_image!.path);
      imageList.length == 2 ? canAddImage = false : canAddImage = true;
    });
    // debugPrint("image path $imagePath");
  }
  //from camera
  // Future getImage() async {
  //   // final image = await imagePicker.getImage(source: ImageSource.camera); change getImage to pickImage
  //   final image = await imagePicker.pickImage(source: ImageSource.camera);
  // setState(() {
  //   _image = File(image!.path);
  //   imageList.add(_image!);
  //   imagePath.add(image.path);
  //   imageList.length == 2 ? canAddImage = false : canAddImage = true;
  // });
  // }

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
    // debugPrint("Fetching invoice.....");
    setState(() {
      _loading = true;
    });
    var data = await getCourierInvoice();
    if (data != null && data['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return CourierCheckout(
              orderDetail: widget.orderDetail,
              userData: widget.userData,
              cartInvoice: data,
            );
          },
        ),
      );
    } else {
      Service.showMessage(
          context: context,
          title: "${errorCodes['${data['error_code']}']}!",
          error: true);
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
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.only(
            left: getProportionateScreenWidth(kDefaultPadding),
            right: getProportionateScreenWidth(kDefaultPadding),
            bottom: getProportionateScreenHeight(kDefaultPadding / 2)),
        child: CustomButton(
          title: "Checkout",
          press: () async {
            if (imagePath.length > 0) {
              // debugPrint("Saving images");
              await Service.save('images', imagePath);
              // debugPrint("Images saved....");
            }
            await Service.saveBool('courier_paid_by_sender', paidBySender);
            _getTotalDistance();
          },
          color: kSecondaryColor,
        ),
      ),
      body: ModalProgressHUD(
        color: kPrimaryColor.withValues(alpha: 0.1),
        inAsyncCall: _loading,
        progressIndicator: LinearLoadingIndicator(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding),
              vertical: getProportionateScreenHeight(kDefaultPadding),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: getProportionateScreenHeight(kDefaultPadding),
              children: [
                // Enhanced Vehicle Selection Section
                Container(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding),
                    ),
                    border: Border.all(
                      color: kWhiteColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: getProportionateScreenHeight(kDefaultPadding),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OrderStatusRow(
                              value: "Select Vehicle",
                              title: "The vehicle for your delivery.",
                              icon: HeroiconsOutline.truck,
                            ),
                          ),
                          if (vehicleList != null &&
                              vehicleList['vehicles'].length > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 4),
                              ),
                              decoration: BoxDecoration(
                                color: kSecondaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding / 2),
                                ),
                              ),
                              child: Text(
                                "${vehicleList['vehicles'].length} Available",
                                style: TextStyle(
                                  fontSize: getProportionateScreenHeight(
                                      kDefaultPadding * 0.6),
                                  fontWeight: FontWeight.w600,
                                  color: kSecondaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      vehicleList != null && vehicleList['vehicles'].length > 0
                          ? Container(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding * 6),
                              child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) => CategoryCard(
                                        imageUrl: selected == index
                                            ? "images/${vehicleList['vehicles'][index]['vehicle_name'].toString().toLowerCase()}_selected.png"
                                            : "images/${vehicleList['vehicles'][index]['vehicle_name'].toString().toLowerCase()}.png",
                                        //imageUrl:  vehicleList['vehicles'][index]
                                        //             ['image_url'] !=
                                        //         null
                                        //     ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${vehicleList['vehicles'][index]['image_url']}"
                                        //     : "https://google.com",
                                        category:
                                            Service.capitalizeFirstLetters(
                                          vehicleList['vehicles'][index]
                                              ['vehicle_name'],
                                        ),
                                        press: () {
                                          setState(() {
                                            selected = index;
                                          });
                                        },
                                        selected: selected == index,
                                      ),
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          SizedBox(
                                            width: getProportionateScreenWidth(
                                                kDefaultPadding),
                                          ),
                                  itemCount: vehicleList['vehicles'] != null
                                      ? vehicleList['vehicles'].length
                                      : 0),
                            )
                          : _loading
                              ? Container(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding * 5.5),
                                  child: ListView.separated(
                                    itemCount: 3,
                                    scrollDirection: Axis.horizontal,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(
                                      width: getProportionateScreenWidth(
                                          kDefaultPadding / 2),
                                    ),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width: getProportionateScreenWidth(
                                            kDefaultPadding * 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: getProportionateScreenHeight(
                                              kDefaultPadding / 4),
                                          children: [
                                            SearchButtonShimmer(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * 5),
                                              height:
                                                  getProportionateScreenHeight(
                                                      kDefaultPadding * 3),
                                              borderRadius: kDefaultPadding / 2,
                                            ),
                                            SearchButtonShimmer(
                                              height:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * 1.5),
                                              borderRadius: kDefaultPadding / 2,
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding * 5),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.all(
                                      getProportionateScreenWidth(
                                          kDefaultPadding)),
                                  decoration: BoxDecoration(
                                    color:
                                        kSecondaryColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                    border: Border.all(
                                      color: kSecondaryColor.withValues(
                                          alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        HeroiconsOutline.exclamationTriangle,
                                        color: kSecondaryColor,
                                        size: getProportionateScreenWidth(
                                            kDefaultPadding * 2),
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 2)),
                                      Text(
                                        "No Vehicles Available",
                                        style: TextStyle(
                                          fontSize:
                                              getProportionateScreenHeight(
                                                  kDefaultPadding * 0.8),
                                          fontWeight: FontWeight.bold,
                                          color: kBlackColor,
                                        ),
                                      ),
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 4)),
                                      Text(
                                        "All our vehicles are busy completing orders.\nPlease try again in a few minutes.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              getProportionateScreenHeight(
                                                  kDefaultPadding * 0.65),
                                          color: kGreyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ],
                  ),
                ),
                // Enhanced Item Quantity Section
                Container(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding),
                    ),
                    border: Border.all(
                      color: kWhiteColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrderStatusRow(
                        value: "Item Quantity",
                        title: "How many items are you sending?",
                        icon: HeroiconsOutline.shoppingBag,
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding / 1.5),
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding * 0.4),
                              ),
                              decoration: BoxDecoration(
                                color: kWhiteColor,
                                border: Border.all(
                                    color: kGreyColor.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding / 2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                HeroiconsOutline.minus,
                                color: quantity > 1
                                    ? kBlackColor
                                    : kGreyColor.withValues(alpha: 0.5),
                                size: getProportionateScreenWidth(
                                    kDefaultPadding),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding / 8),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kSecondaryColor.withValues(alpha: 0.05),
                                    kSecondaryColor.withValues(alpha: 0.1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding / 2),
                                ),
                                border: Border.all(
                                  color: kSecondaryColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                                children: [
                                  Text(
                                    "$quantity",
                                    style: TextStyle(
                                      fontSize: getProportionateScreenHeight(
                                          kDefaultPadding),
                                      fontWeight: FontWeight.bold,
                                      color: kSecondaryColor,
                                    ),
                                  ),
                                  Text(
                                    quantity == 1 ? "Item" : "Items",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge!
                                        .copyWith(color: kBlackColor),
                                    // style: TextStyle(
                                    //   fontSize: getProportionateScreenHeight(
                                    //       kDefaultPadding / 2),
                                    //   color: kGreyColor,
                                    // ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                quantity++;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding / 1.5),
                                vertical: getProportionateScreenHeight(
                                    kDefaultPadding * 0.4),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kSecondaryColor,
                                    kSecondaryColor.withValues(alpha: 0.9)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding / 2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        kSecondaryColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                HeroiconsOutline.plus,
                                color: kWhiteColor,
                                size: getProportionateScreenWidth(
                                    kDefaultPadding),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(
                      //     height: getProportionateScreenHeight(
                      //         kDefaultPadding / 2)),
                      // SingleChildScrollView(
                      //   scrollDirection: Axis.horizontal,
                      //   child: Center(
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       spacing: getProportionateScreenWidth(
                      //           kDefaultPadding / 2),
                      //       children: [
                      //         _buildQuickQuantityButton(5),
                      //         _buildQuickQuantityButton(10),
                      //         _buildQuickQuantityButton(15),
                      //         _buildQuickQuantityButton(20),
                      //         _buildQuickQuantityButton(25),
                      //         _buildQuickQuantityButton(30),
                      //         // _buildQuickQuantityButton(35),
                      //         // _buildQuickQuantityButton(40),
                      //         // _buildQuickQuantityButton(50),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                // Payment Method Section with Enhanced UI
                Container(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding),
                    ),
                    border: Border.all(
                      color: kWhiteColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: getProportionateScreenHeight(kDefaultPadding),
                    children: [
                      OrderStatusRow(
                        value: "Payment Method",
                        title: "Who will pay for this delivery?",
                        icon: HeroiconsOutline.banknotes,
                      ),
                      Row(
                        spacing:
                            getProportionateScreenWidth(kDefaultPadding / 2),
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  paidBySender = true;
                                });
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                padding: EdgeInsets.all(
                                  getProportionateScreenWidth(
                                      kDefaultPadding * 0.8),
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  // color: paidBySender ? null : kWhiteColor,
                                  borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding),
                                  ),
                                  border: Border.all(
                                    color: paidBySender
                                        ? kSecondaryColor
                                        : kGreyColor.withValues(alpha: 0.2),
                                    width: paidBySender ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  spacing: getProportionateScreenHeight(
                                      kDefaultPadding / 3),
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        getProportionateScreenWidth(
                                            kDefaultPadding / 2),
                                      ),
                                      decoration: BoxDecoration(
                                        color: kWhiteColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        color: kBlackColor,
                                        size: getProportionateScreenWidth(
                                            kDefaultPadding * 1.2),
                                      ),
                                    ),
                                    Text(
                                      "Sender",
                                      style: TextStyle(
                                        color: kBlackColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: getProportionateScreenHeight(
                                            kDefaultPadding * 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  paidBySender = false;
                                });
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                padding: EdgeInsets.all(
                                  getProportionateScreenWidth(
                                      kDefaultPadding * 0.8),
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding),
                                  ),
                                  border: Border.all(
                                    color: !paidBySender
                                        ? kSecondaryColor
                                        : kGreyColor.withValues(alpha: 0.2),
                                    width: !paidBySender ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  spacing: getProportionateScreenHeight(
                                      kDefaultPadding / 3),
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        getProportionateScreenWidth(
                                            kDefaultPadding / 2),
                                      ),
                                      decoration: BoxDecoration(
                                        color: kWhiteColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_pin_outlined,
                                        color: kBlackColor,
                                        size: getProportionateScreenWidth(
                                            kDefaultPadding * 1.2),
                                      ),
                                    ),
                                    Text(
                                      "Receiver",
                                      style: TextStyle(
                                        color: kBlackColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: getProportionateScreenHeight(
                                            kDefaultPadding * 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Round Trip Section with Enhanced UI
                Container(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding),
                    ),
                    border: Border.all(
                      color: kWhiteColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: getProportionateScreenHeight(kDefaultPadding),
                    children: [
                      OrderStatusRow(
                        value: "Trip Type",
                        title: "Delivery trip type",
                        icon: HeroiconsOutline.arrowPathRoundedSquare,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding * 2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isRoundTrip = false;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: getProportionateScreenHeight(
                                        kDefaultPadding * 0.8),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: !isRoundTrip
                                        ? LinearGradient(
                                            colors: [
                                              kSecondaryColor,
                                              kSecondaryColor.withValues(
                                                  alpha: 0.9)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding * 2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        HeroiconsOutline.mapPin,
                                        color: !isRoundTrip
                                            ? kWhiteColor
                                            : kGreyColor,
                                        size: getProportionateScreenWidth(
                                            kDefaultPadding * 0.8),
                                      ),
                                      SizedBox(
                                          width: getProportionateScreenWidth(
                                              kDefaultPadding / 4)),
                                      Text(
                                        "One Way",
                                        style: TextStyle(
                                          color: !isRoundTrip
                                              ? kWhiteColor
                                              : kGreyColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              getProportionateScreenHeight(
                                                  kDefaultPadding * 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isRoundTrip = true;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: getProportionateScreenHeight(
                                        kDefaultPadding * 0.8),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isRoundTrip
                                        ? LinearGradient(
                                            colors: [
                                              kSecondaryColor,
                                              kSecondaryColor.withValues(
                                                  alpha: 0.9)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding * 2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        HeroiconsOutline.arrowsRightLeft,
                                        color: isRoundTrip
                                            ? kWhiteColor
                                            : kGreyColor,
                                        size: getProportionateScreenWidth(
                                            kDefaultPadding * 0.8),
                                      ),
                                      SizedBox(
                                          width: getProportionateScreenWidth(
                                              kDefaultPadding / 4)),
                                      Text(
                                        "Round Trip",
                                        style: TextStyle(
                                          color: isRoundTrip
                                              ? kWhiteColor
                                              : kGreyColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              getProportionateScreenHeight(
                                                  kDefaultPadding * 0.7),
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

                //image section
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                      vertical:
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding),
                    ),
                    border: Border.all(
                      color: kWhiteColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: getProportionateScreenHeight(kDefaultPadding),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OrderStatusRow(
                              value: "Images",
                              title: "Item proof photo",
                              icon: HeroiconsOutline.photo,
                            ),
                          ),
                          if (imageList.length < 2)
                            InkWell(
                              onTap: getImage,
                              child: Row(
                                spacing: getProportionateScreenWidth(
                                    kDefaultPadding / 4),
                                children: [
                                  Text(
                                    imageList.length > 0 && imageList.length < 2
                                        ? "Add More "
                                        : "Add Image",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          color: kSecondaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Icon(
                                    imageList.length >= 2
                                        ? null
                                        : HeroiconsOutline.plusCircle,
                                    color: kSecondaryColor,
                                    size: getProportionateScreenHeight(18),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      imageList.length <= 0
                          ? SizedBox.shrink()
                          : Container(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding * 6),
                              child: ListView.separated(
                                itemCount: imageList.length,
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                      kDefaultPadding),
                                ),
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        SizedBox(
                                  width: getProportionateScreenWidth(
                                      kDefaultPadding),
                                ),
                                itemBuilder: (context, index) => Stack(
                                  children: [
                                    Container(
                                      height: getProportionateScreenHeight(
                                          kDefaultPadding * 6),
                                      width: getProportionateScreenWidth(
                                          kDefaultPadding * 5),
                                      child: Image.file(imageList[index]),
                                    ),
                                    Positioned(
                                      top: -2,
                                      right: -3,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            imageList.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          // padding: EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: kWhiteColor,
                                              width: 2,
                                            ),
                                            boxShadow: [kDefaultShadow],
                                          ),
                                          child: Icon(
                                            HeroiconsOutline.xCircle,
                                            color: kSecondaryColor,
                                            size: getProportionateScreenWidth(
                                                kDefaultPadding * 1.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> getVehicleList() async {
    // debugPrint("getting vehicle list");
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

    // debugPrint(url);

    var body = json.encode(data);
    // debugPrint(body);
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
      // debugPrint(e);
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
    // debugPrint("getting total distance");
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
      // debugPrint(json.decode(response.body));
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
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
    // debugPrint("getting courier invoice");
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
    // debugPrint(body);
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
      // debugPrint(e);
      setState(() {
        this._loading = false;
      });

      Service.showMessage(
          context: context,
          title: "Please check your internet connection",
          error: true);
      return null;
    }
  }

  // Widget _buildQuickQuantityButton(int value) {
  //   return GestureDetector(
  //     onTap: () {
  //       setState(() {
  //         quantity = value;
  //       });
  //     },
  //     child: Container(
  //       padding: EdgeInsets.symmetric(
  //         horizontal: getProportionateScreenWidth(kDefaultPadding * 0.6),
  //         vertical: getProportionateScreenHeight(kDefaultPadding * 0.3),
  //       ),
  //       decoration: BoxDecoration(
  //         color: quantity == value
  //             ? kSecondaryColor.withValues(alpha: 0.1)
  //             : kWhiteColor,
  //         borderRadius: BorderRadius.circular(
  //           getProportionateScreenWidth(kDefaultPadding / 2),
  //         ),
  //         border: Border.all(
  //           color: quantity == value
  //               ? kSecondaryColor
  //               : kGreyColor.withValues(alpha: 0.2),
  //           width: quantity == value ? 1.5 : 1,
  //         ),
  //       ),
  //       child: Text(
  //         "$value",
  //         style: TextStyle(
  //           fontSize: getProportionateScreenHeight(kDefaultPadding * 0.65),
  //           fontWeight: quantity == value ? FontWeight.bold : FontWeight.normal,
  //           color: quantity == value ? kSecondaryColor : kGreyColor,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
