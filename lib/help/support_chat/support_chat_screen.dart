import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmall/help/support_chat/components/chat_bot_icon.dart';
import 'package:zmall/models/chat_message.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/help/support_chat/service/chat_service.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/help/support_chat/components/chat_bubble.dart';
import 'package:zmall/help/support_chat/components/chat_input.dart';
import 'package:zmall/help/support_chat/components/quick_replies.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class SupportChatScreen extends StatefulWidget {
  static String routeName = '/support-chat';
  // final userLocation;

  const SupportChatScreen({
    super.key,
    // this.userLocation,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showQuickReplies = true;
  bool _showScrollToBottom = false;
  String serverToken = '';
  List userLocation = [];
  String imageUrl = '';
  String userId = '';
  var userData;
  var userLat;
  var userLng;

  ///
  // String userLastOrder = '';
  String?
  userLastOrderId; // Store as String (API returns int, converted to String)
  var userOrderStatus;

  // Chat persistence settings
  static const int _chatExpirationHours = 24; // Auto-delete after 24 hours

  // User-specific storage keys (will be set after user data loads)
  String get _chatStorageKey => 'support_chat_messages_$userId';
  String get _chatTimestampKey => 'support_chat_timestamp_$userId';

  ///

  @override
  void initState() {
    super.initState();
    _getUser(); // Load user data (chat history will load after user data is available)
    _scrollController.addListener(_scrollListener);
    userLat = Provider.of<ZMetaData>(context, listen: false).latitude;
    userLng = Provider.of<ZMetaData>(context, listen: false).longitude;
    userLocation = ["$userLat", "$userLng"];
  }

  void _getUser() async {
    var data = await Service.read('user');
    if (data != null && mounted) {
      setState(() {
        userData = data;
      });

      var usrData = await ChatService.userDetails(
        context: context,
        userId: userData["user"]["_id"],
        serverToken: userData["user"]["server_token"],
      );
      if (usrData != null && usrData['success']) {
        if (mounted) {
          setState(() {
            userData = usrData;
            if (userData['user'] != null) {
              imageUrl = userData["user"]["image_url"];
              userId = userData["user"]["_id"];
              serverToken = userData["user"]["server_token"];
              // Fetch user's order for order-related queries
              _getUserOrder(userId: userId, serverToken: serverToken);
            }
          });
          Service.save('user', userData);

          // Load chat history AFTER userId is set (user-specific storage)
          if (userId.isNotEmpty) {
            _loadChatHistory();
          }
        }
      }
    }
  }

  void _scrollListener() {
    // Show button when scrolled up more than 200 pixels from bottom
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final isNearBottom = (maxScroll - currentScroll) < 200;

      if (_showScrollToBottom == isNearBottom) {
        setState(() {
          _showScrollToBottom = !isNearBottom;
        });
      }
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final chatTimestamp = await Service.read(_chatTimestampKey);
      final chatData = await Service.read(_chatStorageKey);

      // Check if chat exists and is not expired
      if (chatTimestamp != null && chatData != null) {
        final savedTime = DateTime.fromMillisecondsSinceEpoch(chatTimestamp);
        final now = DateTime.now();
        final difference = now.difference(savedTime);

        // If chat is older than expiration time, clear it
        if (difference.inHours >= _chatExpirationHours) {
          await _clearChatHistory();
          _initializeChat();
        } else {
          // Load saved messages
          final List<dynamic> messagesJson = chatData;
          setState(() {
            _messages.clear();
            _messages.addAll(
              messagesJson.map((json) => ChatMessage.fromJson(json)).toList(),
            );
            _showQuickReplies = _messages.length <= 1;
          });
          _scrollToBottom();
        }
      } else {
        // No saved chat, initialize fresh
        _initializeChat();
      }
    } catch (e) {
      // debugPrint("❌ Error loading chat history: $e");
      _initializeChat();
    }
  }

  void _initializeChat() {
    // Add welcome message
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _addBotMessage(
          "Hello! Welcome to ZMall Support. 👋\nHow can I help you today?",
        );
      }
    });
  }

  Future<void> _saveChatHistory() async {
    // Don't save if userId is not set yet (prevents saving to wrong user)
    if (userId.isEmpty) return;

    try {
      // Save messages as JSON using Service
      final messagesJson = _messages
          .map((message) => message.toJson())
          .toList();
      await Service.save(_chatStorageKey, messagesJson);

      // Save current timestamp
      await Service.save(
        _chatTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // debugPrint("❌ Error saving chat history: $e");
    }
  }

  Future<void> _clearChatHistory() async {
    try {
      await Service.remove(_chatStorageKey);
      await Service.remove(_chatTimestampKey);
    } catch (e) {
      // debugPrint("❌ Error clearing chat history: $e");
    }
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
    _saveChatHistory(); // Save after adding message
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _showQuickReplies = false;
    });
    _scrollToBottom();
    _saveChatHistory(); // Save after adding message
  }

  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    // Fetch real bot response from API
    _fetchBotResponse(message);
  }

  void _handleQuickReply(String reply) {
    _addUserMessage(reply);
    _fetchBotResponse(reply);
    // Hide quick replies after selection
    setState(() {
      _showQuickReplies = false;
    });
  }

  void _toggleQuickReplies() {
    setState(() {
      _showQuickReplies = !_showQuickReplies;
    });
  }

  Future<void> _fetchBotResponse(String userMessage) async {
    setState(() {
      _isLoading = true;
    });

    // debugPrint("Message: $userMessage");
    // debugPrint("Is Order Related: $isOrderRelated");
    // debugPrint("Sending Order ID: $userLastOrderId");

    try {
      final response = await ChatService.sendMessage(
        message: userMessage,
        context: context,
        userId: userId,
        orderId: userLastOrderId,
        serverToken: serverToken,
        userLocation: userLocation,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response != null) {
        if (response['error'] == true) {
          // Handle error from API
          _addBotMessage(
            "Sorry, I'm having trouble connecting right now. 😔\nPlease try again later.\nYou can also:\n Call: +251 967 575757\n Email: info@zmallshop.com",
            // "Sorry, I'm having trouble connecting right now. 😔\n${response['message'] ?? 'Please try again later.'}\nYou can also:\n Call: +251 967 575757\n Email: info@zmallshop.com",
          );
        } else {
          // Try different possible response field names from API
          String botMessage =
              response['response'] ??
              response['message'] ??
              response['reply'] ??
              response['answer'] ??
              response['text'] ??
              'I received your message. How else can I help you?';

          _addBotMessage(botMessage);
        }
      } else {
        // Response is null
        _addBotMessage(
          "Sorry, I'm having trouble connecting right now. 😔\nPlease check your internet connection and try again.\nYou can also:\n Call: +251 967 575757\n Email: info@zmallshop.com",
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _addBotMessage(
        "Oops! Something went wrong. 😔\nPlease try again or contact us directly:\n Call: +251 967 575757\n Email: info@zmallshop.com",
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _saveChatHistory(); // Save chat when leaving screen
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ///get user orders
  void _getUserOrder({
    required String userId,
    required String serverToken,
  }) async {
    // Fetch orders silently in background - no loading indicator needed
    try {
      var data = await ChatService.getOrders(
        userId: userId,
        serverToken: serverToken,
        context: context,
      );

      if (data != null &&
          data['success'] &&
          data['order_list'] != null &&
          data['order_list'].isNotEmpty) {
        if (mounted) {
          var userLastOrder = data['order_list'][0];
          setState(() {
            // Convert unique_id to String (API returns int)
            userLastOrderId = userLastOrder['unique_id']?.toString() ?? '';
            // userLastOrder['_id']?.toString() ?? '';
            userOrderStatus = userLastOrder['order_status'];
            // debugPrint("✅ Last Order ID: $userLastOrderId");
            // debugPrint("✅ Order Status: $userOrderStatus");
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userLastOrderId = null; // No order found
          });
        }
        // debugPrint("⚠️ No orders found for user");
      }
    } catch (e) {
      // debugPrint("❌ Error fetching orders: $e");
      if (mounted) {
        setState(() {
          userLastOrderId = null;
        });
      }
    }
  }

  ///

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            ChatBotIcon(width: 40, height: 40, iconSize: 20),
            SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ZMall Support",
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online • Responds quickly",
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(11),
                    color: kGreenColor,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: Icon(HeroiconsOutline.phone, color: kBlackColor),
          //   onPressed: () {
          //     launchUrl(Uri(scheme: 'tel', path: '+251967575757'));
          //   },
          // ),
          IconButton(
            icon: Icon(HeroiconsOutline.ellipsisVertical, color: kBlackColor),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          top: getProportionateScreenHeight(kDefaultPadding),
                          bottom: getProportionateScreenHeight(kDefaultPadding),
                        ),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isLoading) {
                            return _buildTypingIndicator();
                          }
                          return ChatBubble(
                            message: _messages[index],
                            imageUrl:
                                "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/$imageUrl",
                            onLongPress: _messages[index].isUser
                                ? () => _showMessageOptions(
                                    context,
                                    _messages[index],
                                  )
                                : null,
                          );
                        },
                      ),
              ),
              if (_showQuickReplies)
                QuickReplies(onReplyTap: _handleQuickReply),
              ChatInput(
                controller: _messageController,
                onSend: _handleSendMessage,
                isLoading: _isLoading,
                onQuickRepliesToggle: _messages.length > 1
                    ? _toggleQuickReplies
                    : null,
              ),
            ],
          ),
          // Scroll to bottom button
          if (_showScrollToBottom)
            Positioned(
              bottom: getProportionateScreenHeight(
                _showQuickReplies ? 230 : 110,
              ),
              right: getProportionateScreenWidth(kDefaultPadding),
              child: Material(
                elevation: 4,
                shape: CircleBorder(),
                color: kGreyColor.withValues(alpha: 0.6),
                // kSecondaryColor,
                child: InkWell(
                  onTap: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  customBorder: CircleBorder(),
                  child: Container(
                    width: getProportionateScreenWidth(38),
                    height: getProportionateScreenWidth(38),
                    child: Center(
                      child: Icon(
                        HeroiconsSolid.chevronDown,
                        color: kPrimaryColor,
                        size: getProportionateScreenWidth(24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChatBotIcon(),
          SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
          Text(
            "Welcome to ZMall Support",
            style: TextStyle(
              fontSize: getProportionateScreenWidth(18),
              fontWeight: FontWeight.bold,
              color: kBlackColor,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding * 3),
            ),
            child: Text(
              "We're here to help! Ask us anything about your orders, deliveries, or account.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14),
                color: kGreyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
        vertical: getProportionateScreenHeight(kDefaultPadding / 3),
      ),
      child: Row(
        children: [
          ChatBotIcon(),
          SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding),
              vertical: getProportionateScreenHeight(kDefaultPadding / 1.5),
            ),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(kDefaultPadding),
              boxShadow: [
                BoxShadow(
                  color: kBlackColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _TypingDots(),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kDefaultPadding),
        ),
      ),
      builder: (context) => SafeArea(
        minimum: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding),
          vertical: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            // Padding(
            //   padding: EdgeInsets.symmetric(
            //     vertical: getProportionateScreenHeight(kDefaultPadding / 2),
            //   ),
            //   child: Text(
            //     "Message Options",
            //     style: TextStyle(
            //       fontSize: getProportionateScreenWidth(16),
            //       fontWeight: FontWeight.bold,
            //       color: kBlackColor,
            //     ),
            //   ),
            // ),
            // Divider(height: 1, color: kGreyColor.withValues(alpha: 0.2)),
            // Resend
            ProfileListTile(
              showTrailing: false,
              borderColor: kPrimaryColor,
              icon: Icon(HeroiconsOutline.arrowPath),
              title: "Resend Message",
              onTap: () {
                Navigator.pop(context);
                _resendMessage(message.message);
              },
            ),
            // Copy
            ProfileListTile(
              showTrailing: false,
              borderColor: kPrimaryColor,
              icon: Icon(HeroiconsOutline.clipboard),
              title: "Copy Message",
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message.message);
              },
            ),
            // Delete
            ProfileListTile(
              showTrailing: false,
              borderColor: kPrimaryColor,
              icon: Icon(HeroiconsOutline.trash, color: Colors.red),
              title: "Delete Message",
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resendMessage(String message) {
    _addUserMessage(message);
    _fetchBotResponse(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Message resent"),
        backgroundColor: kSecondaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Message copied to clipboard"),
        backgroundColor: kSecondaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteMessage(ChatMessage message) {
    setState(() {
      _messages.removeWhere((msg) => msg.id == message.id);
    });
    _saveChatHistory(); // Save after deletion

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Message deleted"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: "Undo",
          textColor: kPrimaryColor,
          onPressed: () {
            setState(() {
              _messages.add(message);
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });
            _saveChatHistory(); // Save after undo
          },
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kDefaultPadding),
        ),
      ),
      builder: (context) => SafeArea(
        minimum: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding),
          vertical: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileListTile(
              showTrailing: false,
              borderColor: kPrimaryColor,
              icon: Icon(HeroiconsOutline.trash, color: kBlackColor),
              title: "Clear Chat",
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _showQuickReplies = true;
                });
                _clearChatHistory(); // Clear saved chat
                _initializeChat();
              },
            ),
            ProfileListTile(
              showTrailing: false,
              borderColor: kPrimaryColor,
              icon: Icon(HeroiconsOutline.phone, color: kBlackColor),
              title: "Call Support",
              subtitle: Text("+251 96 757 5757"),
              onTap: () {
                launchUrl(Uri(scheme: 'tel', path: '+251967575757'));
              },
            ),
            ProfileListTile(
              showTrailing: false,
              borderColor: kPrimaryColor,
              icon: Icon(HeroiconsOutline.envelope, color: kBlackColor),
              title: "Email Support",
              subtitle: Text("info@zmallshop.com"),
              onTap: () {
                launchUrl(Uri(scheme: 'mailto', path: "info@zmallshop.com"));
                // launch("mailto:info@zmallshop.com");
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Smooth typing animation widget
class _TypingDots extends StatefulWidget {
  const _TypingDots({Key? key}) : super(key: key);

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    )..repeat(); // Repeat continuously
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        SizedBox(width: 4),
        _buildDot(1),
        SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate opacity with staggered delay for each dot
        final double delay = index * 0.25;
        final double value = (_controller.value + delay) % 1.0;

        // Create smooth fade in/out effect
        double opacity;
        if (value < 0.5) {
          opacity = value * 2; // Fade in (0 -> 1)
        } else {
          opacity = 2 - (value * 2); // Fade out (1 -> 0)
        }

        return Opacity(
          opacity: opacity.clamp(0.2, 1.0), // Min 0.2, max 1.0
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: kGreyColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:heroicons_flutter/heroicons_flutter.dart';
// import 'package:zmall/models/chat_message.dart';
// import 'package:zmall/support_chat/components/chat_bubble.dart';
// import 'package:zmall/support_chat/components/chat_input.dart';
// import 'package:zmall/support_chat/components/quick_replies.dart';
// import 'package:zmall/utils/constants.dart';
// import 'package:zmall/utils/size_config.dart';

// class SupportChatScreen extends StatefulWidget {
//   static String routeName = '/support-chat';

//   const SupportChatScreen({super.key});

//   @override
//   State<SupportChatScreen> createState() => _SupportChatScreenState();
// }

// class _SupportChatScreenState extends State<SupportChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<ChatMessage> _messages = [];
//   bool _isLoading = false;
//   bool _showQuickReplies = true;

//   @override
//   void initState() {
//     super.initState();
//     _initializeChat();
//   }

//   void _initializeChat() {
//     // Add welcome message
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (mounted) {
//         _addBotMessage(
//           "Hello! Welcome to ZMall Support. 👋\n\nHow can I help you today?",
//         );
//       }
//     });
//   }

//   void _addBotMessage(String message) {
//     setState(() {
//       _messages.add(
//         ChatMessage(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           message: message,
//           isUser: false,
//           timestamp: DateTime.now(),
//         ),
//       );
//     });
//     _scrollToBottom();
//   }

//   void _addUserMessage(String message) {
//     setState(() {
//       _messages.add(
//         ChatMessage(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           message: message,
//           isUser: true,
//           timestamp: DateTime.now(),
//         ),
//       );
//       _showQuickReplies = false;
//     });
//     _scrollToBottom();
//   }

//   void _handleSendMessage() {
//     final message = _messageController.text.trim();
//     if (message.isEmpty) return;

//     _addUserMessage(message);
//     _messageController.clear();

//     // Simulate bot response
//     _simulateBotResponse(message);
//   }

//   void _handleQuickReply(String reply) {
//     _addUserMessage(reply);
//     _simulateBotResponse(reply);
//   }

//   void _simulateBotResponse(String userMessage) {
//     setState(() {
//       _isLoading = true;
//     });

//     // Simulate thinking delay
//     Future.delayed(Duration(seconds: 1), () {
//       if (!mounted) return;

//       setState(() {
//         _isLoading = false;
//       });

//       final lowerMessage = userMessage.toLowerCase();
//       String response;

//       if (lowerMessage.contains('track') || lowerMessage.contains('order')) {
//         response =
//             "To track your order:\n\n1. Go to Orders tab\n2. Select your active order\n3. View real-time tracking\n\nOr provide your order ID and I'll help you track it!";
//       } else if (lowerMessage.contains('payment')) {
//         response =
//             "I can help with payment issues!\n\nCommon payment methods:\n• Telebirr\n• CBE Birr\n• Amole\n• Credit/Debit Cards\n\nWhat specific payment issue are you facing?";
//       } else if (lowerMessage.contains('delivery') ||
//           lowerMessage.contains('time')) {
//         response =
//             "Delivery times vary by location:\n\n🚴 Standard: 30-45 mins\n🚗 Express: 15-30 mins\n\nYour estimated delivery time is shown at checkout. Is there a specific order you'd like to check?";
//       } else if (lowerMessage.contains('cancel')) {
//         response =
//             "To cancel an order:\n\n1. Go to Orders\n2. Select the order\n3. Tap 'Cancel Order'\n\nNote: You can only cancel before the store accepts it. Need help canceling a specific order?";
//       } else if (lowerMessage.contains('refund')) {
//         response =
//             "Refunds are processed within 3-5 business days.\n\nRefund goes to:\n• Original payment method\n• ZMall Wallet (instant)\n\nProvide your order ID to check refund status.";
//       } else if (lowerMessage.contains('agent') ||
//           lowerMessage.contains('human') ||
//           lowerMessage.contains('talk')) {
//         response =
//             "I'll connect you with a live agent!\n\n📞 Call: +251 967 575757\n📧 Email: info@zmallshop.com\n⏰ Hours: 8 AM - 10 PM\n\nOur team will assist you shortly.";
//       } else if (lowerMessage.contains('hello') ||
//           lowerMessage.contains('hi') ||
//           lowerMessage.contains('hey')) {
//         response =
//             "Hello! 😊 I'm here to help. What can I assist you with today?";
//       } else if (lowerMessage.contains('thank')) {
//         response =
//             "You're welcome! 🎉\n\nIs there anything else I can help you with?";
//       } else {
//         response =
//             "I understand you're asking about \"$userMessage\".\n\nI can help with:\n• Order tracking\n• Payment issues\n• Delivery questions\n• Cancellations\n• Refunds\n\nOr connect you with a live agent. What would you like to know?";
//       }

//       _addBotMessage(response);
//     });
//   }

//   void _scrollToBottom() {
//     Future.delayed(Duration(milliseconds: 100), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         title: Row(
//           children: [
//             Container(
//               width: getProportionateScreenWidth(40),
//               height: getProportionateScreenWidth(40),
//               decoration: BoxDecoration(
//                 color: kSecondaryColor.withValues(alpha: 0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.support_agent_rounded,
//                 color: kSecondaryColor,
//                 size: getProportionateScreenWidth(22),
//               ),
//             ),
//             SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "ZMall Support",
//                   style: TextStyle(
//                     fontSize: getProportionateScreenWidth(16),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   "Online • Responds quickly",
//                   style: TextStyle(
//                     fontSize: getProportionateScreenWidth(11),
//                     color: kGreenColor,
//                     fontWeight: FontWeight.normal,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(HeroiconsOutline.phone, color: kBlackColor),
//             onPressed: () {
//               // TODO: Implement call functionality
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text("Calling +251 967 575757..."),
//                   backgroundColor: kSecondaryColor,
//                 ),
//               );
//             },
//           ),
//           IconButton(
//             icon: Icon(HeroiconsOutline.ellipsisVertical, color: kBlackColor),
//             onPressed: () {
//               _showOptionsMenu(context);
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _messages.isEmpty
//                 ? _buildEmptyState()
//                 : ListView.builder(
//                     controller: _scrollController,
//                     padding: EdgeInsets.only(
//                       top: getProportionateScreenHeight(kDefaultPadding),
//                       bottom: getProportionateScreenHeight(kDefaultPadding),
//                     ),
//                     itemCount: _messages.length + (_isLoading ? 1 : 0),
//                     itemBuilder: (context, index) {
//                       if (index == _messages.length && _isLoading) {
//                         return _buildTypingIndicator();
//                       }
//                       return ChatBubble(message: _messages[index]);
//                     },
//                   ),
//           ),
//           if (_showQuickReplies && _messages.length <= 1)
//             QuickReplies(onReplyTap: _handleQuickReply),
//           ChatInput(
//             controller: _messageController,
//             onSend: _handleSendMessage,
//             isLoading: _isLoading,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: getProportionateScreenWidth(100),
//             height: getProportionateScreenWidth(100),
//             decoration: BoxDecoration(
//               color: kSecondaryColor.withValues(alpha: 0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.support_agent_rounded,
//               size: getProportionateScreenWidth(50),
//               color: kSecondaryColor,
//             ),
//           ),
//           SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
//           Text(
//             "Welcome to ZMall Support",
//             style: TextStyle(
//               fontSize: getProportionateScreenWidth(18),
//               fontWeight: FontWeight.bold,
//               color: kBlackColor,
//             ),
//           ),
//           SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
//           Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: getProportionateScreenWidth(kDefaultPadding * 3),
//             ),
//             child: Text(
//               "We're here to help! Ask us anything about your orders, deliveries, or account.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: getProportionateScreenWidth(14),
//                 color: kGreyColor,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTypingIndicator() {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: getProportionateScreenWidth(kDefaultPadding),
//         vertical: getProportionateScreenHeight(kDefaultPadding / 3),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: getProportionateScreenWidth(32),
//             height: getProportionateScreenWidth(32),
//             decoration: BoxDecoration(
//               color: kSecondaryColor.withValues(alpha: 0.1),
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: kSecondaryColor.withValues(alpha: 0.3),
//                 width: 1,
//               ),
//             ),
//             child: Icon(
//               Icons.support_agent_rounded,
//               color: kSecondaryColor,
//               size: getProportionateScreenWidth(18),
//             ),
//           ),
//           SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
//           Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: getProportionateScreenWidth(kDefaultPadding),
//               vertical: getProportionateScreenHeight(kDefaultPadding / 1.5),
//             ),
//             decoration: BoxDecoration(
//               color: kWhiteColor,
//               borderRadius: BorderRadius.circular(kDefaultPadding),
//               boxShadow: [
//                 BoxShadow(
//                   color: kBlackColor.withValues(alpha: 0.08),
//                   blurRadius: 8,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildDot(0),
//                 SizedBox(width: 4),
//                 _buildDot(1),
//                 SizedBox(width: 4),
//                 _buildDot(2),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDot(int index) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 600),
//       builder: (context, value, child) {
//         return Opacity(
//           opacity: (value + index * 0.3) % 1.0,
//           child: Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(
//               color: kGreyColor,
//               shape: BoxShape.circle,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _showOptionsMenu(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: kPrimaryColor,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(kDefaultPadding),
//         ),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: Icon(HeroiconsOutline.trash, color: kBlackColor),
//               title: Text("Clear Chat"),
//               onTap: () {
//                 Navigator.pop(context);
//                 setState(() {
//                   _messages.clear();
//                   _showQuickReplies = true;
//                 });
//                 _initializeChat();
//               },
//             ),
//             ListTile(
//               leading: Icon(HeroiconsOutline.phone, color: kBlackColor),
//               title: Text("Call Support"),
//               subtitle: Text("+251967575757"),
//               onTap: () {
//                 Navigator.pop(context);
//                 // TODO: Implement call
//               },
//             ),
//             ListTile(
//               leading: Icon(HeroiconsOutline.envelope, color: kBlackColor),
//               title: Text("Email Support"),
//               subtitle: Text("info@zmallshop.com"),
//               onTap: () {
//                 Navigator.pop(context);
//                 // TODO: Implement email
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
