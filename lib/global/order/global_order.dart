import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/global/order/components/active_orders.dart';
import 'package:zmall/global/order/components/global_history.dart';

class GlobalOrder extends StatelessWidget {
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
            tabs: [
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      Icons.delivery_dining,
                      color: kSecondaryColor,
                    ),
                  ),
                  Text(
                    "Active Orders",
                    style: TextStyle(color: kBlackColor),
                  )
                ],
              ),
              Column(
                children: [
                  Tab(
                    icon: Icon(
                      Icons.history,
                      color: kSecondaryColor,
                    ),
                  ),
                  Text(
                    "Order History",
                    style: TextStyle(color: kBlackColor),
                  )
                ],
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GlobalActiveOrders(),
            GlobalOrderHistory(),
          ],
        ),
      ),
    );
  }
}
