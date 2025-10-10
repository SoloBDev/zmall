import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/home/components/indicator_dot.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/utils/size_config.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    Key? key,
    required this.promotionalItems,
  }) : super(key: key);

  final promotionalItems;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentPage = 0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: AspectRatio(
        aspectRatio: 1.81,
        child: Stack(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                PageView.builder(
                  onPageChanged: (value) {
                    setState(() {
                      _currentPage = value;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(kDefaultPadding),
                      child: CachedNetworkImage(
                        imageUrl: widget.promotionalItems != null &&
                                widget
                                        .promotionalItems['promotional_items']
                                            [index]['image_url']
                                        .length >
                                    0
                            ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.promotionalItems['promotional_items'][index]['image_url'][0]}"
                            : "www.google.com",
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              image: imageProvider,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Center(
                          child: Container(
                            width: getProportionateScreenWidth(
                                kDefaultPadding * 3.5),
                            height: getProportionateScreenHeight(
                                kDefaultPadding * 3.5),
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(kWhiteColor),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: AssetImage('images/trending.png'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: widget.promotionalItems != null &&
                          widget.promotionalItems['promotional_items'].length >
                              0
                      ? widget.promotionalItems['promotional_items'].length
                      : 0,
                ),
                Positioned(
                  bottom: getProportionateScreenWidth(kDefaultPadding),
                  right: getProportionateScreenWidth(kDefaultPadding),
                  child: Row(
                    children: List.generate(
                      widget.promotionalItems != null &&
                              widget.promotionalItems['promotional_items']
                                      .length >
                                  0
                          ? widget.promotionalItems['promotional_items'].length
                          : 0,
                      (index) => Padding(
                        padding: EdgeInsets.only(left: kDefaultPadding / 10),
                        child: IndicatorDot(
                          isActive: index == _currentPage,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
