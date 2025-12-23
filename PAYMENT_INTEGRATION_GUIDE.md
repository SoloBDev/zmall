# ZMall Payment Integration Guide

> **Comprehensive documentation for understanding and implementing ZMall's payment system**
> **Target Audience**: Developers building the web version of ZMall
> **Last Updated**: December 2025
> **Version**: 3.2.3+339

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Payment Flow](#payment-flow)
4. [Payment Gateway Integration Patterns](#payment-gateway-integration-patterns)
5. [Individual Payment Gateway Implementations](#individual-payment-gateway-implementations)
6. [API Endpoints](#api-endpoints)
7. [Data Models](#data-models)
8. [Error Handling](#error-handling)
9. [Security Considerations](#security-considerations)
10. [Web Implementation Guide](#web-implementation-guide)
11. [Testing Checklist](#testing-checklist)

---

## Overview

### What is Kifiya?

**Kifiya** (ክፍያ) is the Amharic word for "payment". The `/lib/kifiya` directory contains all payment-related functionality in the ZMall mobile app, supporting 10+ payment gateways for Ethiopian, South Sudanese, and international transactions.

### Supported Payment Methods

| Payment Gateway | Type | Region | Integration Method |
|----------------|------|--------|-------------------|
| **Telebirr InApp** | Mobile Money | Ethiopia | Native SDK (Platform Channels) |
| **Telebirr USSD** | Mobile Money | Ethiopia | API + Polling |
| **Telebirr Reference** | Mobile Money | Ethiopia | Reference Number + Manual Verification |
| **Chapa** | Payment Aggregator | Ethiopia | WebView (Hosted Checkout) |
| **EthSwitch** | Banking Network | Ethiopia | WebView (Payment Form) |
| **Addis Pay** | Payment Gateway | Ethiopia | WebView |
| **Amole** | Mobile Money | Ethiopia | WebView |
| **CBE USSD** | Bank USSD | Ethiopia | API |
| **Dashen MasterCard** | Bank Card | Ethiopia | WebView |
| **SantimPay** | Digital Wallet | Ethiopia | WebView |
| **StarPay** | Payment Gateway | Ethiopia | WebView |
| **YagoutPay** | Payment Gateway | Ethiopia | WebView |
| **Etta Card** | Card Payment | Ethiopia | WebView |
| **CyberSource** | International Cards | Global | WebView |
| **Event Santim** | Event Payments | Ethiopia | WebView |
| **Momo USSD** | Mobile Money | South Sudan | API |
| **Wallet (Borsa)** | ZMall Digital Wallet | App-wide | Internal API |
| **Cash** | Cash on Delivery | Local | No integration needed |

---

## Architecture

### Directory Structure

```
lib/kifiya/
├── kifiya_screen.dart                      # Main payment method selection screen
├── kifiya_verification.dart                # Telebirr reference verification
├── components/
│   ├── kifiya_method_container.dart        # Payment method card widget
│   ├── telebirr_inapp.dart                 # Telebirr SDK integration
│   ├── telebirr_screen.dart                # Telebirr standard flow
│   ├── telebirr_ussd.dart                  # Telebirr USSD payment
│   ├── chapa_screen.dart                   # Chapa payment gateway
│   ├── ethswitch_screen.dart               # EthSwitch integration
│   ├── addis_pay.dart                      # Addis Pay gateway
│   ├── amole_screen.dart                   # Amole mobile money
│   ├── cbe_ussd.dart                       # CBE USSD payments
│   ├── dashen_master_card.dart             # Dashen bank cards
│   ├── santimpay_screen.dart               # SantimPay wallet
│   ├── starpay_screen.dart                 # StarPay gateway
│   ├── yagoutpay.dart                      # YagoutPay gateway
│   ├── etta_card_screen.dart               # Etta card payments
│   ├── cyber_source.dart                   # CyberSource international
│   ├── event_santim.dart                   # Event payments
│   └── momo_ussd.dart                      # Momo USSD (South Sudan)
```

### Key Services

```
lib/services/
├── service.dart              # Main service handler (payment helpers, utilities)
└── core_services.dart        # API integration layer
```

### State Management

- **Provider Pattern**: Used for global state (user data, metadata)
- **setState()**: Used for local component state
- **SharedPreferences**: For persistent cart and user data
- **FlutterSecureStorage**: For sensitive payment credentials

---

## Payment Flow

### High-Level Payment Flow Diagram

```
┌─────────────────┐
│  Checkout       │
│  Screen         │
└────────┬────────┘
         │
         │ Navigate to Kifiya
         ▼
┌─────────────────┐
│  KifiyaScreen   │ ◄─── Fetch Payment Gateways from API
│  (Payment       │
│   Selection)    │
└────────┬────────┘
         │
         │ User selects payment method
         ▼
┌─────────────────┐
│  Verify Stock   │
│  & Availability │
└────────┬────────┘
         │
         │ Stock Available
         ▼
┌─────────────────┐
│  Initialize     │ ◄─── Generate unique trace number
│  Payment        │      (UUID + orderPaymentUniqueId)
└────────┬────────┘
         │
         ├─────────────────┬──────────────┬────────────┐
         │                 │              │            │
         ▼                 ▼              ▼            ▼
┌──────────────┐  ┌──────────────┐  ┌─────────┐  ┌──────────┐
│ Native SDK   │  │  WebView     │  │  USSD   │  │  Manual  │
│ (Telebirr)   │  │ (Chapa, etc) │  │  API    │  │Reference │
└──────┬───────┘  └──────┬───────┘  └────┬────┘  └────┬─────┘
       │                 │               │            │
       │                 │               │            │
       ▼                 ▼               ▼            ▼
┌──────────────────────────────────────────────────────┐
│           Payment Gateway Processing                 │
└──────────────────────┬───────────────────────────────┘
                       │
                       │ Success/Failure
                       ▼
┌──────────────────────────────────────────────────────┐
│           Verify Payment (Webhook/Polling)           │
└──────────────────────┬───────────────────────────────┘
                       │
                       │ Payment Verified
                       ▼
┌──────────────────────────────────────────────────────┐
│                  Create Order                        │
│         (Submit to ZMall Backend API)                │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│              Order Confirmation Screen               │
└──────────────────────────────────────────────────────┘
```

### Step-by-Step Process

#### Step 1: Navigate to Payment Screen

**Location**: `lib/checkout/checkout_screen.dart`

When user proceeds to checkout, the app navigates to `KifiyaScreen`:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => KifiyaScreen(
      price: totalAmount,
      orderPaymentId: orderPaymentId,
      orderPaymentUniqueId: orderPaymentUniqueId,
      vehicleId: selectedVehicleId,
      isCourier: false,
      onlyCashless: false,
    ),
  ),
);
```

**Required Parameters**:
- `price`: Total amount to be paid
- `orderPaymentId`: Backend-generated payment ID
- `orderPaymentUniqueId`: Unique identifier for this payment session
- `vehicleId`: (Optional) For courier services
- `isCourier`: Boolean flag for courier vs regular order
- `onlyCashless`: Boolean to restrict to digital payments only

---

#### Step 2: Fetch Available Payment Gateways

**Location**: `lib/kifiya/kifiya_screen.dart` → `_getPaymentGateway()`

The screen fetches available payment methods from the backend:

```dart
void _getPaymentGateway() async {
  setState(() {
    _loading = true;
  });

  await getPaymentGateway();

  if (paymentResponse != null && paymentResponse['success']) {
    // Payment gateways loaded successfully
    setState(() {
      _loading = false;
    });
  }
}
```

**API Call**:
```dart
Future<dynamic> getPaymentGateway() async {
  var url = "${baseUrl}/api/get_payment_gateway";

  Map data = {
    "user_id": userId,
    "server_token": serverToken,
    "country_id": countryId,
  };

  http.Response response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: json.encode(data),
  );

  return json.decode(response.body);
}
```

**Response Structure**:
```json
{
  "success": true,
  "payment_gateway": [
    {
      "_id": "gateway_unique_id",
      "name": "Telebirr InApp",
      "description": "Pay using Telebirr mobile app",
      "is_active": true,
      "image_url": "https://...",
      "gateway_type": "native_sdk"
    },
    {
      "_id": "gateway_unique_id_2",
      "name": "Chapa",
      "description": "Pay with cards or mobile money",
      "is_active": true,
      "image_url": "https://...",
      "gateway_type": "webview"
    }
    // ... more gateways
  ]
}
```

---

#### Step 3: Display Payment Methods

Payment methods are displayed in a grid using `KifiyaMethodContainer` widget:

```dart
GridView.builder(
  itemCount: paymentResponse['payment_gateway'].length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  itemBuilder: (context, index) {
    return KifiyaMethodContainer(
      selected: kifiyaMethod == index,
      title: paymentResponse['payment_gateway'][index]['name'],
      imagePath: getPaymentImage(
        paymentResponse['payment_gateway'][index]['name']
      ),
      press: () {
        setState(() {
          kifiyaMethod = index; // Select this payment method
        });
      },
    );
  },
)
```

---

#### Step 4: User Selects Payment Method

When a payment method is tapped:

1. **Update Selection State**:
   ```dart
   setState(() {
     kifiyaMethod = index;
   });
   ```

2. **Visual Feedback**: Border color changes to indicate selection
   ```dart
   border: Border.all(
     width: 2,
     color: selected ? kSecondaryColor : kWhiteColor,
   )
   ```

---

#### Step 5: Verify Stock Availability (for e-commerce orders)

**Location**: `lib/kifiya/kifiya_screen.dart` → Stock verification

Before processing payment, the app verifies that all items are still in stock:

```dart
void _checkStockBeforePayment() async {
  var stockResponse = await checkItemStock(
    storeId: cart.storeId,
    items: cart.items,
  );

  if (stockResponse['success']) {
    // All items in stock, proceed to payment
    _initiatePayment();
  } else {
    // Show out-of-stock items
    Service.showMessage(
      context: context,
      title: "Some items are out of stock",
      error: true,
    );
  }
}
```

---

#### Step 6: Generate Trace Number

**Trace Number Format**: `{random_uuid}_{orderPaymentUniqueId}`

```dart
String uuid = RandomDigits.getRandomDigits(10); // e.g., "1234567890"
String traceNo = "${uuid}_${widget.orderPaymentUniqueId}";
// Result: "1234567890_ORD_20231215_ABC123"
```

This trace number is used to track the payment across all systems.

---

#### Step 7: Initialize Payment

Different payment methods use different initialization patterns:

##### **Pattern A: Native SDK (Telebirr InApp)**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TelebirrInApp(
      amount: widget.price,
      phone: userData['user']['phone'],
      traceNo: traceNo,
      context: context,
    ),
  ),
).then((paymentResult) {
  if (paymentResult != null && paymentResult['code'] == 0) {
    // Payment successful, create order
    _createOrder();
  }
});
```

##### **Pattern B: WebView (Chapa, EthSwitch, etc.)**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChapaScreen(
      url: "$BASE_URL/api/chapa/generatepaymenturl",
      hisab: widget.price,
      traceNo: traceNo,
      phone: userData['user']['phone'],
      orderPaymentId: widget.orderPaymentId,
    ),
  ),
);
```

##### **Pattern C: USSD/API (Telebirr USSD)**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TelebirrUssd(
      url: "https://pgw.shekla.app/telebirrUssd/generate",
      hisab: widget.price,
      traceNo: traceNo,
      phone: userData['user']['phone'],
      orderPaymentId: widget.orderPaymentId,
      userId: userData['user']['_id'],
      serverToken: userData['user']['server_token'],
    ),
  ),
);
```

##### **Pattern D: Manual Reference (Telebirr Reference)**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => KifiyaVerification(
      hisab: widget.price,
      phone: userData['user']['phone'],
      traceNo: traceNo,
      orderPaymentId: widget.orderPaymentId,
    ),
  ),
).then((verified) {
  if (verified == true) {
    _createOrder();
  }
});
```

---

#### Step 8: Payment Processing (Gateway-Specific)

See [Individual Payment Gateway Implementations](#individual-payment-gateway-implementations) for detailed flows.

---

#### Step 9: Payment Verification

Two verification patterns:

##### **Pattern A: Immediate Response (SDK/WebView)**
- Payment result returned when user returns from gateway
- No additional verification needed

##### **Pattern B: Polling Verification (USSD/Reference)**

```dart
Future<dynamic> verifyPayment() async {
  var url = "${baseUrl}/admin/check_paid_order";

  Map data = {
    "user_id": userId,
    "server_token": serverToken,
    "order_payment_id": orderPaymentId,
  };

  http.Response response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: json.encode(data),
  );

  var result = json.decode(response.body);

  if (result['success']) {
    return true; // Payment verified
  } else {
    // Poll again after 2 seconds
    await Future.delayed(Duration(seconds: 2));
    return verifyPayment();
  }
}
```

---

#### Step 10: Create Order

Once payment is verified, create the order:

```dart
void _createOrder() async {
  var url = "${baseUrl}/api/user/create_order";

  Map data = {
    "user_id": userId,
    "server_token": serverToken,
    "order_payment_id": orderPaymentId,
    "cart": cart.toJson(),
    "delivery_address": selectedAddress,
    "delivery_time": deliveryTime,
    "payment_gateway_id": paymentResponse['payment_gateway'][kifiyaMethod]['_id'],
  };

  http.Response response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: json.encode(data),
  );

  var result = json.decode(response.body);

  if (result['success']) {
    // Navigate to order confirmation
    Navigator.pushReplacementNamed(context, '/order-success');
  }
}
```

---

## Payment Gateway Integration Patterns

### Pattern 1: Native SDK Integration (Platform Channels) /Not needed for website

**Used by**: Telebirr InApp

**File**: `lib/kifiya/components/telebirr_inapp.dart`

**How it works**:
1. Flutter calls native Android/iOS code via MethodChannel
2. Native code invokes Telebirr SDK
3. SDK handles payment UI and processing
4. Result returned to Flutter via callback

**Implementation**:

```dart
class TelebirrInApp extends StatefulWidget {
  final double amount;
  final String phone;
  final String traceNo;

  @override
  _TelebirrInAppState createState() => _TelebirrInAppState();
}

class _TelebirrInAppState extends State<TelebirrInApp> {
  static const MethodChannel _channel = MethodChannel('telebirrInAppSdkChannel');

  @override
  void initState() {
    super.initState();
    getRreceiveCode(); // Step 1: Get receive code from backend
  }

  // Step 1: Get receive code from payment aggregator
  Future<dynamic> getRreceiveCode() async {
    var url = "https://pgw.shekla.app/telebirrInapp/create_order";

    Map data = {
      "traceNo": widget.traceNo,
      "phone": widget.phone,
      "amount": "${widget.amount}",
      "description": "ZMall_Telebirr_InApp",
      "isInapp": true,
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    var responseData = json.decode(response.body);

    if (responseData['createOrderResult']['result'] == 'success') {
      // Step 2: Call native SDK with receive code
      Platform.isIOS
        ? placeOrderIOS(
            receiveCode: responseData['createOrderResult']['biz_content']['receiveCode'],
            appId: responseData["appId"],
            shortCode: responseData["shortCode"],
          )
        : placeOrder(
            receiveCode: responseData['createOrderResult']['biz_content']['receiveCode'],
            appId: responseData["appId"],
            shortCode: responseData["shortCode"],
          );
    }
  }

  // Step 2: Invoke native SDK (Android)
  Future<dynamic> placeOrder({
    required String receiveCode,
    required String appId,
    required String shortCode,
  }) async {
    final Map<String, dynamic> arguments = {
      'receiveCode': receiveCode,
      'appId': appId,
      'shortCode': shortCode,
    };

    final response = await _channel.invokeMethod('placeOrder', arguments);

    if (response.isNotEmpty) {
      final int code = int.parse(response['code'].toString());

      if (code == 0) {
        // Step 3: Verify payment on backend
        var confirmPaymentResponse = await confirmPayment(
          code: code,
          status: response['status'].toString(),
          traceNo: widget.traceNo,
          message: response['errMsg'].toString(),
        );

        if (confirmPaymentResponse != null && confirmPaymentResponse["success"]) {
          // Payment successful
          _handlePaymentResponse(code: 0);
          Navigator.pop(context, {"code": 0, "traceNo": widget.traceNo});
        }
      } else {
        // Payment failed
        _handlePaymentResponse(code: code);
        Navigator.pop(context, false);
      }
    }
  }

  // Step 3: Confirm payment with backend
  Future<dynamic> confirmPayment({
    required int code,
    required String traceNo,
    required String status,
    required String message,
  }) async {
    var url = "https://pgw.shekla.app/telebirrInapp/in_app_call_back";

    Map data = {
      "code": code,
      "status": status,
      "traceNo": traceNo,
      "message": message,
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    return json.decode(response.body);
  }

  // Handle different response codes
  void _handlePaymentResponse({required int code}) {
    String message;
    bool isError = false;

    switch (code) {
      case 0:
        message = "✅ Payment successful!";
        isError = false;
        break;
      case -1:
        message = "❌ Unknown error occurred.";
        isError = true;
        break;
      case -2:
        message = "⚠️ Invalid parameters provided.";
        isError = true;
        break;
      case -3:
        message = "⚠️ Payment cancelled by user.";
        isError = true;
        break;
      case -10:
        message = "⚠️ Telebirr app not installed.";
        isError = true;
        break;
      case -11:
        message = "⚠️ Telebirr version not supported.";
        isError = true;
        break;
      default:
        message = "❌ Unknown error.";
        isError = true;
    }

    Service.showMessage(
      context: context,
      title: message,
      error: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("TeleBirr InApp")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/payment/telebirr.png", height: 200),
            SizedBox(height: 20),
            SpinKitPouringHourGlassRefined(color: kGreyColor),
            SizedBox(height: 10),
            Text("Waiting for payment confirmation..."),
          ],
        ),
      ),
    );
  }
}
```

### Pattern 2: WebView Integration

**Used by**: Chapa, EthSwitch, Addis Pay, Amole, SantimPay, StarPay, YagoutPay, Etta Card, CyberSource, Event Santim

**File**: `lib/kifiya/components/chapa_screen.dart` (example)

**How it works**:
1. Backend generates a payment URL
2. Flutter opens URL in InAppWebView
3. User completes payment in web interface
4. Gateway redirects to callback URL
5. Backend webhook confirms payment
6. User returns to app

**Implementation**:

```dart
class ChapaScreen extends StatefulWidget {
  final String url;          // Backend URL to initiate payment
  final double hisab;        // Amount to pay
  final String phone;        // User phone number
  final String traceNo;      // Unique transaction ID
  final String orderPaymentId;

  @override
  _ChapaScreenState createState() => _ChapaScreenState();
}

class _ChapaScreenState extends State<ChapaScreen> {
  bool _loading = false;
  String initUrl = "";

  InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    clearCache: true,
    useShouldOverrideUrlLoading: true,
    useHybridComposition: true, // Android
    allowsInlineMediaPlayback: true, // iOS
  );

  @override
  void initState() {
    super.initState();
    _initiateUrl(); // Step 1: Get payment URL from backend
  }

  // Step 1: Get payment URL
  void _initiateUrl() async {
    var data = await initiateUrl();

    if (data != null && data['success']) {
      Service.showMessage(
        context: context,
        title: "Invoice initiated successfully. Loading...",
        error: false,
      );

      setState(() {
        initUrl = data['data']['data']['checkout_url'];
      });
    }
  }

  // Call backend to generate payment URL
  Future<dynamic> initiateUrl() async {
    setState(() {
      _loading = true;
    });

    var url = widget.url; // e.g., "$BASE_URL/api/chapa/generatepaymenturl"

    Map data = {
      "id": widget.traceNo,
      "amount": widget.hisab,
      "customization": {
        "title": "ZMall Delivery Payment",
        "description": "Order Payment to ZMall Delivery",
        "logo": null,
      },
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    ).timeout(Duration(seconds: 10));

    setState(() {
      _loading = false;
    });

    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chapa Payment")),
      body: SafeArea(
        child: _loading
          ? Center(child: CircularProgressIndicator())
          : InAppWebView(
              initialSettings: settings,
              initialUrlRequest: URLRequest(url: WebUri(initUrl)),
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW;
              },
            ),
      ),
    );
  }
}
```

**Backend Endpoint** (`/api/chapa/generatepaymenturl`):

```javascript
// Node.js/Express example
app.post('/api/chapa/generatepaymenturl', async (req, res) => {
  const { id, amount, customization } = req.body;

  try {
    // Call Chapa API to initialize payment
    const chapaResponse = await axios.post('https://api.chapa.co/v1/transaction/initialize', {
      amount: amount,
      currency: 'ETB',
      tx_ref: id, // Our trace number
      callback_url: `${process.env.BASE_URL}/api/chapa/callback`,
      return_url: `${process.env.BASE_URL}/payment-success`,
      customization: customization,
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.CHAPA_SECRET_KEY}`,
        'Content-Type': 'application/json',
      }
    });

    res.json({
      success: true,
      data: chapaResponse.data,
    });
  } catch (error) {
    res.json({
      success: false,
      message: error.message,
    });
  }
});

// Chapa webhook endpoint
app.post('/api/chapa/callback', async (req, res) => {
  const { tx_ref, status } = req.body;

  if (status === 'success') {
    // Update order payment status in database
    await OrderPayment.updateOne(
      { trace_no: tx_ref },
      { is_paid: true, payment_verified_at: new Date() }
    );
  }

  res.json({ success: true });
});
```

---

### Pattern 3: USSD/API Integration with Polling

**Used by**: Telebirr USSD, CBE USSD, Momo USSD

**File**: `lib/kifiya/components/telebirr_ussd.dart`

**How it works**:
1. App calls API to initiate USSD push
2. Gateway sends USSD prompt to user's phone
3. User completes payment via USSD menu
4. App polls backend every 2 seconds to check if payment received
5. When payment confirmed, proceed to create order

**Implementation**:

```dart
class TelebirrUssd extends StatefulWidget {
  final String url;
  final double hisab;
  final String phone;
  final String traceNo;
  final String orderPaymentId;
  final String userId;
  final String serverToken;

  @override
  _TelebirrUssdState createState() => _TelebirrUssdState();
}

class _TelebirrUssdState extends State<TelebirrUssd> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initTelebirr(); // Step 1: Initialize USSD payment
  }

  // Step 1: Initialize USSD payment
  void _initTelebirr() async {
    var data = await initTelebirr();

    if (data != null && data['result']['success']) {
      Service.showMessage(
        context: context,
        title: "${data['result']['message']}. Waiting for payment...",
        error: false,
      );

      // Step 2: Start polling for payment verification
      _verifyPayment();
    }
  }

  // Call USSD API to send payment prompt to user's phone
  Future<dynamic> initTelebirr() async {
    setState(() {
      _loading = true;
    });

    var url = widget.url; // "https://pgw.shekla.app/telebirrUssd/generate"

    Map data = {
      "traceNo": widget.traceNo,
      "amount": widget.hisab,
      "phone": "251${widget.phone}",
      "payerId": "22",
      "appId": "1234",
      "apiKey": "90e503b019a811ef9bc8005056a4ed36",
      "zmall": true,
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    ).timeout(Duration(seconds: 10));

    setState(() {
      _loading = false;
    });

    return json.decode(response.body);
  }

  // Step 2: Poll backend to check if payment received
  void _verifyPayment() async {
    var data = await verifyPayment();

    if (data != null && data['success']) {
      // Payment verified, return to previous screen
      Navigator.pop(context, true);
    } else {
      // Payment not yet received, poll again after 2 seconds
      await Future.delayed(Duration(seconds: 2));
      _verifyPayment(); // Recursive polling
    }
  }

  // Check if payment has been received on backend
  Future<dynamic> verifyPayment() async {
    var url = "${baseUrl}/admin/check_paid_order";

    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "order_payment_id": widget.orderPaymentId,
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    ).timeout(Duration(seconds: 10));

    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Telebirr USSD")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/payment/telebirr.png", height: 200),
            SizedBox(height: 20),
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
    );
  }
}
```

**Backend Polling Endpoint** (`/admin/check_paid_order`):

```javascript
app.post('/admin/check_paid_order', async (req, res) => {
  const { user_id, server_token, order_payment_id } = req.body;

  // Verify user session
  const user = await User.findOne({ _id: user_id, server_token: server_token });
  if (!user) {
    return res.json({ success: false, error: "Invalid session" });
  }

  // Check if payment has been received
  const orderPayment = await OrderPayment.findById(order_payment_id);

  if (orderPayment && orderPayment.is_paid) {
    return res.json({
      success: true,
      message: "Payment verified"
    });
  } else {
    return res.json({
      success: false,
      error: "Payment not yet received"
    });
  }
});
```

---

### Pattern 4: Manual Reference Number Verification

**Used by**: Telebirr Reference

**File**: `lib/kifiya/kifiya_verification.dart`

**How it works**:
1. App generates a reference number and posts it to Telebirr
2. User opens Telebirr app manually
3. User navigates to "Utility Payment" → "ZMALL"
4. User enters reference number and completes payment
5. User returns to app and clicks "Verify"
6. App checks backend if payment received

**Implementation**:

```dart
class KifiyaVerification extends StatefulWidget {
  final double hisab;
  final String phone;
  final String traceNo;
  final String orderPaymentId;

  @override
  _KifiyaVerificationState createState() => _KifiyaVerificationState();
}

class _KifiyaVerificationState extends State<KifiyaVerification> {
  bool copied = false;
  bool _loading = false;
  var userData;

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
      _telebirrPostBill(); // Step 1: Post bill to Telebirr
    }
  }

  // Step 1: Post bill to Telebirr
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
      "code": "0005",
      "trace_no": widget.traceNo,
      "amount": "${widget.hisab}",
      "appId": "1234"
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    ).timeout(Duration(seconds: 10));

    return json.decode(response.body);
  }

  // Step 2: Verify bill payment (user clicks "Verify" button)
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

    await Future.delayed(Duration(seconds: 3));

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

      Navigator.pop(context, true); // Return success
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
    var url = "${baseUrl}/admin/check_paid_order";

    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
      "order_payment_id": widget.orderPaymentId
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    ).timeout(Duration(seconds: 10));

    return json.decode(response.body);
  }

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
                    "Please use the bottom reference number to complete your payment using Tele Birr App or USSD.",
                    style: TextStyle(color: kGreyColor),
                  ),
                  SizedBox(height: 10),

                  // Reference Number Display
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

                  // Copy Button
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

            // Verify Button
            CustomButton(
              title: "Verify",
              press: _telebirrVerifyBill,
              color: copied ? kSecondaryColor : kGreyColor,
            ),

            SizedBox(height: 20),

            // Instructions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "How to pay with Telebirr?",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("1. Copy the reference number above ☝🏾"),
                  SizedBox(height: 5),
                  Text("2. Open Telebirr App and Login"),
                  SizedBox(height: 5),
                  Text("3. Press \"Pay with Telebirr\""),
                  SizedBox(height: 5),
                  Text("4. Press \"Utility Payment\""),
                  SizedBox(height: 5),
                  Text("5. Press \"ZMALL\""),
                  SizedBox(height: 5),
                  Text("6. Paste the reference number and proceed with payment"),
                  SizedBox(height: 5),
                  Text("7. Press Verify to complete verification and create order."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Individual Payment Gateway Implementations

### 1. Telebirr InApp (Native SDK) /Not needed for Website

**File**: `lib/kifiya/components/telebirr_inapp.dart`

**Type**: Native SDK Integration

**Flow**:
1. Call backend to get receive code
2. Invoke native Telebirr SDK via MethodChannel
3. SDK opens Telebirr app for payment
4. User completes payment in Telebirr
5. SDK returns result to Flutter
6. Confirm payment with backend webhook
7. Return result to KifiyaScreen

**Response Codes**:
- `0`: Success
- `-1`: Unknown error
- `-2`: Invalid parameters
- `-3`: Cancelled by user
- `-10`: Telebirr app not installed
- `-11`: Telebirr version not supported
- `-99`: Payment not confirmed

**URLs**:
- Create Order: `https://pgw.shekla.app/telebirrInapp/create_order`
- Callback: `https://pgw.shekla.app/telebirrInapp/in_app_call_back`

---

### 2. Telebirr USSD

**File**: `lib/kifiya/components/telebirr_ussd.dart`

**Type**: USSD API with Polling

**Flow**:
1. Call API to initiate USSD push
2. User receives USSD prompt on phone
3. User completes payment via USSD menu
4. App polls backend every 2 seconds
5. When payment confirmed, return success

**URLs**:
- Generate USSD: `https://pgw.shekla.app/telebirrUssd/generate`
- Verify: `${baseUrl}/admin/check_paid_order`

**Polling Interval**: 2 seconds

---

### 3. Telebirr Reference (Manual)

**File**: `lib/kifiya/kifiya_verification.dart`

**Type**: Manual Reference Number

**Flow**:
1. Post bill to Telebirr API
2. Display reference number to user
3. User manually pays via Telebirr app
4. User clicks "Verify" button
5. App checks backend if payment received

**URLs**:
- Post Bill: `https://pgw.shekla.app/telebirr/post_bill`
- Verify: `${baseUrl}/admin/check_paid_order`

**User Steps**:
1. Copy reference number
2. Open Telebirr app
3. Go to "Pay with Telebirr" → "Utility Payment" → "ZMALL"
4. Paste reference number
5. Complete payment
6. Return to app and click "Verify"

---

### 4. Chapa (Payment Aggregator)

**File**: `lib/kifiya/components/chapa_screen.dart`

**Type**: WebView Integration

**Flow**:
1. Call backend to generate Chapa payment URL
2. Open URL in InAppWebView
3. User selects payment method (cards, mobile money, etc.)
4. User completes payment in web interface
5. Chapa sends webhook to backend
6. User returns to app

**URLs**:
- Generate URL: `${baseUrl}/api/chapa/generatepaymenturl`
- Chapa API: `https://api.chapa.co/v1/transaction/initialize`

**Supported Payment Methods via Chapa**:
- Credit/Debit Cards
- Telebirr
- CBE Birr
- M-Pesa
- Awash Birr

---

### 5. EthSwitch (Ethiopian Banking Network)

**File**: `lib/kifiya/components/ethswitch_screen.dart`

**Type**: WebView Integration

**Flow**:
1. Call backend to initiate EthSwitch payment
2. Backend returns form URL
3. Open form URL in InAppWebView
4. User enters card details
5. User completes payment
6. EthSwitch sends webhook to backend

**URLs**:
- Initiate: `https://pgw.shekla.app/ethioSwitch/initiate`

**Important**: Amount must be sent in **cents** (multiply by 100)

```dart
Map data = {
  "trace_no": traceNo,
  "amount": hisab * 100, // Convert to cents
  "description": "ZMall Delivery Order Payment",
  "issued_to": "0${phone}",
  "appId": "1234",
};
```

---

### 6. Addis Pay

**File**: `lib/kifiya/components/addis_pay.dart`

**Type**: WebView Integration

**Similar to Chapa implementation**

---

### 7. Amole

**File**: `lib/kifiya/components/amole_screen.dart`

**Type**: WebView Integration

**Similar to Chapa implementation**

---

### 8. CBE USSD

**File**: `lib/kifiya/components/cbe_ussd.dart`

**Type**: USSD API with Polling

**Similar to Telebirr USSD implementation**

---

### 9. Dashen MasterCard

**File**: `lib/kifiya/components/dashen_master_card.dart`

**Type**: WebView Integration

**Similar to EthSwitch implementation**

---

### 10. SantimPay

**File**: `lib/kifiya/components/santimpay_screen.dart`

**Type**: WebView Integration

**Similar to Chapa implementation**

---

### 11. StarPay

**File**: `lib/kifiya/components/starpay_screen.dart`

**Type**: WebView Integration

**Similar to Chapa implementation**

---

### 12. YagoutPay

**File**: `lib/kifiya/components/yagoutpay.dart`

**Type**: WebView Integration

**Similar to Chapa implementation**

---

### 13. Etta Card

**File**: `lib/kifiya/components/etta_card_screen.dart`

**Type**: WebView Integration

**Similar to EthSwitch implementation**

---

### 14. CyberSource (International Cards)

**File**: `lib/kifiya/components/cyber_source.dart`

**Type**: WebView Integration

**Similar to Chapa implementation**

**Supports**: Visa, MasterCard, American Express (international)

---

### 15. Event Santim

**File**: `lib/kifiya/components/event_santim.dart`

**Type**: WebView Integration

**Used for**: Event ticket payments

---

### 16. Momo USSD (South Sudan)

**File**: `lib/kifiya/components/momo_ussd.dart`

**Type**: USSD API with Polling

**Similar to Telebirr USSD implementation**

**Region**: South Sudan only

---

### 17. Wallet (Borsa)

**Type**: Internal Balance

**Flow**:
1. Check if user has sufficient wallet balance
2. Deduct amount from wallet
3. Create order immediately
4. No external gateway involved

**Implementation** (in `kifiya_screen.dart`):

```dart
void _useWalletBalance() async {
  // Check wallet balance
  var walletData = await getUserWallet();

  if (walletData['wallet']['balance'] >= widget.price) {
    // Sufficient balance
    var deductResult = await deductFromWallet(
      amount: widget.price,
      orderId: widget.orderPaymentId,
    );

    if (deductResult['success']) {
      // Wallet payment successful
      _createOrder();
    }
  } else {
    // Insufficient balance
    Service.showMessage(
      context: context,
      title: "Insufficient wallet balance. Please top up.",
      error: true,
    );
  }
}
```

---

### 18. Cash (Cash on Delivery)

**Type**: No integration

**Flow**:
1. User selects "Cash"
2. Order is created with `payment_type: "cash"`
3. Payment collected upon delivery
4. Delivery person confirms payment in their app

---

## API Endpoints

### 1. Get Payment Gateways

**Endpoint**: `GET/POST ${baseUrl}/api/get_payment_gateway`

**Request**:
```json
{
  "user_id": "user_unique_id",
  "server_token": "user_session_token",
  "country_id": "5b3f76f2022985030cd3a437"
}
```

**Response**:
```json
{
  "success": true,
  "payment_gateway": [
    {
      "_id": "gateway_id_1",
      "name": "Telebirr InApp",
      "description": "Pay using Telebirr mobile app",
      "is_active": true,
      "gateway_type": "native_sdk",
      "image_url": "https://cdn.zmall.et/payment/telebirr.png"
    },
    {
      "_id": "gateway_id_2",
      "name": "Chapa",
      "description": "Pay with cards or mobile money",
      "is_active": true,
      "gateway_type": "webview",
      "image_url": "https://cdn.zmall.et/payment/chapa.png"
    }
  ]
}
```

---

### 2. Pay Order Payment (Register Payment Method)

**Endpoint**: `POST ${baseUrl}/api/user/pay_order_payment`

**Request**:
```json
{
  "user_id": "user_unique_id",
  "server_token": "user_session_token",
  "order_payment_id": "payment_session_id",
  "payment_gateway_id": "selected_gateway_id",
  "otp": "123456"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Payment method registered successfully"
}
```

**Note**: This doesn't process payment, it just registers which payment method the user will use.

---

### 3. Check Paid Order (Verify Payment)

**Endpoint**: `POST ${baseUrl}/admin/check_paid_order`

**Request**:
```json
{
  "user_id": "user_unique_id",
  "server_token": "user_session_token",
  "order_payment_id": "payment_session_id"
}
```

**Response** (Success):
```json
{
  "success": true,
  "message": "Payment verified",
  "payment_details": {
    "amount": 1250.00,
    "currency": "ETB",
    "paid_at": "2023-12-15T10:30:00Z",
    "gateway": "Telebirr",
    "trace_no": "1234567890_ORD_123"
  }
}
```

**Response** (Not Paid):
```json
{
  "success": false,
  "error": "Payment not yet received"
}
```

---

### 4. Create Order

**Endpoint**: `POST ${baseUrl}/api/user/create_order`

**Request**:
```json
{
  "user_id": "user_unique_id",
  "server_token": "user_session_token",
  "order_payment_id": "payment_session_id",
  "cart": {
    "store_id": "store_id",
    "items": [
      {
        "item_id": "item_id_1",
        "quantity": 2,
        "price": 500.00,
        "specifications": []
      }
    ]
  },
  "delivery_address": {
    "lat": 9.0054,
    "lng": 38.7636,
    "address": "Bole, Addis Ababa"
  },
  "delivery_time": "asap",
  "payment_gateway_id": "selected_gateway_id"
}
```

**Response**:
```json
{
  "success": true,
  "order": {
    "_id": "order_id",
    "unique_id": "ORD_20231215_123",
    "total": 1250.00,
    "delivery_fee": 50.00,
    "status": "pending"
  }
}
```

---

### 5. Chapa Generate Payment URL

**Endpoint**: `POST ${baseUrl}/api/chapa/generatepaymenturl`

**Request**:
```json
{
  "id": "1234567890_ORD_123",
  "amount": 1250.00,
  "customization": {
    "title": "ZMall Delivery Payment",
    "description": "Order Payment to ZMall Delivery",
    "logo": null
  }
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "data": {
      "checkout_url": "https://checkout.chapa.co/checkout/payment/abcd1234..."
    }
  }
}
```

---

### 6. EthSwitch Initiate

**Endpoint**: `POST https://pgw.shekla.app/ethioSwitch/initiate`

**Request**:
```json
{
  "trace_no": "1234567890_ORD_123",
  "amount": 125000,
  "description": "ZMall Delivery Order Payment",
  "issued_to": "0912345678",
  "appId": "1234"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Payment form generated successfully",
  "data": {
    "formUrl": "https://payment.ethswitch.et/form/abcd1234..."
  }
}
```

---

### 7. Telebirr InApp Create Order

**Endpoint**: `POST https://pgw.shekla.app/telebirrInapp/create_order`

**Request**:
```json
{
  "traceNo": "1234567890_ORD_123",
  "phone": "0912345678",
  "amount": "1250.00",
  "description": "ZMall_Telebirr_InApp",
  "isInapp": true
}
```

**Response**:
```json
{
  "createOrderResult": {
    "result": "success",
    "biz_content": {
      "receiveCode": "RCVCODE123456..."
    }
  },
  "appId": "com.zmall.delivery",
  "shortCode": "ZMALL"
}
```

---

### 8. Telebirr InApp Callback

**Endpoint**: `POST https://pgw.shekla.app/telebirrInapp/in_app_call_back`

**Request**:
```json
{
  "code": 0,
  "status": "success",
  "traceNo": "1234567890_ORD_123",
  "message": "Payment successful"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Payment confirmed"
}
```

---

### 9. Telebirr USSD Generate

**Endpoint**: `POST https://pgw.shekla.app/telebirrUssd/generate`

**Request**:
```json
{
  "traceNo": "1234567890_ORD_123",
  "amount": 1250.00,
  "phone": "251912345678",
  "payerId": "22",
  "appId": "1234",
  "apiKey": "90e503b019a811ef9bc8005056a4ed36",
  "zmall": true
}
```

**Response**:
```json
{
  "result": {
    "success": true,
    "message": "USSD prompt sent successfully"
  }
}
```

---

### 10. Telebirr Post Bill

**Endpoint**: `POST https://pgw.shekla.app/telebirr/post_bill`

**Request**:
```json
{
  "phone": "251912345678",
  "description": "ZMall Delivery Order Payment",
  "code": "0005",
  "trace_no": "1234567890_ORD_123",
  "amount": "1250.00",
  "appId": "1234"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Bill posted successfully"
}
```

---

## Data Models

### OrderPayment Model

```dart
class OrderPayment {
  String? id;
  String? uniqueId;
  String? userId;
  String? storeId;
  double? amount;
  String? currency;
  String? paymentGatewayId;
  String? traceNo;
  bool? isPaid;
  DateTime? paidAt;
  DateTime? createdAt;

  OrderPayment({
    this.id,
    this.uniqueId,
    this.userId,
    this.storeId,
    this.amount,
    this.currency,
    this.paymentGatewayId,
    this.traceNo,
    this.isPaid,
    this.paidAt,
    this.createdAt,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['_id'],
      uniqueId: json['unique_id'],
      userId: json['user_id'],
      storeId: json['store_id'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      paymentGatewayId: json['payment_gateway_id'],
      traceNo: json['trace_no'],
      isPaid: json['is_paid'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'unique_id': uniqueId,
      'user_id': userId,
      'store_id': storeId,
      'amount': amount,
      'currency': currency,
      'payment_gateway_id': paymentGatewayId,
      'trace_no': traceNo,
      'is_paid': isPaid,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
```

### PaymentGateway Model

```dart
class PaymentGateway {
  String? id;
  String? name;
  String? description;
  String? gatewayType;
  bool? isActive;
  String? imageUrl;

  PaymentGateway({
    this.id,
    this.name,
    this.description,
    this.gatewayType,
    this.isActive,
    this.imageUrl,
  });

  factory PaymentGateway.fromJson(Map<String, dynamic> json) {
    return PaymentGateway(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      gatewayType: json['gateway_type'],
      isActive: json['is_active'],
      imageUrl: json['image_url'],
    );
  }
}
```

---

## Error Handling

### Common Error Codes

```dart
Map<String, String> errorCodes = {
  "100": "Registration request already sent",
  "101": "Registration request not found",
  "102": "You cannot place order",
  "103": "Store is closed",
  "104": "No item in cart",
  "105": "User not found",
  "106": "Invalid parameters",
  "107": "Session expired",
  "108": "Payment already processed",
  "109": "Payment verification failed",
  "110": "Insufficient wallet balance",
  "999": "Session expired. Please login again.",
};
```

### Error Handling Pattern

```dart
if (response['success']) {
  // Success
  proceedToNextStep();
} else {
  // Error
  String errorMessage = errorCodes['${response['error_code']}'] ??
                        response['message'] ??
                        "Something went wrong";

  Service.showMessage(
    context: context,
    title: errorMessage,
    error: true,
  );

  // Handle session expiration
  if (response['error_code'] == 999) {
    await Service.saveBool('logged', false);
    await Service.remove('user');
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }
}
```

### Network Error Handling

```dart
try {
  http.Response response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: body,
  ).timeout(
    Duration(seconds: 10),
    onTimeout: () {
      throw TimeoutException("The connection has timed out!");
    },
  );

  return json.decode(response.body);
} catch (e) {
  Service.showMessage(
    context: context,
    title: "Something went wrong. Please check your internet connection!",
    error: true,
  );
  return null;
}
```

---

## Security Considerations

### 1. Secure Storage

Sensitive data is stored using FlutterSecureStorage:

```dart
static const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
```

### 2. Server Tokens

All authenticated API calls require:
- `user_id`
- `server_token` (session token)

```dart
Map data = {
  "user_id": userData['user']['_id'],
  "server_token": userData['user']['server_token'],
  // ... other data
};
```

### 3. Trace Number Generation

Unique trace numbers prevent duplicate transactions:

```dart
String uuid = RandomDigits.getRandomDigits(10);
String traceNo = "${uuid}_${orderPaymentUniqueId}";
```

### 4. WebView Security

```dart
InAppWebViewSettings settings = InAppWebViewSettings(
  javaScriptEnabled: true,      // Required for payment processing
  clearCache: true,             // Clear cache for security
  useShouldOverrideUrlLoading: true,
);
```

### 5. Payment Verification

Always verify payment on backend before creating order:

```dart
// Mobile app just collects payment method
// Backend verifies actual payment receipt via webhooks
// Only create order after backend confirms payment
```

### 6. Webhook Validation

Backend should validate webhook signatures:

```javascript
// Chapa webhook validation example
const validateChapaWebhook = (req) => {
  const signature = req.headers['chapa-signature'];
  const payload = JSON.stringify(req.body);
  const hash = crypto
    .createHmac('sha256', process.env.CHAPA_WEBHOOK_SECRET)
    .update(payload)
    .digest('hex');

  return hash === signature;
};
```

---

## Web Implementation Guide

### Overview

For the web version, you'll need to adapt the mobile patterns to work in a browser environment.

---

### Architecture Differences

| Aspect | Mobile (Flutter) | Web (React/Vue/etc.) |
|--------|------------------|----------------------|
| **Native SDK** | Platform Channels | Not possible - use redirect URLs |
| **WebView** | InAppWebView | iframes or popup windows |
| **Polling** | Background timers | Same approach works |
| **Storage** | SharedPreferences | localStorage / sessionStorage |
| **Secure Storage** | FlutterSecureStorage | Not truly secure - use httpOnly cookies |

---

### Pattern Adaptations for Web

#### Pattern 1: Native SDK → Redirect URLs

Since native SDKs don't work on web, use redirect-based flows:

**Mobile**:
```dart
// Opens Telebirr app via SDK
TelebirrSDK.pay(receiveCode);
```

**Web**:
```javascript
// Redirect to Telebirr web payment page
window.location.href = `https://telebirr.et/pay?code=${receiveCode}&return_url=${encodeURIComponent(window.location.origin + '/payment-callback')}`;
```

**Implementation**:

```javascript
// PaymentService.js
class PaymentService {
  static async initiateTelebirrPayment(amount, traceNo, phone) {
    // Step 1: Get receive code from backend
    const response = await fetch('/api/telebirr/create-order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount,
        traceNo,
        phone,
      }),
    });

    const data = await response.json();

    if (data.success) {
      const returnUrl = `${window.location.origin}/payment-callback`;
      const paymentUrl = `https://telebirr.et/pay?code=${data.receiveCode}&return=${encodeURIComponent(returnUrl)}`;

      // Step 2: Redirect to payment page
      window.location.href = paymentUrl;
    }
  }
}

// PaymentCallback component
function PaymentCallback() {
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const status = params.get('status');
    const traceNo = params.get('tx_ref');

    if (status === 'success') {
      // Verify payment with backend
      verifyPayment(traceNo);
    } else {
      // Payment failed
      navigate('/checkout?error=payment_failed');
    }
  }, []);

  return <div>Processing payment...</div>;
}
```

---

#### Pattern 2: WebView → iframes or Popup Windows

**Option A: iframe** (Better UX, same page)

```javascript
function ChapaPayment({ amount, traceNo, onSuccess, onError }) {
  const [paymentUrl, setPaymentUrl] = useState('');

  useEffect(() => {
    // Get payment URL from backend
    fetch('/api/chapa/generate-url', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount, traceNo }),
    })
      .then(res => res.json())
      .then(data => setPaymentUrl(data.checkoutUrl));
  }, []);

  useEffect(() => {
    // Listen for payment completion messages
    const handleMessage = (event) => {
      if (event.origin !== 'https://checkout.chapa.co') return;

      if (event.data.status === 'success') {
        onSuccess(event.data);
      } else {
        onError(event.data);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  return (
    <div className="payment-modal">
      <iframe
        src={paymentUrl}
        width="100%"
        height="600px"
        frameBorder="0"
        title="Chapa Payment"
      />
    </div>
  );
}
```

**Option B: Popup Window** (Better security, separate window)

```javascript
function openPaymentWindow(paymentUrl, callback) {
  const width = 600;
  const height = 700;
  const left = (window.screen.width - width) / 2;
  const top = (window.screen.height - height) / 2;

  const popup = window.open(
    paymentUrl,
    'Payment',
    `width=${width},height=${height},left=${left},top=${top}`
  );

  // Poll for popup close or message
  const interval = setInterval(() => {
    if (popup.closed) {
      clearInterval(interval);
      callback({ status: 'cancelled' });
    }
  }, 500);

  // Listen for messages from popup
  window.addEventListener('message', (event) => {
    if (event.source === popup) {
      clearInterval(interval);
      popup.close();
      callback(event.data);
    }
  });
}
```

---

#### Pattern 3: USSD Polling → Same Approach

Polling works the same on web:

```javascript
function TelebirrUssdPayment({ amount, traceNo, phone, orderPaymentId }) {
  const [checking, setChecking] = useState(false);

  useEffect(() => {
    // Step 1: Initiate USSD payment
    initializeUssdPayment();
  }, []);

  const initializeUssdPayment = async () => {
    const response = await fetch('/api/telebirr-ussd/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount, traceNo, phone }),
    });

    const data = await response.json();

    if (data.success) {
      toast.success('USSD prompt sent to your phone. Please complete payment.');

      // Step 2: Start polling
      startPolling();
    }
  };

  const startPolling = () => {
    setChecking(true);

    const pollInterval = setInterval(async () => {
      const verified = await verifyPayment(orderPaymentId);

      if (verified) {
        clearInterval(pollInterval);
        setChecking(false);
        onPaymentSuccess();
      }
    }, 2000); // Poll every 2 seconds

    // Stop polling after 5 minutes
    setTimeout(() => {
      clearInterval(pollInterval);
      setChecking(false);
      toast.error('Payment timeout. Please try again.');
    }, 300000);
  };

  const verifyPayment = async (orderPaymentId) => {
    const response = await fetch('/api/check-payment', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ orderPaymentId }),
    });

    const data = await response.json();
    return data.success;
  };

  return (
    <div className="ussd-payment">
      <img src="/images/telebirr.png" alt="Telebirr" />
      {checking && (
        <>
          <Spinner />
          <p>Please complete payment via USSD prompt on your phone...</p>
          <p>Checking payment status...</p>
        </>
      )}
    </div>
  );
}
```

---

#### Pattern 4: Manual Reference → Same UI Flow

```javascript
function TelebirrReferencePayment({ amount, traceNo, orderPaymentId }) {
  const [copied, setCopied] = useState(false);
  const [verifying, setVerifying] = useState(false);

  useEffect(() => {
    // Post bill to Telebirr
    postBill();
  }, []);

  const postBill = async () => {
    const response = await fetch('/api/telebirr/post-bill', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount, traceNo }),
    });

    const data = await response.json();

    if (data.success) {
      toast.success('Bill posted successfully. Please pay via Telebirr app.');
    }
  };

  const copyReferenceNumber = () => {
    navigator.clipboard.writeText(traceNo);
    setCopied(true);
    toast.success('Reference number copied!');
  };

  const verifyPayment = async () => {
    if (!copied) {
      toast.error('Please copy the reference number first.');
      return;
    }

    setVerifying(true);

    const response = await fetch('/api/check-payment', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ orderPaymentId }),
    });

    const data = await response.json();
    setVerifying(false);

    if (data.success) {
      toast.success('Payment verified!');
      onPaymentSuccess();
    } else {
      toast.error('Payment not yet received. Please complete payment and try again.');
    }
  };

  return (
    <div className="reference-payment">
      <h2>Pay ብር {amount.toFixed(2)} with Tele Birr</h2>

      <div className="reference-box">
        <p>Reference Number:</p>
        <div className="reference-number">{traceNo}</div>
        <button onClick={copyReferenceNumber}>
          {copied ? '✓ Copied' : 'Copy Reference Number'}
        </button>
      </div>

      <button
        onClick={verifyPayment}
        disabled={!copied || verifying}
        className={copied ? 'btn-primary' : 'btn-disabled'}
      >
        {verifying ? 'Verifying...' : 'Verify Payment'}
      </button>

      <div className="instructions">
        <h3>How to pay with Telebirr?</h3>
        <ol>
          <li>Copy the reference number above ☝🏾</li>
          <li>Open Telebirr App and Login</li>
          <li>Press "Pay with Telebirr"</li>
          <li>Press "Utility Payment"</li>
          <li>Press "ZMALL"</li>
          <li>Paste the reference number and proceed with payment</li>
          <li>Press Verify to complete verification and create order</li>
        </ol>
      </div>
    </div>
  );
}
```

---

### Complete Web Payment Component

```javascript
// PaymentGatewaySelector.jsx
import { useState, useEffect } from 'react';

function PaymentGatewaySelector({ amount, orderPaymentId, onSuccess }) {
  const [gateways, setGateways] = useState([]);
  const [selectedGateway, setSelectedGateway] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchPaymentGateways();
  }, []);

  const fetchPaymentGateways = async () => {
    setLoading(true);

    const response = await fetch('/api/payment-gateways', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include', // Include session cookie
    });

    const data = await response.json();

    if (data.success) {
      setGateways(data.payment_gateway);
    }

    setLoading(false);
  };

  const handleProceedToPayment = () => {
    if (!selectedGateway) {
      toast.error('Please select a payment method');
      return;
    }

    const gateway = gateways[selectedGateway];

    switch (gateway.name.toLowerCase()) {
      case 'telebirr inapp':
        // Redirect to Telebirr
        initiateTelebirrPayment();
        break;

      case 'chapa':
        // Open Chapa in iframe/popup
        initiateChapaPayment();
        break;

      case 'telebirr ussd':
        // Show USSD component
        setShowUssdPayment(true);
        break;

      case 'telebirr reference':
        // Show reference component
        setShowReferencePayment(true);
        break;

      case 'ethswitch':
        // Open EthSwitch in iframe/popup
        initiateEthSwitchPayment();
        break;

      case 'wallet':
        // Deduct from wallet
        useWalletBalance();
        break;

      case 'cash':
        // Create order with cash payment
        createOrderWithCash();
        break;

      default:
        toast.error('Payment method not yet implemented for web');
    }
  };

  return (
    <div className="payment-gateway-selector">
      <h2>Select Payment Method</h2>

      {loading ? (
        <Spinner />
      ) : (
        <div className="gateway-grid">
          {gateways.map((gateway, index) => (
            <div
              key={gateway._id}
              className={`gateway-card ${selectedGateway === index ? 'selected' : ''}`}
              onClick={() => setSelectedGateway(index)}
            >
              <img
                src={getGatewayImage(gateway.name)}
                alt={gateway.name}
              />
              <p>{gateway.name}</p>
            </div>
          ))}
        </div>
      )}

      <button
        onClick={handleProceedToPayment}
        disabled={selectedGateway === null}
        className="btn-primary"
      >
        Proceed to Payment
      </button>
    </div>
  );
}

export default PaymentGatewaySelector;
```

---

### Session Management

**Mobile**:
```dart
// User session stored in SharedPreferences
var userData = await Service.read('user');
String serverToken = userData['user']['server_token'];
```

**Web**:
```javascript
// Use httpOnly cookies for security
// Session managed on backend

// Login sets cookie
app.post('/api/login', (req, res) => {
  // ... authenticate user

  res.cookie('session_token', serverToken, {
    httpOnly: true,
    secure: true, // HTTPS only
    sameSite: 'strict',
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
  });

  res.json({ success: true, user: userData });
});

// Authenticated requests automatically include cookie
fetch('/api/payment-gateways', {
  method: 'POST',
  credentials: 'include', // Important!
});
```

---

### State Management

**Recommendation**: Use Redux, Zustand, or Context API

```javascript
// paymentStore.js (Zustand example)
import create from 'zustand';

const usePaymentStore = create((set) => ({
  gateways: [],
  selectedGateway: null,
  orderPaymentId: null,
  amount: 0,
  paymentStatus: 'idle', // idle, processing, success, failed

  setGateways: (gateways) => set({ gateways }),
  setSelectedGateway: (gateway) => set({ selectedGateway: gateway }),
  setOrderPaymentId: (id) => set({ orderPaymentId: id }),
  setAmount: (amount) => set({ amount }),
  setPaymentStatus: (status) => set({ paymentStatus: status }),
}));

export default usePaymentStore;
```

---

### Error Handling

```javascript
// errorHandler.js
export const handlePaymentError = (error, toast) => {
  const errorMessages = {
    100: "Registration request already sent",
    101: "Registration request not found",
    102: "You cannot place order",
    103: "Store is closed",
    104: "No item in cart",
    105: "User not found",
    106: "Invalid parameters",
    107: "Session expired",
    108: "Payment already processed",
    109: "Payment verification failed",
    110: "Insufficient wallet balance",
    999: "Session expired. Please login again.",
  };

  const message = errorMessages[error.error_code] ||
                  error.message ||
                  "Something went wrong";

  toast.error(message);

  // Handle session expiration
  if (error.error_code === 999) {
    localStorage.removeItem('user');
    window.location.href = '/login';
  }
};
```

---

### Testing Considerations

1. **Test all payment gateways** in sandbox mode first
2. **Test polling timeouts** - ensure polling stops after reasonable time
3. **Test popup blockers** - provide fallback for blocked popups
4. **Test mobile browsers** - ensure responsive design
5. **Test webhook callbacks** - use tools like ngrok for local testing
6. **Test error scenarios** - network failures, timeouts, cancellations

---

## Testing Checklist

### Pre-Launch Testing

- [ ] All payment gateways load correctly
- [ ] Payment method selection works
- [ ] Stock verification prevents out-of-stock orders
- [ ] Trace numbers are unique
- [ ] Each payment gateway processes successfully
- [ ] Webhooks update payment status
- [ ] Polling stops after timeout
- [ ] Payment verification works
- [ ] Orders create after payment
- [ ] Error messages display correctly
- [ ] Session expiration handled
- [ ] Network errors handled gracefully
- [ ] Loading states show during processing
- [ ] User can cancel payment
- [ ] Return to app works correctly
- [ ] Wallet balance updates after payment
- [ ] Cash on delivery works
- [ ] Multi-currency support (ETB, SSP, USD)

### Security Testing

- [ ] API endpoints require authentication
- [ ] Server tokens validated
- [ ] Webhooks validate signatures
- [ ] Payment amounts match
- [ ] Duplicate payments prevented
- [ ] SQL injection prevented
- [ ] XSS attacks prevented
- [ ] CSRF tokens implemented
- [ ] HTTPS enforced
- [ ] Sensitive data encrypted

### Performance Testing

- [ ] Payment gateway list loads < 2s
- [ ] Payment initiation < 3s
- [ ] Polling doesn't block UI
- [ ] WebView loads smoothly
- [ ] No memory leaks during polling
- [ ] App handles 100+ concurrent payments

---

## Conclusion

This guide provides a comprehensive overview of ZMall's payment integration system. The mobile app uses four main patterns:

1. **Native SDK** (Telebirr InApp)
2. **WebView** (Chapa, EthSwitch, etc.)
3. **USSD/API with Polling** (Telebirr USSD, CBE USSD, Momo USSD)
4. **Manual Reference** (Telebirr Reference)

For web implementation:
- Replace Native SDK with redirect URLs
- Replace WebView with iframes or popups
- Keep polling approach
- Keep reference number approach
- Use httpOnly cookies for sessions
- Implement proper CORS and CSRF protection

**Key Takeaways**:
- Always verify payment on backend before creating order
- Use unique trace numbers to prevent duplicates
- Handle session expiration gracefully
- Provide clear error messages
- Test all payment gateways thoroughly
- Implement proper timeout handling
- Ensure webhooks are secure

**Need Help?**
- Review individual payment gateway files in `/lib/kifiya/components/`
- Check backend API documentation
- Test with sandbox credentials first
- Contact payment gateway support for integration issues

---

**Document Version**: 1.0
**Last Updated**: December 23, 2025
**Maintained By**: ZMall Engineering Team
