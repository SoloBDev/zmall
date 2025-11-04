import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/help/support_chat/support_chat_screen.dart';
import 'package:zmall/home/home_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/orders/orders_screen.dart';
import 'package:zmall/profile/profile_screen.dart';
import 'package:zmall/services/service.dart';
import 'constants.dart';

class TabScreen extends StatefulWidget {
  static String routeName = '/start';
  const TabScreen({this.isLaunched = false});

  final bool isLaunched;

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  int _selectedIndex = 0;
  bool _isChatbotEnabled = false;

  // List of screens to display
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _checkChatbotAvailability();
  }

  Future<void> _checkChatbotAvailability() async {
    // Check if user is logged in
    final isLogged = await Service.readBool('logged');
    //debugPrint("=====isLogged $isLogged========");
    if (isLogged == true) {
      //debugPrint("=====  IN IF =====");
      // User is logged in, check the backend flag
      final userData = await Service.getUser();
      //debugPrint("=====userData $userData========");
      if (userData != null && userData['user'] != null) {
        //debugPrint("=====  IN IF 2 =====");
        // Check for 'is_chatbot_active' key in user data
        // Default to false if key doesn't exist
        _isChatbotEnabled = userData['is_chatbot_active'] ?? false;
        //debugPrint("=====_isChatbotEnabled11 $_isChatbotEnabled========");
        _isChatbotEnabled = true;
        //debugPrint("=====_isChatbotEnabled22 $_isChatbotEnabled========");
      } else {
        //debugPrint("=====  IN ELSE =====");
        _isChatbotEnabled = false;
        //debugPrint("=====_isChatbotEnabled33 $_isChatbotEnabled========");
      }
    } else {
      // Guest user - chatbot disabled
      //debugPrint("=====  IN ELSE 2 =====");
      _isChatbotEnabled = false;
      //debugPrint("=====_isChatbotEnabled44 $_isChatbotEnabled========");
    }

    setState(() {
      _initializeScreensAndNav();
    });
  }

  void _initializeScreensAndNav() {
    if (_isChatbotEnabled) {
      _screens = [
        HomeScreen(isLaunched: widget.isLaunched),
        OrdersScreen(),
        SupportChatScreen(),
        ProfileScreen(),
      ];
    } else {
      _screens = [
        HomeScreen(isLaunched: widget.isLaunched),
        OrdersScreen(),
        ProfileScreen(),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build navigation items dynamically based on chatbot availability
    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: Icon(HeroiconsOutline.home),
        activeIcon: Icon(HeroiconsMini.home),
        label: Provider.of<ZLanguage>(context).home,
      ),
      BottomNavigationBarItem(
        icon: Icon(HeroiconsOutline.listBullet),
        activeIcon: Icon(Icons.view_list),
        label: Provider.of<ZLanguage>(context).orders,
      ),
      if (_isChatbotEnabled)
        BottomNavigationBarItem(
          // icon: FaIcon(FontAwesomeIcons.robot, size: 22),
          icon: Icon(HeroiconsOutline.chatBubbleLeftEllipsis),
          activeIcon: Icon(HeroiconsMini.chatBubbleLeftEllipsis),
          label: Provider.of<ZLanguage>(context).chatbot,
        ),
      BottomNavigationBarItem(
        icon: Icon(HeroiconsOutline.user),
        activeIcon: Icon(HeroiconsMini.user),
        // icon: Icon(Icons.account_circle_rounded),
        label: Provider.of<ZLanguage>(context).profile,
      ),
    ];

    return Scaffold(
      // backgroundColor: kWhiteColor,
      body: _screens.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kSecondaryColor,
        unselectedItemColor: kGreyColor,
        selectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        backgroundColor: kWhiteColor,
        items: navItems,
      ),
    );
  }
}
