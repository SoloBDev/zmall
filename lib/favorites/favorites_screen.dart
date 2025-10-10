import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/controllers/controllers.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/store/components/custom_list_tile.dart';

class FavoritesScreen extends StatefulWidget {
  static String routeName = '/favorites';

  final double? latitude;
  final double? longitude;
  final Controller? controller;

  const FavoritesScreen({
    super.key,
    @required this.latitude,
    @required this.longitude,
    @required this.controller,
  });

  @override
  FavoritesScreenState createState() => FavoritesScreenState(controller!);
}

class FavoritesScreenState extends State<FavoritesScreen> {
  var userData;
  bool isLoading = false;
  var stores;
  List<bool> isOpen = [];

  FavoritesScreenState(Controller controller) {
    controller.getFavorites = _favoriteStores;
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    setState(() {
      isLoading = true;
    });
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      _favoriteStores();
    }
  }

  void _favoriteStores() async {
    if (userData != null) {
      var localData = await Service.read("user_favorite_stores");
      if (localData == null) {
        var data = await favoriteStores();
        if (data != null && data['success']) {
          stores = data['favourite_stores'];
          stores = List.from(stores.reversed);
          storeOpen(stores);
        } else {
          if (!(data['error_code'] == 556)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${errorCodes['${data['error_code']}']}"),
              ),
            );
          }
        }
      } else {
        if (localData['success']) {
          stores = localData['favourite_stores'];
          stores = List.from(stores.reversed);
          storeOpen(stores);
          setState(() {
            isLoading = false;
          });
        }
        var data = await favoriteStores();
      }
    }
    if (mounted)
      setState(() {
        isLoading = false;
      });
  }

  void storeOpen(List stores) {
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
        DateTime zmallClose = dateFormat.parse("21:00");
        DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
        zmallClose = DateTime(
            now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
        now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

        now.isAfter(zmallClose) ? isStoreOpen = false : isStoreOpen = true;
      }
      isOpen.add(isStoreOpen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      progressIndicator: linearProgressIndicator,
      color: kPrimaryColor,
      child: stores != null
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stores.length,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  children: [
                    index == 0
                        ? SizedBox(
                            width: getProportionateScreenWidth(kDefaultPadding),
                          )
                        : Container(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        getProportionateScreenWidth(kDefaultPadding),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          // borderRadius: BorderRadius.circular(
                          //   getProportionateScreenWidth(kDefaultPadding),
                          // ),
                          // boxShadow: [boxShadow],
                          border: Border.all(
                            color: kGreyColor.withValues(alpha: 0.2),
                            // vertical:
                            // BorderSide(color: kGreyColor.withValues(alpha: 0.2)),
                          ),
                        ),
                        width:
                            getProportionateScreenWidth(kDefaultPadding * 10),
                        child: FavoriteCustomListTile(
                          press: () {
                            // debugPrint("FAVORITE STORE CLICKED >>>>");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return ProductScreen(
                                    store: stores[index],
                                    location: stores[index]["location"],
                                    isOpen: isOpen[index],
                                    latitude: widget.latitude!,
                                    longitude: widget.longitude!,
                                  );
                                },
                              ),
                            ).then((value) {
                              _favoriteStores();
                            });
                          },
                          store: stores[index],
                          isOpen: isOpen[index],
                        ),
                      ),
                    ),
                  ],
                );
              },
              separatorBuilder: (BuildContext context, int index) => SizedBox(
                width: getProportionateScreenWidth(kDefaultPadding / 2),
              ),
            )
          : !isLoading
              ? Container(
                  child: Center(
                    child: Text("Favourite store list not found."),
                  ),
                )
              : Container(),
    );
  }

  Future<dynamic> favoriteStores() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_favourite_store_list";
    Map data = {
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
        Duration(seconds: 10),
        onTimeout: () {
          Service.showMessage(
            context: context,
            title: "Network error",
            error: true,
          );
          setState(() {
            isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      var val = json.decode(response.body);
      if (val['success']) {
        await Service.save("user_favorite_stores", val);
      }
      return val;
    } catch (e) {
      // debugPrint(e);
      return null;
    }
  }
}
