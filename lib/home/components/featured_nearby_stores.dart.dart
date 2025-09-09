import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/custom_list_tile.dart';
import 'package:zmall/widgets/custom_back_button.dart';
import 'package:zmall/widgets/custom_search_bar.dart';
import 'package:zmall/widgets/shimmer_widget.dart';

class NearbyStoresScreen extends StatefulWidget {
  final List<dynamic> storesList;
  final double? longitude, latitude;
  final bool isPromotional;

  NearbyStoresScreen({
    this.isPromotional = false,
    this.longitude,
    this.latitude,
    required this.storesList,
  });

  @override
  State<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends State<NearbyStoresScreen> {
  TextEditingController controller = TextEditingController();
  bool _loading = true;
  var responseData;
  List<dynamic> storesList = [];
  List<dynamic> _searchResult = [];
  List<bool> isOpen = [];
  bool isLoggedIn = false;
  var userData;
  var appOpen;
  var appClose;

  @override
  void initState() {
    super.initState();
    storesList = widget.storesList;
    getAppKeys();
    isLogged();
  }

  Future<void> _onRefresh() async {
    storesList = widget.storesList;
    getAppKeys();
    isLogged();
  }

  void getAppKeys() async {
    var appKeys = await CoreServices.appKeys(context);
    if (appKeys != null && appKeys['success']) {
      setState(() {
        appClose = appKeys['app_close'];
        appOpen = appKeys['app_open'];
        Service.save("app_close", appClose);
        Service.save("app_open", appOpen);
      });
    } else {
      appClose = await Service.read('app_close');
      appOpen = await Service.read('app_open');
    }
  }

  void _getAppKeys() async {
    var data = await CoreServices.appKeys(context);
    if (data != null && data['success']) {
      setState(() {
        Service.saveBool("is_closed", data['message_flag']);
        Service.save("closed_message", data['message']);
        Service.save("ios_app_version", data['ios_user_app_version_code']);
        Service.saveBool(
            "ios_update_dialog", data['is_ios_user_app_open_update_dialog']);
        Service.saveBool(
            "ios_force_update", data['is_ios_user_app_force_update']);
        Service.save('app_close', data['app_close']);
        Service.save('app_open', data['app_open']);
        appOpen = data['app_open'];
        appClose = data['app_close'];
      });
    } else {
      getAppKeys();
    }
  }

  void storeOpen(List stores) async {
    isOpen.clear();
    DateFormat dateFormat = new DateFormat.Hm();
    // DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
    DateTime now = DateTime.now().toUtc();
    if (appOpen == null || appClose == null) {
      appOpen = await Service.read('app_open');
      appClose = await Service.read('app_close');
    }

    DateTime zmallOpen = dateFormat.parse(appOpen);
    DateTime zmallClose = dateFormat.parse(appClose);

    zmallOpen = new DateTime(
        now.year, now.month, now.day, zmallOpen.hour, zmallOpen.minute);
    zmallClose = new DateTime(
        now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);

    stores.forEach((store) {
      bool isStoreOpen = false;
      if (store['store_time'] != null && store['store_time'].length != 0) {
        for (var i = 0; i < store['store_time'].length; i++) {
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
                    now.isAfter(zmallOpen) &&
                    now.isBefore(close) &&
                    store['store_time'][i]['is_store_open'] &&
                    now.isBefore(zmallClose)) {
                  isStoreOpen = true;
                  break;
                } else {
                  isStoreOpen = false;
                }
              }
            } else {
              // DateTime zmallOpen = dateFormat.parse(appOpen);
              // DateTime zmallClose = dateFormat.parse(appClose);
              // zmallOpen = new DateTime(now.year, now.month, now.day,
              //     zmallOpen.hour, zmallOpen.minute);
              // zmallClose = new DateTime(now.year, now.month, now.day,
              //     zmallClose.hour, zmallClose.minute);
              if (now.isAfter(zmallOpen) &&
                  now.isBefore(zmallClose) &&
                  store['store_time'][i]['is_store_open']) {
                isStoreOpen = true;
              } else {
                isStoreOpen = false;
              }
            }
          }
        }
      } else {
        // DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
        DateTime now = DateTime.now().toUtc();
        DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
        DateFormat dateFormat = DateFormat.Hm();
        if (appClose != null) {
          zmallClose = dateFormat.parse(appClose);
        }

        zmallClose = DateTime(
            now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
        now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

        now.isAfter(zmallClose) ? isStoreOpen = false : isStoreOpen = true;
      }
      isOpen.add(isStoreOpen);
    });
  }

  void isLogged() async {
    var data = await Service.readBool('logged');
    if (data != null) {
      setState(() {
        isLoggedIn = data;
      });
      getUser();
    } else {
      // print("No logged user found");
    }
    storeOpen(storesList);
    _getAppKeys();
    setState(() {
      _loading = false;
    });
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
        _loading = false;
      });
    }
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {
        storeOpen(storesList);
      });
      return;
    }

    storesList.forEach((store) {
      if (store['name'].toString().toLowerCase().contains(text.toLowerCase())) {
        _searchResult.add(store);
      }
    });

    setState(() {
      storeOpen(_searchResult);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.isPromotional ? "Featured Stores" : "Nearby Stores"),
          leading: CustomBackButton(),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: kPrimaryColor,
            backgroundColor: kSecondaryColor,
            onRefresh: _onRefresh,
            child: ModalProgressHUD(
              inAsyncCall: _loading,
              color: kPrimaryColor,
              progressIndicator: ProductListShimmer(),
              child: storesList.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomSearchBar(
                            controller: controller,
                            hintText: Provider.of<ZLanguage>(context).search,
                            onChanged: onSearchTextChanged,
                            onSubmitted: (value) {
                              onSearchTextChanged(value);
                            },
                            onClearButtonTap: () {
                              controller.clear();
                              onSearchTextChanged('');
                              setState(() {
                                storeOpen(storesList);
                              });
                            }),
                        _searchResult.isNotEmpty || controller.text.isNotEmpty
                            ? _buildSearchList()
                            : Expanded(
                                child: ListView.separated(
                                  itemCount: storesList.length,
                                  padding:
                                      const EdgeInsets.all(kDefaultPadding / 2),
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 2)),
                                  itemBuilder: (context, index) {
                                    String featuredTag = storesList[index]
                                            ['promo_tags']
                                        .toString()
                                        .toLowerCase();

                                    if (widget.isPromotional) {
                                      return Stack(
                                        children: [
                                          StoreLists(
                                              index: index,
                                              isFromPromotional: true,
                                              featuredTag: storesList[index]
                                                      ['promo_tags']
                                                  .toString()
                                                  .toLowerCase()),
                                          if (widget.isPromotional)
                                            Positioned(
                                              right: 2,
                                              top: -2,
                                              child: Container(
                                                height:
                                                    getProportionateScreenWidth(
                                                        kDefaultPadding * 4),
                                                width:
                                                    getProportionateScreenWidth(
                                                        kDefaultPadding * 4),
                                                child: Center(
                                                    child: Image.asset(
                                                        "images/store_tags/$featuredTag.png")),
                                              ),
                                            )
                                        ],
                                      );
                                    } else {
                                      return StoreLists(
                                          index: index,
                                          featuredTag: storesList[index]
                                                  ['promo_tags']
                                              .toString()
                                              .toLowerCase());
                                    }
                                  },
                                ),
                              ),
                      ],
                    )
                  : !_loading
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(
                                kDefaultPadding * 4),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomButton(
                                  title: "Retry",
                                  press: () {
                                    _onRefresh();
                                  },
                                  color: kSecondaryColor,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(),
            ),
          ),
        ),
      ),
    );
  }

//////////////////////////newly added

  Widget StoreLists({
    required int index,
    required String featuredTag,
    bool? isFromPromotional,
  }) {
    bool storeIsOpen = isOpen.length > index ? isOpen[index] : false;
    return Container(
      child: CustomListTile(
        isFromPromotional: isFromPromotional,
        press: () {
          // print("Navigate to store....");
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ProductScreen(
                    latitude: widget.latitude!,
                    longitude: widget.longitude!,
                    store: storesList[index],
                    location: storesList[index]["location"],
                    isOpen: storeIsOpen,
                  );
                },
              ),
            );
          } catch (e) {
            if (isLoggedIn) {
              storeClicked(storesList[index]);
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ProductScreen(
                    latitude: widget.latitude!,
                    longitude: widget.longitude!,
                    store: storesList[index],
                    location: storesList[index]["location"],
                    isOpen: storeIsOpen,
                  );
                },
              ),
            );
          }
        },
        store: storesList[index],
        isOpen: storeIsOpen,
      ),
    );
  }

  Widget SearchStoreLists({required dynamic store, required bool isOpen}) {
    String featuredTag = store['promo_tags'].toString().toLowerCase();

    if (widget.isPromotional) {
      return Stack(
        children: [
          Container(
            child: CustomListTile(
              isFromPromotional: true,
              press: () {
                // print("Navigate to store....");
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ProductScreen(
                          latitude: widget.latitude!,
                          longitude: widget.longitude!,
                          store: store,
                          location: store["location"],
                          isOpen: isOpen,
                        );
                      },
                    ),
                  );
                } catch (e) {
                  if (isLoggedIn) {
                    storeClicked(store);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ProductScreen(
                          latitude: widget.latitude!,
                          longitude: widget.longitude!,
                          store: store,
                          location: store["location"],
                          isOpen: isOpen,
                        );
                      },
                    ),
                  );
                }
              },
              store: store,
              isOpen: isOpen,
            ),
          ),
          Positioned(
            right: 2,
            top: -2,
            child: Container(
              height: getProportionateScreenWidth(kDefaultPadding * 4),
              width: getProportionateScreenWidth(kDefaultPadding * 4),
              child: Center(
                  child: Image.asset("images/store_tags/$featuredTag.png")),
            ),
          )
        ],
      );
    } else {
      return Container(
        child: CustomListTile(
          press: () {
            // print("Navigate to store....");
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ProductScreen(
                      latitude: widget.latitude!,
                      longitude: widget.longitude!,
                      store: store,
                      location: store["location"],
                      isOpen: isOpen,
                    );
                  },
                ),
              );
            } catch (e) {
              if (isLoggedIn) {
                storeClicked(store);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ProductScreen(
                      latitude: widget.latitude!,
                      longitude: widget.longitude!,
                      store: store,
                      location: store["location"],
                      isOpen: isOpen,
                    );
                  },
                ),
              );
            }
          },
          store: store,
          isOpen: isOpen,
        ),
      );
    }
  }

  Widget _buildSearchList() {
    return Expanded(
      child: ListView.separated(
        itemCount: _searchResult.length,
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        separatorBuilder: (context, index) => Container(
          height: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        itemBuilder: (context, index) {
          return SearchStoreLists(
            store: _searchResult[index],
            isOpen: isOpen.length > index ? isOpen[index] : false,
          );
        },
      ),
    );
  }

  void storeClicked(dynamic store) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/add_user_and_store";
    Map data = {
      "store_id": store['_id'],
      "user_id": userData['user']['_id'],
      "latitude": widget.latitude,
      "longitude": widget.longitude,
      "last_opened": "2020-04-17T06:45:55.873Z",
      "is_promotional": false
    };
    var body = json.encode(data);
    try {
      await http.post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      );
      // print("Store clicked");
    } catch (e) {
      // print(e);
    }
  }
}
