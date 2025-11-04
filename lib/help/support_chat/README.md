# Support Chat Feature

A comprehensive AI-powered support chat system for ZMall application with persistent chat history, real-time API integration, and user-specific message storage.

## Structure

```
support_chat/
├── support_chat_screen.dart    # Main chat screen with persistence
├── components/
│   ├── chat_bubble.dart        # Message bubble widget
│   ├── chat_input.dart         # Message input field with toggle
│   ├── quick_replies.dart      # Quick reply buttons
│   └── chat_bot_icon.dart      # Custom bot avatar icon
├── service/
│   └── chat_service.dart       # API service for chatbot integration
└── README.md                   # This file
```

## Features

### 1. **Chat Interface**

- Modern chat UI with message bubbles
- User and bot messages with distinct styling
- Custom bot avatar icon with animation
- User profile picture integration
- Timestamp display (relative and absolute)
- Auto-scroll to bottom on new messages
- **Scroll to bottom button** (appears when scrolled up)
- Smooth animations and transitions

### 2. **Message Persistence** ✨ NEW

- **User-specific chat history** - Each user has isolated chat storage
- **Automatic saving** - Messages saved locally after every interaction
- **24-hour expiration** - Old chats automatically cleared after 24 hours
- **Session recovery** - Chat history restored when reopening the app
- **Secure isolation** - Account 1 messages won't appear for Account 2
- Storage keys format: `support_chat_messages_<userId>` and `support_chat_timestamp_<userId>`

### 3. **Quick Replies**

Pre-configured quick reply buttons for common queries with toggle functionality:

- Track my order
- Payment issues
- Delivery time
- Cancel order
- Refund status
- Talk to agent

**Features:**

- Toggle quick replies on/off with button in input field
- Automatically hide after first use
- Re-show by clicking toggle button

### 4. **AI-Powered Bot Responses** 🤖

**Real-time API Integration:**

- Connected to ZMall chatbot API via `ChatService`
- Context-aware responses based on user data
- **Order-specific queries** - Automatically fetches user's last order
- **Location-aware** - Uses user's current location for relevant responses
- **User identification** - Sends userId and serverToken for personalized responses

**Intelligent responses for:**

- Order tracking with real order data
- Payment method information
- Delivery time estimates based on location
- Cancellation procedures with order status
- Refund status checking
- Live agent connection fallback

### 5. **Message Management**

**Long-press message options:**

- **Resend Message** - Retry sending a failed message
- **Copy Message** - Copy message text to clipboard
- **Delete Message** - Remove message with undo option

**Features:**

- Undo delete functionality
- Sorted message list after modifications
- Persistent storage after each action

### 6. **Additional Features**

- **Typing indicator** - Smooth 3-dot animation with staggered fade effect
- **Loading states** - Visual feedback during API calls
- **Empty state display** - Welcoming UI when no messages
- **Options menu** (3-dot menu):
  - Clear Chat (removes all messages)
  - Call Support (+251 96 757 5757)
  - Email Support (info@zmallshop.com)
- **Direct contact shortcuts** - One-tap call and email via URL schemes
- **Online status indicator** - Shows bot availability
- **Error handling** - Graceful fallback messages for API failures
- **Welcome message** - Automatic greeting on first load

## Usage

### Navigate to Support Chat

```dart
Navigator.pushNamed(context, SupportChatScreen.routeName);
```

### Add Route

In your routes file, add:

```dart
SupportChatScreen.routeName: (context) => SupportChatScreen(),
```

### Integration with Help Screen

Add a button/tile in the help screen:

```dart
ProfileListTile(
  icon: Icon(
    Icons.support_agent_rounded,
    color: kBlackColor,
  ),
  title: "Chat with Support",
  subtitle: "Get instant help",
  onTap: () {
    Navigator.pushNamed(context, SupportChatScreen.routeName);
  },
),
```

## API Integration

### ChatService Methods

The chat system uses `ChatService` for backend communication:

#### 1. User Details

```dart
await ChatService.userDetails(
  context: context,
  userId: userId,
  serverToken: serverToken,
);
```

#### 2. Send Message

```dart
await ChatService.sendMessage(
  message: userMessage,
  context: context,
  userId: userId,
  orderId: userLastOrderId,
  serverToken: serverToken,
  userLocation: ["latitude", "longitude"],
);
```

#### 3. Get User Orders

```dart
await ChatService.getOrders(
  userId: userId,
  serverToken: serverToken,
  context: context,
);
```

### Response Handling

The bot response can be in different fields:

- `response['response']`
- `response['message']`
- `response['reply']`
- `response['answer']`
- `response['text']`

The system checks all possible fields and uses the first available one.

## Chat Persistence Implementation

### Storage Keys

User-specific storage keys ensure chat isolation:

```dart
// Getter methods in support_chat_screen.dart
String get _chatStorageKey => 'support_chat_messages_$userId';
String get _chatTimestampKey => 'support_chat_timestamp_$userId';
```

### Saving Chat History

```dart
Future<void> _saveChatHistory() async {
  // Prevents saving without userId (account isolation)
  if (userId.isEmpty) return;

  try {
    final messagesJson = _messages.map((m) => m.toJson()).toList();
    await Service.save(_chatStorageKey, messagesJson);
    await Service.save(_chatTimestampKey, DateTime.now().millisecondsSinceEpoch);
  } catch (e) {
    debugPrint("❌ Error saving chat history: $e");
  }
}
```

### Loading Chat History

```dart
Future<void> _loadChatHistory() async {
  try {
    final chatTimestamp = await Service.read(_chatTimestampKey);
    final chatData = await Service.read(_chatStorageKey);

    if (chatTimestamp != null && chatData != null) {
      final savedTime = DateTime.fromMillisecondsSinceEpoch(chatTimestamp);
      final now = DateTime.now();
      final difference = now.difference(savedTime);

      // Check expiration (24 hours)
      if (difference.inHours >= _chatExpirationHours) {
        await _clearChatHistory();
        _initializeChat();
      } else {
        // Load saved messages
        setState(() {
          _messages.clear();
          _messages.addAll(
            messagesJson.map((json) => ChatMessage.fromJson(json)).toList(),
          );
        });
      }
    } else {
      _initializeChat();
    }
  } catch (e) {
    debugPrint("❌ Error loading chat history: $e");
    _initializeChat();
  }
}
```

### Load Sequence

1. User opens support chat screen
2. `_getUser()` loads user data from storage
3. After userId is set, `_loadChatHistory()` is called
4. Chat history specific to that userId is loaded
5. If no history or expired, welcome message is shown

## Customization

### Add New Quick Replies

Edit `components/quick_replies.dart`:

```dart
static final List<QuickReply> replies = [
  QuickReply(
    text: "Your custom reply",
    icon: HeroiconsOutline.yourIcon,
  ),
  // ... more replies
];
```

### Modify Chat Expiration Time

Edit `support_chat_screen.dart`:

```dart
static const int _chatExpirationHours = 24; // Change to desired hours
```

### Custom Bot Error Messages

Edit error handling in `_fetchBotResponse()`:

```dart
if (response['error'] == true) {
  _addBotMessage(
    "Your custom error message here"
  );
}
```

## Dependencies

Make sure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  heroicons_flutter: ^0.10.0
  intl: ^0.18.0
  provider: ^6.0.5
  url_launcher: ^6.1.14
```

## Design System

The chat interface follows ZMall's design system:

- **Primary Color**: White background (#FFFFFF)
- **Secondary Color**: Message accent and buttons
- **Text Colors**: Black for primary, Grey for secondary
- **Shadows**: Consistent with app-wide shadow system (0.08 alpha)
- **Border Radius**: Consistent with kDefaultPadding
- **Font**: Nunito family across all text

## Testing

### Test User-Specific Chat History

1. **Test Account Isolation:**

   - Login as Account 1
   - Send some messages in support chat
   - Logout
   - Login as Account 2
   - Open support chat
   - ✅ Verify: Account 2 should NOT see Account 1's messages
   - Send different messages as Account 2
   - Logout and login back to Account 1
   - ✅ Verify: Account 1 messages are still there

2. **Test Chat Persistence:**

   - Send messages in support chat
   - Close the app completely
   - Reopen the app
   - Navigate to support chat
   - ✅ Verify: Previous messages are restored

3. **Test Chat Expiration:**

   - (For testing, temporarily change expiration to 1 minute)
   - Send messages
   - Wait 1+ minute
   - Reopen support chat
   - ✅ Verify: Old messages are cleared, welcome message appears

4. **Test Quick Replies:**

   - Click on quick reply buttons
   - ✅ Verify: Quick replies hide after selection
   - Click toggle button in input field
   - ✅ Verify: Quick replies reappear

5. **Test API Integration:**

   - Send: "track my order"
   - ✅ Verify: Bot responds with order-specific information
   - Send: "payment"
   - ✅ Verify: Bot responds with payment info
   - Test with no internet
   - ✅ Verify: Error message appears with fallback contact info

6. **Test Message Management:**

   - Long-press on a user message
   - Select "Delete Message"
   - ✅ Verify: Message disappears
   - Click "Undo" in snackbar
   - ✅ Verify: Message reappears
   - Long-press and select "Copy Message"
   - ✅ Verify: Message copied to clipboard
   - Long-press and select "Resend Message"
   - ✅ Verify: Message sent again

7. **Test Options Menu:**

   - Click 3-dot menu
   - Select "Clear Chat"
   - ✅ Verify: All messages cleared
   - Select "Call Support"
   - ✅ Verify: Phone dialer opens with correct number
   - Select "Email Support"
   - ✅ Verify: Email app opens with correct address

8. **Test Scroll Behavior:**
   - Send many messages (20+)
   - Scroll to top
   - ✅ Verify: "Scroll to bottom" button appears
   - Click the button
   - ✅ Verify: Smoothly scrolls to bottom
   - Send new message
   - ✅ Verify: Auto-scrolls to show new message

## Known Issues & Solutions

### Issue: Chat not loading after user login

**Solution:** Ensure `_loadChatHistory()` is called AFTER `userId` is set in `_getUser()` method.

### Issue: Messages appearing for wrong user

**Solution:** This was fixed by implementing user-specific storage keys. Ensure you're using the latest version with the `userId` appended to storage keys.

### Issue: Chat history not persisting

**Solution:** Check that `_saveChatHistory()` is called after every message addition. Also verify the `userId.isEmpty` check is not blocking saves.

## Future Enhancements

- [x] Message persistence (save chat history) ✅ IMPLEMENTED
- [x] User-specific chat isolation ✅ IMPLEMENTED
- [x] API integration for real-time responses ✅ IMPLEMENTED
- [x] Message management (copy, delete, resend) ✅ IMPLEMENTED
- [ ] File/image attachment support
- [ ] Voice message support
- [ ] Push notifications for agent responses
- [ ] Chat history view (separate screen)
- [ ] Multi-language support for bot responses
- [ ] Rich text formatting (bold, italic, links)
- [ ] Link preview with thumbnails
- [ ] Emoji picker integration
- [ ] Read receipts
- [ ] Live agent typing indicator
- [ ] Chat export (PDF/text)
- [ ] Message search functionality

## Performance Considerations

- **Chat history is loaded only once** when screen opens
- **Messages saved asynchronously** to avoid UI blocking
- **Expired chats auto-deleted** to prevent storage bloat
- **Scroll listener optimized** with 200px threshold
- **Typing animation uses AnimationController** for smooth performance

## Security & Privacy

- **User-specific storage** ensures chat isolation between accounts
- **No PII in chat keys** - only userId used for identification
- **Local storage only** - messages not sent to any third-party analytics
- **Automatic expiration** reduces data retention risk
- **Clear chat option** available for users who want to delete history

## Support

For issues or questions about this feature:

- Technical Issues: Contact the development team
- Feature Requests: Submit via project management system
- Bug Reports: Include steps to reproduce and device information

---

**Last Updated:** January 2025
**Version:** 2.0
**Maintainer:** ZMall Development Team
