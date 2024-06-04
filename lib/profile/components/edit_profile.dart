import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/profile/components/change_password.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/store/components/image_container.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({this.userData});
  final userData;
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool enabled = false;
  bool _loading = false;
  bool imageEdited = false;
  String firstName = "";
  String lastName = "";
  String email = "";
  String address = "";
  String phone = "";
  List<File> imageList = [];
  String password = "";

  late File _image;
  final imagePicker = ImagePicker();
  Future getImage() async {
    final image = await imagePicker.pickImage(
        source: ImageSource.gallery); // change getImage to pickImage
    setState(() {
      imageList.clear();
      _image = File(image!.path);
      imageList.add(_image);
      imageEdited = true;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    firstName = widget.userData['user']['first_name'];
    lastName = widget.userData['user']['last_name'];
    email = widget.userData['user']['email'];
    //address = widget.userData['user']['address'];
    widget.userData['user']['address'] ??
        'Addis Ababa, Ethiopia'; //new change because address cannot be null : when user register their is no address
    phone = widget.userData['user']['phone'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${Provider.of<ZLanguage>(context).edit} ${Provider.of<ZLanguage>(context).profilePage}",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
        actions: [
          enabled
              ? IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      enabled = false;
                    });
                  })
              : IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      enabled = true;
                    });
                  })
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding),
                  ),
                ),
                padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: imageEdited
                          ? Container(
                              width: getProportionateScreenWidth(
                                  kDefaultPadding * 4.5),
                              height: getProportionateScreenHeight(
                                  kDefaultPadding * 4.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kWhiteColor,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(imageList[0]),
                                ),
                              ),
                            )
                          : ImageContainer(
                              url:
                                  "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.userData['user']['image_url']}"),
                    ),
                    enabled
                        ? Center(
                            child: TextButton(
                                onPressed: () {
                                  getImage();
                                },
                                child: Text("Change Profile Picture")),
                          )
                        : Container(),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    Text(
                      Provider.of<ZLanguage>(context).name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      enabled: enabled,
                      cursorColor: kSecondaryColor,
                      style:
                          TextStyle(color: enabled ? kBlackColor : kGreyColor),
                      keyboardType: TextInputType.text,
                      onChanged: (val) {
                        firstName = val;
                      },
                      decoration: InputDecoration(
                        labelStyle: TextStyle(
                          color: enabled ? kGreyColor : kBlackColor,
                        ),
                        hintText: firstName,
                        hintStyle: TextStyle(
                            color: enabled ? kGreyColor : kBlackColor),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kSecondaryColor),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kBlackColor),
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    Text(
                      "Last Name",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      enabled: enabled,
                      cursorColor: kSecondaryColor,
                      style:
                          TextStyle(color: enabled ? kBlackColor : kGreyColor),
                      keyboardType: TextInputType.text,
                      onChanged: (val) {
                        lastName = val;
                      },
                      decoration: InputDecoration(
                        labelStyle: TextStyle(
                          color: enabled ? kBlackColor : kGreyColor,
                        ),
                        hintText: lastName,
                        hintStyle: TextStyle(
                            color: enabled ? kGreyColor : kBlackColor),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kSecondaryColor),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kBlackColor),
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    Text(
                      "Email",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      enabled: enabled,
                      cursorColor: kSecondaryColor,
                      style:
                          TextStyle(color: enabled ? kBlackColor : kGreyColor),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) {
                        email = val;
                      },
                      decoration: InputDecoration(
                        hintText: email,
                        hintStyle: TextStyle(
                            color: enabled ? kGreyColor : kBlackColor),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kSecondaryColor),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kBlackColor),
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    Text(
                      "Address",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      enabled: enabled,
                      cursorColor: kSecondaryColor,
                      style:
                          TextStyle(color: enabled ? kBlackColor : kGreyColor),
                      keyboardType: TextInputType.text,
                      onChanged: (val) {
                        address = val;
                      },
                      decoration: InputDecoration(
                        hintText: address,
                        hintStyle: TextStyle(
                            color: enabled ? kGreyColor : kBlackColor),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kSecondaryColor),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: kBlackColor),
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    enabled
                        ? Center(
                            child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChangePassword(
                                        userData: widget.userData,
                                      ),
                                    ),
                                  );
                                },
                                child: Text("Change Password")),
                          )
                        : Container(),
                  ],
                ),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
              enabled
                  ? _loading
                      ? SpinKitWave(
                          color: kSecondaryColor,
                          size: getProportionateScreenHeight(kDefaultPadding),
                        )
                      : CustomButton(
                          title: "Update",
                          color: kSecondaryColor,
                          press: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Enter Password To Update"),
                                    content: TextField(
                                      cursorColor: kSecondaryColor,
                                      style: TextStyle(color: kBlackColor),
                                      keyboardType: TextInputType.text,
                                      obscureText: true,
                                      onChanged: (val) {
                                        setState(() {
                                          password = val;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelStyle: TextStyle(
                                          color: kGreyColor,
                                        ),
                                        labelText: "Password",
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: kSecondaryColor),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: kBlackColor),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          "Cancel",
                                          style:
                                              TextStyle(color: kSecondaryColor),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text(
                                          "Submit",
                                          style: TextStyle(color: kBlackColor),
                                        ),
                                        onPressed: () async {
                                          if (password.isNotEmpty) {
                                            setState(() {
                                              _loading = true;
                                            });
                                            Navigator.of(context).pop();
                                            var data = await updateUser();
                                            if (data != null &&
                                                data['success']) {
                                              setState(() {
                                                enabled = false;
                                                _loading = false;
                                              });
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(Service.showMessage(
                                                    "Please enter your password",
                                                    true));
                                          }
                                        },
                                      )
                                    ],
                                  );
                                });
                          })
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> updateUser() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/update";
    var postUri = Uri.parse(url);
    try {
      http.MultipartRequest request = new http.MultipartRequest("POST", postUri)
        ..fields['user_id'] = widget.userData['user']['_id']
        ..fields['server_token'] = widget.userData['user']['server_token']
        ..fields['first_name'] = firstName
        ..fields['last_name'] = lastName
        ..fields['email'] = email
        ..fields['address'] = address
        ..fields['old_password'] = password
        ..fields['new_password'] = password;
      if (imageList != null && imageList.length > 0) {
        http.MultipartFile multipartFile =
            await http.MultipartFile.fromPath('file', imageList[0].path);
        request.files.add(multipartFile);
      }
      await request.send().then((response) async {
        http.Response.fromStream(response).then((value) async {
          var data = json.decode(value.body);
          if (data != null && data['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
                Service.showMessage("User updated successfully!", false));
            setState(() {
              _loading = false;
              enabled = false;
            });
          } else {
            setState(() {
              _loading = false;
            });
            if (data['error_code'] == 999) {
              ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
                  "${errorCodes['${data['error_code']}']}!", true));
              await Service.saveBool('logged', false);
              await Service.remove('user');
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(Service.showMessage(
                  "Something went wrong. Please try again!", true));
            }
          }
          return json.decode(value.body);
        });
      }).timeout(Duration(seconds: 10), onTimeout: () {
        setState(() {
          _loading = false;
        });
        throw TimeoutException("The connection has timed out!");
      });
    } catch (e) {
      setState(() {
        this._loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong. Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    }
  }
}
