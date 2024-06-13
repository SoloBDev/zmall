import 'package:flutter/material.dart';
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
            indicatorColor: kSecondaryColor,
            labelColor: kSecondaryColor,
            unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
            unselectedLabelColor: kGreyColor,
            tabs: [
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      Icons.delivery_dining,
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
                      Icons.history,
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
