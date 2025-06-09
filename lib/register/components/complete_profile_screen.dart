import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

import 'complete_profile_form.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.confirmPassword,
  }) : super(key: key);

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
  final String email, password, confirmPassword;
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(20)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: SizeConfig.screenHeight! * 0.03),
                  Text("Complete Profile", style: headingStyle),
                  // Text(
                  //   "Complete your details or continue  \nwith social media",
                  //   textAlign: TextAlign.center,
                  // ),
                  SizedBox(height: SizeConfig.screenHeight! * 0.06),
                  CompleteProfileForm(
                    password: widget.password,
                    email: widget.email,
                    confirmPassword: widget.confirmPassword,
                  ),
                  // SizedBox(height: getProportionateScreenHeight(30)),
                  // Text(
                  //   "By continuing your confirm that you agree \nwith our Term and Condition",
                  //   textAlign: TextAlign.center,
                  //   style: Theme.of(context).textTheme.caption,
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
