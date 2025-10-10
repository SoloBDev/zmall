import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class ImageContainer extends StatelessWidget {
  final BoxFit? fit;
  final String? url;
  final String? errorUrl;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape? shape;
  final BoxBorder? border;

  ImageContainer({
    super.key,
    this.url,
    this.fit,
    this.errorUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.shape,
    this.border,
  });
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url!,
      imageBuilder: (context, imageProvider) => Container(
        width: width ?? getProportionateScreenWidth(kDefaultPadding * 5),
        height: height ?? getProportionateScreenHeight(kDefaultPadding * 5),
        padding: EdgeInsets.all(kDefaultPadding),
        decoration: BoxDecoration(
          shape: shape ?? BoxShape.rectangle,
          borderRadius: (shape ?? BoxShape.rectangle) == BoxShape.rectangle
              ? (borderRadius ??
                  BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 1.5),
                  ))
              : null,
          color: kWhiteColor,
          border: border,
          image: DecorationImage(
            fit: fit ?? BoxFit.cover,
            image: imageProvider,
          ),
        ),
      ),
      placeholder: (context, url) => Center(
        child: Container(
          width: width ?? getProportionateScreenWidth(kDefaultPadding * 5),
          height: height ?? getProportionateScreenHeight(kDefaultPadding * 5),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kWhiteColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width ?? getProportionateScreenWidth(kDefaultPadding * 5),
        height: height ?? getProportionateScreenHeight(kDefaultPadding * 5),
        decoration: BoxDecoration(
          shape: shape ?? BoxShape.circle,
          color: kWhiteColor,
          borderRadius: borderRadius,
          image: DecorationImage(
            fit: fit ?? BoxFit.cover,
            image: AssetImage(errorUrl ?? zmallLogo),
          ),
        ),
      ),
    );
  }
}

class FavoriteImageContainer extends StatelessWidget {
  const FavoriteImageContainer({
    Key? key,
    this.url,
  }) : super(key: key);
  final String? url;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return CachedNetworkImage(
          imageUrl: url!,
          imageBuilder: (context, imageProvider) => Container(
            width: constraint.maxWidth,
            height: getProportionateScreenHeight(kDefaultPadding * 5.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              image: DecorationImage(
                fit: BoxFit.scaleDown,
                image: imageProvider,
              ),
            ),
          ),
          placeholder: (context, url) => Center(
            child: Container(
              width: getProportionateScreenWidth(kDefaultPadding * 5),
              height: getProportionateScreenHeight(kDefaultPadding * 5),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kWhiteColor),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: getProportionateScreenWidth(kDefaultPadding * 3.5),
            height: getProportionateScreenHeight(kDefaultPadding * 3.5),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.transparent,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('images/zmall.jpg'),
              ),
            ),
          ),
        );
      },
    );
  }
}
