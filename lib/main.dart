import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/routes.dart';
import 'package:zmall/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    // options: FirebaseOptions(
    //   apiKey: "AIzaSyDFfRtPeakrhsHOxOaZOYpPQM8klHC6Y80",
    //   appId: "1:362956281866:android:732f5c7b2987fa35",
    //   messagingSenderId: "362956281866",
    //   projectId: "zmall-184809",
    //   iosClientId:
    //       "362956281866-7eotv0dma4074a29aov6qluqiuvrvo8p.apps.googleusercontent.com",
    //   androidClientId:
    //       "362956281866-34miif7nvrmtgvrn7o8lsb5ul3nlvq5r.apps.googleusercontent.com",
    // ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseInAppMessaging messaging = FirebaseInAppMessaging.instance;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ZMetaData>(create: (_) => ZMetaData()),
        ChangeNotifierProvider<ZLanguage>(create: (_) => ZLanguage()),
      ],
      child: OverlaySupport.global(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: Platform.isIOS ? "Nunito" : "Nunito",
            primarySwatch: Colors.red,
            scaffoldBackgroundColor: kWhiteColor,
            appBarTheme: AppBarTheme(
              color: kWhiteColor,
              iconTheme: IconThemeData(color: kBlackColor),
            ),
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: kBlackColor,
                  fontFamily: Platform.isIOS ? "Nunito" : "Nunito",
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kSecondaryColor,
              ),
            ),
          ),
          routes: routes,
          initialRoute: SplashScreen.routeName,
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: analytics),
          ],
        ),
      ),
    );
  }
}
