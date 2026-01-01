import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zmall/home/magazine/models/magazine_model.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class MagazineCard extends StatelessWidget {
  final Magazine magazine;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onInfo;

  const MagazineCard({
    super.key,
    required this.magazine,
    required this.onTap,
    this.onLike,
    this.onInfo,
  });

  // Helper method to validate URL
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Helper method to build placeholder
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFED2437).withValues(alpha: 0.8),
            const Color(0xFFc91f2f).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_stories, size: 48, color: kWhiteColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Cover Image (3/4 of card)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: kGreyColor.withValues(alpha: 0.2),
                    ),
                    child:
                        magazine.coverImage.isNotEmpty &&
                            _isValidUrl(magazine.coverImage)
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: magazine.coverImage,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                color: kGreyColor.withValues(alpha: 0.2),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFED2437),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  _buildPlaceholder(),
                            ),
                          )
                        : _buildPlaceholder(),
                  ),

                  // New badge
                  if (magazine.isNew)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFED2437),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: kWhiteColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Protected badge
                  if (magazine.isProtected)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kBlackColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: kWhiteColor),
                            SizedBox(width: 3),
                            Text(
                              'PROTECTED',
                              style: TextStyle(
                                color: kWhiteColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Page count badge (only show if pageCount > 0)
                  if (magazine.pageCount > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kBlackColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.description,
                              size: 12,
                              color: kWhiteColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${magazine.pageCount} pages',
                              style: const TextStyle(
                                color: kWhiteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details section (1/4 of card)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Magazine info (compact)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(
                        kDefaultPadding / 2,
                      ),
                      vertical: getProportionateScreenHeight(
                        kDefaultPadding / 3,
                      ),
                    ),
                    child: Column(
                      spacing: getProportionateScreenHeight(2),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          magazine.title,
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(11),
                            fontWeight: FontWeight.w600,
                            color: kBlackColor,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Category
                        Text(
                          magazine.category.isNotEmpty
                              ? magazine.category
                              : magazine.formattedDate,
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(8),
                            color: kGreyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Engagement metrics row (TikTok style)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(
                          kDefaultPadding / 2,
                        ),
                        vertical: getProportionateScreenHeight(
                          kDefaultPadding / 3,
                        ),
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
                          // Like button with count
                          if (onLike != null)
                            GestureDetector(
                              onTap: onLike,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    magazine.userEngagement.hasLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: getProportionateScreenWidth(18),
                                    color: magazine.userEngagement.hasLiked
                                        ? const Color(0xFFED2437)
                                        : kGreyColor,
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(2),
                                  ),
                                  Text(
                                    magazine.formattedLikesCount,
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(9),
                                      color: kGreyColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Views with count
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: getProportionateScreenWidth(18),
                                color: kGreyColor,
                              ),
                              SizedBox(height: getProportionateScreenHeight(2)),
                              Text(
                                magazine.formattedViewsCount,
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(9),
                                  color: kGreyColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Info button (preview)
                          if (onInfo != null)
                            GestureDetector(
                              onTap: onInfo,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: getProportionateScreenWidth(18),
                                    color: kGreyColor,
                                  ),
                                  SizedBox(
                                    height: getProportionateScreenHeight(2),
                                  ),
                                  Text(
                                    'Info',
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(9),
                                      color: kGreyColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
          ],
        ),
      ),
    );
  }
}
