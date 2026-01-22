import 'package:flutter/material.dart';
import 'package:zmall/borsa/borsa_screen.dart';
import 'package:zmall/cart/cart_screen.dart';
import 'package:zmall/checkout/checkout_screen.dart';
import 'package:zmall/courier/components/vehicle_screen.dart';
import 'package:zmall/courier/courier_screen.dart';
import 'package:zmall/courier_checkout/courier_checkout_screen.dart';
import 'package:zmall/delivery/delivery_screen.dart';
import 'package:zmall/events/events_screen.dart';
import 'package:zmall/favorites/favorites_screen.dart';
import 'package:zmall/forgot_password/forgot_password_screen.dart';
import 'package:zmall/global/delivery/global_delivery.dart';
import 'package:zmall/global/global.dart';
import 'package:zmall/help/faq/faq_screen.dart';
import 'package:zmall/help/help_screen.dart';
import 'package:zmall/home/home_screen.dart';
import 'package:zmall/item/item_screen.dart';
import 'package:zmall/kifiya/kifiya_screen.dart';
import 'package:zmall/location/components/provider_location.dart';
import 'package:zmall/location/location_screen.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/orders/components/order_history_detail.dart';
import 'package:zmall/orders/components/order_rating.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/profile/components/subscribe.dart';
import 'package:zmall/profile/profile_screen.dart';
import 'package:zmall/register/register_screen.dart';
import 'package:zmall/report/report_screen.dart';
import 'package:zmall/splash/splash_screen.dart';
// import 'package:zmall/help/support_chat/support_chat_screen.dart';
import 'package:zmall/utils/tab_screen.dart';
import 'package:zmall/store/store_screen.dart';
import '../global/home_page/global_home.dart';

final Map<String, WidgetBuilder> routes = {
  SplashScreen.routeName: (context) => SplashScreen(),
  LoginScreen.routeName: (context) => LoginScreen(),
  TabScreen.routeName: (context) => TabScreen(isLaunched: false),
  HomeScreen.routeName: (context) => HomeScreen(),
  StoreScreen.routeName: (context) => StoreScreen(),
  ProductScreen.routeName: (context) => ProductScreen(),
  ItemScreen.routeName: (context) => ItemScreen(),
  ProfileScreen.routeName: (context) => ProfileScreen(),
  CartScreen.routeName: (context) => CartScreen(),
  DeliveryScreen.routeName: (context) => DeliveryScreen(),
  LocationScreen.routeName: (context) => LocationScreen(),
  CheckoutScreen.routeName: (context) => CheckoutScreen(),
  ReportScreen.routeName: (context) => ReportScreen(),
  KifiyaScreen.routeName: (context) => KifiyaScreen(),
  OrderHistoryDetail.routeName: (context) => OrderHistoryDetail(),
  OrderRating.routeName: (context) => OrderRating(),
  RegisterScreen.routeName: (context) => RegisterScreen(),
  ProviderLocation.routeName: (context) => ProviderLocation(),
  BorsaScreen.routeName: (context) => BorsaScreen(),
  FavoritesScreen.routeName: (context) => FavoritesScreen(),
  HelpScreen.routeName: (context) => HelpScreen(),
  CourierScreen.routeName: (context) => CourierScreen(),
  VehicleScreen.routeName: (context) => VehicleScreen(),
  CourierCheckout.routeName: (context) => CourierCheckout(),
  ForgotPassword.routeName: (context) => ForgotPassword(),
  GlobalScreen.routeName: (context) => GlobalScreen(),
  GlobalHome.routeName: (context) => GlobalHome(),
  GlobalDelivery.routeName: (context) => GlobalDelivery(),
  EventsScreen.routeName: (context) => EventsScreen(),
  SubscribeScreen.routeName: (context) => SubscribeScreen(),
  // SupportChatScreen.routeName: (context) => SupportChatScreen(),
  FAQScreen.routeName: (context) => FAQScreen(),
  // ScannerScreen.routeName: (context) => ScannerScreen(),
};
