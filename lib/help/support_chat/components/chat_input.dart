import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final VoidCallback? onQuickRepliesToggle;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.onQuickRepliesToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
        vertical: getProportionateScreenHeight(kDefaultPadding / 2),
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quick Replies Button
            if (onQuickRepliesToggle != null)
              GestureDetector(
                onTap: onQuickRepliesToggle,
                child: Container(
                  width: getProportionateScreenWidth(45),
                  height: getProportionateScreenWidth(45),
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kGreyColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    HeroiconsOutline.sparkles,
                    color: kSecondaryColor,
                    size: getProportionateScreenWidth(20),
                  ),
                ),
              ),
            if (onQuickRepliesToggle != null)
              SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: kGreyColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    hintStyle: TextStyle(
                      color: kGreyColor.withValues(alpha: 0.6),
                      fontSize: getProportionateScreenWidth(13),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                      vertical: getProportionateScreenHeight(
                        kDefaultPadding / 1.5,
                      ),
                    ),
                    prefixIcon: Icon(
                      HeroiconsOutline.chatBubbleLeftRight,
                      color: kGreyColor.withValues(alpha: 0.5),
                      size: getProportionateScreenWidth(20),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(14),
                    color: kBlackColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
            GestureDetector(
              onTap: isLoading ? null : _handleSend,
              child: Container(
                width: getProportionateScreenWidth(45),
                height: getProportionateScreenWidth(45),
                decoration: BoxDecoration(
                  color: kSecondaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kSecondaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading
                    ? Padding(
                        padding: EdgeInsets.all(
                          getProportionateScreenWidth(kDefaultPadding / 1.5),
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kPrimaryColor,
                          ),
                        ),
                      )
                    : Icon(
                        HeroiconsSolid.paperAirplane,
                        color: kPrimaryColor,
                        size: getProportionateScreenWidth(22),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    if (controller.text.trim().isNotEmpty && !isLoading) {
      onSend();
    }
  }
}
