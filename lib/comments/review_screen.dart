import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/comments/components/comment_container.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_progress_indicator.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({
    required this.userId,
    required this.storeId,
    required this.serverToken,
    this.isLocal = true,
  });

  final String userId;
  final String storeId;
  final String serverToken;
  final bool isLocal;
  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  bool _loading = false;
  var reviews;

  void _getStoreReviews() async {
    setState(() {
      _loading = true;
    });
    var data = await getStoreReviews();

    if (data != null && data['success']) {
      setState(() {
        reviews = data;
        _loading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          Service.showMessage("${errorCodes['${data['error_code']}']}!", true));
      if (data['error_code'] == 999) {
        await CoreServices.clearCache();
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getStoreReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Reviews",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenHeight(kDefaultPadding),
          vertical: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        child: ModalProgressHUD(
          inAsyncCall: _loading,
          progressIndicator:
              CustomLinearProgressIndicator(message: "Loading reviews..."),
          color: kWhiteColor,
          child: reviews != null
              ? reviews['store_review_list'].length > 0
                  ? ListView.separated(
                      shrinkWrap: true,
                      itemCount: reviews['store_review_list'].length,
                      itemBuilder: (context, index) {
                        return CommentContainer(
                          press: () {
                            // print(reviews['store_review_list'][index]);
                          },
                          comment: reviews['store_review_list'][index]
                              ['user_review_to_store'],
                          rating: reviews['store_review_list'][index]
                                  ['user_rating_to_store']
                              .toDouble(),
                          dateTime: reviews['store_review_list'][index]
                                  ['created_at']
                              .toString(),
                          userName:
                              "${reviews['store_review_list'][index]['user_detail']['first_name']} ${reviews['store_review_list'][index]['user_detail']['last_name']}",
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 4),
                      ),
                    )
                  : Center(
                      child: Text("No comments for this store!"),
                    )
              : !_loading
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            getProportionateScreenWidth(kDefaultPadding * 4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(
                            title: "Retry",
                            press: () {
                              setState(() {
                                _loading = true;
                              });
                              _getStoreReviews();
                            },
                            color: kSecondaryColor,
                          ),
                        ],
                      ),
                    )
                  : Container(),
        ),
      ),
    );
  }

  Future<dynamic> getStoreReviews() async {
    setState(() {
      _loading = true;
    });
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/user_get_store_review_list";
    Map data = {
      "user_id": widget.userId,
      "store_id": widget.storeId,
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
      // print(e);
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
          "Your internet connection is unstable. Please try again...", true));
      return null;
    }
  }
}
