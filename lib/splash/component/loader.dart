import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rive/rive.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class Loader extends StatelessWidget {
  const Loader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: getProportionateScreenWidth(kDefaultPadding * 10),
          height: getProportionateScreenHeight(kDefaultPadding * 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(zmallLogo),
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
        Container(
          child: Column(
            children: [
              SpinKitWave(
                color: kPrimaryColor,
                size: getProportionateScreenWidth(kDefaultPadding),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              Text(
                "Loading...",
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .copyWith(color: kBlackColor),
              )
            ],
          ),
        ),
        // Positioned.fill(
        //   child: BackdropFilter(
        //     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        //     child: SizedBox(),
        //   ),
        // ),
        // RiveAnimation.asset(
        //   "images/zmall_animation.riv",
        //   fit: BoxFit.cover,
        // ),
      ],
    );

    //   Stack(
    //   // mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     // Positioned(
    //     //   width: MediaQuery.of(context).size.width * 1.5,
    //     //   bottom: 200,
    //     //   left: 100,
    //     //   child: Image.asset("images/zmall.jpg"),
    //     // ),
    //     // Positioned.fill(
    //     //   child: BackdropFilter(
    //     //     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    //     //     child: SizedBox(),
    //     //   ),
    //     // ),
    //     // RiveAnimation.asset(
    //     //   "images/zmall_animation.riv",
    //     //   fit: BoxFit.cover,
    //     // ),
    //     // Positioned.fill(
    //     //   child: BackdropFilter(
    //     //     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    //     //     child: SizedBox(),
    //     //   ),
    //     // ),
    //     Container(
    //       width: getProportionateScreenWidth(kDefaultPadding * 10),
    //       height: getProportionateScreenHeight(kDefaultPadding * 10),
    //       decoration: BoxDecoration(
    //         shape: BoxShape.circle,
    //         image: DecorationImage(
    //           image: AssetImage(zmallLogo),
    //           fit: BoxFit.contain,
    //         ),
    //       ),
    //     ),
    //     SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),
    //     Container(
    //       child: Column(
    //         children: [
    //           SpinKitWave(
    //             color: kPrimaryColor,
    //             size: getProportionateScreenWidth(kDefaultPadding),
    //           ),
    //           SizedBox(
    //             height: getProportionateScreenHeight(kDefaultPadding / 2),
    //           ),
    //           Text(
    //             "Loading...",
    //             style: Theme.of(context)
    //                 .textTheme
    //                 .caption!
    //                 .copyWith(color: kBlackColor),
    //           )
    //         ],
    //       ),
    //     ),
    //   ],
    // );
  }
}
