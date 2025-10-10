import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/world_cup/components/logo_container.dart';

class MatchRow extends StatelessWidget {
  final String homeClubName;
  final String homeClubLogo;
  final String homeErrorClubLogo;
  final String awayErrorClubLogo;
  final String awayClubName;
  final String awayClubLogo;
  final String status; // "NS" = Not started, "FT" = Finished
  final String timeOrScore;
  final String stadium;
  final String gameType;
  final bool isFinished;
  final VoidCallback? onPredictTap;
  final ImageProvider<Object> bannerImage;

  const MatchRow(
      {super.key,
      required this.homeClubName,
      required this.homeClubLogo,
      required this.awayClubName,
      required this.awayClubLogo,
      required this.status,
      required this.timeOrScore,
      required this.stadium,
      required this.gameType,
      required this.isFinished,
      this.onPredictTap,
      required this.bannerImage,
      required this.homeErrorClubLogo,
      required this.awayErrorClubLogo});

  @override
  Widget build(BuildContext context) {
    String formatGameTime(String gameTime) {
      DateTime dt = DateTime.parse(gameTime); // parse the ISO string
      String time = DateFormat('HH:mm').format(dt); // 03:00
      String date = DateFormat('dd MMM').format(dt); // 18 Aug
      return '$time\n$date';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        image: DecorationImage(
          image: bannerImage,
          fit: BoxFit.cover,
        ),
      ),
      child: InkWell(
        // Predict button
        onTap: !isFinished && onPredictTap != null
            ? onPredictTap
            : () {
                Service.showMessage(
                    context: context,
                    title: "The game is finished. You can guess other games.",
                    error: false);
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game Type
            Text(
              gameType.toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kPrimaryColor
                  // Colors.black54,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Clubs Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        homeClubName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: kPrimaryColor),
                      ),
                      const SizedBox(width: 8),
                      LogoContainer(
                        logoUrl: homeClubLogo,
                        errorLogoAsset: homeErrorClubLogo,
                      ),
                      // Image.network(
                      //   homeClubLogo,
                      //   height: 32,
                      //   width: 32,
                      //   errorBuilder: (_, __, ___) =>
                      //       const Icon(Icons.sports_soccer, color: kPrimaryColor),
                      // ),
                    ],
                  ),
                ),

                // Score or Time
                Text(
                  isFinished ? timeOrScore : formatGameTime(timeOrScore),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      // color: Colors.blueAccent,
                      color: kPrimaryColor),
                ),

                // Away
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      LogoContainer(
                          logoUrl: awayClubLogo,
                          errorLogoAsset: awayErrorClubLogo),
                      const SizedBox(width: 8),
                      Text(
                        awayClubName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Statis
            if (status.toLowerCase() == 'ft')
              Text(
                "Finished",
                style: const TextStyle(fontSize: 12, color: kPrimaryColor
                    // color: Colors.black54
                    ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 4),
            // Stadium
            Text(
              stadium.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: kPrimaryColor
                  // color: Colors.black54,

                  ),
              textAlign: TextAlign.center,
            ),
            // const SizedBox(height: 4),

            // Predict button
            // if (!isFinished && onPredictTap != null)
            //   InkWell(
            //     onTap: onPredictTap,
            //     child: Container(
            //       alignment: Alignment.center,
            //       padding: const EdgeInsets.symmetric(vertical: 8),
            //       decoration: BoxDecoration(
            //         color: kWhiteColor,
            //         //  Colors.orangeAccent,,
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       child: const Text(
            //         "PREDICT & WIN",
            //         style: TextStyle(
            //             fontWeight: FontWeight.bold, color: kBlackColor),
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// class SoccerPredictionCard extends StatelessWidget {
//   final Map<String, dynamic> game;
//   final VoidCallback onPredict;
//   final double kDefaultPadding;
//   final Color kPrimaryColor;
//   final Color kWhiteColor;
//   final Color kBlackColor;
//   final Color worldCupColor;
//   final Widget Function(String url, String errorUrl, double height,
//       double width, BorderRadius borderRadius) imageBuilder;
//   final Widget Function(Color color, String text, {Color? textColor})
//       tagBuilder;

//   const SoccerPredictionCard({
//     super.key,
//     required this.game,
//     required this.onPredict,
//     required this.kDefaultPadding,
//     required this.kPrimaryColor,
//     required this.kWhiteColor,
//     required this.kBlackColor,
//     required this.worldCupColor,
//     required this.imageBuilder,
//     required this.tagBuilder,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(kDefaultPadding),
//         image: DecorationImage(
//           image: game['game_banner'] != null && game['game_banner'].isNotEmpty
//               ? NetworkImage(game['game_banner'])
//               : AssetImage(
//                   _isWithinEuroPrediction()
//                       ? "images/pl_logos/banner.png"
//                       : "images/pl_logos/pl_bg_dr.png",
//                 ) as ImageProvider,
//           fit: BoxFit.fill,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           spacing: kDefaultPadding,
//           children: [
//             // Game type tag
//             tagBuilder(
//               Colors.transparent,
//               game['type'].toString().toUpperCase(),
//               textColor: kBlackColor,
//             ),

//             // Teams & score row
//             _buildTeamsRow(context),

//             // Game time
//             Text(
//               "${game['game_time'].split('T')[0]} ${game['game_time'].split('T')[1].split(".")[0]}",
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: kWhiteColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),

//             // Stadium
//             Text(
//               game['stadium'].toString().toUpperCase(),
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: kWhiteColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),

//             // Predict & Win button
//             if (!game['is_finished'])
//               InkWell(
//                 onTap: onPredict,
//                 child: Container(
//                   alignment: Alignment.center,
//                   width: kDefaultPadding * 10,
//                   padding: EdgeInsets.all(kDefaultPadding * 0.75),
//                   decoration: BoxDecoration(
//                     color: kWhiteColor,
//                     borderRadius: BorderRadius.all(
//                       Radius.circular(kDefaultPadding / 2),
//                     ),
//                   ),
//                   child: Text(
//                     "PREDICT & WIN",
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: worldCupColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTeamsRow(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildTeamColumn(
//           game['home_team_logo'] ?? '',
//           "images/pl_logos/${game['home_team'].toString().toLowerCase()}.png",
//           game['home_team'],
//         ),
//         Text(
//           game['is_finished'] ? game['home_score'].toString() : "-",
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: kPrimaryColor,
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         Text(
//           "\t:\t",
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: kPrimaryColor,
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         Text(
//           game['is_finished'] ? game['away_score'].toString() : "-",
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: kPrimaryColor,
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         _buildTeamColumn(
//           game['away_team_logo'] ?? '',
//           "images/pl_logos/${game['away_team'].toString().toLowerCase()}.png",
//           game['away_team'],
//         ),
//       ],
//     );
//   }

//   Widget _buildTeamColumn(String logoUrl, String errorUrl, String teamName) {
//     return Expanded(
//       child: Column(
//         children: [
//           imageBuilder(
//             logoUrl,
//             errorUrl,
//             kDefaultPadding * 3,
//             kDefaultPadding * 3,
//             BorderRadius.circular(5),
//           ),
//           SizedBox(height: kDefaultPadding / 2),
//           tagBuilder(Colors.transparent, teamName),
//         ],
//       ),
//     );
//   }

//   bool _isWithinEuroPrediction() {
//     final now = DateTime.now();
//     // Replace with your actual start/end times
//     DateTime euroPredictStart = DateTime(2024, 6, 10);
//     DateTime euroPredictEnd = DateTime(2024, 7, 10);
//     return now.isBefore(euroPredictEnd) && now.isAfter(euroPredictStart);
//   }
// }
