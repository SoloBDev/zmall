import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/events/components/description_row.dart';
import 'package:zmall/kifiya/components/event_santim.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/custom_progress_indicator.dart';

class EventsScreen extends StatefulWidget {
  static String routeName = '/events';

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  var eventsData;
  bool _loading = true;
  var events;
  var userData;
  List<dynamic> tagFilters = [];
  List<dynamic> selectedTagFilters = [];
  TextEditingController controller = TextEditingController();
  List<dynamic> _searchResult = [];
  int isSelected = -1;
  List<dynamic> ticketPrices = [];
  int quantity = 1;
  double selectedPrice = 0.0;
  double purchasePrice = 0.0;
  String selectedTicketId = "";

  void getUser() async {
    setState(() {
      _loading = true;
    });
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  void updatePrice() {
    setState(() {
      purchasePrice = quantity * selectedPrice;
    });
  }

  _getEvents() async {
    setState(() {
      _loading = true;
    });
    var eData = await getEvents();

    if (eData != null && eData['success']) {
      events = eData['events'];
      getPrices(events);
      getTags(events);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Events not found..."),
          ),
        );
      }
    }
    setState(() {
      _loading = false;
    });
  }

  void getPrices(List events) {
    ticketPrices.clear();
    events.forEach((event) {
      if (event['ticket_types'].length > 0) {
        List<double> prices = [];
        var tickets = event['ticket_types'];
        tickets.forEach((ticket) {
          prices.add(int.parse(ticket['ticket_price'].toString()).toDouble());
        });
        ticketPrices.add(prices.reduce((min)));
      } else {
        ticketPrices.add(0.toDouble());
      }
    });
  }

  void getTags(List events) {
    var eventsTags = {};
    events.forEach((event) {
      var tags = event['event_tags'].toString().split(',');
      tags.forEach((tag) {
        String t = tag.trim().toLowerCase();
        if (eventsTags.containsKey(t)) {
          eventsTags[t] += 1;
        } else {
          if (t.isNotEmpty && t != "null" && t != "undefined") {
            eventsTags[t] = 1;
          }
        }
      });
    });
    eventsTags.forEach((key, value) {
      if (value > 0) {
        tagFilters.add(key);
      }
    });
  }

  void filterUsingTag() {
    _searchResult.clear();
    if (selectedTagFilters.length == 0) {
      controller.text = "";
      setState(() {});
      return;
    }
    events.forEach((event) {
      selectedTagFilters.forEach((selectedTag) {
        if (event['event_tags']
            .toString()
            .toLowerCase()
            .contains(selectedTag)) {
          if (!(_searchResult.contains(event))) {
            _searchResult.add(event);
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
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getEvents();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: PreferredSize(
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Padding(
            padding: EdgeInsets.only(
              left: getProportionateScreenWidth(kDefaultPadding),
              right: getProportionateScreenWidth(kDefaultPadding),
              top: getProportionateScreenWidth(kDefaultPadding),
              bottom: getProportionateScreenWidth(kDefaultPadding),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.arrow_back_rounded),
                  GestureDetector(
                    onTap: () {
                      // debugPrint("Purchase history...");
                    },
                    child: Text(
                      "EVENTS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                        // decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(FontAwesomeIcons.ticketSimple),
                  )
                ],
              ),
            ),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kPrimaryColor.withValues(alpha: 0.9),
                kPrimaryColor.withValues(alpha: 0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              new BoxShadow(
                color: kPrimaryColor,
                blurRadius: 10.0,
                spreadRadius: 1.0,
              )
            ],
          ),
        ),
        preferredSize: new Size(MediaQuery.of(context).size.width, 150.0),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        progressIndicator: CustomLinearProgressIndicator(
          message: "Loading Events...",
        ),
        color: kPrimaryColor,
        child: events != null
            ? PageView.builder(
                itemCount: events.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (_, index) {
                  return GestureDetector(
                    onTap: () {
                      //:TODO Pop up to share to social media
                      // debugPrint(
                      //     "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${events[index]['image_url'][0]}");
                    },
                    child: Container(
                      height: size.height,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(events[index]["image_url"]
                                            .length >
                                        1
                                    ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${events[index]['image_url'][1]}"
                                    : "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${events[index]['image_url'][0]}"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            height: size.height * 0.45,
                            padding: EdgeInsets.symmetric(
                              vertical: getProportionateScreenHeight(
                                  kDefaultPadding / 2),
                              horizontal:
                                  getProportionateScreenWidth(kDefaultPadding),
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              gradient: LinearGradient(
                                colors: [
                                  kPrimaryColor,
                                  kPrimaryColor.withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding * 10),
                                ),
                                bottomLeft: Radius.circular(
                                  getProportionateScreenWidth(kDefaultPadding),
                                ),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                //  Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  Row(
                                    children: [
                                      if (events[index]['is_featured'] !=
                                              null &&
                                          events[index]['is_featured'])
                                        Icon(
                                          Icons.verified,
                                          color: kSecondaryColor,
                                          size: getProportionateScreenWidth(
                                              kDefaultPadding),
                                        ),
                                      if (events[index]['is_featured'] !=
                                              null &&
                                          events[index]['is_featured'])
                                        SizedBox(
                                          width: getProportionateScreenWidth(
                                              kDefaultPadding / 2),
                                        ),
                                      Expanded(
                                        child: Text(
                                          events[index]['name']
                                              .toString()
                                              .toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: kSecondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 4),
                                  ),
                                  Text(
                                    events[index]['description'].toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: kBlackColor,
                                        ),
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  DescriptionRow(
                                      title: events[index]
                                          ['organization_detail']['name'],
                                      iconData: Icons.perm_identity),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  DescriptionRow(
                                      title: events[index]['address'],
                                      iconData: FontAwesomeIcons.mapPin),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  DescriptionRow(
                                    title: events[index]['start_date']
                                        .toString()
                                        .split("T")[0],
                                    iconData: FontAwesomeIcons.calendar,
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  DescriptionRow(
                                    title: events[index]['event_tags'],
                                    iconData: FontAwesomeIcons.tag,
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding),
                                  ),
// Container(
//                               margin: EdgeInsets.only(
//                                 left: kDefaultPadding,
//                                 top: kDefaultPadding / 2,
//                               ),
//                               width: kDefaultPadding * 10,
//                               height: getProportionateScreenHeight(
//                                   kDefaultPadding * 3),
//                               child: CustomButton(
//                                 title:
                                  // ticketPrices[index] > 0
                                  //     ? "From ETB ${ticketPrices[index].toStringAsFixed(2)}"
                                  //     : "Free",
//                                 press: () {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (context) =>
//                                               EventSantimPayScreen(
//                                                 url: events[index]
//                                                     ['ticket_url'],
//                                                 title: events[index]['name'],
//                                               )));
//                                 },
//
                                  // setState(() {
                                  //   isSelected = -1;
                                  //   selectedPrice = 0.0;
                                  //   quantity = 1;
                                  //   selectedTicketId = "";
                                  //   updatePrice();
                                  // });
                                  // showModalBottomSheet<void>(
                                  //   isScrollControlled: true,
                                  //   context: context,
                                  //   shape: RoundedRectangleBorder(
                                  //     borderRadius: BorderRadius.only(
                                  //       topLeft: Radius.circular(30.0),
                                  //       topRight: Radius.circular(30.0),
                                  //     ),
                                  //   ),
                                  //   builder: (BuildContext context) {
                                  //     return StatefulBuilder(builder:
                                  //         (BuildContext context,
                                  //             StateSetter setState) {
                                  //       return DraggableScrollableSheet(
                                  //           expand: false,
                                  //           builder: (BuildContext context,
                                  //               ScrollController
                                  //                   scrollController) {
                                  //             return Padding(
                                  //               padding: EdgeInsets.all(
                                  //                   getProportionateScreenHeight(
                                  //                       kDefaultPadding)),
                                  //               child: Column(
                                  //                   crossAxisAlignment:
                                  //                       CrossAxisAlignment
                                  //                           .start,
                                  //                   children: <Widget>[
                                  //                     Text(
                                  //                       "Buy Ticket",
                                  //                       style: Theme.of(
                                  //                               context)
                                  //                           .textTheme
                                  //                           .headline5!
                                  //                           .copyWith(
                                  //                             fontWeight:
                                  //                                 FontWeight
                                  //                                     .bold,
                                  //                           ),
                                  //                     ),
                                  //                     Container(
                                  //                       height: getProportionateScreenHeight(
                                  //                           kDefaultPadding),
                                  //                     ),
                                  //                     Expanded(
                                  //                       child: ListView
                                  //                           .builder(
                                  //                               controller:
                                  //                                   scrollController,
                                  //                               itemCount: events[index]
                                  //                                       [
                                  //                                       'ticket_types']
                                  //                                   .length,
                                  //                               itemBuilder:
                                  //                                   (context,
                                  //                                       idx) {
                                  //                                 return GestureDetector(
                                  //                                   onTap:
                                  //                                       () {
                                  //                                     setState(
                                  //                                         () {
                                  //                                       isSelected =
                                  //                                           idx;
                                  //                                       selectedPrice =
                                  //                                           int.parse(events[index]['ticket_types'][idx]['ticket_price'].toString()).toDouble();
                                  //                                       selectedTicketId =
                                  //                                           events[index]['ticket_types'][idx]['_id'];
                                  //                                       updatePrice();
                                  //                                     });
                                  //                                   },
                                  //                                   child:
                                  //                                       Container(
                                  //                                     margin:
                                  //                                         EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                                  //                                     padding:
                                  //                                         EdgeInsets.all(kDefaultPadding / 2),
                                  //                                     decoration:
                                  //                                         BoxDecoration(
                                  //                                       color: isSelected == idx
                                  //                                           ? kSecondaryColor.withValues(alpha: 0.8)
                                  //                                           : kPrimaryColor,
                                  //                                       borderRadius:
                                  //                                           BorderRadius.circular(kDefaultPadding / 2),
                                  //                                       border:
                                  //                                           Border.all(),
                                  //                                     ),
                                  //                                     child:
                                  //                                         Row(
                                  //                                       mainAxisAlignment:
                                  //                                           MainAxisAlignment.spaceBetween,
                                  //                                       children: [
                                  //                                         Column(
                                  //                                           mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  //                                           crossAxisAlignment: CrossAxisAlignment.start,
                                  //                                           children: [
                                  //                                             Text("ETB ${events[index]['ticket_types'][idx]['ticket_price']}",
                                  //                                                 style: Theme.of(context).textTheme.subtitle1!.copyWith(
                                  //                                                       color: kBlackColor,
                                  //                                                       fontWeight: FontWeight.bold,
                                  //                                                     ),
                                  //                                                 textAlign: TextAlign.center),
                                  //                                             Text(
                                  //                                               events[index]['ticket_types'][idx]['ticket_name'],
                                  //                                               style: TextStyle(
                                  //                                                 color: kBlackColor,
                                  //                                                 fontWeight: FontWeight.w500,
                                  //                                               ),
                                  //                                               textAlign: TextAlign.center,
                                  //                                             ),
                                  //                                             Text(
                                  //                                               events[index]['ticket_types'][idx]['description'],
                                  //                                               style: Theme.of(context).textTheme.caption,
                                  //                                               textAlign: TextAlign.center,
                                  //                                             ),
                                  //                                           ],
                                  //                                         ),
                                  //                                         Container(
                                  //                                           height: kDefaultPadding,
                                  //                                           width: getProportionateScreenWidth(kDefaultPadding / 2),
                                  //                                           decoration: BoxDecoration(
                                  //                                             color: isSelected == idx ? kSecondaryColor : kPrimaryColor,
                                  //                                             shape: BoxShape.circle,
                                  //                                             border: Border.all(width: 1, color: isSelected == idx ? kGreyColor : kBlackColor),
                                  //                                           ),
                                  //                                         ),
                                  //                                       ],
                                  //                                     ),
                                  //                                   ),
                                  //                                 );
                                  //                               }),
                                  //                     ),
                                  //                     Container(
                                  //                       height: getProportionateScreenHeight(
                                  //                           kDefaultPadding),
                                  //                     ),
                                  //                     Row(
                                  //                       children: [
                                  //                         Expanded(
                                  //                             child:
                                  //                                 CustomButton(
                                  //                           title:
                                  //                               "Purchase for $purchasePrice",
                                  //                           color: purchasePrice >
                                  //                                   0
                                  //                               ? kSecondaryColor
                                  //                               : kGreyColor,
                                  //                           press: () {
                                  //                             if (userData !=
                                  //                                 null) {
                                  //                               if (selectedTicketId
                                  //                                   .isNotEmpty) {
                                  //                                 debugPrint(userData[
                                  //                                         'user']
                                  //                                     [
                                  //                                     '_id']);
                                  //                                 debugPrint(userData[
                                  //                                         'user']
                                  //                                     [
                                  //                                     'server_token']);
                                  //                                 debugPrint(
                                  //                                     quantity);
                                  //                                 debugPrint(
                                  //                                     selectedTicketId);
                                  //                                 Navigator.of(
                                  //                                         context)
                                  //                                     .push(
                                  //                                   MaterialPageRoute(
                                  //                                     builder:
                                  //                                         (context) {
                                  //                                       return TicketOrderPayment(
                                  //                                           quantity: quantity,
                                  //                                           userId: userData['user']['_id'],
                                  //                                           serverToken: userData['user']['server_token'],
                                  //                                           ticketId: selectedTicketId);
                                  //                                     },
                                  //                                   ),
                                  //                                 );
                                  //                               }
                                  //                             } else {
                                  //                               Service.showMessage(
                                  //                                   "You are not logged in! Please login to continue with this purchase",
                                  //                                   true);
                                  //                             }
                                  //                           },
                                  //                         )),
                                  //                         SizedBox(
                                  //                           width: getProportionateScreenWidth(
                                  //                               kDefaultPadding /
                                  //                                   2),
                                  //                         ),
                                  //                         Row(
                                  //                           children: [
                                  //                             InkWell(
                                  //                               child:
                                  //                                   Container(
                                  //                                 child:
                                  //                                     Padding(
                                  //                                   padding:
                                  //                                       EdgeInsets.all(
                                  //                                     getProportionateScreenWidth(kDefaultPadding /
                                  //                                         3),
                                  //                                   ),
                                  //                                   child:
                                  //                                       Icon(
                                  //                                     Icons
                                  //                                         .remove,
                                  //                                     color:
                                  //                                         kPrimaryColor,
                                  //                                   ),
                                  //                                 ),
                                  //                                 decoration:
                                  //                                     BoxDecoration(
                                  //                                   color: quantity !=
                                  //                                           1
                                  //                                       ? kSecondaryColor
                                  //                                       : kGreyColor,
                                  //                                   borderRadius:
                                  //                                       BorderRadius.only(
                                  //                                     topLeft:
                                  //                                         Radius.circular(kDefaultPadding),
                                  //                                     bottomLeft:
                                  //                                         Radius.circular(kDefaultPadding),
                                  //                                   ),
                                  //                                 ),
                                  //                               ),
                                  //                               onTap: quantity !=
                                  //                                       1
                                  //                                   ? () {
                                  //                                       setState(() {
                                  //                                         quantity -= 1;
                                  //                                         updatePrice();
                                  //                                       });
                                  //                                     }
                                  //                                   : () {
                                  //                                       ScaffoldMessenger.of(context).showSnackBar(Service.showMessage("Minimum order quantity is 1",
                                  //                                           true));
                                  //                                     },
                                  //                             ),
                                  //                             Container(
                                  //                               padding: EdgeInsets.symmetric(
                                  //                                   horizontal:
                                  //                                       getProportionateScreenWidth(kDefaultPadding /
                                  //                                           3)),
                                  //                               child: Text(
                                  //                                 this
                                  //                                     .quantity
                                  //                                     .toString(),
                                  //                                 style: Theme.of(
                                  //                                         context)
                                  //                                     .textTheme
                                  //                                     .headline6,
                                  //                               ),
                                  //                             ),
                                  //                             InkWell(
                                  //                               child:
                                  //                                   Container(
                                  //                                 decoration:
                                  //                                     BoxDecoration(
                                  //                                   color:
                                  //                                       kSecondaryColor,
                                  //                                   borderRadius:
                                  //                                       BorderRadius.only(
                                  //                                     topRight:
                                  //                                         Radius.circular(kDefaultPadding),
                                  //                                     bottomRight:
                                  //                                         Radius.circular(kDefaultPadding),
                                  //                                   ),
                                  //                                 ),
                                  //                                 child:
                                  //                                     Padding(
                                  //                                   padding:
                                  //                                       EdgeInsets.all(
                                  //                                     getProportionateScreenWidth(kDefaultPadding /
                                  //                                         3),
                                  //                                   ),
                                  //                                   child:
                                  //                                       Icon(
                                  //                                     Icons
                                  //                                         .add,
                                  //                                     color:
                                  //                                         kPrimaryColor,
                                  //                                   ),
                                  //                                 ),
                                  //                               ),
                                  //                               onTap: () {
                                  //                                 setState(
                                  //                                     () {
                                  //                                   quantity +=
                                  //                                       1;
                                  //                                   updatePrice();
                                  //                                 });
                                  //                               },
                                  //                             ),
                                  //                           ],
                                  //                         ),
                                  //                       ],
                                  //                     )
                                  //                   ]),
                                  //             );
                                  //           });
                                  //     });
                                  //   },
                                  // ).whenComplete(() {
                                  //   setState(() {});
                                  // });
                                  //color: kBlackColor,
                                  //),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 2),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                left: kDefaultPadding,
                                top: kDefaultPadding / 2,
                              ),
                              width: kDefaultPadding * 10,
                              height: getProportionateScreenHeight(
                                  kDefaultPadding * 3),
                              child: CustomButton(
                                title: 'Get ticket',
                                // ticketPrices[index] > 0
                                //     ? "From ETB ${ticketPrices[index].toStringAsFixed(2)}"
                                //     : "Free",
                                press: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EventSantimPayScreen(
                                                url: events[index]
                                                    ['ticket_url'],
                                                title: events[index]['name'],
                                              )));
                                },
                                color: kBlackColor,
                              ),
                            ),
                          ),
                          if (events.length - index != 1)
                            Padding(
                              padding: EdgeInsets.all(
                                  getProportionateScreenWidth(kDefaultPadding)),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.circleUp,
                                      color: kSecondaryColor,
                                    ),
                                    Text(
                                      "SWIPE UP",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: kSecondaryColor,
                                          ),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                })
            : _loading
                ? SpinKitWave(
                    color: kSecondaryColor,
                    size: getProportionateScreenWidth(kDefaultPadding),
                  )
                : Center(
                    child: Text("Loading Events"),
                  ),
      ),
    );
  }

  Future<dynamic> getEvents() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_user_event_history";
    Map data = {
      // "number_of_rec": 10,
      // "page": 1,
      // "search_field": "name",
      // "search_value": "",
      // "sort_field": "unique_id",
      // "end_date": "9-20-2022",
      // "start_date": "6-20-2022"
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
            Service.showMessage(
              context: context,
              title: "Something went wrong! Check your internet and try again",
              error: true,
              duration: 3,
            );
          }

          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.eventsData = json.decode(response.body);
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
}
