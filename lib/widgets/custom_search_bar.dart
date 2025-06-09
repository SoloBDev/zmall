import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final Iterable<Widget>? trailing;
  const CustomSearchBar(
      {super.key, this.controller, this.onChanged, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: 'Search',
      controller: controller,
      leading: const Icon(Icons.search),
      onChanged: onChanged,
      trailing: trailing,
      elevation: WidgetStateProperty.all(0),
      padding:
          WidgetStateProperty.all(EdgeInsets.only(left: kDefaultPadding * 1.5)),
      textStyle:
          WidgetStateProperty.all<TextStyle>(TextStyle(color: kBlackColor)),
      hintStyle:
          WidgetStateProperty.all<TextStyle>(TextStyle(color: kBlackColor)),
      backgroundColor: WidgetStateProperty.all(kPrimaryColor),
      overlayColor: WidgetStateProperty.all(kPrimaryColor),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultPadding * 2),
        ),
      ),
    );
  }
}
