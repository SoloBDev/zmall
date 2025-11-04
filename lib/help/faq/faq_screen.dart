import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

class FAQScreen extends StatelessWidget {
  static String routeName = '/faq';

  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: Text("FAQ")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            getProportionateScreenHeight(kDefaultPadding),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction text
              Text(
                "Find answers to common questions about ZMall Delivery services",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: kGreyColor,
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),

              // FAQ Categories
              _buildCategoryCard(
                context,
                title: "General Overview",
                icon: HeroiconsOutline.informationCircle,
                color: Colors.blue,
                questions: [
                  "What is ZMall?",
                  "What services does ZMall offer?",
                  "Which countries does ZMall operate in?",
                  "What languages does ZMall support?",
                ],
                answers: [
                  "ZMall is a comprehensive e-commerce and delivery platform that connects customers with local merchants and services in Ethiopia and South Sudan. It offers food delivery, shopping, courier services, and various other on-demand services through a mobile application.",
                  "ZMall provides:\n- Food delivery from restaurants and cafes\n- Grocery and retail shopping\n- Courier/parcel delivery services\n- Laundry services with multiple delivery options\n- Event ticketing\n- ZMall Global (order from anywhere in the world for loved ones in Ethiopia)\n- Dine-in ordering at restaurants\n- Promotional offers and loyalty programs",
                  "ZMall operates in:\n- Ethiopia (Main focus on Addis Ababa for deliveries)\n- South Sudan (Juba and surrounding areas)\n- ZMall Global - Accessible from anywhere worldwide to send orders to Ethiopia",
                  "The app supports multiple languages to serve diverse user communities in Ethiopia and South Sudan. The interface can be switched between languages based on user preference.",
                ],
              ),

              _buildCategoryCard(
                context,
                title: "User Account & Authentication",
                icon: HeroiconsOutline.userCircle,
                color: Colors.green,
                questions: [
                  "How do I create a ZMall account?",
                  "What authentication methods are available?",
                  "How does biometric authentication work?",
                  "Can I use multiple accounts on the same device?",
                  "What if I forget my password?",
                ],
                answers: [
                  "To create an account:\n1. Download the ZMall app\n2. Click on \"Register\"\n3. Enter your phone number (starting with 9 or 7 for Ethiopia)\n4. Complete your profile information\n5. Verify your phone number with OTP\n6. Set a secure password (minimum 8 characters)",
                  "ZMall offers:\n- Phone & Password login with OTP verification\n- Biometric authentication (Face ID/Touch ID/Fingerprint)\n- Multi-account support for switching between multiple accounts\n- Guest mode for browsing without login\n- Saved accounts feature for quick switching",
                  "After logging in once with your phone and password:\n1. The app will offer to enable biometric authentication\n2. Your credentials are securely stored using device encryption\n3. Next time, simply use your fingerprint/Face ID to login\n4. Supports multiple accounts with individual biometric settings",
                  "Yes! ZMall supports multi-account functionality:\n- Save multiple account credentials\n- Switch between accounts easily\n- Each account can have its own biometric settings\n- Access \"Switch Account\" from the login screen",
                  "Use the \"Forgot Password?\" option:\n1. Enter your registered phone number\n2. Receive OTP verification\n3. Create a new password\n4. Login with your new credentials",
                ],
              ),

              _buildCategoryCard(
                context,
                title: "Shopping & Ordering",
                icon: HeroiconsOutline.shoppingCart,
                color: Colors.orange,
                questions: [
                  "How do I place an order?",
                  "What delivery options are available?",
                  "Can I order for someone else?",
                  "How do I track my order?",
                  "Can I modify or cancel an order?",
                ],
                answers: [
                  "To place an order:\n1. Browse categories or search for items/stores\n2. Add items to your cart\n3. Review your cart and proceed to checkout\n4. Select delivery address\n5. Choose delivery options (ASAP, scheduled, or self-pickup)\n6. Select payment method\n7. Confirm and place order",
                  "ZMall offers flexible delivery options:\n- ASAP Delivery - Express delivery as soon as possible\n- Scheduled Delivery - Pre-order for a specific date/time (up to 7 days ahead)\n- Self Pickup - Collect order yourself from the store\n- Laundry Services offer:\n - Normal delivery (4-5 days)\n - Half express (2 days)\n - Next day delivery\n - Three hours delivery",
                  "Yes, you can order for others:\n- Enter receiver's name and phone number during checkout\n- Specify delivery address for the receiver\n- For delivery orders: Receiver can pay cash on delivery OR sender pays online\n- For self-pickup: Sender MUST pay online (no cash option available)\n- Cash payment only possible when there's a delivery person to collect it\n- Track the order on behalf of the receiver",
                  "Order tracking features:\n- Real-time status updates in the Orders section\n- Push notifications for order status changes\n- Estimated delivery time (ETA) displayed\n- Delivery person contact information when assigned\n- Live location tracking for deliveries",
                  "Order modifications depend on status:\n- Orders can typically be cancelled before merchant acceptance\n- Contact support for urgent cancellations\n- Scheduled orders CANNOT be modified once placed - must contact support for any changes\n- Order details are fixed once submitted\n- Refunds processed based on cancellation policy",
                ],
              ),

              _buildCategoryCard(
                context,
                title: "Payment Methods",
                icon: HeroiconsOutline.creditCard,
                color: Colors.purple,
                questions: [
                  "What payment methods does ZMall accept?",
                  "How does the payment process work?",
                  "Is my payment information secure?",
                  "What is ZMall Wallet (Borsa)?",
                ],
                answers: [
                  "ZMall integrates with multiple payment providers:\n\n Mobile Money & Digital Wallets: \n- Telebirr (In-app and USSD)\n- CBE Birr (Commercial Bank of Ethiopia)\n- Amole \n- M-PESA \n- Santimpay \n\n Bank Cards & International: \n- Ethswitch (Ethiopian banks)\n- Dashen Bank MasterCard \n- BOA (International cards)\n- Chapa payment gateway\n\n Other Methods: \n- YagoutPay payment gateway\n- AddisPay payment gateway\n- Cash on Delivery (ONLY available for delivery orders, NOT for self-pickup)\n- ZMall Wallet (Borsa) for balance top-up",
                  "Payment flow depends on your delivery method:\n\n For Self-Pickup Orders: \n- Sender/orderer MUST pay online (no cash option)\n- Use digital payment methods or ZMall Wallet\n- Payment required before order confirmation\n- Cannot pay cash at pickup location\n\n For Delivery Orders: \n- Two payment options available:\n - Cash on Delivery (COD): Receiver pays the delivery person in cash\n - Online Payment: Sender pays digitally before order confirmation\n- Flexibility exists because delivery person can collect payment\n- Sender chooses payment method during checkout\n\nKey Point: With delivery, either sender OR receiver can pay depending on payment method chosen. With self-pickup, only sender can pay (online only)",
                  "Yes, ZMall ensures payment security through:\n- Encrypted payment data transmission\n- Integration with certified payment providers\n- No storage of sensitive card details\n- Secure tokenization for saved payment methods\n- Compliance with payment industry standards",
                  "Borsa is ZMall's digital wallet:\n- Top-up balance for faster checkout\n- Pay for orders from wallet balance\n- View transaction history\n- Transfer funds between users\n- Convenient payment method for regular users",
                ],
              ),

              _buildCategoryCard(
                context,
                title: "Delivery & Logistics",
                icon: HeroiconsOutline.truck,
                color: Colors.teal,
                questions: [
                  "How is delivery fee calculated?",
                  "What are the delivery timeframes?",
                  "Can I tip the delivery person?",
                  "What if my order is late or wrong?",
                  "Do you deliver everywhere in the city?",
                ],
                answers: [
                  "Delivery fees are based on:\n- Distance between store and delivery address\n- Delivery urgency (express vs normal)",
                  "Typical delivery times:\n- Average delivery: 20-30 minutes (varies based on distance)\n- Longer distances: May take additional time\n- Peak hours: Slightly longer during busy periods\n- Scheduled orders: Delivered at your selected time\n- Laundry: Based on selected service level (3 hours to 5 days)",
                  "Yes, tipping is available:\n- Add tip during checkout\n- Quick tip options (+20, +30, +40 Birr)\n- Custom tip amount\n- Tip goes directly to delivery person",
                  "For order issues:\n1. Check order status in the app\n2. Contact delivery person if assigned\n3. Report issue through in-app support\n4. Request refund/replacement if applicable\n5. Rate your experience after delivery",
                  "Delivery coverage:\n- Primary service in Addis Ababa city limits\n- Check app for service availability in your area\n- Expanding coverage regularly",
                ],
              ),

              _buildCategoryCard(
                context,
                title: "Special Services",
                icon: HeroiconsOutline.star,
                color: Colors.pink,
                questions: [
                  "What is ZMall Global?",
                  "How does ZMall Global work?",
                  "Who typically uses ZMall Global?",
                  "How do courier services work?",
                ],
                answers: [
                  "ZMall Global is a special feature that enables users anywhere in the world to:\n- Order food, groceries, and gifts for their loved ones in Ethiopia\n- Send packages and deliveries to family and friends back home\n- Access all ZMall services remotely from any country\n- Pay using international payment methods\n- Support family members without being physically present\n- Perfect for diaspora communities wanting to care for relatives in Ethiopia",
                  "Using ZMall Global is simple:\n1. Access ZMall Global from the login screen or main menu\n2. Select items from Ethiopian stores and restaurants\n3. Enter your loved one's delivery address in Ethiopia\n4. Pay using international payment methods (online only)\n5. Track the delivery to your recipient\n6. If delivery: Recipient can receive without paying (you already paid online)\n7. Your family/friends receive the order in Ethiopia while you're anywhere in the world",
                  "ZMall Global is popular among:\n- Ethiopian diaspora living abroad (USA, Europe, Middle East, etc.)\n- International students wanting to send gifts home\n- Business travelers supporting family while away\n- Anyone wanting to surprise loved ones in Ethiopia\n- Organizations sending aid or support to Ethiopia\n- Anyone with international payment methods who wants to order for people in Ethiopia\n- Local users with international cards/payment access",
                  "Courier service features:\n- Send packages within the city\n- Attach image evidences\n- Multiple vehicle options\n- Track packages in real-time\n- Proof of delivery",
                ],
              ),

              _buildCategoryCard(
                context,
                title: "Support & Help",
                icon: HeroiconsOutline.questionMarkCircle,
                color: Colors.amber,
                questions: [
                  "How do I contact customer support?",
                  "How do I report a problem with my order?",
                  "Can I provide feedback or suggestions?",
                ],
                answers: [
                  "Support channels:\n- In-app chat support\n- Help center in the app\n- Report issues for specific orders\n- Email support\n- Phone support for urgent issues",
                  "To report issues:\n1. Go to profile section\n2. Select Help & support\n3. You will get all support methods and contacts",
                  "We welcome feedback:\n- Rate orders after delivery\n- App store reviews\n- Participate in surveys\n- Contact support with suggestions",
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> questions,
    required List<String> answers,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: getProportionateScreenHeight(kDefaultPadding),
      ),
      decoration: BoxDecoration(
        color: kWhiteColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        // boxShadow: [
        // BoxShadow(
        // color: kBlackColor.withValues(alpha: 0.08),
        // blurRadius: 8,
        // offset: Offset(0, 4),
        // ),
        // ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
          vertical: getProportionateScreenHeight(kDefaultPadding / 4),
        ),
        childrenPadding: EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: kWhiteColor),
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(color: kWhiteColor),
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        leading: Icon(icon, color: kBlackColor),

        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: kBlackColor),
        ),
        children: [
          for (int i = 0; i < questions.length; i++)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                getProportionateScreenHeight(kDefaultPadding),
              ),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                border: Border(top: BorderSide(color: kWhiteColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: getProportionateScreenHeight(8),
                children: [
                  Text(
                    "Q: ${questions[i]}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kBlackColor,
                    ),
                  ),

                  Text(
                    "A: ${answers[i]}",
                    style: TextStyle(color: kGreyColor, height: 1.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
