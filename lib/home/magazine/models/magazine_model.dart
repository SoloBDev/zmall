class UserEngagement {
  final bool hasViewed;
  final bool hasLiked;
  final bool isFavorite;
  final String? lastViewedAt;
  final double readingProgress;
  final int lastPageNumber;

  UserEngagement({
    this.hasViewed = false,
    this.hasLiked = false,
    this.isFavorite = false,
    this.lastViewedAt,
    this.readingProgress = 0.0,
    this.lastPageNumber = 0,
  });

  factory UserEngagement.fromJson(Map<String, dynamic> json) {
    return UserEngagement(
      hasViewed: json['has_viewed'] ?? false,
      hasLiked: json['has_liked'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      lastViewedAt: json['last_viewed_at'],
      readingProgress: (json['reading_progress'] ?? 0.0).toDouble(),
      lastPageNumber: json['last_page_number'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_viewed': hasViewed,
      'has_liked': hasLiked,
      'is_favorite': isFavorite,
      'last_viewed_at': lastViewedAt,
      'reading_progress': readingProgress,
      'last_page_number': lastPageNumber,
    };
  }

  // Create a copy with updated fields
  UserEngagement copyWith({
    bool? hasViewed,
    bool? hasLiked,
    bool? isFavorite,
    String? lastViewedAt,
    double? readingProgress,
    int? lastPageNumber,
  }) {
    return UserEngagement(
      hasViewed: hasViewed ?? this.hasViewed,
      hasLiked: hasLiked ?? this.hasLiked,
      isFavorite: isFavorite ?? this.isFavorite,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      readingProgress: readingProgress ?? this.readingProgress,
      lastPageNumber: lastPageNumber ?? this.lastPageNumber,
    );
  }
}

class Magazine {
  final String id;
  final int uniqueId;
  final String title;
  final String description;
  final String coverImage;
  final List<String> coverImages; // Array of cover images from API
  final String pdfUrl;
  final int pageCount;
  final String category;
  final DateTime publishedDate;
  final DateTime updatedAt;
  final bool isNew;
  final bool isProtected;
  final bool isActive;
  final List<String> tags;
  final List<String> images;

  // Engagement metrics
  final int viewsCount;
  final int likesCount;
  final int favoritesCount;
  final UserEngagement userEngagement;

  Magazine({
    required this.id,
    required this.uniqueId,
    required this.title,
    required this.description,
    required this.coverImage,
    this.coverImages = const [],
    required this.pdfUrl,
    required this.pageCount,
    this.category = '',
    required this.publishedDate,
    required this.updatedAt,
    this.isNew = false,
    this.isProtected = false,
    this.isActive = true,
    this.tags = const [],
    this.images = const [],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.favoritesCount = 0,
    UserEngagement? userEngagement,
  }) : userEngagement = userEngagement ?? UserEngagement();

  factory Magazine.fromJson(Map<String, dynamic> json) {
    // Handle cover_image as array
    List<String> coverImagesList = [];
    String firstCoverImage = '';

    if (json['cover_image'] != null) {
      if (json['cover_image'] is List) {
        coverImagesList = List<String>.from(json['cover_image']);
        if (coverImagesList.isNotEmpty) {
          firstCoverImage = coverImagesList[0];
        }
      } else if (json['cover_image'] is String) {
        firstCoverImage = json['cover_image'];
        coverImagesList = [firstCoverImage];
      }
    }

    // Parse dates
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();

    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at']);
      }
      if (json['updated_at'] != null) {
        updatedAt = DateTime.parse(json['updated_at']);
      }
    } catch (e) {
      // Use current date if parsing fails
    }

    // Check if magazine is new (created within last 30 days)
    final isNew = DateTime.now().difference(createdAt).inDays <= 5;

    return Magazine(
      id: json['_id'] ?? json['id'] ?? '',
      uniqueId: json['unique_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverImage: firstCoverImage,
      coverImages: coverImagesList,
      pdfUrl: json['url'] ?? json['pdf_url'] ?? '',
      pageCount: json['page_count'] ?? 0,
      category: json['category'] ?? '',
      publishedDate: createdAt,
      updatedAt: updatedAt,
      isNew: isNew,
      isProtected: json['is_protected'] ?? false,
      isActive: json['is_active'] ?? true,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      images: coverImagesList, // Use cover images as images array
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      favoritesCount: json['favorites_count'] ?? 0,
      userEngagement: json['user_engagement'] != null
          ? UserEngagement.fromJson(json['user_engagement'])
          : UserEngagement(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'unique_id': uniqueId,
      'title': title,
      'description': description,
      'cover_image': coverImages.isNotEmpty ? coverImages : [coverImage],
      'url': pdfUrl,
      'page_count': pageCount,
      'category': category,
      'created_at': publishedDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_new': isNew,
      'is_protected': isProtected,
      'is_active': isActive,
      'tags': tags,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'favorites_count': favoritesCount,
      'user_engagement': userEngagement.toJson(),
    };
  }

  // Create a copy with updated fields
  Magazine copyWith({
    String? id,
    int? uniqueId,
    String? title,
    String? description,
    String? coverImage,
    List<String>? coverImages,
    String? pdfUrl,
    int? pageCount,
    String? category,
    DateTime? publishedDate,
    DateTime? updatedAt,
    bool? isNew,
    bool? isProtected,
    bool? isActive,
    List<String>? tags,
    List<String>? images,
    int? viewsCount,
    int? likesCount,
    int? favoritesCount,
    UserEngagement? userEngagement,
  }) {
    return Magazine(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      coverImages: coverImages ?? this.coverImages,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pageCount: pageCount ?? this.pageCount,
      category: category ?? this.category,
      publishedDate: publishedDate ?? this.publishedDate,
      updatedAt: updatedAt ?? this.updatedAt,
      isNew: isNew ?? this.isNew,
      isProtected: isProtected ?? this.isProtected,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      userEngagement: userEngagement ?? this.userEngagement,
    );
  }

  // Helper method to format numbers (e.g., 1234 -> 1.2K)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String get formattedViewsCount => _formatCount(viewsCount);
  String get formattedLikesCount => _formatCount(likesCount);
  String get formattedFavoritesCount => _formatCount(favoritesCount);

  // Get formatted publish date
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[publishedDate.month - 1]} ${publishedDate.day}, ${publishedDate.year}';
  }
}
