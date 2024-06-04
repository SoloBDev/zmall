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
import 'package:zmall/world_cup.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({
    Key? key,
    @required this.game,
  }) : super(key: key);

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
  @override
  void initState() {
    // TODO: implement initState
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
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Prediction submitted successfully! Good luck...", false,
          duration: 4));
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
      body: ModalProgressHUD(
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
        child: SingleChildScrollView(
          child: Column(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTag(
                        color: Colors.lightBlueAccent,
                        text: widget.game['type'].toString().toUpperCase()),
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
                                    color: kPrimaryColor,
                                  ),
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 2),
                                ),
                                CustomTag(
                                  color: Colors.lightBlueAccent,
                                  text: widget.game['home_team'].toString().toUpperCase(),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.game['is_finished']
                                ? widget.game['home_score'].toString()
                                : "-",
                            style:
                                Theme.of(context).textTheme.headline6?.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            "\t:\t",
                            style:
                                Theme.of(context).textTheme.headline6?.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            widget.game['is_finished']
                                ? widget.game['away_score'].toString()
                                : "-",
                            style:
                                Theme.of(context).textTheme.headline6?.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
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
                                  color: Colors.lightBlueAccent,
                                  text: widget.game['away_team'].toString().toUpperCase(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Container(
                      color: kBlackColor.withOpacity(0.3),
                      child: Text(
                        "${widget.game['game_time'].split('T')[0]} ${widget.game['game_time'].split('T')[1].split(".")[0]}",
                        style: Theme.of(context).textTheme.caption?.copyWith(
                              color: kWhiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Container(
                      color: kBlackColor.withOpacity(0.2),
                      child: Text(
                        widget.game['stadium'].toString().toUpperCase(),
                        style: Theme.of(context).textTheme.caption?.copyWith(
                              color: kWhiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
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
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          fontWeight: FontWeight.w500, color: kPrimaryColor),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 1.5),
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
                                print("User not logged in...");
                                ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        "Please login in...", true));
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
                            getProportionateScreenWidth(kDefaultPadding / 1.5),
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
                                print("User not logged in...");
                                ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        "Please login in...", true));
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
                                  .bodyText1
                                  ?.copyWith(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(
                            getProportionateScreenWidth(kDefaultPadding / 1.5),
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
                                print("User not logged in...");
                                ScaffoldMessenger.of(context).showSnackBar(
                                    Service.showMessage(
                                        "Please login in...", true));
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
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
                ),
                child: Column(
                  children: [
                    Text(
                      "You think the score will be...",
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          fontWeight: FontWeight.w500, color: kPrimaryColor),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    Row(
                      children: [
                        TeamContainer(
                          teamName: widget.game['home_team'],
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  homeScore++;
                                });
                              },
                              child: Container(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding * 2.5),
                                decoration: BoxDecoration(
                                  color: kSecondaryColor,
                                  boxShadow: [boxShadow],
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                    topLeft: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                    padding: EdgeInsets.all(
                                        getProportionateScreenHeight(
                                            kDefaultPadding / 1.5)),
                                    child: Text(
                                      "+",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline6
                                          ?.copyWith(
                                            color: kPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    )),
                              ),
                            ),
                            SizedBox(
                              height: 1,
                            ),
                            Container(
                              color: kSecondaryColor.withOpacity(0.8),
                              width: getProportionateScreenWidth(
                                  kDefaultPadding * 2.5),
                              child: Padding(
                                padding: EdgeInsets.all(
                                    getProportionateScreenHeight(
                                        kDefaultPadding / 2)),
                                child: Text(
                                  homeScore.toString(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline6
                                      ?.copyWith(
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 1,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (homeScore > 0) {
                                  setState(() {
                                    homeScore--;
                                  });
                                }
                              },
                              child: Container(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding * 2.5),
                                decoration: BoxDecoration(
                                  color: kSecondaryColor,
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                    bottomLeft: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      getProportionateScreenHeight(
                                          kDefaultPadding / 1.5)),
                                  child: Text(
                                    "-",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        ?.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: getProportionateScreenWidth(kDefaultPadding),
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  awayScore++;
                                });
                              },
                              child: Container(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding * 2.5),
                                decoration: BoxDecoration(
                                  color: kSecondaryColor,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                    topLeft: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                    padding: EdgeInsets.all(
                                        getProportionateScreenHeight(
                                            kDefaultPadding / 1.5)),
                                    child: Text(
                                      "+",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline6
                                          ?.copyWith(
                                            color: kPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    )),
                              ),
                            ),
                            SizedBox(
                              height: 1,
                            ),
                            Container(
                              color: kSecondaryColor.withOpacity(0.8),
                              width: getProportionateScreenWidth(
                                  kDefaultPadding * 2.5),
                              child: Padding(
                                  padding: EdgeInsets.all(
                                      getProportionateScreenHeight(
                                          kDefaultPadding / 2)),
                                  child: Text(
                                    awayScore.toString(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        ?.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  )),
                            ),
                            SizedBox(
                              height: 1,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (awayScore > 0) {
                                  setState(() {
                                    awayScore--;
                                  });
                                }
                              },
                              child: Container(
                                width: getProportionateScreenWidth(
                                    kDefaultPadding * 2.5),
                                decoration: BoxDecoration(
                                  color: kSecondaryColor,
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                    bottomLeft: Radius.circular(
                                      getProportionateScreenWidth(
                                          kDefaultPadding / 1.5),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      getProportionateScreenHeight(
                                          kDefaultPadding / 1.5)),
                                  child: Text(
                                    "-",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        ?.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TeamContainer(
                          teamName: widget.game['away_team'],
                        ),
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
              if (predicted)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              CustomTag(
                                color: Colors.green,
                                text: widget.game['home_team'],
                              ),
                              SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding / 4),
                              ),
                              Text(
                                "${(widget.game['home_win_count'] / (widget.game['home_win_count'] + widget.game['draw_count'] + widget.game['away_win_count']) * 100).toString().split(".")[0]}%",
                                style: Theme.of(context)
                                    .textTheme
                                    .caption
                                    ?.copyWith(color: kPrimaryColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              CustomTag(
                                color: kGreyColor,
                                text: "Draw",
                              ),
                              SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding / 4),
                              ),
                              Text(
                                "${(widget.game['draw_count'] / (widget.game['home_win_count'] + widget.game['draw_count'] + widget.game['away_win_count']) * 100).toString().split(".")[0]}%",
                                style: Theme.of(context)
                                    .textTheme
                                    .caption
                                    ?.copyWith(color: kPrimaryColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              CustomTag(
                                color: Colors.blue,
                                text: widget.game['away_team'],
                              ),
                              SizedBox(
                                height: getProportionateScreenWidth(
                                    kDefaultPadding / 4),
                              ),
                              Text(
                                "${(widget.game['away_win_count'] / (widget.game['home_win_count'] + widget.game['draw_count'] + widget.game['away_win_count']) * 100).toString().split(".")[0]}%",
                                style: Theme.of(context)
                                    .textTheme
                                    .caption
                                    ?.copyWith(color: kPrimaryColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height:
                            getProportionateScreenWidth(kDefaultPadding / 4),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: widget.game['home_win_count'],
                            child: Container(
                              height: getProportionateScreenWidth(
                                  kDefaultPadding * 1.2),
                              padding: EdgeInsets.all(
                                  getProportionateScreenWidth(
                                      kDefaultPadding / 4)),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding / 3),
                                  ),
                                  topLeft: Radius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding / 3),
                                  ),
                                ),
                              ),
                              // child: Text(
                              //   "${(widget.game['home_win_count'] / (widget.game['home_win_count'] + widget.game['draw_count'] + widget.game['away_win_count']) * 100).toString().split(".")[0]}%",
                              //   style: Theme.of(context)
                              //       .textTheme
                              //       .caption
                              //       .copyWith(color: kPrimaryColor),
                              //   textAlign: TextAlign.center,
                              // ),
                            ),
                          ),
                          Expanded(
                            flex: widget.game['draw_count'],
                            child: Container(
                              height: getProportionateScreenWidth(
                                  kDefaultPadding * 1.2),
                              padding: EdgeInsets.all(
                                  getProportionateScreenWidth(
                                      kDefaultPadding / 4)),
                              color: kGreyColor,
                              // child: Text(
                              //   "${(widget.game['draw_count'] / (widget.game['home_win_count'] + widget.game['draw_count'] + widget.game['away_win_count']) * 100).toString().split(".")[0]}%",
                              //   style: Theme.of(context)
                              //       .textTheme
                              //       .caption
                              //       .copyWith(color: kPrimaryColor),
                              //   textAlign: TextAlign.center,
                              // ),
                            ),
                          ),
                          Expanded(
                            flex: widget.game['away_win_count'],
                            child: Container(
                              height: getProportionateScreenWidth(
                                  kDefaultPadding * 1.2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding / 2),
                                  ),
                                  bottomRight: Radius.circular(
                                    getProportionateScreenWidth(
                                        kDefaultPadding / 2),
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.all(
                                  getProportionateScreenWidth(
                                      kDefaultPadding / 4)),
                              // child: Text(
                              //   "${(widget.game['away_win_count'] / (widget.game['home_win_count'] + widget.game['draw_count'] + widget.game['away_win_count']) * 100).toString().split(".")[0]}%",
                              //   style: Theme.of(context)
                              //       .textTheme
                              //       .caption
                              //       .copyWith(color: kPrimaryColor),
                              //   textAlign: TextAlign.center,
                              // ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              if (!predicted)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  child: CustomButton(
                    title: "Submit",
                    press: () {
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
                    },
                    color: kSecondaryColor,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> getPredictions() async {
    var url =
        "https://app.zmallapp.com/api/admin/get_prediction_history";
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
            Service.showMessage("Something went wrong!", true, duration: 3),
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

  Future<dynamic> predictGame() async {
    var url =
        "https://app.zmallapp.com/api/admin/predict_game";
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
            Service.showMessage("Something went wrong!", true, duration: 3),
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

class TeamContainer extends StatelessWidget {
  const TeamContainer({
    Key? key,
    required this.teamName,
  }) : super(key: key);

  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: getProportionateScreenHeight(kDefaultPadding * 2),
            width: getProportionateScreenWidth(kDefaultPadding * 2),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/pl_logos/${teamName.toString().toLowerCase()}.png"),
                fit: BoxFit.fill,
              ),
              shape: BoxShape.rectangle,
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(getProportionateScreenHeight(5)),
            ),
          ),
          SizedBox(
            height: getProportionateScreenHeight(kDefaultPadding / 2),
          ),
          CustomTag(
            color: Colors.transparent,
            text: teamName.toUpperCase(),
          ),
        ],
      ),
    );
  }
}
