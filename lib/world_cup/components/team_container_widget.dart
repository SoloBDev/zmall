import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_tag.dart';

class TeamContainer extends StatelessWidget {
  const TeamContainer({
    super.key,
    required this.teamName,
  });

  final String teamName;

  @override
  Widget build(BuildContext context) {
    // DateTime euroPredictStart = DateTime(2024, 06, 10);
    // DateTime euroPredictEnd = DateTime(2024, 07, 15);
    return Expanded(
      child: Column(
        children: [
          Container(
            height: getProportionateScreenHeight(kDefaultPadding * 3),
            width: getProportionateScreenWidth(kDefaultPadding * 3),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "images/pl_logos/${teamName.toString().toLowerCase()}.png"),
                fit: BoxFit.fill,
              ),
              shape: BoxShape.rectangle,
              color: kPrimaryColor.withValues(alpha: 0.6),
              borderRadius:
                  BorderRadius.circular(getProportionateScreenHeight(5)),
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
