import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zmall/global/global.dart';
import 'package:zmall/global/home_page/global_home.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/service.dart';
import 'package:zmall/tab_screen.dart';

class SkipButton extends StatelessWidget {
  const SkipButton({
    Key? key,
    required this.logged,
  }) : super(key: key);
  final bool logged;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextButton(
          child: Text("Skip >>"),
          style: TextButton.styleFrom(
            backgroundColor: Colors.black26,
            foregroundColor: Colors.white70,
          ),
          onPressed: () async {
            bool isGlobal = await Service.readBool('is_global');
            var abroadData = await Service.read('abroad_user');
            try {
              isGlobal != null && isGlobal
                  ? Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            abroadData != null ? GlobalHome() : GlobalScreen(),
                      ),
                    )
                  : Navigator.pushReplacementNamed(context,
                      logged ? TabScreen.routeName : LoginScreen.routeName);
            } catch (e) {
              debugPrint("Ad skipped...");
            }
          },
        ),
      ),
    );
  }
}
