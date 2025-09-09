import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    this.subtitle,
    this.titleColor,
    this.borderColor,
    required this.icon,
    required this.title,
    required this.onTap,
    this.showTrailing = true,
  });

  final Icon icon;
  final String title;
  final Widget? subtitle;
  final Color? titleColor;
  final Color? borderColor;
  final bool showTrailing;

  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 0,
        horizontal: getProportionateScreenHeight(kDefaultPadding / 8),
      ),
      decoration: BoxDecoration(
          color: titleColor != null
              ? titleColor!.withValues(alpha: 0.1)
              : kPrimaryColor,
          border: Border.all(
              color: titleColor != null
                  ? titleColor!.withValues(alpha: 0.1)
                  : borderColor ?? kWhiteColor),
          borderRadius: BorderRadius.circular(kDefaultPadding)),
      child: ListTile(
        subtitle: subtitle,
        leading: IconTheme(
          data: IconThemeData(
            size: 22, color: titleColor ?? kBlackColor,
            //  kSecondaryColor
          ),
          child: icon,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: titleColor ?? kBlackColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        tileColor: kPrimaryColor,
        trailing: showTrailing
            ? Icon(
                size: 18,
                HeroiconsSolid.chevronRight,
                color: titleColor ?? kBlackColor)
            : null,
        onTap: onTap,
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 10,
        ),
      ),
    );
  }
}
