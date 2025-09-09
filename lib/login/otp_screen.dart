import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/tab_screen.dart';

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
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with CodeAutoFill, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Offset> _shakeAnimation;

  ////
  final TextEditingController _otpController = TextEditingController();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static const int countdownDuration = 60;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isLoading = false;
  // String errorMessage = '';
  // String password = '';
  // String phone = '';
  var otpResponse;
  var responseData;
  String otpCode = '';
  bool isError = false;

  @override
  void initState() {
    super.initState();
    listenForCode(); // Start listening for incoming OTP
    _startCountdown();
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

    // Listen for changes in otpCode
    _otpController.addListener(_onOtpChanged);
  }

  void _onOtpChanged() {
    setState(() {
      otpCode = _otpController.text;
    });
  }

  @override
  void codeUpdated() {
    setState(() {
      otpCode = code!;
      _otpController.text = otpCode;
    });

    if (otpCode.isNotEmpty && otpCode.length == 6) {
      _verifyOTP(phone: widget.phone, code: otpCode);
    }
  }

////resend code countdown
  void _startCountdown() {
    _remainingSeconds = countdownDuration;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

//resend code
  void _handleResend() async {
    _otpController.clear();
    bool isGeneratOtp = await generateOtpAtLogin(
        phone: widget.phone, password: widget.password);
    if (isGeneratOtp) {
      debugPrint("after otp resend");
      _startCountdown();
    }
  }

  // Function to show error animation
  void _showErrorAnimation() {
    setState(() {
      isError = true;
    });

    _animationController.reset();
    _animationController.forward();
  }

  // Reset error state
  void _resetErrorState() {
    if (isError) {
      setState(() {
        isError = false;
      });
    }
  }

  // Handle input of digit from custom keyboard
  void _handleDigitInput(String digit) {
    _resetErrorState();
    if (otpCode.length < 6) {
      setState(() {
        otpCode = otpCode + digit;
        _otpController.text = otpCode;
      });

      if (otpCode.length == 6) {
        _verifyOTP(phone: widget.phone, code: otpCode);
      }
    }
  }

  // Handle backspace from custom keyboard
  void _handleBackspace() {
    _resetErrorState();
    if (otpCode.isNotEmpty) {
      setState(() {
        otpCode = otpCode.substring(0, otpCode.length - 1);
        _otpController.text = otpCode;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otpController.dispose();
    cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Column(
                    spacing: kDefaultPadding,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(kDefaultPadding / 1.5),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding),
                            color: kWhiteColor),
                        child: Icon(
                          HeroiconsOutline.chatBubbleLeftEllipsis,
                          size: 40,
                          color: kBlackColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      Text(
                        "We have sent the code to the SMS for ${widget.areaCode + widget.phone}.\nPlease enter the code sent to your phone",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      SlideTransition(
                        position: _shakeAnimation,
                        child: PinFieldAutoFill(
                          codeLength: 6,
                          currentCode: otpCode,
                          controller: _otpController,
                          decoration: BoxLooseDecoration(
                            strokeColorBuilder: FixedColorBuilder(
                              // _otpController.text.isEmpty
                              // ? kGreyColor
                              // :
                              isError
                                  ? kSecondaryColor
                                  : kGreyColor.withValues(alpha: 0.3),
                            ),
                            bgColorBuilder: FixedColorBuilder(isError
                                    ? kSecondaryColor.withValues(alpha: 0.18)
                                    : Colors.transparent
                                //  kPrimaryColor.withValues(alpha: 0.6),
                                // kGreenColor.withValues(alpha: 0.18)
                                // : _otpController.text.isNotEmpty
                                // ? kGreenColor.withValues(alpha: 0.18)
                                // : kPrimaryColor.withValues(alpha: 0.6),
                                ),
                            // A border width based on error state
                            strokeWidth: isError ? 2.0 : 1.0,
                          ),
                          onCodeChanged: (code) {
                            // debugPrint("onchnage");
                            setState(() {
                              code = _otpController.text;
                            });
                            // if (code != null && code.length == 6) {

                            // _verifyOTP(phone: widget.phone, code: code);
                            // }
                            // FocusScope.of(context).requestFocus(FocusNode());
                          },
                          onCodeSubmitted: (code) {
                            // debugPrint("onCodeSubmitted");
                            if (_otpController.text.length == 6) {
                              _verifyOTP(
                                  phone: widget.phone,
                                  code: _otpController.text);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ///////////////Resend OTP section///////////////
            Center(
              child: _remainingSeconds > 0
                  ? Text(
                      "Didn't receive a code? resend in ${_remainingSeconds}s",
                      style: const TextStyle(
                          fontSize: 14,
                          color: kGreyColor,
                          fontWeight: FontWeight.bold),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive a code?",
                          style: const TextStyle(
                              fontSize: 14,
                              color: kGreyColor,
                              fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                            onPressed: _handleResend,
                            child: Text(
                              "Resend code",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: kSecondaryColor,
                                  fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
            ),
            ///////////////Number Keyboard section///////////////
            Container(
              margin: EdgeInsets.only(top: kDefaultPadding / 2),
              padding: EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(color: kWhiteColor
                  //  kGreyColor.withValues(alpha: 0.1),
                  ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: getProportionateScreenWidth(kDefaultPadding / 4),
                    children: [
                      _numberButton('1'),
                      _numberButton('2'),
                      _numberButton('3'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: getProportionateScreenWidth(kDefaultPadding / 4),
                    children: [
                      _numberButton('4'),
                      _numberButton('5'),
                      _numberButton('6'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: getProportionateScreenWidth(kDefaultPadding / 4),
                    children: [
                      _numberButton('7'),
                      _numberButton('8'),
                      _numberButton('9'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: getProportionateScreenWidth(kDefaultPadding / 4),
                    children: [
                      // _numberButton(''),
                      // _emptySpaceButton(),
                      _backspaceButton(),
                      _numberButton('0'),
                      _submitButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

//////////////////////////////Custom Widget section///////////////////////////////////////////
  Widget _numberButton(String number) {
    return Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
      child: SizedBox(
        width: getProportionateScreenWidth(kDefaultPadding * 7),
        height: getProportionateScreenHeight(kDefaultPadding * 3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: kBlackColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
          ),
          onPressed: () => _handleDigitInput(number),
          child: Text(
            number,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
      child: SizedBox(
        width: getProportionateScreenWidth(kDefaultPadding * 7),
        height: getProportionateScreenHeight(kDefaultPadding * 3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: kBlackColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
          ),
          onPressed: () {
            if (otpCode.isNotEmpty && otpCode.length == 6) {
              _verifyOTP(phone: widget.phone, code: otpCode);
            }
          },
          child: _isLoading
              ? loadingIndicator(size: 30, color: kSecondaryColor)
              : const Icon(
                  size: 26,
                  HeroiconsOutline.arrowRight,
                  color: kBlackColor,
                ),
        ),
      ),
    );
  }

  Widget _backspaceButton() {
    return Padding(
      padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
      child: SizedBox(
        width: getProportionateScreenWidth(kDefaultPadding * 7),
        height: getProportionateScreenHeight(kDefaultPadding * 3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: kBlackColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
          ),
          onPressed: _handleBackspace,
          child: const Icon(
            size: 26,
            HeroiconsOutline.backspace,
            color: kBlackColor,
          ),
        ),
      ),
    );
  }

//////////////////////////////API Requiest section///////////////////////////////////////////
  //  /api/user/forgot_password_with_otp"
  void _verifyOTP({required String phone, required String code}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      var data = await verifyOTP(phone, code);
      if (data != null && data["success"] != null && data["success"]) {
        _login(
          phone: phone,
          password: widget.password,
        );
      } else {
        setState(() {
          isError = true;
        });
        _showErrorAnimation();
        Service.showMessage(
            context: context,
            title:
                "Your OTP is incorrect or no longer valid. Please try again.",
            error: true);
      }
    } catch (e) {
      _showErrorAnimation();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<dynamic> verifyOTP(String phone, String code) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/verify_otp";

    setState(() {
      _isLoading = true;
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
            this._isLoading = false;
          });
          throw TimeoutException("The connection has timed out!");
        },
      );

      return json.decode(response.body);
    } catch (e) {
      Service.showMessage(
        context: context,
        title: "Something went wrong! Please check your internet connection!",
        error: true,
      );
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ////////login//////

  // get responseData => null;
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
          Service.showMessage(
            context: context,
            title:
                "Your account has either been deleted or deactivated. Please reach out to our customer service via email or hotline 8707 to reactivate your account!",
            error: true,
            duration: 8,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        Service.showMessage(
          context: context,
          title: responseData['error_code'] != null
              ? "${errorCodes['${responseData['error_code']}']}"
              : responseData['error_description'],
          error: false,
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
    String deviceType = Platform.isIOS ? 'iOS' : "android";
    setState(() {
      _isLoading = true;
    });
    try {
      Map data = {
        "email": phoneNumber,
        "password": password,
        "app_version": appVersion,
        "device_type": deviceType,
        //modified
        //// todo: Change the next line before pushing to the App Store
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
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  ///////////////otp authentication/////

  Future<dynamic> generateOtpAtLogin(
      {required String phone, required String password}) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/generate_otp_at_login";
    setState(() {
      _isLoading = true;
    });
    try {
      Map data = {
        "phone": phone,
        "password": password,
      };
      var body = json.encode(data);
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{"Content-Type": "application/json"},
        body: body,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );
      var newResponse = json.decode(response.body);
      if (newResponse != null &&
          (newResponse["success"] != null && newResponse["success"])) {
        Service.showMessage(
            context: context,
            title: "OTP code sent to your phone...",
            error: false);
        return true;
      } else {
        Service.showMessage(
            context: context,
            title:
                "Failed to send an OTP. Please check your phone and password and try again.",
            error: true);
        return false;
      }
    } catch (e) {
      // print(e);
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
