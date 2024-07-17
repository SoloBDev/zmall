import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    Key? key,
    @required this.cityId,
    @required this.categories,
    @required this.latitude,
    @required this.longitude,
  }) : super(key: key);
  final String? cityId;
  final categories;
  final double? latitude, longitude;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "";
  bool _loading = false;
  var responseData;
  var filteredResult = {'items': []};
  List<bool> isOpen = [];
  final _controller = TextEditingController();
  var selectedPriceRange = RangeValues(0.0, 1000);
  bool isFiltered = false;
  int maxPrice = 1000;
  /////new
  bool isStoreSelected = false;
  bool isCatagorySelected = false;
  var storeDeliveryId;
  var selectedCatagory = 0;
  List<dynamic> _searchResult = [];
  List<dynamic> stores = [];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getAppKeys() async {
    var appKeys = await CoreServices.appKeys(context);
    if (appKeys != null && appKeys['success']) {
      setState(() {
        Service.save("app_close", appKeys['app_close']);
        Service.save("app_open", appKeys['app_open']);
      });
    }
  }

  void _searchItem({String? query}) async {
    setState(() {
      _loading = true;
      isFiltered = false;
      filteredResult['items'] = [];
    });
    getAppKeys();
    var data = await searchItem(query);
    if (data != null && data['success']) {
      int max = 0;
      for (int i = 0; i < data['items'].length; i++) {
        try {
          if (max < data['items'][i]['price']) {
            max = data['items'][i]['price'];
          }
        } catch (e) {
          continue;
        }
      }
      max += 50;
      setState(() {
        _loading = false;
        responseData = data;
        maxPrice = max;
        selectedPriceRange = RangeValues(0.00, double.parse(max.toString()));
      });
      storeOpen(data['items']);
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));

      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  void storeOpen(List stores) async {
    var appClose = await Service.read('app_close');
    var appOpen = await Service.read('app_open');
    isOpen.clear();
    stores.forEach((store) {
      bool isStoreOpen = false;
      if (store['store_open_close_time'] != null &&
          store['store_open_close_time'].length != 0) {
        for (var i = 0; i < store['store_open_close_time'].length; i++) {
          DateFormat dateFormat = new DateFormat.Hm();
          DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
          int weekday;
          if (now.weekday == 7) {
            weekday = 0;
          } else {
            weekday = now.weekday;
          }

          if (store['store_open_close_time'][i]['day'] == weekday) {
            if (store['store_open_close_time'][i]['day_time'].length != 0 &&
                store['store_open_close_time'][i]['is_store_open']) {
              for (var j = 0;
                  j < store['store_open_close_time'][i]['day_time'].length;
                  j++) {
                DateTime open = dateFormat.parse(store['store_open_close_time']
                    [i]['day_time'][j]['store_open_time']);
                open = new DateTime(
                    now.year, now.month, now.day, open.hour, open.minute);
                DateTime close = dateFormat.parse(store['store_open_close_time']
                    [i]['day_time'][j]['store_close_time']);
                // print(appClose);
                // DateTime close = dateFormat.parse(appClose);
                close = new DateTime(
                    now.year, now.month, now.day, close.hour, close.minute);
                now = DateTime(
                    now.year, now.month, now.day, now.hour, now.minute);
                // DateTime zmallClose =
                //     DateTime(now.year, now.month, now.day, 21, 00);
                // DateTime zmallOpen =
                //     DateTime(now.year, now.month, now.day, 09, 00);
                // if (appClose != null && appOpen != null) {
                DateTime zmallOpen = dateFormat.parse(appOpen);
                DateTime zmallClose = dateFormat.parse(appClose);
                // }
                zmallOpen = new DateTime(now.year, now.month, now.day,
                    zmallOpen.hour, zmallOpen.minute);
                zmallClose = new DateTime(now.year, now.month, now.day,
                    zmallClose.hour, zmallClose.minute);
                if (now.isAfter(open) &&
                    now.isAfter(zmallOpen) &&
                    now.isBefore(close) &&
                    store['store_open_close_time'][i]['is_store_open'] &&
                    now.isBefore(zmallClose)) {
                  isStoreOpen = true;
                  break;
                } else {
                  isStoreOpen = false;
                }
              }
            } else {
              // DateTime zmallClose =
              //     DateTime(now.year, now.month, now.day, 21, 00);
              // DateTime zmallOpen =
              //     DateTime(now.year, now.month, now.day, 09, 00);
              // if (appOpen != null && appClose != null) {
              DateTime zmallOpen = dateFormat.parse(appOpen);
              DateTime zmallClose = dateFormat.parse(appClose);
              // }
              zmallOpen = new DateTime(now.year, now.month, now.day,
                  zmallOpen.hour, zmallOpen.minute);
              zmallClose = new DateTime(now.year, now.month, now.day,
                  zmallClose.hour, zmallClose.minute);
              if (now.isAfter(zmallOpen) &&
                  now.isBefore(zmallClose) &&
                  store['store_open_close_time'][i]['is_store_open']) {
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

  void filterPrice() {
    List results = [];
    for (int i = 0; i < responseData['items'].length; i++) {
      try {
        if (responseData['items'][i]['price'] > selectedPriceRange.start &&
            responseData['items'][i]['price'] < selectedPriceRange.end) {
          results.add(responseData['items'][i]);
        }
      } catch (e) {
        continue;
      }
    }
    setState(() {
      filteredResult['items'] = results;
      storeOpen(results);
    });
  }

////////////////////////////////////////////////////////////////////////////////

  void _getCompanyList() async {
    getAppKeys();
    var data = await getCompanyList();
    if (data != null && data['success']) {
      stores = data['stores'];
      print(stores);
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
  }

/////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: Text(
          Provider.of<ZLanguage>(context).search,
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 0.4,
        actions: [
          Visibility(
            visible: !isStoreSelected,
            child: TextButton(
              onPressed: () {
                if (responseData != null) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            backgroundColor: kPrimaryColor,
                            title: Text(
                                Provider.of<ZLanguage>(context).priceFilter),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RangeSlider(
                                  values: selectedPriceRange,
                                  onChanged: (RangeValues val) {
                                    setState(() => selectedPriceRange = val);
                                  },
                                  min: 0.0,
                                  max: double.parse(maxPrice.toString()),
                                  divisions: 20,
                                  labels: RangeLabels(
                                      '${selectedPriceRange.start}',
                                      '${selectedPriceRange.end}'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                child: Text(
                                  Provider.of<ZLanguage>(context).cancel,
                                  style: TextStyle(color: kBlackColor),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isFiltered = false;
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text(
                                  Provider.of<ZLanguage>(context).filter,
                                  style: TextStyle(
                                    color: kSecondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isFiltered = true;
                                  });
                                  filterPrice();
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        });
                      });
                }
              },
              child: Text(
                Provider.of<ZLanguage>(context).filter,
                style: TextStyle(color: kBlackColor),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: kDefaultPadding),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isStoreSelected = !isStoreSelected;
                  storeDeliveryId = widget.categories[0]['_id'];
                  _getCompanyList();
                });
              },
              child: Container(
                  padding: const EdgeInsets.all(kDefaultPadding / 3),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(kDefaultPadding * 0.666),
                    border: Border.all(color: Colors.grey.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 1,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isStoreSelected ? 'Items' : 'Stores',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )),
            ),
          ),
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        progressIndicator: linearProgressIndicator,
        color: kPrimaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(
              // horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
              // vertical: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
          child: Column(
            children: [
              Form(
                child: TextFormField(
                  controller: _controller,
                  onChanged: (value) {
                    // print(value);
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                    if (searchQuery.isNotEmpty) {
                      onSearchTextChanged(query: searchQuery);
                      _searchItem(query: searchQuery);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: searchQuery == ''
                        ? Provider.of<ZLanguage>(context).searchEngine
                        : searchQuery,
                    filled: true,
                    fillColor: kPrimaryColor,
                    border: outlineInputBorder(),
                    enabledBorder: outlineInputBorder(),
                    focusedBorder: outlineInputBorder(),
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: kSecondaryColor,
                      size: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    suffixIcon: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding / 4),
                      ),
                      child: FocusScope.of(context).hasFocus
                          ? IconButton(
                              tooltip: 'Clear',
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                  onSearchTextChanged(query: '');
                                });
                                _controller.clear();
                              },
                            )
                          : IconButton(
                              tooltip: 'Search',
                              icon: Icon(Icons.search),
                              onPressed: () {
                                if (searchQuery.isNotEmpty) {
                                  onSearchTextChanged(query: searchQuery);
                                  _searchItem(query: searchQuery);
                                } else {
                                  FocusScope.of(context).requestFocus();
                                  // FocusScope.of(context).previousFocus();
                                }
                              },
                            ),
                    ),
                  ),
                ),
              ),
              isStoreSelected && widget.categories.length != 0
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: kDefaultPadding * 0.4,
                        right: kDefaultPadding * 0.4,
                        bottom: kDefaultPadding * 0.4,
                      ),
                      child: Container(
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 1.5),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.categories.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                _searchResult.clear;

                                setState(() {
                                  storeDeliveryId =
                                      widget.categories[index]['_id'];
                                  isCatagorySelected = true;
                                  selectedCatagory = index;
                                });
                                _getCompanyList();
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isStoreSelected &&
                                          selectedCatagory == index
                                      ? kSecondaryColor
                                      : kPrimaryColor,
                                  borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding / 8),
                                  ),
                                  border: Border.all(
                                    width: 1.0,
                                    color: isStoreSelected &&
                                            selectedCatagory == index
                                        ? kSecondaryColor.withOpacity(0.6)
                                        : kBlackColor.withOpacity(0.4),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(
                                        kDefaultPadding / 2)),
                                child: Row(
                                  children: [
                                    Text(
                                      widget.categories[index]['delivery_name']
                                          .toString()
                                          .toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: isStoreSelected &&
                                                    selectedCatagory == index
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isStoreSelected &&
                                                    selectedCatagory == index
                                                ? kPrimaryColor
                                                : kBlackColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              SizedBox(
                            width: getProportionateScreenWidth(
                                kDefaultPadding / 5),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),

              // SizedBox(
              //     height: getProportionateScreenHeight(kDefaultPadding / 5)),
              _loading
                  ? Expanded(
                      child: ListView.separated(
                        itemBuilder: (context, index) => Column(
                          children: [
                            // index == 0
                            //     ? SizedBox(
                            //         height: getProportionateScreenHeight(
                            //             kDefaultPadding / 2))
                            //     : Container(),
                            ShimmerSkeleton(),
                          ],
                        ),
                        separatorBuilder: (context, index) => const SizedBox(
                          height: 10,
                        ),
                        itemCount: 5,
                      ),
                    )
                  : !isStoreSelected
                      ? (filteredResult != null &&
                              filteredResult['items']!.length > 0)
                          ? Expanded(
                              child: ListView.separated(
                                itemBuilder: (context, index) => Column(
                                  children: [
                                    // index == 0
                                    //     ? SizedBox(
                                    //         height: getProportionateScreenHeight(
                                    //             kDefaultPadding / 2))
                                    //     : Container(),
                                    GestureDetector(
                                      onTap: () {
                                        if (isOpen[index]) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return ItemScreen(
                                                    item: filteredResult[
                                                        'items']![index],
                                                    location: filteredResult[
                                                            'items']![index]
                                                        ['store_location']);
                                              },
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            Service.showMessage(
                                                "Sorry, store is currently closed. Please comeback soon.",
                                                false,
                                                duration: 3),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          // borderRadius: BorderRadius.all(
                                          //   Radius.circular(
                                          //     getProportionateScreenWidth(
                                          //         kDefaultPadding * .75),
                                          //   ),
                                          // ),
                                        ),
                                        child: Row(
                                          children: [
                                            SearchImageContainer(
                                              url: filteredResult['items']![
                                                                  index]
                                                              ['image_url']
                                                          .length >
                                                      0
                                                  ? "http://159.65.147.111:8000/${filteredResult['items']![index]['image_url'][0]}"
                                                  : "https://ibb.co/vkhzjd6",
                                            ),
                                            SizedBox(
                                              width:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 2),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    filteredResult['items']![
                                                        index]['store_name'],
                                                    style: TextStyle(
                                                      fontSize:
                                                          getProportionateScreenWidth(
                                                              kDefaultPadding /
                                                                  1.7),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      // color: kBlackColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    filteredResult['items']![
                                                        index]['name'],
                                                    style: TextStyle(
                                                      fontSize:
                                                          getProportionateScreenWidth(
                                                              kDefaultPadding /
                                                                  1.3),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      // color: kBlackColor,
                                                    ),
                                                  ),
                                                  filteredResult['items']![
                                                              index]['details']
                                                          .toString()
                                                          .isNotEmpty
                                                      ? Text(
                                                          filteredResult['items']![
                                                                      index]
                                                                  ['details']
                                                              .toString()
                                                              .toLowerCase(),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color:
                                                                        kGreyColor,
                                                                  ),
                                                        )
                                                      : Container(),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "${filteredResult['items']![index]['price'].toString()} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                                        style: TextStyle(
                                                          fontSize:
                                                              getProportionateScreenWidth(
                                                                  kDefaultPadding /
                                                                      1.5),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: kGreyColor,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(
                                                            horizontal:
                                                                getProportionateScreenHeight(
                                                                    kDefaultPadding /
                                                                        2)),
                                                        child: Text(
                                                          "${(filteredResult['items']![index]['similarity'] * 100).toInt().toString()}% ${Provider.of<ZLanguage>(context).match}",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color: (filteredResult['items']![index]['similarity'] * 100).toInt() >
                                                                            90
                                                                        ? Colors
                                                                            .green
                                                                        : (filteredResult['items']![index]['similarity'] * 100).toInt() >
                                                                                70
                                                                            ? Colors.orange
                                                                            : (filteredResult['items']![index]['similarity'] * 100).toInt() > 50
                                                                                ? kSecondaryColor
                                                                                : kGreyColor,
                                                                  ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    isOpen[index]
                                                        ? Provider.of<
                                                                    ZLanguage>(
                                                                context)
                                                            .open
                                                        : Provider.of<
                                                                    ZLanguage>(
                                                                context)
                                                            .closed,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isOpen[index]
                                                                ? Colors.green
                                                                : kSecondaryColor),
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 1),
                                itemCount: filteredResult['items']!.length,
                              ),
                            )
                          : isFiltered
                              ? Center(
                                  child: Text(
                                    "\n\n\n\n${Provider.of<ZLanguage>(context).nothingFound}",
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : responseData != null &&
                                      responseData['success'] &&
                                      responseData['items'].length > 0
                                  ? Expanded(
                                      child: ListView.separated(
                                        itemBuilder: (context, index) => Column(
                                          children: [
                                            // index == 0
                                            //     ? SizedBox(
                                            //         height:
                                            //             getProportionateScreenHeight(
                                            //                 kDefaultPadding / 2))
                                            //     : Container(),
                                            GestureDetector(
                                              onTap: () {
                                                if (isOpen[index]) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return ItemScreen(
                                                            item: responseData[
                                                                'items'][index],
                                                            location: responseData[
                                                                        'items']
                                                                    [index][
                                                                'store_location']);
                                                      },
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    Service.showMessage(
                                                        "Sorry, store is currently closed. Please comeback soon.",
                                                        false,
                                                        duration: 3),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: kPrimaryColor,
                                                  // borderRadius: BorderRadius.all(
                                                  //   Radius.circular(
                                                  //     getProportionateScreenWidth(
                                                  //         kDefaultPadding * .75),
                                                  //   ),
                                                  // ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          getProportionateScreenWidth(
                                                              kDefaultPadding /
                                                                  2),
                                                    ),
                                                    SearchImageContainer(
                                                      url: responseData['items']
                                                                          [
                                                                          index]
                                                                      [
                                                                      'image_url']
                                                                  .length >
                                                              0
                                                          ? "http://159.65.147.111:8000/${responseData['items'][index]['image_url'][0]}"
                                                          : "https://ibb.co/vkhzjd6",
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          getProportionateScreenWidth(
                                                              kDefaultPadding /
                                                                  2),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(
                                                            height: getProportionateScreenWidth(
                                                                kDefaultPadding /
                                                                    3),
                                                          ),
                                                          Text(
                                                            responseData[
                                                                        'items']
                                                                    [index]
                                                                ['store_name'],
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(),
                                                          ),
                                                          SizedBox(
                                                            height: getProportionateScreenWidth(
                                                                kDefaultPadding /
                                                                    5),
                                                          ),
                                                          Text(
                                                              responseData[
                                                                          'items']
                                                                      [index]
                                                                  ['name'],
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600)),
                                                          // responseData['items']
                                                          //                 [index]
                                                          //             ['details']
                                                          //         .toString()
                                                          //         .isNotEmpty
                                                          //     ? Padding(
                                                          //         padding: EdgeInsets
                                                          //             .only(
                                                          //                 right:
                                                          //                     8.0),
                                                          //         child: Text(
                                                          //           responseData['items']
                                                          //                       [
                                                          //                       index]
                                                          //                   [
                                                          //                   'details']
                                                          //               .toString()
                                                          //               .toLowerCase(),
                                                          //           style: Theme.of(
                                                          //                   context)
                                                          //               .textTheme
                                                          //               .bodySmall
                                                          //               ?.copyWith(
                                                          //                 color:
                                                          //                     kGreyColor,
                                                          //               ),
                                                          //         ),
                                                          //       )
                                                          //     : Container(),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                "${responseData['items'][index]['price'].toString()} ${Provider.of<ZMetaData>(context, listen: false).currency}",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: getProportionateScreenWidth(
                                                                      kDefaultPadding /
                                                                          1.5),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      kGreyColor,
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: EdgeInsets.symmetric(
                                                                    horizontal: getProportionateScreenHeight(
                                                                        kDefaultPadding /
                                                                            2)),
                                                                child: Text(
                                                                  "${(responseData['items'][index]['similarity'] * 100).toInt().toString()}% ${Provider.of<ZLanguage>(context).match}",
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        color: (responseData['items'][index]['similarity'] * 100).toInt() >
                                                                                90
                                                                            ? Colors.green
                                                                            : (responseData['items'][index]['similarity'] * 100).toInt() > 70
                                                                                ? Colors.orange
                                                                                : (responseData['items'][index]['similarity'] * 100).toInt() > 50
                                                                                    ? kSecondaryColor
                                                                                    : kGreyColor,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            isOpen[index]
                                                                ? Provider.of<
                                                                            ZLanguage>(
                                                                        context)
                                                                    .open
                                                                : Provider.of<
                                                                            ZLanguage>(
                                                                        context)
                                                                    .closed,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: isOpen[
                                                                            index]
                                                                        ? Colors
                                                                            .green
                                                                        : kSecondaryColor),
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        separatorBuilder: (context, index) =>
                                            SizedBox(height: 1),
                                        itemCount: responseData['items'].length,
                                      ),
                                    )
                                  : searchQuery == ''
                                      ? Center(
                                          child: Text(
                                            "\n\n\n\n${Provider.of<ZLanguage>(context).whatShould}",
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            "\n\n\n\n${Provider.of<ZLanguage>(context).nothingFound}",
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                      :
                      ///////////////////////////////
                      _controller.text.isEmpty
                          ? Center(
                              child: Text(
                                "\n\n\n\n${Provider.of<ZLanguage>(context).whatShould}",
                                textAlign: TextAlign.center,
                              ),
                            )
                          : _searchResult.length != 0 && selectedCatagory != -1
                              ? Expanded(
                                  child: ListView.separated(
                                    itemCount: _searchResult.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return SearchLists(index: index);

                                      /////////////////
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            SizedBox(
                                      height: 2,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    "\n\n\n\n${Provider.of<ZLanguage>(context).nothingFound}",
                                    textAlign: TextAlign.center,
                                  ),
                                )

              /////////////////////////////////////////////////////////////////
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> searchItem(searchQuery) async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/search_item_global";
    Map data = {
      "name": searchQuery,
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
            this._loading = false;
            // this.isFiltered = false;
            // this.filteredResult['items'] = [];
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Something went wrong! Please check your internet connection!"),
            backgroundColor: kSecondaryColor,
          ),
        );
      }
      return null;
    }
  }

///////////////////////////////////////////////////////////////////////////
  double calculateStoreSimilarity(String item, String query) {
    double similarity = 0.0;
    setState(() {
      var matchingChars = item.split('').where((char) => query.contains(char));
      similarity = ((matchingChars.length / item.length) * 100);
    });
    return similarity;
  }

  Future<dynamic> getCompanyList() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_company_list";

    Map data = {
      "city_id": widget.cityId!,
      "store_delivery_id": storeDeliveryId,
      "latitude": widget.latitude!,
      "longitude": widget.longitude!,
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
      return json.decode(response.body);
    } catch (e) {
      return null;
    }
  }

  onSearchTextChanged({required String query}) async {
    _searchResult.clear();
    if (query.isEmpty) {
      setState(() {
        storeOpen(stores);
      });
      return;
    }

    stores.forEach((store) {
      if (store['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase())) {
        double similarity = calculateStoreSimilarity(
            store['name'].toString().toLowerCase(), query.toLowerCase());
        final updatedStore = {
          ...store,
          'similarity': similarity,
        };
        _searchResult.add(updatedStore);
      }
    });

    setState(() {
      storeOpen(_searchResult);
    });
  }

  Widget SearchLists({required int index}) {
    double rating =
        double.parse(_searchResult[index]['user_rate'].toStringAsFixed(2));
    List ratingVal = ["☆", "☆", "☆", "☆", "☆"];
    for (int i = 0; i < int.parse(rating.ceil().toString()); i++) {
      ratingVal[i] = '★';
    }
    String parsedRVAl = ratingVal.join("");
    return GestureDetector(
      onTap: () {
        if (isOpen[index]) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ProductScreen(
                  store: _searchResult[index],
                  location: _searchResult[index]["location"],
                  latitude: _searchResult[index]["location"][0],
                  longitude: _searchResult[index]["location"][1],
                  isOpen: isOpen[index],
                );
              },
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            Service.showMessage(
                "Sorry, store is currently closed. Please comeback soon.",
                false,
                duration: 3),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: kPrimaryColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                      height: getProportionateScreenWidth(kDefaultPadding / 2)),
                  SearchImageContainer(
                    url: _searchResult[index]['image_url'].length > 0
                        ? "http://159.65.147.111:8000/${_searchResult[index]['image_url']}"
                        : "https://ibb.co/vkhzjd6",
                  ),
                  SizedBox(
                    width: getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _searchResult[index]['name'],
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding / 1.3),
                            fontWeight: FontWeight.bold,
                            // color: kBlackColor,
                          ),
                        ),
                        Text(
                          parsedRVAl,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: kSecondaryColor,
                                    fontSize: getProportionateScreenWidth(
                                        kDefaultPadding * .7),
                                  ),
                        ),
                        Text(
                          isOpen[index]
                              ? Provider.of<ZLanguage>(context).open
                              : Provider.of<ZLanguage>(context).closed,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isOpen[index]
                                      ? Colors.green
                                      : kSecondaryColor),
                        )
                      ],
                    ),
                  ),
                      Text(
                    "${(_searchResult[index]['similarity']).toInt().toString()}% ${Provider.of<ZLanguage>(context).match}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (_searchResult[index]['similarity']).toInt() >
                                  90
                              ? Colors.green
                              : (_searchResult[index]['similarity']).toInt() >
                                      70
                                  ? Colors.orange
                                  : (_searchResult[index]['similarity'])
                                              .toInt() >
                                          50
                                      ? kSecondaryColor
                                      : kGreyColor,
                        ),
                  ), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
///////////////////////////////////////////////////////////
}

class SearchImageContainer extends StatelessWidget {
  const SearchImageContainer({
    Key? key,
    required this.url,
  }) : super(key: key);

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => Container(
        width: getProportionateScreenWidth(kDefaultPadding * 5),
        height: getProportionateScreenHeight(kDefaultPadding * 5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kBlackColor.withOpacity(0.04),
          // borderRadius: BorderRadius.all(
          //   Radius.circular(
          //     getProportionateScreenHeight(kDefaultPadding * .75),
          //   ),
          // ),
          image: DecorationImage(
            fit: BoxFit.contain,
            image: imageProvider,
          ),
        ),
      ),
      placeholder: (context, url) => Center(
        child: Container(
          width: getProportionateScreenWidth(kDefaultPadding * 4),
          height: getProportionateScreenHeight(kDefaultPadding * 4),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kWhiteColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: getProportionateScreenWidth(kDefaultPadding * 5),
        height: getProportionateScreenHeight(kDefaultPadding * 5),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: kBlackColor.withOpacity(0.01),
          // borderRadius: BorderRadius.all(
          //   Radius.circular(
          //     getProportionateScreenHeight(kDefaultPadding * .75),
          //   ),
          // ),
          image: DecorationImage(
            fit: BoxFit.contain,
            image: AssetImage(zmallLogo),
          ),
        ),
      ),
    );
  }
}

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Skeleton(
          height: getProportionateScreenHeight(kDefaultPadding * 4),
          width: getProportionateScreenWidth(kDefaultPadding * 4),
        ),
        SizedBox(width: getProportionateScreenHeight(kDefaultPadding)),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: getProportionateScreenWidth(kDefaultPadding * 4)),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            Skeleton(),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            Skeleton(),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            Row(
              children: [
                Expanded(child: Skeleton()),
                SizedBox(width: getProportionateScreenHeight(kDefaultPadding)),
                Expanded(child: Skeleton()),
              ],
            ),
          ],
        ))
      ],
    );
  }
}

class Skeleton extends StatelessWidget {
  const Skeleton({
    Key? key,
    this.height,
    this.width,
  }) : super(key: key);
  final double? height, width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding:
          EdgeInsets.all(getProportionateScreenHeight(kDefaultPadding / 2)),
      decoration: BoxDecoration(
        color: kBlackColor.withOpacity(0.04),
        // borderRadius: BorderRadius.all(
        //   Radius.circular(
        //     getProportionateScreenHeight(kDefaultPadding * .75),
        //   ),
        // ),
      ),
    );
  }
}
