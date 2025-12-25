import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/home/yearly_recap/models/wrapped_data.dart';

class StorySlideWidget extends StatefulWidget {
  final StorySlide story;
  final VoidCallback onTap;

  const StorySlideWidget({super.key, required this.story, required this.onTap});

  @override
  State<StorySlideWidget> createState() => _StorySlideWidgetState();
}

class _StorySlideWidgetState extends State<StorySlideWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.story.gradient,
        ),
      ),
      child: Stack(
        children: [
          // Animated background patterns
          _buildBackgroundPattern(),

          // Main content
          SafeArea(
            bottom: false,
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                          ).copyWith(bottom: kDefaultPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo or Icon or Emoji or Image
                              if (widget.story.useLogo)
                                _buildLogo()
                              else if (widget.story.imageUrl != null)
                                _buildImage()
                              else if (widget.story.emoji != null)
                                _buildEmoji()
                              else if (widget.story.icon != null)
                                _buildIcon(),

                              const SizedBox(height: 40),

                              // Title
                              _buildTitle(),

                              const SizedBox(height: 24),

                              // Subtitle
                              _buildSubtitle(),

                              // Additional data or Top Restaurants
                              if (widget.story.type == 'top_restaurants' &&
                                  widget.story.data != null)
                                _buildTopRestaurants()
                              else if (widget.story.data != null)
                                _buildAdditionalData(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // TikTok-style watermark logo at bottom-right
          Positioned(
            top: kDefaultPadding * 5,
            left: MediaQuery.sizeOf(context).width * 0.27,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value * 0.85,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Image.asset(
                        'images/zmall_white.png',
                        width: 140,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPatternPainter(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget _buildEmoji() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.story.emoji),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Text(
            widget.story.emoji!,
            style: const TextStyle(fontSize: 120, height: 1),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      key: ValueKey('logo_${widget.story.title}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 180,
            height: 180,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFED2437).withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Image.asset('images/zmall.jpg', fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.story.icon),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(widget.story.icon, size: 80, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildImage() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.story.imageUrl),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFED2437).withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.story.imageUrl!,
                fit: BoxFit.fill,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) {
                  // Fallback to icon if image fails to load
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.story.title),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Text(
              widget.story.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.story.title.length > 10 ? 48 : 72,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.story.subtitle),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Text(
              widget.story.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdditionalData() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.story.data),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(top: 32),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.story.data.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopRestaurants() {
    final restaurants = widget.story.data as List;

    return TweenAnimationBuilder<double>(
      key: ValueKey('top_restaurants'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              margin: const EdgeInsets.only(top: 40),
              child: Column(
                children: List.generate(
                  restaurants.length > 3 ? 3 : restaurants.length,
                  (index) {
                    final restaurant = restaurants[index];
                    return _buildRestaurantCard(restaurant, index, value);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(
    dynamic restaurant,
    int index,
    double animationValue,
  ) {
    final delay = index * 0.15;
    final cardAnimation = (animationValue - delay).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, 30 * (1 - cardAnimation)),
      child: Opacity(
        opacity: cardAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              // Restaurant image
              ClipOval(
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: restaurant.storeImage != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant.storeImage!,
                          fit: BoxFit.fill,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 40,
                          ),
                        )
                      : const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 40,
                        ),
                ),
              ),
              const SizedBox(width: 20),

              // Restaurant name
              Expanded(
                child: Text(
                  restaurant.storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw animated circles
    for (var i = 0; i < 5; i++) {
      final radius = size.width * (0.3 + i * 0.2);
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint,
      );
    }

    // Draw decorative lines
    for (var i = 0; i < 8; i++) {
      final y = size.height * (i / 8);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * 0.15, y),
        paint..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
