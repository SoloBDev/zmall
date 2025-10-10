import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/global/cart/global_cart.dart';
import 'package:zmall/global/home_page/components/global_home_screen.dart';
import 'package:zmall/global/profile/global_profile.dart';
import 'package:zmall/utils/size_config.dart';

class GlobalHome extends StatefulWidget {
  static String routeName = '/global_home';

  // const GlobalHome({
  //   // @required this.user
  // });

  // final User? user;

  @override
  _GlobalHomeState createState() => _GlobalHomeState();
}

class _GlobalHomeState extends State<GlobalHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    GlobalHomeScreen(),
    GlobalCart(hasBack: false),
    GlobalProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: kSecondaryColor,
        unselectedItemColor: kGreyColor,
        selectedLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: kSecondaryColor,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              HeroiconsMini.home,
              size: getProportionateScreenHeight(kDefaultPadding * 1.5),
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              HeroiconsSolid.shoppingCart,
              size: getProportionateScreenHeight(kDefaultPadding * 1.5),
            ),
            label: "Basket",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              HeroiconsSolid.user,
              size: getProportionateScreenHeight(kDefaultPadding * 1.5),
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
