# Proximity Order Feature - Simple Implementation Guide

## Using Existing `/admin/orders_list` Endpoint (No Model Needed)

## Overview

Display nearby delivery orders on the HomeBody screen using the existing orders list API and response structure.

---

## Response Structure (Already Available)

```json
{
  "success": true,
  "message": 242,
  "pages": 1,
  "orders": [
    {
      "_id": "690f0055ecd76d1367498c18",
      "unique_id": 413008,
      "order_status": 7,
      "delivery_type": 1,
      "created_at": "2025-11-08T08:33:25.458Z",
      "store_detail": {
        "name": "Store Name",
        "image_url": "path/to/image.jpg",
        "location": [8.9797543, 38.7714572]
      },
      "cart_detail": {
        "destination_addresses": [
          {
            "address": "User Pickup",
            "location": [8.9994291, 38.7694476],
            "user_details": {
              "name": "Eyob",
              "phone": "947635677"
            }
          }
        ]
      },
      "order_payment_detail": {
        "total_order_price": 1,
        "total_delivery_price": 0
      }
    }
  ]
}
```

---

## Implementation Steps

### 1. Add Service Method (lib/services/service.dart)

Add this method to fetch and filter proximity orders:

```dart
/// Fetch proximity orders using existing orders_list endpoint
/// Returns list of orders within specified radius from user location
static Future<List<Map<String, dynamic>>> getProximityOrders({
  required BuildContext context,
  required double userLatitude,
  required double userLongitude,
  double radiusKm = 5.0,
}) async {
  try {
    // Fetch all active delivery orders
    var response = await CoreServices.getOrdersList(
      context: context,
      orderStatus: "all",      // All statuses
      paymentStatus: "all",
      page: 1,
      pickupType: "both",
      createdBy: "both",
      orderType: "both",
      searchField: "user_detail.first_name",
      searchValue: "",
    );

    if (response != null && response['success'] == true) {
      List ordersList = response['orders'] ?? [];
      List<Map<String, dynamic>> proximityOrders = [];

      for (var order in ordersList) {
        // Only process delivery orders (delivery_type == 1)
        if (order['delivery_type'] != 1) continue;

        // Only show orders that are in-delivery status (order_status == 7)
        if (order['order_status'] != 7) continue;

        // Get destination location
        var cartDetail = order['cart_detail'];
        if (cartDetail == null) continue;

        var destAddresses = cartDetail['destination_addresses'] as List?;
        if (destAddresses == null || destAddresses.isEmpty) continue;

        var destLocation = destAddresses[0]['location'] as List?;
        if (destLocation == null || destLocation.length < 2) continue;

        double destLat = destLocation[0].toDouble();
        double destLong = destLocation[1].toDouble();

        // Calculate distance from user to delivery destination
        double distance = calculateDistance(
          userLatitude,
          userLongitude,
          destLat,
          destLong,
        );

        // Filter by radius
        if (distance <= radiusKm) {
          // Add distance to order data
          order['distance_from_user'] = distance;

          // Check if urgent (created more than 30 minutes ago)
          DateTime createdAt = DateTime.parse(order['created_at']);
          Duration timeSinceCreation = DateTime.now().difference(createdAt);
          order['is_urgent'] = timeSinceCreation.inMinutes > 30;

          proximityOrders.add(order);
        }
      }

      // Sort by distance (closest first)
      proximityOrders.sort((a, b) {
        double distA = a['distance_from_user'] ?? double.infinity;
        double distB = b['distance_from_user'] ?? double.infinity;
        return distA.compareTo(distB);
      });

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

### 2. Update HomeBody (lib/home/components/home_body.dart)

#### 2.1 Add State Variable

```dart
List<Map<String, dynamic>> proximityOrdersList = [];
Timer? _proximityOrderTimer;
```

#### 2.2 Add Fetch Method

```dart
void _getProximityOrders() async {
  if (userData == null || latitude == null || longitude == null) return;

  try {
    List<Map<String, dynamic>> orders = await Service.getProximityOrders(
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

#### 2.3 Update initState

```dart
@override
void initState() {
  super.initState();
  // ... existing init code ...

  // Initial fetch after 2 seconds
  Future.delayed(Duration(seconds: 2), () {
    if (mounted) _getProximityOrders();
  });

  // Auto-refresh every 30 seconds
  _proximityOrderTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    if (mounted) _getProximityOrders();
  });
}
```

#### 2.4 Update dispose

```dart
@override
void dispose() {
  _proximityOrderTimer?.cancel();
  // ... existing dispose code ...
  super.dispose();
}
```

#### 2.5 Add UI Section (after Featured Stores)

Find the Featured Stores section in the build method and add this after it:

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

      // Horizontal Order List
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
              : proximityOrdersList.length,
          itemBuilder: (context, index) {
            final order = proximityOrdersList[index];
            final storeDetail = order['store_detail'] ?? {};
            final orderPayment = order['order_payment_detail'] ?? {};
            final cartDetail = order['cart_detail'] ?? {};
            final destAddresses = cartDetail['destination_addresses'] as List? ?? [];
            final destAddress = destAddresses.isNotEmpty ? destAddresses[0] : {};

            final double distance = order['distance_from_user'] ?? 0.0;
            final bool isUrgent = order['is_urgent'] ?? false;
            final String storeName = storeDetail['name'] ?? 'Unknown Store';
            final String storeImage = storeDetail['image_url'] ?? '';
            final String deliveryAddress = destAddress['address'] ?? 'Unknown';
            final double deliveryFee = (orderPayment['total_delivery_price'] ?? 0).toDouble();

            return _buildProximityOrderCard(
              order: order,
              storeName: storeName,
              storeImage: storeImage,
              distance: distance,
              deliveryAddress: deliveryAddress,
              deliveryFee: deliveryFee,
              isUrgent: isUrgent,
            );
          },
        ),
      ),
    ],
  ),
```

#### 2.6 Add Card Widget Method

```dart
Widget _buildProximityOrderCard({
  required Map<String, dynamic> order,
  required String storeName,
  required String storeImage,
  required double distance,
  required String deliveryAddress,
  required double deliveryFee,
  required bool isUrgent,
}) {
  return InkWell(
    onTap: () => _showProximityOrderDetail(order),
    borderRadius: BorderRadius.circular(kDefaultPadding),
    child: Container(
      width: getProportionateScreenWidth(kDefaultPadding * 17),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        border: Border.all(
          color: isUrgent ? kSecondaryColor : kWhiteColor,
          width: isUrgent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: EdgeInsets.all(
        getProportionateScreenWidth(kDefaultPadding / 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Row(
            children: [
              // Store Image
              ClipRRect(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                child: CachedNetworkImage(
                  imageUrl: "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/$storeImage",
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

              // Store Name & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Service.capitalizeFirstLetters(storeName),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isUrgent)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kSecondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(HeroiconsOutline.fire, size: 12, color: kSecondaryColor),
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
              Icon(HeroiconsOutline.mapPin, size: 16, color: kSecondaryColor),
              SizedBox(width: 4),
              Text(
                "${distance.toStringAsFixed(1)} km away",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kGreyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 4)),

          // Delivery Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(HeroiconsOutline.home, size: 16, color: kGreyColor),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  deliveryAddress,
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

          // Delivery Fee
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
                "${Provider.of<ZMetaData>(context, listen: false).currency} ${deliveryFee.toStringAsFixed(2)}",
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
```

#### 2.7 Add Detail Dialog

```dart
void _showProximityOrderDetail(Map<String, dynamic> order) {
  final storeDetail = order['store_detail'] ?? {};
  final orderPayment = order['order_payment_detail'] ?? {};
  final cartDetail = order['cart_detail'] ?? {};
  final destAddresses = cartDetail['destination_addresses'] as List? ?? [];
  final destAddress = destAddresses.isNotEmpty ? destAddresses[0] : {};
  final userDetails = destAddress['user_details'] ?? {};

  final String storeName = storeDetail['name'] ?? 'Unknown Store';
  final String uniqueId = order['unique_id']?.toString() ?? 'N/A';
  final double distance = order['distance_from_user'] ?? 0.0;
  final String deliveryAddr = destAddress['address'] ?? 'Unknown';
  final String userName = userDetails['name'] ?? 'Unknown';
  final String userPhone = userDetails['phone'] ?? '';
  final double totalPrice = (orderPayment['total_order_price'] ?? 0).toDouble();
  final double deliveryFee = (orderPayment['total_delivery_price'] ?? 0).toDouble();

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
            Icon(HeroiconsOutline.shoppingBag, color: kSecondaryColor, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                Service.capitalizeFirstLetters(storeName),
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
                value: "#$uniqueId",
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.mapPin,
                label: "Distance",
                value: "${distance.toStringAsFixed(1)} km away",
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.user,
                label: "Customer",
                value: "$userName${userPhone.isNotEmpty ? ' • $userPhone' : ''}",
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.home,
                label: "Delivery To",
                value: deliveryAddr,
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.currencyDollar,
                label: "Order Total",
                value: "${Provider.of<ZMetaData>(context, listen: false).currency} ${totalPrice.toStringAsFixed(2)}",
              ),
              _buildDetailRow(
                icon: HeroiconsOutline.truck,
                label: "Delivery Fee",
                value: "${Provider.of<ZMetaData>(context, listen: false).currency} ${deliveryFee.toStringAsFixed(2)}",
                isHighlighted: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: kGreyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Service.showMessage(
                context: context,
                title: "Delivery acceptance coming soon!",
                error: false,
              );
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
                style: TextStyle(fontSize: 12, color: kGreyColor),
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
```

---

## Summary

### What This Does:

1. ✅ Fetches all orders from existing API
2. ✅ Filters for delivery orders (delivery_type == 1)
3. ✅ Filters for in-delivery status (order_status == 7)
4. ✅ Calculates distance to user
5. ✅ Filters by 5km radius
6. ✅ Marks urgent orders (>30 min old)
7. ✅ Displays in horizontal scrollable list
8. ✅ Auto-refreshes every 30 seconds
9. ✅ Shows order details in dialog

### Timeline: 2-3 days

- ✅ Service method: 2 hours
- ✅ HomeBody integration: 4 hours
- ✅ Testing: 1 day

### No Additional Dependencies Needed!

All existing packages are used.
