import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';
import 'package:zmall/world_cup/components/score_prediction_widget.dart';
import 'package:zmall/world_cup/components/win_percentage_widget.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key, @required this.game});

  final game;

  @override
  _PredictScreenState createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  bool homeWin = false;
  bool awayWin = false;
  bool draw = false;
  int homeScore = 0;
  int awayScore = 0;
  var userData;
  bool _isLoading = false;
  bool predicted = false;
  DateTime euroPredictStart = DateTime(2024, 06, 10);
  DateTime euroPredictEnd = DateTime(2024, 07, 15);
  @override
  void initState() {
    super.initState();
    getUser();
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

  void _getPredictions() async {
    setState(() {
      _isLoading = true;
    });
    var data = await getPredictions();
    // debugPrint("prediction data: $data");
    if (data != null && data['success']) {
      for (var index = 0; index < data['scores'].length; index++) {
        if (data['scores'][index]['game_id'] == widget.game['_id']) {
          setState(() {
            homeWin = data['scores'][index]['home_win'];
            awayWin = data['scores'][index]['away_win'];
            draw = data['scores'][index]['draw'];
            homeScore = data['scores'][index]['home_score'];
            awayScore = data['scores'][index]['away_score'];
            predicted = true;
          });
        }
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("${errorCodes['${data['error_code']}']}"),
      //   ),
      // );
    }
  }

  void _predictGame() async {
    setState(() {
      _isLoading = true;
    });
    var data = await predictGame();
    if (data != null && data['success']) {
      Service.showMessage(
          context: context,
          title: "Prediction submitted successfully! Good luck...",
          error: false,
          duration: 4);
      setState(() {
        _isLoading = false;
      });
      _getPredictions();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${errorCodes['${data['error_code']}']}"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlackColor,
      appBar: AppBar(
        backgroundColor: kBlackColor,
        title: Text(
          "Predict & Win",
          style: TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(
          color: kPrimaryColor,
        ),
        elevation: 1.0,
      ),
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: _isLoading,
          color: kBlackColor.withValues(alpha: 0.3),
          progressIndicator: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitWave(
                  color: kPrimaryColor,
                  size: getProportionateScreenWidth(kDefaultPadding),
                ),
                SizedBox(height: kDefaultPadding * 0.5),
                Text(
                  "Loading...",
                  style: TextStyle(color: kPrimaryColor),
                ),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              spacing: getProportionateScreenHeight(kDefaultPadding),
              children: [
                Container(
                  width: double.infinity,
                  height: getProportionateScreenHeight(kDefaultPadding * 14),
                  decoration: BoxDecoration(
                    boxShadow: [boxShadow],
                    image: DecorationImage(
                      image: AssetImage("images/std_bg.png"),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                        getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      bottomRight: Radius.circular(
                        getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                    ),
                  ),
                  child: Column(
                    spacing: kDefaultPadding,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ///game type section////
                      CustomTag(
                          // color: Colors.lightBlueAccent,
                          color: kBlackColor.withValues(alpha: 0.5),
                          text: widget.game['type'].toString().toUpperCase()),

                      ///clubs logo section////
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding * 3),
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding * 3),
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                            "images/pl_logos/${widget.game['home_team'].toString().toLowerCase()}.png"),
                                        fit: BoxFit.fill,
                                      ),
                                      shape: BoxShape.circle,
                                      // color: kPrimaryColor,
                                    ),
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  CustomTag(
                                    color: kBlackColor.withValues(alpha: 0.8),
                                    // color: Colors.lightBlueAccent,
                                    text: widget.game['home_team']
                                        .toString()
                                        .toUpperCase(),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: kDefaultPadding / 4,
                                  vertical: kDefaultPadding / 8),
                              decoration: BoxDecoration(
                                color: kBlackColor.withValues(alpha: 0.4),
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding / 2),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    widget.game['is_finished']
                                        ? widget.game['home_score'].toString()
                                        : "-",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    "\t:\t",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    widget.game['is_finished']
                                        ? widget.game['away_score'].toString()
                                        : "-",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding * 3),
                                    width: getProportionateScreenWidth(
                                        kDefaultPadding * 3),
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          "images/pl_logos/${widget.game['away_team'].toString().toLowerCase()}.png",
                                        ),
                                        fit: BoxFit.fill,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  CustomTag(
                                    color: kBlackColor.withValues(alpha: 0.8),
                                    // color: Colors.lightBlueAccent,
                                    text: widget.game['away_team']
                                        .toString()
                                        .toUpperCase(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      ///game time section////
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2,
                            vertical: kDefaultPadding / 4),
                        decoration: BoxDecoration(
                            color: kBlackColor.withValues(alpha: 0.5),
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2)),
                        child: Text(
                          "${widget.game['game_time'].split('T')[0]} ${widget.game['game_time'].split('T')[1].split(".")[0]}",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: kWhiteColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),

                      ///game stadium section////
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2,
                            vertical: kDefaultPadding / 4),
                        decoration: BoxDecoration(
                            color: kBlackColor.withValues(alpha: 0.5),
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2)),
                        child: Text(
                          widget.game['stadium'].toString().toUpperCase(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: kWhiteColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                ////who will win the cgame section////
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding / 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Who will win the game?",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500, color: kPrimaryColor),
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(
                                  kDefaultPadding / 1.5),
                            ),
                            onTap: () {
                              if (userData != null && !predicted) {
                                setState(() {
                                  homeWin = true;
                                  draw = false;
                                  awayWin = false;
                                });
                              } else {
                                if (predicted) {
                                } else {
                                  // debugPrint("User not logged in...");

                                  Service.showMessage(
                                      context: context,
                                      title: "Please login in...",
                                      error: true);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(
                                        firstRoute: false,
                                      ),
                                    ),
                                  ).then((value) => getUser());
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                getProportionateScreenWidth(kDefaultPadding),
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: homeWin
                                        ? kSecondaryColor
                                        : Colors.transparent,
                                    width: 3),
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding * 1.5),
                                ),
                                boxShadow: [boxShadow],
                              ),
                              child: Text(
                                "HOME",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(
                                  kDefaultPadding / 1.5),
                            ),
                            onTap: () {
                              if (userData != null && !predicted) {
                                setState(() {
                                  draw = true;
                                  awayWin = false;
                                  homeWin = false;
                                });
                              } else {
                                if (predicted) {
                                } else {
                                  // debugPrint("User not logged in...");

                                  Service.showMessage(
                                      context: context,
                                      title: "Please login in...",
                                      error: true);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(
                                        firstRoute: false,
                                      ),
                                    ),
                                  ).then((value) => getUser());
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                getProportionateScreenWidth(kDefaultPadding),
                              ),
                              width: getProportionateScreenWidth(
                                  kDefaultPadding * 5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: draw
                                        ? kSecondaryColor
                                        : Colors.transparent,
                                    width: 3),
                                color: kGreyColor,
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding * 1.5),
                                ),
                                boxShadow: [boxShadow],
                              ),
                              child: Text(
                                "X",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              getProportionateScreenWidth(
                                  kDefaultPadding / 1.5),
                            ),
                            onTap: () {
                              if (userData != null && !predicted) {
                                setState(() {
                                  awayWin = true;
                                  draw = false;
                                  homeWin = false;
                                });
                              } else {
                                if (predicted) {
                                } else {
                                  // debugPrint("User not logged in...");

                                  Service.showMessage(
                                      context: context,
                                      title: "Please login in...",
                                      error: true);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(
                                        firstRoute: false,
                                      ),
                                    ),
                                  ).then((value) => getUser());
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                getProportionateScreenWidth(kDefaultPadding),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                border: Border.all(
                                    color: awayWin
                                        ? kSecondaryColor
                                        : Colors.transparent,
                                    width: 3),
                                borderRadius: BorderRadius.circular(
                                  getProportionateScreenWidth(
                                      kDefaultPadding * 1.5),
                                ),
                                boxShadow: [boxShadow],
                              ),
                              child: Text(
                                "AWAY",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                ////////////score counter section//////////////
                ScorePredictionWidget(
                  isPredicted: predicted,
                  homeTeam: widget.game['home_team'],
                  awayTeam: widget.game['away_team'],
                  homeScore: homeScore,
                  awayScore: awayScore,
                  onHomeIncrement: () => setState(() => homeScore++),
                  onHomeDecrement: () => setState(() {
                    if (homeScore > 0) homeScore--;
                  }),
                  onAwayIncrement: () => setState(() => awayScore++),
                  onAwayDecrement: () => setState(() {
                    if (awayScore > 0) awayScore--;
                  }),
                ),

                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding),
                ),

                ///winning percenrtage section///
                if (predicted)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding / 2),
                    ),
                    child: WinPercentageWidget(
                      homeTeam: widget.game['home_team'],
                      awayTeam: widget.game['away_team'],
                      homeWinCount: widget.game['home_win_count'],
                      drawCount: widget.game['draw_count'],
                      awayWinCount: widget.game['away_win_count'],
                      homeColor: Colors.green,
                      drawColor: Colors.grey,
                      awayColor: Colors.blue,
                      padding: getProportionateScreenWidth(kDefaultPadding),
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: kPrimaryColor),
                    ),
                  ),

                ///Submit button section///
                if (!predicted)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          getProportionateScreenWidth(kDefaultPadding / 2),
                    ),
                    child: CustomButton(
                      title: "Submit",
                      color: kSecondaryColor,
                      press: () {
                        if (userData != null) {
                          if (homeScore == awayScore) {
                            setState(() {
                              homeWin = false;
                              awayWin = false;
                              draw = true;
                              widget.game['draw_count']++;
                            });
                          } else if (homeScore > awayScore) {
                            setState(() {
                              homeWin = true;
                              awayWin = false;
                              draw = false;
                              widget.game['home_win_count']++;
                            });
                          } else {
                            setState(() {
                              awayWin = true;
                              homeWin = false;
                              draw = false;
                              widget.game['away_win_count']++;
                            });
                          }
                          _predictGame();
                        } else {
                          Service.showMessage(
                              context: context,
                              title:
                                  "Please log in to join the prediction and stand a chance to win!",
                              error: true,
                              duration: 4);
                        }
                      },
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
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
    // debugPrint('data?????? $data');
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
              title: "Something went wrong!",
              error: true,
              duration: 3);
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
    }
  }

  Future<dynamic> predictGame() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/predict_game";
    Map data = {
      "user_id": userData['user']["_id"],
      "server_token": userData['user']['server_token'],
      "game_id": widget.game['_id'],
      "home_score": homeScore,
      "away_score": awayScore,
      "away_win": awayWin,
      "home_win": homeWin,
      "draw": draw,
      "penalties": false,
      "penalty_score": 0
    };
    // debugPrint('data>>>>>>> $data');
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
              title: "Something went wrong!",
              error: true,
              duration: 3);
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
    }
  }
}
////////////old score counter section//////////////
                // Padding(
                //   padding: EdgeInsets.symmetric(
                //     horizontal:
                //         getProportionateScreenWidth(kDefaultPadding / 2),
                //   ),
                //   child: Column(
                //     children: [
                //       Text(
                //         "You think the score will be...",
                //         style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                //             fontWeight: FontWeight.w500, color: kPrimaryColor),
                //       ),
                //       SizedBox(
                //         height: getProportionateScreenHeight(kDefaultPadding),
                //       ),
                //       Row(
                //         children: [
                //           TeamContainer(
                //             teamName: widget.game['home_team'],
                //           ),
                //           Column(
                //             children: [
                //               GestureDetector(
                //                 onTap: () {
                //                   setState(() {
                //                     homeScore++;
                //                   });
                //                 },
                //                 child: Container(
                //                   width: getProportionateScreenWidth(
                //                       kDefaultPadding * 2.5),
                //                   decoration: BoxDecoration(
                //                     color: kSecondaryColor,
                //                     boxShadow: [boxShadow],
                //                     borderRadius: BorderRadius.only(
                //                       topRight: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                       topLeft: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                     ),
                //                   ),
                //                   child: Padding(
                //                       padding: EdgeInsets.all(
                //                           getProportionateScreenHeight(
                //                               kDefaultPadding / 1.5)),
                //                       child: Text(
                //                         "+",
                //                         textAlign: TextAlign.center,
                //                         style: Theme.of(context)
                //                             .textTheme
                //                             .titleLarge
                //                             ?.copyWith(
                //                               color: kPrimaryColor,
                //                               fontWeight: FontWeight.bold,
                //                             ),
                //                       )),
                //                 ),
                //               ),
                //               SizedBox(
                //                 height: 1,
                //               ),
                //               Container(
                //                 color: kSecondaryColor.withValues(alpha: 0.8),
                //                 width: getProportionateScreenWidth(
                //                     kDefaultPadding * 2.5),
                //                 child: Padding(
                //                   padding: EdgeInsets.all(
                //                       getProportionateScreenHeight(
                //                           kDefaultPadding / 2)),
                //                   child: Text(
                //                     homeScore.toString(),
                //                     textAlign: TextAlign.center,
                //                     style: Theme.of(context)
                //                         .textTheme
                //                         .titleLarge
                //                         ?.copyWith(
                //                           color: kPrimaryColor,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                   ),
                //                 ),
                //               ),
                //               SizedBox(
                //                 height: 1,
                //               ),
                //               GestureDetector(
                //                 onTap: () {
                //                   if (homeScore > 0) {
                //                     setState(() {
                //                       homeScore--;
                //                     });
                //                   }
                //                 },
                //                 child: Container(
                //                   width: getProportionateScreenWidth(
                //                       kDefaultPadding * 2.5),
                //                   decoration: BoxDecoration(
                //                     color: kSecondaryColor,
                //                     borderRadius: BorderRadius.only(
                //                       bottomRight: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                       bottomLeft: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                     ),
                //                   ),
                //                   child: Padding(
                //                     padding: EdgeInsets.all(
                //                         getProportionateScreenHeight(
                //                             kDefaultPadding / 1.5)),
                //                     child: Text(
                //                       "-",
                //                       textAlign: TextAlign.center,
                //                       style: Theme.of(context)
                //                           .textTheme
                //                           .titleLarge
                //                           ?.copyWith(
                //                             color: kPrimaryColor,
                //                             fontWeight: FontWeight.bold,
                //                           ),
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //           SizedBox(
                //             width: getProportionateScreenWidth(kDefaultPadding),
                //           ),
                //           Column(
                //             children: [
                //               GestureDetector(
                //                 onTap: () {
                //                   setState(() {
                //                     awayScore++;
                //                   });
                //                 },
                //                 child: Container(
                //                   width: getProportionateScreenWidth(
                //                       kDefaultPadding * 2.5),
                //                   decoration: BoxDecoration(
                //                     color: kSecondaryColor,
                //                     borderRadius: BorderRadius.only(
                //                       topRight: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                       topLeft: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                     ),
                //                   ),
                //                   child: Padding(
                //                       padding: EdgeInsets.all(
                //                           getProportionateScreenHeight(
                //                               kDefaultPadding / 1.5)),
                //                       child: Text(
                //                         "+",
                //                         textAlign: TextAlign.center,
                //                         style: Theme.of(context)
                //                             .textTheme
                //                             .titleLarge
                //                             ?.copyWith(
                //                               color: kPrimaryColor,
                //                               fontWeight: FontWeight.bold,
                //                             ),
                //                       )),
                //                 ),
                //               ),
                //               SizedBox(
                //                 height: 1,
                //               ),
                //               Container(
                //                 color: kSecondaryColor.withValues(alpha: 0.8),
                //                 width: getProportionateScreenWidth(
                //                     kDefaultPadding * 2.5),
                //                 child: Padding(
                //                     padding: EdgeInsets.all(
                //                         getProportionateScreenHeight(
                //                             kDefaultPadding / 2)),
                //                     child: Text(
                //                       awayScore.toString(),
                //                       textAlign: TextAlign.center,
                //                       style: Theme.of(context)
                //                           .textTheme
                //                           .titleLarge
                //                           ?.copyWith(
                //                             color: kPrimaryColor,
                //                             fontWeight: FontWeight.bold,
                //                           ),
                //                     )),
                //               ),
                //               SizedBox(
                //                 height: 1,
                //               ),
                //               GestureDetector(
                //                 onTap: () {
                //                   if (awayScore > 0) {
                //                     setState(() {
                //                       awayScore--;
                //                     });
                //                   }
                //                 },
                //                 child: Container(
                //                   width: getProportionateScreenWidth(
                //                       kDefaultPadding * 2.5),
                //                   decoration: BoxDecoration(
                //                     color: kSecondaryColor,
                //                     borderRadius: BorderRadius.only(
                //                       bottomRight: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                       bottomLeft: Radius.circular(
                //                         getProportionateScreenWidth(
                //                             kDefaultPadding / 1.5),
                //                       ),
                //                     ),
                //                   ),
                //                   child: Padding(
                //                     padding: EdgeInsets.all(
                //                         getProportionateScreenHeight(
                //                             kDefaultPadding / 1.5)),
                //                     child: Text(
                //                       "-",
                //                       textAlign: TextAlign.center,
                //                       style: Theme.of(context)
                //                           .textTheme
                //                           .titleLarge
                //                           ?.copyWith(
                //                             color: kPrimaryColor,
                //                             fontWeight: FontWeight.bold,
                //                           ),
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //           TeamContainer(
                //             teamName: widget.game['away_team'],
                //           ),
                //         ],
                //       )
                //     ],
                //   ),
                // ),