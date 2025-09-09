import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/constants.dart';
import 'package:flutter/material.dart';
import 'package:zmall/world_cup/my_prediction.dart';
import 'package:zmall/world_cup/available_games.dart';

class WorldCupScreen extends StatelessWidget {
  const WorldCupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime euroPredictStart = DateTime(2024, 06, 10);
    DateTime euroPredictEnd = DateTime(2024, 07, 15);
    var currentYear = now.year % 100;
    var nextYear = (now.year + 1) % 100;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBlackColor,
        appBar: AppBar(
          backgroundColor: kBlackColor,
          title: Text(
            DateTime.now().isBefore(euroPredictEnd) &&
                    DateTime.now().isAfter(euroPredictStart)
                ? "UEFA Euro 2024"
                : "Predict $currentYear/$nextYear",
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
            unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
            unselectedLabelColor: kWhiteColor,
            indicatorColor: Colors.lightBlueAccent,
            labelStyle: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.bold),
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
                      HeroiconsOutline.clock,
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
          children: [AvailableGames(), MyPrediction()],
        ),
      ),
    );
  }
}
