# Proximity Order Feature - Implementation Plan

## Overview

Add a proximity-based order notification system that displays nearby delivery opportunities to users on the HomeBody screen. This feature allows users to see orders that are being delivered near their current location, potentially enabling them to pick up or assist with deliveries.

## Feature Placement

- **Location**: HomeBody screen, below "Featured Stores" section
- **Visibility**: Only shown when proximity orders are available
- **Priority**: Real-time updates based on user location

---

## 1. Backend API Requirements

### Endpoint: Get Proximity Orders

```
POST /api/user/get_proximity_orders
```

**Request Body:**

```json
{
  "user_id": "string",
  "server_token": "string",
  "latitude": double,
  "longitude": double,
  "radius_km": double (default: 5km)
}
```

**Response:**

```json
{
  "success": true,
  "proximity_orders": [
    {
      "_id": "string",
      "order_id": "string",
      "unique_id": "string",
      "store_name": "string",
      "store_image": "string",
      "delivery_address": {
        "name": "string",
        "note": "string",
        "lat": double,
        "long": double
      },
      "pickup_address": {
        "name": "string",
        "lat": double,
        "long": double
      },
      "distance_from_user": double, // in km
      "order_status": int,
      "delivery_status": int,
      "total_price": double,
      "delivery_fee": double,
      "created_at": "string",
      "estimated_delivery_time": "string",
      "is_urgent": boolean
    }
  ],
  "total_count": int
}
```

---

## 2. Data Model

### Create: `lib/models/proximity_order.dart`

```dart
class ProximityOrder {
  final String id;
  final String orderId;
  final String uniqueId;
  final String storeName;
  final String storeImage;
  final DeliveryAddress deliveryAddress;
  final PickupAddress pickupAddress;
  final double distanceFromUser;
  final int orderStatus;
  final int? deliveryStatus;
  final double totalPrice;
  final double deliveryFee;
  final String createdAt;
  final String? estimatedDeliveryTime;
  final bool isUrgent;

  ProximityOrder({
    required this.id,
    required this.orderId,
    required this.uniqueId,
    required this.storeName,
    required this.storeImage,
    required this.deliveryAddress,
    required this.pickupAddress,
    required this.distanceFromUser,
    required this.orderStatus,
    this.deliveryStatus,
    required this.totalPrice,
    required this.deliveryFee,
    required this.createdAt,
    this.estimatedDeliveryTime,
    required this.isUrgent,
  });

  factory ProximityOrder.fromJson(Map<String, dynamic> json) {
    return ProximityOrder(
      id: json['_id'],
      orderId: json['order_id'],
      uniqueId: json['unique_id'],
      storeName: json['store_name'],
      storeImage: json['store_image'],
      deliveryAddress: DeliveryAddress.fromJson(json['delivery_address']),
      pickupAddress: PickupAddress.fromJson(json['pickup_address']),
      distanceFromUser: json['distance_from_user'].toDouble(),
      orderStatus: json['order_status'],
      deliveryStatus: json['delivery_status'],
      totalPrice: json['total_price'].toDouble(),
      deliveryFee: json['delivery_fee'].toDouble(),
      createdAt: json['created_at'],
      estimatedDeliveryTime: json['estimated_delivery_time'],
      isUrgent: json['is_urgent'] ?? false,
    );
  }
}

class DeliveryAddress {
  final String name;
  final String? note;
  final double lat;
  final double long;

  DeliveryAddress({
    required this.name,
    this.note,
    required this.lat,
    required this.long,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      name: json['name'],
      note: json['note'],
      lat: json['lat'].toDouble(),
      long: json['long'].toDouble(),
    );
  }
}

class PickupAddress {
  final String name;
  final double lat;
  final double long;

  PickupAddress({
    required this.name,
    required this.lat,
    required this.long,
  });

  factory PickupAddress.fromJson(Map<String, dynamic> json) {
    return PickupAddress(
      name: json['name'],
      lat: json['lat'].toDouble(),
      long: json['long'].toDouble(),
    );
  }
}
```

---

## 3. Service Layer

### Add to: `lib/services/service.dart`

```dart
/// Fetch proximity orders near user's current location
static Future<Map<String, dynamic>?> getProximityOrders({
  required BuildContext context,
  required String userId,
  required String serverToken,
  required double latitude,
  required double longitude,
  double radiusKm = 5.0,
}) async {
  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_proximity_orders";

  Map data = {
    "user_id": userId,
    "server_token": serverToken,
    "latitude": latitude,
    "longitude": longitude,
    "radius_km": radiusKm,
  };

  var body = json.encode(data);

  try {
    http.Response response = await http
        .post(
          Uri.parse(url),
          headers: <String, String>{
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: body,
        )
        .timeout(
          Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException("The connection has timed out!");
          },
        );

    return json.decode(response.body);
  } catch (e) {
    return null;
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
        padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: getProportionateScreenHeight(kDefaultPadding / 4),
          children: [
            // Header with store image and urgent badge
            Row(
              children: [
                // Store Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  child: CachedNetworkImage(
                    imageUrl: "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${order.storeImage}",
                    width: getProportionateScreenWidth(kDefaultPadding * 3),
                    height: getProportionateScreenWidth(kDefaultPadding * 3),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: kWhiteColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
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

            Divider(color: kWhiteColor, height: 16),

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

#### 5.1 Add State Variables (around line 94-100)

```dart
var proximityOrders;
List<ProximityOrder> proximityOrdersList = [];
Timer? _proximityOrderTimer;
```

#### 5.2 Add Fetch Method

```dart
void _getProximityOrders() async {
  if (userData == null || latitude == null || longitude == null) return;

  var data = await Service.getProximityOrders(
    context: context,
    userId: userData['user']['_id'],
    serverToken: userData['user']['server_token'],
    latitude: latitude!,
    longitude: longitude!,
    radiusKm: 5.0,
  );

  if (data != null && data['success'] && mounted) {
    setState(() {
      proximityOrders = data;
      proximityOrdersList = (data['proximity_orders'] as List)
          .map((order) => ProximityOrder.fromJson(order))
          .toList();
    });
  }
}
```

#### 5.3 Add Auto-Refresh Timer in initState

```dart
@override
void initState() {
  super.initState();
  // ... existing init code ...

  // Fetch proximity orders every 30 seconds
  _proximityOrderTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    if (mounted) {
      _getProximityOrders();
    }
  });
}
```

#### 5.4 Dispose Timer

```dart
@override
void dispose() {
  _proximityOrderTimer?.cancel();
  // ... existing dispose code ...
  super.dispose();
}
```

#### 5.5 Add UI Section (after Featured Stores, around line 1780-1800)

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
        height: getProportionateScreenHeight(kDefaultPadding * 10),
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
          itemCount: proximityOrdersList.length,
          itemBuilder: (context, index) {
            return ProximityOrderCard(
              order: proximityOrdersList[index],
              onTap: () {
                // Navigate to order detail or show more info
                _showProximityOrderDetail(proximityOrdersList[index]);
              },
            );
          },
        ),
      ),
    ],
  ),
```

#### 5.6 Add Detail Dialog Method

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
        title: Text(
          Service.capitalizeFirstLetters(order.storeName),
          style: TextStyle(
            color: kBlackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
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
              value: "${order.distanceFromUser.toStringAsFixed(1)} km",
            ),
            _buildDetailRow(
              icon: HeroiconsOutline.home,
              label: "Delivery To",
              value: order.deliveryAddress.name,
            ),
            _buildDetailRow(
              icon: HeroiconsOutline.currencyDollar,
              label: "Delivery Fee",
              value: "${Provider.of<ZMetaData>(context, listen: false).currency} ${order.deliveryFee.toStringAsFixed(2)}",
            ),
            if (order.estimatedDeliveryTime != null)
              _buildDetailRow(
                icon: HeroiconsOutline.clock,
                label: "Est. Time",
                value: order.estimatedDeliveryTime!,
              ),
          ],
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
              // TODO: Implement accept order logic
              _acceptProximityOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              foregroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              ),
            ),
            child: Text("Accept Delivery"),
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
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: kSecondaryColor),
        SizedBox(width: 12),
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
                  color: kBlackColor,
                  fontWeight: FontWeight.w600,
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
  // TODO: Implement backend call to accept the order
  Service.showMessage(
    context: context,
    title: "Feature coming soon!",
    error: false,
  );
}
```

---

## 6. Implementation Steps

### Phase 1: Backend Setup

1. ✅ Create API endpoint `/api/user/get_proximity_orders`
2. ✅ Implement proximity search logic (within radius)
3. ✅ Add real-time order filtering (active deliveries only)
4. ✅ Test API with sample data

### Phase 2: Model & Service

1. Create `ProximityOrder` model (`lib/models/proximity_order.dart`)
2. Add `getProximityOrders` method to Service class
3. Add unit tests for model parsing

### Phase 3: UI Components

1. Create `ProximityOrderCard` widget
2. Add styles and animations
3. Test card rendering with mock data

### Phase 4: Integration

1. Add state variables to HomeBody
2. Implement fetch method
3. Add auto-refresh timer
4. Integrate UI section below Featured Stores
5. Add detail dialog

### Phase 5: Testing & Polish

1. Test with real location data
2. Test auto-refresh mechanism
3. Add error handling
4. Optimize performance
5. Add analytics tracking

---

## 7. Additional Considerations

### Performance Optimization

- Cache proximity orders locally
- Debounce location updates
- Lazy load order details

### User Experience

- Show loading shimmer while fetching
- Add pull-to-refresh
- Animated card entrance
- Distance-based sorting (closest first)

### Security

- Validate user permissions
- Rate limit API calls
- Encrypt sensitive order data

### Future Enhancements

- Push notifications for new proximity orders
- Filter by delivery fee range
- Map view showing order locations
- Accept/reject order functionality
- Earnings tracking for completed deliveries

---

## 8. Timeline Estimate

- **Backend API**: 2-3 days
- **Model & Service**: 1 day
- **UI Components**: 2 days
- **Integration**: 1-2 days
- **Testing & Polish**: 2 days

**Total**: ~8-10 days

---

## 9. Dependencies

No new dependencies required. Using existing packages:

- `http` - API calls
- `cached_network_image` - Image caching
- `heroicons_flutter` - Icons
- `provider` - State management

---

## 10. Success Metrics

- User engagement with proximity orders
- Number of accepted deliveries
- Average response time
- User satisfaction ratings
- Additional revenue from deliveries

  <!-- RxInt page = 1.obs;
  RxInt itemsPerPage = 20.obs;
  RxInt totalPages = 1.obs;
  RxString searchValue = "".obs;
  RxString searchFieldId = 'user_detail.first_name'.obs;
  RxString searchFieldName = 'User'.obs;
  RxString selectedStatus = 'all'.obs;
  RxString selectedPaymentMode = 'all'.obs;
  RxString selectedPickupType = 'both'.obs;
  RxString selectedOrderType = 'both'.obs;
  RxString selectedCreatedBy = 'both'.obs;
  RxString selectedPaymentMethod = 'Tele Birr'.obs;
  RxInt orderStatus = 1.obs; -->
