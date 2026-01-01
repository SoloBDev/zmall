import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:page_flip/page_flip.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:zmall/home/magazine/models/magazine_model.dart';
import 'package:zmall/home/magazine/services/magazine_service.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/constants.dart';

class MagazineReaderScreen extends StatefulWidget {
  final Magazine magazine;

  const MagazineReaderScreen({super.key, required this.magazine});

  @override
  State<MagazineReaderScreen> createState() => _MagazineReaderScreenState();
}

class _MagazineReaderScreenState extends State<MagazineReaderScreen> {
  late PdfDocument _pdfDocument;
  final _pageFlipController = GlobalKey<PageFlipWidgetState>();
  int currentPage = 1;
  int totalPages = 0;
  bool isLoading = true;
  String? errorMessage;
  bool isWebFlipbook = false;

  // Cache for preloaded pages
  Map<int, PdfPageImage> _pageCache = {};

  // WebView controller
  InAppWebViewController? webViewController;
  double webViewProgress = 0;

  // Track page turns to hide hint
  int pageTurnCount = 0;
  bool showNavigationHint = true;

  // Screenshot prevention method channel
  static const platform = MethodChannel('com.zmall.user/security');

  @override
  void initState() {
    super.initState();

    // Track magazine view
    _trackMagazineView();

    // Check if URL is a web-based flipbook (e.g., Heyzine, FlipHTML5, etc.)
    isWebFlipbook = _isWebBasedFlipbook(widget.magazine.pdfUrl);

    // Only enable screenshot prevention if magazine is protected
    if (widget.magazine.isProtected) {
      _enableScreenshotPrevention();
    }

    if (isWebFlipbook) {
      setState(() {
        isLoading = false;
      });
    } else {
      _initializePdf();
    }
  }

  // Track magazine view
  Future<void> _trackMagazineView() async {
    try {
      // Get user data
      final userData = await Service.read('user');
      if (userData == null) return;

      final magazineViews =
          userData['user']['magazine_views'] as Map<String, dynamic>?;
      final hasAlreadyViewed = magazineViews?[widget.magazine.id] == true;

      // Only track view if not already viewed
      if (!hasAlreadyViewed) {
        await MagazineService.updateUserMagazineInteraction(
          context: context,
          interactionType: 'view',
          year: DateTime.now().year,
          magazineId: widget.magazine.id,
          userId: userData['user']['_id'],
          serverToken: userData['user']['server_token'],
        );

        debugPrint('Magazine view tracked for: ${widget.magazine.title}');
      } else {
        debugPrint(
          'Magazine already viewed, skipping view tracking: ${widget.magazine.title}',
        );
      }
    } catch (e) {
      debugPrint('Error tracking magazine view: $e');
      // Don't show error to user, just log it
    }
  }

  // Check if URL is a web-based flipbook
  bool _isWebBasedFlipbook(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Check if URL ends with .pdf - if so, it's not a web flipbook
    if (url.toLowerCase().endsWith('.pdf')) {
      return false;
    }

    // Check for common flipbook hosting domains
    final flipbookDomains = [
      'heyzine.com',
      'fliphtml5.com',
      'issuu.com',
      'flipsnack.com',
      'yumpu.com',
      'calameo.com',
      'anyflip.com',
      'publuu.com',
      'google.com', // Google Docs/Workspace
      'docs.google.com',
      'workspace.google.com',
    ];

    // If it matches known flipbook domains or patterns, it's a web flipbook
    final matchesFlipbookDomain = flipbookDomains.any(
      (domain) => uri.host.contains(domain),
    );
    final matchesFlipbookPattern =
        url.contains('/flip-book/') ||
        url.contains('/flipbook/') ||
        url.contains('/magazine/');

    // If URL doesn't end with .pdf and matches domains/patterns, treat as web flipbook
    // Also, if URL is an http/https link but not a PDF, treat as web flipbook by default
    return matchesFlipbookDomain ||
        matchesFlipbookPattern ||
        (uri.scheme.startsWith('http') && !url.toLowerCase().endsWith('.pdf'));
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

      // Check if URL ends with .pdf
      final isPdfUrl = widget.magazine.pdfUrl.toLowerCase().endsWith('.pdf');
      if (!isPdfUrl) {
        throw Exception(
          'URL is not a PDF file. Please use a valid PDF URL or web flipbook URL.',
        );
      }

      final response = await http.get(Uri.parse(widget.magazine.pdfUrl));

      if (response.statusCode == 200) {
        // Check if response is actually a PDF
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.contains('pdf') && response.bodyBytes.length < 100) {
          throw Exception('Downloaded file is not a valid PDF');
        }

        // Load PDF from downloaded bytes
        debugPrint('PDF loaded successfully from network');
        return await PdfDocument.openData(response.bodyBytes);
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } else {
      throw Exception('No PDF URL provided');
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
    // Clear the page cache to prevent using closed document
    _pageCache.clear();
    if (!isLoading && errorMessage == null && !isWebFlipbook) {
      _pdfDocument.close();
    }
    super.dispose();
  }

  Widget _buildWebFlipbook() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.magazine.pdfUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            supportZoom: true,
            useOnLoadResource: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            transparentBackground: true,
            disableHorizontalScroll: false,
            disableVerticalScroll: false,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(() {
              webViewProgress = 0;
            });
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              webViewProgress = progress / 100;
            });
          },
          onLoadStop: (controller, url) async {
            setState(() {
              webViewProgress = 1;
            });
          },
          onReceivedError: (controller, request, error) {
            setState(() {
              errorMessage =
                  'Failed to load magazine.\nPlease check your connection.';
            });
          },
        ),
        // Loading progress bar
        if (webViewProgress < 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: webViewProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFED2437),
              ),
            ),
          ),
        // Protected content indicator
        if (widget.magazine.isProtected)
          Positioned(
            top: 20,
            right: kDefaultPadding,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 12, color: Colors.white70),
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
      ],
    );
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        // Track page turns and hide hint after 3 turns
        pageTurnCount++;
        if (pageTurnCount >= 3) {
          showNavigationHint = false;
        }
      });
      _pageFlipController.currentState?.goToPage(currentPage - 1); // 0-indexed
      _prefetchSurroundingPages(currentPage);
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
        // Track page turns and hide hint after 3 turns
        pageTurnCount++;
        if (pageTurnCount >= 3) {
          showNavigationHint = false;
        }
      });
      _pageFlipController.currentState?.goToPage(currentPage - 1); // 0-indexed
      _prefetchSurroundingPages(currentPage);
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

  // Build a single page for the flip widget
  Widget _buildPage(int pageNumber) {
    final cachedPage = _pageCache[pageNumber];

    return VisibilityDetector(
      key: Key('page_$pageNumber'),
      onVisibilityChanged: (info) {
        // Update current page when this page becomes visible (>50% visible)
        if (info.visibleFraction > 0.5 && mounted) {
          Future.microtask(() {
            if (mounted && currentPage != pageNumber) {
              setState(() {
                currentPage = pageNumber;
                // Track page turns for hint hiding
                pageTurnCount++;
                if (pageTurnCount >= 3) {
                  showNavigationHint = false;
                }
              });
              _prefetchSurroundingPages(currentPage);
            }
          });
        }
      },
      child: Container(
        color: Colors.white, // Background color
        child: cachedPage != null
            ? Image.memory(
                cachedPage.bytes,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
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

                    return Image.memory(
                      snapshot.data!.bytes,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading page $pageNumber',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
      // backgroundColor: kPrimaryColor,
      // isLoading ? Colors.white : Colors.black,
      appBar: AppBar(
        // backgroundColor: kPrimaryColor,
        // isLoading ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: kBlackColor,
            // isLoading ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.magazine.title,
          style: TextStyle(
            color: kBlackColor,
            // isLoading ? Colors.black : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isWebFlipbook
            ? errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: kBlackColor,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFED2437),
                              ),
                              child: const Text(
                                'Go Back',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildWebFlipbook()
            : isLoading
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
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: kBlackColor,
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
                    child: PageFlipWidget(
                      key: _pageFlipController,
                      backgroundColor: Colors.transparent,
                      lastPage: Container(
                        color: const Color(0xFFFFFCF5),
                        child: const Center(
                          child: Text(
                            'End of Magazine',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      children: List.generate(
                        totalPages,
                        (index) => _buildPage(index + 1),
                      ),
                    ),
                  ),

                  // Page indicator overlay
                  Positioned(
                    bottom: kDefaultPadding,
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
                      top: 20,
                      right: kDefaultPadding,
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
                            Icon(Icons.lock, size: 12, color: Colors.white70),
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

                  // Navigation hints (hide after 3 page turns)
                  if (showNavigationHint)
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: showNavigationHint ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
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
                    ),
                ],
              ),
      ),
    );
  }
}
