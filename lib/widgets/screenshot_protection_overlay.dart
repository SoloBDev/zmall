import 'package:flutter/material.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

/// Black overlay shown when screenshot is taken or screen recording is active
/// Customizable UI that appears in Flutter instead of native code
class ScreenshotProtectionOverlay extends StatelessWidget {
  final bool show;
  final String? customMessage;

  const ScreenshotProtectionOverlay({
    super.key,
    required this.show,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: kBlackColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.block,
                color: kPrimaryColor,
                size: getProportionateScreenWidth(kDefaultPadding * 5),
              ),

              SizedBox(height: getProportionateScreenHeight(kDefaultPadding * 2)),

              // Main message
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding * 2),
                ),
                child: Text(
                  customMessage ?? 'SCREENSHOT IS NOT ALLOWED',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: getProportionateScreenWidth(
                          kDefaultPadding * 1.5,
                        ),
                      ),
                ),
              ),

              SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),

              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding * 3),
                ),
                child: Text(
                  'This content is protected',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kPrimaryColor.withValues(alpha: 0.7),
                        fontSize: getProportionateScreenWidth(
                          kDefaultPadding * 0.8,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
