import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zmall/borsa/components/payment_card.dart';
import 'package:zmall/borsa/topup_kifiya/inapp_topup_payment.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'package:zmall/widgets/order_status_row.dart';
import 'package:zmall/widgets/sliver_appbar_delegate.dart';

class BorsaScreen extends StatefulWidget {
  static String routeName = '/borsa';

  const BorsaScreen({super.key, @required this.userData});

  final userData;

  @override
  _BorsaScreenState createState() => _BorsaScreenState();
}

class _BorsaScreenState extends State<BorsaScreen> {
  var userData;
  late String otp;
  var responseData;
  var kifiyaGateway;
  bool isLoading = false;
  String payeePhone = "";
  double topUpAmount = 0.0;
  String payerPassword = "";
  bool transferError = false;
  var selectedFilter = "All";
  double currentBalance = 0.0;
  // bool isTopupEnabled = false;
  var isTopupEnabled;
  bool transferLoading = false;
  String transferAmount = "0.00";

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
    currentBalance = double.parse(widget.userData['user']['wallet'].toString());
    _getTransactions();
  }

  void _userDetails() async {
    var usrData = await userDetails();
    if (usrData != null && usrData['success']) {
      setState(() {
        userData = usrData;
        currentBalance = double.parse(userData['user']['wallet'].toString());
      });
      Service.save('user', userData);
    }
  }

  void _getTransactions() async {
    setState(() {
      isLoading = true;
    });
    await transactionHistoryDetails();

    if (responseData != null && responseData['success']) {
      setState(() {
        isLoading = false;
        isTopupEnabled =
            responseData["wallet_history"][0]["wallet_top_up_option"];
      });
    } else {
      if (responseData['error_code'] != null &&
          responseData['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        isLoading = false;
      });
      if (responseData['error_code'] != null &&
          errorCodes['${responseData['error_code']}'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${errorCodes['${responseData['error_code']}']}"),
            backgroundColor: kSecondaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No wallet transaction history"),
            backgroundColor: kSecondaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Wallet",
          style: TextStyle(
            color: kBlackColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _zWalletCard(textTheme: textTheme)),

          // Transactions Section
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverAppBarDelegate(
              minHeight: getProportionateScreenWidth(80),
              maxHeight: getProportionateScreenWidth(80),
              child: Container(
                color: kPrimaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding),
                  vertical: getProportionateScreenHeight(kDefaultPadding / 4),
                ),
                child: Column(
                  spacing: getProportionateScreenHeight(kDefaultPadding / 2),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Text(
                      "Transactions",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                      ),
                    ),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            "All",
                            HeroiconsOutline.arrowPathRoundedSquare,
                            selectedFilter == "All",
                            () {
                              setState(() {
                                selectedFilter = "All";
                              });
                            },
                          ),
                          SizedBox(width: 12),
                          _buildFilterChip(
                            "Received",
                            HeroiconsOutline.arrowDown,
                            selectedFilter == "Received",
                            () {
                              setState(() {
                                selectedFilter = "Received";
                              });
                            },
                          ),
                          SizedBox(width: 12),
                          _buildFilterChip(
                            "Sent",
                            HeroiconsOutline.arrowUp,
                            selectedFilter == "Sent",
                            () {
                              setState(() {
                                selectedFilter = "Sent";
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (responseData == null || !responseData['success'])
            SliverToBoxAdapter(
              child: isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: kDefaultPadding * 2,
                        ),
                        child: SpinKitWave(
                          color: kSecondaryColor,
                          size: getProportionateScreenWidth(kDefaultPadding),
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: kDefaultPadding * 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              HeroiconsOutline.arrowsUpDown,
                              size: 60,
                              color: kGreyColor.withValues(alpha: 0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No wallet history found!",
                              style: TextStyle(color: kGreyColor, fontSize: 16),
                            ),
                            Text(
                              "Add funds to your wallet",
                              style: TextStyle(
                                color: kGreyColor.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

          if (responseData != null &&
              responseData['wallet_history'] != null &&
              responseData['wallet_history'].length == 0)
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      HeroiconsOutline.wallet,
                      size: 64,
                      color: kGreyColor.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No wallet transactions yet!",
                      style: TextStyle(color: kGreyColor, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Transactions List
          if (responseData != null &&
              responseData['wallet_history'] != null &&
              responseData['wallet_history'].length != 0)
            SliverList(
              delegate: SliverChildBuilderDelegate(childCount: 1, (
                BuildContext context,
                int index,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: kDefaultPadding),
                  child: _buildTransactionsList(),
                );
              }),
            ),
        ],
      ),
    );
  }

  ShowPaymentOption() {
    // bool showPayments = false;
    GlobalKey<FormState> topupFormKey = GlobalKey<FormState>();
    // TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kPrimaryColor,
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * 0.55,
        maxHeight: MediaQuery.sizeOf(context).height * 1.0,
      ),
      builder: (BuildContext context) {
        // var uuid = Uuid();
        // String uniqueId = uuid.v4().substring(0, 10);
        var uuid = Uuid();
        String uniqueId = uuid
            .v4()
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
            .substring(0, 10);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    kDefaultPadding, // Adjust for keyboard
              ),
              child: SafeArea(
                minimum: EdgeInsets.only(
                  left: getProportionateScreenWidth(kDefaultPadding),
                  right: getProportionateScreenWidth(kDefaultPadding),
                  top: getProportionateScreenHeight(kDefaultPadding / 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(kDefaultPadding),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: getProportionateScreenHeight(kDefaultPadding),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Add to Wallet",
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                              ),
                              // if (showPayments)
                              Text(
                                "Add $topUpAmount to Wallet",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.cancel_outlined,
                                color: kBlackColor.withValues(alpha: 0.5),
                              ),
                              // style: IconButton.styleFrom(
                              //     backgroundColor: kWhiteColor),
                            ),
                          ),
                        ],
                      ),
                      Form(
                        key: topupFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: getProportionateScreenHeight(
                            kDefaultPadding,
                          ),
                          children: [
                            CustomTextField(
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  // Safely parse to double, default to 0.0 if empty
                                  topUpAmount = double.tryParse(
                                    val,
                                  )!.ceilToDouble();
                                });
                              },
                              hintText: "Enter the amount to topup",
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter the amount";
                                }

                                // Try parsing the value
                                final double? price = double.tryParse(value);

                                if (price == null) {
                                  return "Invalid number entered.";
                                }

                                if (price < 100.0) {
                                  final currency = Provider.of<ZMetaData>(
                                    context,
                                    listen: false,
                                  ).currency;
                                  // return "The minimum amount you can add is 1 $currency.";
                                  return "The minimum amount you can add is 100 $currency.";
                                }
                                if (price == 0.0) {
                                  return "Amount cannot be zero.";
                                }
                                return null;
                              },
                            ),
                            SizedBox(
                              height: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                            ),
                            // if (showPayments)
                            Text(
                              "Continue topup",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            // if (showPayments)
                            PaymentCard(
                              title: "Telebirr InApp",
                              subtitle: "Pay with mobile app",
                              imageUrl: "images/telebirr.png",
                              onPressed: () {
                                if (topupFormKey.currentState!.validate()) {
                                  _getKifiyaGateway();

                                  if (kifiyaGateway != null &&
                                      kifiyaGateway['success'] &&
                                      kifiyaGateway['payment_gateway'] !=
                                          null) {
                                    final telebirrId = getPaymentMethodIdByName(
                                      "Telebirr inapp",
                                    );

                                    setState(() {
                                      paymentId = telebirrId;
                                    });
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return TopupPaymentInApp(
                                            amount: topUpAmount,
                                            context: context,
                                            traceNo: uniqueId,
                                            phone: userData['user']['phone'],
                                          );
                                        },
                                      ),
                                    ).then((value) async {
                                      if (value != null) {
                                        if (value == false) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                setState(() {
                                                  topUpAmount = 0.0;
                                                });
                                              });
                                          Navigator.of(context).pop();
                                          Service.showMessage(
                                            error: true,
                                            context: context,
                                            title:
                                                "Faild to topup wallet amount. Please try again!.",
                                          );
                                        } else if ((value['code'] != null &&
                                                value['code'] == 0) ||
                                            (value['status'] != null &&
                                                value['status']
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "success")) {
                                          _addToWallet();
                                        }
                                      } else {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              setState(() {
                                                topUpAmount = 0.0;
                                              });
                                            });
                                        Navigator.of(context).pop();

                                        Future.delayed(
                                          Duration(milliseconds: 100),
                                          () {
                                            if (mounted) {
                                              Service.showMessage(
                                                error: true,
                                                context: context,
                                                title:
                                                    "Faild to topup wallet amount. Please try again!.",
                                              );
                                            }
                                          },
                                        );
                                      }
                                    });
                                  }
                                }
                              },
                            ),
                            // if (!showPayments && amountController.text.isNotEmpty)
                            //   CustomButton(
                            //     title: "Submit",
                            //     isLoading: isLoading,
                            //     press: () async {
                            //       if (topupFormKey.currentState!.validate()) {
                            //         setState(() {
                            //           showPayments = true;
                            //         });
                            //       }
                            //     },
                            //   ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _userDetails();
      _getTransactions();
    });
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
        vertical: getProportionateScreenHeight(kDefaultPadding / 2),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: OrderStatusRow(
          icon: icon,
          value: title,
          title: subtitle,
          iconColor: color,
          textColor: kWhiteColor,
          iconBackgroundColor: color.withValues(alpha: 0.1),
          fontSize: getProportionateScreenWidth(14),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    Color color = label.toLowerCase() == "sent"
        ? kSecondaryColor
        : label.toLowerCase() == "received"
        ? kGreenColor
        : kGreyColor;
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(kDefaultPadding),
          vertical: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              // kSecondaryColor.withValues(alpha: 0.18)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: !isSelected
              ? null
              : [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          spacing: getProportionateScreenWidth(kDefaultPadding / 2),
          children: [
            Icon(icon, size: 18, color: color),
            Text(
              label,
              style: TextStyle(
                color: color,
                // color: isSelected ?  kSecondaryColor : kGreyColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Filter transactions based on selected filter
    List filteredTransactions = [];
    filteredTransactions = responseData['wallet_history'].where((transaction) {
      bool isDeposit =
          transaction['wallet_amount'] < transaction['total_wallet_amount'];

      if (selectedFilter == "Received") return isDeposit;
      if (selectedFilter == "Sent") return !isDeposit;
      return true; // "All"
    }).toList();

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filteredTransactions.length,
      separatorBuilder: (context, idx) =>
          SizedBox(height: getProportionateScreenWidth(kDefaultPadding / 2)),
      padding: EdgeInsets.symmetric(
        // vertical: getProportionateScreenWidth(kDefaultPadding / 2),
        horizontal: getProportionateScreenWidth(kDefaultPadding / 2),
      ),
      itemBuilder: (context, idx) {
        var transaction = filteredTransactions[idx];
        bool isDeposit =
            transaction['wallet_amount'] < transaction['total_wallet_amount'];

        return Container(
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kWhiteColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding / 1.5),
              vertical: 0,
            ),
            leading: Container(
              padding: EdgeInsets.all(
                getProportionateScreenWidth(kDefaultPadding / 2),
              ),
              decoration: BoxDecoration(
                color: (isDeposit ? kGreenColor : kSecondaryColor).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeposit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isDeposit ? kGreenColor : kSecondaryColor,
                size: 20,
              ),
            ),
            title: Text(
              transaction['wallet_description'] != "Card : undefined"
                  ? transaction['wallet_description']
                  : "Online Top-up",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: kBlackColor,
              ),
            ),
            subtitle: Text(
              "${transaction['updated_at'].split("T")[0]} ${transaction['updated_at'].split("T")[1].split('.')[0]}",
              style: TextStyle(fontSize: 12, color: kGreyColor),
            ),
            trailing: RichText(
              text: TextSpan(
                text: isDeposit ? "+ " : "- ",
                style: TextStyle(
                  color: isDeposit ? kGreenColor : kSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        "${Provider.of<ZMetaData>(context, listen: false).currency} ",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: transaction['from_amount'].toStringAsFixed(2),
                    style: TextStyle(
                      color: isDeposit ? kGreenColor : kSecondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransferBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kPrimaryColor,
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * 0.55,
        maxHeight: MediaQuery.sizeOf(context).height * 1.0,
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SafeArea(
              minimum: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding),
                vertical: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(kDefaultPadding),
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: getProportionateScreenHeight(kDefaultPadding),
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transfer",
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(HeroiconsOutline.xCircle),
                        ),
                      ],
                    ),

                    CustomTextField(
                      // style: TextStyle(color: kBlackColor),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        FilteringTextInputFormatter.singleLineFormatter,
                      ],
                      maxLength: 9,
                      onChanged: (val) {
                        payeePhone = val;
                      },
                      // decoration: textFieldInputDecorator.copyWith(
                      hintText: "Enter receiver number",
                      helperText: "Start phone number with 9..",
                      // hintText: "...",
                      // prefix: Text(
                      //     "${Provider.of<ZMetaData>(context, listen: false).areaCode}"),
                      // ),
                    ),

                    //
                    CustomTextField(
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (val) {
                        transferAmount = val;
                      },
                      // labelText: "Amount",
                      hintText: "Enter amount",
                    ),

                    //
                    CustomTextField(
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      onChanged: (val) {
                        payerPassword = val;
                      },
                      // labelText: "Password",
                      hintText: "Enter your password",
                    ),

                    if (transferError)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "Invalid! Please make sure all fields are filled.",
                          style: TextStyle(color: kSecondaryColor),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        title: "Send",
                        isLoading: transferLoading,
                        color: kSecondaryColor,
                        press: () async {
                          // Your existing transfer logic here
                          if (payeePhone.isNotEmpty &&
                              transferAmount.isNotEmpty &&
                              payerPassword.isNotEmpty) {
                            setState(() {
                              transferLoading = true;
                            });
                            var data = await genzebLak();
                            if (data != null && data['success']) {
                              setState(() {
                                transferLoading = false;
                                widget.userData['user']['wallet'] -=
                                    double.parse(transferAmount);
                              });
                              _userDetails();
                              _getTransactions();

                              Service.showMessage(
                                context: context,
                                title: "Transfer successful",
                                error: false,
                                duration: 5,
                              );
                              setState(() {
                                transferLoading = false;
                              });
                              Navigator.of(context).pop();
                            } else {
                              if (data['error_code'] == 999) {
                                await Service.saveBool('logged', false);
                                await Service.remove('user');
                                Navigator.pushReplacementNamed(
                                  context,
                                  LoginScreen.routeName,
                                );
                              }
                              setState(() {
                                transferLoading = false;
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${errorCodes['${data['error_code']}']}",
                                  ),
                                  backgroundColor: kSecondaryColor,
                                ),
                              );
                            }
                          } else {
                            setState(() {
                              transferError = true;
                            });

                            Service.showMessage(
                              context: context,
                              title:
                                  "Invalid! Please make sure all fields are filled.",
                              error: true,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        payeePhone = '';
        transferAmount = '0.00';
        payerPassword = '';
        transferError = false;
      });
    });
  }

  //
  bool _isBalanceVisible = false;
  Widget _zWalletCard({required TextTheme textTheme}) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(kDefaultPadding),
        vertical: getProportionateScreenHeight(kDefaultPadding),
      ),

      // height: getProportionateScreenHeight(215),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main card background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  getProportionateScreenWidth(kDefaultPadding),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kSecondaryColor.withValues(alpha: 1.0),
                    kSecondaryColor.withValues(alpha: 0.7),
                    kSecondaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Card content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding),
              vertical: getProportionateScreenHeight(kDefaultPadding),
            ),
            child: Column(
              // spacing: 4,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section with logo and card type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quick Pay",
                          style: textTheme.labelLarge!.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          "Z-WALLET CARD",
                          style: textTheme.bodyMedium!.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    // Balance visibility toggle button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(
                            kDefaultPadding / 2.5,
                          ),
                          vertical: getProportionateScreenHeight(
                            kDefaultPadding / 2.5,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: kWhiteColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            kDefaultPadding / 2,
                          ),
                        ),
                        child: Row(
                          spacing: getProportionateScreenWidth(
                            kDefaultPadding / 4,
                          ),
                          children: [
                            Text(
                              _isBalanceVisible ? "Hide" : "Show",
                              style: TextStyle(color: kPrimaryColor),
                            ),
                            Icon(
                              _isBalanceVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                //
                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 2),
                ),

                //Middle section//balance and name
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ///balance
                      Text(
                        _isBalanceVisible
                            ? "${Provider.of<ZMetaData>(context, listen: false).currency} ${currentBalance.toStringAsFixed(2)}"
                            : "**** **** ****",
                        style: textTheme.labelLarge!.copyWith(
                          color: kWhiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontStyle: _isBalanceVisible
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),

                      // name
                      Text(
                        "${widget.userData['user']['first_name'] ?? ''} ${widget.userData['user']['last_name'] ?? ''}"
                            .trim()
                            .toUpperCase(),
                        style: textTheme.labelLarge!.copyWith(
                          color: kWhiteColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                ////////////////////////////////////////////////

                // Spacer(),
                Divider(color: kWhiteColor.withValues(alpha: 0.2)),
                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 2),
                ),
                ////bottom section ///
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: getProportionateScreenWidth(kDefaultPadding),
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: HeroiconsOutline.paperAirplane,
                        title: "Transfer",
                        subtitle: "Send funds",
                        color: kWhiteColor,
                        onTap: () => _showTransferBottomSheet(context),
                      ),
                    ),
                    if (isTopupEnabled != null && isTopupEnabled)
                      Expanded(
                        child: _buildActionCard(
                          icon: HeroiconsOutline.plusCircle,
                          title: "Top-up",
                          subtitle: "Add funds",
                          color: kWhiteColor,
                          onTap: () {
                            ShowPaymentOption();
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Decorative circles
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -25,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> transactionHistoryDetails() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/get_wallet_history";
    Map data = {
      "id": widget.userData['user']['_id'],
      "type": widget.userData['user']['admin_type'],
      "server_token": widget.userData['user']['server_token'],
    };
    var body = json.encode(data);

    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Network error",
                error: true,
              );

              throw TimeoutException("The connection has timed out!");
            },
          );

      responseData = json.decode(response.body);
      return json.decode(response.body);
    } catch (e) {
      return null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<dynamic> userDetails() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_detail";
    Map data = {
      "user_id": userData['user']['_id'],
      "server_token": userData['user']['server_token'],
    };
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Network error",
                error: true,
              );

              throw TimeoutException("The connection has timed out!");
            },
          );
      return json.decode(response.body);
    } catch (e) {
      return null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<dynamic> genzebLak() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/transfer_wallet_amount";
    Map data = {
      "user_id": widget.userData['user']['_id'],
      "top_up_user_phone": payeePhone,
      "password": payerPassword,
      "wallet": transferAmount,
      "server_token": widget.userData['user']['server_token'],
    };
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              Service.showMessage(
                context: context,
                title: "Network error",
                error: true,
              );

              throw TimeoutException("The connection has timed out!");
            },
          );
      return json.decode(response.body);
    } catch (e) {
      return null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  ////Topup wallet ammount//
  Future<void> _addToWallet() async {
    try {
      var data = await amoleAddToBorsa();

      if (data != null && data['success']) {
        // userData['user']['wallet'] += topUpAmount;
        // Service.save('user', userData);
        Navigator.of(context).pop();
        Service.showMessage(
          context: context,
          title: "Wallet top-up completed successfully!",
          error: false,
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      Service.showMessage(
        context: context,
        title:
            "Add to wallet failed! Please check if you have sufficient fund.",
        error: true,
        duration: 4,
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          topUpAmount = 0.0;
          isLoading = false;
        });
      });
    }
  }

  String paymentId = '';
  String getPaymentMethodIdByName(String name) {
    final methods = kifiyaGateway['payment_gateway'] as List;
    final method = methods.firstWhere(
      (m) => m['name'].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => null,
    );
    return method != null ? method['_id'] : '';
  }

  Future<dynamic> amoleAddToBorsa() async {
    setState(() {
      isLoading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_wallet_amount_new";

    Map data = {
      "user_id": userData['user']['_id'],
      "payment_id": paymentId,
      // kifiyaGateway['payment_gateway'][0]['_id'],
      // "otp": otp,
      "is_payment_paid": true,
      "type": userData['user']['admin_type'],
      "server_token": userData['user']['server_token'],
      "wallet": topUpAmount,
    };

    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              setState(() {
                this.isLoading = false;
              });
              Service.showMessage(
                error: true,
                context: context,
                title: "Something went wrong!",
              );
              throw TimeoutException("The connection has timed out!");
            },
          );
      return json.decode(response.body);
    } catch (e) {
      Service.showMessage(
        error: true,
        context: context,
        title: "Your internet connection is bad!",
      );
      return null;
    } finally {
      setState(() {
        this.isLoading = false;
      });
    }
  }

  ///_getKifiyaGateway
  ///
  ///
  void _getKifiyaGateway() async {
    setState(() {
      isLoading = true;
    });
    try {
      var data = await getKifiyaGateway();
      if (data != null && data['success']) {
        setState(() {
          kifiyaGateway = data;
        });
      } else {
        Service.showMessage(
          context: context,
          title: "${errorCodes['${data['error_code']}']}!",
          error: true,
        );
        await Future.delayed(Duration(seconds: 2));
        if (data['error_code'] == 999) {
          await Service.saveBool('logged', false);
          await Service.remove('user');
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      }
    } catch (e) {
      Service.showMessage(
        context: context,
        title: "Something went wrong, please try agin!",
        error: true,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<dynamic> getKifiyaGateway() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_payment_gateway";
    Map data = {
      "user_id": widget.userData['user']['_id'],
      "city_id": "5b406b46d2ddf8062d11b788",
      "server_token": widget.userData['user']['server_token'],
    };
    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException("The connection has timed out!");
            },
          );

      return json.decode(response.body);
    } catch (e) {
      Service.showMessage(
        context: context,
        title:
            "Something went wrong, please check your connection and try again!",
        error: true,
      );
      return null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class CustomCard extends StatelessWidget {
  const CustomCard({
    Key? key,
    required this.iconData,
    required this.title,
    required this.press,
    required this.subtitle,
    required this.color,
    required this.textColor,
  }) : super(key: key);

  final IconData iconData;
  final String title, subtitle;
  final Color color, textColor;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: press,
        child: Container(
          height: getProportionateScreenHeight(kDefaultPadding * 8),
          decoration: BoxDecoration(
            color: color,
            // boxShadow: [kDefaultShadow],
            borderRadius: BorderRadius.circular(
              getProportionateScreenWidth(kDefaultPadding),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: getProportionateScreenHeight(kDefaultPadding),
              horizontal: getProportionateScreenWidth(kDefaultPadding),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconData, color: textColor),
                Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 5),
                ),
                Text(subtitle, style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// !showPayments
//                         ? Form(
//                             key: topupFormKey,
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               spacing:
//                                   getProportionateScreenHeight(kDefaultPadding),
//                               children: [
//                                 CustomTextField(
//                                   // style: TextStyle(color: kBlackColor),
//                                   keyboardType: TextInputType.numberWithOptions(
//                                       decimal: true),
//                                   onChanged: (val) {
//                                     setState(() {
//                                       // Safely parse to double, default to 0.0 if empty
//                                       topUpAmount = double.tryParse(val) ?? 0.0;
//                                     });
//                                   },

//                                   hintText: "Enter the amount to send",
//                                   validator: (value) {
//                                     if (value == null || value.isEmpty) {
//                                       WidgetsBinding.instance
//                                           .addPostFrameCallback((_) {
//                                         // Use postFrameCallback to avoid setState during build
//                                         if (mounted && showPayments) {
//                                           // Check if mounted and payments were shown
//                                           setState(() {
//                                             showPayments = false;
//                                           });
//                                         }
//                                       });
//                                       return "Please enter the amount";
//                                     }

//                                     // Try parsing the value
//                                     final double? price =
//                                         double.tryParse(value);

//                                     if (price == null) {
//                                       WidgetsBinding.instance
//                                           .addPostFrameCallback((_) {
//                                         if (mounted && showPayments) {
//                                           setState(() {
//                                             showPayments = false;
//                                           });
//                                         }
//                                       });
//                                       return "Invalid number entered.";
//                                     }

//                                     if (price < 100.0) {
//                                       // Changed to < 100.0 as per your message
//                                       WidgetsBinding.instance
//                                           .addPostFrameCallback((_) {
//                                         if (mounted && showPayments) {
//                                           setState(() {
//                                             showPayments = false;
//                                           });
//                                         }
//                                       });
//                                       final currency = Provider.of<ZMetaData>(
//                                               context,
//                                               listen: false)
//                                           .currency;
//                                       return "The minimum amount you can add is 100 $currency.";
//                                     }
//                                     if (price == 0.0) {
//                                       WidgetsBinding.instance
//                                           .addPostFrameCallback((_) {
//                                         if (mounted && showPayments) {
//                                           setState(() {
//                                             showPayments = false;
//                                           });
//                                         }
//                                       });
//                                       return "Amount cannot be zero.";
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                                 CustomButton(
//                                   title: "Submit",
//                                   isLoading: isLoading,
//                                   press: () async {
//                                     if (topupFormKey.currentState!.validate()) {
//                                       setState(() {
//                                         showPayments = true;
//                                       });
//                                     }
//                                   },
//                                 ),
//                               ],
//                             ),
//                           )
//                         : Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             spacing:
//                                 getProportionateScreenHeight(kDefaultPadding),
//                             children: [
//                               PaymentCard(
//                                 title: "Telebirr InApp",
//                                 subtitle: "Pay with mobile app",
//                                 imageUrl: "images/telebirr.png",
//                                 onPressed: () {
//                                   _getKifiyaGateway();

//                                   if (kifiyaGateway != null &&
//                                       kifiyaGateway['success'] &&
//                                       kifiyaGateway['payment_gateway'] !=
//                                           null) {
//                                     final telebirrId = getPaymentMethodIdByName(
//                                         "Telebirr inapp");

//                                     setState(() {
//                                       paymentId = telebirrId;
//                                     });
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(builder: (context) {
//                                         return TopupPaymentInApp(
//                                           amount: topUpAmount,
//                                           context: context,
//                                           traceNo: uniqueId,
//                                           phone: userData['user']['phone'],
//                                         );
//                                       }),
//                                     ).then((value) async {
//                                       if (value != null) {
//                                         if (value == false) {
//                                           Navigator.of(context).pop();
//                                           Service.showMessage(
//                                             error: true,
//                                             context: context,
//                                             title:
//                                                 "Faild to topup wallet amount. Please try again!.",
//                                           );
//                                         } else if ((value['code'] != null &&
//                                                 value['code'] == 0) ||
//                                             (value['status'] != null &&
//                                                 value['status']
//                                                         .toString()
//                                                         .toLowerCase() ==
//                                                     "success")) {
//                                           _addToWallet();
//                                         }
//                                       } else {
//                                         Navigator.of(context).pop();

//                                         Future.delayed(
//                                             Duration(milliseconds: 100), () {
//                                           if (mounted) {
//                                             Service.showMessage(
//                                               error: true,
//                                               context: context,
//                                               title:
//                                                   "Faild to topup wallet amount. Please try again!.",
//                                             );
//                                           }
//                                         });
//                                       }
//                                     });
//                                   }
//                                 },
//                               ),
//                               PaymentCard(
//                                 title: "Telebirr USSD",
//                                 subtitle: "Pay with USSD code",
//                                 imageUrl: "images/telebirr.png",
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(builder: (context) {
//                                       return TopupPaymentUssd(
//                                         amount: topUpAmount,
//                                         traceNo:
//                                             "${uniqueId}_${userData['user']['_id']}",
//                                         phone: userData['user']['phone'],
//                                         userId: userData['user']['_id'],
//                                         url:
//                                             "http://196.189.44.60:8069/telebirr/ussd/send_sms",
//                                         // serverToken: userData['user']
//                                         //     ['serverToken'],
//                                         // orderPaymentId:
//                                         //     DateTime.now().toIso8601String(),
//                                       );
//                                     }),
//                                   ).then((_) => Navigator.of(context).pop());
//                                 },
//                               ),
//                             ],
//                           ),