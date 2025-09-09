// import 'dart:async';
// import 'dart:convert';
// import 'package:heroicons_flutter/heroicons_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/custom_widgets/custom_button.dart';
// import 'package:zmall/login/login_screen.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';
// import 'package:zmall/widgets/custom_text_field.dart';

// class ChangePassword extends StatefulWidget {
//   const ChangePassword({this.userData});

//   final userData;

//   @override
//   _ChangePasswordState createState() => _ChangePasswordState();
// }

// class _ChangePasswordState extends State<ChangePassword> {
//   final _formKey = GlobalKey<FormState>();
//   String oldPassword = "";
//   String newPassword = "";
//   String confirmPassword = "";
//   bool _isLoading = false;

//   void _changePassword() async {
//     var data = await changePassword();
//     if (data != null && data['success']) {
//       Service.showMessage(
//         context: context,
//         title: "Password changed successfull",
//         error: false,
//       );
//       setState(() {
//         _isLoading = false;
//       });
//       Navigator.of(context).pop();
//     } else {
//       if (data['error_code'] == 999) {
//         Service.showMessage(
//           context: context,
//           title: "${errorCodes['${data['error_code']}']}!",
//           error: true,
//         );
//         await Service.saveBool('logged', false);
//         await Service.remove('user');
//         Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//       } else {
//         Service.showMessage(
//           context: context,
//           title: "${errorCodes['${data['error_code']}']}!",
//           error: true,
//         );
//         Service.showMessage(
//           context: context,
//           title: "Change password failed! Please try again",
//           error: true,
//         );
//       }
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
//       child: Scaffold(
//         backgroundColor: kPrimaryColor,
//         appBar: AppBar(
//           title: Text(
//             "Change Password",
//             style: TextStyle(
//               color: kBlackColor,
//             ),
//           ),
//         ),
//         body: Padding(
//           padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
//           child: Center(
//             child: Container(
//               padding: EdgeInsets.symmetric(
//                   horizontal: getProportionateScreenWidth(kDefaultPadding),
//                   vertical: getProportionateScreenHeight(kDefaultPadding)),
//               decoration: BoxDecoration(
//                 color: kPrimaryColor,
//                 borderRadius: BorderRadius.circular(kDefaultPadding),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.1),
//                     spreadRadius: 1,
//                     blurRadius: 3,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: EdgeInsets.all(kDefaultPadding / 1.5),
//                             decoration: BoxDecoration(
//                                 borderRadius:
//                                     BorderRadius.circular(kDefaultPadding),
//                                 color: kWhiteColor),
//                             child: Icon(
//                               HeroiconsOutline.lockClosed,
//                               size: 40,
//                               color: kBlackColor.withValues(alpha: 0.7),
//                             ),
//                           ),
//                           const SizedBox(height: kDefaultPadding / 2),
//                           const Text(
//                             "Change Password",
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const Text(
//                             "Update your password by entering a new one.",
//                           ),
//                         ],
//                       ),
//                     ),

//                     SizedBox(
//                         height: getProportionateScreenHeight(
//                             kDefaultPadding * 1.5)),

//                     _buildLable(
//                       icon: HeroiconsOutline.lockClosed,
//                       title: "Old Password",
//                     ),
//                     SizedBox(
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding / 2)),
//                     CustomTextField(
//                       hintText: "Enter your old password",
//                       onChanged: (val) {
//                         oldPassword = val;
//                       },
//                       validator: (value) {
//                         if (!passwordRegex.hasMatch(value!)) {
//                           return kPasswordErrorMessage;
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(
//                         height: getProportionateScreenHeight(kDefaultPadding)),
//                     _buildLable(
//                       icon: HeroiconsOutline.lockClosed,
//                       title: "New Password",
//                     ),
//                     SizedBox(
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding / 2)),
//                     CustomTextField(
//                       hintText: "Enter your new password",
//                       keyboardType: TextInputType.emailAddress,
//                       onChanged: (val) {
//                         setState(() {
//                           newPassword = val;
//                         });
//                       },
//                       validator: (value) {
//                         if (!passwordRegex.hasMatch(value!)) {
//                           return kPasswordErrorMessage;
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(
//                         height: getProportionateScreenHeight(kDefaultPadding)),
//                     _buildLable(
//                       icon: HeroiconsOutline.lockClosed,
//                       title: "Confirm Password",
//                     ),
//                     SizedBox(
//                         height:
//                             getProportionateScreenHeight(kDefaultPadding / 2)),
//                     CustomTextField(
//                       // label: 'Address',
//                       // initialValue: '',
//                       hintText: "Confirm your new password",
//                       onChanged: (val) {
//                         setState(() {
//                           confirmPassword = val;
//                         });
//                       },

//                       suffixIcon: newPassword.isNotEmpty &&
//                               newPassword == confirmPassword
//                           ? Icon(
//                               Icons.check,
//                               color: Colors.green,
//                             )
//                           : Icon(
//                               Icons.close,
//                               color: kWhiteColor,
//                             ),
//                       validator: (value) {
//                         if (value!.isEmpty) {
//                           return kPassNullError;
//                         } else if ((newPassword != value)) {
//                           return kMatchPassError;
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(
//                         height: getProportionateScreenHeight(kDefaultPadding)),

//                     ///
//                     CustomButton(
//                       title: "Submit",
//                       isLoading: _isLoading,
//                       press: () {
//                         if (_formKey.currentState!.validate()) {
//                           _changePassword();
//                         }
//                       },
//                       color: newPassword.isNotEmpty &&
//                               newPassword == confirmPassword
//                           ? kSecondaryColor
//                           : kSecondaryColor.withValues(alpha: 0.7),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLable({required IconData icon, required String title}) {
//     return Row(
//       spacing: kDefaultPadding,
//       children: [
//         Icon(
//           icon,
//           size: 18,
//         ),
//         Text(
//           title,
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }

//   Future<dynamic> changePassword() async {
//     setState(() {
//       _isLoading = true;
//     });

//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/update";
//     Map data = {
//       "user_id": widget.userData['user']['_id'],
//       "server_token": widget.userData['user']['server_token'],
//       "first_name": widget.userData['user']['first_name'],
//       "last_name": widget.userData['user']['last_name'],
//       "old_password": oldPassword,
//       "new_password": newPassword,
//     };
//     var body = json.encode(data);
//     try {
//       http.Response response = await http
//           .post(
//         Uri.parse(url),
//         headers: <String, String>{
//           "Content-Type": "application/json",
//           "Accept": "application/json"
//         },
//         body: body,
//       )
//           .timeout(
//         Duration(seconds: 10),
//         onTimeout: () {
//           setState(() {
//             this._isLoading = false;
//           });
//           throw TimeoutException("The connection has timed out!");
//         },
//       );

//       return json.decode(response.body);
//     } catch (e) {
//       // debugPrint(e);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               "Something went wrong. Please check your internet connection!"),
//           backgroundColor: kSecondaryColor,
//         ),
//       );
//       return null;
//     } finally {
//       setState(() {
//         this._isLoading = false;
//       });
//     }
//   }
// }
//  // Text(
//                   //   "Old Password",
//                   //   style: TextStyle(fontWeight: FontWeight.bold),
//                   // ),
//                   // TextField(
//                   //   cursorColor: kSecondaryColor,
//                   //   style: TextStyle(color: kBlackColor),
//                   //   keyboardType: TextInputType.text,
//                   //   obscureText: true,
//                   //   onChanged: (val) {
//                   //     oldPassword = val;
//                   //   },
//                   //   decoration: InputDecoration(
//                   //     focusedBorder: UnderlineInputBorder(
//                   //       borderSide: BorderSide(color: kSecondaryColor),
//                   //     ),
//                   //     enabledBorder: UnderlineInputBorder(
//                   //       borderSide: BorderSide(color: kBlackColor),
//                   //     ),
//                   //   ),
//                   // ),
//                   // SizedBox(
//                   //     height: getProportionateScreenHeight(kDefaultPadding / 2)),
//                   // Text(
//                   //   "New Password",
//                   //   style: TextStyle(fontWeight: FontWeight.bold),
//                   // ),
//                   // TextField(
//                   //   cursorColor: kSecondaryColor,
//                   //   style: TextStyle(color: kBlackColor),
//                   //   keyboardType: TextInputType.text,
//                   //   obscureText: true,
//                   //   onChanged: (val) {
//                   //     setState(() {
//                   //       newPassword = val;
//                   //     });
//                   //   },
//                   //   decoration: InputDecoration(
//                   //     suffixIcon:
//                   //         newPassword.isNotEmpty && newPassword == confirmPassword
//                   //             ? Icon(
//                   //                 Icons.check,
//                   //                 color: Colors.green,
//                   //               )
//                   //             : Icon(
//                   //                 Icons.close,
//                   //                 color: kWhiteColor,
//                   //               ),
//                   //     focusedBorder: UnderlineInputBorder(
//                   //       borderSide: BorderSide(color: kSecondaryColor),
//                   //     ),
//                   //     enabledBorder: UnderlineInputBorder(
//                   //       borderSide: BorderSide(color: kBlackColor),
//                   //     ),
//                   //   ),
//                   // ),
//                   // SizedBox(
//                   //     height: getProportionateScreenHeight(kDefaultPadding / 2)),
//                   // Text(
//                   //   "Confirm Password",
//                   //   style: TextStyle(fontWeight: FontWeight.bold),
//                   // ),
//                   // TextField(
//                   //   cursorColor: kSecondaryColor,
//                   //   style: TextStyle(color: kBlackColor),
//                   //   keyboardType: TextInputType.text,
//                   //   obscureText: true,
//                   //   onChanged: (val) {
//                   //     setState(() {
//                   //       confirmPassword = val;
//                   //     });
//                   //   },
//                   //   decoration: InputDecoration(
//                   //     suffixIcon:
//                   //         newPassword.isNotEmpty && newPassword == confirmPassword
//                   //             ? Icon(
//                   //                 Icons.check,
//                   //                 color: Colors.green,
//                   //               )
//                   //             : Icon(
//                   //                 Icons.close,
//                   //                 color: kWhiteColor,
//                   //               ),
//                   //     focusedBorder: UnderlineInputBorder(
//                   //       borderSide: BorderSide(color: kSecondaryColor),
//                   //     ),
//                   //     enabledBorder: UnderlineInputBorder(
//                   //       borderSide: BorderSide(color: kBlackColor),
//                   //     ),
//                   //   ),
//                   // ),
