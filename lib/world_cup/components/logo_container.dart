import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class LogoContainer extends StatelessWidget {
  final String logoUrl;
  final String errorLogoAsset;
  final double? size;
  final double borderRadius;
  final Color? backgroundColor;
  const LogoContainer({
    super.key,
    this.size,
    this.backgroundColor,
    this.borderRadius = 12,
    required this.logoUrl,
    required this.errorLogoAsset,
  });

  @override
  Widget build(BuildContext context) {
    // return size ??= getProportionateScreenWidth(kDefaultPadding * 3);
    return Container(
      width: size ?? getProportionateScreenWidth(kDefaultPadding * 3),
      height: size ?? getProportionateScreenWidth(kDefaultPadding * 3),
      padding: EdgeInsets.all(kDefaultPadding / 4),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor ?? kWhiteColor.withValues(alpha: 0.2),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: CachedNetworkImageProvider(
            logoUrl,
            errorListener: (_) {},
          ),
        ),
      ),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            image: DecorationImage(
              image: AssetImage(errorLogoAsset),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
