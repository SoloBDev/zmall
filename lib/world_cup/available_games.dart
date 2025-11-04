import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';
import 'package:zmall/world_cup/components/prediction_card.dart';
import 'package:zmall/world_cup/predict_screen.dart';

class AvailableGames extends StatefulWidget {
  const AvailableGames({super.key});

  @override
  State<AvailableGames> createState() => _AvailableGamesState();
}

class _AvailableGamesState extends State<AvailableGames> {
  DateTime euroPredictStart = DateTime(2024, 06, 10);
  DateTime euroPredictEnd = DateTime(2024, 07, 15);
  DateTime now = DateTime.now();
  bool _isLoading = false;
  bool predicted = false;
  var userPredictions;
  var currentYear;
  var userData;
  var nextYear;
  var games;

  @override
  void initState() {
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
    // debugPrint("getGames data: $data");
    if (data != null && data['success']) {
      setState(() {
        _isLoading = false;
        games = data['games'];
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      // Service.showMessage(
      //   error: false,
      //   context: context,
      //   title: "No new games available...",
      // );
    }
  }

  void _getPredictions() async {
    setState(() {
      _isLoading = true;
    });
    var data = await getPredictions();
    // debugPrint("_getPredictions data: $data");
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
    return Scaffold(
      backgroundColor: kBlackColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kSecondaryColor,
        foregroundColor: kPrimaryColor,
        onPressed: () {
          _getPredictions();
          _getGames();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.refresh)],
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        color: kBlackColor.withValues(alpha: 0.3),
        progressIndicator: LinearLoadingIndicator(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
            vertical: getProportionateScreenHeight(kDefaultPadding / 2),
          ),
          child: _isLoading && games == null
              ? SizedBox.shrink()
              : games != null && games.length > 0
              ? ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    // print("game $game");

                    // Check if the game is predicted
                    bool predicted = false;
                    if (userPredictions != null &&
                        userPredictions['scores'] != null) {
                      predicted = userPredictions['scores'].any(
                        (prediction) => prediction['game_id'] == game['_id'],
                      );
                    }

                    // Skip games that are predicted AND not finished
                    if (predicted && !game['is_finished']) {
                      return const SizedBox.shrink(); // More efficient than Container(height: 0)
                    }
                    DateTime gameTime = DateTime.parse(
                      game['game_time'],
                    ).toLocal();
                    DateTime now = DateTime.now().toUtc().add(
                      Duration(hours: 3),
                    );
                    bool isLive =
                        now.isAfter(gameTime) &&
                        now.isBefore(
                          gameTime.add(const Duration(minutes: 125)),
                        );

                    // Finished if more than 125 minutes have passed since start
                    bool isGameTimeFinished = now.isAfter(
                      gameTime.add(const Duration(minutes: 125)),
                    );

                    return MatchRow(
                      homeClubName: game['home_team'],
                      homeClubLogo:
                          game['home_team_logo'] ??
                          "images/pl_logos/${game['home_team'].toLowerCase()}.png",
                      awayClubName: game['away_team'],
                      awayClubLogo:
                          game['away_team_logo'] ??
                          "images/pl_logos/${game['away_team'].toLowerCase()}.png",
                      status: game['is_finished'] || isGameTimeFinished
                          ? "FT"
                          : isLive
                          ? "Live"
                          : "NS",
                      // game['is_finished'] ? "FT" : "NS",
                      timeOrScore: games[index]['is_finished']
                          ? "${games[index]['home_score'].toString()} : ${games[index]['away_score'].toString()}"
                          : "${games[index]['game_time'].split('T')[0]} ${games[index]['game_time'].split('T')[1].split(".")[0]}",
                      stadium: game['stadium'],
                      gameType: game['type'],
                      isFinished: game['is_finished'],
                      bannerImage:
                          game['game_banner'] != null &&
                              games[index]['game_banner'].isNotEmpty
                          ? NetworkImage(games[index]['game_banner'])
                          : AssetImage(
                              "images/pl_logos/pl.jpg",
                              // DateTime.now().isBefore(euroPredictEnd) &&
                              //         DateTime.now()
                              //             .isAfter(euroPredictStart)
                              //     ? "images/pl_logos/banner.png"
                              //     : "images/pl_logos/pl_bg_dr.png",
                            ),
                      homeErrorClubLogo:
                          "images/pl_logos/${game['home_team'].toString().toLowerCase()}.png",
                      awayErrorClubLogo:
                          "images/pl_logos/${game['away_team'].toString().toLowerCase()}.png",
                      onPredictTap: () {
                        // Lock prediction if 1 hour or less before kickoff
                        bool isLocked =
                            gameTime.difference(now).inMinutes <= 60;
                        if (isLocked) {
                          Service.showMessage(
                            context: context,
                            title:
                                "Prediction closed, less than 1 hour left before the game starts.",
                            error: false,
                          );
                          return;
                        }

                        // Allow prediction if not locked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PredictScreen(game: game),
                          ),
                        ).then((_) {
                          _getGames();
                          _getPredictions();
                        });
                      },
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        color: kGreyColor.withValues(alpha: 0.7),
                        size: getProportionateScreenWidth(kDefaultPadding * 4),
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(
                          kDefaultPadding / 2,
                        ),
                      ),
                      Text(
                        "No upcoming matches right now.",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: kGreyColor,
                              fontWeight: FontWeight.w400,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(
                          kDefaultPadding / 4,
                        ),
                      ),
                      Text(
                        "Check back later for more action!",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kGreyColor.withValues(alpha: 0.7),
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
              "Accept": "application/json",
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
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
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
}
//////////old list of games section////////
 // Available Games
            // ModalProgressHUD(
            //   inAsyncCall: _isLoading,
            //   color: kBlackColor.withValues(alpha: 0.3),
            //   progressIndicator: Container(
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         SpinKitWave(
            //           color: kPrimaryColor,
            //           size: getProportionateScreenWidth(kDefaultPadding),
            //         ),
            //         SizedBox(height: kDefaultPadding * 0.5),
            //         Text(
            //           "Loading...",
            //           style: TextStyle(color: kPrimaryColor),
            //         ),
            //       ],
            //     ),
            //   ),
            //   child: Padding(
            //     padding: EdgeInsets.symmetric(
            //         horizontal:
            //             getProportionateScreenWidth(kDefaultPadding / 2),
            //         vertical:
            //             getProportionateScreenHeight(kDefaultPadding / 2)),
            //     child: games != null && games.length > 0
            //         ? ListView.separated(
            //             itemBuilder: (context, index) {
            //               return Column(
            //                 children: [
            //                   Container(
            //                     decoration: BoxDecoration(
            //                       borderRadius:
            //                           BorderRadius.circular(kDefaultPadding),
            //                       image: DecorationImage(
            //                         image:
            //                             games[index]['game_banner'] != null &&
            //                                     games[index]['game_banner']
            //                                         .isNotEmpty
            //                                 ? NetworkImage(
            //                                     games[index]['game_banner'])
            //                                 : AssetImage(
            //                                     DateTime.now().isBefore(
            //                                                 euroPredictEnd) &&
            //                                             DateTime.now().isAfter(
            //                                                 euroPredictStart)
            //                                         ? "images/pl_logos/banner.png"
            //                                         : "images/pl_logos/pl_bg_dr.png",
            //                                   ),
            //                         fit: BoxFit.fill,
            //                       ),
            //                     ),
            //                     child: Padding(
            //                       padding: const EdgeInsets.all(8.0),
            //                       child: Column(
            //                         children: [
            //                           CustomTag(
            //                             color: Colors.transparent,
            //                             text: games[index]['type']
            //                                 .toString()
            //                                 .toUpperCase(),
            //                             textColor: kBlackColor,
            //                           ),
            //                           Container(
            //                             child: Row(
            //                               mainAxisAlignment:
            //                                   MainAxisAlignment.spaceBetween,
            //                               children: [
            //                                 Expanded(
            //                                   child: Column(
            //                                     children: [
            //                                       ImageContainer(
            //                                         shape: BoxShape.rectangle,
            //                                         url: games[index][
            //                                                 'home_team_logo'] ??
            //                                             '',
            //                                         errorUrl:
            //                                             "images/pl_logos/${games[index]['home_team'].toString().toLowerCase()}.png",
            //                                         height:
            //                                             getProportionateScreenHeight(
            //                                                 kDefaultPadding *
            //                                                     3),
            //                                         width:
            //                                             getProportionateScreenWidth(
            //                                                 kDefaultPadding *
            //                                                     3),
            //                                         borderRadius:
            //                                             BorderRadius.circular(
            //                                                 getProportionateScreenHeight(
            //                                                     5)),
            //                                       ),
            //                                       // Container(
            //                                       //   height:
            //                                       //       getProportionateScreenHeight(
            //                                       //           kDefaultPadding *
            //                                       //               3),
            //                                       //   width:
            //                                       //       getProportionateScreenWidth(
            //                                       //           kDefaultPadding *
            //                                       //               3),
            //                                       //   decoration: BoxDecoration(
            //                                       //     image: DecorationImage(
            //                                       //       image: games[index][
            //                                       //                       'home_team_logo'] !=
            //                                       //                   null &&
            //                                       //               games[index][
            //                                       //                       'home_team_logo']
            //                                       //                   .isNotEmpty
            //                                       //           ? NetworkImage(games[
            //                                       //                   index][
            //                                       //               'home_team_logo'])
            //                                       //           : AssetImage(
            //                                       //               "images/pl_logos/${games[index]['home_team'].toString().toLowerCase()}.png"),
            //                                       //       fit: BoxFit.fill,
            //                                       //     ),
            //                                       //     shape: BoxShape.rectangle,
            //                                       //     color: kPrimaryColor,
            //                                       //     borderRadius:
            //                                       //         BorderRadius.circular(
            //                                       //             getProportionateScreenHeight(
            //                                       //                 5)),
            //                                       //   ),
            //                                       // ),
            //                                       SizedBox(
            //                                         height:
            //                                             getProportionateScreenHeight(
            //                                                 kDefaultPadding /
            //                                                     2),
            //                                       ),
            //                                       CustomTag(
            //                                         color: Colors.transparent,
            //                                         text: games[index]
            //                                             ['home_team'],
            //                                       )
            //                                       // Text(
            //                                       //   games[index]['home_team'],
            //                                       //   style: Theme.of(context)
            //                                       //       .textTheme
            //                                       //       .bodyLarge
            //                                       //       ?.copyWith(
            //                                       //           color:
            //                                       //               kPrimaryColor,
            //                                       //           fontWeight:
            //                                       //               FontWeight
            //                                       //                   .w600),
            //                                       // )
            //                                     ],
            //                                   ),
            //                                 ),
            //                                 Text(
            //                                   games[index]['is_finished']
            //                                       ? games[index]['home_score']
            //                                           .toString()
            //                                       : "-",
            //                                   style: Theme.of(context)
            //                                       .textTheme
            //                                       .titleLarge
            //                                       ?.copyWith(
            //                                         color: kPrimaryColor,
            //                                         fontWeight: FontWeight.bold,
            //                                       ),
            //                                 ),
            //                                 Text(
            //                                   "\t:\t",
            //                                   style: Theme.of(context)
            //                                       .textTheme
            //                                       .titleLarge
            //                                       ?.copyWith(
            //                                         color: kPrimaryColor,
            //                                         fontWeight: FontWeight.bold,
            //                                       ),
            //                                 ),
            //                                 Text(
            //                                   games[index]['is_finished']
            //                                       ? games[index]['away_score']
            //                                           .toString()
            //                                       : "-",
            //                                   style: Theme.of(context)
            //                                       .textTheme
            //                                       .titleLarge
            //                                       ?.copyWith(
            //                                         color: kPrimaryColor,
            //                                         fontWeight: FontWeight.bold,
            //                                       ),
            //                                 ),
            //                                 Expanded(
            //                                   child: Column(
            //                                     children: [
            //                                       ImageContainer(
            //                                         shape: BoxShape.rectangle,
            //                                         url: games[index][
            //                                                 'away_team_logo'] ??
            //                                             '',
            //                                         errorUrl:
            //                                             "images/pl_logos/${games[index]['away_team'].toString().toLowerCase()}.png",
            //                                         height:
            //                                             getProportionateScreenHeight(
            //                                                 kDefaultPadding *
            //                                                     3),
            //                                         width:
            //                                             getProportionateScreenWidth(
            //                                                 kDefaultPadding *
            //                                                     3),
            //                                         borderRadius:
            //                                             BorderRadius.circular(
            //                                                 getProportionateScreenHeight(
            //                                                     5)),
            //                                       ),
            //                                       // Container(
            //                                       //   height:
            //                                       //       getProportionateScreenHeight(
            //                                       //           kDefaultPadding *
            //                                       //               3),
            //                                       //   width:
            //                                       //       getProportionateScreenWidth(
            //                                       //           kDefaultPadding *
            //                                       //               3),
            //                                       //   decoration: BoxDecoration(
            //                                       //     image: DecorationImage(
            //                                       //       image: AssetImage(
            //                                       //             "images/pl_logos/${games[index]['away_team'].toString().toLowerCase()}.png",
            //                                       //       ),
            //                                       //       fit: BoxFit.fill,
            //                                       //     ),
            //                                       //     shape: BoxShape.rectangle,
            //                                       //     color: kPrimaryColor,
            //                                       //     borderRadius:
            //                                       //         BorderRadius.circular(
            //                                       //             getProportionateScreenHeight(
            //                                       //                 5)),
            //                                       //   ),
            //                                       // ),
            //                                       SizedBox(
            //                                         height:
            //                                             getProportionateScreenHeight(
            //                                                 kDefaultPadding /
            //                                                     2),
            //                                       ),
            //                                       CustomTag(
            //                                         color: Colors.transparent,
            //                                         text: games[index]
            //                                             ['away_team'],
            //                                       ),
            //                                       // Text(
            //                                       //   games[index]['away_team'],
            //                                       //   style: Theme.of(context)
            //                                       //       .textTheme
            //                                       //       .bodyLarge
            //                                       //       ?.copyWith(
            //                                       //           color:
            //                                       //               kPrimaryColor,
            //                                       //           fontWeight:
            //                                       //               FontWeight
            //                                       //                   .w600),
            //                                       // )
            //                                     ],
            //                                   ),
            //                                 ),
            //                               ],
            //                             ),
            //                           ),
            //                           SizedBox(
            //                             height: getProportionateScreenHeight(
            //                                 kDefaultPadding / 4),
            //                           ),
            //                           Text(
            //                             "${games[index]['game_time'].split('T')[0]} ${games[index]['game_time'].split('T')[1].split(".")[0]}",
            //                             style: Theme.of(context)
            //                                 .textTheme
            //                                 .bodySmall
            //                                 ?.copyWith(
            //                                   color: kWhiteColor,
            //                                   fontWeight: FontWeight.bold,
            //                                 ),
            //                           ),
            //                           SizedBox(
            //                             height: getProportionateScreenHeight(
            //                                 kDefaultPadding / 4),
            //                           ),
            //                           Text(
            //                             games[index]['stadium']
            //                                 .toString()
            //                                 .toUpperCase(),
            //                             style: Theme.of(context)
            //                                 .textTheme
            //                                 .bodySmall
            //                                 ?.copyWith(
            //                                   color: kWhiteColor,
            //                                   fontWeight: FontWeight.bold,
            //                                 ),
            //                           ),
            //                           SizedBox(
            //                             height: getProportionateScreenHeight(
            //                                 kDefaultPadding / 2),
            //                           ),
            //                           if (!games[index]['is_finished'])
            //                             InkWell(
            //                               onTap: () {
            //                                 Navigator.push(
            //                                   context,
            //                                   MaterialPageRoute(
            //                                     builder: (context) {
            //                                       return PredictScreen(
            //                                           game: games[index]);
            //                                     },
            //                                   ),
            //                                 ).then((value) {
            //                                   _getGames();
            //                                   _getPredictions();
            //                                 });
            //                               },
            //                               child: Container(
            //                                 alignment: Alignment.center,
            //                                 width: kDefaultPadding * 10,
            //                                 padding: EdgeInsets.all(
            //                                     kDefaultPadding * 0.75),
            //                                 decoration: BoxDecoration(
            //                                   color: kWhiteColor,
            //                                   borderRadius: BorderRadius.all(
            //                                     Radius.circular(
            //                                         kDefaultPadding / 2),
            //                                   ),
            //                                   // boxShadow: [boxShadow],
            //                                 ),
            //                                 child: Text(
            //                                   "PREDICT & WIN",
            //                                   style: Theme.of(context)
            //                                       .textTheme
            //                                       .bodySmall
            //                                       ?.copyWith(
            //                                         color: worldCupColor,
            //                                         fontWeight: FontWeight.bold,
            //                                       ),
            //                                 ),
            //                               ),
            //                             ),
            //                           SizedBox(
            //                             height: getProportionateScreenHeight(
            //                                 kDefaultPadding / 2),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               );
            //             },
            //             separatorBuilder: (BuildContext context, int index) =>
            //                 SizedBox(
            //                   height: getProportionateScreenWidth(
            //                       kDefaultPadding / 2),
            //                 ),
            //             itemCount: games.length)
            //         : _isLoading
            //             ? Container()
            //             : Center(
            //                 child: Text("No games to show..."),
            //               ),
            //   ),
            // ),
