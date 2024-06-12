import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class ImageContainer extends StatelessWidget {
  ImageContainer({Key? key, this.url,}) : super(key: key);
  final String? url;
  


  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url!,
      imageBuilder: (context, imageProvider) => Container(
        width: getProportionateScreenWidth(kDefaultPadding * 5),
        height: getProportionateScreenHeight(kDefaultPadding * 5),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(
              kDefaultPadding / 8,
            ),
          ),
          color: kWhiteColor,
          image: DecorationImage(
            fit: BoxFit.cover,
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
        width: getProportionateScreenWidth(kDefaultPadding * 5),
        height: getProportionateScreenHeight(kDefaultPadding * 5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kWhiteColor,
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage(zmallLogo),
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
