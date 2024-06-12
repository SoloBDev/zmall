import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class StoresCard extends StatelessWidget {
  const StoresCard({
    Key? key,
    required this.imageUrl,
    required this.storeName,
    required this.deliveryType,
    required this.distance,
    required this.press,
    required this.rating,
    required this.ratingCount,
    this.featuredTag = "",
    this.isFeatured = false,
  }) : super(key: key);

  final String imageUrl;
  final String storeName;
  final String deliveryType;
  final String distance, rating, ratingCount, featuredTag;
  final GestureTapCallback press;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: ClipRRect(

        borderRadius: BorderRadius.only(
          topRight: Radius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
          topLeft: Radius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
        ),
        child: Stack(
          children: [

            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: isFeatured ? getProportionateScreenWidth(kDefaultPadding) : 0, right: isFeatured ? getProportionateScreenWidth(kDefaultPadding) : 0, ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    boxShadow: [boxShadow],
                    border: Border.all(width: 0.1, color: kGreyColor),
                    borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding / 2),
                    ),

                  ),
                  height: getProportionateScreenHeight(kDefaultPadding * 6),
                  width: getProportionateScreenWidth(kDefaultPadding * 10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: imageProvider,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => Center(
                      child: Container(
                        width:
                        getProportionateScreenWidth(kDefaultPadding * 5),
                        height:
                        getProportionateScreenHeight(kDefaultPadding * 5),
                        child: CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.transparent),
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
                ),
                Container(
                  color: kPrimaryColor,
                  width: getProportionateScreenWidth(kDefaultPadding * 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: getProportionateScreenHeight(
                                kDefaultPadding / 5)),
                        child: Text(
                          storeName,
                          style: Theme.of(context).textTheme.button?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: kBlackColor,
                          ),
                          maxLines: 1,
                        ),
                      ),

                      Text(
                        deliveryType,
                        style: Theme.of(context).textTheme.caption?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: kBlackColor,
                        ),
                        maxLines: 1,
                      ),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: getProportionateScreenWidth(kDefaultPadding),),
                          SizedBox(width: 5,),
                          Text("$rating ($ratingCount)", style:
                          Theme.of(context).textTheme.caption?.copyWith(

                            fontWeight: FontWeight.w500,
                            color: kGreyColor,
                          ),),
                          SizedBox(width: 10,),
                          Icon(Icons.social_distance_rounded
                            , color: kGreyColor, size: getProportionateScreenWidth(kDefaultPadding),),
                          SizedBox(width: 5,),
                          Text(
                            "$distance KM",
                            style:
                            Theme.of(context).textTheme.caption?.copyWith(

                              fontWeight: FontWeight.w500,
                              color: kGreyColor,
                            ),
                          ),


                        ],
                      ),


                    ],
                  ),
                )
              ],
            ),

            // isFeatured ? Align(
            //   alignment: Alignment.topRight,
            //   child: Container(
            //     // color: kSecondaryColor,
            //     child: Padding(
            //       padding: EdgeInsets.symmetric(
            //           horizontal: kDefaultPadding / 2),
            //       child: SvgPicture.asset("images/store_tags/24_7.svg")
            //     ),
            //   ),
            // ) : Container(),
            isFeatured ? Positioned(
              right: 0,
              child: Container(
                height: getProportionateScreenWidth(kDefaultPadding * 3),
                width: getProportionateScreenWidth(kDefaultPadding * 3),
                //
                child: Center(
                  child: Image
                      .asset("images/store_tags/$featuredTag.png")
                ),
              ),
            ) : Container()
            
          ],
        ),
      ),
    );
  }
}
