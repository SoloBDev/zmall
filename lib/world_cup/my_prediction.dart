import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/world_cup/components/logo_container.dart';
import 'package:zmall/world_cup/components/win_percentage_widget.dart';

class MyPrediction extends StatefulWidget {
  const MyPrediction({super.key});

  @override
  State<MyPrediction> createState() => _MyPredictionState();
}

class _MyPredictionState extends State<MyPrediction> {
  bool _isLoading = false;
  List<bool> _isTileExpanded = [];
  var games;
  var userData;
  var userPredictions;
  DateTime now = DateTime.now();
  var currentYear;
  var nextYear;
  bool predicted = false;
  DateTime euroPredictStart = DateTime(2024, 06, 10);
  DateTime euroPredictEnd = DateTime(2024, 07, 15);

  @override
  void initState() {
    super.initState();
    // _getGames();
    getUser();
    currentYear = now.year % 100;
    nextYear = (now.year + 1) % 100;
  }

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
      _getPredictions();
    }
  }

  void _initializeExpansionStates() {
    if (userPredictions != null && userPredictions['scores'] != null) {
      _isTileExpanded =
          List<bool>.filled(userPredictions['scores'].length, false);
    }
  }

  // void _getGames() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   var data = await getGames();
  //   // debugPrint("getGames data: $data");
  //   if (data != null && data['success']) {
  //     setState(() {
  //       _isLoading = false;
  //       games = data['games'];
  //     });
  //   } else {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("No new games available..."),
  //       ),
  //     );
  //   }
  // }

  void _getPredictions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      var data = await getPredictions();
      // debugPrint("_getPredictions data: $data");
      if (data != null && data['success']) {
        setState(() {
          _isLoading = false;
          userPredictions = data;
          _initializeExpansionStates();
        });
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("${errorCodes['${data['error_code']}']}"),
      //   ),
      // );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlackColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kSecondaryColor,
        foregroundColor: kPrimaryColor,
        onPressed: () {
          _getPredictions();
          // _getGames();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
            ),
          ],
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        color: kBlackColor.withValues(alpha: 0.3),
        progressIndicator: LinearLoadingIndicator(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
          ).copyWith(
            bottom: getProportionateScreenHeight(kDefaultPadding / 2),
          ),
          child: _isLoading && userPredictions == null
              ? SizedBox.shrink()
              : userPredictions != null && userPredictions['scores'].length > 0
                  ? Column(
                      children: [
                        TextButton(
                          onPressed: () {
                            Service.launchInWebViewOrVC(
                                "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/predictions");
                          },
                          child: Text(
                            "Rules & Winnings",
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: kGreyColor,
                                      decoration: TextDecoration.underline,
                                      decorationColor: kPrimaryColor,
                                    ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: userPredictions['scores'].length,
                            itemBuilder: (context, index) {
                              final prediction =
                                  userPredictions['scores'][index];
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black12, blurRadius: 4)
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(
                                      "images/pl_logos/pl.jpg",
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: ExpansionTile(
                                    leading: SizedBox.shrink(),
                                    trailing: SizedBox.shrink(),
                                    tilePadding: EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: getProportionateScreenHeight(
                                          kDefaultPadding / 8),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    //

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          kDefaultPadding),
                                    ),
                                    collapsedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          kDefaultPadding),
                                    ),
                                    childrenPadding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                          kDefaultPadding / 2),
                                      vertical: getProportionateScreenHeight(
                                          kDefaultPadding / 2),
                                    ),
                                    onExpansionChanged: (bool expanded) {
                                      setState(() {
                                        _isTileExpanded[index] = expanded;
                                      });
                                    },
                                    initiallyExpanded: _isTileExpanded[index],
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        LogoContainer(
                                          // shape: BoxShape.rectangle,
                                          // backgroundColor: kBlackColor
                                          // .withValues(alpha: 0.5),
                                          logoUrl: prediction['game_detail']
                                                  ['home_team_logo'] ??
                                              '',
                                          errorLogoAsset:
                                              "images/pl_logos/${prediction['game_detail']['home_team'].toString().toLowerCase()}.png",
                                        ),
                                        SizedBox(
                                          width: getProportionateScreenHeight(
                                              kDefaultPadding / 2),
                                        ),
                                        Text(
                                          prediction['game_detail']
                                              ['home_team'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  color: kPrimaryColor,
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        Spacer(),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    prediction['game_detail']
                                                            ['is_finished']
                                                        ? prediction[
                                                                    'game_detail']
                                                                ['home_score']
                                                            .toString()
                                                        : "-",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontSize: 24,
                                                          color: kPrimaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  Text(
                                                    "\t:\t",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          color: kPrimaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  Text(
                                                    prediction['game_detail']
                                                            ['is_finished']
                                                        ? prediction[
                                                                    'game_detail']
                                                                ['away_score']
                                                            .toString()
                                                        : "-",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontSize: 24,
                                                          color: kPrimaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              //////////////user prediction section//////////
                                              if (!_isTileExpanded[index])
                                                Row(
                                                  spacing:
                                                      getProportionateScreenWidth(
                                                          kDefaultPadding / 3),
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      prediction['home_score']
                                                          .toString(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: kGreyColor,
                                                          ),
                                                    ),
                                                    Text(
                                                      "Prediction",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: kGreyColor,
                                                          ),
                                                    ),
                                                    Text(
                                                      prediction['away_score']
                                                          .toString(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: kGreyColor,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              // //////////////user prediction result//////////
                                              prediction['game_detail']
                                                          ['is_finished'] &&
                                                      prediction['game_detail']
                                                              ['home_score'] ==
                                                          prediction[
                                                              'home_score'] &&
                                                      prediction['game_detail']
                                                              ['away_score'] ==
                                                          prediction[
                                                              'away_score']
                                                  ? Text(
                                                      "WIN",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                              color:
                                                                  Colors.green,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    )
                                                  : prediction['game_detail']
                                                          ['is_finished']
                                                      ? Text(
                                                          "LOSE",
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                  color:
                                                                      kSecondaryColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        )
                                                      : Text(
                                                          "Result Pending...",
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                  color:
                                                                      kGreyColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          prediction['game_detail']
                                              ['away_team'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  color: kPrimaryColor,
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          width: getProportionateScreenHeight(
                                              kDefaultPadding / 2),
                                        ),
                                        LogoContainer(
                                          logoUrl: userPredictions['scores']
                                                      [index]['game_detail']
                                                  ['away_tew600am_logo'] ??
                                              '',
                                          errorLogoAsset:
                                              "images/pl_logos/${prediction['game_detail']['away_team'].toString().toLowerCase()}.png",
                                        ),
                                      ],
                                    ),
                                    children: [
                                      //////////////user prediction section//////////
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            prediction['home_score'].toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Text(
                                            "Prediction",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Text(
                                            prediction['away_score'].toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      WinPercentageWidget(
                                        showColor: false,
                                        homeTeam: prediction['game_detail']
                                            ['home_team'],
                                        awayTeam: prediction['game_detail']
                                            ['away_team'],
                                        homeWinCount: prediction['game_detail']
                                            ['home_win_count'],
                                        drawCount: prediction['game_detail']
                                            ['draw_count'],
                                        awayWinCount: prediction['game_detail']
                                            ['away_win_count'],
                                        homeColor: Colors.green,
                                        drawColor: Colors.grey,
                                        awayColor: Colors.blue,
                                        padding: getProportionateScreenWidth(
                                            kDefaultPadding),
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: kPrimaryColor),
                                      ),
                                    ]),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) => SizedBox(
                              height: getProportionateScreenWidth(
                                  kDefaultPadding / 2),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            HeroiconsOutline.trophy,
                            color: kSecondaryColor.withValues(alpha: 0.7),
                            size: getProportionateScreenWidth(
                                kDefaultPadding * 4),
                          ),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 2)),
                          Text(
                            "No predictions found.",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: kGreyColor,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                              height: getProportionateScreenHeight(
                                  kDefaultPadding / 4)),
                          Text(
                            "Start predicting game outcomes to see your scores here!",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: kGreyColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Future<dynamic> getGames() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_game_user_history";
    Map data = {};
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
            this._isLoading = false;
          });

          Service.showMessage(
            context: context,
            title: "Network error! Please try again...",
            error: true,
            duration: 3,
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _isLoading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      if (mounted) {
        setState(() {
          this._isLoading = false;
        });
      }

      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<dynamic> getPredictions() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_prediction_history";
    Map data = {
      "start_date": "",
      "end_date": "",
      "search_field": "user_detail._id",
      "search_value": userData['user']["_id"],
    };
    var body = json.encode(data);
    // print("prediction body $body");
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
            this._isLoading = false;
          });

          Service.showMessage(
            context: context,
            title: "Network error! Please try again...",
            error: true,
            duration: 3,
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _isLoading = false;
      });
      // print("prediction ${json.decode(response.body)}");
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      if (mounted) {
        setState(() {
          this._isLoading = false;
        });
      }

      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
//  ModalProgressHUD(
//               inAsyncCall: _isLoading,
//               color: kBlackColor.withValues(alpha: 0.3),
//               progressIndicator: Container(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SpinKitWave(
//                       color: kPrimaryColor,
//                       size: getProportionateScreenWidth(kDefaultPadding),
//                     ),
//                     SizedBox(height: kDefaultPadding * 0.5),
//                     Text(
//                       "Loading...",
//                       style: TextStyle(color: kPrimaryColor),
//                     ),
//                   ],
//                 ),
//               ),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
//                   vertical: getProportionateScreenHeight(kDefaultPadding / 2),
//                 ),
//                 child: userPredictions != null &&
//                         userPredictions['scores'].length > 0
//                     ? Column(
//                         children: [
//                           TextButton(
//                             onPressed: () {
//                               Service.launchInWebViewOrVC(
//                                   "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/predictions");
//                             },
//                             child: Text(
//                               "Rules & Winnings",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodySmall
//                                   ?.copyWith(
//                                     color: kGreyColor,
//                                     decoration: TextDecoration.underline,
//                                     decorationColor: kPrimaryColor,
//                                   ),
//                             ),
//                           ),
//                           Expanded(
//                             child: ListView.separated(
//                               itemCount: userPredictions['scores'].length,
//                               itemBuilder: (context, index) {
//                                 return Container(
//                                   padding: EdgeInsets.symmetric(
//                                     horizontal: getProportionateScreenWidth(
//                                         kDefaultPadding / 2),
//                                     vertical: getProportionateScreenHeight(
//                                         kDefaultPadding / 2),
//                                   ),
//                                   width: double.infinity,
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(
//                                       getProportionateScreenWidth(
//                                           kDefaultPadding / 4),
//                                     ),
//                                     color: kPrimaryColor.withValues(alpha: 0.1),
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           ImageContainer(
//                                             shape: BoxShape.rectangle,
//                                             url: userPredictions['scores']
//                                                         [index]['game_detail']
//                                                     ['home_team_logo'] ??
//                                                 '',
//                                             errorUrl:
//                                                 "images/pl_logos/${userPredictions['scores'][index]['game_detail']['home_team'].toString().toLowerCase()}.png",
//                                             height:
//                                                 getProportionateScreenHeight(
//                                                     kDefaultPadding * 3),
//                                             width: getProportionateScreenWidth(
//                                                 kDefaultPadding * 3),
//                                             borderRadius: BorderRadius.circular(
//                                                 getProportionateScreenHeight(
//                                                     5)),
//                                           ),
//                                           // Container(
//                                           //   height:
//                                           //       getProportionateScreenHeight(
//                                           //           kDefaultPadding * 2.5),
//                                           //   width: getProportionateScreenWidth(
//                                           //       kDefaultPadding * 2.5),
//                                           //   decoration: BoxDecoration(
//                                           //     image: DecorationImage(
//                                           //       image: AssetImage(
//                                           //           "images/pl_logos/${userPredictions['scores'][index]['game_detail']['home_team'].toString().toLowerCase()}.png"),
//                                           //       fit: BoxFit.fill,
//                                           //     ),
//                                           //     shape: BoxShape.rectangle,
//                                           //     borderRadius: BorderRadius.circular(
//                                           //         getProportionateScreenHeight(
//                                           //             5)),
//                                           //     color: kPrimaryColor,
//                                           //     boxShadow: [boxShadow],
//                                           //   ),
//                                           // ),
//                                           SizedBox(
//                                             width: getProportionateScreenHeight(
//                                                 kDefaultPadding / 2),
//                                           ),
//                                           Text(
//                                             userPredictions['scores'][index]
//                                                 ['game_detail']['home_team'],
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .titleMedium
//                                                 ?.copyWith(
//                                                     color: kPrimaryColor,
//                                                     fontWeight:
//                                                         FontWeight.w600),
//                                           ),
//                                           Spacer(),
//                                           Text(
//                                             userPredictions['scores'][index]
//                                                 ['game_detail']['away_team'],
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .titleMedium
//                                                 ?.copyWith(
//                                                     color: kPrimaryColor,
//                                                     fontWeight:
//                                                         FontWeight.w600),
//                                           ),
//                                           SizedBox(
//                                             width: getProportionateScreenHeight(
//                                                 kDefaultPadding / 2),
//                                           ),
//                                           ImageContainer(
//                                             shape: BoxShape.rectangle,
//                                             url: userPredictions['scores']
//                                                         [index]['game_detail']
//                                                     ['away_team_logo'] ??
//                                                 '',
//                                             errorUrl:
//                                                 "images/pl_logos/${userPredictions['scores'][index]['game_detail']['away_team'].toString().toLowerCase()}.png",
//                                             height:
//                                                 getProportionateScreenHeight(
//                                                     kDefaultPadding * 3),
//                                             width: getProportionateScreenWidth(
//                                                 kDefaultPadding * 3),
//                                             borderRadius: BorderRadius.circular(
//                                                 getProportionateScreenHeight(
//                                                     5)),
//                                           ),
//                                           // Container(
//                                           //   height:
//                                           //       getProportionateScreenHeight(
//                                           //           kDefaultPadding * 2.5),
//                                           //   width: getProportionateScreenWidth(
//                                           //       kDefaultPadding * 2.5),
//                                           //   decoration: BoxDecoration(
//                                           //     image: DecorationImage(
//                                           //       image: AssetImage(
//                                           //           "images/pl_logos/${userPredictions['scores'][index]['game_detail']['away_team'].toString().toLowerCase()}.png"),
//                                           //       fit: BoxFit.fill,
//                                           //     ),
//                                           //     shape: BoxShape.rectangle,
//                                           //     borderRadius: BorderRadius.circular(
//                                           //         getProportionateScreenHeight(
//                                           //             5)),
//                                           //     color: kPrimaryColor,
//                                           //     boxShadow: [boxShadow],
//                                           //   ),
//                                           // ),
//                                         ],
//                                       ),
//                                       SizedBox(
//                                         height: getProportionateScreenHeight(
//                                             kDefaultPadding / 2),
//                                       ),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceAround,
//                                         children: [
//                                           Text(
//                                             userPredictions['scores'][index]
//                                                     ['home_score']
//                                                 .toString(),
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .bodyLarge
//                                                 ?.copyWith(
//                                                     color: kPrimaryColor,
//                                                     fontWeight:
//                                                         FontWeight.w600),
//                                           ),
//                                           Text(
//                                             "Prediction",
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .bodyLarge
//                                                 ?.copyWith(
//                                                     color: kPrimaryColor,
//                                                     fontWeight:
//                                                         FontWeight.w600),
//                                           ),
//                                           Text(
//                                             userPredictions['scores'][index]
//                                                     ['away_score']
//                                                 .toString(),
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .bodyLarge
//                                                 ?.copyWith(
//                                                     color: kPrimaryColor,
//                                                     fontWeight:
//                                                         FontWeight.w600),
//                                           ),
//                                         ],
//                                       ),
//                                       if (userPredictions['scores'][index]
//                                           ['game_detail']['is_finished'])
//                                         SizedBox(
//                                           height: getProportionateScreenHeight(
//                                               kDefaultPadding / 2),
//                                         ),
//                                       if (userPredictions['scores'][index]
//                                           ['game_detail']['is_finished'])
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.spaceAround,
//                                           children: [
//                                             Text(
//                                               userPredictions['scores'][index]
//                                                           ['game_detail']
//                                                       ['home_score']
//                                                   .toString(),
//                                               style: Theme.of(context)
//                                                   .textTheme
//                                                   .bodyLarge
//                                                   ?.copyWith(
//                                                       color: kPrimaryColor,
//                                                       fontWeight:
//                                                           FontWeight.w600),
//                                             ),
//                                             Text(
//                                               "Result",
//                                               style: Theme.of(context)
//                                                   .textTheme
//                                                   .bodyLarge
//                                                   ?.copyWith(
//                                                       color: kPrimaryColor,
//                                                       fontWeight:
//                                                           FontWeight.w600),
//                                             ),
//                                             Text(
//                                               userPredictions['scores'][index]
//                                                           ['game_detail']
//                                                       ['away_score']
//                                                   .toString(),
//                                               style: Theme.of(context)
//                                                   .textTheme
//                                                   .bodyLarge
//                                                   ?.copyWith(
//                                                       color: kPrimaryColor,
//                                                       fontWeight:
//                                                           FontWeight.w600),
//                                             ),
//                                           ],
//                                         ),
//                                       SizedBox(
//                                         height: getProportionateScreenHeight(
//                                             kDefaultPadding / 2),
//                                       ),
//                                       userPredictions['scores'][index]
//                                                       ['game_detail']
//                                                   ['is_finished'] &&
//                                               userPredictions['scores'][index]
//                                                           ['game_detail']
//                                                       ['home_score'] ==
//                                                   userPredictions['scores']
//                                                       [index]['home_score'] &&
//                                               userPredictions['scores'][index]
//                                                           ['game_detail']
//                                                       ['away_score'] ==
//                                                   userPredictions['scores']
//                                                       [index]['away_score']
//                                           ? Text(
//                                               "WIN",
//                                               style: Theme.of(context)
//                                                   .textTheme
//                                                   .titleLarge
//                                                   ?.copyWith(
//                                                       color: Colors.green),
//                                             )
//                                           : userPredictions['scores'][index]
//                                                   ['game_detail']['is_finished']
//                                               ? Text(
//                                                   "LOSE",
//                                                   style: Theme.of(context)
//                                                       .textTheme
//                                                       .bodyLarge
//                                                       ?.copyWith(
//                                                           color:
//                                                               kSecondaryColor),
//                                                 )
//                                               : Text(
//                                                   "Result Pending...",
//                                                   style: Theme.of(context)
//                                                       .textTheme
//                                                       .bodyLarge
//                                                       ?.copyWith(
//                                                           color: kGreyColor),
//                                                 ),
//                                     ],
//                                   ),
//                                 );
//                               },
//                               separatorBuilder:
//                                   (BuildContext context, int index) => SizedBox(
//                                 height: getProportionateScreenWidth(
//                                     kDefaultPadding / 2),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )
//                     : _isLoading
//                         ? Container()
//                         : Center(
//                             child: Text(
//                               "You have no predictions yet...",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodySmall
//                                   ?.copyWith(
//                                     color: kPrimaryColor,
//                                   ),
//                             ),
//                           ),
//               ),
//             )
//           ],
//         ),
