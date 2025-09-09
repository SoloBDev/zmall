import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/orders/components/orders_history.dart';
import 'components/body.dart';

class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Orders",
            style: TextStyle(color: kBlackColor),
          ),
          elevation: 1.0,
          bottom: TabBar(
            labelColor: kSecondaryColor,
            indicatorColor: kSecondaryColor,
            labelStyle: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
            unselectedLabelColor: kGreyColor,
            indicatorAnimation: TabIndicatorAnimation.elastic,
            tabs: [
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      HeroiconsOutline.shoppingBag,
                    ),
                  ),
                  Text(
                    "Active Orders",
                  )
                ],
              ),
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      HeroiconsOutline.clock,
                    ),
                  ),
                  Text(
                    "Order History",
                  )
                ],
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Body(),
            OrderHistory(),
          ],
        ),
      ),
    );
  }
}
