import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/loyalty_card/add_new_card.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';

class LoyaltyCardScreen extends StatefulWidget {
  const LoyaltyCardScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyCardScreen> createState() => _LoyaltyCardScreenState();
}

class _LoyaltyCardScreenState extends State<LoyaltyCardScreen> {
  var userData;

  TextEditingController cardNumberController = TextEditingController();

  // CardType cardType = CardType.Invalid;

  void getUser() async {
    var data = await Service.read('user');
    if (data != null) {
      setState(() {
        userData = data;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Loyalty Card",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ZMall Loyalty Card',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              'Add and manage your loyalty cards.',
              style: TextStyle(fontSize: 21, color: Colors.black45),
            ),
            _buildCreditCard(
              color: Color(0xFF090943),
              cardNumber: "6800 0714 **** 5495",
              cardHolder: "Yoseph Solomon",
              cardExpiration: "12/27",
            ),
            SizedBox(height: 15),
            _buildCreditCard(
              color: Color(0xFF000000),
              cardExpiration: "05/24",
              cardHolder: "Temesgen G/Hiwot",
              cardNumber: "9874 4785 XXXX 6548",
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF081603),
        foregroundColor: kPrimaryColor,
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context){
            return AddNewCardScreen();
          }));
        },
      ),
    );
  }

  Card _buildCreditCard(
      {required Color color,
      required String cardNumber,
      required String cardHolder,
      required String cardExpiration}) {
    return Card(
      elevation: 4.0,
      color: color,
      /*1*/
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, bottom: 22.0, top: 10),
        child: Column(
          /*2*/
          crossAxisAlignment: CrossAxisAlignment.start,
          /*3*/
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildLogosBlock(),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                '$cardNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  // fontFamily: 'CourrierPrime',
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildDetailsBlock(
                  label: 'CARDHOLDER',
                  value: cardHolder.toUpperCase(),
                ),
                _buildDetailsBlock(
                  label: 'VALID THRU',
                  value: cardExpiration,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Column _buildDetailsBlock({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label',
          style: TextStyle(
              color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        Text(
          '$value',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  Row _buildLogosBlock() {
    return Row(
      /*1*/
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Image.asset(
          "images/contact_less.png",
          height: 20,
          width: 18,
        ),
        Spacer(),
        Container(
          color: kPrimaryColor,
          child: Image.asset(
            "images/dashen.png",
            height: 40,
            width: 40,
          ),
        ),
        SizedBox(width: getProportionateScreenWidth(kDefaultPadding),),
        Image.asset(
          "images/zmall.jpg",
          height: 40,
          width: 40,
        ),
      ],
    );
  }
}
