import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/world_cup/components/team_container_widget.dart';

// A reusable widget for predicting match scores
class ScorePredictionWidget extends StatelessWidget {
  final bool isPredicted;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final VoidCallback onHomeIncrement;
  final VoidCallback onHomeDecrement;
  final VoidCallback onAwayIncrement;
  final VoidCallback onAwayDecrement;

  const ScorePredictionWidget({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.onHomeIncrement,
    required this.onHomeDecrement,
    required this.onAwayIncrement,
    required this.onAwayDecrement,
    required this.isPredicted,
  });

  Widget buildScoreColumn(
      {required int score,
      required VoidCallback onIncrement,
      required VoidCallback onDecrement,
      required BuildContext context}) {
    return Column(
      children: [
        GestureDetector(
          onTap: isPredicted
              ? () {
                  Service.showMessage(
                      context: context,
                      title: "The game is already predicted",
                      error: true);
                }
              : onIncrement,
          child: Container(
            width: getProportionateScreenWidth(kDefaultPadding * 2.5),
            decoration: BoxDecoration(
              color: kSecondaryColor,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 1.5)),
                topLeft: Radius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 1.5)),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                  getProportionateScreenHeight(kDefaultPadding / 1.5)),
              child: Text(
                "+",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Container(
          color: kSecondaryColor.withValues(alpha: 0.8),
          width: getProportionateScreenWidth(kDefaultPadding * 2.5),
          child: Padding(
            padding: EdgeInsets.all(
                getProportionateScreenHeight(kDefaultPadding / 2)),
            child: Text(
              score.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 1),
        GestureDetector(
          onTap: isPredicted
              ? () {
                  Service.showMessage(
                      context: context,
                      title: "The game is already predicted",
                      error: true);
                }
              : onDecrement,
          child: Container(
            width: getProportionateScreenWidth(kDefaultPadding * 2.5),
            decoration: BoxDecoration(
              color: kSecondaryColor,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 1.5)),
                bottomLeft: Radius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 1.5)),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                  getProportionateScreenHeight(kDefaultPadding / 1.5)),
              child: Text(
                "-",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
        vertical: getProportionateScreenWidth(kDefaultPadding / 8),
      ),
      child: Column(
        children: [
          Text(
            "You think the score will be...",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: kPrimaryColor,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
          Row(
            children: [
              TeamContainer(teamName: homeTeam),
              buildScoreColumn(
                score: homeScore,
                onIncrement: onHomeIncrement,
                onDecrement: onHomeDecrement,
                context: context,
              ),
              SizedBox(width: getProportionateScreenWidth(kDefaultPadding)),
              buildScoreColumn(
                score: awayScore,
                onIncrement: onAwayIncrement,
                onDecrement: onAwayDecrement,
                context: context,
              ),
              TeamContainer(teamName: awayTeam),
            ],
          ),
        ],
      ),
    );
  }
}
