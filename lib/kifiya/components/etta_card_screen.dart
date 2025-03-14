import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class EttaCardScreen extends StatefulWidget {
  const EttaCardScreen({
    Key? key,
    required this.phone,
    required this.amount,
    required this.traceNo,
    required this.orderPaymentId,
    required this.url,
  }) : super(key: key);

  final String url;
  final double amount;
  final String phone;
  final String traceNo;
  final String orderPaymentId;

  @override
  State<EttaCardScreen> createState() => _EttaCardScreenState();
}

class _EttaCardScreenState extends State<EttaCardScreen> {
  TextEditingController cardNumberController = TextEditingController();

  // CardType cardType = CardType.Invalid;
  String cardNumber = "";
  String pin = "";
  String exp = "";

  bool _loading = false;


  void _payPayment() async {
    setState(() {
      _loading = true;
    });
    var data = await payPayment();
    if(data != null && data['success']){
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Payment completed successfully.", false,
          duration: 5));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Payment failed. Please try other payment methods", true,
          duration: 4));
      await Future.delayed(Duration(seconds: 4)).then((value) => Navigator.pop(context));
    }


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0.0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        progressIndicator: linearProgressIndicator,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(kDefaultPadding),
              vertical: getProportionateScreenHeight(kDefaultPadding),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pay Using ETTA Card',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Powered by Dashen Bank S.C.',
                            style: TextStyle(fontSize: 21, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Image.asset(
                        "images/dashen.png",
                        height: getProportionateScreenHeight(kDefaultPadding * 4),
                        width: getProportionateScreenWidth(kDefaultPadding * 4),
                      ),
                    ),
                  ],
                ),

                const Spacer(),
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          CardNumberInputFormatter(),
                        ],
                        decoration: InputDecoration(hintText: "Card number"),
                        onChanged: (value){
                          setState(() {
                            cardNumber = value;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: TextFormField(
                          decoration:
                              const InputDecoration(hintText: "Full name"),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                // Limit the input
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: (value){
                                setState(() {
                                  pin = value;
                                });
                              },
                              decoration: const InputDecoration(hintText: "PIN"),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              onChanged: (value){
                                setState(() {
                                  exp = value;
                                });
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                                CardMonthInputFormatter(),
                              ],
                              decoration:
                                  const InputDecoration(hintText: "MM/YY"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CustomButton(
                      press: () {
                        _payPayment();
                      },
                      title: 'Pay ${widget.amount.toStringAsFixed(2)}',
                      color: kBlackColor,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> payPayment() async {
    setState(() {
      _loading = true;
    });
    var url = "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/admin/pay_payment_ettacard";

    Map data = {
      "card": cardNumber.replaceAll(" ",""),
      "pin": pin,
      "amount": widget.amount,
      "description": "ZMall Order Payment for order ${widget.traceNo}",
      "trace_no": widget.traceNo,
      "expiration_date": exp,
    };

    var body = json.encode(data);
    try {
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 20),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );

      setState(() {
        this._loading = false;
      });

      return json.decode(response.body);
    } catch (e) {
      print(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage(
            "Something went wrong. Please check your internet connection!",
            true),
      );
      return null;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cardNumberController.dispose();
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write('  '); // Add double spaces.
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class CardMonthInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
