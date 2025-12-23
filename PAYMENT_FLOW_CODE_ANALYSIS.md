# ZMall Payment Flow - Detailed Code Analysis

> **Critical Payment Integration Documentation**
>
> This document provides a **line-by-line analysis** of the payment integration code in ZMall's mobile app. Use this to understand the exact flow and replicate it for the web version.

---

## Table of Contents

1. [Checkout Screen → KifiyaScreen Navigation](#checkout-screen--kifiyascreen-navigation)
2. [Complete Payment Flow Overview](#complete-payment-flow-overview)
3. [KifiyaScreen - Main Payment Selection Screen](#kifiyascreen---main-payment-selection-screen)
4. [Payment Gateway Patterns](#payment-gateway-patterns)
5. [Critical API Functions](#critical-api-functions)
6. [Individual Gateway Implementations](#individual-gateway-implementations)
7. [Web Implementation Guidance](#web-implementation-guidance)

---

## Checkout Screen → KifiyaScreen Navigation

### File Location
`lib/checkout/checkout_screen.dart`

This section explains **how and when** the checkout screen navigates to the payment screen (KifiyaScreen), including all parameters, conditions, and the invoice API call.

---

### Pre-Navigation: Get Order Invoice

**Before** navigating to KifiyaScreen, the checkout screen must call the backend to create an "order payment" session and get the invoice details.

#### API Function: getCartInvoice()

```dart
Future<dynamic> getCartInvoice() async {
  setState(() {
    linearProgressIndicator = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitWave(
            color: kSecondaryColor,
            size: getProportionateScreenWidth(kDefaultPadding),
          ),
          SizedBox(height: kDefaultPadding * 0.5),
          Text(
            "Generating Order Invoice...",
            style: TextStyle(color: kBlackColor),
          ),
        ],
      ),
    );
  });

  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_order_cart_invoice";

  Map data = {
    "user_id": cart!.userId,
    "store_id": cart!.storeId,
    "total_time": selfPickup ? 0 : time,              // Delivery time (0 for self-pickup)
    "total_distance": selfPickup ? 0 : distance,      // Delivery distance (0 for self-pickup)
    "order_type": 7,                                  // 7 = regular order, different for courier
    "is_user_pick_up_order": selfPickup,              // true if user picks up from store
    "total_item_count": cart!.items?.length,          // Number of items in cart
    "is_user_drop_order": !cart!.isLaundryService,    // true for regular orders
    "express_option": selectedExpressOption,           // "normal", "3hours", "half_express", etc.
    "server_token": cart!.serverToken,
    "vehicle_id": widget.vehicleId,                   // Vehicle selected (for courier)
    "tip": tip,                                       // Delivery tip amount
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(
      Duration(seconds: 30),
      onTimeout: () {
        setState(() {
          this._loading = false;
        });
        throw TimeoutException("The connection has timed out!");
      },
    );

    setState(() {
      this.responseData = json.decode(response.body);
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    if (mounted) {
      Service.showMessage(
        context: context,
        title: "Order invoice failed! Check your internet and try again",
        error: true,
        duration: 4,
      );
    }
    return null;
  }
}
```

**API Endpoint:** `/api/user/get_order_cart_invoice`

**Request Example:**
```json
{
  "user_id": "60a7b3c4e5f6g7h8i9j0k1",
  "store_id": "store_unique_id",
  "total_time": 25.5,
  "total_distance": 5.2,
  "order_type": 7,
  "is_user_pick_up_order": false,
  "total_item_count": 5,
  "is_user_drop_order": true,
  "express_option": "normal",
  "server_token": "session_token",
  "vehicle_id": "",
  "tip": 10.0
}
```

**Response Structure (responseData):**
```json
{
  "success": true,
  "order_payment": {
    "_id": "payment_session_id_abc123",
    "unique_id": "ORD_20231215_ABC123",
    "user_id": "60a7b3c4e5f6g7h8i9j0k1",
    "store_id": "store_unique_id",
    "user_pay_payment": 1250.00,
    "total_cart_price": 1200.00,
    "total_delivery_price": 50.00,
    "total_tax": 0.00,
    "total_admin_tax": 0.00,
    "wallet_payment": 0.00,
    "is_payment_paid": false,
    "created_at": "2023-12-15T08:30:00Z"
  },
  "vehicles": [
    {
      "_id": "vehicle_id_1",
      "vehicle_name": "Bike",
      "base_price": 50.00
    }
  ]
}
```

**Critical Fields:**
- **`order_payment._id`**: This becomes `orderPaymentId` - used to track payment throughout the flow
- **`order_payment.unique_id`**: This becomes `orderPaymentUniqueId` - used for trace numbers
- **`order_payment.user_pay_payment`**: The **total amount** user must pay (after discounts, including delivery)
- **`vehicles[0]._id`**: Vehicle ID (for courier orders, or default vehicle for delivery)

---

### Determining onlyCashless Flag

Before navigation, the checkout screen determines if cash payment should be disabled:

```dart
// State variable
bool? onlyCashless;

// Loaded from store details API
void _getStoreDetail() async {
  setState(() {
    _loading = true;
  });

  var data = await getStoreDetail();

  if (data != null && data['success']) {
    setState(() {
      storeDetail = data;
      onlyCashless = storeDetail['store']['accept_only_cashless_payment'];
      onlySelfPickup = storeDetail['store']['accept_user_pickup_delivery_only'];
      onlyScheduledOrder = storeDetail['store']['accept_scheduled_order_only'];
    });
  }
}
```

**Store Detail API Response:**
```json
{
  "success": true,
  "store": {
    "_id": "store_id",
    "name": "Super Market",
    "accept_only_cashless_payment": false,
    "accept_user_pickup_delivery_only": false,
    "accept_scheduled_order_only": false
  }
}
```

**`onlyCashless` Logic:**
- If `storeDetail['store']['accept_only_cashless_payment'] == true` → Store only accepts digital payments
- If `selfPickup == true` → Self-pickup orders ALWAYS require digital payment (cash not allowed)

---

### Navigation Code

When user clicks "Place Order" button in checkout:

```dart
CustomButton(
  isLoading: _placeOrder,
  title: Provider.of<ZLanguage>(context).placeOrder,
  press: () {
    // CASE 1: Scheduled Order
    if (scheduledOrder) {
      if (_scheduledDate != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return KifiyaScreen(
                price: promoCodeApplied
                    ? promoCodeData['order_payment']['user_pay_payment'].toDouble()
                    : responseData['order_payment']['user_pay_payment'].toDouble(),
                orderPaymentId: responseData['order_payment']['_id'],
                orderPaymentUniqueId: responseData['order_payment']['unique_id'].toString(),
                onlyCashless: onlyCashless,
                vehicleId: responseData['vehicles'][0]['_id'],
                userpickupWithSchedule: cart!.isSchedule && selfPickup ? true : false,
              );
            },
          ),
        );
      } else {
        Service.showMessage(
          context: context,
          title: "Please select date & time for schedule",
          error: false,
          duration: 5,
        );
      }
    }

    // CASE 2: Regular Order (ASAP or Self-Pickup)
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return KifiyaScreen(
              price: promoCodeApplied
                  ? promoCodeData['order_payment']['user_pay_payment'].toDouble()
                  : responseData['order_payment']['user_pay_payment'].toDouble(),
              orderPaymentId: responseData['order_payment']['_id'],
              orderPaymentUniqueId: responseData['order_payment']['unique_id'].toString(),
              onlyCashless: (onlyCashless ?? false)
                  ? true
                  : (selfPickup ? true : false),
              vehicleId: responseData['vehicles'][0]['_id'],
            );
          },
        ),
      );
    }
  },
)
```

---

### Parameter Breakdown

#### 1. **price** (required)
```dart
price: promoCodeApplied
    ? promoCodeData['order_payment']['user_pay_payment'].toDouble()
    : responseData['order_payment']['user_pay_payment'].toDouble()
```

**Logic:**
- If promo code applied → Use discounted amount from `promoCodeData`
- Otherwise → Use amount from `responseData`

**Example Values:**
- Regular order: `1250.00` (items + delivery fee)
- With promo: `1125.00` (after 10% discount)

---

#### 2. **orderPaymentId** (required)
```dart
orderPaymentId: responseData['order_payment']['_id']
```

**What it is:**
- Backend-generated payment session ID
- Created when `get_order_cart_invoice` API is called
- Used throughout payment flow to track this specific payment

**Example Value:** `"6584abc123def456789"`

**Used For:**
- Verifying payment status via `/admin/check_paid_order`
- Linking payment to order when creating final order
- Tracking payment in backend database

---

#### 3. **orderPaymentUniqueId** (required)
```dart
orderPaymentUniqueId: responseData['order_payment']['unique_id'].toString()
```

**What it is:**
- Human-readable unique identifier
- Format: `ORD_{YYYYMMDD}_{RANDOM}`
- Used to generate trace numbers for payment gateways

**Example Value:** `"ORD_20231215_ABC123"`

**Used For:**
- Creating trace numbers: `{uuid}_{orderPaymentUniqueId}`
  - Example: `"1234567890_ORD_20231215_ABC123"`
- Displaying to user in payment screens
- Reference number for manual payments (Telebirr Reference)

---

#### 4. **onlyCashless** (optional, default: false)
```dart
onlyCashless: (onlyCashless ?? false)
    ? true
    : (selfPickup ? true : false)
```

**Complex Logic Explained:**

**Step 1:** Check if `onlyCashless` is already set (from store settings)
- If `onlyCashless == true` → Return `true`
- If `onlyCashless == false` or `null` → Go to Step 2

**Step 2:** Check if order is self-pickup
- If `selfPickup == true` → Return `true` (self-pickup ALWAYS cashless)
- If `selfPickup == false` → Return `false` (cash allowed)

**Truth Table:**

| onlyCashless | selfPickup | (onlyCashless ?? false) | Final Result | Cash Allowed? |
|--------------|------------|-------------------------|--------------|---------------|
| true         | true       | true                    | true         | ❌ No         |
| true         | false      | true                    | true         | ❌ No         |
| false        | true       | false                   | true         | ❌ No         |
| false        | false      | false                   | false        | ✅ Yes        |
| null         | true       | false                   | true         | ❌ No         |
| null         | false      | false                   | false        | ✅ Yes        |

**How to read this table:**
- Column 3 shows the result of the null coalescing operator: `null` becomes `false`, everything else stays the same
- If column 3 is `true`, the result is always `true` (first part of ternary)
- If column 3 is `false`, the result depends on `selfPickup` (second part of ternary)

**When true:**
- Cash payment option is **disabled** in KifiyaScreen
- If user selects "Cash", they get error: "Only digital payment accepted"
- Used for:
  - Stores that don't accept cash
  - Self-pickup orders (must pay before picking up)
  - High-value orders requiring digital payment

---

#### 5. **vehicleId** (optional)
```dart
vehicleId: responseData['vehicles'][0]['_id']
```

**What it is:**
- ID of the selected delivery vehicle
- Comes from invoice response

**Example Values:**
- `"bike_vehicle_id"` - For bike delivery
- `"car_vehicle_id"` - For car delivery
- `""` - Empty for self-pickup

**Used For:**
- Backend to assign correct delivery vehicle
- Calculating delivery fee based on vehicle type
- Courier orders specifically

---

#### 6. **userpickupWithSchedule** (optional, default: false)
```dart
userpickupWithSchedule: cart!.isSchedule && selfPickup ? true : false
```

**Logic:**
- Only `true` if BOTH conditions met:
  - Order is scheduled (`cart.isSchedule == true`)
  - Order is self-pickup (`selfPickup == true`)

**Scenarios:**

| cart.isSchedule | selfPickup | userpickupWithSchedule | Meaning |
|-----------------|------------|------------------------|---------|
| true            | true       | true                   | Scheduled self-pickup |
| true            | false      | false                  | Scheduled delivery |
| false           | true       | false                  | ASAP self-pickup |
| false           | false      | false                  | ASAP delivery |

**Used For:**
- Backend to handle scheduled pickup orders differently
- Payment gateway availability (some may not support scheduled pickup)

---

### Complete Navigation Examples

#### Example 1: Regular ASAP Delivery Order
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      return KifiyaScreen(
        price: 1250.00,                           // Total: items + delivery
        orderPaymentId: "6584abc123def456789",    // Payment session ID
        orderPaymentUniqueId: "ORD_20231215_ABC123",
        onlyCashless: false,                      // Cash allowed
        vehicleId: "bike_vehicle_id",             // Bike delivery
        isCourier: false,                         // Regular order
      );
    },
  ),
);
```

---

#### Example 2: Self-Pickup Order (Cashless Required)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      return KifiyaScreen(
        price: 1200.00,                           // No delivery fee
        orderPaymentId: "6584abc123def456790",
        orderPaymentUniqueId: "ORD_20231215_ABC124",
        onlyCashless: true,                       // Cash NOT allowed (self-pickup)
        vehicleId: "",                            // No vehicle needed
        isCourier: false,
      );
    },
  ),
);
```

---

#### Example 3: Cashless-Only Store
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      return KifiyaScreen(
        price: 875.50,
        orderPaymentId: "6584abc123def456791",
        orderPaymentUniqueId: "ORD_20231215_ABC125",
        onlyCashless: true,                       // Store policy: no cash
        vehicleId: "car_vehicle_id",
        isCourier: false,
      );
    },
  ),
);
```

---

#### Example 4: Scheduled Self-Pickup with Promo Code
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      return KifiyaScreen(
        price: 1080.00,                           // After 10% discount
        orderPaymentId: "6584abc123def456792",
        orderPaymentUniqueId: "ORD_20231215_ABC126",
        onlyCashless: true,                       // Self-pickup = cashless
        vehicleId: "",
        userpickupWithSchedule: true,             // Scheduled pickup
        isCourier: false,
      );
    },
  ),
);
```

---

### Validation Before Navigation

The checkout screen performs these checks before allowing navigation:

```dart
// Check 1: Must have valid invoice response
if (responseData == null || responseData['order_payment'] == null) {
  Service.showMessage(
    context: context,
    title: "Failed to generate invoice. Please try again.",
    error: true,
  );
  return;
}

// Check 2: For scheduled orders, date must be selected
if (scheduledOrder && _scheduledDate == null) {
  Service.showMessage(
    context: context,
    title: "Please select date & time for schedule",
    error: false,
    duration: 5,
  );
  return;
}

// Check 3: Cart must not be empty
if (cart == null || cart.items == null || cart.items!.isEmpty) {
  Service.showMessage(
    context: context,
    title: "Your cart is empty",
    error: true,
  );
  return;
}
```

---

### Web Implementation Guidance

For web version, create similar flow:

```javascript
// Step 1: Get order invoice
const getOrderInvoice = async () => {
  const response = await fetch('/api/user/get_order_cart_invoice', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({
      user_id: userData.user._id,
      store_id: cart.storeId,
      total_time: selfPickup ? 0 : estimatedTime,
      total_distance: selfPickup ? 0 : estimatedDistance,
      order_type: 7,
      is_user_pick_up_order: selfPickup,
      total_item_count: cart.items.length,
      is_user_drop_order: !cart.isLaundryService,
      express_option: selectedExpressOption,
      server_token: userData.user.server_token,
      vehicle_id: selectedVehicleId,
      tip: tipAmount,
    }),
  });

  return await response.json();
};

// Step 2: Navigate to payment
const proceedToPayment = async () => {
  const invoiceData = await getOrderInvoice();

  if (invoiceData && invoiceData.success) {
    // Determine onlyCashless
    const cashlessRequired = (storeData.accept_only_cashless_payment || selfPickup);

    navigate('/payment', {
      state: {
        price: promoCodeApplied
          ? promoCodeData.order_payment.user_pay_payment
          : invoiceData.order_payment.user_pay_payment,
        orderPaymentId: invoiceData.order_payment._id,
        orderPaymentUniqueId: invoiceData.order_payment.unique_id,
        onlyCashless: cashlessRequired,
        vehicleId: invoiceData.vehicles[0]._id,
        userpickupWithSchedule: cart.isSchedule && selfPickup,
      },
    });
  } else {
    toast.error("Failed to generate invoice. Please try again.");
  }
};
```

---

## Courier Checkout → KifiyaScreen Navigation

### File Locations
- Vehicle Selection: `lib/courier/components/vehicle_screen.dart`
- Courier Checkout: `lib/courier_checkout/courier_checkout_screen.dart`

This section explains **how courier orders** navigate to the payment screen, which differs from regular e-commerce checkout.

---

### Courier Order Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     COURIER SCREEN                              │
│  User fills out courier delivery form:                         │
│  - Pickup location                                             │
│  - Destination location                                        │
│  - Package details                                             │
│  - Quantity                                                    │
│  - Round trip option                                           │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VEHICLE SELECTION SCREEN                     │
│                                                                 │
│  1. Calculate distance via Google Maps API                     │
│  2. User selects vehicle (Bike, Car, Truck, etc.)             │
│  3. User clicks "Continue"                                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ _getTotalDistance()
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              GET DISTANCE FROM GOOGLE MAPS API                  │
│  https://maps.googleapis.com/maps/api/distancematrix/json     │
│                                                                 │
│  Returns:                                                       │
│  - distance (in meters)                                        │
│  - time (in seconds)                                           │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ _getCourierInvoice()
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              GET COURIER ORDER INVOICE FROM BACKEND             │
│  /api/user/get_courier_order_invoice                          │
│                                                                 │
│  Creates order_payment session                                │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                   COURIER CHECKOUT SCREEN                       │
│  Displays invoice details:                                     │
│  - Time, Distance, Service Price                              │
│  - Total Order Price                                           │
│  User clicks "Place Order"                                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        KIFIYA SCREEN                            │
│  (Payment Selection - with isCourier = true)                  │
└─────────────────────────────────────────────────────────────────┘
```

---

### Step 1: Calculate Distance

**Location**: `lib/courier/components/vehicle_screen.dart` → `getTotalDistance()`

Before getting the invoice, the app calculates delivery distance and time using Google Maps API:

```dart
Future<dynamic> getTotalDistance() async {
  var url = "https://maps.googleapis.com/maps/api/distancematrix/json?" +
      "origins=${widget.pickupAddress!.latitude.toStringAsFixed(6)}," +
      "${widget.pickupAddress!.longitude.toStringAsFixed(6)}" +
      "&destinations=${widget.destinationAddress!.latitude.toStringAsFixed(6)}," +
      "${widget.destinationAddress!.longitude}" +
      "&key=$apiKey";

  try {
    http.Response response = await http.get(Uri.parse(url)).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        setState(() {
          this._loading = false;
        });
        throw TimeoutException("The connection has timed out!");
      },
    );

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong! Please check your internet connection"),
        backgroundColor: kSecondaryColor,
      ),
    );
    return null;
  }
}
```

**Called From**:
```dart
void _getTotalDistance() async {
  setState(() {
    _loading = true;
  });

  var data = await getTotalDistance();

  if (data != null && data['rows'][0]['elements'][0]['status'] == 'OK') {
    setState(() {
      distance = data['rows'][0]['elements'][0]['distance']['value'].toDouble();
      time = data['rows'][0]['elements'][0]['duration']['value'].toDouble();
    });

    _getCourierInvoice();  // Proceed to get invoice
  } else {
    setState(() {
      _loading = false;
    });
  }
}
```

**Google Maps Response**:
```json
{
  "rows": [
    {
      "elements": [
        {
          "status": "OK",
          "distance": {
            "value": 5200,        // meters
            "text": "5.2 km"
          },
          "duration": {
            "value": 1530,        // seconds (25.5 minutes)
            "text": "26 mins"
          }
        }
      ]
    }
  ]
}
```

**Critical Variables Set**:
- `distance`: Distance in meters (e.g., `5200`)
- `time`: Time in seconds (e.g., `1530`)

---

### Step 2: Get Courier Invoice

**Location**: `lib/courier/components/vehicle_screen.dart` → `getCourierInvoice()`

```dart
Future<dynamic> getCourierInvoice() async {
  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_courier_order_invoice";

  Map data = {
    "user_id": widget.userData['user']['_id'],
    "total_time": time,                                    // From Google Maps (seconds)
    "total_distance": distance,                            // From Google Maps (meters)
    "is_user_pickup_order": false,                         // Always false for courier
    "total_item_count": quantity,                          // Number of packages
    "is_user_drop_order": true,                           // Always true for courier
    "server_token": widget.userData['user']['server_token'],
    "vehicle_id": vehicleList['vehicles'][selected]['_id'], // Selected vehicle
    "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
    "country_id": widget.userData['user']['country_id'],
    "is_round_trip": isRoundTrip,                         // One-way or round trip
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: body,
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        setState(() {
          this._loading = false;
        });
        throw TimeoutException("The connection has timed out!");
      },
    );

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong!"),
        backgroundColor: kSecondaryColor,
      ),
    );
    return null;
  }
}
```

**API Endpoint**: `/api/user/get_courier_order_invoice`

**Request Example**:
```json
{
  "user_id": "60a7b3c4e5f6g7h8i9j0k1",
  "total_time": 1530,
  "total_distance": 5200,
  "is_user_pickup_order": false,
  "total_item_count": 2,
  "is_user_drop_order": true,
  "server_token": "session_token",
  "vehicle_id": "bike_vehicle_id_123",
  "city_id": "5b3f76f2022985030cd3a437",
  "country_id": "5b3f76f2022985030cd3a437",
  "is_round_trip": false
}
```

**Response Structure (cartInvoice)**:
```json
{
  "success": true,
  "order_payment": {
    "_id": "courier_payment_session_id",
    "unique_id": "COR_20231215_XYZ789",
    "user_id": "60a7b3c4e5f6g7h8i9j0k1",
    "total": 350.00,
    "total_service_price": 300.00,
    "total_distance": 5.2,
    "total_time": 25.5,
    "vehicle_id": "bike_vehicle_id_123",
    "is_payment_paid": false,
    "created_at": "2023-12-15T09:00:00Z"
  },
  "vehicles": [
    {
      "_id": "bike_vehicle_id_123",
      "vehicle_name": "Bike",
      "base_price": 50.00,
      "price_per_km": 20.00
    }
  ]
}
```

**Critical Fields**:
- **`order_payment._id`**: Courier payment session ID
- **`order_payment.unique_id`**: Format `COR_{YYYYMMDD}_{RANDOM}` (COR = Courier)
- **`order_payment.total`**: Total amount to pay
- **`order_payment.total_service_price`**: Service fee (before additional charges)
- **`vehicles[0]._id`**: Selected vehicle ID

---

### Step 3: Navigate to Courier Checkout

**Location**: `lib/courier/components/vehicle_screen.dart`

After getting the invoice, navigate to CourierCheckout:

```dart
void _getCourierInvoice() async {
  setState(() {
    _loading = true;
  });

  var data = await getCourierInvoice();

  if (data != null && data['success']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CourierCheckout(
            orderDetail: widget.orderDetail,
            userData: widget.userData,
            cartInvoice: data,                // Pass invoice data
          );
        },
      ),
    );
  } else {
    Service.showMessage(
      context: context,
      title: "${errorCodes['${data['error_code']}']}!",
      error: true,
    );

    await Future.delayed(Duration(seconds: 2));

    if (data['error_code'] == 999) {
      await Service.saveBool('logged', false);
      await Service.remove('user');
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  setState(() {
    _loading = false;
  });
}
```

**Parameters Passed to CourierCheckout**:
- `orderDetail`: Courier delivery details (pickup/destination addresses, package info)
- `userData`: Current user data
- `cartInvoice`: Invoice response from backend

---

### Step 4: CourierCheckout Screen Display

**Location**: `lib/courier_checkout/courier_checkout_screen.dart`

The CourierCheckout screen displays invoice details and provides "Place Order" button:

```dart
class CourierCheckout extends StatefulWidget {
  const CourierCheckout({
    super.key,
    @required this.orderDetail,
    @required this.userData,
    @required this.cartInvoice,
  });

  final orderDetail;
  final userData;
  final cartInvoice;

  @override
  _CourierCheckoutState createState() => _CourierCheckoutState();
}
```

**Display Fields**:
```dart
// Time
Text("${widget.cartInvoice['order_payment']['total_time']} mins")

// Distance
Text("${widget.cartInvoice['order_payment']['total_distance'].toStringAsFixed(2)} km")

// Service Price
Text("${currency} ${widget.cartInvoice['order_payment']['total_service_price'].toStringAsFixed(2)}")

// Total Order Price
Text("${currency} ${widget.cartInvoice['order_payment']['total'].toStringAsFixed(2)}")
```

---

### Step 5: Navigate to KifiyaScreen

**Location**: `lib/courier_checkout/courier_checkout_screen.dart`

When user clicks "Place Order":

```dart
CustomButton(
  title: "Place Order",
  press: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return KifiyaScreen(
            price: widget.cartInvoice['order_payment']['total'].toDouble(),
            orderPaymentId: widget.cartInvoice['order_payment']['_id'],
            orderPaymentUniqueId: widget.cartInvoice['order_payment']['unique_id'].toString(),
            isCourier: true,                                    // KEY DIFFERENCE
            vehicleId: widget.cartInvoice['vehicles'][0]['_id'],
          );
        },
      ),
    );
  },
  color: kSecondaryColor,
)
```

---

### Parameter Breakdown for Courier

#### 1. **price** (required)
```dart
price: widget.cartInvoice['order_payment']['total'].toDouble()
```

**What it is:**
- Total courier service fee
- Calculated based on: distance × price_per_km + base_price

**Example Value:** `350.00`

**Calculation Example**:
```
Base Price: 50.00
Distance: 5.2 km
Price per km: 20.00
Additional fees: 50.00

Total = 50.00 + (5.2 × 20.00) + 50.00
Total = 50.00 + 104.00 + 50.00
Total = 204.00

If round trip: Total × 2 = 408.00
```

---

#### 2. **orderPaymentId** (required)
```dart
orderPaymentId: widget.cartInvoice['order_payment']['_id']
```

**What it is:**
- Courier payment session ID
- Generated when `get_courier_order_invoice` is called

**Example Value:** `"courier_payment_abc123def456"`

**Used For:**
- Same as regular orders: tracking payment verification
- Linking payment to courier order

---

#### 3. **orderPaymentUniqueId** (required)
```dart
orderPaymentUniqueId: widget.cartInvoice['order_payment']['unique_id'].toString()
```

**What it is:**
- Human-readable courier order identifier
- Format: `COR_{YYYYMMDD}_{RANDOM}`

**Example Value:** `"COR_20231215_XYZ789"`

**Difference from Regular Orders:**
- Regular orders: `ORD_*`
- Courier orders: `COR_*`

---

#### 4. **isCourier** (required: **TRUE**)
```dart
isCourier: true
```

**Critical Difference:**
- Regular orders: `isCourier: false` or not set
- Courier orders: **`isCourier: true`**

**Impact**:
- When creating order, calls `_createCourierOrder()` instead of `_createOrder()`
- Backend uses different order type (7 = courier vs 1 = regular)
- Different payment flow handling

---

#### 5. **vehicleId** (required)
```dart
vehicleId: widget.cartInvoice['vehicles'][0]['_id']
```

**What it is:**
- ID of the selected delivery vehicle
- User selected in vehicle screen

**Example Values:**
- `"bike_vehicle_id_123"` - For bike
- `"car_vehicle_id_456"` - For car
- `"truck_vehicle_id_789"` - For truck

**Critical for Courier:**
- Determines pricing
- Assigns correct delivery person
- Must match the vehicle used for invoice calculation

---

#### 6. **onlyCashless** (NOT SET for courier)

**Important**: Courier orders do NOT pass `onlyCashless` parameter.

**Default Behavior**:
- Defaults to `false` in KifiyaScreen
- Cash payment IS allowed for courier orders
- No restriction on payment methods

---

### Comparison: Regular vs Courier

| Parameter | Regular Checkout | Courier Checkout |
|-----------|------------------|------------------|
| **price** | Items + delivery fee | Service fee based on distance |
| **orderPaymentId** | From `get_order_cart_invoice` | From `get_courier_order_invoice` |
| **orderPaymentUniqueId** | `ORD_*` format | `COR_*` format |
| **isCourier** | `false` (default) | **`true`** (required) |
| **vehicleId** | Auto-assigned | User-selected |
| **onlyCashless** | Based on store/pickup | Not set (cash allowed) |
| **userpickupWithSchedule** | May be set | Never set |

---

### Complete Courier Navigation Example

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      return KifiyaScreen(
        price: 350.00,                              // Courier service fee
        orderPaymentId: "courier_payment_abc123",   // Courier payment session
        orderPaymentUniqueId: "COR_20231215_XYZ789", // Courier order ID
        isCourier: true,                            // CRITICAL: marks as courier
        vehicleId: "bike_vehicle_id_123",           // Selected bike
      );
    },
  ),
);
```

---

### Invoice API Request Differences

#### Regular E-Commerce Invoice
```json
{
  "user_id": "...",
  "store_id": "...",               // Store selling items
  "total_time": 25.5,              // Estimated delivery time
  "total_distance": 5.2,           // Delivery distance
  "order_type": 7,                 // Regular order
  "is_user_pick_up_order": false,
  "total_item_count": 5,           // Shopping items
  "is_user_drop_order": true,
  "express_option": "normal",      // Delivery speed
  "server_token": "...",
  "vehicle_id": "",
  "tip": 10.0                      // Optional tip
}
```

#### Courier Invoice
```json
{
  "user_id": "...",
  // NO store_id - courier service only
  "total_time": 1530,              // Time in SECONDS
  "total_distance": 5200,          // Distance in METERS
  // NO order_type field
  "is_user_pickup_order": false,   // Always false
  "total_item_count": 2,           // Number of packages
  "is_user_drop_order": true,      // Always true
  // NO express_option
  "server_token": "...",
  "vehicle_id": "bike_vehicle_id", // User-selected vehicle
  "city_id": "...",                // Current city
  "country_id": "...",             // Current country
  "is_round_trip": false           // One-way or round trip
  // NO tip field
}
```

**Key Differences**:
1. **No store_id** - Courier is a service, not shopping
2. **Units**: Courier uses meters/seconds, regular uses km/minutes
3. **Vehicle selection**: Courier requires user selection, regular auto-assigns
4. **Round trip**: Only courier has this option
5. **Express option**: Only regular orders have delivery speed options
6. **Tip**: Only regular orders support tipping

---

### Web Implementation Guidance for Courier

```javascript
// Step 1: Calculate distance via Google Maps
const calculateDistance = async (pickupLat, pickupLng, destLat, destLng) => {
  const url = `https://maps.googleapis.com/maps/api/distancematrix/json?` +
    `origins=${pickupLat},${pickupLng}&` +
    `destinations=${destLat},${destLng}&` +
    `key=${GOOGLE_MAPS_API_KEY}`;

  const response = await fetch(url);
  const data = await response.json();

  if (data.rows[0].elements[0].status === 'OK') {
    return {
      distance: data.rows[0].elements[0].distance.value,  // meters
      time: data.rows[0].elements[0].duration.value,      // seconds
    };
  }

  throw new Error('Failed to calculate distance');
};

// Step 2: Get courier invoice
const getCourierInvoice = async (userData, selectedVehicleId, quantity, isRoundTrip) => {
  const { distance, time } = await calculateDistance(
    pickupAddress.lat,
    pickupAddress.lng,
    destinationAddress.lat,
    destinationAddress.lng
  );

  const response = await fetch('/api/user/get_courier_order_invoice', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({
      user_id: userData.user._id,
      total_time: time,
      total_distance: distance,
      is_user_pickup_order: false,
      total_item_count: quantity,
      is_user_drop_order: true,
      server_token: userData.user.server_token,
      vehicle_id: selectedVehicleId,
      city_id: currentCityId,
      country_id: userData.user.country_id,
      is_round_trip: isRoundTrip,
    }),
  });

  return await response.json();
};

// Step 3: Navigate to payment
const proceedToCourierPayment = async () => {
  const invoiceData = await getCourierInvoice(
    userData,
    selectedVehicle._id,
    packageQuantity,
    isRoundTrip
  );

  if (invoiceData && invoiceData.success) {
    navigate('/payment', {
      state: {
        price: invoiceData.order_payment.total,
        orderPaymentId: invoiceData.order_payment._id,
        orderPaymentUniqueId: invoiceData.order_payment.unique_id,
        isCourier: true,                              // CRITICAL
        vehicleId: invoiceData.vehicles[0]._id,
        // NO onlyCashless - cash allowed for courier
      },
    });
  } else {
    toast.error("Failed to generate courier invoice");
  }
};
```

---

### Validation for Courier Orders

Before generating invoice, validate:

```dart
// Check 1: Must have valid pickup and destination addresses
if (pickupAddress == null || destinationAddress == null) {
  Service.showMessage(
    context: context,
    title: "Please select both pickup and destination addresses",
    error: true,
  );
  return;
}

// Check 2: Must select a vehicle
if (selected == null || vehicleList == null) {
  Service.showMessage(
    context: context,
    title: "Please select a vehicle",
    error: true,
  );
  return;
}

// Check 3: Must specify package quantity
if (quantity == null || quantity <= 0) {
  Service.showMessage(
    context: context,
    title: "Please specify package quantity",
    error: true,
  );
  return;
}
```

---

## Complete Payment Flow Overview

### The Journey from Checkout to Order Creation

```
┌─────────────────────────────────────────────────────────────────┐
│                         CHECKOUT SCREEN                         │
│                   User clicks "Proceed to Payment"              │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                         KIFIYA SCREEN                           │
│                                                                 │
│  1. initState() → getUser()                                    │
│  2. getUser() → getCart()                                      │
│  3. getCart() → _getPaymentGateway()                          │
│  4. _getPaymentGateway() → API Call                           │
│  5. Display payment methods in GridView                       │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ User selects payment method
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PAYMENT METHOD SELECTED                      │
│                                                                 │
│  1. Set kifiyaMethod = index                                   │
│  2. Call useBorsa() → Updates wallet usage preference          │
│  3. Navigate to specific payment screen OR                     │
│     Show confirmation dialog                                   │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│   WEBVIEW GATEWAYS       │    │   USSD/API GATEWAYS      │
│   (Chapa, EthSwitch,     │    │   (Telebirr USSD,        │
│    SantimPay, etc.)      │    │    CBE USSD)             │
│                          │    │                          │
│  1. Call initiateUrl()   │    │  1. Call initPayment()   │
│  2. Get checkout URL     │    │  2. Send USSD push       │
│  3. Open InAppWebView    │    │  3. Start polling        │
│  4. User pays in webview │    │  4. _verifyPayment()     │
│  5. Return to app        │    │     every 2 seconds      │
└────────────┬─────────────┘    └────────────┬─────────────┘
             │                               │
             │                               │
             └───────────┬───────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PAYMENT VERIFICATION                        │
│                                                                 │
│  For WebView: Return directly                                  │
│  For USSD: Poll backend until payment confirmed                │
│                                                                 │
│  Call: boaVerify() or _ethSwitchVerify()                       │
│  Backend checks if payment received via webhook                │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ Payment verified ✓
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CREATE ORDER (FINAL STEP)                    │
│                                                                 │
│  1. _payOrderPayment() → Register payment method                │
│  2. Check order type:                                          │
│     - Courier? → _createCourierOrder()                        │
│     - AliExpress? → _createAliexpressOrder()                  │
│     - Regular? → _createOrder()                               │
│  3. Navigate to success screen                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## KifiyaScreen - Main Payment Selection Screen

### File Location
`lib/kifiya/kifiya_screen.dart`

### Component Properties

```dart
class KifiyaScreen extends StatefulWidget {
  const KifiyaScreen({
    this.vehicleId,              // For courier orders: vehicle selection
    this.onlyCashless = false,   // CRITICAL: When true, cash payment disabled
    @required this.price,        // Total amount to pay
    this.isCourier = false,      // Is this a courier order?
    @required this.orderPaymentId,      // Backend payment session ID
    @required this.orderPaymentUniqueId, // Unique ID for trace number
    this.userpickupWithSchedule, // Pickup scheduling flag
  });
}
```

**Key Properties Explained:**

- **`price`**: The total amount to be paid
- **`orderPaymentId`**: Generated by backend when checkout is initiated - used to track payment status
- **`orderPaymentUniqueId`**: Used to create trace numbers (format: `{uuid}_{orderPaymentUniqueId}`)
- **`onlyCashless`**: When `true`, cash payment is rejected (used for orders requiring digital payment)

---

### State Variables

```dart
class _KifiyaScreenState extends State<KifiyaScreen> {
  bool _loading = true;                    // Loading indicator
  bool _placeOrder = false;                // Order creation in progress
  bool paidBySender = true;                // Courier: who pays?
  late Cart cart;                          // Shopping cart data
  AliExpressCart? aliexpressCart;          // AliExpress cart (if any)
  var paymentResponse;                     // Payment gateways from API
  var orderResponse;                       // Order creation response
  var userData;                            // Current user data
  int kifiyaMethod = -1;                   // Selected payment index (-1 = none)
  double currentBalance = 0.0;             // User's wallet balance
  late String uuid;                        // Incremental trace number part

  // ... more state variables
}
```

**Critical State Variables:**

- **`kifiyaMethod = -1`**: Index of selected payment method in the gateway array. `-1` means no selection.
- **`paymentResponse`**: Contains the array of available payment gateways from backend
- **`uuid`**: Used to generate unique trace numbers for each payment attempt

---

### Lifecycle: initState()

```dart
@override
void initState() {
  super.initState();

  getUser();  // Step 1: Load user data from local storage

  if (widget.onlyCashless != null && widget.onlyCashless == true) {
    kifiyaMethod = -1;  // Force no selection for cashless-only orders
  }

  uuid = widget.orderPaymentUniqueId!;  // Initialize trace number base
}
```

**Flow:**
1. Component initializes
2. Calls `getUser()` to load user data
3. Sets initial uuid from the provided unique ID

---

### Step 1: Load User Data

```dart
void getUser() async {
  // Read user data from SharedPreferences
  var data = await Service.read('user');
  var aliAcct = await Service.read('ali_access_token');

  if (data != null) {
    setState(() {
      userData = data;
      currentBalance = double.parse(userData['user']['wallet'].toString());

      // Load AliExpress token if exists
      if (aliAcct != null && aliAcct.isNotEmpty) {
        aliExpressAccessToken = aliAcct;
      }
    });

    getCart();  // Step 2: Load cart data
  }
}
```

**What Happens:**
- Reads user data stored locally (from login)
- Extracts wallet balance
- Proceeds to load cart

**User Data Structure:**
```json
{
  "user": {
    "_id": "user_unique_id",
    "phone": "912345678",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "wallet": 1500.00,
    "server_token": "session_token_string"
  }
}
```

---

### Step 2: Load Cart Data

```dart
void getCart() async {
  if (widget.isCourier != null && widget.isCourier == true) {
    // For courier orders
    var data = await Service.read('courier');

    if (data != null) {
      setState(() {
        courierCart = data;
        _getPaymentGateway();  // Fetch payment gateways
        getServices();
        getImages();
        getCourierKefay();
        getCourierSchedule();
        getCourierScheduleDate();
      });
    }
  } else {
    // For regular shopping orders
    var data = await Service.read('cart');
    var aliCart = await Service.read('aliexpressCart');

    if (data != null) {
      setState(() {
        cart = Cart.fromJson(data);

        // Load AliExpress cart if exists
        if (aliCart != null) {
          aliexpressCart = AliExpressCart.fromJson(aliCart);
          itemIds = aliexpressCart!.itemIds!;
          productIds = aliexpressCart!.productIds!;
        }
      });

      _getPaymentGateway();  // Step 3: Fetch payment gateways
    }
  }
}
```

**What Happens:**
- Checks if this is a courier order or shopping order
- Loads appropriate cart data from local storage
- Proceeds to fetch available payment gateways

---

### Step 3: Fetch Payment Gateways

```dart
void _getPaymentGateway() async {
  setState(() {
    _loading = true;
    _placeOrder = true;
  });

  await getPaymentGateway();  // API call

  if (paymentResponse != null && paymentResponse['success']) {
    // Success: Payment gateways loaded
    for (var i = 0; i < paymentResponse['payment_gateway'].length; i++) {
      debugPrint(paymentResponse['payment_gateway'][i]['name']);
      debugPrint("\t${paymentResponse['payment_gateway'][i]['description']}");
    }

    setState(() {
      _loading = false;
      _placeOrder = false;
    });

    await useBorsa();  // Check wallet usage
  } else {
    // Error: Session expired or other error
    setState(() {
      _loading = false;
      _placeOrder = false;
    });

    await Future.delayed(Duration(seconds: 2));

    if (paymentResponse['error_code'] != null &&
        paymentResponse['error_code'] == 999) {
      // Session expired - logout
      await Service.saveBool('logged', false);
      await Service.remove('user');
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }
}
```

**Critical Logic:**
1. Sets loading state
2. Calls API to get available payment methods
3. If successful, stores gateways in `paymentResponse`
4. If error code 999 (session expired), logs user out
5. Calls `useBorsa()` to check wallet preferences

---

### API Function: getPaymentGateway()

```dart
Future<dynamic> getPaymentGateway() async {
  final deviceType = Platform.isIOS ? "iOS" : "android";

  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_payment_gateway";

  Map data = {
    "user_id": userData['user']['_id'],
    "city_id": Provider.of<ZMetaData>(context, listen: false).cityId,
    "server_token": userData['user']['server_token'],
    "store_delivery_id": widget.orderPaymentId,
    "is_user_pickup_with_schedule": widget.userpickupWithSchedule,
    "vehicleId": widget.vehicleId,
    "device_type": deviceType,
    "app_version": appVersion,
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        setState(() {
          this._loading = false;
        });
        throw TimeoutException("The connection has timed out!");
      },
    );

    setState(() {
      paymentResponse = json.decode(response.body);
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong. Please check your internet connection!"),
        backgroundColor: kSecondaryColor,
      ),
    );
    return null;
  }
}
```

**Request Payload:**
```json
{
  "user_id": "60a7b3c4e5f6g7h8i9j0k1",
  "city_id": "5b3f76f2022985030cd3a437",
  "server_token": "user_session_token_here",
  "store_delivery_id": "payment_session_id",
  "is_user_pickup_with_schedule": false,
  "vehicleId": null,
  "device_type": "android",
  "app_version": "3.2.3"
}
```

**Response Structure:**
```json
{
  "success": true,
  "wallet": 1500.00,
  "payment_gateway": [
    {
      "_id": "gateway_id_1",
      "name": "Wallet",
      "description": "Pay from your ZMall wallet balance",
      "is_active": true
    },
    {
      "_id": "gateway_id_2",
      "name": "Cash",
      "description": "Pay with cash on delivery",
      "is_active": true
    },
    {
      "_id": "gateway_id_3",
      "name": "Telebirr Reference",
      "description": "Pay using Telebirr app with reference number",
      "is_active": true
    },
    {
      "_id": "gateway_id_4",
      "name": "Chapa",
      "description": "Pay with cards or mobile money via Chapa",
      "is_active": true
    },
    {
      "_id": "gateway_id_5",
      "name": "EthSwitch",
      "description": "Pay with any Ethiopian bank card",
      "is_active": true
    },
    {
      "_id": "gateway_id_6",
      "name": "SantimPay",
      "description": "Pay using SantimPay wallet",
      "is_active": true
    }
    // ... more gateways
  ]
}
```

**Critical Fields:**
- `wallet`: User's current wallet balance
- `payment_gateway[]`: Array of available payment methods
- Each gateway has `_id` which is used when creating the order

---

### Step 4: Display Payment Methods

```dart
GridView.builder(
  itemCount: paymentResponse['payment_gateway'].length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: getProportionateScreenWidth(kDefaultPadding),
    mainAxisSpacing: getProportionateScreenWidth(kDefaultPadding / 2),
  ),
  itemBuilder: (BuildContext ctx, index) {
    String paymentName = paymentResponse['payment_gateway'][index]['name']
        .toString()
        .toLowerCase();

    return KifiyaMethodContainer(
      selected: kifiyaMethod == index,
      title: paymentName,
      kifiyaMethod: kifiyaMethod,
      imagePath: getImagePathForPayment(paymentName),
      press: () async {
        // Handle payment selection
        await handlePaymentSelection(index, paymentName);
      },
    );
  },
)
```

**Visual Display:**
- 3 columns grid
- Each payment method shown as a card
- Selected method has highlighted border
- Tapping a method triggers selection logic

---

### Step 5: User Selects Payment Method

When user taps a payment method, this logic executes:

```dart
press: () async {
  setState(() {
    kifiyaMethod = index;  // Mark this payment as selected
  });

  // CASE 1: CASH PAYMENT
  if (paymentName == "cash") {
    if (widget.onlyCashless!) {
      // Cash not allowed for cashless-only orders
      Service.showMessage(
        context: context,
        title: Provider.of<ZLanguage>(context, listen: false).onlyDigitalPayments,
        duration: 5,
      );
      setState(() {
        kifiyaMethod = -1;  // Deselect
      });
    } else {
      await useBorsa();  // Update wallet preference (not using wallet)
    }
  }

  // CASE 2: WALLET PAYMENT
  else if (paymentName == "wallet") {
    if (widget.onlyCashless! &&
        paymentResponse != null &&
        paymentResponse['wallet'] < widget.price) {
      // Insufficient balance for cashless-only order
      Service.showMessage(
        context: context,
        title: "Only digital payment accepted and your balance is insufficient!",
        duration: 5,
      );
      setState(() {
        kifiyaMethod = -1;
      });
    } else {
      await useBorsa();  // Update wallet preference (using wallet)
    }
  }

  // CASE 3: TELEBIRR REFERENCE (Manual payment)
  else if (paymentName == "telebirr reference") {
    var data = await useBorsa();

    if (data['success']) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text("Pay Using Telebirr App"),
            content: Text("Proceed to pay ${widget.price!.toStringAsFixed(2)}?"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: Text("Continue"),
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  // Navigate to reference payment screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KifiyaVerification(
                        hisab: widget.price!,
                        traceNo: widget.orderPaymentUniqueId!,
                        phone: userData['user']['phone'],
                        orderPaymentId: widget.orderPaymentId!,
                      ),
                    ),
                  ).then((success) {
                    if (success == true) {
                      // Payment verified, create order
                      if (widget.isCourier!) {
                        _createCourierOrder();
                      } else if (aliexpressCart != null &&
                                 aliexpressCart!.cart.storeId == cart.storeId) {
                        _createAliexpressOrder();
                      } else {
                        _createOrder();
                      }
                    }
                  });
                },
              ),
            ],
          );
        },
      );
    }
  }

  // CASE 4: ETHSWITCH (WebView payment)
  else if (paymentName == "ethswitch") {
    var data = await useBorsa();

    if (data != null && data['success']) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Pay Using EthSwitch"),
            content: Text("Proceed to pay ${widget.price!.toStringAsFixed(2)}?"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text("Continue"),
                onPressed: () {
                  Navigator.of(context).pop();

                  // Increment UUID for unique trace number
                  setState(() {
                    uuid = (int.parse(uuid) + 1).toString();
                  });

                  // Navigate to EthSwitch WebView
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EthSwitchScreen(
                        title: "EthSwitch Payment Gateway",
                        url: "https://pgw.shekla.app/ethioSwitch/initiate",
                        hisab: widget.price!,
                        traceNo: uuid + '_' + widget.orderPaymentUniqueId!,
                        phone: userData['user']['phone'],
                        orderPaymentId: widget.orderPaymentId!,
                      ),
                    ),
                  ).then((value) {
                    // Verify payment after returning
                    _ethSwitchVerify(uuid + '_' + widget.orderPaymentUniqueId!);
                  });
                },
              ),
            ],
          );
        },
      );
    }
  }

  // CASE 5: CHAPA (WebView payment)
  else if (paymentName == "chapa") {
    var data = await useBorsa();

    if (data != null && data['success']) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Pay Using Chapa"),
            content: Text("Proceed to pay ${widget.price!.toStringAsFixed(2)}?"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text("Continue"),
                onPressed: () {
                  Navigator.of(context).pop();

                  setState(() {
                    uuid = (int.parse(uuid) + 1).toString();
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChapaScreen(
                        title: "Chapa Payment Gateway",
                        url: "$BASE_URL/api/chapa/generatepaymenturl",
                        hisab: widget.price!,
                        traceNo: uuid + '_' + widget.orderPaymentUniqueId!,
                        phone: userData['user']['phone'],
                        orderPaymentId: widget.orderPaymentId!,
                      ),
                    ),
                  ).then((value) {
                    _boaVerify();  // Verify payment
                  });
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Similar patterns for other payment methods...
}
```

**Key Pattern:**
1. Set `kifiyaMethod = index` to mark selection
2. Call `useBorsa()` to update wallet usage preference
3. Show confirmation dialog
4. Navigate to payment screen
5. When returning, verify payment
6. Create order

---

## Payment Gateway Patterns

### Pattern 1: WebView-Based Gateways

**Used By:** Chapa, EthSwitch, SantimPay, Addis Pay, Amole, Dashen MasterCard, Etta Card, CyberSource, Yagout Pay, StarPay

**Example: Chapa Implementation**

#### File: `lib/kifiya/components/chapa_screen.dart`

```dart
class ChapaScreen extends StatefulWidget {
  const ChapaScreen({
    required this.url,          // Backend URL to initiate payment
    required this.hisab,        // Amount (Ethiopian term for "amount/bill")
    required this.phone,        // User phone number
    required this.traceNo,      // Unique transaction ID
    required this.orderPaymentId,
    this.title = "Chapa Payment",
    this.isAbroad = false,
  });
}
```

**Step 1: Initialize**

```dart
@override
void initState() {
  super.initState();
  _initiateUrl();  // Call backend to get payment URL
}
```

**Step 2: Get Payment URL from Backend**

```dart
void _initiateUrl() async {
  var data = await initiateUrl();

  if (data != null && data['success']) {
    Service.showMessage(
      context: context,
      title: "Invoice initiated successfully. Loading...",
      error: false,
      duration: 6,
    );

    setState(() {
      initUrl = data['data']['data']['checkout_url'];
    });
  }
}

Future<dynamic> initiateUrl() async {
  setState(() {
    _loading = true;
  });

  var url = widget.url;  // e.g., "$BASE_URL/api/chapa/generatepaymenturl"

  Map data = {
    "id": widget.traceNo,
    "amount": widget.hisab,
    "customization": {
      "title": "ZMall Delivery Payment",
      "description": "Order Payment to ZMall Delivery",
      "logo": null,
    },
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    Service.showMessage(
      context: context,
      title: "Something went wrong. Please check your internet connection!",
      error: true,
    );
    return null;
  }
}
```

**Backend Response:**
```json
{
  "success": true,
  "data": {
    "data": {
      "checkout_url": "https://checkout.chapa.co/checkout/payment/abcd1234efgh5678"
    }
  }
}
```

**Step 3: Display WebView**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: _loading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitWave(color: kSecondaryColor, size: 40),
                SizedBox(height: 16),
                Text("Connecting to Chapa..."),
              ],
            ),
          )
        : InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,       // Required for payment forms
              clearCache: true,              // Security: clear cache
              useShouldOverrideUrlLoading: true,
              useHybridComposition: true,    // Android
              allowsInlineMediaPlayback: true, // iOS
            ),
            initialUrlRequest: URLRequest(url: WebUri(initUrl)),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              return NavigationActionPolicy.ALLOW;
            },
          ),
    ),
  );
}
```

**Critical Settings:**
- `javaScriptEnabled: true` - Payment forms require JavaScript
- `clearCache: true` - Clear previous payment data for security
- `NavigationActionPolicy.ALLOW` - Allow redirects during payment

**Flow:**
1. Screen opens with loading indicator
2. Backend generates Chapa checkout URL
3. WebView loads Chapa payment page
4. User completes payment in Chapa interface
5. Chapa sends webhook to backend
6. User returns to app (by closing webview or back button)
7. App calls verification API to confirm payment

---

### Pattern 2: USSD/API with Polling

**Used By:** Telebirr USSD, CBE USSD

**Example: CBE USSD Implementation**

#### File: `lib/kifiya/components/cbe_ussd.dart`

```dart
class CbeUssd extends StatefulWidget {
  const CbeUssd({
    required this.url,
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.title = "CBE USSD",
    this.isAbroad = false,
    required this.serverToken,  // For verification
    required this.userId,       // For verification
  });
}
```

**Step 1: Initialize USSD Payment**

```dart
@override
void initState() {
  super.initState();
  _initPayment();
}

void _initPayment() async {
  var data = await initPayment();

  if (data != null && data['success']) {
    Service.showMessage(
      context: context,
      title: "${data['message']}. Waiting for payment to be completed",
      error: false,
      duration: 6,
    );

    _verifyPayment();  // Start polling immediately
  } else {
    Service.showMessage(
      context: context,
      title: "${data['message']}. Please try other payment methods",
      error: true,
      duration: 4,
    );

    await Future.delayed(Duration(seconds: 3));
    Navigator.pop(context);  // Close screen if initiation failed
  }
}
```

**Step 2: Call USSD API**

```dart
Future<dynamic> initPayment() async {
  setState(() {
    _loading = true;
  });

  var url = widget.url;  // USSD gateway URL

  Map data = {
    "trace_no": widget.traceNo,
    "amount": widget.hisab,
    "phone": widget.phone,
    "appId": "1234",
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    Service.showMessage(
      context: context,
      title: "Something went wrong. Please check your internet connection!",
      error: true,
    );
    return null;
  }
}
```

**What Happens:**
- API sends USSD push notification to user's phone
- User receives USSD menu on their phone
- User enters PIN and confirms payment via USSD
- Gateway processes payment and notifies backend via webhook

**Step 3: Polling Verification**

```dart
void _verifyPayment() async {
  var data = await verifyPayment();

  if (data != null && data['success']) {
    // Payment confirmed! Close screen and return to KifiyaScreen
    Navigator.pop(context);
  } else {
    // Payment not yet received, poll again after 2 seconds
    await Future.delayed(Duration(seconds: 2));
    _verifyPayment();  // RECURSIVE CALL - continues polling
  }
}

Future<dynamic> verifyPayment() async {
  setState(() {
    _loading = true;
  });

  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";

  Map data = {
    "user_id": widget.userId,
    "server_token": widget.serverToken,
    "order_payment_id": widget.orderPaymentId,
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    Service.showMessage(
      context: context,
      title: "Something went wrong. Please check your internet connection!",
      error: true,
    );
    return null;
  }
}
```

**Polling Logic:**
1. Call backend verification API
2. If `success: true` → Payment received, close screen
3. If `success: false` → Wait 2 seconds, call again
4. Continues indefinitely until payment received or user cancels

**Screen Display:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pay Using CBE Birr',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              'Powered by CBE',
              style: TextStyle(fontSize: 21, color: Colors.black45),
            ),
            Image.asset("images/payment/cbebirr.png", height: 200, width: 200),
            SizedBox(height: 10),
            SpinKitPouringHourGlassRefined(color: kBlackColor),
            SizedBox(height: 10),
            Text(
              "Please complete payment through the USSD prompt.\n"
              "Waiting for payment to be completed....",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
```

**User Experience:**
1. Screen opens showing CBE logo and loading spinner
2. User switches to their phone's USSD menu
3. User completes payment via USSD
4. App detects payment (via polling) and automatically closes screen
5. Returns to KifiyaScreen

---

### Pattern 3: WebView with Custom Backend

**Used By:** SantimPay, Addis Pay

**Example: SantimPay Implementation**

#### File: `lib/kifiya/components/santimpay_screen.dart`

```dart
class SantimPay extends StatefulWidget {
  const SantimPay({
    required this.url,
    required this.hisab,
    required this.phone,
    required this.traceNo,
    required this.orderPaymentId,
    this.title = "SantimPay Payment",
    this.isAbroad = false,
  });
}
```

**Similar to Chapa, but with different backend response:**

```dart
Future<dynamic> initiateUrl() async {
  setState(() {
    _loading = true;
  });

  var url = widget.url;

  Map data = {
    "id": widget.traceNo,
    "amount": widget.hisab,
    "reason": "ZMall Delivery Order Payment",
    "phone_number": "+251${widget.phone}",  // Note: includes country code
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    Service.showMessage(
      context: context,
      title: "Something went wrong. Please check your internet connection!",
      error: true,
    );
    return null;
  }
}
```

**Backend Response:**
```json
{
  "success": true,
  "url": "https://santimpay.com/checkout/xyz123"
}
```

**Key Difference from Chapa:**
- Response structure: `data['url']` instead of `data['data']['data']['checkout_url']`
- Requires phone number with country code format

```dart
void _initiateUrl() async {
  var data = await initiateUrl();

  if (data != null && data['success']) {
    Service.showMessage(
      context: context,
      title: "Invoice initiated successfully. Loading...",
      error: false,
      duration: 3,
    );

    setState(() {
      initUrl = data['url'];  // Direct URL access
    });
  } else {
    Service.showMessage(
      context: context,
      title: "Error while initiating payment. Please try again.",
      error: true,
      duration: 4,
    );
  }
}
```

---

### Pattern 4: Manual Reference Number

**Used By:** Telebirr Reference

**File:** `lib/kifiya/kifiya_verification.dart`

**Step 1: Post Bill to Telebirr**

```dart
@override
void initState() {
  super.initState();
  getUser();
}

void getUser() async {
  var data = await Service.read('user');

  if (data != null) {
    setState(() {
      userData = data;
    });
    _telebirrPostBill();  // Post bill immediately
  }
}

void _telebirrPostBill() async {
  setState(() {
    _loading = true;
  });

  var data = await telebirrPostBill();

  if (data != null && data['success']) {
    setState(() {
      _loading = false;
    });

    Service.showMessage(
      context: context,
      title: "${data['message']}! Please complete your payment using Tele Birr App",
      error: false,
    );
  } else {
    setState(() {
      _loading = false;
    });

    Service.showMessage(
      context: context,
      title: "${data['message']}",
      error: true,
    );
  }
}

Future<dynamic> telebirrPostBill() async {
  var url = "https://pgw.shekla.app/telebirr/post_bill";

  Map data = {
    "phone": "251${widget.phone}",
    "description": "ZMall Delivery Order Payment",
    "code": "0005",                    // ZMall's merchant code
    "trace_no": widget.traceNo,
    "amount": "${widget.hisab}",
    "appId": "1234"
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong. Please check your internet connection!"),
        backgroundColor: kSecondaryColor,
      ),
    );
    return null;
  }
}
```

**What Happens:**
- API posts the bill to Telebirr system
- Bill becomes available in Telebirr app under "Utility Payments" → "ZMALL"
- Reference number (trace_no) is the identifier

**Step 2: Display Reference Number to User**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text("Tele Birr")),
    body: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  "Pay ብር ${widget.hisab.toStringAsFixed(2)} with Tele Birr",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  "Please use the bottom reference number to complete your payment "
                  "using Tele Birr App or USSD.",
                  style: TextStyle(color: kGreyColor),
                ),
                SizedBox(height: 10),

                // REFERENCE NUMBER DISPLAY
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${widget.traceNo}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),

                // COPY BUTTON
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.traceNo));
                    setState(() {
                      copied = true;
                    });
                    Service.showMessage(
                      context: context,
                      title: "Reference number copied to clipboard!",
                      error: false,
                    );
                  },
                  child: Text("Copy Reference Number"),
                ),

                SizedBox(height: 10),

                RichText(
                  text: TextSpan(
                    text: 'Press',
                    style: TextStyle(color: kGreyColor),
                    children: [
                      TextSpan(
                        text: ' VERIFY',
                        style: TextStyle(
                          color: kBlackColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' once you\'re done paying...',
                        style: TextStyle(color: kGreyColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // VERIFY BUTTON
          CustomButton(
            title: "Verify",
            press: _telebirrVerifyBill,
            color: copied ? kSecondaryColor : kGreyColor,
          ),

          // ... Instructions section
        ],
      ),
    ),
  );
}
```

**Step 3: User Manual Payment**

User must:
1. Copy the reference number
2. Open Telebirr app
3. Navigate to: "Pay with Telebirr" → "Utility Payment" → "ZMALL"
4. Paste reference number
5. Enter PIN and confirm payment
6. Return to ZMall app
7. Click "Verify" button

**Step 4: Verification**

```dart
void _telebirrVerifyBill() async {
  if (!copied) {
    Service.showMessage(
      context: context,
      title: "Please copy the reference number and make payment on Tele Birr application.",
      error: true,
    );
    return;
  }

  setState(() {
    _loading = true;
  });

  await Future.delayed(Duration(seconds: 3));  // Give backend time to receive webhook

  var data = await telebirrVerifyBill();

  if (data != null && data['success']) {
    setState(() {
      _loading = false;
    });

    Service.showMessage(
      context: context,
      title: "Payment successful!",
      error: false,
    );

    Navigator.pop(context, true);  // Return success to KifiyaScreen
  } else {
    setState(() {
      _loading = false;
    });

    Service.showMessage(
      context: context,
      title: "${data['error']}! Please complete your payment using Tele Birr App",
      error: true,
    );
  }
}

Future<dynamic> telebirrVerifyBill() async {
  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";

  Map data = {
    "user_id": userData['user']['_id'],
    "server_token": userData['user']['server_token'],
    "order_payment_id": widget.orderPaymentId
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong. Please check your internet connection!"),
        backgroundColor: kSecondaryColor,
      ),
    );
    return null;
  }
}
```

**Verification Flow:**
1. User clicks "Verify" button
2. App waits 3 seconds (give backend time to receive webhook)
3. App calls `/admin/check_paid_order` API
4. If payment received, return `true` to KifiyaScreen
5. If not received, show error and let user try again

---

## Payment Gateway API Details

This section provides the **exact URLs and request bodies** for each payment method (excluding Telebirr InApp which is mobile-only).

### 1. Chapa (WebView Pattern)

**File:** `/lib/kifiya/components/chapa_screen.dart`

**API Endpoint:**
```
POST {gateway.url}
```
Where `{gateway.url}` comes from the payment gateway object returned by `/api/user/get_payment_gateway`

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "id": "{traceNo}",                    // Format: {uuid}_{orderPaymentUniqueId}
  "amount": 150.50,                     // Double, total amount to pay
  "customization": {
    "title": "ZMall Delivery Payment",
    "description": "Order Payment to ZMall Delivery",
    "logo": null
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "data": {
      "checkout_url": "https://checkout.chapa.co/checkout/web/payment/..."
    }
  }
}
```

**Flow:**
1. App POSTs to Chapa API with amount and trace number
2. Receives `checkout_url` from response
3. Opens `checkout_url` in WebView (`data['data']['data']['checkout_url']`)
4. User completes payment in WebView
5. Chapa redirects back and payment is verified

---

### 2. EthSwitch (WebView Pattern)

**File:** `/lib/kifiya/components/ethswitch_screen.dart`

**API Endpoint:**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "amount": 15050,                      // Integer: amount * 100 (in cents/santim)
  "description": "ZMall Delivery Order Payment",
  "issued_to": "0912345678",            // Phone with leading 0
  "appId": "1234"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment initiated",
  "data": {
    "formUrl": "https://ethswitch.et/payment/..."
  }
}
```

**Flow:**
1. App POSTs with amount (multiplied by 100), trace number, and phone
2. Receives `formUrl` from response (`data['data']['formUrl']`)
3. Opens `formUrl` in WebView
4. User completes payment
5. EthSwitch redirects and verifies payment

**Important:** Amount must be multiplied by 100 (line 123)

---

### 3. SantimPay (WebView Pattern)

**File:** `/lib/kifiya/components/santimpay_screen.dart`

**API Endpoint:**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "id": "{traceNo}",                    // Format: {uuid}_{orderPaymentUniqueId}
  "amount": 150.50,                     // Double
  "reason": "ZMall Delivery Order Payment",
  "phone_number": "+251912345678"       // Full phone with country code
}
```

**Response:**
```json
{
  "success": true,
  "url": "https://santimpay.com/payment/..."
}
```

**Flow:**
1. App POSTs with amount, trace number, phone number
2. Receives `url` from response (`data['url']`)
3. Opens URL in WebView
4. User completes payment
5. SantimPay verifies and redirects

---

### 4. Telebirr WebView (WebView Pattern)

**File:** `/lib/kifiya/components/telebirr_screen.dart`

**API Endpoint:**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "phone": "+251912345678",             // Full phone (adds +251 if not abroad)
  "description": "ZMall Order Payment",
  "amount": 150.50,                     // Double
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "appId": "1234",
  "returnUrl": "/"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment initiated",
  "data": {
    "data": {
      "toPayUrl": "https://telebirr.com/payment/..."
    }
  }
}
```

**Flow:**
1. App POSTs with phone, amount, trace number
2. Receives `toPayUrl` from response (`data['data']['data']['toPayUrl']`)
3. Opens `toPayUrl` in WebView
4. User completes payment in WebView
5. Telebirr redirects and verifies

---

### 5. Telebirr USSD (USSD with Polling Pattern)

**File:** `/lib/kifiya/components/telebirr_ussd.dart`

**API Endpoint (Initiate):**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body (Initiate):**
```json
{
  "traceNo": "{traceNo}",               // Format: {uuid}_{orderPaymentUniqueId}
  "amount": 150.50,                     // Double
  "phone": "251912345678",              // Phone with 251 prefix (no +)
  "payerId": "22",
  "appId": "1234",
  "apiKey": "90e503b019a811ef9bc8005056a4ed36",
  "zmall": true
}
```

**Response (Initiate):**
```json
{
  "result": {
    "success": true,
    "message": "USSD prompt sent to your phone"
  }
}
```

**Verification Endpoint:**
```
POST {baseUrl}/admin/check_paid_order
```

**Request Body (Verify):**
```json
{
  "user_id": "{userId}",
  "server_token": "{serverToken}",
  "order_payment_id": "{orderPaymentId}"
}
```

**Response (Verify):**
```json
{
  "success": true  // or false if not paid yet
}
```

**Flow:**
1. App POSTs to initiate USSD
2. User receives USSD prompt on their phone (*127#)
3. App starts polling `/admin/check_paid_order` every 2 seconds
4. When payment is confirmed, response returns `success: true`
5. App closes payment screen and navigates back

---

### 6. Telebirr Manual Reference (Manual Reference Pattern)

**File:** `/lib/kifiya/kifiya_verification.dart`

**API Endpoint:**
```
POST https://pgw.shekla.app/telebirr/post_bill
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "phone": "+251912345678",             // Full phone with country code
  "description": "ZMall Delivery Order Payment",
  "code": "0005",                       // Biller code
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "amount": "150.50",                   // String format
  "appId": "1234"
}
```

**Response:**
```json
{
  "success": true,
  "reference_number": "REF123456789"
}
```

**Flow:**
1. App POSTs to generate reference number
2. User receives reference number
3. User manually pays via Telebirr app or USSD using reference number
4. User returns to app and submits reference number
5. App verifies payment with backend

---

### 7. CBE USSD (USSD with Polling Pattern)

**File:** `/lib/kifiya/components/cbe_ussd.dart`

**API Endpoint (Initiate):**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body (Initiate):**
```json
{
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "amount": 150.50,                     // Double
  "phone": "912345678",                 // 9 digits (no country code)
  "appId": "1234"
}
```

**Response (Initiate):**
```json
{
  "success": true,
  "message": "USSD prompt sent"
}
```

**Verification Endpoint:**
```
POST {baseUrl}/admin/check_paid_order
```

**Request Body (Verify):**
```json
{
  "user_id": "{userId}",
  "server_token": "{serverToken}",
  "order_payment_id": "{orderPaymentId}"
}
```

**Flow:**
1. App POSTs to initiate CBE Birr USSD
2. User receives USSD prompt on phone
3. App polls `/admin/check_paid_order` every 2 seconds
4. When paid, returns `success: true` and closes screen

---

### 8. Amole (OTP-Based Pattern)

**File:** `/lib/kifiya/components/amole_screen.dart`

**API Endpoint (Send OTP):**
```
POST {baseUrl}/api/user/send_otp
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body (Send OTP):**
```json
{
  "user_id": "{userId}",
  "phone": "912345678",
  "type": "{admin_type}",               // User type from user object
  "token": "{server_token}",
  "country_phone_code": "+251"
}
```

**Response (Send OTP):**
```json
{
  "success": true
}
```

**Flow:**
1. App POSTs to send OTP to user's phone
2. User receives OTP from Amole
3. User enters OTP in app
4. App returns OTP to KifiyaScreen
5. KifiyaScreen uses OTP to complete payment

**Note:** Amole implementation is different - it collects OTP and returns it to parent screen for processing.

---

### 9. StarPay (WebView with Items Pattern)

**File:** `/lib/kifiya/components/starpay_screen.dart`

**API Endpoint:**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "items": [
    {
      "productId": "prod_123",
      "quantity": 2,
      "item_name": "Burger",
      "unit_price": 75.25
    },
    {
      "productId": "prod_456",
      "quantity": 1,
      "item_name": "Fries",
      "unit_price": 30.00
    }
  ],
  "email": "user@example.com",
  "amount": 150.50,                     // Double, total amount
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "last_name": "Doe",
  "first_name": "John",
  "phone": "+251912345678",
  "description": "Order payment Zmall Food Delivery"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Payment initiated",
    "data": {
      "payment_url": "https://starpay.et/checkout/..."
    }
  }
}
```

**Flow:**
1. App POSTs with cart items array, user details, amount
2. Receives `payment_url` from response (`data['data']['data']['payment_url']`)
3. Opens `payment_url` in WebView
4. User completes payment
5. StarPay redirects and verifies

**Unique Feature:** StarPay requires full cart items with productId, quantity, item_name, and unit_price.

---

### 10. EventSantim (Direct URL - No API Call)

**File:** `/lib/kifiya/components/event_santim.dart`

**API Endpoint:** None (direct WebView load)

**Flow:**
1. KifiyaScreen already has pre-generated URL from backend
2. Opens `widget.url` directly in WebView
3. User completes payment in WebView
4. EventSantim redirects back to app

**Note:** No client-side API call required. The URL is generated by the backend and passed directly to the screen.

---

### 11. YagoutPay (WebView Pattern)

**File:** `/lib/kifiya/components/yagoutpay.dart`

**API Endpoint:**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "phone": "912345678",                 // 9 digits (no country code)
  "amount": 150.50,                     // Double
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "first_name": "John",
  "last_name": "Doe",
  "appId": "123456",
  "description": "ZMall YgoutPay order payment"
}
```

**Response:**
Raw text response containing PaymentLink:
```json
"...\"PaymentLink\":\"https://yagoutpay.com/payment/...\"..."
```

**Flow:**
1. App POSTs with phone, amount, user details
2. Response is raw text (not clean JSON)
3. App extracts `PaymentLink` using regex: `"PaymentLink"\s*:\s*"([^"]+)"`
4. Opens extracted URL in WebView
5. User completes payment

**Special Handling:** YagoutPay returns non-standard response, requires regex extraction (line 144-146).

---

### 12. AddisPay (WebView Pattern)

**File:** `/lib/kifiya/components/addis_pay.dart`

**API Endpoint:**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "appId": "123456",
  "amount": "150.50",                   // String format
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "phone": "912345678",                 // 9 digits
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "description": "ZMall Order payment"
}
```

**Response:**
```json
{
  "checkout_url": "https://addispay.et/checkout/...",
  "uuid": "unique-transaction-id"
}
```

**Flow:**
1. App POSTs with amount (as string), user details, trace number
2. Receives `checkout_url` and `uuid`
3. Constructs full URL: `${checkout_url}/${uuid}`
4. Opens constructed URL in WebView (line 69)
5. User completes payment

**Important:** Amount is sent as string, and final URL is `checkout_url + "/" + uuid`.

---

### 13. CyberSource (Direct URL - No API Call)

**File:** `/lib/kifiya/components/cyber_source.dart`

**API Endpoint:** None (direct WebView load)

**Flow:**
1. KifiyaScreen already has pre-generated URL from backend
2. Opens `widget.url` directly in WebView (Bank of Abyssinia Cybersource)
3. User completes payment in WebView
4. Cybersource redirects back to app

**Note:** Like EventSantim, no client-side API call. URL comes from backend.

---

### 14. Dashen MasterCard (WebView Pattern)

**File:** `/lib/kifiya/components/dashen_master_card.dart`

**API Endpoint:**
```
POST {gateway.url}
```

**Request Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Request Body:**
```json
{
  "amount": 150.50,                     // Double
  "currency": "ETB",                    // or "USD" if isAbroad
  "phone": "+251912345678",             // Full phone with country code
  "trace_no": "{traceNo}",              // Format: {uuid}_{orderPaymentUniqueId}
  "orderPaymentId": "{orderPaymentId}", // MongoDB ObjectID
  "appId": "1234",
  "description": "ZMall Order Payment"
}
```

**Response:**
```json
{
  "success": true,
  "mastercardUrl": "https://dashenbank.et/mastercard/..."
}
```

**Flow:**
1. App POSTs with amount, currency, phone, order payment ID
2. Receives `mastercardUrl` from response (`data['mastercardUrl']`)
3. Opens `mastercardUrl` in WebView
4. User enters card details and completes payment
5. Dashen Bank redirects and verifies

**Important:** Includes `orderPaymentId` in request body (unlike most other gateways).

---

### Summary Table: Payment Gateway APIs

| Payment Method | Pattern | API Call Required | Key Request Fields | Response URL Field |
|----------------|---------|-------------------|--------------------|--------------------|
| **Chapa** | WebView | ✅ Yes | `id`, `amount`, `customization` | `data.data.checkout_url` |
| **EthSwitch** | WebView | ✅ Yes | `trace_no`, `amount * 100`, `issued_to` | `data.formUrl` |
| **SantimPay** | WebView | ✅ Yes | `id`, `amount`, `phone_number` | `url` |
| **Telebirr WebView** | WebView | ✅ Yes | `phone`, `amount`, `trace_no`, `returnUrl` | `data.data.toPayUrl` |
| **Telebirr USSD** | USSD + Polling | ✅ Yes | `traceNo`, `phone`, `apiKey`, `zmall: true` | N/A (polling) |
| **Telebirr Reference** | Manual | ✅ Yes | `phone`, `code: "0005"`, `trace_no` | `reference_number` |
| **CBE USSD** | USSD + Polling | ✅ Yes | `trace_no`, `amount`, `phone` | N/A (polling) |
| **Amole** | OTP | ✅ Yes | `user_id`, `phone`, `token` | N/A (returns OTP) |
| **StarPay** | WebView | ✅ Yes | `items[]`, `email`, `amount`, `phone` | `data.data.payment_url` |
| **EventSantim** | Direct URL | ❌ No | N/A | N/A (direct load) |
| **YagoutPay** | WebView | ✅ Yes | `phone`, `amount`, `first_name`, `last_name` | Extract with regex |
| **AddisPay** | WebView | ✅ Yes | `amount` (string), `email`, `first_name` | `checkout_url` + `uuid` |
| **CyberSource** | Direct URL | ❌ No | N/A | N/A (direct load) |
| **Dashen MasterCard** | WebView | ✅ Yes | `amount`, `currency`, `orderPaymentId` | `mastercardUrl` |

### Common Request Parameters

Parameters that appear across multiple gateways:

| Parameter | Purpose | Format | Gateways |
|-----------|---------|--------|----------|
| **trace_no / traceNo / id** | Unique transaction identifier | `{uuid}_{orderPaymentUniqueId}` | All except Amole, EventSantim, CyberSource |
| **amount** | Payment amount | `Double` or `Integer` (EthSwitch *100) | All except EventSantim, CyberSource |
| **phone / phone_number** | User phone number | Various formats (see individual docs) | 12 out of 14 |
| **appId** | Application identifier | `"1234"` or `"123456"` | 11 out of 14 |
| **description / reason** | Payment description | String | 9 out of 14 |
| **first_name, last_name** | User name | Strings | StarPay, YagoutPay, AddisPay |
| **email** | User email | String | StarPay, AddisPay |

### Important Notes

1. **Trace Number Format:** Most gateways use `{uuid}_{orderPaymentUniqueId}` format
2. **Phone Number Formats:**
   - Full with country code: `+251912345678` (Telebirr WebView, SantimPay, StarPay, Dashen)
   - With country prefix (no +): `251912345678` (Telebirr USSD)
   - With leading 0: `0912345678` (EthSwitch)
   - 9 digits only: `912345678` (CBE USSD, Amole, YagoutPay, AddisPay)
3. **Amount Formats:**
   - Most: Double (e.g., `150.50`)
   - EthSwitch: Integer in cents (`amount * 100`)
   - AddisPay, Telebirr Reference: String (e.g., `"150.50"`)
4. **Direct URL Gateways:** EventSantim and CyberSource don't require client-side API calls
5. **Special Cases:**
   - YagoutPay uses regex extraction for payment link
   - AddisPay constructs URL from `checkout_url + "/" + uuid`
   - StarPay requires full cart items array
   - Amole returns OTP instead of payment URL

---

## Critical API Functions

### 1. useBorsa() - Update Wallet Preference

**Called:** Before navigating to any payment gateway

**Purpose:** Tell backend if user wants to use wallet balance or not

```dart
Future<dynamic> useBorsa() async {
  setState(() {
    _loading = true;
  });

  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/change_user_wallet_status";

  Map data = {
    "user_id": userData['user']['_id'],
    "is_use_wallet": kifiyaMethod != -1 &&
        paymentResponse['payment_gateway'][kifiyaMethod]['name']
            .toString()
            .toLowerCase() == "wallet",
    "server_token": userData['user']['server_token'],
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong."),
        backgroundColor: kSecondaryColor,
      ),
    );
    return null;
  }
}
```

**Logic:**
- `is_use_wallet = true` if selected payment method is "wallet"
- `is_use_wallet = false` for all other methods

**Request:**
```json
{
  "user_id": "60a7b3c4e5f6g7h8i9j0k1",
  "is_use_wallet": false,
  "server_token": "session_token"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Wallet preference updated"
}
```

---

### 2. boaVerify() - Payment Verification

**Called:** After returning from WebView payment gateways

**Purpose:** Check if backend received payment webhook

```dart
Future<dynamic> boaVerify({String title = "Verifying payment..."}) async {
  setState(() {
    linearProgressIndicator = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitWave(
            color: kSecondaryColor,
            size: getProportionateScreenWidth(kDefaultPadding),
          ),
          SizedBox(height: kDefaultPadding * 0.5),
          Text(title, style: TextStyle(color: kBlackColor)),
        ],
      ),
    );
  });

  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/check_paid_order";

  Map data = {
    "user_id": userData['user']['_id'],
    "server_token": userData['user']['server_token'],
    "order_payment_id": widget.orderPaymentId,
  };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 30));

    return json.decode(response.body);
  } catch (e) {
    return null;
  }
}
```

**Called From:**
```dart
void _boaVerify() async {
  setState(() {
    _loading = true;
    _placeOrder = true;
  });

  var data = await boaVerify();

  if (data != null && data['success']) {
    setState(() {
      _loading = false;
      _placeOrder = false;
    });

    Service.showMessage(
      context: context,
      title: "Payment verification Successfull!",
      error: false,
      duration: 2,
    );

    // Create order based on type
    widget.isCourier!
        ? _createCourierOrder()
        : (aliexpressCart != null && aliexpressCart!.cart.storeId == cart.storeId)
            ? _createAliexpressOrder()
            : _createOrder();
  } else {
    setState(() {
      _loading = false;
      _placeOrder = false;

      if (widget.onlyCashless!) {
        kifiyaMethod = -1;
      } else {
        kifiyaMethod = 1;
      }
    });

    await useBorsa();

    Service.showMessage(
      context: context,
      title: "${data['error']}! Please complete your payment!",
      error: true,
    );

    await Future.delayed(Duration(seconds: 3));
  }
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Payment verified",
  "payment_details": {
    "amount": 1250.00,
    "currency": "ETB",
    "gateway": "Chapa",
    "trace_no": "123_ORD_20231215_ABC"
  }
}
```

**Response (Not Paid):**
```json
{
  "success": false,
  "error": "Payment not yet received"
}
```

---

### 3. payOrderPayment() - Register Payment Method

**Called:** When user clicks "Place Order" button

**Purpose:** Tell backend which payment method user selected

```dart
Future<dynamic> payOrderPayment(otp, paymentId) async {
  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/pay_order_payment";

  Map data = widget.isCourier!
      ? {
          "user_id": userData['user']['_id'],
          "otp": otp,
          "order_payment_id": widget.orderPaymentId,
          "payment_id": paymentId,
          "order_type": 7,
          "is_payment_mode_cash": kifiyaMethod != -1 &&
              (paymentResponse['payment_gateway'][kifiyaMethod]['name']
                      .toString()
                      .toLowerCase() == "wallet" ||
                  paymentResponse['payment_gateway'][kifiyaMethod]['name']
                      .toString()
                      .toLowerCase() == "cash"),
          "server_token": userData['user']['server_token'],
        }
      : {
          "user_id": userData['user']['_id'],
          "otp": otp,
          "order_payment_id": widget.orderPaymentId,
          "payment_id": paymentId,
          "order_type": 1,
          "is_payment_mode_cash": kifiyaMethod != -1 &&
              (paymentResponse['payment_gateway'][kifiyaMethod]['name']
                      .toString()
                      .toLowerCase() == "wallet" ||
                  paymentResponse['payment_gateway'][kifiyaMethod]['name']
                      .toString()
                      .toLowerCase() == "cash"),
          "server_token": userData['user']['server_token'],
        };

  var body = json.encode(data);

  try {
    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    setState(() {
      this._loading = false;
    });

    return json.decode(response.body);
  } catch (e) {
    setState(() {
      this._loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong."),
        backgroundColor: kSecondaryColor,
      ),
    );
    return null;
  }
}
```

**Called From:**
```dart
void _payOrderPayment({otp, paymentId = ""}) async {
  var pId = "";

  if (otp.toString().isNotEmpty) {
    pId = paymentId;
  } else {
    if (widget.isCourier != null && widget.isCourier == false) {
      pId = "0";
    }
  }

  if (kifiyaMethod != -1) {
    setState(() {
      _loading = true;
      _placeOrder = true;
    });

    var data = await payOrderPayment(
      otp,
      paymentResponse['payment_gateway'][kifiyaMethod]['_id'],
    );

    if (data != null && data['success']) {
      // Create order
      widget.isCourier!
          ? _createCourierOrder()
          : (aliexpressCart != null && aliexpressCart!.cart.storeId == cart.storeId)
              ? _createAliexpressOrder()
              : _createOrder();
    } else {
      setState(() {
        _loading = false;
        _placeOrder = false;
      });

      Service.showMessage(
        context: context,
        title: "${errorCodes['${data['error_code']}']}!",
        error: true,
      );

      await Future.delayed(Duration(seconds: 2));

      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  } else {
    Service.showMessage(
      context: context,
      title: "Please select a payment method for your order.",
      error: true,
      duration: 4,
    );
  }
}
```

**Request:**
```json
{
  "user_id": "60a7b3c4e5f6g7h8i9j0k1",
  "otp": "",
  "order_payment_id": "payment_session_id",
  "payment_id": "gateway_id_4",
  "order_type": 1,
  "is_payment_mode_cash": false,
  "server_token": "session_token"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment method registered"
}
```

---

### 4. createOrder() - Final Order Creation

**Called:** After payment verification succeeds

**Purpose:** Create the actual order in the system

```dart
Future<dynamic> createOrder({List<dynamic>? orderIds}) async {
  setState(() {
    linearProgressIndicator = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitWave(
            color: kSecondaryColor,
            size: getProportionateScreenWidth(kDefaultPadding),
          ),
          SizedBox(height: kDefaultPadding * 0.5),
          Text("Creating order...", style: TextStyle(color: kBlackColor)),
        ],
      ),
    );
  });

  var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/create_order";

  try {
    List<dynamic>? filteredOrderIds;
    if (aliexpressCart != null && aliexpressCart!.cart.storeId == cart.storeId) {
      filteredOrderIds = orderIds?.where((id) => id != null).toList();
    }

    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
      "order_payment_id": widget.orderPaymentId,
      "store_delivery_id": widget.orderPaymentId,
      "cart_id": cart.cartId,
      "cart_unique_token": cart.uniqueToken,
      "is_user_pick_up_order": cart.isUserPickUpOrder,
      "orderIds": filteredOrderIds ?? [],
    };

    var body = json.encode(data);

    http.Response response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    ).timeout(Duration(seconds: 30));

    setState(() {
      orderResponse = json.decode(response.body);
      this._loading = false;
      this._placeOrder = false;
    });

    return orderResponse;
  } catch (e) {
    setState(() {
      this._loading = false;
      this._placeOrder = false;
    });

    Service.showMessage(
      context: context,
      title: "Failed to create order, please check your internet and try again",
      error: true,
    );
    return null;
  }
}
```

**Called From:**
```dart
void _createOrder({List<dynamic>? orderIds}) async {
  setState(() {
    _loading = true;
    _placeOrder = true;
  });

  var data = await createOrder(orderIds: orderIds);

  if (data != null && data['success']) {
    Service.showMessage(
      context: context,
      title: "Order successfully created",
      error: false,
    );

    await Service.remove('cart');
    await Service.remove('aliexpressCart');

    setState(() {
      _loading = false;
      _placeOrder = false;
    });

    // Navigate to success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          price: widget.price!,
          orderPaymentUniqueId: widget.orderPaymentUniqueId!,
        ),
      ),
    );
  } else {
    Service.showMessage(
      context: context,
      title: "${errorCodes['${data['error_code']}']}!",
      error: true,
    );

    setState(() {
      _loading = false;
      _placeOrder = false;
    });
  }
}
```

**Request:**
```json
{
  "user_id": "60a7b3c4e5f6g7h8i9j0k1",
  "server_token": "session_token",
  "order_payment_id": "payment_session_id",
  "store_delivery_id": "payment_session_id",
  "cart_id": "cart_unique_id",
  "cart_unique_token": "cart_token",
  "is_user_pick_up_order": false,
  "orderIds": []
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "_id": "order_id",
    "unique_id": "ORD_20231215_ABC123",
    "total": 1250.00,
    "delivery_fee": 50.00,
    "status": "pending",
    "created_at": "2023-12-15T10:30:00Z"
  }
}
```

---

## Web Implementation Guidance

### Key Differences Mobile vs Web

| Aspect | Mobile (Flutter) | Web (React/Vue/Angular) |
|--------|------------------|-------------------------|
| **WebView** | InAppWebView widget | iframe or popup window |
| **Storage** | SharedPreferences | localStorage or cookies |
| **Polling** | Recursive async function | setInterval or recursive setTimeout |
| **Navigation** | Navigator.push/pop | React Router or similar |
| **State** | setState() | useState/Redux/Vuex |

---

### Web Pattern 1: WebView → iframe

**Mobile Code:**
```dart
InAppWebView(
  initialSettings: settings,
  initialUrlRequest: URLRequest(url: WebUri(initUrl)),
  shouldOverrideUrlLoading: (controller, navigationAction) async {
    return NavigationActionPolicy.ALLOW;
  },
)
```

**Web Equivalent (React):**
```jsx
function ChapaPayment({ amount, traceNo, onSuccess, onError }) {
  const [paymentUrl, setPaymentUrl] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    initiatePayment();
  }, []);

  const initiatePayment = async () => {
    try {
      const response = await fetch('/api/chapa/generatepaymenturl', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',  // Include session cookie
        body: JSON.stringify({
          id: traceNo,
          amount: amount,
          customization: {
            title: "ZMall Delivery Payment",
            description: "Order Payment to ZMall Delivery",
            logo: null,
          },
        }),
      });

      const data = await response.json();

      if (data.success) {
        setPaymentUrl(data.data.data.checkout_url);
        setLoading(false);
      } else {
        onError(data.message);
      }
    } catch (error) {
      onError("Failed to initiate payment");
    }
  };

  if (loading) {
    return <LoadingSpinner message="Connecting to Chapa..." />;
  }

  return (
    <div className="payment-modal">
      <iframe
        src={paymentUrl}
        width="100%"
        height="600px"
        frameBorder="0"
        title="Chapa Payment"
        style={{ border: 'none' }}
      />
    </div>
  );
}
```

---

### Web Pattern 2: USSD Polling

**Mobile Code:**
```dart
void _verifyPayment() async {
  var data = await verifyPayment();

  if (data != null && data['success']) {
    Navigator.pop(context);
  } else {
    await Future.delayed(Duration(seconds: 2));
    _verifyPayment();  // Recursive call
  }
}
```

**Web Equivalent (React):**
```jsx
function CbeUssdPayment({ amount, traceNo, orderPaymentId, userId, serverToken, onSuccess }) {
  const [checking, setChecking] = useState(false);
  const pollingIntervalRef = useRef(null);

  useEffect(() => {
    initializePayment();

    return () => {
      // Cleanup: stop polling when component unmounts
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current);
      }
    };
  }, []);

  const initializePayment = async () => {
    try {
      const response = await fetch('/api/cbe-ussd/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          trace_no: traceNo,
          amount: amount,
          phone: userData.phone,
          appId: "1234",
        }),
      });

      const data = await response.json();

      if (data.success) {
        toast.success(`${data.message}. Waiting for payment...`);
        startPolling();
      } else {
        toast.error(`${data.message}. Please try other payment methods.`);
        setTimeout(() => onError(), 3000);
      }
    } catch (error) {
      toast.error("Failed to initialize payment");
    }
  };

  const startPolling = () => {
    setChecking(true);

    pollingIntervalRef.current = setInterval(async () => {
      const verified = await verifyPayment();

      if (verified) {
        clearInterval(pollingIntervalRef.current);
        setChecking(false);
        onSuccess();
      }
    }, 2000); // Poll every 2 seconds

    // Stop polling after 5 minutes
    setTimeout(() => {
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current);
        setChecking(false);
        toast.error("Payment timeout. Please try again.");
      }
    }, 300000);
  };

  const verifyPayment = async () => {
    try {
      const response = await fetch('/api/check-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          user_id: userId,
          server_token: serverToken,
          order_payment_id: orderPaymentId,
        }),
      });

      const data = await response.json();
      return data.success;
    } catch (error) {
      return false;
    }
  };

  return (
    <div className="ussd-payment-screen">
      <img src="/images/cbebirr.png" alt="CBE Birr" />
      {checking && (
        <>
          <Spinner />
          <p>Please complete payment through the USSD prompt on your phone...</p>
          <p>Waiting for payment to be completed....</p>
        </>
      )}
    </div>
  );
}
```

---

### Web Pattern 3: Manual Reference

**Mobile Code:**
```dart
TextButton(
  onPressed: () {
    Clipboard.setData(ClipboardData(text: widget.traceNo));
    setState(() {
      copied = true;
    });
  },
  child: Text("Copy Reference Number"),
),
```

**Web Equivalent (React):**
```jsx
function TelebirrReferencePayment({ amount, traceNo, orderPaymentId }) {
  const [copied, setCopied] = useState(false);
  const [verifying, setVerifying] = useState(false);

  useEffect(() => {
    postBill();
  }, []);

  const postBill = async () => {
    try {
      const response = await fetch('/api/telebirr/post-bill', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          phone: `251${userData.phone}`,
          description: "ZMall Delivery Order Payment",
          code: "0005",
          trace_no: traceNo,
          amount: `${amount}`,
          appId: "1234",
        }),
      });

      const data = await response.json();

      if (data.success) {
        toast.success(`${data.message}! Please pay using Telebirr app.`);
      } else {
        toast.error(data.message);
      }
    } catch (error) {
      toast.error("Failed to post bill");
    }
  };

  const copyReferenceNumber = () => {
    navigator.clipboard.writeText(traceNo);
    setCopied(true);
    toast.success("Reference number copied to clipboard!");
  };

  const verifyPayment = async () => {
    if (!copied) {
      toast.error("Please copy the reference number first.");
      return;
    }

    setVerifying(true);

    // Wait 3 seconds (give backend time to receive webhook)
    await new Promise(resolve => setTimeout(resolve, 3000));

    try {
      const response = await fetch('/api/check-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ order_payment_id: orderPaymentId }),
      });

      const data = await response.json();
      setVerifying(false);

      if (data.success) {
        toast.success("Payment verified!");
        onPaymentSuccess();
      } else {
        toast.error(`${data.error}! Please complete payment and try again.`);
      }
    } catch (error) {
      setVerifying(false);
      toast.error("Verification failed");
    }
  };

  //return (
    // <div className="reference-payment">
    //   <div className="payment-card">
    //     <h2>Pay ብር {amount.toFixed(2)} with Tele Birr</h2>
    //     <p>Use the reference number below to complete payment via Telebirr app.</p>

    //     <div className="reference-box">
    //       <div className="reference-number">{traceNo}</div>
    //     </div>

    //     <button onClick={copyReferenceNumber} className="copy-btn">
    //       {copied ? "✓ Copied" : "Copy Reference Number"}
    //     </button>

    //     <p className="instruction">
    //       Press <strong>VERIFY</strong> once you're done paying...
    //     </p>
    //   </div>

    //   <button
    //     onClick={verifyPayment}
    //     disabled={!copied || verifying}
    //     className={`verify-btn ${copied ? 'active' : 'disabled'}`}
    //   >
  //       {verifying ? "Verifying..." : "Verify"}
  //     </button>

  //     <div className="instructions">
  //       <h3>How to pay with Telebirr?</h3>
  //       <ol>
  //         <li>Copy the reference number above ☝🏾</li>
  //         <li>Open Telebirr App and Login</li>
  //         <li>Press "Pay with Telebirr"</li>
  //         <li>Press "Utility Payment"</li>
  //         <li>Press "ZMALL"</li>
  //         <li>Paste the reference number and proceed</li>
  //         <li>Press Verify to complete</li>
  //       </ol>
  //     </div>
  //   </div>
  // );
}
```

---

## Summary: Complete Payment Flow

### For Regular E-Commerce Order (Cash/Wallet/Digital Payment)

```
1. User navigates to KifiyaScreen
2. Screen fetches payment gateways from API
3. User selects payment method
4. App calls useBorsa() to set wallet preference
5. App navigates to payment screen OR creates order directly (cash/wallet)
6. For digital payments:
   a. WebView: User pays, returns, app verifies
   b. USSD: App initiates, polls until verified
   c. Reference: User pays manually, clicks verify
7. After verification, app calls payOrderPayment()
8. App calls createOrder()
9. Navigate to success screen
```

### Critical Points for Web Implementation

1. **Session Management**: Use httpOnly cookies, not localStorage
2. **Polling**: Implement cleanup on component unmount
3. **iframe Security**: Set CSP headers properly
4. **Error Handling**: Handle network failures gracefully
5. **Webhooks**: Backend must validate signatures
6. **Trace Numbers**: Ensure uniqueness (use UUID + timestamp)
7. **Payment Verification**: Always verify on backend before creating order

---

**End of Document**

This documentation provides the exact code-level details needed to replicate ZMall's payment system on the web. All patterns have been extracted from actual production code.

