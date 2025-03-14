import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.press,
  }) : super(key: key);

  final Icon icon;
  final String title;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        child: ListTile(
          leading: icon,
          title: Text(title),
          tileColor: kPrimaryColor,
          trailing: Icon(
            Icons.arrow_right,
            color: kSecondaryColor,
          ),
          onTap: press,
        ),
        borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding)));
  }
}
