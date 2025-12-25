import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zmall/home/magazine/models/magazine_model.dart';
import 'package:zmall/home/magazine/widgets/magazine_card.dart';
import 'package:zmall/home/magazine/screens/magazine_reader_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class MagazineListScreen extends StatefulWidget {
  final String url;
  final String? title;
  final List<Magazine>? magazines;
  const MagazineListScreen({
    super.key,
    required this.url,
    this.title,
    this.magazines,
  });

  @override
  State<MagazineListScreen> createState() => _MagazineListScreenState();
}

class _MagazineListScreenState extends State<MagazineListScreen> {
  List<Magazine> magazines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMagazinesFromUrls();
  }

  Future<void> _loadMagazinesFromUrls() async {
    setState(() => isLoading = true);
    // debugPrint("url ${widget.url}");
    try {
      // Trim the input to remove any leading/trailing whitespace
      final cleanedUrl = widget.url.trim();

      // Parse JSON data
      final jsonData = json.decode(cleanedUrl) as List;
      final loadedMagazines = jsonData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value as Map<String, dynamic>;

        // Parse date
        DateTime publishedDate;
        try {
          publishedDate = DateTime.parse(data['date'] ?? '');
        } catch (e) {
          publishedDate = DateTime.now();
        }

        // Clean and trim the URL to remove any whitespace or line breaks
        final cleanUrl = (data['url'] ?? '').toString().trim().replaceAll(
          RegExp(r'\s+'),
          '',
        );

        // Get cover image from either 'cover_image' or 'coverImage' field
        final coverImage = (data['cover_image'] ?? data['coverImage'] ?? '')
            .toString()
            .trim();

        return Magazine(
          id: 'magazine_$index',
          title: data['title'] ?? 'Z Magazine ${index + 1}',
          description:
              data['description'] ?? 'Discover amazing content in this edition',
          coverImage: coverImage,
          pdfUrl: cleanUrl,
          pageCount: data['pageCount'] ?? 0,
          category: data['category'] ?? 'Magazine',
          publishedDate: publishedDate,
          isNew: _isNewMagazine(publishedDate),
          isProtected: data['is_protected'] ?? false,
          tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
        );
      }).toList();

      setState(() {
        magazines = loadedMagazines;
        isLoading = false;
      });
    } catch (e) {
      // debugPrint('Error loading magazines: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load magazines: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to determine if a magazine is new (published within last 30 days)
  bool _isNewMagazine(DateTime publishedDate) {
    final now = DateTime.now();
    final difference = now.difference(publishedDate).inDays;
    return difference <= 30;
  }

  void _openMagazine(Magazine magazine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MagazineReaderScreen(magazine: magazine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          Service.capitalizeFirstLetters(widget.title ?? 'Z - Magazines'),
          style: TextStyle(
            color: kBlackColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFED2437)),
              )
            : magazines.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 64,
                      color: kGreyColor,
                    ),
                    SizedBox(height: getProportionateScreenHeight(16)),
                    Text(
                      'No magazines available',
                      style: TextStyle(color: kGreyColor, fontSize: 16),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding),
                  vertical: getProportionateScreenHeight(kDefaultPadding),
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: getProportionateScreenWidth(
                    kDefaultPadding,
                  ),
                  mainAxisSpacing: getProportionateScreenHeight(
                    kDefaultPadding,
                  ),
                  childAspectRatio: 0.65,
                ),
                itemCount: magazines.length,
                itemBuilder: (context, index) {
                  final magazine = magazines[index];
                  return MagazineCard(
                    magazine: magazine,
                    onTap: () => _openMagazine(magazine),
                  );
                },
              ),
      ),
    );
  }
}
