import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zmall/home/magazine/models/magazine_model.dart';
import 'package:zmall/home/magazine/services/magazine_service.dart';
import 'package:zmall/home/magazine/widgets/magazine_card.dart';
import 'package:zmall/home/magazine/screens/magazine_reader_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/services/core_services.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class MagazineListScreen extends StatefulWidget {
  final String? userId;
  final String? title;
  final dynamic userData;
  final String? serverToken;
  final bool isGlobalUser;
  final String? globalUserName;
  final String? globalUserEmail;
  const MagazineListScreen({
    super.key,
    this.title,
    this.userId,
    this.userData,
    this.serverToken,
    this.isGlobalUser = false,
    this.globalUserName,
    this.globalUserEmail,
  });

  @override
  State<MagazineListScreen> createState() => _MagazineListScreenState();
}

class _MagazineListScreenState extends State<MagazineListScreen> {
  List<Magazine> magazines = [];
  bool isLoading = true;
  var updatedUsserData;

  @override
  void initState() {
    super.initState();
    _fetchMagazinesFromAPI();
  }

  Future<void> _onRefresh() async {
    await _fetchMagazinesFromAPI();
  }

  Future<void> _fetchMagazinesFromAPI() async {
    setState(() => isLoading = true);

    try {

      final effectiveUserId = widget.isGlobalUser
          ? (widget.globalUserEmail ?? 'global_user')
          : widget.userId ?? '';
      final effectiveServerToken = widget.isGlobalUser
          ? 'global_user_token'
          : widget.serverToken ?? '';

      final fetchedMagazines = await MagazineService.fetchMagazines(
        userId: effectiveUserId,
        serverToken: effectiveServerToken,
        context: context,
        isGlobalUser: widget.isGlobalUser,
      );

      debugPrint('Fetched ${fetchedMagazines.length} magazines');

      // Get user data to check liked magazines
      final userData = await Service.read('user');
      final magazineLikes =
          userData?['user']['magazine_likes'] as Map<String, dynamic>?;

      // Update magazines with liked status from user data
      final updatedMagazines = fetchedMagazines.map((magazine) {
        final hasLiked = magazineLikes?[magazine.id] == true;
        return magazine.copyWith(
          userEngagement: magazine.userEngagement.copyWith(hasLiked: hasLiked),
        );
      }).toList();

      setState(() {
        magazines = updatedMagazines;
        isLoading = false;
      });
    } catch (e) {
      //debugPrint('Error fetching magazines: $e');
      setState(() => isLoading = false);

      if (mounted) {
        Service.showMessage(
          error: true,
          context: context,
          title: 'Failed to load magazines',
        );
      }
    }
  }

  Future<void> _getUserDetails({userId, serverToken}) async {
    var data = await CoreServices.getUserDetail(userId, serverToken, context);

    if (data != null && data['success']) {
      if (mounted) {
        updatedUsserData = data;
        await Service.save('user', updatedUsserData);
        setState(() {});
      }
    } else {
      if (data != null && data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Service.showMessage(
          context: context,
          title: "${errorCodes['${data['error_code']}']}!",
          error: true,
        );
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  void _openMagazine(Magazine magazine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MagazineReaderScreen(magazine: magazine),
      ),
    );
  }

  void _handleLike(int index) async {
    // Disable likes for global users ( they don't have persistent user data)
    if (widget.isGlobalUser) {
      Service.showMessage(
        error: false,
        context: context,
        title: "Login to ZMall to like magazines",
      );
      return;
    }

    final magazine = magazines[index];

    // Check if already liked in the current UI state (prevents double-tap)
    if (magazine.userEngagement.hasLiked) {
      // Service.showMessage(
      //   error: true,
      //   context: context,
      //   title: 'You have already liked this magazine',
      // );
      return;
    }

    // Get user data
    final userData = await Service.read('user');
    if (userData == null) return;

    // Optimistically update UI
    final updatedEngagement = magazine.userEngagement.copyWith(hasLiked: true);

    setState(() {
      magazines[index] = magazine.copyWith(
        likesCount: magazine.likesCount + 1,
        userEngagement: updatedEngagement,
      );
    });

    // Sync with API
    try {
      final response = await MagazineService.updateUserMagazineInteraction(
        year: DateTime.now().year,
        userId: userData['user']['_id'],
        magazineId: magazine.id,
        serverToken: userData['user']['server_token'],
        context: context,
        interactionType: 'like',
        isGlobalUser: widget.isGlobalUser,
      );

      // Update user data with the new likes from API response
      if (response != null && response['success'] == true) {
        // Fetch fresh user data from server to get updated magazine_likes
        await _getUserDetails(
          userId: userData['user']['_id'],
          serverToken: userData['user']['server_token'],
        );

        // Update the magazine likes count from API response
        final actualLikesCount =
            response['likes_count'] ?? magazine.likesCount + 1;

        if (mounted) {
          setState(() {
            magazines[index] = magazine.copyWith(
              likesCount: actualLikesCount,
              userEngagement: updatedEngagement,
            );
          });
        }
      }
    } catch (e) {
      //debugPrint('Error liking magazine: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          magazines[index] = magazine.copyWith(
            likesCount: magazine.likesCount,
            userEngagement: magazine.userEngagement,
          );
        });
        Service.showMessage(
          error: true,
          context: context,
          title: 'Failed to like magazine',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.title ?? 'Z - Magazines',
          style: TextStyle(
            color: kBlackColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: kSecondaryColor,
        onRefresh: _onRefresh,
        child: SafeArea(
          child: isLoading
              ? _buildShimmerLoading()
              : magazines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        HeroiconsOutline.bookOpen,
                        // Icons.auto_stories_outlined,
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
                    childAspectRatio: 0.50, // Makes cards taller
                  ),
                  itemCount: magazines.length,
                  itemBuilder: (context, index) {
                    final magazine = magazines[index];
                    return MagazineCard(
                      magazine: magazine,
                      onTap: () => _openMagazine(magazine),
                      onLike: () => _handleLike(index),
                      onInfo: () => _showMagazineInfo(magazine),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showMagazineInfo(Magazine magazine) {
    final dialogHeight = MediaQuery.of(context).size.height * 0.85;
    final imageHeight = dialogHeight * 0.8;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(20),
          vertical: getProportionateScreenHeight(40),
        ),
        child: Container(
          height: dialogHeight,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(16),
            ),
          ),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: kBlackColor,
                    size: getProportionateScreenWidth(24),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Magazine preview (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images gallery or cover image (80% of dialog height)
                      SizedBox(
                        height: imageHeight,
                        child: magazine.images.isNotEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                itemCount: magazine.images.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: getProportionateScreenWidth(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        getProportionateScreenWidth(12),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: magazine.images[index],
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                        height: imageHeight,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.75,
                                              height: imageHeight,
                                              color: kGreyColor.withValues(
                                                alpha: 0.2,
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFFED2437),
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.75,
                                              height: imageHeight,
                                              color: kGreyColor.withValues(
                                                alpha: 0.2,
                                              ),
                                              child: Icon(
                                                // Icons.broken_image,
                                                HeroiconsOutline.photo,
                                                size:
                                                    getProportionateScreenWidth(
                                                      48,
                                                    ),
                                                color: kGreyColor,
                                              ),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    getProportionateScreenWidth(12),
                                  ),
                                  child: magazine.coverImage.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: magazine.coverImage,
                                          width: double.infinity,
                                          height: imageHeight,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                height: imageHeight,
                                                color: kGreyColor.withValues(
                                                  alpha: 0.2,
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Color(
                                                          0xFFED2437,
                                                        ),
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                height: imageHeight,
                                                color: kGreyColor.withValues(
                                                  alpha: 0.2,
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    // Icons.broken_image,
                                                    HeroiconsOutline.photo,
                                                    size:
                                                        getProportionateScreenWidth(
                                                          64,
                                                        ),
                                                    color: kGreyColor,
                                                  ),
                                                ),
                                              ),
                                        )
                                      : Container(
                                          height: imageHeight,
                                          color: kGreyColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              // Icons.auto_stories,
                                              HeroiconsOutline.bookOpen,
                                              size: getProportionateScreenWidth(
                                                64,
                                              ),
                                              color: kGreyColor,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(16)),
                      // Details section (scrollable content)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(
                            kDefaultPadding,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              magazine.title,
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(18),
                                fontWeight: FontWeight.bold,
                                color: kBlackColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              // textAlign: TextAlign.right,
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            // Category and date
                            Wrap(
                              spacing: getProportionateScreenWidth(8),
                              runSpacing: getProportionateScreenHeight(8),
                              children: [
                                if (magazine.category.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getProportionateScreenWidth(
                                        10,
                                      ),
                                      vertical: getProportionateScreenHeight(5),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFED2437,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        getProportionateScreenWidth(8),
                                      ),
                                    ),
                                    child: Text(
                                      magazine.category,

                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(
                                          11,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFED2437),
                                      ),
                                    ),
                                  ),
                                Text(
                                  magazine.formattedDate,
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(11),
                                    color: kGreyColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: getProportionateScreenHeight(12)),
                            // Description
                            Text(
                              magazine.description,
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(13),
                                color: kBlackColor,
                                height: 1.4,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              // textAlign: TextAlign.right,
                            ),
                            SizedBox(height: getProportionateScreenHeight(12)),
                            // Stats
                            Wrap(
                              spacing: getProportionateScreenWidth(12),
                              runSpacing: getProportionateScreenHeight(8),
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: getProportionateScreenWidth(14),
                                      color: kGreyColor,
                                    ),
                                    SizedBox(
                                      width: getProportionateScreenWidth(4),
                                    ),
                                    Text(
                                      '${magazine.formattedViewsCount} views',
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(
                                          11,
                                        ),
                                        color: kGreyColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: getProportionateScreenWidth(14),
                                      color: const Color(0xFFED2437),
                                    ),
                                    SizedBox(
                                      width: getProportionateScreenWidth(4),
                                    ),
                                    Text(
                                      '${magazine.formattedLikesCount} likes',
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(
                                          11,
                                        ),
                                        color: kGreyColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.menu_book,
                                      size: getProportionateScreenWidth(14),
                                      color: kGreyColor,
                                    ),
                                    SizedBox(
                                      width: getProportionateScreenWidth(4),
                                    ),
                                    Text(
                                      '${magazine.pageCount} pages',
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(
                                          11,
                                        ),
                                        color: kGreyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                            // Read button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _openMagazine(magazine);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFED2437),
                                  padding: EdgeInsets.symmetric(
                                    vertical: getProportionateScreenHeight(14),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      getProportionateScreenWidth(12),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Read Magazine',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(15),
                                    fontWeight: FontWeight.bold,
                                    color: kWhiteColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: getProportionateScreenWidth(18),
            height: getProportionateScreenWidth(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(2)),
          Container(
            width: getProportionateScreenWidth(20),
            height: getProportionateScreenHeight(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
        vertical: getProportionateScreenHeight(kDefaultPadding),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: getProportionateScreenWidth(kDefaultPadding),
        mainAxisSpacing: getProportionateScreenHeight(kDefaultPadding),
        childAspectRatio: 0.50,
      ),
      itemCount: 6, // Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kBlackColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image shimmer (3/4 of card)
              Expanded(
                flex: 3,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              // Details section shimmer (1/4 of card)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Magazine info shimmer
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(8),
                        vertical: getProportionateScreenHeight(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title shimmer
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: getProportionateScreenHeight(11),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(2)),
                          // Category shimmer
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: getProportionateScreenWidth(60),
                              height: getProportionateScreenHeight(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Engagement metrics row shimmer
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(8),
                          vertical: getProportionateScreenHeight(6),
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: kGreyColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Like icon shimmer
                            _buildIconShimmer(),
                            // Views icon shimmer
                            _buildIconShimmer(),
                            // Info icon shimmer
                            _buildIconShimmer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
