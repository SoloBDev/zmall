import 'package:zmall/home/magazine/models/magazine_model.dart';

class MagazineService {
  // Fetch magazines from API
  static Future<List<Magazine>> fetchMagazines() async {
    // TODO: Implement actual API call
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1));
    return _getMockMagazines();
  }

  // Fetch magazine by ID
  static Future<Magazine?> fetchMagazineById(String id) async {
    final magazines = await fetchMagazines();
    try {
      return magazines.firstWhere((mag) => mag.id == id);
    } catch (e) {
      return null;
    }
  }

  // Fetch magazines by category
  static Future<List<Magazine>> fetchMagazinesByCategory(
    String category,
  ) async {
    final magazines = await fetchMagazines();
    return magazines.where((mag) => mag.category == category).toList();
  }

  // Mock data for testing
  // Using archive.org public domain content as demo
  static const String _mockPdfUrl =
      // 'https://ontheline.trincoll.edu/images/bookdown/sample-local-pdf.pdf?utm_source=chatgpt.com';
      'https://ia800503.us.archive.org/21/items/treasureisland0000unse_k0j8/treasureisland0000unse_k0j8.pdf';

  static List<Magazine> _getMockMagazines() {
    return [
      Magazine(
        id: '1',
        title: 'ZMall Monthly - January 2025',
        description:
            'Discover the latest products, deals, and trends for the new year. Featuring exclusive interviews with our top sellers.',
        coverImage: '',
        pdfUrl: _mockPdfUrl,
        pageCount: 160,
        category: 'Monthly',
        publishedDate: DateTime(2025, 1, 1),
        isNew: true,
        tags: ['Featured', 'New Year', 'Deals'],
      ),
      Magazine(
        id: '2',
        title: 'Food & Dining Guide 2025',
        description:
            'Your ultimate guide to the best restaurants, cafes, and food delivery options in your area.',
        coverImage: '',
        pdfUrl: _mockPdfUrl,
        pageCount: 160,
        category: 'Food',
        publishedDate: DateTime(2024, 12, 15),
        isNew: false,
        tags: ['Food', 'Restaurants', 'Guide'],
      ),
      Magazine(
        id: '3',
        title: 'Tech & Gadgets Catalog',
        description:
            'Explore the latest smartphones, laptops, and tech accessories available on ZMall.',
        coverImage: '',
        pdfUrl: _mockPdfUrl,
        pageCount: 160,
        category: 'Technology',
        publishedDate: DateTime(2024, 12, 1),
        isNew: false,
        tags: ['Technology', 'Gadgets', 'Electronics'],
      ),
      Magazine(
        id: '4',
        title: 'Fashion & Style Winter Collection',
        description:
            'Stay warm and stylish this winter with our curated collection of clothing and accessories.',
        coverImage: '',
        pdfUrl: _mockPdfUrl,
        pageCount: 160,
        category: 'Fashion',
        publishedDate: DateTime(2024, 11, 20),
        isNew: false,
        tags: ['Fashion', 'Winter', 'Clothing'],
      ),
    ];
  }
}
