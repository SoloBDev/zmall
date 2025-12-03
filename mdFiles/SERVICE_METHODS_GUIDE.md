# Service Methods Implementation Guide

This document explains the reusable service methods implemented in `lib/services/service.dart` for the ZMall Flutter application.

## Table of Contents

1. [Cart Helper Methods](#cart-helper-methods)
2. [Store Helper Methods](#store-helper-methods)

---

## Cart Helper Methods

### Overview

These methods handle cart item management, preventing duplicate items and ensuring correct price calculations when adding items to the cart.

### Methods

#### 1. `isSameItem(Item existingItem, Item newItem)`

**Purpose:** Compares two cart items to determine if they are identical.

**Returns:** `bool` - `true` if items are the same, `false` otherwise

**Comparison Logic:**

- Items are considered identical if they have:
  - Same item ID
  - Same specifications (including all spec unique_ids and selected options)

**Usage Example:**

```dart
if (Service.isSameItem(existingItem, newItem)) {
  // Update quantity instead of adding duplicate
  existingItem.quantity += newItem.quantity;
} else {
  // Add as new item
  cart.items.add(newItem);
}
```

**Location in Service:** Lines 341-393

---

#### 2. `addOrMergeCartItem(Cart cart, Item newItem)`

**Purpose:** Intelligently adds items to cart by merging with existing identical items instead of creating duplicates.

**Returns:** `bool` - `true` if item was merged, `false` if added as new

**How It Works:**

1. Searches for an existing item with same ID and specifications using `isSameItem()`
2. If found:
   - Calculates unit price: `unitPrice = existingPrice / existingQuantity`
   - Updates quantity: `newQuantity = oldQuantity + addedQuantity`
   - Recalculates total price: `newPrice = unitPrice * newQuantity`
3. If not found:
   - Adds item as new entry to cart

**Usage Example:**

```dart
Cart cart = await Service.read('cart');
Item newItem = Item(id: '123', quantity: 1, price: 275.0);

bool wasMerged = Service.addOrMergeCartItem(cart, newItem);
await Service.save('cart', cart.toJson());

if (wasMerged) {
  print('Item quantity updated');
} else {
  print('New item added to cart');
}
```

**Used In:**

- `lib/item/components/body.dart` (line 330)

**Location in Service:** Lines 421-454

---

## Store Helper Methods

### Overview

These methods determine if stores are currently open based on their schedules, app-wide open/close times, and UTC+3 timezone (Ethiopia and South Sudan).

### Two Implementation Patterns

There are two distinct patterns for checking store open/close status:

| Pattern       | Method                   | Return Type          | Use Case                              | Screens Using It |
| ------------- | ------------------------ | -------------------- | ------------------------------------- | ---------------- |
| **Pattern 1** | `isStoreOpen(var store)` | `Future<bool>`       | Check if a **single store** is open   | 4 screens        |
| **Pattern 2** | `storeOpen(List stores)` | `Future<List<bool>>` | Check if **multiple stores** are open | 3 screens        |

---

### Methods

#### Pattern 1: `isStoreOpen(var store)`

**Purpose:** Check if a single store is currently open.

**Parameters:**

- `store` - Store object containing `store_time` schedule

**Returns:** `Future<bool>` - `true` if store is open, `false` otherwise

**How It Works:**

- Wraps the single store in a list
- Calls `storeOpen([store])`
- Returns the first result

**Usage Example:**

```dart
bool isOpen = await Service.isStoreOpen(store);
if (isOpen) {
  print('Store is open');
} else {
  print('Store is closed');
}
```

**Used In:**

- `lib/home/components/home_body.dart`
- `lib/notifications/notification_store.dart` (line 91)
- `lib/splash/component/splash_container.dart` (line 47)
- `lib/global/home_page/components/global_home_screen.dart` (line 122)

**Location in Service:** Lines 521-524

**IMPORTANT - App Metadata Requirement:**

Before calling `Service.isStoreOpen()`, you **MUST** ensure that app metadata (`app_open` and `app_close`) has been fetched and saved to storage. This is done by calling `_getAppKeys()` or `getAppKeys()` method.

**Why is this required?**

The Service method reads `app_open` and `app_close` from SharedPreferences storage to determine app-wide operating hours. If these values are not in storage, the store check will fail.

**Implementation Pattern:**

```dart
void _getItemInformation(String itemId) async {
  setState(() {
    _loading = true;
  });
  // Ensure app metadata is loaded before checking store status
  _getAppKeys();
  await getItemInformation(itemId);
  if (notificationItem != null && notificationItem['success']) {
    bool isOpen = await Service.isStoreOpen(notificationItem['item']);
    // ... rest of the logic
  }
}
```

**Screens Updated to Call `_getAppKeys()`:**

- ✅ `lib/splash/component/splash_container.dart` - Calls `_getAppKeys()` at line 44 before using `Service.isStoreOpen()`
- ✅ `lib/notifications/notification_store.dart` - Calls `_getAppKeys()` at line 88 before using `Service.isStoreOpen()`
- ✅ `lib/home/components/home_body.dart` - Calls `_getAppKeys()` in `getCategories()` called from `initState()`
- ✅ `lib/global/home_page/components/global_home_screen.dart` - Calls `_getAppKeys()` at line 210 before using `Service.isStoreOpen()`

---

#### Pattern 2: `storeOpen(List stores)`

**Purpose:** Check which stores from a list are currently open.

**Parameters:**

- `stores` - List of store objects containing `store_time` schedules

**Returns:** `Future<List<bool>>` - List where each boolean indicates if the corresponding store is open

**How It Works:**

1. Reads app-wide open/close times from storage (`app_open`, `app_close`)
2. Gets current time in UTC+3 timezone
3. For each store:
   - Checks if store has custom schedule (`store_time`)
   - Matches current weekday (Sunday=0, Monday=1, etc.)
   - Compares current time against:
     - Store-specific open/close times
     - App-wide open/close times
     - `is_store_open` flag
4. Returns list of boolean values

**Usage Example:**

```dart
List<bool> isOpen = await Service.storeOpen(stores);

for (int i = 0; i < stores.length; i++) {
  if (isOpen[i]) {
    print('${stores[i]['name']} is open');
  } else {
    print('${stores[i]['name']} is closed');
  }
}
```

**Used In:**

- `lib/store/components/body.dart` (line 228)
- `lib/search/search_screen.dart`
- `lib/home/components/featured_nearby_stores.dart.dart`

**Location in Service:** Lines 545-666

---

### Store Open/Close Logic Details

#### Timezone

- All calculations use **UTC+3** timezone (Ethiopia and South Sudan)
- Current time: `DateTime.now().toUtc().add(Duration(hours: 3))`

#### Weekday Mapping

```dart
Sunday    = 0
Monday    = 1
Tuesday   = 2
Wednesday = 3
Thursday  = 4
Friday    = 5
Saturday  = 6
```

#### Store Schedule Structure

Stores can have custom schedules with:

- **Day-specific hours:** Different open/close times for different days
- **Multiple time ranges:** Store can have multiple open periods in one day
- **Override flag:** `is_store_open` can force open/closed status
- **Fallback:** If no schedule exists, uses app-wide times only

#### Checking Logic

A store is considered **OPEN** if:

1. Current time is after store open time AND
2. Current time is after app-wide open time AND
3. Current time is before store close time AND
4. Current time is before app-wide close time AND
5. `is_store_open` flag is `true`

---

## Migration Guide

### For Pattern 1 Screens (Single Store Check)

**Before:**

```dart
Future<bool> storeOpen(var store) async {
  // 50+ lines of duplicate logic
  DateFormat dateFormat = DateFormat.Hm();
  DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
  // ... complex logic ...
  return isStoreOpen;
}
```

**After:**

```dart
// Remove the entire storeOpen method
// Replace usage with:
bool isOpen = await Service.isStoreOpen(store);
```

---

### For Pattern 2 Screens (Multiple Stores Check)

**Before:**

```dart
void storeOpen(List stores) async {
  // 120+ lines of duplicate logic
  List<bool> isOpen = [];
  DateFormat dateFormat = DateFormat.Hm();
  // ... complex logic ...
  setState(() {
    this.isOpen = isOpen;
  });
}
```

**After:**

```dart
void storeOpen(List stores) async {
  isOpen = await Service.storeOpen(stores);
  setState(() {}); // Trigger rebuild if needed
}
```

**Or even simpler (3 lines):**

```dart
void storeOpen(List stores) async {
  isOpen = await Service.storeOpen(stores);
}
```

---

## Benefits of Centralized Service Methods

### 1. Code Reusability

- **Before:** 7 screens × ~100 lines = ~700 lines of duplicated logic
- **After:** 1 central implementation + 7 screens × ~3 lines = ~120 lines total
- **Reduction:** ~82% less code

### 2. Maintainability

- Bug fixes only need to be applied once in `service.dart`
- Logic changes propagate to all screens automatically
- Easier to test a single implementation

### 3. Consistency

- All screens use identical logic
- No risk of different screens having different behaviors
- Uniform timezone handling across the app

### 4. Type Safety

- Clear method signatures
- Documentation in one place
- IDE autocomplete for all usages

---

## Summary

| Feature           | Cart Methods                 | Store Methods (Pattern 1) | Store Methods (Pattern 2)     |
| ----------------- | ---------------------------- | ------------------------- | ----------------------------- |
| **Purpose**       | Prevent duplicate cart items | Check single store status | Check multiple store statuses |
| **Key Method**    | `addOrMergeCartItem()`       | `isStoreOpen()`           | `storeOpen()`                 |
| **Returns**       | `bool` (merged or new)       | `Future<bool>`            | `Future<List<bool>>`          |
| **Lines Saved**   | ~40 per screen               | ~50 per screen            | ~120 per screen               |
| **Screens Using** | 1 screen                     | 4 screens                 | 3 screens                     |

---

## Code Evolution (Before & After)

This section shows the complete transformation from duplicated code to centralized service methods.

### 1. Cart Item Management - `lib/item/components/body.dart`

#### Previous Implementation (Problematic)

```dart
// OLD CODE - Created duplicate cart items
setState(() {
  if (cart!.items == null) {
    cart!.items = [];
  }
  // PROBLEM: Always adds as new item, even if it already exists
  cart!.items!.add(item);
  Service.save('cart', cart);
  Navigator.of(context).pop();
});
```

**Issues:**

- ❌ Created duplicate items in cart
- ❌ No specification comparison
- ❌ Price not recalculated when merging quantities

#### Intermediate Fix (Price calculation bug)

```dart
// INTERMEDIATE - Fixed duplicates but wrong price calculation
setState(() {
  // Check if the same item with same specifications exists
  int existingItemIndex = -1;
  for (int i = 0; i < (cart!.items?.length ?? 0); i++) {
    if (_isSameItem(cart!.items![i], item)) {
      existingItemIndex = i;
      break;
    }
  }

  if (existingItemIndex != -1) {
    // PROBLEM: Just copied new item's price without recalculating
    cart!.items![existingItemIndex].quantity =
        (cart!.items![existingItemIndex].quantity ?? 0) + (item.quantity ?? 0);
    cart!.items![existingItemIndex].price = item.price; // WRONG!
  } else {
    if (cart!.items == null) {
      cart!.items = [];
    }
    cart!.items!.add(item);
  }
  Service.save('cart', cart);
  Navigator.of(context).pop();
});

// Helper method to compare items
bool _isSameItem(Item existingItem, Item newItem) {
  // ~50 lines of comparison logic...
}
```

**Issues:**

- ✅ Fixed duplicate items
- ❌ Price calculation still wrong (item price 275.00, quantity 2, total showing 275.00)
- ❌ Logic duplicated in this file only

#### Current Implementation (Correct)

```dart
// CURRENT - Uses centralized Service method
setState(() {
  // Use Service method to add or merge item
  Service.addOrMergeCartItem(cart!, item);
  Service.save('cart', cart);
  Navigator.of(context).pop();
});
```

**Benefits:**

- ✅ No duplicate items
- ✅ Correct price calculation: `unitPrice = existingPrice / existingQuantity`, then `newPrice = unitPrice * newQuantity`
- ✅ Reusable across entire app
- ✅ Only 3 lines instead of 50+

---

### 2. Store Open/Close Logic - `lib/store/components/body.dart`

#### Previous Implementation (Duplicated Logic)

```dart
// OLD CODE - 120+ lines duplicated in multiple files
import 'package:intl/intl.dart'; // Import needed in each file

void storeOpen(List stores) async {
  List<bool> isOpen = [];
  DateFormat dateFormat = DateFormat.Hm();
  DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));

  // Read app open/close times from storage
  var appOpen = await Service.read('app_open');
  var appClose = await Service.read('app_close');

  DateTime zmallOpen = dateFormat.parse(appOpen!);
  DateTime zmallClose = dateFormat.parse(appClose!);

  zmallOpen = DateTime(
    now.year,
    now.month,
    now.day,
    zmallOpen.hour,
    zmallOpen.minute,
  );
  zmallClose = DateTime(
    now.year,
    now.month,
    now.day,
    zmallClose.hour,
    zmallClose.minute,
  );

  stores.forEach((store) {
    bool isStoreOpen = false;
    if (store['store_time'] != null && store['store_time'].length != 0) {
      for (var i = 0; i < store['store_time'].length; i++) {
        int weekday;
        if (now.weekday == 7) {
          weekday = 0;
        } else {
          weekday = now.weekday;
        }

        if (store['store_time'][i]['day'] == weekday) {
          if (store['store_time'][i]['day_time'].length != 0 &&
              store['store_time'][i]['is_store_open']) {
            for (var j = 0; j < store['store_time'][i]['day_time'].length; j++) {
              DateTime open = dateFormat.parse(
                store['store_time'][i]['day_time'][j]['store_open_time'],
              );
              open = DateTime(now.year, now.month, now.day, open.hour, open.minute);
              DateTime close = dateFormat.parse(
                store['store_time'][i]['day_time'][j]['store_close_time'],
              );
              close = DateTime(now.year, now.month, now.day, close.hour, close.minute);
              now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

              if (now.isAfter(open) &&
                  now.isAfter(zmallOpen) &&
                  now.isBefore(close) &&
                  store['store_time'][i]['is_store_open'] &&
                  now.isBefore(zmallClose)) {
                isStoreOpen = true;
                break;
              } else {
                isStoreOpen = false;
              }
            }
          } else {
            if (now.isAfter(zmallOpen) &&
                now.isBefore(zmallClose) &&
                store['store_time'][i]['is_store_open']) {
              isStoreOpen = true;
            } else {
              isStoreOpen = false;
            }
          }
        }
      }
    } else {
      DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
      DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
      DateFormat dateFormat = DateFormat.Hm();
      if (appClose != null) {
        zmallClose = dateFormat.parse(appClose);
      }

      zmallClose = DateTime(
        now.year,
        now.month,
        now.day,
        zmallClose.hour,
        zmallClose.minute,
      );
      now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      now.isAfter(zmallClose) ? isStoreOpen = false : isStoreOpen = true;
    }
    isOpen.add(isStoreOpen);
  });

  setState(() {
    this.isOpen = isOpen;
  });
}
```

**Issues:**

- ❌ 120+ lines of complex logic
- ❌ Duplicated across 3 screens (Pattern 2)
- ❌ Requires `intl` import in every file
- ❌ Hard to maintain and test
- ❌ Risk of inconsistency between screens

#### Current Implementation (Centralized)

```dart
// CURRENT - Simple 3-line implementation
void storeOpen(List stores) async {
  // Use Service method to determine which stores are open
  isOpen = await Service.storeOpen(stores);
}

// Note: Import 'package:intl/intl.dart' removed from this file
```

**Benefits:**

- ✅ Only 2 lines instead of 120+
- ✅ No duplicate logic across screens
- ✅ Consistent behavior everywhere
- ✅ Centralized testing and maintenance
- ✅ Single source of truth for business logic

---

### 3. Single Store Check - Pattern 1 Screens

#### Previous Implementation (4 Screens)

Each of these screens had similar 50+ line implementations:

- `lib/home/components/home_body.dart`
- `lib/notifications/notification_store.dart`
- `lib/splash/component/splash_container.dart`
- `lib/global/home_page/components/global_home_screen.dart`

```dart
// OLD CODE - Duplicated in 4 different files
Future<bool> storeOpen(var store) async {
  DateFormat dateFormat = DateFormat.Hm();
  DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));

  var appOpen = await Service.read('app_open');
  var appClose = await Service.read('app_close');

  DateTime zmallOpen = dateFormat.parse(appOpen!);
  DateTime zmallClose = dateFormat.parse(appClose!);

  zmallOpen = DateTime(now.year, now.month, now.day, zmallOpen.hour, zmallOpen.minute);
  zmallClose = DateTime(now.year, now.month, now.day, zmallClose.hour, zmallClose.minute);

  bool isStoreOpen = false;

  // ... 40+ more lines of logic ...

  return isStoreOpen;
}
```

**Issues:**

- ❌ 50+ lines duplicated across 4 files
- ❌ Same logic written 4 different times
- ❌ Bug fixes must be applied 4 times

#### Current Implementation (Recommended)

```dart
// CURRENT - Use centralized Service method
bool isOpen = await Service.isStoreOpen(store);
```

**Benefits:**

- ✅ Single line usage
- ✅ Reuses Pattern 2 logic internally
- ✅ Consistent with other screens
- ✅ No duplication

---

### 4. Service Class Implementation

#### Added to `lib/services/service.dart`

```dart
// ============= Cart Helper Methods =============

/// Check if two cart items are identical
static bool isSameItem(Item existingItem, Item newItem) {
  // Check if item IDs match
  if (existingItem.id != newItem.id) {
    return false;
  }

  // Check if specifications match
  if (existingItem.specification == null && newItem.specification == null) {
    return true;
  }

  if (existingItem.specification == null || newItem.specification == null) {
    return false;
  }

  if (existingItem.specification!.length != newItem.specification!.length) {
    return false;
  }

  // Compare each specification
  for (var newSpec in newItem.specification!) {
    bool found = false;
    for (var existingSpec in existingItem.specification!) {
      if (existingSpec.uniqueId == newSpec.uniqueId) {
        // Check if the selected options within this spec are the same
        if (existingSpec.list!.length != newSpec.list!.length) {
          return false;
        }

        // Compare each option in the specification
        for (var newOption in newSpec.list!) {
          bool optionFound = false;
          for (var existingOption in existingSpec.list!) {
            if (existingOption.uniqueId == newOption.uniqueId) {
              optionFound = true;
              break;
            }
          }
          if (!optionFound) {
            return false;
          }
        }
        found = true;
        break;
      }
    }
    if (!found) {
      return false;
    }
  }

  return true;
}

/// Add or merge an item into the cart
static bool addOrMergeCartItem(Cart cart, Item newItem) {
  // Check if the same item with same specifications exists
  int existingItemIndex = -1;
  for (int i = 0; i < (cart.items?.length ?? 0); i++) {
    if (isSameItem(cart.items![i], newItem)) {
      existingItemIndex = i;
      break;
    }
  }

  if (existingItemIndex != -1) {
    // Item found - merge by updating quantity and price
    int oldQuantity = cart.items![existingItemIndex].quantity ?? 0;
    int newQuantity = oldQuantity + (newItem.quantity ?? 0);

    // Calculate unit price from the existing item
    // If old quantity is 0, calculate from new item to avoid division by zero
    double unitPrice = oldQuantity > 0
        ? (cart.items![existingItemIndex].price ?? 0) / oldQuantity
        : (newItem.price ?? 0) / (newItem.quantity ?? 1);

    // Update quantity and recalculate total price
    cart.items![existingItemIndex].quantity = newQuantity;
    cart.items![existingItemIndex].price = unitPrice * newQuantity;

    return true; // Item was merged
  } else {
    // Item not found - add as new
    cart.items ??= [];
    cart.items!.add(newItem);

    return false; // Item was added as new
  }
}

// ============= Store Helper Methods =============

/// Check if a single store is currently open (Pattern 1)
static Future<bool> isStoreOpen(var store) async {
  List<bool> result = await storeOpen([store]);
  return result.isNotEmpty ? result[0] : false;
}

/// Determine which stores are currently open based on their schedules (Pattern 2)
static Future<List<bool>> storeOpen(List stores) async {
  List<bool> isOpen = [];
  DateFormat dateFormat = DateFormat.Hm();
  DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));

  // Read app open/close times from storage
  var appOpen = await read('app_open');
  var appClose = await read('app_close');

  DateTime zmallOpen = dateFormat.parse(appOpen!);
  DateTime zmallClose = dateFormat.parse(appClose!);

  zmallOpen = DateTime(
    now.year,
    now.month,
    now.day,
    zmallOpen.hour,
    zmallOpen.minute,
  );
  zmallClose = DateTime(
    now.year,
    now.month,
    now.day,
    zmallClose.hour,
    zmallClose.minute,
  );

  stores.forEach((store) {
    bool isStoreOpen = false;
    if (store['store_time'] != null && store['store_time'].length != 0) {
      for (var i = 0; i < store['store_time'].length; i++) {
        int weekday;
        if (now.weekday == 7) {
          weekday = 0;
        } else {
          weekday = now.weekday;
        }

        if (store['store_time'][i]['day'] == weekday) {
          if (store['store_time'][i]['day_time'].length != 0 &&
              store['store_time'][i]['is_store_open']) {
            for (var j = 0; j < store['store_time'][i]['day_time'].length; j++) {
              DateTime open = dateFormat.parse(
                store['store_time'][i]['day_time'][j]['store_open_time'],
              );
              open = DateTime(now.year, now.month, now.day, open.hour, open.minute);
              DateTime close = dateFormat.parse(
                store['store_time'][i]['day_time'][j]['store_close_time'],
              );
              close = DateTime(now.year, now.month, now.day, close.hour, close.minute);
              now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

              if (now.isAfter(open) &&
                  now.isAfter(zmallOpen) &&
                  now.isBefore(close) &&
                  store['store_time'][i]['is_store_open'] &&
                  now.isBefore(zmallClose)) {
                isStoreOpen = true;
                break;
              } else {
                isStoreOpen = false;
              }
            }
          } else {
            if (now.isAfter(zmallOpen) &&
                now.isBefore(zmallClose) &&
                store['store_time'][i]['is_store_open']) {
              isStoreOpen = true;
            } else {
              isStoreOpen = false;
            }
          }
        }
      }
    } else {
      DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
      DateTime zmallClose = DateTime(now.year, now.month, now.day, 21, 00);
      DateFormat dateFormat = DateFormat.Hm();
      if (appClose != null) {
        zmallClose = dateFormat.parse(appClose);
      }

      zmallClose = DateTime(
        now.year,
        now.month,
        now.day,
        zmallClose.hour,
        zmallClose.minute,
      );
      now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      now.isAfter(zmallClose) ? isStoreOpen = false : isStoreOpen = true;
    }
    isOpen.add(isStoreOpen);
  });

  return isOpen;
}
```

---

### Key Improvements Summary

| Aspect                      | Before                              | After                                      | Improvement     |
| --------------------------- | ----------------------------------- | ------------------------------------------ | --------------- |
| **Cart Logic**              | 50+ lines per screen                | 3 lines per screen                         | 94% reduction   |
| **Store Logic (Pattern 1)** | 50+ lines × 4 screens = 200+ lines  | 1 line × 4 screens + 4 lines in Service    | 96% reduction   |
| **Store Logic (Pattern 2)** | 120+ lines × 3 screens = 360+ lines | 2 lines × 3 screens + 120 lines in Service | 65% reduction   |
| **Total Code**              | ~610 lines duplicated               | ~135 lines total                           | 78% reduction   |
| **Maintainability**         | Fix bugs in 8 places                | Fix bugs in 1 place                        | 8× easier       |
| **Testing**                 | Test 8 implementations              | Test 1 implementation                      | 8× simpler      |
| **Consistency**             | Risk of divergence                  | Guaranteed consistency                     | 100% consistent |

---

## Related Files

- **Service Implementation:** `/lib/services/service.dart`
- **Cart Model:** `/lib/models/cart.dart`
- **Example Usage (Cart):** `/lib/item/components/body.dart`
- **Example Usage (Store):** `/lib/store/components/body.dart`

---

**Last Updated:** 2025-11-04
**ZMall Version:** 3.2.3+340
**Refactoring Date:** 2025-11-04
