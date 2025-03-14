import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/cart/cart_screen.dart';
import 'package:zmall/home/home_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/orders/orders_screen.dart';
import 'package:zmall/profile/profile_screen.dart';
import 'package:zmall/search/search_screen.dart';
import 'package:zmall/size_config.dart';

import 'constants.dart';

class TabScreen extends StatelessWidget {
  static String routeName = '/start';
  const TabScreen({this.isLaunched = false});

  final bool isLaunched;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: TabBarView(
          children: [
            HomeScreen(isLaunched: isLaunched),
            OrdersScreen(),
            // SearchScreen(),
            // CartScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: TabBar(
          labelColor: kSecondaryColor,
          unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
          unselectedLabelColor: kGreyColor,
          indicatorColor: kSecondaryColor,
          tabs: <Widget>[
            Tab(
                icon: Icon(
                  Icons.home_rounded,
                ),
                // text: "Home",
                text: Provider.of<ZLanguage>(context).home),
            Tab(
                icon: Icon(
                  Icons.view_list,
                ),
                // text: "Orders",
                text: Provider.of<ZLanguage>(context).orders),
            // Tab(
            //     icon: Icon(
            //       FontAwesomeIcons.search,
            //     ),
            //     // text: "Search",
            //     text: "Search"),
            // Tab(
            //   icon: Icon(
            //     Icons.shopping_bag_rounded,
            //   ),
            //   // text: "Basket",
            //   text: "Cart",
            // ),
            Tab(
                icon: Icon(
                  Icons.account_circle_rounded,
                ),
                // text: "Profile",
                text: Provider.of<ZLanguage>(
                  context,
                ).profile),
          ],
        ),
      ),
    );
  }
}
