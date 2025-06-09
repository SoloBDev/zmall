import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/global/order/global_order.dart';
import 'package:zmall/help/help_screen.dart';
import 'package:zmall/models/cart.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/profile/components/profile_list_tile.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class GlobalProfile extends StatefulWidget {
  @override
  State<GlobalProfile> createState() => _GlobalProfileState();
}

class _GlobalProfileState extends State<GlobalProfile> {
  AbroadData? abroadData;
  String username = "";
  String email = "";
  late User user;
  bool isLoading = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAbroadUser();
  }

  void getAbroadUser() async {
    var data = await Service.read('abroad_user');
    if (data != null) {
      setState(() {
        abroadData = AbroadData.fromJson(data);
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: kPrimaryColor,
            title: Text("Dear Esteemed User,"),
            content: Wrap(
              children: [
                Text("Please complete registration..."),
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding / 2),
                ),
                TextField(
                  style: TextStyle(color: kBlackColor),
                  keyboardType: TextInputType.text,
                  onChanged: (val) {
                    username = val;
                  },
                  decoration: textFieldInputDecorator.copyWith(
                      labelText: username.isNotEmpty ? username : "Full Name"),
                ),
                Container(
                  height: getProportionateScreenHeight(kDefaultPadding),
                ),
                TextField(
                  style: TextStyle(color: kBlackColor),
                  keyboardType: TextInputType.text,
                  onChanged: (val) {
                    email = val;
                  },
                  decoration: textFieldInputDecorator.copyWith(
                      labelText: email.isNotEmpty ? email : "Email"),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Save Now",
                  style: TextStyle(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  if (username.isNotEmpty && email.isNotEmpty) {
                    var abroadUser = AbroadData(
                        abroadName: username,
                        abroadEmail: email,
                        abroadPhone: user.phoneNumber);
                    setState(() {
                      abroadData = abroadUser;
                    });
                    // print(abroadData!.toJson());
                    await Service.save('abroad_user', abroadData!.toJson());
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        Service.showMessage(
                            "User data successfully updated", false));
                  } else {
                    // Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        Service.showMessage(
                            "Please add the necessary information", true));
                  }
                  // Service.launchInWebViewOrVC("http://onelink.to/vnchst");
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Profile",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(kDefaultPadding / 2),
          horizontal: getProportionateScreenHeight(kDefaultPadding),
        ),
        child: Column(
          children: [
            Container(
              padding:
                  EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(
                  getProportionateScreenWidth(kDefaultPadding),
                ),
              ),
              child: Column(
                children: [
                  ImageContainer(
                      url:
                          "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/"),
                  SizedBox(
                      height:
                          getProportionateScreenHeight(kDefaultPadding / 2)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        abroadData != null ? abroadData!.abroadName! : "",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      abroadData != null && abroadData!.abroadPhone != null
                          ? Icon(
                              Icons.verified_outlined,
                              color: kSecondaryColor,
                              size:
                                  getProportionateScreenWidth(kDefaultPadding),
                            )
                          : Container(),
                    ],
                  ),
                  Text(
                    abroadData != null
                        ? abroadData!.abroadPhone.toString()
                        : "",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    abroadData != null ? abroadData!.abroadEmail! : "",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => EditProfile(
                  //           userData: userData,
                  //         ),
                  //       ),
                  //     ).then((value) => getUser());
                  //     print(userData['user']);
                  //   },
                  //   child: Text("Edit"),
                  // ),
                ],
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
            ProfileListTile(
              icon: Icon(
                Icons.shopping_bag_rounded,
                color: kSecondaryColor,
              ),
              title: "My Orders",
              press: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return GlobalOrder();
                }));
              },
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            ProfileListTile(
              icon: Icon(
                Icons.help,
                color: kSecondaryColor,
              ),
              title: "Help",
              press: () {
                Navigator.pushNamed(context, HelpScreen.routeName);
              },
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            ProfileListTile(
              icon: Icon(
                FontAwesomeIcons.instagram,
                color: kSecondaryColor,
              ),
              title: "Follow us on Instagram",
              press: () {
                Service.launchInWebViewOrVC(
                    "https://www.instagram.com/zmall_delivery/?hl=en");
              },
            ),
            SizedBox(
              height: getProportionateScreenHeight(kDefaultPadding / 2),
            ),
            ProfileListTile(
              icon: Icon(
                Icons.facebook,
                color: kSecondaryColor,
              ),
              title: "Follow us on Facebook",
              press: () {
                Service.launchInWebViewOrVC(
                    "https://www.facebook.com/Zmallshop/");
              },
            ),
            Spacer(),
            isLoading
                ? SpinKitWave(
                    color: kSecondaryColor,
                    size: getProportionateScreenWidth(kDefaultPadding),
                  )
                : CustomButton(
                    title: "LOGOUT",
                    press: () {
                      setState(() {
                        isLoading = true;
                      });
                      _showDialog();
                    },
                    color: kSecondaryColor,
                  ),
          ],
        ),
      ),
    );
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kPrimaryColor,
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Think about it!",
                style: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isLoading = false;
                });
              },
            ),
            TextButton(
              child: Text(
                "Sure",
                style: TextStyle(color: kBlackColor),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await Service.remove("abroad_user");
                await Service.remove("abroad_cart");
                Navigator.pushReplacementNamed(context, '/global');
              },
            ),
          ],
        );
      },
    );
  }
}
