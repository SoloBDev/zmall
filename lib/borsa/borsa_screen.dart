import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/topup/topup_screen.dart';
import 'package:zmall/widgets/section_title.dart';

class BorsaScreen extends StatefulWidget {
  static String routeName = '/borsa';

  const BorsaScreen({@required this.userData});

  final userData;

  @override
  _BorsaScreenState createState() => _BorsaScreenState();
}

class _BorsaScreenState extends State<BorsaScreen> {
  var responseData;
  bool isLoading = false;
  bool _loading = false;
  double currentBalance = 0.0;
  String payeePhone = "";
  String amount = "0.00";
  String payerPassword = "";
  bool transferError = false;
  bool transferLoading = false;
  var userData;
  double topUpAmount = 0.0;
  late String otp;
  var kifiyaGateway;

  @override
  void initState() {
    // TODO: implement initState
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
      });
    } else {
      if (responseData['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
      setState(() {
        isLoading = false;
      });
      if (errorCodes['${responseData['error_code']}'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${errorCodes['${responseData['error_code']}']}"),
          backgroundColor: kSecondaryColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("No wallet transaction history"),
          backgroundColor: kSecondaryColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Wallet",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: getProportionateScreenHeight(kDefaultPadding / 2),
            horizontal: getProportionateScreenWidth(kDefaultPadding),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  // borderRadius: BorderRadius.circular(
                  //   getProportionateScreenWidth(kDefaultPadding),
                  // ),
                  // boxShadow: [kDefaultShadow],
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                      getProportionateScreenWidth(kDefaultPadding)),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          "Current Balance",
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: kGreyColor,
                                  ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: "ETB",
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                            children: <TextSpan>[
                              TextSpan(
                                text: " ${currentBalance.toStringAsFixed(2)}",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                  height: getProportionateScreenHeight(kDefaultPadding / 1.5)),
              Row(
                children: [
                  CustomCard(
                      iconData: Icons.send,
                      title: "Transfer",
                      subtitle: "Send funds",
                      color: kSecondaryColor.withOpacity(.8),
                      textColor: kPrimaryColor,
                      press: () {
                        showModalBottomSheet<void>(
                          isScrollControlled: true,
                          context: context,
                          shape: RoundedRectangleBorder(
                              // borderRadius: BorderRadius.only(
                              //   topLeft: Radius.circular(30.0),
                              //   topRight: Radius.circular(30.0),
                              // ),
                              ),
                          builder: (BuildContext context) {
                            return Padding(
                              padding: MediaQuery.of(context).viewInsets,
                              child: Container(
                                padding: EdgeInsets.all(
                                    getProportionateScreenHeight(
                                        kDefaultPadding)),
                                child: Wrap(
                                  children: <Widget>[
                                    Text(
                                      "Transfer",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Container(
                                      height: getProportionateScreenHeight(
                                          kDefaultPadding),
                                    ),
                                    TextField(
                                      style: TextStyle(color: kBlackColor),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        FilteringTextInputFormatter
                                            .singleLineFormatter,
                                      ],
                                      maxLength: 9,
                                      onChanged: (val) {
                                        payeePhone = val;
                                      },
                                      decoration:
                                          textFieldInputDecorator.copyWith(
                                        labelText: "Receiver phone number",
                                        helperText:
                                            "Start phone number with 9..",
                                        prefix: Text(
                                            "${Provider.of<ZMetaData>(context, listen: false).areaCode}"),
                                      ),
                                    ),
                                    Container(
                                      height: getProportionateScreenHeight(
                                          kDefaultPadding / 2),
                                    ),
                                    /*         
                                    TextField(
                                      style: TextStyle(color: kBlackColor),
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (val) {
                                        amount = val;
                                      },
                                      decoration:
                                          textFieldInputDecorator.copyWith(
                                        labelText: "Amount",
                                      ),
                                    ), */
                                    Container(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2)),
                                    TextField(
                                      style: TextStyle(color: kBlackColor),
                                      keyboardType: TextInputType.text,
                                      obscureText: true,
                                      onChanged: (val) {
                                        payerPassword = val;
                                      },
                                      decoration: textFieldInputDecorator
                                          .copyWith(labelText: "Password"),
                                    ),
                                    transferError
                                        ? Text(
                                            "Invalid! Please make sure all fields are filled.",
                                            style: TextStyle(
                                                color: kSecondaryColor),
                                          )
                                        : Container(),
                                    Container(
                                        height: getProportionateScreenHeight(
                                            kDefaultPadding / 2)),
                                    transferLoading
                                        ? SpinKitWave(
                                            color: kSecondaryColor,
                                            size: getProportionateScreenWidth(
                                                kDefaultPadding),
                                          )
                                        : CustomButton(
                                            title: "Send",
                                            color: kSecondaryColor,
                                            press: () async {
                                              if (payeePhone.isNotEmpty &&
                                                  amount.isNotEmpty &&
                                                  payerPassword.isNotEmpty) {
                                                setState(() {
                                                  transferLoading = true;
                                                });
                                                var data = await genzebLak();
                                                if (data != null &&
                                                    data['success']) {
                                                  setState(() {
                                                    transferLoading = false;
                                                    widget.userData['user']
                                                            ['wallet'] -=
                                                        double.parse(amount);
                                                  });

                                                  _userDetails();
                                                  _getTransactions();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                          Service.showMessage(
                                                              "Transfer successfull",
                                                              false,
                                                              duration: 5));
                                                  setState(() {
                                                    transferLoading = false;
                                                  });
                                                  Navigator.of(context).pop();
                                                } else {
                                                  if (data['error_code'] ==
                                                      999) {
                                                    await Service.saveBool(
                                                        'logged', false);
                                                    await Service.remove(
                                                        'user');
                                                    Navigator
                                                        .pushReplacementNamed(
                                                            context,
                                                            LoginScreen
                                                                .routeName);
                                                  }
                                                  setState(() {
                                                    transferLoading = false;
                                                  });
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(
                                                        "${errorCodes['${data['error_code']}']}"),
                                                    backgroundColor:
                                                        kSecondaryColor,
                                                  ));
                                                }
                                              } else {
                                                setState(() {
                                                  transferError = true;
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  Service.showMessage(
                                                    "Invalid! Please make sure all fields are filled.",
                                                    true,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).whenComplete(() {
                          setState(() {
                            payeePhone = '';
                            amount = '0.00';
                            payerPassword = '';
                            transferError = false;
                          });
                        });
                      }),
                  SizedBox(
                      width: getProportionateScreenWidth(kDefaultPadding / 2)),
                  CustomCard(
                    title: "Top-up",
                    subtitle: "Add funds",
                    color: kYellowColor,
                    textColor: kBlackColor,
                    iconData: Icons.add_box,
                    press: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return TopUpScreen(userData: userData);
                      })).then((value) {
                        _userDetails();
                        _getTransactions();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 2),
              ),
              SectionTitle(
                sectionTitle: "Transactions",
                subTitle: " ",
              ),
              responseData != null && responseData['success']
                  ? responseData['wallet_history'].length > 0
                      ? ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: responseData['wallet_history'].length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                ClipRRect(
                                  child: ListTile(
                                    tileColor: kPrimaryColor,
                                    title: responseData['wallet_history'][index]
                                                ['wallet_description'] !=
                                            "Card : undefined"
                                        ? Text(
                                            "${responseData['wallet_history'][index]['wallet_description']}",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          )
                                        : Text(
                                            "Online Top-up",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                    subtitle: Text(
                                        "${responseData['wallet_history'][index]['updated_at'].split("T")[0]} ${responseData['wallet_history'][index]['updated_at'].split("T")[1].split('.')[0]}"),
                                    trailing: RichText(
                                      text: TextSpan(
                                        text: responseData['wallet_history']
                                                    [index]['wallet_amount'] <
                                                responseData['wallet_history']
                                                        [index]
                                                    ['total_wallet_amount']
                                            ? "+ "
                                            : "- ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: " ETB ",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                          TextSpan(
                                            text: responseData['wallet_history']
                                                    [index]['from_amount']
                                                .toStringAsFixed(2),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                    color: responseData['wallet_history']
                                                                    [index][
                                                                'wallet_amount'] <
                                                            responseData[
                                                                        'wallet_history']
                                                                    [index][
                                                                'total_wallet_amount']
                                                        ? Colors.green
                                                        : kSecondaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  // borderRadius: BorderRadius.circular(
                                  //   getProportionateScreenWidth(
                                  //       kDefaultPadding),
                                  // ),
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(
                                      kDefaultPadding / 3),
                                ),
                              ],
                            );
                          },
                        )
                      : Text("No wallet transactions yet!")
                  : isLoading
                      ? SpinKitWave(
                          color: kSecondaryColor,
                          size: getProportionateScreenWidth(kDefaultPadding),
                        )
                      : Text("Transaction history not found!")
            ],
          ),
        ),
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
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
          setState(() {
            isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      responseData = json.decode(response.body);
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return null;
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
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
          setState(() {
            isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<dynamic> genzebLak() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/transfer_wallet_amount";
    Map data = {
      "user_id": widget.userData['user']['_id'],
      "top_up_user_phone": payeePhone,
      "password": payerPassword,
      "wallet": amount,
      "server_token": widget.userData['user']['server_token'],
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
        Duration(seconds: 10),
        onTimeout: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(Service.showMessage("Network error", true));
          setState(() {
            isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );
      return json.decode(response.body);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<dynamic> amoleAddToBorsa() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/add_wallet_amount";

    Map data = {
      "user_id": userData['user']['_id'],
      "payment_id": kifiyaGateway['payment_gateway'][0]['_id'],
      "otp": otp,
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
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Something went wrong!"),
              backgroundColor: kSecondaryColor,
            ),
          );
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
        SnackBar(
          content: Text("Your internet connection is bad!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
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
            // borderRadius: BorderRadius.circular(
            //   getProportionateScreenWidth(kDefaultPadding),
            // ),
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
                Icon(
                  iconData,
                  color: textColor,
                ),
                Spacer(),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 5)),
                Text(
                  subtitle,
                  style: TextStyle(color: textColor),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
