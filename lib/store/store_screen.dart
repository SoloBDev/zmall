import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/controllers/controllers.dart';
import 'package:zmall/map_view/map_view.dart';
import 'package:zmall/service.dart';
import 'package:zmall/widgets/open_close_status_card.dart';
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
  bool allClosed = false; // New state to track if all stores are closed
  bool isSearching = false; // New state to track if user is searching or not
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

// Callback to receive allClosed status from Body
  void _onAllClosedChanged(bool value) {
    setState(() {
      allClosed = value;
    });
  }

  // Callback to receive allClosed status from Body
  void _onSearching(bool value) {
    setState(() {
      isSearching = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        title: Text(
            Service.capitalizeFirstLetters(widget.category['delivery_name']),
            style: TextStyle(color: kBlackColor)),
        elevation: 1.0,
        actions: [
          if (!isSearching)
            InkWell(
              onTap: () {
                setState(() {
                  filterOpenedStore = !filterOpenedStore;
                });
              },
              child: OpenCloseStatusCard(
                isOpen: !allClosed && filterOpenedStore,
                statusText:
                    !allClosed && filterOpenedStore ? 'Opened' : 'All stores',
                padding: EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 1.5,
                    vertical: kDefaultPadding / 4),
              ),
              // Container(
              //     padding: const EdgeInsets.all(5.0),
              //     decoration: BoxDecoration(
              //       color: !allClosed && filterOpenedStore
              //           ? Colors.green
              //           : kSecondaryColor,
              //       borderRadius:
              //           BorderRadius.circular(kDefaultPadding * 0.666),
              //     ),
              //     child: Text(
              //       !allClosed && filterOpenedStore ? 'Opened' : 'All stores',
              //       style: TextStyle(
              //           fontWeight: FontWeight.bold, color: kPrimaryColor),
              //     )),
            ),
          IconButton(
              onPressed: () {
                mapViewSelected(context);
              },
              tooltip: "Map view",
              icon: Icon(
                Icons.map_outlined,
                color: kSecondaryColor,
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
        //  // Pass callback to Body
        onAllClosedChanged: _onAllClosedChanged,
        onSearching: _onSearching,
      ),
    );
  }
}
