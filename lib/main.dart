import 'dart:io' show Platform;
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zmall/utils/firebase_options.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/utils/routes.dart';
import 'package:zmall/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseInAppMessaging messaging = FirebaseInAppMessaging.instance;
  static final facebookAppEvents = FacebookAppEvents();

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
            scaffoldBackgroundColor: kPrimaryColor,
            // kWhiteColor,
            appBarTheme: AppBarTheme(
              backgroundColor: kWhiteColor,
              // backgroundColor: kPrimaryColor,
              surfaceTintColor: kPrimaryColor,
              // titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              //       color: kGreyColor,
              //     ),
              titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: kBlackColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              iconTheme: IconThemeData(color: kBlackColor),
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: kBlackColor,
              fontFamily: Platform.isIOS ? "Nunito" : "Nunito",
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kSecondaryColor),
            ),
          ),
          routes: routes,
          initialRoute: SplashScreen.routeName,
          navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
        ),
      ),
    );
  }
}

///for debugging FacebookAppEvents
// import 'dart:io' show Platform;
// import 'package:facebook_app_events/facebook_app_events.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:overlay_support/overlay_support.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/utils/constants.dart';
// import 'package:zmall/models/language.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/utils/routes.dart';
// import 'package:zmall/splash/splash_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   if (kDebugMode) {
//     debugPrint('🚀 ===== ZMall App Starting =====');
//   }

//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   if (kDebugMode) {
//     debugPrint('✅ Firebase initialized successfully');
//   }

//   // Initialize Facebook App Events
//   final facebookAppEvents = FacebookAppEvents();

//   if (kDebugMode) {
//     debugPrint('📱 Facebook App Events initialized');
//     debugPrint('🔍 App ID: 1050203588837738');

//     // Log app open event manually to see it in console
//     await facebookAppEvents.logEvent(
//       name: 'fb_mobile_app_open',
//       parameters: {
//         'app_name': 'ZMall',
//         'timestamp': DateTime.now().toIso8601String(),
//       },
//     );

//     debugPrint('✅ Facebook Event Logged: fb_mobile_app_open');
//     debugPrint(
//       '📊 Event Parameters: {app_name: ZMall, timestamp: ${DateTime.now()}}',
//     );
//   }

//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
//   static FirebaseInAppMessaging messaging = FirebaseInAppMessaging.instance;
//   static final facebookAppEvents = FacebookAppEvents();

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     if (kDebugMode) {
//       debugPrint('✅ FacebookAppEvents instance created');
//       debugPrint('🎯 Lifecycle observer attached - will log app state changes');
//       debugPrint('═══════════════════════════════════════════════════════');
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     if (kDebugMode) {
//       switch (state) {
//         case AppLifecycleState.resumed:
//           debugPrint('📱 App State: RESUMED (foreground)');
//           debugPrint('   → Facebook will track: fb_mobile_activate_app');
//           MyApp.facebookAppEvents.logEvent(
//             name: 'fb_mobile_activate_app',
//             parameters: {'timestamp': DateTime.now().toIso8601String()},
//           );
//           debugPrint('✅ Facebook Event Logged: fb_mobile_activate_app');
//           break;
//         case AppLifecycleState.inactive:
//           debugPrint('📱 App State: INACTIVE (transitioning)');
//           break;
//         case AppLifecycleState.paused:
//           debugPrint('📱 App State: PAUSED (background)');
//           debugPrint('   → Facebook will track: fb_mobile_deactivate_app');
//           MyApp.facebookAppEvents.logEvent(
//             name: 'fb_mobile_deactivate_app',
//             parameters: {'timestamp': DateTime.now().toIso8601String()},
//           );
//           debugPrint('✅ Facebook Event Logged: fb_mobile_deactivate_app');
//           break;
//         case AppLifecycleState.detached:
//           debugPrint('📱 App State: DETACHED (closing)');
//           break;
//         case AppLifecycleState.hidden:
//           debugPrint('📱 App State: HIDDEN');
//           break;
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider<ZMetaData>(create: (_) => ZMetaData()),
//         ChangeNotifierProvider<ZLanguage>(create: (_) => ZLanguage()),
//       ],
//       child: OverlaySupport.global(
//         child: MaterialApp(
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             fontFamily: Platform.isIOS ? "Nunito" : "Nunito",
//             primarySwatch: Colors.red,
//             scaffoldBackgroundColor: kPrimaryColor,
//             // kWhiteColor,
//             appBarTheme: AppBarTheme(
//               backgroundColor: kWhiteColor,
//               // backgroundColor: kPrimaryColor,
//               surfaceTintColor: kPrimaryColor,
//               // titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
//               //       color: kGreyColor,
//               //     ),
//               titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 color: kBlackColor,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 20,
//               ),
//               iconTheme: IconThemeData(color: kBlackColor),
//             ),
//             textTheme: Theme.of(context).textTheme.apply(
//               bodyColor: kBlackColor,
//               fontFamily: Platform.isIOS ? "Nunito" : "Nunito",
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(foregroundColor: kSecondaryColor),
//             ),
//           ),
//           routes: routes,
//           initialRoute: SplashScreen.routeName,
//           navigatorObservers: [
//             FirebaseAnalyticsObserver(analytics: MyApp.analytics),
//           ],
//         ),
//       ),
//     );
//   }
// }
