# Proximity Order Feature - Revised Implementation Plan

## Using Existing `/admin/orders_list` Endpoint

## Overview

Add a proximity-based order notification system that displays nearby delivery opportunities to users on the HomeBody screen, **reusing the existing `getOrdersList` endpoint** from CoreServices.

## Feature Placement

- **Location**: HomeBody screen, below "Featured Stores" section
- **Visibility**: Only shown when proximity orders are available
- **Priority**: Real-time updates based on user location

---

## 1. Backend API - Using Existing Endpoint ✅

### Endpoint: `/admin/orders_list` (Already exists!)

**Request Parameters for Proximity Orders:**

```dart
//default
{
  "order_status": "all",
  "payment_status": "all",
  "pickup_type": "both",
  "created_by": "both",
  "order_type": "both",
  "search_field": "user_detail.first_name",
  "search_value": "",
  "page": 1
}
CoreServices.getOrdersList(
  context: context,
  orderStatus: "all",        // Order accepted/in delivery
  paymentStatus: "all",       // Any payment status
  pickupType: "both",         // all
  createdBy: "both",           // All orders
  orderType: "both",          // all orders
  searchField: "user_detail.first_name",
  searchValue: "",
  page: 1,
);
```

**Existing Response Structure:**

```json
{
  "success": true,
  "order_list": [
    {
      "_id": "string",
      "unique_id": "string",
      "store_name": "string",
      "store_image": "string",
      "destination_addresses": [
        {
          "location": [lat, long],
          "address": "string",
          "name": "string",
          "note": "string"
        }
      ],
      "store_location": [lat, long],
      "order_status": int,
      "delivery_status": int,
      "total_order_price": double,
      "delivery_price": double,
      "created_at": "string"
    }
  ],
  "count": int
}
```

### Client-Side Processing

1. Fetch all active delivery orders using existing endpoint
2. Calculate distance from user's location to each order's destination
3. Filter orders within 5km radius
4. Sort by distance (closest first)

---

## 2. Data Model

### Create: `lib/models/proximity_order.dart`

```dart
import 'package:zmall/services/service.dart';

class ProximityOrder {
  final String id;
  final String uniqueId;
  final String storeName;
  final String storeImage;
  final DeliveryAddress deliveryAddress;
  final StoreLocation storeLocation;
  final double distanceFromUser;
  final int orderStatus;
  final int? deliveryStatus;
  final double totalPrice;
  final double deliveryFee;
  final String createdAt;
  final bool isUrgent;

  ProximityOrder({
    required this.id,
    required this.uniqueId,
    required this.storeName,
    required this.storeImage,
    required this.deliveryAddress,
    required this.storeLocation,
    required this.distanceFromUser,
    required this.orderStatus,
    this.deliveryStatus,
    required this.totalPrice,
    required this.deliveryFee,
    required this.createdAt,
    required this.isUrgent,
  });

  /// Create from existing orders_list API response
  factory ProximityOrder.fromOrdersList({
    required Map<String, dynamic> json,
    required double userLat,
    required double userLong,
  }) {
    // Extract destination location
    final destAddresses = json['destination_addresses'] as List;
    final firstDest = destAddresses.isNotEmpty ? destAddresses[0] : null;

    double destLat = 0.0;
    double destLong = 0.0;
    String destAddress = "Unknown";
    String destName = "Unknown";
    String? destNote;

    if (firstDest != null) {
      final location = firstDest['location'] as List;
      destLat = location[0].toDouble();
      destLong = location[1].toDouble();
      destAddress = firstDest['address'] ?? "Unknown";
      destName = firstDest['name'] ?? "Unknown";
      destNote = firstDest['note'];
    }

    // Extract store location
    final storeLocationList = json['store_location'] as List;
    double storeLat = storeLocationList[0].toDouble();
    double storeLong = storeLocationList[1].toDouble();

    // Calculate distance from user to delivery destination
    double distance = Service.calculateDistance(
      userLat,
      userLong,
      destLat,
      destLong,
    );

    // Determine if order is urgent (created > 30 mins ago)
    DateTime createdAt = DateTime.parse(json['created_at']);
    Duration timeSinceCreation = DateTime.now().difference(createdAt);
    bool isUrgent = timeSinceCreation.inMinutes > 30;

    return ProximityOrder(
      id: json['_id'],
      uniqueId: json['unique_id'].toString(),
      storeName: json['store_name'] ?? "Unknown Store",
      storeImage: json['store_image'] ?? "",
      deliveryAddress: DeliveryAddress(
        name: destName,
        address: destAddress,
        note: destNote,
        lat: destLat,
        long: destLong,
      ),
      storeLocation: StoreLocation(
        lat: storeLat,
        long: storeLong,
      ),
      distanceFromUser: distance,
      orderStatus: json['order_status'],
      deliveryStatus: json['delivery_status'],
      totalPrice: json['total_order_price'].toDouble(),
      deliveryFee: json['delivery_price'].toDouble(),
      createdAt: json['created_at'],
      isUrgent: isUrgent,
    );
  }

  /// Check if order is within proximity radius
  bool isWithinRadius(double radiusKm) {
    return distanceFromUser <= radiusKm;
  }
}

class DeliveryAddress {
  final String name;
  final String address;
  final String? note;
  final double lat;
  final double long;

  DeliveryAddress({
    required this.name,
    required this.address,
    this.note,
    required this.lat,
    required this.long,
  });
}

class StoreLocation {
  final double lat;
  final double long;

  StoreLocation({
    required this.lat,
    required this.long,
  });
}
```

---

## 3. Service Layer

### Add to: `lib/services/service.dart`

```dart
/// Fetch proximity orders using existing orders_list endpoint
/// Filters orders within specified radius from user location
static Future<List<ProximityOrder>> getProximityOrders({
  required BuildContext context,
  required double userLatitude,
  required double userLongitude,
  double radiusKm = 5.0,
}) async {
  try {
    // Fetch active delivery orders using existing endpoint
    var response = await CoreServices.getOrdersList(
      context: context,
      orderStatus: "7",        // Order accepted/in delivery
      paymentStatus: "",       // Any payment status
      page: 1,
      pickupType: "1",         // Delivery orders only
      createdBy: "",           // All orders
      orderType: "0",          // Regular orders
      searchField: "",
      searchValue: "",
    );

    if (response != null && response['success'] == true) {
      List ordersList = response['order_list'] ?? [];

      // Convert to ProximityOrder and calculate distances
      List<ProximityOrder> proximityOrders = ordersList
          .map((order) => ProximityOrder.fromOrdersList(
                json: order,
                userLat: userLatitude,
                userLong: userLongitude,
              ))
          .where((order) => order.isWithinRadius(radiusKm))
          .toList();

      // Sort by distance (closest first)
      proximityOrders.sort((a, b) =>
        a.distanceFromUser.compareTo(b.distanceFromUser)
      );

      return proximityOrders;
    }

    return [];
  } catch (e) {
    print("Error fetching proximity orders: $e");
    return [];
  }
}
```

---

## 4. UI Component

### Create: `lib/home/components/proximity_order_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/models/proximity_order.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/services/service.dart';

class ProximityOrderCard extends StatelessWidget {
  const ProximityOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  final ProximityOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kDefaultPadding),
      child: Container(
        width: getProportionateScreenWidth(kDefaultPadding * 17),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          border: Border.all(
            color: order.isUrgent ? kSecondaryColor : kWhiteColor,
            width: order.isUrgent ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        padding: EdgeInsets.all(
          getProportionateScreenWidth(kDefaultPadding / 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with store image and urgent badge
            Row(
              children: [
                // Store Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  child: CachedNetworkImage(
                    imageUrl:
                        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${order.storeImage}",
                    width: getProportionateScreenWidth(kDefaultPadding * 3),
                    height: getProportionateScreenWidth(kDefaultPadding * 3),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: kWhiteColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kSecondaryColor),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: kWhiteColor,
                      child: Icon(Icons.store, color: kGreyColor),
                    ),
                  ),
                ),
                SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),

                // Store name and urgent badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Service.capitalizeFirstLetters(order.storeName),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: kBlackColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (order.isUrgent)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                HeroiconsOutline.fire,
                                size: 12,
                                color: kSecondaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Urgent",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kSecondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),
            Divider(color: kWhiteColor, height: 1),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),

            // Distance
            Row(
              children: [
                Icon(
                  HeroiconsOutline.mapPin,
                  size: 16,
                  color: kSecondaryColor,
                ),
                SizedBox(width: 4),
                Text(
                  "${order.distanceFromUser.toStringAsFixed(1)} km away",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kGreyColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),

            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 4)),

            // Delivery address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  HeroiconsOutline.home,
                  size: 16,
                  color: kGreyColor,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kGreyColor,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 2)),

            // Delivery fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Delivery Fee",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kGreyColor,
                      ),
                ),
                Text(
                  "${Provider.of<ZMetaData>(context, listen: false).currency} ${order.deliveryFee.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Integration in HomeBody

### Modify: `lib/home/components/home_body.dart`

#### 5.1 Import the model

```dart
import 'package:zmall/models/proximity_order.dart';
```

#### 5.2 Add State Variables (around line 94-100)

```dart
List<ProximityOrder> proximityOrdersList = [];
Timer? _proximityOrderTimer;
```

#### 5.3 Add Fetch Method

```dart
void _getProximityOrders() async {
  if (userData == null || latitude == null || longitude == null) return;

  try {
    List<ProximityOrder> orders = await Service.getProximityOrders(
      context: context,
      userLatitude: latitude!,
      userLongitude: longitude!,
      radiusKm: 5.0,
    );

    if (mounted) {
      setState(() {
        proximityOrdersList = orders;
      });
    }
  } catch (e) {
    print("Error fetching proximity orders: $e");
  }
}
```

#### 5.4 Update initState (add proximity order fetching)

```dart
@override
void initState() {
  super.initState();
  // ... existing init code ...

  // Initial fetch
  Future.delayed(Duration(seconds: 2), () {
    _getProximityOrders();
  });

  // Auto-refresh every 30 seconds
  _proximityOrderTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    if (mounted) {
      _getProximityOrders();
    }
  });
}
```

#### 5.5 Update dispose

```dart
@override
void dispose() {
  _proximityOrderTimer?.cancel();
  // ... existing dispose code ...
  super.dispose();
}
```

#### 5.6 Add UI Section (after Featured Stores section)

Find the Featured Stores section and add this right after it:

```dart
// Proximity Orders Section
if (proximityOrdersList.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),

      // Section Title
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding),
        ),
        child: SectionTitle(
          sectionTitle: "Nearby Orders",
          subTitle: "${proximityOrdersList.length} available",
          onSubTitlePress: null,
        ),
      ),

      // Horizontal List
      Container(
        height: getProportionateScreenHeight(kDefaultPadding * 11),
        margin: EdgeInsets.only(
          top: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding),
          ),
          separatorBuilder: (context, index) => SizedBox(
            width: getProportionateScreenWidth(kDefaultPadding / 2),
          ),
          itemCount: proximityOrdersList.length > 10
              ? 10
              : proximityOrdersList.length, // Limit to 10 orders
          itemBuilder: (context, index) {
            return ProximityOrderCard(
              order: proximityOrdersList[index],
              onTap: () {
                _showProximityOrderDetail(proximityOrdersList[index]);
              },
            );
          },
        ),
      ),
    ],
  ),
```

#### 5.7 Add Detail Dialog Method

```dart
void _showProximityOrderDetail(ProximityOrder order) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: kPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        title: Row(
          children: [
            Icon(
              HeroiconsOutline.shoppingBag,
              color: kSecondaryColor,
              size: 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                Service.capitalizeFirstLetters(order.storeName),
                style: TextStyle(
                  color: kBlackColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                icon: HeroiconsOutline.hashtag,
                label: "Order ID",
                value: "#${order.uniqueId}",
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.mapPin,
                label: "Distance",
                value: "${order.distanceFromUser.toStringAsFixed(1)} km away",
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.home,
                label: "Delivery To",
                value: order.deliveryAddress.name,
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.mapPin,
                label: "Address",
                value: order.deliveryAddress.address,
              ),
              if (order.deliveryAddress.note != null &&
                  order.deliveryAddress.note!.isNotEmpty)
                _buildDetailRow(
                  icon: HeroiconsOutline.informationCircle,
                  label: "Note",
                  value: order.deliveryAddress.note!,
                ),
              _buildDetailRow(
                icon: HeroiconsOutline.currencyDollar,
                label: "Total Order",
                value:
                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${order.totalPrice.toStringAsFixed(2)}",
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.truck,
                label: "Delivery Fee",
                value:
                    "${Provider.of<ZMetaData>(context, listen: false).currency} ${order.deliveryFee.toStringAsFixed(2)}",
                isHighlighted: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: kGreyColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptProximityOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              foregroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding),
                vertical: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
            ),
            child: Text(
              "Accept Delivery",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildDetailRow({
  required IconData icon,
  required String label,
  required String value,
  bool isHighlighted = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
      vertical: getProportionateScreenHeight(kDefaultPadding / 3),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted ? kSecondaryColor : kGreyColor,
        ),
        SizedBox(width: getProportionateScreenWidth(kDefaultPadding / 2)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: kGreyColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlighted ? kSecondaryColor : kBlackColor,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _acceptProximityOrder(ProximityOrder order) async {
  // TODO: Implement backend call to accept/claim the delivery order
  Service.showMessage(
    context: context,
    title: "Delivery acceptance feature coming soon!",
    error: false,
  );
}
```

---

## 6. Implementation Steps

### ✅ Phase 1: No Backend Work Needed!

Using existing `/admin/orders_list` endpoint

### Phase 2: Model & Service (1 day)

1. ✅ Create `ProximityOrder` model with `fromOrdersList` factory
2. ✅ Add `getProximityOrders` method to Service class
3. ✅ Add client-side distance calculation and filtering
4. Test with existing orders

### Phase 3: UI Components (2 days)

1. Create `ProximityOrderCard` widget
2. Add styles with urgent badge
3. Test card rendering

### Phase 4: Integration (1-2 days)

1. Add state variables to HomeBody
2. Implement fetch method
3. Add auto-refresh timer (30s)
4. Integrate UI section below Featured Stores
5. Add detail dialog

### Phase 5: Testing & Polish (1-2 days)

1. Test with real location data
2. Test auto-refresh mechanism
3. Add error handling
4. Optimize performance
5. Test with different order statuses

---

## 7. Key Advantages of This Approach

✅ **No Backend Changes** - Uses existing, tested API endpoint
✅ **Faster Implementation** - Skip backend development phase
✅ **Leverages Existing Code** - Reuses `CoreServices.getOrdersList`
✅ **Real Order Data** - Works with actual orders in the system
✅ **Easy to Test** - Can test with existing orders immediately
✅ **Maintainable** - Uses established patterns

---

## 8. Performance Considerations

### Client-Side Distance Calculation

- Use existing `Service.calculateDistance()` method
- Efficient for filtering 50-100 orders
- Cache calculated distances

### Optimization Tips

- Limit to first 10 proximity orders displayed
- Only fetch when user location is available
- Debounce auto-refresh if user is inactive
- Consider pagination for many orders

---

## 9. Timeline Estimate

- ~~Backend API: 2-3 days~~ **Not needed! ✅**
- **Model & Service**: 1 day
- **UI Components**: 2 days
- **Integration**: 1-2 days
- **Testing & Polish**: 1-2 days

**Total**: ~5-7 days (3 days faster!)

---

## 10. Testing Checklist

- [ ] Model correctly parses orders_list response
- [ ] Distance calculation is accurate
- [ ] Orders filtered within 5km radius
- [ ] Orders sorted by distance
- [ ] UI displays correctly with 0, 1, and multiple orders
- [ ] Auto-refresh works without memory leaks
- [ ] Detail dialog shows all order information
- [ ] Urgent badge appears for old orders (>30 min)
- [ ] Handles missing/null data gracefully
- [ ] Performance acceptable with 50+ orders

---

## 11. Future Enhancements

- Accept/claim order functionality (backend needed)
- Push notifications for new nearby orders
- Filter by delivery fee range
- Map view of order locations
- Navigation integration to order destination
- Earnings tracker for completed deliveries
