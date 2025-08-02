import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/controllers/controllers.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_search_bar.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/widgets/shimmer_widget.dart';
import '../store_screen.dart';
import 'custom_list_tile.dart';

class Body extends StatefulWidget {
  Body({
    @required this.cityId,
    @required this.storeDeliveryId,
    @required this.latitude,
    @required this.longitude,
    @required this.isStore,
    @required this.category,
    @required this.companyId,
    this.controller,
    @required this.filterOpenedStore,
    // New callback parameter
    this.onAllClosedChanged,
    this.onSearching,
  });

  final String? cityId, storeDeliveryId;
  final double? longitude, latitude;
  final bool? isStore, filterOpenedStore;
  final category;
  final int? companyId;
  final Controller? controller;
  // Callback to notify parent
  final Function(bool)? onAllClosedChanged;
  final Function(bool)? onSearching;
  @override
  BodyState createState() => BodyState(this.controller!);
}

class BodyState extends State<Body> {
  bool _loading = true;
  var responseData;
  var stores;
  List<bool> isOpen = [];
  TextEditingController controller = TextEditingController();
  List<dynamic> _searchResult = [];
  bool isLoggedIn = false;
  var userData;
  var appOpen;
  var appClose;
  List<dynamic> tagFilters = [];
  List<dynamic> selectedTagFilters = [];

  BodyState(Controller controller) {
    controller.getStores = getElements;
  }

  @override
  void initState() {
    super.initState();
    getAppKeys();
    widget.isStore! ? _getStoreListByCompany() : _getCompanyList();
    isLogged();
  }

  Future<void> _onRefresh() async {
    getAppKeys();
    widget.isStore! ? _getStoreListByCompany() : _getCompanyList();
    isLogged();
  }

  dynamic getElements() {
    if (_loading || stores == null) {
      return null;
    }
    return {
      "stores": (_searchResult.length != 0 || controller.text.isNotEmpty)
          ? _searchResult
          : stores,
      "isOpen": isOpen,
    };
  }

  _getStoreListByCompany() async {
    setState(() {
      _loading = true;
    });

    await getStoreListByCompany(widget.cityId!, widget.storeDeliveryId!,
        widget.latitude!, widget.longitude!, widget.companyId!);

    if (responseData != null && responseData['success']) {
      stores = responseData['stores'];
      storeOpen(stores);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${errorCodes['${responseData['error_code']}']}"),
          ),
        );
      }
    }
    setState(() {
      _loading = false;
    });
  }

  void _getCompanyList() async {
    setState(() {
      _loading = true;
    });
    _getAppKeys();
    await getCompanyList(widget.cityId!, widget.storeDeliveryId!,
        widget.latitude!, widget.longitude!);
    if (responseData != null && responseData['success']) {
      stores = responseData['stores'];

      storeOpen(stores);

      getTags(stores);
      setState(() {
        this._loading = false;
        _notifyAllClosed(); // Notify parent after updating isOpen
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${errorCodes['${responseData['error_code']}']}"),
          ),
        );
      }
    }
    setState(() {
      _loading = false;
    });
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

  void getTags(List stores) {
    tagFilters.clear();
    var storeTags = {};
    stores.forEach((store) {
      var tags = store['famous_products_tags'];
      // var tags = store['store_tags'].toString().split(',');
      tags.forEach((tag) {
        String t = tag.trim().toLowerCase();
        if (storeTags.containsKey(t)) {
          storeTags[t] += 1;
        } else {
          if (t.isNotEmpty && t != "null" && t != "undefined") {
            storeTags[t] = 1;
          }
        }
      });
    });
    storeTags.forEach((key, value) {
      if (value > 0) {
        tagFilters.add(key);
      }
    });
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
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
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
        DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
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
      debugPrint("No logged user found");
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

  void filterUsingTag() {
    _searchResult.clear();
    if (selectedTagFilters.length == 0) {
      controller.text = "";
      setState(() {
        storeOpen(stores);
      });
      return;
    }
    stores.forEach((store) {
      selectedTagFilters.forEach((selectedTag) {
        if (store['famous_products_tags'].contains(selectedTag)) {
          if (!(_searchResult.contains(store))) {
            _searchResult.add(store);
          }
        }
      });
    });
    String filterText = "Filtered with: ";
    selectedTagFilters.forEach((tag) {
      filterText += "$tag, ";
    });
    int x = filterText.lastIndexOf(',');
    filterText = filterText.replaceRange(x, x + 1, "");
    controller.text = filterText;
    setState(() {
      storeOpen(_searchResult);
    });
  }

//////////// Notify parent ////////////////
  void _notifyAllClosed() {
    final allClosed = isOpen.isNotEmpty && !isOpen.any((open) => open);
    widget.onAllClosedChanged?.call(allClosed);
  }

  void _notifyOnSearch() {
    final isSearching = _searchResult.isNotEmpty || controller.text.isNotEmpty;
    widget.onSearching?.call(isSearching);
  }

//////////// Notify parent ////////////////

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: kSecondaryColor,
        onRefresh: _onRefresh,
        child: ModalProgressHUD(
          inAsyncCall: _loading,
          color: kPrimaryColor,
          // progressIndicator: CustomLinearProgressIndicator(
          //   message: "Gathering Stores...",
          // ),
          progressIndicator: stores != null
              ? LinearLoadingIndicator()
              : SingleChildScrollView(
                  child: Column(
                    spacing: getProportionateScreenHeight(kDefaultPadding),
                    children: [
                      SearchButtonShimmer(width: screenWidth * 0.9),
                      Container(
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 5),
                        child: ItemTagShimmer(),
                      ),
                      SizedBox(
                          width: getProportionateScreenHeight(kDefaultPadding)),
                      Container(
                          height: screenHeight * 0.7,
                          child: ProductListShimmer()),
                    ],
                  ),
                ),
          child: stores != null
              ? Column(
                  children: [
                    !widget.isStore!
                        ? CustomSearchBar(
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
                                storeOpen(stores);
                              });
                            })
                        : Container(),
                    // Container(
                    //     color: kPrimaryColor,
                    //     child: Container(
                    //       // color: kPrimaryColor,
                    //       margin: EdgeInsets.all(
                    //         getProportionateScreenWidth(
                    //             kDefaultPadding / 4),
                    //       ),
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: getProportionateScreenWidth(
                    //             kDefaultPadding),
                    //       ),
                    //       decoration: BoxDecoration(
                    //           color: kPrimaryColor,
                    //           border:
                    //               Border.all(color: kWhiteColor, width: 2),
                    //           borderRadius: BorderRadius.circular(
                    //               kDefaultPadding * 2)),
                    //       // child: Card(
                    //       //   elevation: 0.3,
                    //       child: Row(
                    //         mainAxisAlignment:
                    //             MainAxisAlignment.spaceAround,
                    //         children: [
                    //           Icon(
                    //             Icons.search,
                    //             color: controller.text.isNotEmpty
                    //                 ? kSecondaryColor.withValues(alpha: 0.6)
                    //                 : kGreyColor,
                    //           ),
                    //           SizedBox(
                    //               width: getProportionateScreenWidth(
                    //                   kDefaultPadding)),
                    //           Expanded(
                    //             child: TextField(
                    //               controller: controller,
                    //               decoration: InputDecoration(
                    //                 hintText:
                    //                     Provider.of<ZLanguage>(context)
                    //                         .search,
                    //                 border: InputBorder.none,
                    //                 // prefixIcon: Icon(Icons.search),
                    //                 // suffixIcon: controller.text.isNotEmpty
                    //                 //     ? IconButton(
                    //                 //         icon: Icon(Icons.cancel),
                    //                 //         onPressed: () {
                    //                 //           controller.clear();
                    //                 //           onSearchTextChanged('');
                    //                 //           setState(
                    //                 //             () {
                    //                 //               storeOpen(stores);
                    //                 //             },
                    //                 //           );
                    //                 //         },
                    //                 //       )
                    //                 //     : null,
                    //               ),
                    //               onChanged: onSearchTextChanged,
                    //             ),
                    //           ),
                    //           if (controller.text.isNotEmpty)
                    //             IconButton(
                    //               icon: Icon(
                    //                 Icons.cancel,
                    //                 color: kSecondaryColor,
                    //               ),
                    //               onPressed: () {
                    //                 controller.clear();
                    //                 onSearchTextChanged('');
                    //                 setState(
                    //                   () {
                    //                     storeOpen(stores);
                    //                   },
                    //                 );
                    //               },
                    //             ),
                    //         ],
                    //       ),
                    //     ),
                    //   )
                    // : Container(),
                    tagFilters.length != 0
                        ? Container(
                            color: kPrimaryColor,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: kDefaultPadding * 0.4,
                                vertical: kDefaultPadding * 0.5,
                              ),
                              // padding: EdgeInsets.only(
                              //   left: kDefaultPadding * 0.4,
                              //   right: kDefaultPadding * 0.4,
                              //   bottom: kDefaultPadding * 0.4,

                              // ),
                              child: Container(
                                height: getProportionateScreenHeight(
                                    kDefaultPadding * 2),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: tagFilters.length,
                                  itemBuilder: (context, index) {
                                    bool isSelected = selectedTagFilters
                                        .contains(tagFilters[index]);
                                    return InkWell(
                                      onTap: () {
                                        if (isSelected) {
                                          selectedTagFilters
                                              .remove(tagFilters[index]);
                                        } else {
                                          selectedTagFilters
                                              .add(tagFilters[index]);
                                        }
                                        filterUsingTag();
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? kSecondaryColor.withValues(
                                                  alpha: 0.3)
                                              : kPrimaryColor,
                                          borderRadius: BorderRadius.circular(
                                            getProportionateScreenWidth(
                                                kDefaultPadding / 2),
                                          ),
                                          border: Border.all(
                                            width: isSelected ? 1.0 : 2.0,
                                            color: isSelected
                                                ? kSecondaryColor.withValues(
                                                    alpha: 0.6)
                                                : kWhiteColor,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal:
                                                getProportionateScreenWidth(
                                                    kDefaultPadding / 2)),
                                        child: Row(
                                          children: [
                                            Text(
                                              Service.capitalizeFirstLetters(
                                                  tagFilters[index].toString()),
                                              // .toUpperCase(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? kSecondaryColor
                                                        : kBlackColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          SizedBox(
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding / 2),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    Expanded(
                      child:
                          _searchResult.isNotEmpty || controller.text.isNotEmpty
                              ? _buildSearchList()
                              : _buildStoreList(),
                    ),
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
                              widget.isStore!
                                  ? _getStoreListByCompany()
                                  : _getCompanyList();
                            },
                            color: kSecondaryColor,
                          ),
                        ],
                      ),
                    )
                  : Container(),
        ),
      ),
    );
  }

//////////////////////////newly added
  Widget _buildStoreList() {
    final allClosed = isOpen.isNotEmpty && !isOpen.any((open) => open);
    return ListView.builder(
      itemCount: stores.length,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      itemBuilder: (context, index) {
        if (widget.filterOpenedStore == true && !allClosed) {
          return isOpen[index]
              ? Column(
                  children: [
                    StoreLists(index: index),
                    SizedBox(height: kDefaultPadding / 4),
                  ],
                )
              : const SizedBox();
        } else {
          return Column(
            children: [
              StoreLists(index: index),
              SizedBox(height: kDefaultPadding / 4),
            ],
          );
        }
      },
    );
  }

  Widget _buildSearchList() {
    return ListView.separated(
      itemCount: _searchResult.length,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      separatorBuilder: (context, index) => Container(
        height: kDefaultPadding / 4,
        color: kWhiteColor,
      ),
      itemBuilder: (context, index) {
        return Container(
          child: CustomListTile(
            press: () {
              try {
                if (_searchResult[index]['store_count'] > 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return StoreScreen(
                          cityId: widget.cityId,
                          storeDeliveryId: widget.storeDeliveryId,
                          category: widget.category,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                          isStore: true,
                          companyId: _searchResult[index]['company_id'],
                        );
                      },
                    ),
                  );
                } else {
                  if (isLoggedIn) {
                    storeClicked(_searchResult[index]);
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ProductScreen(
                          latitude: widget.latitude!,
                          longitude: widget.longitude!,
                          store: _searchResult[index],
                          location: _searchResult[index]["location"],
                          isOpen: isOpen[index],
                        );
                      },
                    ),
                  );
                }
              } catch (e) {
                if (isLoggedIn) {
                  storeClicked(_searchResult[index]);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ProductScreen(
                        latitude: widget.latitude!,
                        longitude: widget.longitude!,
                        store: _searchResult[index],
                        location: _searchResult[index]["location"],
                        isOpen: true,
                      );
                    },
                  ),
                );
              }
            },
            store: _searchResult[index],
            isOpen: isOpen[index],
          ),
        );
      },
    );
  }

  Widget StoreLists({required int index}) {
    return Container(
      child: CustomListTile(
        press: () {
          debugPrint("Navigate to store....");
          try {
            if (stores[index]['store_count'] > 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return StoreScreen(
                      cityId: widget.cityId,
                      storeDeliveryId: widget.storeDeliveryId,
                      category: widget.category,
                      latitude: widget.latitude,
                      longitude: widget.longitude,
                      isStore: true,
                      companyId: stores[index]['company_id'],
                    );
                  },
                ),
              );
            } else {
              if (isLoggedIn) {
                storeClicked(stores[index]);
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ProductScreen(
                      latitude: widget.latitude!,
                      longitude: widget.longitude!,
                      store: stores[index],
                      location: stores[index]["location"],
                      isOpen: isOpen[index],
                    );
                  },
                ),
              );
            }
          } catch (e) {
            if (isLoggedIn) {
              storeClicked(stores[index]);
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ProductScreen(
                    latitude: widget.latitude!,
                    longitude: widget.longitude!,
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
      ),
    );
  }

///////////////////////////////////////
  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      selectedTagFilters.clear();
      setState(() {
        storeOpen(stores);
        _notifyOnSearch();
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
      _notifyOnSearch();
    });
  }

  Future<dynamic> getStoreListByCompany(String cityId, String storeDeliveryId,
      double latitude, double longitude, int companyId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_store_list_by_company";
    Map data = {
      "city_id": cityId,
      "store_delivery_id": storeDeliveryId,
      "latitude": latitude,
      "longitude": longitude,
      "company_id": companyId
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
        Duration(seconds: 15),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              Service.showMessage(
                  "Something went wrong! Check your internet and try again",
                  true,
                  duration: 3),
            );
          }

          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.responseData = json.decode(response.body);
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      setState(() {
        this._loading = false;
      });

      return null;
    }
  }

  Future<dynamic> getCompanyList(String cityId, String storeDeliveryId,
      double latitude, double longitude) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_company_list";

    Map data = {
      "city_id": cityId,
      "store_delivery_id": storeDeliveryId,
      "latitude": latitude,
      "longitude": longitude,
    };
    var body = json.encode(data);
    // print("body $body");
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
        Duration(seconds: 15),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Something went wrong! Check your internet and try again"),
                backgroundColor: kSecondaryColor,
              ),
            );
          }
          throw TimeoutException("The connection has timed out!");
        },
      );

      setState(() {
        this.responseData = json.decode(response.body);
      });

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      setState(() {
        this._loading = false;
      });

      return null;
    }
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
      http.Response response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      );
      debugPrint("Store clicked");
    } catch (e) {
      // debugPrint(e);
    }
  }
}
