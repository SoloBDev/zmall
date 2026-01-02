import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/login/login_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/store/components/image_container.dart';
import 'package:zmall/widgets/custom_text_field.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';

class EditProfile extends StatefulWidget {
  final userData;
  final bool? isEnabled;
  const EditProfile({this.userData, this.isEnabled});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  List<File> imageList = [];
  bool imageEdited = false;
  bool _loading = false;
  bool enabled = false;
  String dateOfBirth = "";
  String firstName = "";
  String password = "";
  String lastName = "";
  String address = "";
  String gender = "";
  String phone = "";
  String email = "";

  late File _image;
  final imagePicker = ImagePicker();
  Future getImage() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
    ); // change getImage to pickImage
    setState(() {
      imageList.clear();
      _image = File(image!.path);
      imageList.add(_image);
      imageEdited = true;
    });
  }

  @override
  void initState() {
    super.initState();
    enabled = widget.isEnabled ?? false;
    firstName = widget.userData['user']['first_name'];
    lastName = widget.userData['user']['last_name'];
    email = widget.userData['user']['email'];
    address = widget.userData['user']['address'] ?? 'Addis Ababa, Ethiopia';
    phone = widget.userData['user']['phone'];
    gender = widget.userData['user']['gender'] ?? '';
    dateOfBirth = widget.userData['user']['date_of_birth'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(kDefaultPadding * 1.5),
          ).copyWith(bottom: getProportionateScreenWidth(kDefaultPadding / 3)),
          child: SafeArea(
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5,
              child: CustomButton(
                title: 'Update Profile',
                press: enabled
                    ? () {
                        _showPasswordBottomSheet();
                      }
                    : () {}, // Empty function when disabled
                color: enabled
                    ? kSecondaryColor
                    : kSecondaryColor.withValues(alpha: 0.5),
                titleColor: kWhiteColor,
              ),
            ),
          ),
        ),
        appBar: AppBar(
          title: Text(
            "${Provider.of<ZLanguage>(context).edit} ${Provider.of<ZLanguage>(context).profilePage}",
            style: TextStyle(color: kBlackColor),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  enabled = !enabled;
                });
              },
              icon: Icon(
                enabled
                    ? HeroiconsOutline.xCircle
                    : HeroiconsOutline.pencilSquare,
              ),
              tooltip: enabled ? 'Cancel' : 'Edit Profile',
            ),
          ],
        ),
        body: ModalProgressHUD(
          inAsyncCall: _loading,
          color: kPrimaryColor,
          progressIndicator: LinearLoadingIndicator(),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding),
                vertical: getProportionateScreenWidth(
                  enabled ? kDefaultPadding / 2 : kDefaultPadding * 2,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 115,
                        height: 115,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          image: imageEdited
                              ? DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(imageList[0]),
                                )
                              : null,
                        ),
                        child: !imageEdited
                            ? ClipOval(
                                child: ImageContainer(
                                  url:
                                      "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.userData['user']['image_url']}",
                                ),
                              )
                            : null,
                      ),
                      if (enabled)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: getImage,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: kSecondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kWhiteColor,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: kWhiteColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding * 2),
                  ),
                  Row(
                    spacing: kDefaultPadding / 2,
                    children: [
                      Flexible(
                        child: Column(
                          children: [
                            _buildLable(
                              icon: HeroiconsOutline.user,
                              title: "First Name",
                            ),
                            SizedBox(
                              height: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                            ),
                            CustomTextField(
                              enabled: enabled,
                              initialValue: firstName,
                              // label: "First Name",
                              keyboardType: TextInputType.text,
                              onChanged: (val) {
                                firstName = val;
                              },
                            ),
                          ],
                        ),
                      ),

                      // SizedBox(
                      //   height: getProportionateScreenHeight(kDefaultPadding),
                      // ),
                      Flexible(
                        child: Column(
                          children: [
                            _buildLable(
                              icon: HeroiconsOutline.user,
                              title: "Last Name",
                            ),
                            SizedBox(
                              height: getProportionateScreenHeight(
                                kDefaultPadding / 2,
                              ),
                            ),
                            CustomTextField(
                              // label: 'Last Name',
                              initialValue: lastName,
                              onChanged: (val) => lastName = val,
                              enabled: enabled,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!email.toLowerCase().contains("telebirr") &&
                      !email.toLowerCase().contains("dashen")) ...[
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    _buildLable(
                      icon: HeroiconsOutline.envelope,
                      title: "Email",
                    ),

                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    CustomTextField(
                      // label: 'Email',
                      initialValue: email,
                      onChanged: (val) => email = val,
                      enabled: enabled,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],

                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  _buildLable(icon: HeroiconsOutline.mapPin, title: "Address"),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 2),
                  ),
                  CustomTextField(
                    // label: 'Address',
                    initialValue: address,
                    onChanged: (val) => address = val,
                    enabled: enabled,
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  _buildLable(
                    icon: HeroiconsOutline.userCircle,
                    title: "Gender",
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 2),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: !enabled
                          ? null
                          : Border.all(
                              color: kGreyColor.withValues(alpha: 0.15),
                            ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: gender.isEmpty ? null : gender,
                        hint: Text(
                          gender.isNotEmpty ? gender : 'Select Gender',
                          style: TextStyle(color: kGreyColor),
                        ),
                        isExpanded: true,
                        dropdownColor: kPrimaryColor,
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: enabled
                              ? kGreyColor.withValues(alpha: 0.3)
                              : kGreyColor.withValues(alpha: 0.15),
                        ),
                        style: TextStyle(color: kBlackColor, fontSize: 16),
                        items: enabled
                            ? ['Male', 'Female'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList()
                            : null,
                        onChanged: enabled
                            ? (String? newValue) {
                                setState(() {
                                  gender = newValue ?? '';
                                });
                              }
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding),
                  ),
                  _buildLable(
                    icon: HeroiconsOutline.calendar,
                    title: "Date of Birth",
                  ),
                  SizedBox(
                    height: getProportionateScreenHeight(kDefaultPadding / 2),
                  ),
                  GestureDetector(
                    onTap: !enabled ? null : _selectDateOfBirth,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        enabled: enabled,
                        // initialValue: dateOfBirth,
                        controller: TextEditingController(
                          text: dateOfBirth.isNotEmpty
                              ? DateFormat(
                                  'MMM d, yyyy',
                                ).format(DateTime.parse(dateOfBirth))
                              : '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLable({required IconData icon, required String title}) {
    return Row(
      spacing: kDefaultPadding,
      children: [
        Icon(icon, size: 18),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showPasswordBottomSheet() {
    bool _showPassword = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kDefaultPadding),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom +
                    kDefaultPadding, // Adjust for keyboard
              ),
              child: SafeArea(
                minimum: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(kDefaultPadding),
                  vertical: getProportionateScreenHeight(kDefaultPadding),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Security Check',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: kBlackColor,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            HeroiconsOutline.xCircle,
                            color: kBlackColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Please confirm your password to update your profile.",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: kGreyColor,
                      ),
                    ),
                    SizedBox(height: kDefaultPadding),
                    Text(
                      "Password",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: kGreyColor,
                      ),
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    CustomTextField(
                      cursorColor: kSecondaryColor,
                      style: TextStyle(color: kBlackColor),
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: !_showPassword,
                      onChanged: (val) {
                        setState(() {
                          password = val;
                        });
                      },
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                        icon: Icon(
                          _showPassword
                              ? HeroiconsOutline.eyeSlash
                              : HeroiconsOutline.eye,
                        ),
                      ),
                    ),
                    SizedBox(height: kDefaultPadding * 1.5),
                    CustomButton(
                      title: 'Submit',
                      press: () async {
                        if (password.isNotEmpty) {
                          setState(() => _loading = true);
                          Navigator.of(context).pop();
                          var data = await updateUser();
                          if (data != null && data['success']) {
                            userDetails();
                            setState(() {
                              enabled = false;
                              _loading = false;
                            });
                          }
                        } else {
                          Service.showMessage(
                            context: context,
                            title: 'Please enter your password',
                            error: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth.isNotEmpty
          ? DateTime.parse(dateOfBirth)
          : DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kSecondaryColor,
              onPrimary: kPrimaryColor,
              surface: kPrimaryColor,
              onSurface: kBlackColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked.toIso8601String() != dateOfBirth) {
      setState(() {
        dateOfBirth = picked.toIso8601String();
      });
    }
  }

  Future<void> userDetails() async {
    var usrData;
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/get_detail";

    setState(() {
      _loading = true;
    });
    try {
      Map data = {
        "user_id": widget.userData['user']['_id'],
        "server_token": widget.userData['user']['server_token'],
      };
      var body = json.encode(data);
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
      setState(() {
        usrData = json.decode(response.body);
      });
      // print("usrData>> $usrData}");
      if (usrData != null && usrData['success']) {
        Service.save('user', usrData);
        Service.read('user');
      }
      // return json.decode(response.body);
    } catch (e) {
      // debugPrint("error $e");
      // return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<dynamic> updateUser() async {
    setState(() {
      this._loading = true;
    });
    // debugPrint("dob $dateOfBirth");
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
        ..fields['gender'] = gender
        ..fields['date_of_birth'] = dateOfBirth
        ..fields['old_password'] = password
        ..fields['new_password'] = password;
      if (imageList.isNotEmpty && imageList.length > 0) {
        http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageList[0].path,
        );
        request.files.add(multipartFile);
      }
      await request
          .send()
          .then((response) async {
            http.Response.fromStream(response).then((value) async {
              var data = json.decode(value.body);
              if (data != null && data['success']) {
                Service.showMessage(
                  context: context,
                  title: "Profile data updated successfully!",
                  error: false,
                );
                setState(() {
                  _loading = false;
                  enabled = false;
                });
              } else {
                if (data['error_code'] == 999) {
                  Service.showMessage(
                    context: context,
                    title: "${errorCodes['${data['error_code']}']}!",
                    error: true,
                  );
                  await Service.saveBool('logged', false);
                  await Service.remove('user');
                  Navigator.pushReplacementNamed(
                    context,
                    LoginScreen.routeName,
                  );
                } else {
                  Service.showMessage(
                    context: context,
                    title: "Something went wrong. Please try again!",
                    error: true,
                  );
                }
              }
              // print("update ${json.decode(value.body)}");
              return json.decode(value.body);
            });
          })
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                "The connection has timed out, please try again!",
              );
            },
          );
    } catch (e) {
      // print("update ${json.decode(value.body)}");

      Service.showMessage(
        context: context,
        title: "Something went wrong. Please check your internet connection!",
        error: true,
      );
      return null;
    } finally {
      setState(() {
        this._loading = false;
      });
    }
  }
}
