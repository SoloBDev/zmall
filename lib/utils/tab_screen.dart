import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/home/home_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/orders/orders_screen.dart';
import 'package:zmall/profile/profile_screen.dart';
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

  // List of screens to display
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(isLaunched: widget.isLaunched),
      OrdersScreen(),
      ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: kWhiteColor,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kSecondaryColor,
        unselectedItemColor: kGreyColor,
        selectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        backgroundColor: kWhiteColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(HeroiconsMini.home),
            // Icons.home_rounded),
            label: Provider.of<ZLanguage>(context).home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            // icon: Icon(HeroiconsMini.shoppingBag),
            label: Provider.of<ZLanguage>(context).orders,
          ),
          BottomNavigationBarItem(
            icon: Icon(HeroiconsMini.user),
            // icon: Icon(Icons.account_circle_rounded),
            label: Provider.of<ZLanguage>(context).profile,
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/home/home_screen.dart';
// import 'package:zmall/models/language.dart';
// import 'package:zmall/orders/orders_screen.dart';
// import 'package:zmall/profile/components/body.dart';
// import 'constants.dart';

// class TabScreen extends StatelessWidget {
//   static String routeName = '/start';
//   const TabScreen({this.isLaunched = false});

//   final bool isLaunched;

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         body: TabBarView(
//           children: [
//             HomeScreen(isLaunched: isLaunched),
//             OrdersScreen(),
//             ProfileScreen(),
//           ],
//         ),
//         bottomNavigationBar: SafeArea(
//           bottom: true,
//           child: TabBar(
//             labelColor: kSecondaryColor,
//             unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
//             unselectedLabelColor: kGreyColor,
//             indicatorColor: kSecondaryColor,
//             // padding: EdgeInsets.only(bottom: kDefaultPadding),
//             tabs: <Widget>[
//               Tab(
//                   icon: Icon(
//                     Icons.home_rounded,
//                   ),
//                   text: Provider.of<ZLanguage>(context).home),
//               Tab(
//                   icon: Icon(
//                     Icons.view_list,
//                   ),
//                   text: Provider.of<ZLanguage>(context).orders),
//               Tab(
//                   icon: Icon(
//                     Icons.account_circle_rounded,
//                   ),
//                   // text: "Profile",
//                   text: Provider.of<ZLanguage>(
//                     context,
//                   ).profile),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
