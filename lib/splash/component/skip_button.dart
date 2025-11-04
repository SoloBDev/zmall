import 'package:flutter/material.dart';
import 'package:zmall/global/global.dart';
import 'package:zmall/global/home_page/global_home.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/tab_screen.dart';

class SkipButton extends StatelessWidget {
  const SkipButton({super.key, required this.logged});
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
              isGlobal
                  ? Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            abroadData != null ? GlobalHome() : GlobalScreen(),
                      ),
                    )
                  : Navigator.pushReplacementNamed(
                      context,
                      logged ? TabScreen.routeName : LoginScreen.routeName,
                    );
            } catch (e) {
              // debugPrint("Ad skipped...");
            }
          },
        ),
      ),
    );
  }
}
