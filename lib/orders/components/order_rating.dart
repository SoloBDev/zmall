import 'dart:async';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
import 'package:zmall/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/store/components/image_container.dart';

class OrderRating extends StatefulWidget {
  static String routeName = "/order_rating";

  const OrderRating({
    @required this.userId,
    @required this.orderId,
    @required this.serverToken,
    @required this.imageUrl,
    @required this.name,
    @required this.isStore,
  });

  final String? userId, orderId, serverToken, imageUrl, name;
  final bool? isStore;

  @override
  _OrderRatingState createState() => _OrderRatingState();
}

class _OrderRatingState extends State<OrderRating> {
  double rating = 0.0;
  String review = "";
  bool _loading = false;
  var responseData;
  TextEditingController controller = TextEditingController(text: "");

  void _submitRating() async {
    setState(() {
      _loading = true;
    });

    var data = await submitRating();
    if (data != null && data['success']) {
      setState(() {
        _loading = false;
        responseData = data;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        Service.showMessage(
            "You have successfully submitted your rating", false),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      if (data['error_code'] == 999) {
        await Service.saveBool('logged', false);
        await Service.remove('user');
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Order Rating",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding)),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(
                      getProportionateScreenWidth(kDefaultPadding)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      ImageContainer(url: widget.imageUrl),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      Text(
                        widget.name!,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: kBlackColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      SmoothStarRating(
                        rating: rating != null ? rating : 0.0,
                        size:
                            getProportionateScreenWidth(kDefaultPadding * 1.4),
                        starCount: 5,
                        color: Colors.amber,
                        borderColor: kSecondaryColor,
                        onRatingChanged: (value) {
                          setState(() {
                            rating = value;
                          });
                        },
                      ),
                      SizedBox(
                          height: getProportionateScreenHeight(
                              kDefaultPadding / 2)),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.text,
                        maxLines: 5,
                        onChanged: (value) {
                          setState(() {
                            review = value;
                          });
                        },
                        decoration: textFieldInputDecorator.copyWith(
                            hintText: "Enter your review here..."),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
              _loading
                  ? SpinKitWave(
                      size: getProportionateScreenWidth(kDefaultPadding),
                      color: kSecondaryColor,
                    )
                  : CustomButton(
                      title: "SUBMIT",
                      press: () {
                        if (rating != 0.0 && review != null) {
                          _submitRating();
                        }
                      },
                      color: rating != 0.0 && review != null
                          ? kSecondaryColor
                          : kGreyColor,
                    )
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> submitRating() async {
    setState(() {
      _loading = true;
    });
    var url = widget.isStore!
        ? "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/rating_to_store"
        : "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/rating_to_provider";

    Map data = widget.isStore!
        ? {
            "user_id": widget.userId,
            "server_token": widget.serverToken,
            "order_id": widget.orderId,
            "user_review_to_store": review,
            "user_rating_to_store": rating
          }
        : {
            "user_id": widget.userId,
            "server_token": widget.serverToken,
            "order_id": widget.orderId,
            "user_review_to_provider": review,
            "user_rating_to_provider": rating
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
      if (json.decode(response.body) != null) {
        setState(() {
          responseData = json.decode(response.body);
        });
      }
      setState(() {
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // print(e);
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
