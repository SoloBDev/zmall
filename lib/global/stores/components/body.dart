import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/products/global_products.dart';
import 'package:zmall/global/stores/global_stores.dart';
import 'package:timezone/timezone.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/custom_list_tile.dart';

class Body extends StatefulWidget {
  Body({
    required this.cityId,
    required this.storeDeliveryId,
    required this.latitude,
    required this.longitude,
    required this.isStore,
    required this.category,
    this.companyId,
  });

  final String cityId, storeDeliveryId;
  final double longitude, latitude;
  final bool isStore;
  final category;
  final int? companyId;
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  bool _loading = true;
  var responseData;
  var stores;
  List<bool> isOpen = [];
  TextEditingController controller = TextEditingController();
  List<dynamic> _searchResult = [];
  bool isLoggedIn = false;
  var userData;
  var now;
  var appOpen;
  var appClose;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.isStore ? _getStoreListByCompany() : _getCompanyList();
    isLogged();
    setupTime();
  }

  _getStoreListByCompany() async {
    await getStoreListByCompany(widget.cityId, widget.storeDeliveryId,
        widget.latitude, widget.longitude, widget.companyId!);

    if (responseData != null && responseData['success']) {
      stores = responseData['stores'];
      storeOpen(stores);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${errorCodes['${responseData['error_code']}']}"),
        ),
      );
    }
  }

  void _getCompanyList() async {
    await getCompanyList(widget.cityId, widget.storeDeliveryId, widget.latitude,
        widget.longitude);
    if (responseData != null && responseData['success']) {
      stores = responseData['stores'];
      storeOpen(stores);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${errorCodes['${responseData['error_code']}']}"),
        ),
      );
    }
  }

  void setupTime() async {
    var byteData = await rootBundle.load('packages/timezone/data/2021a.tzf');
    initializeDatabase(byteData.buffer.asUint8List());
  }

  void storeOpen(List stores) async {
    isOpen.clear();
    DateFormat dateFormat = new DateFormat.Hm();
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
    if (appOpen == null || appClose == null) {
      print("Couldn't find app open-close time...fetching is locally");
      appOpen = await Service.read('app_open');
      appClose = await Service.read('app_close');
    }

    stores.forEach((store) {
      bool isStoreOpen = false;
      if (store['store_time'] != null && store['store_time'].length != 0) {
        for (var i = 0; i < store['store_time'].length; i++) {
          DateFormat dateFormat = new DateFormat.Hm();
          // DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
          int weekday;
          if (now.weekday == 7) {
            weekday = 0;
          } else {
            weekday = now.weekday;
          }

          if (store['store_time'][i]['day'] == weekday) {
            if (store['store_time'][i]['day_time'].length != 0 &&
                store['store_time'][i]['is_store_open']) {
              for (var j = 0;
                  j < store['store_time'][i]['day_time'].length;
                  j++) {
                DateTime open = dateFormat.parse(
                    store['store_time'][i]['day_time'][j]['store_open_time']);
                open = new DateTime(
                    now.year, now.month, now.day, open.hour, open.minute);
                DateTime close = dateFormat.parse(
                    store['store_time'][i]['day_time'][j]['store_close_time']);
                close = new DateTime(
                    now.year, now.month, now.day, close.hour, close.minute);
                now = DateTime(
                    now.year, now.month, now.day, now.hour, now.minute);
                if (now.isAfter(open) &&
                    now.isBefore(close) &&
                    store['store_time'][i]['is_store_open']) {
                  isStoreOpen = true;
                  break;
                } else {
                  isStoreOpen = false;
                }
              }
            } else {
              isStoreOpen = store['store_time'][i]['is_store_open'];
            }
          }
        }
      } else {
        DateFormat dateFormat = DateFormat.Hm();
        // print(store['store_time']);
        DateTime zmallOpen = dateFormat.parse("09:00");
        DateTime zmallClose = dateFormat.parse("21:00");
        // DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));

        zmallClose = DateTime(
            now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
        now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

        now.isAfter(zmallClose) || now.isBefore(zmallOpen)
            ? isStoreOpen = false
            : isStoreOpen = true;
      }
      // print("Is store open: $isStoreOpen");
      isOpen.add(isStoreOpen);
    });
  }

  void isLogged() async {
    var data = await Service.readBool('logged');
    if (data != null) {
      // print("Logged in: $data");
      setState(() {
        isLoggedIn = data;
      });
      getUser();
    } else {
      print("No logged user found");
    }
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _loading,
      color: kPrimaryColor,
      progressIndicator: linearProgressIndicator,
      child: stores != null
          ? Column(
              children: [
                !widget.isStore
                    ? Container(
                        color: kPrimaryColor,
                        child: Card(
                          elevation: 0.3,
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Search',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.cancel),
                                      onPressed: () {
                                        controller.clear();
                                        onSearchTextChanged('');
                                        setState(
                                          () {
                                            storeOpen(stores);
                                          },
                                        );
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: onSearchTextChanged,
                          ),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: _searchResult.length != 0 || controller.text.isNotEmpty
                      ? ListView.separated(
                          itemCount: _searchResult.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              child: CustomListTile(
                                press: () {
                                  try {
                                    if (_searchResult[index]['store_count'] >
                                        1) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return GlobalStore(
                                              cityId: widget.cityId,
                                              storeDeliveryId:
                                                  widget.storeDeliveryId,
                                              category: widget.category,
                                              latitude: widget.latitude,
                                              longitude: widget.longitude,
                                              isStore: true,
                                              companyId: _searchResult[index]
                                                  ['company_id'],
                                            );
                                          },
                                        ),
                                      );
                                    } else {
                                      storeClicked(_searchResult[index]);
                                      print(
                                          "=======================PRODUCTS=======================");
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return GlobalProduct(
                                              latitude: widget.latitude,
                                              longitude: widget.longitude,
                                              store: _searchResult[index],
                                              location: _searchResult[index]
                                                  ["location"],
                                              isOpen: isOpen[index],
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    storeClicked(_searchResult[index]);
                                    print(
                                        "=======================PRODUCTS=======================");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return GlobalProduct(
                                            latitude: widget.latitude,
                                            longitude: widget.longitude,
                                            store: _searchResult[index],
                                            location: _searchResult[index]
                                                ["location"],
                                            isOpen: true,
                                          );
                                        },
                                      ),
                                    );
                                  }
                                },
                                store: _searchResult[index],
                                isOpen: isOpen[index],
                                isAbroad: true,
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(
                            height: 2,
                          ),
                        )
                      : ListView.separated(
                          itemCount: stores.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              child: CustomListTile(
                                press: () {
                                  try {
                                    if (stores[index]['store_count'] > 1) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return GlobalStore(
                                              cityId: widget.cityId,
                                              storeDeliveryId:
                                                  widget.storeDeliveryId,
                                              category: widget.category,
                                              latitude: widget.latitude,
                                              longitude: widget.longitude,
                                              isStore: true,
                                              companyId: stores[index]
                                                  ['company_id'],
                                            );
                                          },
                                        ),
                                      );
                                    } else {
                                      storeClicked(stores[index]);
                                      print(
                                          "=======================PRODUCTS=======================");
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return GlobalProduct(
                                              latitude: widget.latitude,
                                              longitude: widget.longitude,
                                              store: stores[index],
                                              location: stores[index]
                                                  ["location"],
                                              isOpen: isOpen[index],
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    storeClicked(stores[index]);
                                    print(
                                        "=======================PRODUCTS=======================");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return GlobalProduct(
                                            latitude: widget.latitude,
                                            longitude: widget.longitude,
                                            store: stores[index],
                                            location: stores[index]["location"],
                                            isOpen: isOpen[index],
                                          );
                                        },
                                      ),
                                    );
                                  }
                                },
                                store: stores[index],
                                isOpen: isOpen[index],
                                isAbroad: true,
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(
                            height: 2,
                          ),
                        ),
                )
              ],
            )
          : !_loading
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding * 4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomButton(
                        title: "Retry",
                        press: () {
                          widget.isStore
                              ? _getStoreListByCompany()
                              : _getCompanyList();
                        },
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                )
              : Container(),
    );
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {
        storeOpen(stores);
      });
      return;
    }

    stores.forEach((store) {
      if (store['name'].toString().toLowerCase().contains(text.toLowerCase())) {
        _searchResult.add(store);
      }
    });

    setState(() {
      storeOpen(_searchResult);
    });
  }

  Future<dynamic> getStoreListByCompany(String cityId, String storeDeliveryId,
      double latitude, double longitude, int companyId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_store_list_by_company";
    Map data = {
      "isGlobal": true,
      "city_id": cityId,
      "store_delivery_id": storeDeliveryId,
      "latitude": latitude,
      "longitude": longitude,
      "company_id": companyId
    };
    var body = json.encode(data);
    // print(body);

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
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // print(e);
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

  Future<dynamic> getCompanyList(String cityId, String storeDeliveryId,
      double latitude, double longitude) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_company_list";
    Map data = {
      "isGlobal": true,
      "city_id": cityId,
      "store_delivery_id": storeDeliveryId,
      "latitude": latitude,
      "longitude": longitude,
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
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
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

  void storeClicked(dynamic store) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/add_user_and_store";
    Map data = {
      "store_id": store['_id'],
      "user_id": store['_id'],
      "latitude": widget.latitude,
      "longitude": widget.longitude,
      "last_opened": DateTime.now().toUtc().add(Duration(hours: 3)).toString(),
      "is_promotional": false
    };
    var body = json.encode(data);
    try {
      http.Response response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      );
      print("Store clicked");
    } catch (e) {
      // print(e);
    }
  }
}
