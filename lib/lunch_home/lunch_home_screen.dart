import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/courier/components/locations_list.dart';
import 'package:zmall/courier_checkout/courier_checkout_screen.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_progress_indicator.dart';
import 'package:zmall/widgets/section_title.dart';

class LunchHomeScreen extends StatefulWidget {
  const LunchHomeScreen({Key? key, required this.curLat, required this.curLon})
      : super(key: key);

  final double curLon;
  final double curLat;

  @override
  _LunchHomeScreenState createState() => _LunchHomeScreenState();
}

class _LunchHomeScreenState extends State<LunchHomeScreen> {
  bool _isLoading = false;
  final _controller = TextEditingController();
  final _dropOffController = TextEditingController();
  double? latitude, longitude;
  double? destLatitude, destLongitude;
  var userData;
  var vehicleList;
  String senderUser = "", senderPhone = "";
  String receiverName = "", receiverPhone = "";
  var orderDetail;
  String loadingMessage = "Loading...";
  double distance = 0.0;
  double time = 0.0;
  bool isSchedule = false;
  DateTime? _scheduledDate;
  Contact? _contact;
  HomeContact? _homeContact;

  final _senderUser = TextEditingController();
  final _senderPhone = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    getHomeContact();
  }

  void getUser() async {
    setState(() {
      _isLoading = true;
    });
    // await Future.delayed(Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
        receiverName = userData['user']['first_name'] +
            " " +
            userData['user']['last_name'];
        receiverPhone = userData['user']['phone'];
      });
    }
  }

  void getHomeContact() async {
    var data = await Service.read('home_contact');
    if (data != null) {
      setState(() {
        _homeContact = HomeContact.fromJson(data);
      });
    }
  }

  void _getVehicleList() async {
    await Service.remove('images');
    setState(() {
      _isLoading = true;
    });
    var data = await getVehicleList();

    if (data != null && data['success']) {
      setState(() {
        _isLoading = false;
        vehicleList = data;
      });
      _getTotalDistance();
    } else {
      setState(() {
        _isLoading = false;
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

  void _getTotalDistance() async {
    setState(() {
      loadingMessage = "Calculating Distance...";
      _isLoading = true;
    });
    var data = await getTotalDistance();
    if (data != null && data['rows'][0]['elements'][0]['status'] == 'OK') {
      setState(() {
        distance =
            data['rows'][0]['elements'][0]['distance']['value'].toDouble();
        time = data['rows'][0]['elements'][0]['duration']['value'].toDouble();
      });
      _getLunchInvoice();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _getLunchInvoice() async {
    setState(() {
      loadingMessage = "Generating Invoice...";
      _isLoading = true;
    });
    var data = await getLunchInvoice();
    if (data != null && data['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return CourierCheckout(
                orderDetail: orderDetail,
                userData: userData,
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
      _isLoading = false;
    });
  }

  void _addLunchToCart() async {
    setState(() {
      _isLoading = true;
    });
    var data = await addLunchToCart();
    if (data != null && data['success']) {
      setState(() {
        _isLoading = false;
      });
      await Service.save('courier', data);
      await Service.saveBool("is_schedule", isSchedule);
      await Service.save(
          "schedule_start", isSchedule ? _scheduledDate.toString() : null);
      _getVehicleList();
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
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home Lunch",
          style: TextStyle(color: kPrimaryColor),
        ),
        elevation: 0.0,
        backgroundColor: kSecondaryColor,
      ),
      body: ModalProgressHUD(
        color: kPrimaryColor.withValues(alpha: 0.1),
        inAsyncCall: _isLoading,
        progressIndicator: CustomLinearProgressIndicator(
          message: loadingMessage,
        ),
        child: SingleChildScrollView(
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
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding),
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
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          Row(
                            children: [
                              Text(
                                "Home Food = Soul Food",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
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
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding)),
                            height: getProportionateScreenHeight(
                                kDefaultPadding * 2.5),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              boxShadow: [kDefaultShadow],
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
                                        title: "Home Address",
                                      ),
                                    ),
                                  ).then((dynamic value) {
                                    if (value != null) {
                                      DestinationAddress address = value;
                                      setState(() {
                                        _controller.text = address!.name!;
                                        longitude = double.parse(
                                            address.long!.toStringAsFixed(6));
                                        latitude = double.parse(
                                            address.lat!.toStringAsFixed(6));
                                      });
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.home,
                                    color: kSecondaryColor,
                                  ),
                                  hintText: "Home Address",
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
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(
                                    kDefaultPadding)),
                            height: getProportionateScreenHeight(
                                kDefaultPadding * 2.5),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(
                                getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                              boxShadow: [kDefaultShadow],
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
                                        title: "Delivery Address",
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
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.pin_drop_outlined,
                                    color: kSecondaryColor,
                                  ),
                                  hintText: "Delivery Address",
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
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(kDefaultPadding)),
                child: SectionTitle(
                  sectionTitle: "Receiver Contact",
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
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  boxShadow: [kDefaultShadow],
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
                        labelText:
                            "${Provider.of<ZMetaData>(context, listen: false).areaCode}$receiverPhone",
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
                        hintText: "$receiverName",
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
                  sectionTitle: "Home Contact",
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
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  boxShadow: [kDefaultShadow],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _senderUser,
                      cursorColor: kSecondaryColor,
                      style: TextStyle(color: kBlackColor),
                      keyboardType: TextInputType.text,
                      onChanged: (val) {
                        senderUser = val;
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kSecondaryColor),
                        ),
                        labelText: "Sender Name",
                        labelStyle: TextStyle(
                          color: kGreyColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    TextField(
                      controller: _senderPhone,
                      cursorColor: kSecondaryColor,
                      style: TextStyle(color: kBlackColor),
                      keyboardType: TextInputType.number,
                      maxLength: 9,
                      onChanged: (val) {
                        senderPhone = val;
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kSecondaryColor),
                        ),
                        labelText: "Sender Phone",
                        labelStyle: TextStyle(
                          color: kGreyColor,
                        ),
                        prefix: Text(
                          "${Provider.of<ZMetaData>(context, listen: false).areaCode}",
                          style: TextStyle(color: kGreyColor),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select from existing contacts",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: kBlackColor),
                        ),
                        if (senderUser.isNotEmpty && senderPhone.isNotEmpty ||
                            (_homeContact != null &&
                                _homeContact!.list!
                                        .where((element) =>
                                            element.phone == senderPhone)
                                        .length >
                                    0))
                          TextButton(
                            onPressed: () {
                              _contact =
                                  Contact(name: senderUser, phone: senderPhone);

                              if (_homeContact != null) {
                                if (_homeContact!.list!
                                        .where((element) =>
                                            element.phone == senderPhone)
                                        .length >
                                    0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        ("Contact already exists"), true),
                                  );
                                } else {
                                  _homeContact!.list!.add(_contact!);
                                  Service.save(
                                      'home_contact', _homeContact!.toJson());

                                  getHomeContact();
                                }
                              } else {
                                _homeContact = HomeContact(
                                  list: [_contact!],
                                );

                                Service.save(
                                    'home_contact', _homeContact!.toJson());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  Service.showMessage(
                                      "Home contact added...", false),
                                );
                                getHomeContact();
                              }
                            },
                            child: Text(
                              "Save Contact",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color: kSecondaryColor,
                                  ),
                            ),
                          )
                      ],
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    if (_homeContact != null && _homeContact!.list!.length > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: getProportionateScreenHeight(
                                kDefaultPadding * 3.5),
                            width: double.infinity,
                            // decoration: BoxDecoration(
                            //   border:
                            //       Border.all(color: kBlackColor.withValues(alpha: 0.2)),
                            // ),
                            padding: EdgeInsets.only(
                              right: getProportionateScreenWidth(
                                  kDefaultPadding / 2),
                            ),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _homeContact != null &&
                                      _homeContact!.list!.length > 0
                                  ? _homeContact!.list!.length
                                  : 0,
                              itemBuilder: (context, index) => Row(
                                children: [
                                  // index == 0
                                  //     ? SizedBox(
                                  //         width: getProportionateScreenWidth(
                                  //             kDefaultPadding),
                                  //       )
                                  //     : Container(),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        senderUser =
                                            _homeContact!.list![index].name!;
                                        senderPhone =
                                            _homeContact!.list![index].phone!;
                                        _senderPhone.text =
                                            _homeContact!.list![index].phone!;
                                        _senderUser.text =
                                            _homeContact!.list![index].name!;
                                      });
                                    },
                                    onDoubleTap: () {
                                      _homeContact!.list!.removeAt(index);
                                      Service.save(
                                          "home_contact", _homeContact);
                                      getHomeContact();
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getProportionateScreenWidth(
                                            kDefaultPadding / 3),
                                        vertical: getProportionateScreenHeight(
                                            kDefaultPadding / 2),
                                      ),
                                      decoration: BoxDecoration(
                                        boxShadow: [boxShadow],
                                        borderRadius: BorderRadius.circular(
                                            getProportionateScreenWidth(
                                                kDefaultPadding / 2)),
                                        border: Border.all(
                                            color: kBlackColor.withValues(
                                                alpha: 0.2)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${_homeContact!.list![index].phone}"
                                                .toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(
                                                  color: kBlackColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          Text(
                                            _homeContact!.list![index].name!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge!
                                                .copyWith(
                                                  color: kBlackColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              separatorBuilder:
                                  (BuildContext context, int index) => SizedBox(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding / 2),
                              ),
                            ),
                          ),
                          SizedBox(
                            height:
                                getProportionateScreenWidth(kDefaultPadding),
                          ),
                          Text(
                            "Double tap to remove...",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
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
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  boxShadow: [kDefaultShadow],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Schedule Order?",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSchedule = !isSchedule;
                            });
                          },
                          child: Container(
                            height: kDefaultPadding,
                            width: getProportionateScreenWidth(kDefaultPadding),
                            decoration: BoxDecoration(
                              color:
                                  isSchedule ? kSecondaryColor : kPrimaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  width: 1,
                                  color: isSchedule ? kGreyColor : kBlackColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    isSchedule
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                child: Text(
                                  _scheduledDate != null
                                      ? _scheduledDate.toString().split('.')[0]
                                      : " Add Date & Time ",
                                  style: TextStyle(
                                    color: kSecondaryColor,
                                  ),
                                ),
                                style: ButtonStyle(
                                  elevation: MaterialStateProperty.all(1.0),
                                  backgroundColor:
                                      MaterialStateProperty.all(kPrimaryColor),
                                ),
                                onPressed: () async {
                                  DateTime _now = DateTime.now();
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: _now,
                                    lastDate: _now.add(
                                      Duration(days: 7),
                                    ),
                                  );
                                  TimeOfDay? time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(
                                          DateTime.now()));
                                  setState(() {
                                    _scheduledDate = pickedDate!.add(Duration(
                                        hours: time!.hour,
                                        minutes: time!.minute));
                                  });
                                },
                              ),
                            ],
                          )
                        : Container(),
                  ],
                ),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(kDefaultPadding)),
                child: CustomButton(
                    title: "Continue",
                    press: () {
                      if (isSchedule && _scheduledDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            Service.showMessage(
                                "Please enter date and time for your schedule!",
                                true));
                      } else if (_controller.text != null &&
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
                        setState(() {
                          loadingMessage = "Making sure there are no dogs...";
                        });
                        _addLunchToCart();
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
                                  "Please enter destination address!", true));
                        } else if (senderPhone.isEmpty || senderUser.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please enter sender information!", true));
                        } else if (receiverPhone.isEmpty ||
                            receiverName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              Service.showMessage(
                                  "Please enter receiver information!", true));
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
      ),
    );
  }

  Future<dynamic> addLunchToCart() async {
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
          "note": "Lunch from Home",
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
          "note": "Lunch From Home",
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
      "delivery_type": 2,
      "is_schedule": isSchedule,
      "schedule_start": isSchedule ? _scheduledDate.toString() : null,
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
            this._isLoading = false;
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
        this._isLoading = false;
        orderDetail = data;
      });
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        this._isLoading = false;
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

  Future<dynamic> getVehicleList() async {
    print("getting vehicle list");
    setState(() {
      _isLoading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/store/get_vehicle_list";

    Map data = {
      "store_id": "",
      "type": 7,
      "delivery_type": 2,
      "user_id": userData['user']['_id'],
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
        Duration(seconds: 20),
        onTimeout: () {
          setState(() {
            _isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _isLoading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        _isLoading = false;
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
    var url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}&destinations=${destLatitude!.toStringAsFixed(6)},${destLongitude!.toStringAsFixed(6)}&key=$apiKey";

    try {
      http.Response response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 20),
        onTimeout: () {
          setState(() {
            _isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }

  Future<dynamic> getLunchInvoice() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_courier_order_invoice";

    Map data = {
      "user_id": userData['user']['_id'],
      "total_time": time,
      "total_distance": distance,
      "is_user_pickup_order": false,
      "total_item_count": 1,
      "is_user_drop_order": true,
      "server_token": userData['user']['server_token'],
      "vehicle_id": vehicleList['vehicles'][0]['_id'],
      "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
      "country_id": Provider.of<ZMetaData>(context, listen: false).countryId,
      "is_round_trip": false,
      "courier_type": "Lunch From Home",
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
            _isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _isLoading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // print(e);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage("Please check your internet connection", true),
      );
      return null;
    }
  }
}
