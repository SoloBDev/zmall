import 'package:flutter/cupertino.dart';
import 'package:zmall/service.dart';

class ZLanguage extends ChangeNotifier {
  String password = "Password";
  String country = "Country";
  String forgotPassword = "Forgot Password";
  String welcome = "Welcome to ZMall";
  String login = "Login";
  String zGlobal = "Go to ZMall Global?";
  String noAccount = "Don't have an account?";
  String register = "Register";

  String search = "Search";
  String hello = "Hello";
  String guest = "Guest";
  String specialForYou = "Special for you";
  String featuredStores = "Featured Stores";
  String nearbyStores = "Nearby Stores";
  String whatWould = "What would you like to order?";
  String missingHome = "Missing Home?";
  String predictAndwin = "Predict & Win";
  String thinkingOf = "Thinking of sending anything?";
  String yourFavorites = "Your Favorites";
  String discover = "Discover";
  String home = "Home";
  String orders = "Orders";
  String profile = "Profile";
  String profilePage = "Profile";
  String youAre = "You are";
  String ordersAway = "orders away from your next delivery cashback.";
  String nextOrderCashback =
      "Your delivery cashback is happening on the next order!";
  String discount = "Discount";

  String english = "English";
  String chinese = "Chinese";

  String language = "Language";
  String wallet = "Wallet";
  String help = "Help";
  String ettaCard = "Loyalty Card";
  String referralCode = "Referral Code";
  String referral = "Referral";
  String edit = "Edit";
  String logout = "Logout";

  String open = "Open";
  String closed = "Closed";
  String busy = "Busy";
  String kmAway = "KM away";
  String filter = "Filter";
  // String searchEngine = "Hi I'm Punjib Z-Search Engine";
  String searchEngine = "Hi I'm Z-Search Engine";
  String whatShould = "What should i search for you?";
  String nothingFound = "Nothing found";
  String tryAgain = "Please try again with a different item";
  String match = "Match";
  String priceFilter = "Price Filter";
  String cancel = "Cancel";

  String noExtra = "No extra specifications";
  String required = "Required";
  String chooseOne = "Choose 1";
  String price = "Price";
  String note = "Note";
  String warning = "Warning";
  String itemsFound =
      "Item(s) from a different store found in cart! Would you like to clear your cart?";
  String clear = "Clear";
  String addToCart = "Add to cart";
  String goToCart = "Go to Cart";

  String basket = "Basket";
  String remove = "Remove";
  String cartTotal = "Cart Total";
  String checkout = "Checkout";

  String deliveryDetails = "Delivery Details";
  String name = "Name";
  String phone = "Phone";
  String farDeliveryLocation =
      "You're a little too far from the store. Please choose a different delivery option or order from a store closer to your location.";
  String changeDetails = "Change Details";
  String orderForOthers = "Order For Others";
  String receiverPhone = "Receiver Phone";
  String submit = "Submit";
  String startPhone = "Start phone number with 9";
  String locations = "Locations";
  String addLocation = "Add Location";
  String useCurrentLocation = "Use current location";
  String currentLocation = "Current Location";
  String userPickup = "User Pickup";
  String selfPickup = "Self Pickup";
  String location = "Location";
  String cont = "Continue";

  String deliveryOptions = "Delivery Options";
  String asSoon = "As Soon as Possible";
  String expressOrder = "Express Order";
  String scheduleOrder = "Schedule an order";
  String addDate = "Add Date & Time";
  String preOrder = "Pre Order";
  String diy = "Do It Yourself";
  String deliveryAddress = "Delivery Address";
  String orderDetail = "Order Detail";
  String servicePrice = "Service Price";
  String totalOrderPrice = "Total Order Price";
  String promoPayment = "Promo Payment";
  String tip = "Tip";
  String addTip = "Add Tip";
  String orderTime = "Your order is estimated to arrive between";
  String total = "Total";
  String applyPromoCode = "Apply Promo Code";
  String placeOrder = "Place Order";
  String promoCode = "Prom Code";
  String apply = "Apply";

  String payments = "Payments";
  String howWouldYouPay = "How would you like to pay";
  String balance = "Balance";
  String addFundsInfo = "Add funds to your wallet from profile screen";
  String selectPayment = "Select Payment Method";
  String onlyDigitalPayments = "Only Digital Payments Accepted";
  String cash = "Cash";
  String zWallet = "Z-Wallet";
  String telebirr = "Telebirr";
  String amole = "Amole";
  String boa = "Bank Of Abyssinia";
  String zemen = "Zemen Bank";

  String activeOrders = "Active Orders";
  String orderHistory = "Order History";
  String orderNumber = "Order Number";
  String reorder = "Reorder";
  String details = "Details";
  String invoice = "Invoice";
  String cart = "Cart";
  String thankYou = "Thank you!";
  String orderDetails = "Order Details";
  String enjoyingZmall = "Are you enjoying ZMall?";
  String rateUs = "Rate Us";
  String rateReviewBlock =
      "Your review helps spread the word and grow our ZMall Community. Whether you love us or feel like we can do better we want to know!";
  String totalServicePrive = "Total Service Price";
  String cartPrice = "Cart Price";
  String totalCartPrice = "Total Cart Price";
  String online = "Online";
  String receivedBy = "Order received by";
  String deliveredBy = "Order delivered by";
  String promo = "Promo";
  String totalPromo = "Total Promo";
  String quantity = "Quantity";

  void changeLanguage(String newString) {
    debugPrint("Setting language to $newString");
    if (newString == "en_US") {
      password = "Password";
      country = "Country";
      forgotPassword = "Forgot Password";
      welcome = "Welcome to ZMall";
      login = "Login";
      zGlobal = "Go to ZMall Global?";
      noAccount = "Don't have an account?";
      register = "Register";

      search = "Search";
      hello = "Hello";
      guest = "Guest";
      specialForYou = "Special for you";
      featuredStores = "Featured Stores";
      nearbyStores = "Nearby Stores";
      whatWould = "What would you like to order?";
      missingHome = "Missing Home?";
      predictAndwin = "Predict & Win";
      thinkingOf = "Thinking of sending anything?";
      yourFavorites = "Your Favorites";
      discover = "Discover";
      home = "Home";
      orders = "Orders";
      profile = "Profile";
      profilePage = "Profile";
      youAre = "You are";
      ordersAway = "orders away from your next delivery cashback.";
      nextOrderCashback =
          "Your delivery cashback is happening on the next order!";
      discount = "Discount";

      wallet = "Wallet";
      help = "Help";
      ettaCard = "Loyalty Card";
      referralCode = "Referral Code";
      referral = "Referral";
      edit = "Edit";
      logout = "Logout";

      filter = "Filter";
      // searchEngine = "Hi I'm Punjib Z-Search Engine";
      searchEngine = "Hi I'm Z-Search Engine";
      whatShould = "What should i search for you?";
      nothingFound = "Nothing found";
      tryAgain = "Please try again with a different item";
      match = "Match";
      open = "Open";
      closed = "Closed";
      busy = "Busy";
      kmAway = "KM away";
      priceFilter = "Price Filter";
      cancel = "Cancel";

      noExtra = "No extra specifications";
      required = "Required";
      chooseOne = "Choose 1";
      price = "Price";
      note = "Note";
      clear = "Clear";
      warning = "Warning";
      itemsFound =
          "Item(s) from a different store found in cart! Would you like to clear your cart?";
      addToCart = "Add to cart";
      goToCart = "Go to Cart";

      basket = "Basket";
      remove = "Remove";
      cartTotal = "Cart Total";
      checkout = "Checkout";

      deliveryDetails = "Delivery Details";
      name = "Name";
      phone = "Phone";
      farDeliveryLocation =
          "You're a little too far from the store. Please choose a different delivery option or order from a store closer to your location.";
      changeDetails = "Change Details";
      orderForOthers = "Order For Others";
      receiverPhone = "Receiver Phone";
      startPhone = "Start phone number with 9 or 7";
      submit = "Submit";
      locations = "Locations";
      addLocation = "Add Location";
      useCurrentLocation = "Use current location";
      currentLocation = "Current Location";
      userPickup = "User Pickup";
      selfPickup = "Self Pickup";
      location = "Location";
      cont = "Continue";

      english = "English";
      chinese = "简体中文";
      language = "Language";

      deliveryOptions = "Delivery Options";
      asSoon = "As Soon as Possible";
      expressOrder = "Express Order";
      scheduleOrder = "Schedule an order";
      addDate = "Add Date & Time";
      preOrder = "Pre Order";
      diy = "Do It Yourself";
      deliveryAddress = "Delivery Address";
      orderDetail = "Order Detail";
      servicePrice = "Service Price";
      totalOrderPrice = "Total Order Price";
      promoPayment = "Promo Payment";
      tip = "Tip";
      addTip = "Add Tip";
      orderTime = "Your order is estimated to arrive between";
      total = "Total";
      applyPromoCode = "Apply Promo Code";
      placeOrder = "Place Order";
      promoCode = "Prom Code";
      apply = "Apply";

      payments = "Payments";
      howWouldYouPay = "How would you like to pay";
      balance = "Z-Wallet Balance";
      addFundsInfo = "Add funds to your wallet from profile screen";
      selectPayment = "Select Payment Method";
      onlyDigitalPayments = "Only Digital Payments Accepted";
      cash = "CASH";
      zWallet = "Z-WALLET";
      telebirr = "TELEBIRR";
      amole = "AMOLE";
      boa = "BANK OF ABYSSINIA";
      zemen = "ZEMEN BANK";

      activeOrders = "Active Orders";
      orderHistory = "Order History";
      orderNumber = "Order Number";
      reorder = "Reorder";
      details = "Details";
      invoice = "Invoice";
      cart = "Cart";
      thankYou = "Thank you!";
      orderDetails = "Order Details";
      enjoyingZmall = "Are you enjoying ZMall?";
      rateUs = "Rate Us";
      rateReviewBlock =
          "Your review helps spread the word and grow our ZMall Community. Whether you love us or feel like we can do better we want to know!";
      totalServicePrive = "Total Service Price";
      cartPrice = "Cart Price";
      totalCartPrice = "Total Cart Price";
      online = "Online";

      receivedBy = "Order received by";
      deliveredBy = "Order delivered by";
      promo = "Promo";
      totalPromo = "Total Promo";
      quantity = "Quantity";

      Service.save("lang", "en_US");
    } else if (newString == "cn_CN") {
      password = "密码";
      country = "国家";
      login = "登录";
      forgotPassword = "忘记密码";
      welcome = "欢迎 ZMall 用户";
      zGlobal = "ZMall国际版";
      noAccount = "没有账号";
      register = "注册";

      search = "搜索";
      hello = "您好";
      specialForYou = "为您推荐";
      featuredStores = "推荐商家";
      nearbyStores = "附近商家";
      whatWould = "您今天想点什么？";
      missingHome = "想家?";
      thinkingOf = "快递";
      yourFavorites = "收藏";
      discover = "发现";
      home = "首页";
      orders = "订单";
      profile = "我";
      profilePage = "个人信息";
      youAre = "您";
      ordersAway = "个订单后收送费返现";
      nextOrderCashback = "下个订单收送费返现";
      discount = "优惠";

      wallet = "钱包";
      help = "帮助";
      ettaCard = "会员卡";
      referralCode = "引荐码";
      referral = "引荐";
      edit = "编辑";
      logout = "退出";

      filter = "筛选";
      searchEngine = "您好，我叫 Punjib 搜索引擎";
      whatShould = "搜一搜";
      nothingFound = "暂无相关结果";
      tryAgain = "您可尝试更换搜索词";
      match = "相配";
      open = "营业";
      closed = "关门";
      busy = "忙";
      kmAway = "公里";
      priceFilter = "价格筛选";
      cancel = "取消";

      noExtra = "无规格";
      required = "必要";
      chooseOne = "选";
      price = "价格";
      note = "留言";
      clear = "清空";
      warning = "提醒";
      itemsFound = "车库里已经有另一家商店的品目！确认先清空购物车？";
      addToCart = "加入购物库";
      goToCart = "购物库";

      basket = "车库";
      remove = "解除";
      cartTotal = "购物车总价";
      checkout = "结算";

      deliveryDetails = "寄递详细";
      name = "姓名";
      phone = " 手机号";
      farDeliveryLocation = "您定位位置离商店有点远！请您更改离您最近的商店或者修还基地选项";
      changeDetails = "更改";
      orderForOthers = "为亲人点";
      receiverPhone = "亲人电话";
      startPhone = "手机号为 9 或 7 开始";
      submit = "提交";
      locations = "地址";
      addLocation = "添加地址";
      useCurrentLocation = "用当前定位";
      currentLocation = "当前定位";
      userPickup = "自取";
      selfPickup = "自取";
      location = "地址";
      cont = "继续结算";

      english = "English";
      chinese = "简体中文";
      language = "语言";

      deliveryOptions = "寄递选项";
      asSoon = "马上寄送";
      expressOrder = "快送";
      scheduleOrder = "预约订单";
      addDate = "添加日点";
      preOrder = "预约";
      diy = "自取";
      deliveryAddress = "外送地址";
      orderDetail = "订单详细";
      servicePrice = "运费";
      totalOrderPrice = "购物车总价";
      promoPayment = "优惠";
      tip = "小费";
      addTip = "给小费";
      orderTime = "这订单预约到达时间为";
      total = "总价";
      applyPromoCode = "添加优惠";
      placeOrder = "订单";
      promoCode = "优惠";
      apply = "提交";

      payments = "支付";
      howWouldYouPay = "您想怎么支付";
      balance = "Z-包余额";
      addFundsInfo = "请从自我页面里加余额";
      selectPayment = "选支付方式";
      onlyDigitalPayments = "不收现金，只能网上支付";
      cash = "现金";
      zWallet = "Z-包";
      telebirr = "Tele比尔";
      amole = "Amole";
      boa = "阿比西尼亚银行";
      zemen = "则门银行";
      activeOrders = "持续订单";
      orderHistory = "订单历史";
      orderNumber = "订单号";
      reorder = "再来订";
      details = "详细";
      invoice = "订单发票";
      cart = "车库";
      thankYou = "谢谢!";
      orderDetails = "订单详细";
      enjoyingZmall = "喜欢用ZMall吗?";
      rateUs = "点评";
      rateReviewBlock = "您的评论很有帮助传播并且发展 ZMall 社区。 无论您爱我们还是觉得我们可以做得更好，我们都想知道！";
      totalServicePrive = "总服务价";
      cartPrice = "车库价";
      totalCartPrice = "总车库价";
      online = "线上";

      receivedBy = "收件人";
      deliveredBy = "送货人";
      promo = "优惠";
      totalPromo = "总有会";
      quantity = "数量";

      Service.save("lang", "cn_CN");
    }
    notifyListeners();
    debugPrint("Language changed....");
  }
}
