import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:zmall/home/magazine/models/magazine_model.dart';
import 'package:zmall/utils/constants.dart';

class MagazineReaderScreen extends StatefulWidget {
  final Magazine magazine;

  const MagazineReaderScreen({super.key, required this.magazine});

  @override
  State<MagazineReaderScreen> createState() => _MagazineReaderScreenState();
}

class _MagazineReaderScreenState extends State<MagazineReaderScreen> {
  late PdfDocument _pdfDocument;
  late PageController _pageController;
  int currentPage = 1;
  int totalPages = 0;
  bool isLoading = true;
  String? errorMessage;

  // Cache for preloaded pages
  Map<int, PdfPageImage> _pageCache = {};

  // Screenshot prevention method channel
  static const platform = MethodChannel('com.zmall.user/security');

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Only enable screenshot prevention if magazine is protected
    if (widget.magazine.isProtected) {
      _enableScreenshotPrevention();
    }
    _initializePdf();
  }

  // Enable screenshot prevention
  Future<void> _enableScreenshotPrevention() async {
    try {
      await platform.invokeMethod('disableScreenshot');
      debugPrint('Screenshot prevention enabled for protected magazine');
    } catch (e) {
      debugPrint('Screenshot prevention not available: $e');
    }
  }

  // Disable screenshot prevention when leaving
  Future<void> _disableScreenshotPrevention() async {
    // Only disable if magazine was protected
    if (!widget.magazine.isProtected) return;

    try {
      await platform.invokeMethod('enableScreenshot');
      debugPrint('Screenshot prevention disabled');
    } catch (e) {
      debugPrint('Could not re-enable screenshot: $e');
    }
  }

  Future<PdfDocument> _loadPdfDocument() async {
    // Load PDF from network URL or asset
    if (widget.magazine.pdfUrl.isNotEmpty) {
      // Download PDF from network
      debugPrint('Loading PDF from: ${widget.magazine.pdfUrl}');
      final response = await http.get(Uri.parse(widget.magazine.pdfUrl));

      if (response.statusCode == 200) {
        // Load PDF from downloaded bytes
        debugPrint('PDF loaded successfully from network');
        return await PdfDocument.openData(response.bodyBytes);
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } else {
      // Load from assets as fallback
      return await PdfDocument.openAsset('assets/sample_magazine.pdf');
    }
  }

  void _initializePdf() async {
    try {
      // Get total pages from the actual document
      _pdfDocument = await _loadPdfDocument();
      final pageCount = await _pdfDocument.pagesCount;

      if (!mounted) return;

      setState(() {
        totalPages = pageCount;
      });

      debugPrint('Magazine loaded: $totalPages pages');

      // Preload first few pages only
      await _preloadInitialPages();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('Initial pages preloaded successfully');
    } catch (e) {
      debugPrint('Error loading magazine: $e');
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Failed to load magazine.\nPlease check your internet connection and try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _preloadInitialPages() async {
    try {
      // Preload first 5 pages for quick start
      final pagesToPreload = totalPages < 5 ? totalPages : 5;
      for (int i = 1; i <= pagesToPreload; i++) {
        final pageImage = await _renderPage(i);
        if (pageImage != null) {
          _pageCache[i] = pageImage;
          debugPrint('Preloaded page $i');
        }
      }
    } catch (e) {
      debugPrint('Error preloading initial pages: $e');
    }
  }

  Future<void> _prefetchSurroundingPages(int currentPage) async {
    // Prefetch 3 pages before and 3 pages after current page
    final pagesToPrefetch = <int>[];

    for (int i = currentPage - 3; i <= currentPage + 3; i++) {
      if (i > 0 && i <= totalPages && !_pageCache.containsKey(i)) {
        pagesToPrefetch.add(i);
      }
    }

    // Load pages in background without blocking UI
    for (final pageNum in pagesToPrefetch) {
      final pageImage = await _renderPage(pageNum);
      if (pageImage != null && mounted) {
        setState(() {
          _pageCache[pageNum] = pageImage;
        });
        debugPrint('Prefetched page $pageNum');
      }
    }
  }

  @override
  void dispose() {
    _disableScreenshotPrevention();
    _pageController.dispose();
    if (!isLoading && errorMessage == null) {
      _pdfDocument.close();
    }
    super.dispose();
  }

  void _previousPage() {
    if (currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic, // Smoother, more book-like curve
      );
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic, // Smoother, more book-like curve
      );
    }
  }

  Future<PdfPageImage?> _renderPage(int pageNumber) async {
    try {
      final page = await _pdfDocument.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      return pageImage;
    } catch (e) {
      debugPrint('Error rendering page $pageNumber: $e');
      return null;
    }
  }

  Widget _buildPageWithFlipEffect(int index) {
    double value = 0.0;

    if (_pageController.position.haveDimensions) {
      value = (_pageController.page ?? 0) - index;
    }

    // Clamp value between -1 and 1
    value = value.clamp(-1.0, 1.0);

    final pageNumber = index + 1;
    final cachedPage = _pageCache[pageNumber];

    // More realistic book page turn effect
    final double rotationAngle = value * math.pi; // Full 180-degree rotation
    final bool isFlippingForward = value < 0;
    final double absValue = value.abs();

    // Apply perspective and rotation for 3D effect
    Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.002) // Stronger perspective for depth
      ..rotateY(rotationAngle);

    // Add slight scaling during flip for realism
    final double scaleValue = 1.0 - (absValue * 0.1);
    transform = Matrix4.diagonal3Values(scaleValue, scaleValue, 1.0) *
        transform;

    return Transform(
      transform: transform,
      alignment: isFlippingForward
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Stack(
        children: [
          // The page content
          cachedPage != null
              ? Center(
                  child: Image.memory(
                    cachedPage.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cannot display page $pageNumber',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : FutureBuilder<PdfPageImage?>(
                  future: _renderPage(pageNumber),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED2437),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      // Cache the page after rendering
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _pageCache[pageNumber] = snapshot.data!;
                          });
                        }
                      });

                      return Center(
                        child: Image.memory(
                          snapshot.data!.bytes,
                          fit: BoxFit.contain,
                        ),
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white54,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading page $pageNumber',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          // Shadow overlay during page flip for depth effect
          if (absValue > 0.05)
            Container(color: Colors.black.withValues(alpha: absValue * 0.3)),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Simulating a realistic magazine page
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Magazine header/title
                      Container(
                        height: 32,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 20,
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Featured image placeholder
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Text content lines
                      ...List.generate(
                        6,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            height: 12,
                            width: index == 5
                                ? MediaQuery.of(context).size.width * 0.3
                                : double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Secondary image placeholder
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Page number at bottom
                      Center(
                        child: Container(
                          height: 16,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Page indicator placeholder
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isLoading ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isLoading ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isLoading ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.magazine.title,
          style: TextStyle(
            color: isLoading ? Colors.black : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingShimmer()
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                          backgroundColor: const Color(0xFFED2437),
                        ),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  // PDF Viewer with page flip effect
                  GestureDetector(
                    onTapUp: (details) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final tapPosition = details.globalPosition.dx;

                      if (tapPosition < screenWidth / 2) {
                        _previousPage();
                      } else {
                        _nextPage();
                      }
                    },
                    child: Container(
                      color: Colors.black,
                      child: AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          return PageView.builder(
                            controller: _pageController,
                            itemCount: totalPages,
                            onPageChanged: (page) {
                              setState(() => currentPage = page + 1);
                              // Prefetch surrounding pages in background
                              _prefetchSurroundingPages(page + 1);
                            },
                            itemBuilder: (context, index) {
                              return _buildPageWithFlipEffect(index);
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Page indicator overlay
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$currentPage / $totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Protected content indicator
                  if (widget.magazine.isProtected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 12,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PROTECTED',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Navigation hints (show on first page)
                  if (currentPage == 1)
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white70,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tap left or right to turn pages',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
