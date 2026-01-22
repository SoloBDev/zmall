import 'package:flutter/material.dart';
import 'components/body.dart';

class ProfileScreen extends StatelessWidget {
  static String routeName = '/profile';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   title: Text(
      //     Provider.of<ZLanguage>(context).profilePage,
      //     style: TextStyle(color: kBlackColor),
      //   ),
      //   elevation: 1.0,
      // ),
      body: Body(),
    );
  }
}
