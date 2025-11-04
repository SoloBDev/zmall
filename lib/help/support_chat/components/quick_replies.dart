import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class QuickReplies extends StatelessWidget {
  final Function(String) onReplyTap;

  const QuickReplies({Key? key, required this.onReplyTap}) : super(key: key);

  static final List<QuickReply> replies = [
    QuickReply(text: "Where is my order?", icon: HeroiconsOutline.mapPin),
    QuickReply(
      text: "Show me my last order",
      icon: HeroiconsOutline.shoppingBag,
    ),
    QuickReply(
      text: "What is my order status",
      icon: HeroiconsOutline.clipboardDocumentCheck,
    ),

    QuickReply(
      text: "What are today's special offers?",
      icon: HeroiconsOutline.sparkles,
    ),
    QuickReply(
      text: "Show me restaurants near me",
      icon: HeroiconsOutline.buildingStorefront,
    ),
    QuickReply(
      text: "Show me top selling stores this week",
      icon: HeroiconsOutline.fire,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: getProportionateScreenHeight(kDefaultPadding),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: getProportionateScreenHeight(kDefaultPadding / 2),
        children: [
          Text(
            "Quick Replies",
            style: TextStyle(
              fontSize: getProportionateScreenWidth(12),
              fontWeight: FontWeight.bold,
              color: kBlackColor,
            ),
          ),

          Wrap(
            spacing: getProportionateScreenWidth(kDefaultPadding / 2),
            runSpacing: getProportionateScreenHeight(kDefaultPadding / 2),
            children: replies
                .map(
                  (reply) => _QuickReplyChip(
                    reply: reply,
                    onTap: () => onReplyTap(reply.text),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final QuickReply reply;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.reply, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding / 1.5),
          vertical: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: getProportionateScreenWidth(6),
          children: [
            Icon(
              reply.icon,
              size: getProportionateScreenWidth(14),
              color: kSecondaryColor,
            ),

            Text(
              reply.text,
              style: TextStyle(
                fontSize: getProportionateScreenWidth(12),
                color: kBlackColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickReply {
  final String text;
  final IconData icon;

  QuickReply({required this.text, required this.icon});
}
