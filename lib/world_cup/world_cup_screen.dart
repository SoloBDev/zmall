import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:zmall/constants.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';
import 'package:zmall/world_cup/predict_screen.dart';

class WorldCupScreen extends StatefulWidget {
  const WorldCupScreen({Key? key}) : super(key: key);

  @override
  _WorldCupScreenState createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> {
  bool _isLoading = false;

  var games;
  var userData;
  var userPredictions;
  DateTime now = DateTime.now();
  var currentYear;
  var nextYear;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getGames();
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

  void _getGames() async {
    setState(() {
      _isLoading = true;
    });
    var data = await getGames();
    if (data != null && data['success']) {
      setState(() {
        _isLoading = false;
        games = data['games'];
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No new games available..."),
        ),
      );
    }
  }

  void _getPredictions() async {
    setState(() {
      _isLoading = true;
    });
    var data = await getPredictions();
    if (data != null && data['success']) {
      setState(() {
        _isLoading = false;
        userPredictions = data;
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBlackColor,
        appBar: AppBar(
          backgroundColor: kBlackColor,
          title: Text(
            "Predict $currentYear/$nextYear",
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: BackButton(
            color: kPrimaryColor,
          ),
          elevation: 1.0,
          bottom: TabBar(
            labelColor: Colors.lightBlueAccent,
            unselectedLabelStyle: Theme.of(context).textTheme.caption,
            unselectedLabelColor: kWhiteColor,
            indicatorColor: Colors.lightBlueAccent,
            tabs: [
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      Icons.sports_soccer,
                    ),
                  ),
                  Text(
                    "Available Games",
                    style: TextStyle(color: kPrimaryColor),
                  )
                ],
              ),
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      Icons.history,
                    ),
                  ),
                  Text(
                    "My Predictions",
                    style: TextStyle(color: kPrimaryColor),
                  )
                ],
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Available Games
            ModalProgressHUD(
              inAsyncCall: _isLoading,
              color: kBlackColor.withOpacity(0.3),
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding / 2),
                    vertical:
                        getProportionateScreenHeight(kDefaultPadding / 2)),
                child: games != null && games.length > 0
                    ? ListView.separated(
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(kDefaultPadding),
                                  image: DecorationImage(
                                    image: AssetImage(
                                        "images/pl_logos/pl_bg_dr.png"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      CustomTag(
                                        color: Colors.transparent,
                                        text: games[index]['type']
                                            .toString()
                                            .toUpperCase(),
                                        textColor: kBlackColor,
                                      ),
                                      Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  Container(
                                                    height:
                                                        getProportionateScreenHeight(
                                                            kDefaultPadding *
                                                                3),
                                                    width:
                                                        getProportionateScreenWidth(
                                                            kDefaultPadding *
                                                                3),
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                            "images/pl_logos/${games[index]['home_team'].toString().toLowerCase()}.png"),
                                                        fit: BoxFit.fill,
                                                      ),
                                                      shape: BoxShape.rectangle,
                                                      color: kPrimaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              getProportionateScreenHeight(
                                                                  5)),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        getProportionateScreenHeight(
                                                            kDefaultPadding /
                                                                2),
                                                  ),
                                                  CustomTag(
                                                    color: Colors.transparent,
                                                    text: games[index]
                                                        ['home_team'],
                                                  )
                                                  // Text(
                                                  //   games[index]['home_team'],
                                                  //   style: Theme.of(context)
                                                  //       .textTheme
                                                  //       .bodyText1
                                                  //       ?.copyWith(
                                                  //           color:
                                                  //               kPrimaryColor,
                                                  //           fontWeight:
                                                  //               FontWeight
                                                  //                   .w600),
                                                  // )
                                                ],
                                              ),
                                            ),
                                            Text(
                                              games[index]['is_finished']
                                                  ? games[index]['home_score']
                                                      .toString()
                                                  : "-",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6
                                                  ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              "\t:\t",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6
                                                  ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              games[index]['is_finished']
                                                  ? games[index]['away_score']
                                                      .toString()
                                                  : "-",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6
                                                  ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  Container(
                                                    height:
                                                        getProportionateScreenHeight(
                                                            kDefaultPadding *
                                                                3),
                                                    width:
                                                        getProportionateScreenWidth(
                                                            kDefaultPadding *
                                                                3),
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          "images/pl_logos/${games[index]['away_team'].toString().toLowerCase()}.png",
                                                        ),
                                                        fit: BoxFit.fill,
                                                      ),
                                                      shape: BoxShape.rectangle,
                                                      color: kPrimaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              getProportionateScreenHeight(
                                                                  5)),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        getProportionateScreenHeight(
                                                            kDefaultPadding /
                                                                2),
                                                  ),
                                                  CustomTag(
                                                    color: Colors.transparent,
                                                    text: games[index]
                                                        ['away_team'],
                                                  ),
                                                  // Text(
                                                  //   games[index]['away_team'],
                                                  //   style: Theme.of(context)
                                                  //       .textTheme
                                                  //       .bodyText1
                                                  //       ?.copyWith(
                                                  //           color:
                                                  //               kPrimaryColor,
                                                  //           fontWeight:
                                                  //               FontWeight
                                                  //                   .w600),
                                                  // )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 4),
                                      ),
                                      Text(
                                        "${games[index]['game_time'].split('T')[0]} ${games[index]['game_time'].split('T')[1].split(".")[0]}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            ?.copyWith(
                                              color: kWhiteColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 4),
                                      ),
                                      Text(
                                        games[index]['stadium']
                                            .toString()
                                            .toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            ?.copyWith(
                                              color: kWhiteColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2),
                                      ),
                                      if (!games[index]['is_finished'])
                                        InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  return PredictScreen(
                                                      game: games[index]);
                                                },
                                              ),
                                            ).then((value) {
                                              _getGames();
                                              _getPredictions();
                                            });
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            width: kDefaultPadding * 10,
                                            padding: EdgeInsets.all(
                                                kDefaultPadding * 0.75),
                                            decoration: BoxDecoration(
                                              color: kWhiteColor,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    kDefaultPadding / 2),
                                              ),
                                              // boxShadow: [boxShadow],
                                            ),
                                            child: Text(
                                              "PREDICT & WIN",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  ?.copyWith(
                                                    color: worldCupColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            SizedBox(
                              height: getProportionateScreenWidth(
                                  kDefaultPadding / 2),
                            ),
                        itemCount: games.length)
                    : _isLoading
                        ? Container()
                        : Center(
                            child: Text("No games to show..."),
                          ),
              ),
            ),

            // My Predictions
            ModalProgressHUD(
              inAsyncCall: _isLoading,
              color: kBlackColor.withOpacity(0.3),
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
                  vertical: getProportionateScreenHeight(kDefaultPadding / 2),
                ),
                child: userPredictions != null &&
                        userPredictions['scores'].length > 0
                    ? Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              Service.launchInWebViewOrVC(
                                  "https://app.zmallapp.com/predictions");
                            },
                            child: Text(
                              "Rules & Winnings",
                              style:
                                  Theme.of(context).textTheme.caption?.copyWith(
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
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: getProportionateScreenWidth(
                                        kDefaultPadding / 2),
                                    vertical: getProportionateScreenHeight(
                                        kDefaultPadding / 2),
                                  ),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 4),
                                    ),
                                    color: kPrimaryColor.withOpacity(0.1),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding * 2.5),
                                            width: getProportionateScreenWidth(
                                                kDefaultPadding * 2.5),
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    "images/pl_logos/${userPredictions['scores'][index]['game_detail']['home_team'].toString().toLowerCase()}.png"),
                                                fit: BoxFit.fill,
                                              ),
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(
                                                  getProportionateScreenHeight(
                                                      5)),
                                              color: kPrimaryColor,
                                              boxShadow: [boxShadow],
                                            ),
                                          ),
                                          SizedBox(
                                            width: getProportionateScreenHeight(
                                                kDefaultPadding / 2),
                                          ),
                                          Text(
                                            userPredictions['scores'][index]
                                                ['game_detail']['home_team'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Spacer(),
                                          Text(
                                            userPredictions['scores'][index]
                                                ['game_detail']['away_team'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          SizedBox(
                                            width: getProportionateScreenHeight(
                                                kDefaultPadding / 2),
                                          ),
                                          Container(
                                            height:
                                                getProportionateScreenHeight(
                                                    kDefaultPadding * 2.5),
                                            width: getProportionateScreenWidth(
                                                kDefaultPadding * 2.5),
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    "images/pl_logos/${userPredictions['scores'][index]['game_detail']['away_team'].toString().toLowerCase()}.png"),
                                                fit: BoxFit.fill,
                                              ),
                                              shape: BoxShape.rectangle,
                                              borderRadius: BorderRadius.circular(
                                                  getProportionateScreenHeight(
                                                      5)),
                                              color: kPrimaryColor,
                                              boxShadow: [boxShadow],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            userPredictions['scores'][index]
                                                    ['home_score']
                                                .toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Text(
                                            "Prediction",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Text(
                                            userPredictions['scores'][index]
                                                    ['away_score']
                                                .toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                ?.copyWith(
                                                    color: kPrimaryColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      if (userPredictions['scores'][index]
                                          ['game_detail']['is_finished'])
                                        SizedBox(
                                          height: getProportionateScreenHeight(
                                              kDefaultPadding / 2),
                                        ),
                                      if (userPredictions['scores'][index]
                                          ['game_detail']['is_finished'])
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Text(
                                              userPredictions['scores'][index]
                                                          ['game_detail']
                                                      ['home_score']
                                                  .toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1
                                                  ?.copyWith(
                                                      color: kPrimaryColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            Text(
                                              "Result",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1
                                                  ?.copyWith(
                                                      color: kPrimaryColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            Text(
                                              userPredictions['scores'][index]
                                                          ['game_detail']
                                                      ['away_score']
                                                  .toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1
                                                  ?.copyWith(
                                                      color: kPrimaryColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      SizedBox(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2),
                                      ),
                                      userPredictions['scores'][index]
                                                      ['game_detail']
                                                  ['is_finished'] &&
                                              userPredictions['scores'][index]
                                                          ['game_detail']
                                                      ['home_score'] ==
                                                  userPredictions['scores']
                                                      [index]['home_score'] &&
                                              userPredictions['scores'][index]
                                                          ['game_detail']
                                                      ['away_score'] ==
                                                  userPredictions['scores']
                                                      [index]['away_score']
                                          ? Text(
                                              "WIN",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6
                                                  ?.copyWith(
                                                      color: Colors.green),
                                            )
                                          : userPredictions['scores'][index]
                                                  ['game_detail']['is_finished']
                                              ? Text(
                                                  "LOSE",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText1
                                                      ?.copyWith(
                                                          color:
                                                              kSecondaryColor),
                                                )
                                              : Text(
                                                  "Result Pending...",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText1
                                                      ?.copyWith(
                                                          color: kGreyColor),
                                                ),
                                    ],
                                  ),
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
                    : _isLoading
                        ? Container()
                        : Center(
                            child: Text(
                              "You have no predictions yet...",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: kPrimaryColor,
                                  ),
                            ),
                          ),
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kSecondaryColor,
          onPressed: () {
            _getPredictions();
            _getGames();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
              ),
              // Text(
              //   "Refresh",
              //   style: Theme.of(context).textTheme.caption?.copyWith(
              //         color: kPrimaryColor,
              //       ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> getGames() async {
    var url = "https://app.zmallapp.com/api/admin/get_game_user_history";
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
          ScaffoldMessenger.of(context).showSnackBar(
            Service.showMessage("Network error! Please try again...", true,
                duration: 3),
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _isLoading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          this._isLoading = false;
        });
      }

      return null;
    }
  }

  Future<dynamic> getPredictions() async {
    var url = "https://app.zmallapp.com/api/admin/get_prediction_history";
    Map data = {
      "start_date": "",
      "end_date": "",
      "search_field": "user_detail._id",
      "search_value": userData['user']["_id"],
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
            this._isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            Service.showMessage("Network error! Please try again...", true,
                duration: 3),
          );
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        _isLoading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          this._isLoading = false;
        });
      }

      return null;
    }
  }
}
