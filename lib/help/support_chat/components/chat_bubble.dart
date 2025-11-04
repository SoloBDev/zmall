import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zmall/help/support_chat/components/chat_bot_icon.dart';
import 'package:zmall/models/chat_message.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String? imageUrl;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.imageUrl,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
        vertical: getProportionateScreenHeight(kDefaultPadding / 3),
      ),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(isBot: true),
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: message.isUser ? onLongPress : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(
                        kDefaultPadding / 2,
                      ),
                      vertical: getProportionateScreenHeight(
                        kDefaultPadding / 2,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser ? kSecondaryColor : kWhiteColor,
                      border: Border.all(color: kWhiteColor),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                        bottomRight: Radius.circular(message.isUser ? 0 : 20),
                      ),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: kBlackColor.withValues(alpha: 0.08),
                      //     blurRadius: 8,
                      //     offset: Offset(0, 2),
                      //   ),
                      // ],
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                        color: message.isUser ? kPrimaryColor : kBlackColor,
                        fontSize: getProportionateScreenWidth(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(
                      kDefaultPadding / 2,
                    ),
                  ),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: kGreyColor,
                      fontSize: getProportionateScreenWidth(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
            _buildAvatar(isBot: false),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isBot}) {
    return isBot
        ? ChatBotIcon()
        : Container(
            width: getProportionateScreenWidth(32),
            height: getProportionateScreenWidth(32),
            decoration: BoxDecoration(
              color: kWhiteColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: kGreyColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: imageUrl != null
                ? ClipOval(child: ImageContainer(url: imageUrl))
                : Icon(
                    Icons.person,
                    color: kGreyColor,
                    size: getProportionateScreenWidth(18),
                  ),
          );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(timestamp);
    }
  }
}
