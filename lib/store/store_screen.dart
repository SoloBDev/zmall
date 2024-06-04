import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/controllers/controllers.dart';
import 'package:zmall/map_view/map_view.dart';
import 'components/body.dart';

class StoreScreen extends StatefulWidget {
  static String routeName = '/store';

  StoreScreen({
    @required this.cityId,
    @required this.storeDeliveryId,
    @required this.category,
    @required this.latitude,
    @required this.longitude,
    @required this.isStore,
    @required this.companyId,
  });
  final String? cityId, storeDeliveryId;
  final category;
  final double? latitude, longitude;
  final bool? isStore;
  final int? companyId;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Controller controller = Controller();
  bool filterOpenedStore = true;

  mapViewSelected(BuildContext context) {
    var items = controller.getStores();
    if (items != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => StoreMapView(
                isOpen: items['isOpen'],
                categoryTitle: widget.category,
                stores: items['stores'],
                cityId: widget.cityId,
                storeDeliveryId: widget.storeDeliveryId,
              )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category['delivery_name'],
            style: TextStyle(color: kBlackColor)),
        elevation: 1.0,
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                filterOpenedStore = !filterOpenedStore;
              });
            },
            child: Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: filterOpenedStore ? Colors.green : kSecondaryColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding * 0.666),
                ),
                child: Text(
                  filterOpenedStore ? 'Opened' : 'All stores',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: kPrimaryColor),
                )),
          ),
          IconButton(
              onPressed: () {
                mapViewSelected(context);
              },
              tooltip: "Map view",
              icon: Icon(
                Icons.map,
                // color: kSecondaryColor,
              ))
        ],
      ),
      body: Body(
        controller: controller,
        cityId: widget.cityId,
        storeDeliveryId: widget.storeDeliveryId,
        latitude: widget.latitude,
        longitude: widget.longitude,
        isStore: widget.isStore,
        category: widget.category,
        companyId: widget.companyId,
        filterOpenedStore: filterOpenedStore,
      ),
    );
  }
}
