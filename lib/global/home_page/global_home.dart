import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/global/cart/global_cart.dart';
import 'package:zmall/global/home_page/components/global_home_screen.dart';
import 'package:zmall/global/profile/global_profile.dart';
import 'package:zmall/size_config.dart';

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
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: TabBarView(
          children: [
            GlobalHomeScreen(),
            GlobalCart(hasBack: false),
            GlobalProfile(),
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
                size: getProportionateScreenHeight(kDefaultPadding * 1.5),
              ),
              text: "Home",
            ),
            Tab(
              icon: Icon(
                FontAwesomeIcons.basketShopping,
                size: getProportionateScreenHeight(kDefaultPadding * 1.5),
              ),
              text: "Basket",
            ),
            Tab(
              icon: Icon(
                Icons.account_circle_rounded,
                size: getProportionateScreenHeight(kDefaultPadding * 1.5),
              ),
              text: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
