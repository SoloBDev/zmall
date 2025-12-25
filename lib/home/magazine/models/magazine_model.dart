import 'package:zmall/utils/constants.dart';

class Magazine {
  final String id;
  final String title;
  final String description;
  final String coverImage;
  final String pdfUrl;
  final int pageCount;
  final String category;
  final DateTime publishedDate;
  final bool isNew;
  final bool isProtected;
  final List<String> tags;

  Magazine({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImage,
    required this.pdfUrl,
    required this.pageCount,
    required this.category,
    required this.publishedDate,
    this.isNew = false,
    this.isProtected = false,
    this.tags = const [],
  });

  factory Magazine.fromJson(Map<String, dynamic> json) {
    return Magazine(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverImage: json['cover_image'] != null && json['cover_image'] != ''
          ? '$BASE_URL/${json['cover_image']}'
          : '',
      pdfUrl: json['pdf_url'] != null && json['pdf_url'] != ''
          ? '$BASE_URL/${json['pdf_url']}'
          : '',
      pageCount: json['page_count'] ?? 0,
      category: json['category'] ?? '',
      publishedDate: json['published_date'] != null
          ? DateTime.parse(json['published_date'])
          : DateTime.now(),
      isNew: json['is_new'] ?? false,
      isProtected: json['is_protected'] ?? false,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_image': coverImage,
      'pdf_url': pdfUrl,
      'page_count': pageCount,
      'category': category,
      'published_date': publishedDate.toIso8601String(),
      'is_new': isNew,
      'is_protected': isProtected,
      'tags': tags,
    };
  }

  // Get formatted publish date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[publishedDate.month - 1]} ${publishedDate.day}, ${publishedDate.year}';
  }
}
