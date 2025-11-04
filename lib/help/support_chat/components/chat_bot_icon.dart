import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class ChatBotIcon extends StatelessWidget {
  final double? width;
  final double? height;
  final double? iconSize;
  const ChatBotIcon({super.key, this.width, this.height, this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: getProportionateScreenWidth(width ?? 32),
      height: getProportionateScreenWidth(height ?? 32),
      decoration: BoxDecoration(
        color: kWhiteColor,
        //  kSecondaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: kGreyColor.withValues(alpha: 0.1), width: 1),
      ),
      child: Icon(
        Icons.support_agent_rounded,
        color: kBlackColor,
        size: getProportionateScreenWidth(iconSize ?? 18),
      ),
    );
  }
}
