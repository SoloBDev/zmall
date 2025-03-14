import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

import 'components/body.dart';

class GlobalStore extends StatelessWidget {
  static String routeName = '/store';

  GlobalStore({
    required this.cityId,
    required this.storeDeliveryId,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.isStore,
    this.companyId,
  });
  final String cityId, storeDeliveryId;
  final category;
  final double latitude, longitude;
  final bool isStore;
  final int? companyId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category['delivery_name'],
            style: TextStyle(color: kBlackColor)),
        elevation: 1.0,
      ),
      body: Body(
        cityId: cityId,
        storeDeliveryId: storeDeliveryId,
        latitude: latitude,
        longitude: longitude,
        isStore: isStore,
        category: category,
        companyId: companyId,
      ),
    );
  }
}
