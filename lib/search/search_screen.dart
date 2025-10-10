import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/core_services.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/custom_back_button.dart';
import 'package:zmall/widgets/custom_search_bar.dart';
import 'package:zmall/widgets/open_close_status_card.dart';
import 'package:zmall/widgets/shimmer_widget.dart';
import 'package:zmall/store/components/custom_list_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    @required this.cityId,
    @required this.categories,
    @required this.latitude,
    @required this.longitude,
  });
  final String? cityId;
  final categories;
  final double? latitude, longitude;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  String searchQuery = "";
  bool _loading = false;
  var responseData;
  var filteredResult = {'items': []};
  List<bool> isOpen = [];
  final _controller = TextEditingController();
  var selectedPriceRange = RangeValues(0.0, 1000);
  bool isFiltered = false;
  int maxPrice = 1000;

  // Tab controller and stores data
  late TabController _tabController;
  bool isCatagorySelected = false;
  var storeDeliveryId;
  var selectedCatagory = 0;
  List<dynamic> _searchResult = [];
  List<dynamic> stores = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initialize with default category when widget loads
    if (widget.categories.isNotEmpty) {
      storeDeliveryId = widget.categories[0]['_id'];
      selectedCatagory = 0;
    }
    _getCompanyList();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      if (_tabController.index == 0) {
        // Stores tab selected
        storeDeliveryId =
            widget.categories.isNotEmpty ? widget.categories[0]['_id'] : null;
        selectedCatagory = 0;
        _searchResult = [];
        isOpen = [];
        _getCompanyList();
      } else {
        // Items tab selected
        _searchResult = [];
        isOpen = [];
        filteredResult['items'] = [];
        responseData = null;
        if (searchQuery.isNotEmpty) {
          _searchItem(query: searchQuery);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
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
        filteredResult['items'] = data['items'];
        maxPrice = max;
        selectedPriceRange = RangeValues(0.00, double.parse(max.toString()));
      });
      storeOpen(data['items']);
    } else {
      setState(() {
        _loading = false;
      });
      Service.showMessage(
        context: context,
        title: "${errorCodes['${data['error_code']}']}!",
        error: true,
      );

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
      if (store['store_time'] != null && store['store_time'].length != 0) {
        for (var i = 0; i < store['store_time'].length; i++) {
          DateFormat dateFormat = new DateFormat.Hm();
          DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
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

                DateTime zmallOpen = dateFormat.parse(appOpen);
                DateTime zmallClose = dateFormat.parse(appClose);
                zmallOpen = new DateTime(now.year, now.month, now.day,
                    zmallOpen.hour, zmallOpen.minute);
                zmallClose = new DateTime(now.year, now.month, now.day,
                    zmallClose.hour, zmallClose.minute);
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
              DateTime zmallOpen = dateFormat.parse(appOpen);
              DateTime zmallClose = dateFormat.parse(appClose);
              zmallOpen = new DateTime(now.year, now.month, now.day,
                  zmallOpen.hour, zmallOpen.minute);
              zmallClose = new DateTime(now.year, now.month, now.day,
                  zmallClose.hour, zmallClose.minute);
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

  void _getCompanyList() async {
    setState(() {
      _loading = true;
    });

    var data = await getCompanyList();
    if (data != null && data['success']) {
      setState(() {
        stores = data['stores'] ?? [];
        _searchResult = [];
        isOpen = [];
        _searchResult = List.from(stores);

        // Apply current search query if it exists
        if (searchQuery.isNotEmpty) {
          _applySearchFilter();
        } else {
          storeOpen(_searchResult);
        }

        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _searchResult = [];
        stores = [];
        isOpen = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${errorCodes['${data?['error_code'] ?? 'Store not found'}']}"),
            backgroundColor: kSecondaryColor,
          ),
        );
      }
    }
  }

  void _applySearchFilter() {
    _searchResult.clear();
    isOpen.clear();

    if (searchQuery.isEmpty) {
      _searchResult = List.from(stores);
    } else {
      for (var store in stores) {
        if (store['name']
                ?.toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ??
            false) {
          double similarity = calculateStoreSimilarity(
              store['name']?.toString().toLowerCase() ?? '',
              searchQuery.toLowerCase());
          final updatedStore = {
            ...store,
            'similarity': similarity,
          };
          _searchResult.add(updatedStore);
        }
      }
    }

    storeOpen(_searchResult);
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
      var response = await http.post(Uri.parse(url),
          body: body,
          headers: <String, String>{
            "Content-Type": "application/json",
            "Accept": "application/json"
          }).timeout(Duration(seconds: 30));
      return json.decode(response.body);
    } catch (error) {
      // print(error);
      return null;
    }
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
      var response = await http.post(Uri.parse(url),
          body: body,
          headers: <String, String>{
            "Content-Type": "application/json",
            "Accept": "application/json"
          }).timeout(Duration(seconds: 30));
      return json.decode(response.body);
    } catch (error) {
      // print(error);
      return null;
    }
  }

  onSearchTextChanged({required String query}) async {
    setState(() {
      _searchResult.clear();
      isOpen.clear();
    });

    if (query.isEmpty) {
      setState(() {
        _searchResult = List.from(stores);
        storeOpen(_searchResult);
      });
      return;
    }

    stores.forEach((store) {
      if (store['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase())) {
        double similarity = calculateStoreSimilarity(
            store['name']?.toString().toLowerCase() ?? '', query.toLowerCase());
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

  double calculateStoreSimilarity(String item, String query) {
    double similarity = 0.0;
    var matchingChars = item.split('').where((char) => query.contains(char));
    similarity = ((matchingChars.length / item.length) * 100);
    return similarity;
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPrimaryColor,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              top: kDefaultPadding,
              left: kDefaultPadding,
              right: kDefaultPadding,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + kDefaultPadding,
            ),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBlackColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: kDefaultPadding),

                // Title
                Text(
                  Provider.of<ZLanguage>(context).priceFilter,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                      ),
                ),
                SizedBox(height: kDefaultPadding),

                // Price range labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min: ${selectedPriceRange.start.round()} ${Provider.of<ZMetaData>(context, listen: false).currency}',
                      style: TextStyle(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Max: ${selectedPriceRange.end.round()} ${Provider.of<ZMetaData>(context, listen: false).currency}',
                      style: TextStyle(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: kDefaultPadding / 2),

                // Range slider
                RangeSlider(
                  values: selectedPriceRange,
                  onChanged: (RangeValues val) {
                    setModalState(() => selectedPriceRange = val);
                  },
                  min: 0.0,
                  max: double.parse(maxPrice.toString()),
                  divisions: 20,
                  activeColor: kSecondaryColor,
                  inactiveColor: kSecondaryColor.withValues(alpha: 0.3),
                  labels: RangeLabels(
                    '${selectedPriceRange.start.round()}',
                    '${selectedPriceRange.end.round()}',
                  ),
                ),
                SizedBox(height: kDefaultPadding),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: kDefaultPadding * 0.8),
                          backgroundColor: kBlackColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                          ),
                        ),
                        child: Text(
                          Provider.of<ZLanguage>(context).cancel,
                          style: TextStyle(
                            color: kBlackColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: kDefaultPadding / 2),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isFiltered = true;
                          });
                          filterPrice();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: kDefaultPadding * 0.8),
                          backgroundColor: kSecondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                          ),
                        ),
                        child: Text(
                          Provider.of<ZLanguage>(context).filter,
                          style: TextStyle(
                            color: kWhiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          Provider.of<ZLanguage>(context).search,
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 0,
        leading: CustomBackButton(),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Stores'),
            Tab(text: 'Items'),
          ],
          indicatorColor: kSecondaryColor,
          labelColor: kSecondaryColor,
          unselectedLabelColor: kBlackColor,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(),
        child: Column(
          children: [
            // Search Bar outside TabBarView
            CustomSearchBar(
              controller: _controller,
              showFilterButton: _tabController.index == 1,
              hintText: searchQuery == ''
                  ? Provider.of<ZLanguage>(context).searchEngine
                  : searchQuery,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });

                // Trigger filtering for both views
                if (_tabController.index == 0) {
                  onSearchTextChanged(query: value);
                } else {
                  if (value.isEmpty) {
                    setState(() {
                      filteredResult['items'] = [];
                      responseData = null;
                    });
                  } else {
                    _searchItem(query: value);
                  }
                }
              },
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
                if (searchQuery.isNotEmpty) {
                  if (_tabController.index == 0) {
                    onSearchTextChanged(query: searchQuery);
                  } else {
                    _searchItem(query: searchQuery);
                  }
                }
              },
              onClearButtonTap: () {
                setState(() {
                  searchQuery = '';
                  if (_tabController.index == 0) {
                    _searchResult = List.from(stores);
                    storeOpen(_searchResult);
                  } else {
                    filteredResult['items'] = [];
                    responseData = null;
                    isOpen = [];
                  }
                });
                _controller.clear();
              },
              onFilterButtonTap: () {
                if (_tabController.index == 1 && responseData != null) {
                  _showPriceFilter();
                }
              },
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Stores Tab
                  StoresTabView(
                    categories: widget.categories,
                    searchResult: _searchResult,
                    selectedCategory: selectedCatagory,
                    loading: _loading,
                    latitude: widget.latitude ?? 0.0,
                    longitude: widget.longitude ?? 0.0,
                    onCategoryTap: () {
                      _getCompanyList();
                    },
                    onCategorySelected: (index) {
                      setState(() {
                        selectedCatagory = index;
                        storeDeliveryId = widget.categories[index]['_id'];
                        _searchResult = [];
                        isOpen = [];
                      });
                      _getCompanyList();
                    },
                    onStoreSelected: (store, isStoreOpen) {
                      if (isStoreOpen) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductScreen(
                              store: store,
                              location: store["location"] ?? [0.0, 0.0],
                              latitude: store["location"]?[0] ?? 0.0,
                              longitude: store["location"]?[1] ?? 0.0,
                              isOpen: isStoreOpen,
                            ),
                          ),
                        );
                      } else {
                        Service.showMessage(
                          context: context,
                          title:
                              "Sorry, store is currently closed. Please comeback soon.",
                          error: false,
                          duration: 3,
                        );
                      }
                    },
                    stores: _searchResult,
                    isOpen: isOpen,
                  ),

                  // Items Tab
                  ItemsTabView(
                    loading: _loading,
                    filteredResult: filteredResult,
                    isOpen: isOpen,
                    onItemSelected: (item, isStoreOpen) {
                      if (isStoreOpen) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemScreen(
                              item: item,
                              location: [0.0, 0.0],
                            ),
                          ),
                        );
                      } else {
                        Service.showMessage(
                          context: context,
                          title:
                              "Sorry, store is currently closed. Please comeback soon.",
                          error: false,
                          duration: 3,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stores Tab View Widget
class StoresTabView extends StatelessWidget {
  final List<dynamic> categories;
  final List<dynamic> searchResult;
  final int selectedCategory;
  final bool loading;
  final double latitude;
  final double longitude;
  final VoidCallback onCategoryTap;
  final Function(int) onCategorySelected;
  final Function(dynamic, bool) onStoreSelected;
  final List<dynamic> stores;
  final List<bool> isOpen;

  const StoresTabView({
    super.key,
    required this.categories,
    required this.searchResult,
    required this.selectedCategory,
    required this.loading,
    required this.latitude,
    required this.longitude,
    required this.onCategoryTap,
    required this.onCategorySelected,
    required this.onStoreSelected,
    required this.stores,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Categories list
        if (categories.length != 0)
          Container(
            color: kPrimaryColor,
            width: double.infinity,
            height: kDefaultPadding * 3,
            margin: const EdgeInsets.only(bottom: kDefaultPadding / 2),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 0.4,
                vertical: kDefaultPadding / 2,
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    onCategorySelected(index);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedCategory == index
                          ? kSecondaryColor.withValues(alpha: 0.1)
                          : kPrimaryColor,
                      borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding / 2),
                      ),
                      border: Border.all(
                        width: 1.0,
                        color: selectedCategory == index
                            ? kSecondaryColor.withValues(alpha: 0.1)
                            : kWhiteColor,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding / 2)),
                    child: Text(
                      Service.capitalizeFirstLetters(
                          categories[index]['delivery_name'].toString()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: selectedCategory == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedCategory == index
                                ? kSecondaryColor
                                : kBlackColor,
                          ),
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => SizedBox(
                width: getProportionateScreenWidth(kDefaultPadding / 3),
              ),
            ),
          ),

        // Store results
        loading
            ? Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) => Column(
                    children: [ProductListShimmer()],
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemCount: 5,
                ),
              )
            : searchResult.isNotEmpty
                ? Expanded(
                    child: ListView.separated(
                      itemCount: searchResult.length,
                      itemBuilder: (BuildContext context, int index) {
                        return SearchLists(
                          index: index,
                          stores: stores,
                          isOpen: isOpen,
                          latitude: latitude,
                          longitude: longitude,
                          onStoreSelected: onStoreSelected,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          HeroiconsOutline.buildingStorefront,
                          size:
                              getProportionateScreenWidth(kDefaultPadding * 4),
                          color: kBlackColor.withValues(alpha: 0.3),
                        ),
                        SizedBox(
                            height:
                                getProportionateScreenHeight(kDefaultPadding)),
                        Text(
                          Provider.of<ZLanguage>(context).nothingFound,
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * 0.8),
                            fontWeight: FontWeight.w500,
                            color: kBlackColor.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2)),
                        Text(
                          "Try adjusting your search or filters",
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * 0.6),
                            color: kBlackColor.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
      ],
    );
  }
}

// Items Tab View Widget
class ItemsTabView extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic> filteredResult;
  final List<bool> isOpen;
  final Function(dynamic, bool) onItemSelected;

  const ItemsTabView({
    super.key,
    required this.loading,
    required this.filteredResult,
    required this.isOpen,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        loading
            ? Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) => Column(
                    children: [ProductListShimmer()],
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemCount: 5,
                ),
              )
            : filteredResult['items']?.isNotEmpty == true
                ? Expanded(
                    child: ListView.separated(
                      itemCount: filteredResult['items']?.length ?? 0,
                      separatorBuilder: (context, index) => const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      itemBuilder: (context, index) {
                        if (index >= filteredResult['items']!.length ||
                            index >= isOpen.length) {
                          return SizedBox.shrink();
                        }
                        final item = filteredResult['items']![index];
                        final isStoreOpen =
                            index < isOpen.length ? isOpen[index] : false;

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () => onItemSelected(item, isStoreOpen),
                              child: Container(
                                margin: const EdgeInsets.only(
                                    left: kDefaultPadding / 2,
                                    right: kDefaultPadding / 2,
                                    top: kDefaultPadding / 4),
                                padding:
                                    const EdgeInsets.all(kDefaultPadding / 2),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  border: Border.all(color: kWhiteColor),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SearchImageContainer(
                                      imageUrl: item['image_url']?.isNotEmpty ==
                                              true
                                          ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${item['image_url'][0]}"
                                          : "https://ibb.co/vkhzjd6",
                                      isOpen: isStoreOpen,
                                    ),
                                    SizedBox(
                                      width: getProportionateScreenWidth(
                                          kDefaultPadding / 2),
                                    ),
                                    // Item info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Service.capitalizeFirstLetters(
                                                item['name']),
                                            style: TextStyle(
                                              fontSize:
                                                  getProportionateScreenWidth(
                                                      kDefaultPadding / 1.2),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                Service.capitalizeFirstLetters(
                                                    item['store_name']),
                                                style: TextStyle(
                                                  fontSize:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding /
                                                              1.4),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (!isStoreOpen)
                                                Text(
                                                  textAlign: TextAlign.center,
                                                  " (Closed)",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          letterSpacing: 1,
                                                          color:
                                                              kSecondaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              getProportionateScreenWidth(
                                                                  8)),
                                                ),
                                            ],
                                          ),
                                          SizedBox(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding / 3),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "${Provider.of<ZMetaData>(context, listen: false).currency} ${item['price']}",
                                                style: TextStyle(
                                                  fontSize:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding /
                                                              1.2),
                                                  fontWeight: FontWeight.bold,
                                                  color: kSecondaryColor,
                                                ),
                                              ),
                                              Spacer(),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        getProportionateScreenHeight(
                                                            kDefaultPadding /
                                                                2)),
                                                child: OpenCloseStatusCard(
                                                  isOpen: isStoreOpen,
                                                  statusText: item[
                                                              'similarity'] !=
                                                          null
                                                      ? "${((item['similarity'] as double) * 100).toInt().toString()}% ${Provider.of<ZLanguage>(context).match}"
                                                      : "",
                                                  color: item['similarity'] !=
                                                          null
                                                      ? ((item['similarity']
                                                                          as double) *
                                                                      100)
                                                                  .toInt() >
                                                              90
                                                          ? Colors.green
                                                          : ((item['similarity']
                                                                              as double) *
                                                                          100)
                                                                      .toInt() >
                                                                  70
                                                              ? Colors.orange
                                                              : ((item['similarity'] as double) *
                                                                              100)
                                                                          .toInt() >
                                                                      50
                                                                  ? kSecondaryColor
                                                                  : kGreyColor
                                                      : kGreyColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size:
                              getProportionateScreenWidth(kDefaultPadding * 4),
                          color: kBlackColor.withValues(alpha: 0.3),
                        ),
                        SizedBox(
                            height:
                                getProportionateScreenHeight(kDefaultPadding)),
                        Text(
                          Provider.of<ZLanguage>(context).nothingFound,
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * 0.8),
                            fontWeight: FontWeight.w500,
                            color: kBlackColor.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2)),
                        Text(
                          "Try searching for different items",
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * 0.6),
                            color: kBlackColor.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
      ],
    );
  }
}

// Search Lists Widget for Stores
class SearchLists extends StatelessWidget {
  final int index;
  final List<dynamic> stores;
  final List<bool> isOpen;
  final double latitude;
  final double longitude;
  final Function(dynamic, bool)? onStoreSelected;

  const SearchLists({
    Key? key,
    required this.index,
    required this.stores,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
    this.onStoreSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (index >= stores.length || index >= isOpen.length) {
      return SizedBox.shrink();
    }

    final store = stores[index];
    final isStoreOpen = isOpen[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: CustomListTile(
        press: () {
          if (onStoreSelected != null) {
            onStoreSelected!(store, isStoreOpen);
          }
        },
        store: store,
        isOpen: isStoreOpen,
      ),
    );
  }
}

// Image Container Widget for Search
class SearchImageContainer extends StatelessWidget {
  final String imageUrl;
  final bool isOpen;

  const SearchImageContainer({
    super.key,
    required this.imageUrl,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: getProportionateScreenWidth(kDefaultPadding * 5),
          height: getProportionateScreenHeight(kDefaultPadding * 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: kBlackColor.withValues(alpha: 0.04),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: kBlackColor.withValues(alpha: 0.04),
                      child: Icon(
                        Icons.fastfood,
                        color: kBlackColor.withValues(alpha: 0.4),
                        size: getProportionateScreenWidth(kDefaultPadding * 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.fastfood,
                      color: kBlackColor.withValues(alpha: 0.4),
                      size: getProportionateScreenWidth(kDefaultPadding * 2),
                    ),
                  )
                : Icon(
                    Icons.fastfood,
                    color: kBlackColor.withValues(alpha: 0.4),
                    size: getProportionateScreenWidth(kDefaultPadding * 2),
                  ),
          ),
        ),
      ],
    );
  }
}
