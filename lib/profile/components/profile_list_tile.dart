import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    this.titleColor,
    required this.icon,
    required this.title,
    required this.press,
  });

  final Icon icon;
  final String title;
  final Color? titleColor;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        child: ListTile(
          leading: IconTheme(
            data: IconThemeData(size: 20, color: kSecondaryColor),
            child: icon,
          ),
          title: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: titleColor ?? kBlackColor)),
          tileColor: kPrimaryColor,
          trailing: Icon(
            size: 16,
            HeroiconsOutline.chevronRight,
            // Icons.arrow_right,

            color: kSecondaryColor,
          ),
          onTap: press,
          leadingAndTrailingTextStyle: TextStyle(
            fontSize: 10,
          ),
        ),
        borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding)));
  }
}
