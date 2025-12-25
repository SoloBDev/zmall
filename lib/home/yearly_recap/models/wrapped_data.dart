import 'package:flutter/material.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/constants.dart';

class YearWrappedData {
  final String userId;
  final int year;
  final int totalOrders;
  final double totalSpent;
  final double rewardsEarned; // Changed from totalSaved
  final String favoriteCategory;
  final String favoriteCategoryEmoji;
  final String mostActiveMonth; // Changed from peakOrderingTime
  final double biggestOrderAmount; // Changed from averageDeliveryMinutes
  final String funFact; // Changed from co2Saved
  final String topRestaurant;
  final String? topRestaurantImage;
  final int restaurantOrderCount;
  final List<TopRestaurant> topRestaurants; // New: Store top 3 restaurants
  final List<String> topDishes;
  final String longestStreak;
  final Map<String, int> monthlyOrders;
  final String personalizedMessage;

  YearWrappedData({
    required this.userId,
    required this.year,
    required this.totalOrders,
    required this.totalSpent,
    required this.rewardsEarned,
    required this.favoriteCategory,
    required this.favoriteCategoryEmoji,
    required this.mostActiveMonth,
    required this.biggestOrderAmount,
    required this.funFact,
    required this.topRestaurant,
    this.topRestaurantImage,
    required this.restaurantOrderCount,
    required this.topRestaurants,
    required this.topDishes,
    required this.longestStreak,
    required this.monthlyOrders,
    required this.personalizedMessage,
  });

  factory YearWrappedData.fromJson(Map<String, dynamic> json) {
    // Handle API response structure with 'recap' wrapper
    final recapData = json['recap'] ?? json;

    // Extract top restaurants info (up to 3)
    final topRestaurantsRaw = recapData['top_restaurants'] as List<dynamic>?;
    final topRestaurantsList = topRestaurantsRaw != null
        ? topRestaurantsRaw
              .take(3) // Take top 3
              .map((r) => TopRestaurant.fromJson(r as Map<String, dynamic>))
              .toList()
        : <TopRestaurant>[];

    final topRestaurantData =
        (topRestaurantsRaw != null && topRestaurantsRaw.isNotEmpty)
        ? topRestaurantsRaw[0] as Map<String, dynamic>
        : null;

    // Extract top products info
    final topProducts = recapData['top_products'] as List<dynamic>?;
    final topProductsList =
        topProducts?.map((p) => p['product_name'] as String? ?? '').toList() ??
        [];

    // Get favorite category from top products or use default
    final topProductName = topProducts != null && topProducts.isNotEmpty
        ? (topProducts[0]['product_name'] as String? ?? '')
        : '';
    final favoriteCategory = topProductName.isNotEmpty
        ? topProductName
        : recapData['favorite_food_category'] as String? ?? 'Food';
    final categoryEmoji = _getCategoryEmoji(favoriteCategory);

    // Use total_wallet_earnings from API
    // API provides breakdown: wallet_earnings_from_game, wallet_earnings_from_review, wallet_earnings_from_10th_order
    final walletEarnings = (recapData['total_wallet_earnings'] ?? 0).toDouble();

    // Generate fun fact
    final newRestaurants = recapData['new_restaurants_tried'] ?? 0;
    final funFact = newRestaurants > 0
        ? 'You tried $newRestaurants new restaurant${newRestaurants > 1 ? 's' : ''}!'
        : 'Keep exploring new restaurants!';

    // Construct full image URL if store image exists
    final storeImage = topRestaurantData?['store_image'] as String?;
    final fullImageUrl = storeImage != null && storeImage.isNotEmpty
        ? '$BASE_URL/$storeImage'
        : null;
    var streak = recapData['longest_ordering_streak'];
    final longestStreakMessage =
        '${streak ?? 0} ${streak != 1 ? 'days' : 'day'}';
    return YearWrappedData(
      userId: json['userId'] ?? '',
      year: recapData['year'] ?? DateTime.now().year,
      totalOrders: recapData['total_orders_delivered'] ?? 0,
      totalSpent: 0.0, // Not provided in API
      rewardsEarned: walletEarnings,
      favoriteCategory: favoriteCategory.isEmpty ? 'Food' : favoriteCategory,
      favoriteCategoryEmoji: categoryEmoji,
      mostActiveMonth: recapData['most_active_month'] ?? '',
      biggestOrderAmount:
          walletEarnings, // Using wallet earnings as placeholder
      funFact: funFact,
      topRestaurant: topRestaurantData?['store_name'] ?? 'Your Favorite Spot',
      topRestaurantImage: fullImageUrl,
      restaurantOrderCount: topRestaurantData?['order_count'] ?? 0,
      topRestaurants: topRestaurantsList,
      topDishes: topProductsList,
      longestStreak: longestStreakMessage,
      monthlyOrders: {}, // Not provided in current API
      personalizedMessage: 'Thank you for being with us this year! 🎉',
    );
  }

  static String _getCategoryEmoji(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('pizza')) return '🍕';
    if (categoryLower.contains('burger')) return '🍔';
    if (categoryLower.contains('sushi')) return '🍣';
    if (categoryLower.contains('coffee')) return '☕';
    if (categoryLower.contains('dessert') || categoryLower.contains('cake'))
      return '🍰';
    if (categoryLower.contains('chicken')) return '🍗';
    if (categoryLower.contains('noodle') || categoryLower.contains('pasta'))
      return '🍜';
    if (categoryLower.contains('salad')) return '🥗';
    if (categoryLower.contains('drink') || categoryLower.contains('juice'))
      return '🥤';
    return '🍽️'; // Default food emoji
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'year': year,
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'rewardsEarned': rewardsEarned,
      'favoriteCategory': favoriteCategory,
      'favoriteCategoryEmoji': favoriteCategoryEmoji,
      'mostActiveMonth': mostActiveMonth,
      'biggestOrderAmount': biggestOrderAmount,
      'funFact': funFact,
      'topRestaurant': topRestaurant,
      'topRestaurantImage': topRestaurantImage,
      'restaurantOrderCount': restaurantOrderCount,
      'topRestaurants': topRestaurants.map((r) => r.toJson()).toList(),
      'topDishes': topDishes,
      'longestStreak': longestStreak,
      'monthlyOrders': monthlyOrders,
      'personalizedMessage': personalizedMessage,
    };
  }
}

// Model for top restaurants
class TopRestaurant {
  final String storeName;
  final String? storeImage;
  final int orderCount;

  TopRestaurant({
    required this.storeName,
    this.storeImage,
    required this.orderCount,
  });

  factory TopRestaurant.fromJson(Map<String, dynamic> json) {
    // Construct full image URL if store image exists
    final storeImage = json['store_image'] as String?;
    final fullImageUrl = storeImage != null && storeImage.isNotEmpty
        ? '$BASE_URL/$storeImage'
        // '$BASE_URL/$storeImage'
        : null;

    return TopRestaurant(
      storeName: Service.capitalizeFirstLetters(json['store_name'] ?? ''),
      storeImage: fullImageUrl,
      orderCount: json['order_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'store_image': storeImage,
      'order_count': orderCount,
    };
  }
}

class StorySlide {
  final String type;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData? icon;
  final String? emoji;
  final String? imageUrl;
  final bool showConfetti;
  final bool useLogo;
  final bool showShare; // Add this
  final dynamic data;

  StorySlide({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.icon,
    this.emoji,
    this.imageUrl,
    this.showConfetti = false,
    this.useLogo = false,
    this.showShare = false, // Add this
    this.data,
  });
}
