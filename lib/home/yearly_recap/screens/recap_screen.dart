import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:zmall/home/yearly_recap/models/wrapped_data.dart';
import 'package:zmall/home/yearly_recap/service/recap_service.dart';
import 'package:zmall/home/yearly_recap/widgets/story_slide_widget.dart';
import 'package:zmall/home/yearly_recap/widgets/progress_bars.dart';
import 'package:zmall/home/yearly_recap/widgets/confetti_widget.dart'
    as recap_confetti;
import 'package:zmall/services/service.dart';

class RecapScreen extends StatefulWidget {
  final String userId;
  final String serverToken;
  final dynamic recapData;

  const RecapScreen({
    super.key,
    required this.userId,
    this.recapData,
    required this.serverToken,
  });

  @override
  State<RecapScreen> createState() => _YearWrappedStoriesState();
}

class _YearWrappedStoriesState extends State<RecapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  DateTime today = DateTime.now();
  int currentStoryIndex = 0;
  late AnimationController _progressController;
  late AnimationController _slideController;
  // late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  YearWrappedData? wrappedData;
  bool isLoading = true;
  List<StorySlide> stories = [];
  bool hasReachedEnd = false;
  bool isPaused = false;
  bool wasPlayingBeforeBackground = false;

  final ScreenshotController screenshotController = ScreenshotController();
  final ScreenshotController summaryScreenshotController =
      ScreenshotController();
  final audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _loadWrappedData();

    // Start the player as soon as the app is displayed.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        audioPlayer.setLoopMode(LoopMode.all);
        await audioPlayer.setAsset('assets/audio/zmall.mp3');
        await audioPlayer.play();
      } catch (e) {
        // debugPrint('Error initializing audio: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App went to background (user shared to social media or switched apps)
        if (audioPlayer.playing) {
          wasPlayingBeforeBackground = true;
          audioPlayer.pause();
          // debugPrint('Audio paused - app in background');
        }
        break;

      case AppLifecycleState.resumed:
        // App came back to foreground
        if (wasPlayingBeforeBackground && !audioPlayer.playing) {
          audioPlayer.play();
          wasPlayingBeforeBackground = false;
          // debugPrint('Audio resumed - app in foreground');
        }
        break;

      case AppLifecycleState.inactive:
        // App is transitioning (e.g., sharing dialog)
        // Don't do anything here, wait for paused state
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being destroyed or hidden
        break;
    }
  }

  // Helper method to get the correct recap year
  // Shows current year during Dec 15 - Jan 31 transition period
  // Otherwise shows previous year
  int getRecapYear() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final currentDay = now.day;

    // If we're in late December (Dec 15-31), show current year
    if (currentMonth == 12 && currentDay >= 15) {
      return currentYear;
    }
    // If we're in early January (Jan 1-31), show previous year
    else if (currentMonth == 1) {
      return currentYear - 1;
    }
    // For all other months (Feb-Nov), show previous year
    else {
      return currentYear - 1;
    }
  }

  Future<void> _toggleMusic() async {
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play();
    }
  }

  void _initializeControllers() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
    //   CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    // );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _progressController.addListener(() {
      if (_progressController.isCompleted && !hasReachedEnd) {
        _nextStory();
      }
    });
  }

  Future<void> _loadWrappedData() async {
    setState(() => isLoading = true);
    // debugPrint("data: ${widget.recapData}");
    YearWrappedData? data;
    // Use provided recapData if available, otherwise fall back to mock data
    if (widget.recapData != null) {
      try {
        data = YearWrappedData.fromJson(widget.recapData);
      } catch (e) {
        // debugPrint('Error parsing recapData: $e');
        // Fall back to mock data on error
        // data = await WrappedApiService.getMockData();
      }
    } else {
      // No recapData provided, use mock data
      // data = await WrappedApiService.getMockData();
    }
    YearWrappedData noData = YearWrappedData(
      userId: '',
      year: getRecapYear(),
      totalOrders: 0,
      totalSpent: 0,
      rewardsEarned: 0,
      favoriteCategory: '',
      favoriteCategoryEmoji: '',
      mostActiveMonth: '',
      biggestOrderAmount: 0,
      funFact: '',
      topRestaurant: '',
      restaurantOrderCount: 0,
      topRestaurants: [],
      topDishes: [],
      longestStreak: '',
      monthlyOrders: {},
      personalizedMessage: '',
    );
    setState(() {
      wrappedData = data ?? noData;
      stories = _generateStories(data ?? noData);
      isLoading = false;
    });
    RecapService.trackRecapOpened(
      context: context,
      userId: widget.userId,
      year: wrappedData!.year,
      serverToken: widget.serverToken,
    );
    _startStory();
  }

  List<StorySlide> _generateStories(YearWrappedData data) {
    List<Color> gradient = [const Color(0xFFED2437), const Color(0xFFc91f2f)];

    // If user has 0 orders, show only welcome and "try next year" message
    if (data.totalOrders == 0) {
      return [
        StorySlide(
          type: 'welcome',
          title: 'Your ${getRecapYear()}\nWrapped',
          subtitle: 'Let\'s look back at your\nZMall journey',
          gradient: [const Color(0xFF0f0f23), const Color(0xFF1a1a2e)],
          useLogo: true,
        ),
        StorySlide(
          type: 'no_orders',
          title: 'No Orders Yet',
          subtitle: 'Start your ZMall journey\nand come back next year!',
          gradient: gradient,
          emoji: '🧺',
          // emoji: '🛒',
        ),
        StorySlide(
          type: 'thankyou',
          title: 'See You Soon!',
          subtitle: 'We can\'t wait to serve you! 🎉',
          gradient: gradient,
          emoji: '👋',
        ),
      ];
    }

    // Regular stories for users with orders
    return [
      // 120 Orders Delivered Successfully
      // ETB 3.3k Rewards Earned from ZMall //wallet earnings
      // Your Favorite Food Category //most ordered product
      // Your Top 3 Most Ordered Restaurant
      // Your Most Active Month //mostly ordered month
      // 12 days Longest Ordering Streak
      // Funfact you triied 23 new restorants this year
      StorySlide(
        type: 'welcome',
        title: 'Your ${getRecapYear()}\nWrapped',
        subtitle: 'Let\'s look back at your\nZMall journey',
        gradient: [const Color(0xFF0f0f23), const Color(0xFF1a1a2e)],
        useLogo: true,
      ),
      StorySlide(
        type: 'stat',
        title: '${data.totalOrders}',
        subtitle: 'Orders Delivered\nSuccessfully',
        gradient: gradient,
        icon: Icons.shopping_bag_outlined,
        showConfetti: true,
      ),
      StorySlide(
        type: 'stat',
        title: 'Birr ${_formatNumber(data.rewardsEarned)}',
        subtitle: 'Rewards Earned\nfrom ZMall',
        gradient: gradient,
        icon: Icons.card_giftcard,
        showConfetti: true,
      ),
      StorySlide(
        type: 'category',
        title: Service.capitalizeFirstLetters(data.favoriteCategory),
        subtitle: 'Your Favorite\nFood Category',
        gradient: gradient,
        emoji: data.favoriteCategoryEmoji,
        showConfetti: true,
      ),
      // Top 3 Restaurants slide
      StorySlide(
        type: 'top_restaurants',
        title: 'Your Top\nRestaurants',
        subtitle: 'Most ordered from',
        gradient: gradient,
        data: data.topRestaurants,
        showConfetti: true,
      ),
      StorySlide(
        type: 'month',
        title: data.mostActiveMonth,
        subtitle: 'Your Most\nActive Month',
        gradient: gradient,
        icon: Icons.calendar_month,
        showConfetti: true,
      ),
      // StorySlide(
      //   type: 'stat',
      //   title: 'ETB${_formatNumber(data.biggestOrderAmount)}',
      //   subtitle: 'Your Biggest\nOrder',
      //   gradient: gradient,
      //   icon: Icons.shopping_cart,
      //   showConfetti: true,
      // ),
      StorySlide(
        type: 'funfact',
        title: 'Fun Fact!',
        subtitle: data.funFact,
        gradient: gradient,
        emoji: '🎉',
        showConfetti: true,
      ),
      StorySlide(
        type: 'streak',
        title: data.longestStreak,
        subtitle: 'Longest Ordering\nStreak',
        gradient: gradient,
        icon: Icons.local_fire_department,
        emoji: '🔥',
        showConfetti: true,
      ),
      StorySlide(
        type: 'thankyou',
        title: 'Thank You!',
        subtitle: data.personalizedMessage,
        gradient: gradient,
        // [const Color(0xFFED2437), const Color(0xFFdb2777)],
        emoji: '❤️',
        showShare: true,
      ),
    ];
  }

  String _formatNumber(double number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  void _startStory() {
    _slideController.forward(from: 0);
    if (!hasReachedEnd) {
      _progressController.forward(from: 0);
    }
  }

  void _nextStory() {
    if (currentStoryIndex < stories.length - 1) {
      setState(() => currentStoryIndex++);
      _progressController.reset();
      _slideController.reset();
      _startStory();
    } else {
      setState(() {
        hasReachedEnd = true;
        _progressController.stop();
      });
    }
  }

  void _previousStory() {
    if (currentStoryIndex > 0) {
      setState(() {
        currentStoryIndex--;
        hasReachedEnd = false;
      });
      _progressController.reset();
      _slideController.reset();
      _startStory();
    }
  }

  void _pauseStory() {
    _progressController.stop();
    setState(() => isPaused = true);
  }

  void _resumeStory() {
    if (!hasReachedEnd) {
      _progressController.forward();
    }
    setState(() => isPaused = false);
  }

  void _exitStories() {
    audioPlayer.stop();
    Navigator.of(context).pop();
  }

  void _restartStories() {
    setState(() {
      currentStoryIndex = 0;
      hasReachedEnd = false;
    });
    _progressController.reset();
    _slideController.reset();
    audioPlayer.seek(Duration.zero);
    audioPlayer.play();
    _startStory();
  }

  Future<void> _shareWrapped() async {
    if (wrappedData == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFED2437)),
        ),
      );

      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/zmall_story_${today.millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);

        Navigator.of(context).pop();

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath)],
            text:
                '🎉 My ZMall Year Wrapped ${wrappedData?.year ?? getRecapYear()}! Order smarter with ZMall! 🚀',
          ),
        );

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Story shared! 🎉'),
        //     backgroundColor: Color(0xFFED2437),
        //   ),
        // );
      }
    } catch (e) {
      Navigator.of(context).pop();
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      // );
    }
  }

  // FIXED: Share to Instagram (Summary)
  Future<void> _shareToInstagram() async {
    if (wrappedData == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFED2437)),
        ),
      );

      final Uint8List? imageBytes = await summaryScreenshotController.capture(
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/zmall_wrapped_summary_${today.millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);

        Navigator.of(context).pop();

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath)],
            text:
                '🎉 My ZMall Year Wrapped ${wrappedData?.year ?? getRecapYear()}! Order smarter with ZMall! 🚀',
          ),
        );

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Share to Instagram Story! 🎉'),
        //     backgroundColor: Color(0xFFED2437),
        //   ),
        // );
      }
    } catch (e) {
      Navigator.of(context).pop();
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      // );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    _slideController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          if (!hasReachedEnd) {
            final screenWidth = MediaQuery.of(context).size.width;
            final tapPosition = details.globalPosition.dx;

            // Divide screen into 3 sections: left (30%), center (40%), right (30%)
            if (tapPosition < screenWidth * 0.3) {
              // Left tap - previous story
              if (!isPaused) _previousStory();
            } else if (tapPosition > screenWidth * 0.7) {
              // Right tap - next story
              if (!isPaused) _nextStory();
            } else {
              // Center tap - toggle pause
              if (isPaused) {
                _resumeStory();
              } else {
                _pauseStory();
              }
            }
          }
        },
        child: Stack(
          children: [
            // Screenshot-able content (without UI buttons)
            Screenshot(
              controller: screenshotController,
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    StorySlideWidget(
                      key: ValueKey(currentStoryIndex),
                      story: stories[currentStoryIndex],
                      onTap: () {},
                    ),
                    if (stories[currentStoryIndex].showConfetti)
                      const recap_confetti.RecapConfettiWidget(),
                  ],
                ),
              ),
            ),

            if (!hasReachedEnd)
              SafeArea(
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return ProgressBars(
                      storyCount: stories.length,
                      currentIndex: currentStoryIndex,
                      progress: _progressController.value,
                    );
                  },
                ),
              ),

            // FIXED: Top left close button
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _exitStories,
                  ),
                ),
              ),
            ),
            // Restart button
            if (hasReachedEnd && currentStoryIndex == stories.length - 1)
              Positioned(
                top: 16,
                right: 80,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.replay, color: Colors.white, size: 24),
                      onPressed: _restartStories,
                    ),
                  ),
                ),
              ),
            // FIXED: Top right buttons
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          audioPlayer.playing
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _toggleMusic,
                      ),
                    ),
                    if (!hasReachedEnd && (wrappedData?.totalOrders ?? 0) > 0)
                      Container(
                        // decoration: BoxDecoration(
                        // color: const Color(0xFFED2437),
                        // borderRadius: BorderRadius.circular(12),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: const Color(
                        //       0xFFED2437,
                        //     ).withValues(alpha: 0.3),
                        //     blurRadius: 12,
                        //     offset: const Offset(0, 4),
                        //   ),
                        // ],
                        // ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _shareWrapped,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Instagram Share button on last slide
            if (hasReachedEnd &&
                currentStoryIndex == stories.length - 1 &&
                (wrappedData?.totalOrders ?? 0) > 0)
              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _shareToInstagram,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF833AB4),
                                Color(0xFFFD1D1D),
                                Color(0xFFFCAF45),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF833AB4,
                                ).withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FontAwesomeIcons.instagram,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Share to Instagram Story',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // const SizedBox(height: 16),
                      // Text(
                      //   'Tap here to share your Wrapped! 🎉',
                      //   style: TextStyle(
                      //     color: Colors.white.withValues(alpha: 0.7),
                      //     fontSize: 14,
                      //   ),
                      // ),
                      // const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

            if (currentStoryIndex == 0 && !hasReachedEnd)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _fadeAnimation.value,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            color: Colors.white54,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white54,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tap sides',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.pause_circle_outline,
                            color: Colors.white54,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tap center',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Off-screen summary widget for Instagram share
            Positioned(
              left: -10000,
              child: Screenshot(
                controller: summaryScreenshotController,
                child: _buildSummaryWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryWidget() {
    if (wrappedData == null) return const SizedBox();

    // Calculate decorative elements: (total stories - welcome - thankyou) * 6
    final int decorativeCount = (stories.length - 2) * 6;

    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0f0f23), Color(0xFF1a1a2e), Color(0xFFED2437)],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(decorativeCount, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * 1080,
              top: random.nextDouble() * 1920,
              child: Container(
                width: 8,
                height: 12,
                decoration: BoxDecoration(
                  color: [
                    const Color(0xFFED2437),
                    const Color(0xFFf59e0b),
                    const Color(0xFF10b981),
                    const Color(0xFF3b82f6),
                    const Color(0xFF8b5cf6),
                  ][random.nextInt(5)],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFED2437).withValues(alpha: 0.5),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Image.asset('images/zmall.jpg', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'MY ${wrappedData!.year} WRAPPED',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 60),

                _buildStatRow('📦', '${wrappedData!.totalOrders}', 'Orders'),
                _buildStatRow(
                  '🎁',
                  'ETB${_formatNumber(wrappedData!.rewardsEarned)}',
                  'Rewards',
                ),
                _buildStatRow(
                  '${wrappedData!.favoriteCategoryEmoji}',
                  wrappedData!.favoriteCategory,
                  'Favorite',
                ),
                _buildStatRow('🍽️', wrappedData!.topRestaurant, 'Top Spot'),
                _buildStatRow(
                  '📅',
                  wrappedData!.mostActiveMonth,
                  'Most Active',
                ),
                // Commented out - API doesn't provide biggest order amount
                // _buildStatRow(
                //   '🛒',
                //   'Birr${_formatNumber(wrappedData!.biggestOrderAmount)}',
                //   'Biggest Order',
                // ),
                _buildStatRow('🔥', wrappedData!.longestStreak, 'Streak'),

                const SizedBox(height: 60),

                const Text(
                  'Order smarter with ZMall! 🚀',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String emoji, String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
