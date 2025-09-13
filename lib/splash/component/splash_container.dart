import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/notifications/notification_store.dart';
import 'package:zmall/service.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/constants.dart';
import 'skip_button.dart';

class SplashContainer extends StatefulWidget {
  const SplashContainer({
    Key? key,
    required this.urlLink,
    required this.adId,
    required this.bytes,
    required this.logged,
  }) : super(key: key);

  final String urlLink, adId;
  final Uint8List bytes;
  final bool logged;

  @override
  State<SplashContainer> createState() => _SplashContainerState();
}

class _SplashContainerState extends State<SplashContainer> {
  bool _loading = false;
  var notificationItem;
  bool _isClosed = false;
  String promptMessage = "";

  void _getItemInformation(String itemId) async {
    setState(() {
      _loading = true;
    });
    await getItemInformation(itemId);
    if (notificationItem != null && notificationItem['success']) {
      bool isOpen = await storeOpen(notificationItem['item']);
      if (isOpen) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ItemScreen(
                item: notificationItem['item'],
                location: notificationItem['item']['store_location'],
                isSplashRedirect: true,
              );
            },
          ),
        );
      } else {
        if (mounted) {
          Service.showMessage(
            context: context,
            title:
                "Store is currently closed. We highly recommend you to try other store. We've got them all...",
            error: false,
            duration: 3,
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${errorCodes['${notificationItem['error_code']}']}"),
        ),
      );
    }
  }

  Future<bool> storeOpen(var store) async {
    setState(() {
      _loading = true;
    });
    _getAppKeys();
    setState(() {
      _loading = false;
    });
    bool isStoreOpen = false;
    if (store['store_time'] != null && store['store_time'].length != 0) {
      var appClose = await Service.read('app_close');
      var appOpen = await Service.read('app_open');
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
              // DateTime zmallClose =
              //     DateTime(now.year, now.month, now.day, 21, 00);
              // DateTime zmallOpen =
              //     DateTime(now.year, now.month, now.day, 09, 00);
              // if (appOpen != null && appOpen != null) {
              DateTime zmallClose = dateFormat.parse(appClose);
              DateTime zmallOpen = dateFormat.parse(appOpen);
              // }

              close = new DateTime(
                  now.year, now.month, now.day, close.hour, close.minute);
              now =
                  DateTime(now.year, now.month, now.day, now.hour, now.minute);

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
            isStoreOpen = store['store_time'][i]['is_store_open'];
          }
        }
      }
    } else {
      var appClose = await Service.read('app_close');
      var appOpen = await Service.read('app_open');
      DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
      DateFormat dateFormat = new DateFormat.Hm();
      // DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
      // DateTime zmallOpen = DateTime(now.year, now.month, now.day, 09, 00);
      // if (appOpen != null && appOpen != null) {
      DateTime zmallClose = dateFormat.parse(appClose);
      DateTime zmallOpen = dateFormat.parse(appOpen);
      // }
      zmallClose = DateTime(
          now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);
      zmallOpen = DateTime(
          now.year, now.month, now.day, zmallOpen.hour, zmallOpen.minute);
      now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      if (now.isAfter(zmallOpen) && now.isBefore(zmallClose)) {
        isStoreOpen = true;
      } else {
        isStoreOpen = false;
      }
    }

    return isStoreOpen;
  }

  void _getAppKeys() async {
    var data = await CoreServices.appKeys(context);
    if (data != null && data['success']) {
      if (mounted)
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
        });
      if (data['message_flag']) {
        showSimpleNotification(
          Text(
            "⚠️ NOTICE ⚠️",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "${data['message']}\n",
          ),
          background: kBlackColor,
          duration: Duration(seconds: 7),
          elevation: 2.0,
          autoDismiss: false,
          slideDismiss: true,
          slideDismissDirection: DismissDirection.up,
        );
      }
    } else {
      getAppKeys();
    }
  }

  void getAppKeys() async {
    var data = await Service.read('ios_app_version');
    var currentVersion = await Service.read('version');
    _isClosed = await Service.readBool('is_closed');
    promptMessage = await Service.read('closed_message');
    var showUpdateDialog = await Service.readBool('ios_update_dialog');
    if (data != null) {
      if (currentVersion.toString() != data.toString()) {
        if (showUpdateDialog) {
          // debugPrint("\t=> \tShowing update dialog...");
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: kPrimaryColor,
                title: Text("New Version Update"),
                content: Text(
                    "We have detected an older version on the App on your phone."),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      "Update Now",
                      style: TextStyle(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Service.launchInWebViewOrVC("http://onelink.to/vnchst");
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // debugPrint("Launch ad url");
        CoreServices.saveAdClick(widget.adId);
        if (widget.urlLink.split("/")[0] == "item") {
          //TODO: Redirect to notification item
          // debugPrint("Redirect to notification item");
          _getItemInformation(widget.urlLink.split("/")[1]);
        } else if (widget.urlLink.split("/")[0] == "store") {
          //TODO: Redirect to notification store
          // debugPrint("Redirect to notification store");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return NotificationStore(storeId: widget.urlLink.split("/")[1]);
              },
            ),
          );
        } else {
          Service.launchInWebViewOrVC(this.widget.urlLink);
        }
      },
      child: Container(
        padding: EdgeInsets.only(bottom: kDefaultPadding / 1.5),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(widget.bytes),
            fit: BoxFit.cover,
          ),
        ),
        child: SkipButton(logged: widget.logged),
      ),
    );
  }

  Future<dynamic> getItemInformation(itemId) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_item_information";
    Map data = {
      "item_id": itemId,
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

          Service.showMessage(
            context: context,
            title: "Something went wrong!",
            error: true,
            duration: 3,
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.notificationItem = json.decode(response.body);
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      if (mounted) {
        setState(() {
          this._loading = false;
        });
      }

      return null;
    }
  }
}
