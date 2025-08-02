import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/tab_screen.dart';
import 'package:zmall/widgets/custom_back_button.dart';
import 'package:zmall/widgets/linear_loading_indicator.dart';

class OtpScreen extends StatefulWidget {
  static String id = '/otpScreen';
  OtpScreen({
    super.key,
    required this.phone,
    required this.password,
    required this.areaCode,
  });

  final String phone;
  final String password;
  final String areaCode;

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  //
  bool _loading = false;
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<bool> _fieldFilled = List.generate(6, (_) => false);

  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Offset> _shakeAnimation;

  bool _isError = false;
  String errorMessage = '';
  String password = '';
  String phone = '';
  var otpResponse;
  var responseData;

  @override
  void initState() {
    super.initState();
    phone = widget.phone;
    password = widget.password;

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create border color animation
    _borderColorAnimation = ColorTween(
      begin: kGreyColor.withValues(alpha: 0.4),
      end: Colors.green,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Create shake animation
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset(0.05, 0.0)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(0.05, 0.0), end: Offset(-0.05, 0.0)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(-0.05, 0.0), end: Offset(0.05, 0.0)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(0.05, 0.0), end: Offset(-0.05, 0.0)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(-0.05, 0.0), end: Offset(0.0, 0.0)),
        weight: 1.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Add listener to rebuild widget when animation value changes
    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  // Function to animate field when filled
  void _animateField(int index) {
    setState(() {
      _fieldFilled[index] = _controllers[index].text.isNotEmpty;
    });

    if (_controllers[index].text.isNotEmpty && !_isError) {
      // Short animation for individual field
      _animationController.forward().then((_) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _animationController.reverse();
          }
        });
      });
    }
  }

  // Reset error state
  void _resetErrorState() {
    if (_isError) {
      setState(() {
        _isError = false;
        errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Code"),
        leading: CustomBackButton(),
      ),
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: _isLoading,
          progressIndicator: LinearLoadingIndicator(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: getProportionateScreenHeight(kDefaultPadding * 4),
                    horizontal: getProportionateScreenWidth(kDefaultPadding)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: getProportionateScreenWidth(kDefaultPadding),
                  children: [
                    Text('Enter an OTP', style: textTheme.titleMedium
                        // TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                    Text(
                      "An OTP (verification code) has been sent to your phone ${widget.areaCode + widget.phone}.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: kGreyColor),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding * 2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SlideTransition(
                          position: _isError
                              ? _shakeAnimation
                              : Tween<Offset>(
                                      begin: Offset.zero, end: Offset.zero)
                                  .animate(_animationController),
                          child: SizedBox(
                            width: 50,
                            child: TextFormField(
                              maxLength: 1,
                              readOnly: true,
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              cursorColor: kBlackColor,
                              autofocus: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      kDefaultPadding * 0.8),
                                  borderSide: BorderSide(
                                    color: _isError
                                        ? kSecondaryColor
                                        : _fieldFilled[index]
                                            ? _borderColorAnimation.value ??
                                                kGreyColor.withValues(
                                                    alpha: 0.4)
                                            : kGreyColor.withValues(alpha: 0.4),
                                    width: (_fieldFilled[index] || _isError)
                                        ? 2.0
                                        : 1.0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      kDefaultPadding * 0.8),
                                  borderSide: BorderSide(
                                    color: _isError
                                        ? kSecondaryColor
                                        : _fieldFilled[index]
                                            ? _borderColorAnimation.value ??
                                                kGreyColor.withValues(
                                                    alpha: 0.4)
                                            : kGreyColor.withValues(alpha: 0.4),
                                    width: (_fieldFilled[index] || _isError)
                                        ? 2.0
                                        : 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      kDefaultPadding * 0.8),
                                  borderSide: BorderSide(
                                    color: _isError
                                        ? kSecondaryColor
                                        : _borderColorAnimation.value ??
                                            kGreyColor.withValues(alpha: 0.4),
                                    width: 2.0,
                                  ),
                                ),
                                filled: _isError,
                                fillColor: _isError
                                    ? kSecondaryColor.withValues(alpha: 0.1)
                                    : null,
                              ),
                              onChanged: (value) {
                                // Reset error state when user starts typing
                                _resetErrorState();

                                _animateField(index);

                                if (value.isNotEmpty && index < 5) {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNodes[index + 1]);
                                }
                                if (value.isEmpty && index > 0) {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNodes[index - 1]);
                                }

                                // Auto verify when all fields are filled
                                if (index == 5 && value.isNotEmpty) {
                                  String otp =
                                      _controllers.map((c) => c.text).join();
                                  if (otp.length == 6) {
                                    _verifyOTP(phone: phone, code: otp);
                                  }
                                }

                                setState(() {});
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(
                        height:
                            getProportionateScreenHeight(kDefaultPadding / 2)),
                    Text(
                      errorMessage,
                      style: textTheme.titleSmall!.copyWith(
                        fontSize: 14,
                        color: kSecondaryColor,
                      ),
                      // style: TextStyle(
                      //   color: kSecondaryColor,
                      //   fontWeight:
                      //       _isError ? FontWeight.bold : FontWeight.normal,
                      // ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              // Number Keyboard
              Container(
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: kGreyColor.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: getProportionateScreenWidth(kDefaultPadding),
                      children: [
                        _numberButton('1'),
                        _numberButton('2'),
                        _numberButton('3'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: getProportionateScreenWidth(kDefaultPadding),
                      children: [
                        _numberButton('4'),
                        _numberButton('5'),
                        _numberButton('6'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: getProportionateScreenWidth(kDefaultPadding),
                      children: [
                        _numberButton('7'),
                        _numberButton('8'),
                        _numberButton('9'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: getProportionateScreenWidth(kDefaultPadding),
                      children: [
                        // _numberButton(''),
                        _nextButton(),
                        _numberButton('0'),
                        _backspaceButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberButton(String number) {
    return Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
      child: SizedBox(
        width: getProportionateScreenWidth(kDefaultPadding * 6),
        height: getProportionateScreenHeight(kDefaultPadding * 3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kWhiteColor,
            foregroundColor: kBlackColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
          ),
          onPressed: number.isEmpty
              ? null
              : () {
                  // Reset error state when user inputs new numbers
                  _resetErrorState();

                  for (int i = 0; i < 6; i++) {
                    if (_controllers[i].text.isEmpty) {
                      _controllers[i].text = number;
                      _animateField(i);

                      // Check if this is the last field being filled
                      if (i == 5) {
                        String otp = _controllers.map((c) => c.text).join();
                        if (otp.length == 6) {
                          _verifyOTP(phone: phone, code: otp);
                        }
                      } else if (i < 5) {
                        FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                      }
                      break;
                    }
                  }
                },
          child: Text(
            number,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _nextButton() {
    return Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
      child: SizedBox(
        width: getProportionateScreenWidth(kDefaultPadding * 6),
        height: getProportionateScreenHeight(kDefaultPadding * 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWhiteColor,
                  foregroundColor: kBlackColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(kDefaultPadding / 2),
                      bottomLeft: Radius.circular(kDefaultPadding / 2),
                    ),
                  ),
                ),
                onPressed: () {
                  // Navigate to previous field
                  for (int i = 0; i < 6; i++) {
                    if (_focusNodes[i].hasFocus && i > 0) {
                      FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                      break;
                    }
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: kBlackColor,
                ),
              ),
            ),
            SizedBox(width: 1), // Small divider
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWhiteColor,
                  foregroundColor: kBlackColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(kDefaultPadding / 2),
                      bottomRight: Radius.circular(kDefaultPadding / 2),
                    ),
                  ),
                ),
                onPressed: () {
                  // Navigate to next field
                  for (int i = 0; i < 5; i++) {
                    if (_focusNodes[i].hasFocus) {
                      FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                      break;
                    }
                  }
                },
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: kBlackColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backspaceButton() {
    return Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
      child: SizedBox(
        width: getProportionateScreenWidth(kDefaultPadding * 6),
        height: getProportionateScreenHeight(kDefaultPadding * 3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kWhiteColor,
            foregroundColor: kBlackColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
          ),
          onPressed: () {
            _resetErrorState();

            for (int i = 5; i >= 0; i--) {
              if (_controllers[i].text.isNotEmpty) {
                _controllers[i].clear();
                _fieldFilled[i] = false;
                FocusScope.of(context).requestFocus(_focusNodes[i]);
                break;
              }
            }
          },
          child: const Icon(
            Icons.backspace,
            color: kBlackColor,
          ),
        ),
      ),
    );
  }

  //
  // /api/user/forgot_password_with_otp"
  void _verifyOTP({required String phone, required String code}) async {
    setState(() {
      _loading = true;
    });
    try {
      var data = await verifyOTP(phone, code);
      // print("data $data");
      // if (data != null && data['success']) {
      if (data != null && data["success"] != null && data["success"]) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   Service.showMessage("Password updated successfully", false),
        // );

        _login(
          phone: phone,
          password: password,
        );
      } else {
        setState(() {
          _isError = true;
          errorMessage =
              "Your OTP is incorrect or no longer valid. Please try again.";
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   Service.showMessage(
        //       "Failed to verify OTP, please enter a valid OTP", true),
        // );
        // Navigator.of(context).pop();
      }
    } catch (e) {
      // print("error");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<dynamic> verifyOTP(String phone, String code) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/verify_otp";
    // String token = Uuid().v4();

    setState(() {
      _loading = true;
    });

    Map data = {
      "code": code,
      "phone": phone,
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      // print(json.decode(response.body)['message']);
      return json.decode(response.body);
    } catch (e) {
      // print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Something went wrong! Please check your internet connection!"),
          backgroundColor: kSecondaryColor,
        ),
      );
      return null;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  ////////login//////
  bool _isLoading = false;
  void _login({required String phone, required String password}) async {
    var loginResponseData = await login(phone, password, context);
    if (this.responseData != null) {
      if (loginResponseData['success']) {
        if (loginResponseData['user']['is_approved']) {
          Service.save('user', responseData);
          Service.saveBool('logged', true);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                "You have successfully logged in!",
                style: TextStyle(
                  color: kBlackColor,
                ),
              ),
              backgroundColor: kPrimaryColor,
            ),
          );
          _fcm.subscribeToTopic(
            Provider.of<ZMetaData>(
              context,
              listen: false,
            ).country.replaceAll(' ', ''),
          );
          // Update index before navigation
          // Provider.of<BottomNavigationState>(
          //   context,
          //   listen: false,
          // ).updateSelectedIndex(0);

          // Then navigate
          Navigator.pushNamedAndRemoveUntil(
            context,
            TabScreen.routeName,
            (Route<dynamic> route) => false,
          );
          // if (widget.firstRoute) {
          //   Navigator.pushNamedAndRemoveUntil(
          //     context,
          //     TabScreen.routeName,
          //     (Route<dynamic> route) => false,
          //   );
          // } else {
          //   Navigator.of(context).pop();
          // }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            Service.showMessage(
              "Your account has either been deleted or deactivated. Please reach out to our customer service via email or hotline 8707 to reactivate your account!",
              true,
              duration: 8,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          Service.showMessage(
            responseData['error_code'] != null
                ? "${errorCodes['${responseData['error_code']}']}"
                : responseData['error_description'],
            false,
          ),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  ///
  ///
  ///
  ///
  Future<dynamic> login(String phoneNumber, String password, context) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/login";
    setState(() {
      _isLoading = true;
    });
    try {
      Map data = {
        "email": phoneNumber,
        "password": password,
        "app_version": "3.1.4",
        // TODO: Change the next line before pushing to the App Store
        "device_type": Platform.isIOS ? 'iOS' : "android",
        // "device_type": "android",
        // "device_type": 'iOS',
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
          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.responseData = json.decode(response.body);
      });

      return json.decode(response.body);
    } catch (e) {
      // print(e);
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
