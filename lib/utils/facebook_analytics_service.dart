// import 'package:facebook_app_events/facebook_app_events.dart';
// import 'package:flutter/foundation.dart';

// /// Facebook Analytics Service
// /// Wrapper class for Facebook App Events to track user actions and behavior
// class FacebookAnalyticsService {
//   static final FacebookAnalyticsService _instance =
//       FacebookAnalyticsService._internal();
//   factory FacebookAnalyticsService() => _instance;
//   FacebookAnalyticsService._internal();

//   final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

//   /// Initialize Facebook App Events
//   Future<void> initialize() async {
//     try {
//       // Enable automatic logging
//       await _facebookAppEvents.setAutoLogAppEventsEnabled(true);

//       // Enable advertiser tracking (iOS)
//       await _facebookAppEvents.setAdvertiserTracking(enabled: true);

//       if (kDebugMode) {
//         print('✅ Facebook App Events initialized successfully');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error initializing Facebook App Events: $e');
//       }
//     }
//   }

//   /// Log app open event
//   Future<void> logAppOpen() async {
//     try {
//       await _facebookAppEvents.logEvent(name: 'app_open');
//       if (kDebugMode) {
//         print('📱 Facebook Event: App Opened');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging app open: $e');
//       }
//     }
//   }

//   /// Log view content event (product view)
//   Future<void> logViewContent({
//     required String contentType,
//     required String contentId,
//     String? currency,
//     double? price,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: 'fb_mobile_content_view',
//         parameters: {
//           'fb_content_type': contentType,
//           'fb_content_id': contentId,
//           if (currency != null) 'fb_currency': currency,
//           if (price != null) 'fb_price': price,
//         },
//       );
//       if (kDebugMode) {
//         print('👁️ Facebook Event: View Content - $contentType ($contentId)');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging view content: $e');
//       }
//     }
//   }

//   /// Log add to cart event
//   Future<void> logAddToCart({
//     required String contentId,
//     required String contentType,
//     required String currency,
//     required double price,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: 'fb_mobile_add_to_cart',
//         parameters: {
//           'fb_content_id': contentId,
//           'fb_content_type': contentType,
//           'fb_currency': currency,
//           'fb_price': price,
//         },
//         valueToSum: price,
//       );
//       if (kDebugMode) {
//         print('🛒 Facebook Event: Add to Cart - $contentId ($price $currency)');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging add to cart: $e');
//       }
//     }
//   }

//   /// Log purchase event
//   Future<void> logPurchase({
//     required double amount,
//     required String currency,
//     Map<String, dynamic>? parameters,
//   }) async {
//     try {
//       await _facebookAppEvents.logPurchase(
//         amount: amount,
//         currency: currency,
//         parameters: parameters,
//       );
//       if (kDebugMode) {
//         print('💰 Facebook Event: Purchase - $amount $currency');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging purchase: $e');
//       }
//     }
//   }

//   /// Log initiate checkout event
//   Future<void> logInitiateCheckout({
//     required double totalPrice,
//     required String currency,
//     required int numItems,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: 'fb_mobile_initiated_checkout',
//         parameters: {
//           'fb_num_items': numItems,
//           'fb_currency': currency,
//           'fb_content_type': 'product',
//         },
//         valueToSum: totalPrice,
//       );
//       if (kDebugMode) {
//         print(
//           '💳 Facebook Event: Initiate Checkout - $totalPrice $currency ($numItems items)',
//         );
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging initiate checkout: $e');
//       }
//     }
//   }

//   /// Log search event
//   Future<void> logSearch({
//     required String searchString,
//     String? contentType,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: 'fb_mobile_search',
//         parameters: {
//           'fb_search_string': searchString,
//           if (contentType != null) 'fb_content_type': contentType,
//         },
//       );
//       if (kDebugMode) {
//         print('🔍 Facebook Event: Search - "$searchString"');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging search: $e');
//       }
//     }
//   }

//   /// Log add to wishlist event
//   Future<void> logAddToWishlist({
//     required String contentId,
//     required String contentType,
//     String? currency,
//     double? price,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: 'fb_mobile_add_to_wishlist',
//         parameters: {
//           'fb_content_id': contentId,
//           'fb_content_type': contentType,
//           if (currency != null) 'fb_currency': currency,
//           if (price != null) 'fb_price': price,
//         },
//       );
//       if (kDebugMode) {
//         print('❤️ Facebook Event: Add to Wishlist - $contentId');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging add to wishlist: $e');
//       }
//     }
//   }

//   /// Log registration/signup event
//   Future<void> logCompleteRegistration({
//     required String registrationMethod,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: 'fb_mobile_complete_registration',
//         parameters: {'fb_registration_method': registrationMethod},
//       );
//       if (kDebugMode) {
//         print('📝 Facebook Event: Complete Registration - $registrationMethod');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging registration: $e');
//       }
//     }
//   }

//   /// Log rating event
//   Future<void> logRate({
//     required String contentType,
//     required String contentId,
//     required double rating,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: 'fb_mobile_rate',
//         parameters: {
//           'fb_content_type': contentType,
//           'fb_content_id': contentId,
//           'fb_rating_value': rating,
//         },
//       );
//       if (kDebugMode) {
//         print('⭐ Facebook Event: Rate - $contentId ($rating stars)');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging rate: $e');
//       }
//     }
//   }

//   /// Log custom event
//   Future<void> logCustomEvent({
//     required String eventName,
//     Map<String, dynamic>? parameters,
//     double? valueToSum,
//   }) async {
//     try {
//       await _facebookAppEvents.logEvent(
//         name: eventName,
//         parameters: parameters,
//         valueToSum: valueToSum,
//       );
//       if (kDebugMode) {
//         print('📊 Facebook Custom Event: $eventName');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error logging custom event: $e');
//       }
//     }
//   }

//   /// Set user ID for analytics (via setUserData)
//   Future<void> setUserId(String userId) async {
//     try {
//       // Facebook App Events uses external_id in setUserData
//       await _facebookAppEvents.setUserData(externalId: userId);
//       if (kDebugMode) {
//         print('👤 Facebook: User ID set - $userId');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error setting user ID: $e');
//       }
//     }
//   }

//   /// Clear user ID
//   Future<void> clearUserId() async {
//     try {
//       await _facebookAppEvents.clearUserData();
//       if (kDebugMode) {
//         print('👤 Facebook: User ID cleared');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error clearing user ID: $e');
//       }
//     }
//   }

//   /// Flush events (send buffered events to Facebook)
//   Future<void> flush() async {
//     try {
//       await _facebookAppEvents.flush();
//       if (kDebugMode) {
//         print('🔄 Facebook: Events flushed');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error flushing events: $e');
//       }
//     }
//   }

//   /// Set user data for advanced matching
//   Future<void> setUserData({
//     String? email,
//     String? firstName,
//     String? lastName,
//     String? phone,
//     String? dateOfBirth,
//     String? gender,
//     String? city,
//     String? state,
//     String? zip,
//     String? country,
//   }) async {
//     try {
//       await _facebookAppEvents.setUserData(
//         email: email,
//         firstName: firstName,
//         lastName: lastName,
//         phone: phone,
//         dateOfBirth: dateOfBirth,
//         gender: gender,
//         city: city,
//         state: state,
//         zip: zip,
//         country: country,
//       );
//       if (kDebugMode) {
//         print('👤 Facebook: User data updated');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error setting user data: $e');
//       }
//     }
//   }

//   /// Clear user data
//   Future<void> clearUserData() async {
//     try {
//       await _facebookAppEvents.clearUserData();
//       if (kDebugMode) {
//         print('👤 Facebook: User data cleared');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error clearing user data: $e');
//       }
//     }
//   }
// }
