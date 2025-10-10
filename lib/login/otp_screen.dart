/////old working code with android autofill, note: ios is not verified yet////
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/models/biometric_credential.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/services/biometric_services/biometric_credentials_manager.dart';
import 'package:zmall/services/biometric_services/biometric_service.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/utils/tab_screen.dart';
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
  bool hasVerified = false; // Add flag to prevent multiple verifications
  bool _rememberMe = true; // Remember me checkbox state

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
    // Prevent processing if already verified
    if (hasVerified) return;

    setState(() {
      otpCode = code!;
      _otpController.text = otpCode;
    });

    if (otpCode.isNotEmpty &&
        otpCode.length == 6 &&
        !_isLoading &&
        !hasVerified) {
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
    setState(() {
      otpCode = '';
      isError = false;
      hasVerified = false; // Reset verification flag for new OTP
    });

    bool isGeneratOtp = await generateOtpAtLogin(
        phone: widget.phone, password: widget.password);
    if (isGeneratOtp) {
      // Re-listen for new OTP
      listenForCode();
      // debugPrint("after otp resend");
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
  // void _resetErrorState() {
  //   if (isError) {
  //     setState(() {
  //       isError = false;
  //     });
  //   }
  // }

  // // Handle input of digit from custom keyboard
  // void _handleDigitInput(String digit) {
  //   _resetErrorState();
  //   if (otpCode.length < 6) {
  //     setState(() {
  //       otpCode = otpCode + digit;
  //       _otpController.text = otpCode;
  //     });

  //     if (otpCode.length == 6) {
  //       _verifyOTP(phone: widget.phone, code: otpCode);
  //     }
  //   }
  // }

  // // Handle backspace from custom keyboard
  // void _handleBackspace() {
  //   _resetErrorState();
  //   if (otpCode.isNotEmpty) {
  //     setState(() {
  //       otpCode = otpCode.substring(0, otpCode.length - 1);
  //       _otpController.text = otpCode;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _animationController.dispose();
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    // Cancel SMS listening
    try {
      cancel(); // Cancel the CodeAutoFill mixin
      SmsAutoFill().unregisterListener();
    } catch (e) {
      // print('Error disposing SMS listener: $e');
    }
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
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        color: kPrimaryColor,
        progressIndicator: LinearLoadingIndicator(),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(kDefaultPadding)),
                  child: Column(
                    spacing: getProportionateScreenHeight(kDefaultPadding),
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
                      Text(
                        "We have sent the code to the SMS for ${widget.areaCode + widget.phone}.\nPlease enter the code sent to your phone",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      SlideTransition(
                        position: _shakeAnimation,
                        child: PinFieldAutoFill(
                          codeLength: 6,
                          autoFocus: true,
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
                                : Colors.transparent),
                            // A border width based on error state
                            strokeWidth: isError ? 2.0 : 1.0,
                          ),
                          onCodeChanged: (code) {
                            // debugPrint("onchnage");
                            if (hasVerified) return; // Skip if already verified

                            setState(() {
                              otpCode = code ?? '';
                            });

                            if (code != null &&
                                code.length == 6 &&
                                !_isLoading &&
                                !hasVerified) {
                              //// Auto-verify with a small delay for UI update
                              Future.delayed(Duration(milliseconds: 200), () {
                                if (!_isLoading && !hasVerified) {
                                  // Prevent multiple verification attempts
                                  _verifyOTP(phone: widget.phone, code: code);
                                }
                              });
                            }
                          },
                          onCodeSubmitted: (code) {
                            // debugPrint("onCodeSubmitted");
                            if (hasVerified) return; // Skip if already verified

                            if (code.length == 6 &&
                                !_isLoading &&
                                !hasVerified) {
                              //// Auto-verify with a small delay for UI update
                              Future.delayed(Duration(milliseconds: 200), () {
                                if (!_isLoading && !hasVerified) {
                                  // Prevent multiple verification attempts
                                  _verifyOTP(phone: widget.phone, code: code);
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding / 2),
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
              const SizedBox(height: kDefaultPadding),
              ///////////////Remember Me Checkbox///////////////
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? true;
                        });
                      },
                      activeColor: kSecondaryColor,
                      side:
                          BorderSide(color: kGreyColor.withValues(alpha: 0.5)),
                    ),
                    Expanded(
                      child: Text(
                        "Remember me for quick login",
                        style: TextStyle(
                          fontSize: 14,
                          color: kGreyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ///////////////Number Keyboard section///////////////
              // Container(
              //   margin: EdgeInsets.only(top: kDefaultPadding / 2),
              //   padding: EdgeInsets.only(bottom: 30),
              //   decoration: BoxDecoration(color: kWhiteColor
              //       //  kGreyColor.withValues(alpha: 0.1),
              //       ),
              //   child: Column(
              //     children: [
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         spacing: getProportionateScreenWidth(kDefaultPadding / 4),
              //         children: [
              //           _numberButton('1'),
              //           _numberButton('2'),
              //           _numberButton('3'),
              //         ],
              //       ),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         spacing: getProportionateScreenWidth(kDefaultPadding / 4),
              //         children: [
              //           _numberButton('4'),
              //           _numberButton('5'),
              //           _numberButton('6'),
              //         ],
              //       ),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         spacing: getProportionateScreenWidth(kDefaultPadding / 4),
              //         children: [
              //           _numberButton('7'),
              //           _numberButton('8'),
              //           _numberButton('9'),
              //         ],
              //       ),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         spacing: getProportionateScreenWidth(kDefaultPadding / 4),
              //         children: [
              //           // _numberButton(''),
              //           // _emptySpaceButton(),
              //           _backspaceButton(),
              //           _numberButton('0'),
              //           _submitButton(),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

//////////////////////////////Custom Widget section///////////////////////////////////////////
  // Widget _numberButton(String number) {
  //   return Padding(
  //     padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
  //     child: SizedBox(
  //       width: getProportionateScreenWidth(kDefaultPadding * 7),
  //       height: getProportionateScreenHeight(kDefaultPadding * 3),
  //       child: ElevatedButton(
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: kPrimaryColor,
  //           foregroundColor: kBlackColor,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(kDefaultPadding / 2),
  //           ),
  //         ),
  //         onPressed: () => _handleDigitInput(number),
  //         child: Text(
  //           number,
  //           style: const TextStyle(fontSize: 24),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _submitButton() {
  //   return Padding(
  //     padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
  //     child: SizedBox(
  //       width: getProportionateScreenWidth(kDefaultPadding * 7),
  //       height: getProportionateScreenHeight(kDefaultPadding * 3),
  //       child: ElevatedButton(
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: kPrimaryColor,
  //           foregroundColor: kBlackColor,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(kDefaultPadding / 2),
  //           ),
  //         ),
  //         onPressed: () {
  //           if (otpCode.isNotEmpty && otpCode.length == 6) {
  //             _verifyOTP(phone: widget.phone, code: otpCode);
  //           }
  //         },
  //         child: _isLoading
  //             ? loadingIndicator(size: 30, color: kSecondaryColor)
  //             : const Icon(
  //                 size: 26,
  //                 HeroiconsOutline.arrowRight,
  //                 color: kBlackColor,
  //               ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _backspaceButton() {
  //   return Padding(
  //     padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
  //     child: SizedBox(
  //       width: getProportionateScreenWidth(kDefaultPadding * 7),
  //       height: getProportionateScreenHeight(kDefaultPadding * 3),
  //       child: ElevatedButton(
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: kPrimaryColor,
  //           foregroundColor: kBlackColor,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(kDefaultPadding / 2),
  //           ),
  //         ),
  //         onPressed: _handleBackspace,
  //         child: const Icon(
  //           size: 26,
  //           HeroiconsOutline.backspace,
  //           color: kBlackColor,
  //         ),
  //       ),
  //     ),
  //   );
  // }

//////////////////////////////API Requiest section///////////////////////////////////////////
  //  /api/user/forgot_password_with_otp"
  void _verifyOTP({required String phone, required String code}) async {
    // Prevent multiple simultaneous calls
    if (_isLoading || hasVerified) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var data = await verifyOTP(phone, code);
      if (data != null && data["success"] != null && data["success"]) {
        setState(() {
          hasVerified = true; // Mark as verified to prevent further attempts
        });
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
          Future.delayed(Duration(milliseconds: 300), () async {
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

            // Save account to multi-account storage if remember me is checked
            if (_rememberMe) {
              // print('Remember me is checked - saving account');
              // Build user name from available fields
              final firstName = loginResponseData['user']['first_name'] ?? '';
              final lastName = loginResponseData['user']['last_name'] ?? '';
              final userName = (firstName.isNotEmpty || lastName.isNotEmpty)
                  ? '$firstName $lastName'.trim()
                  : (loginResponseData['user']['name'] ?? phone);

              // print('User name to save: $userName');
              await _saveAccountAndPromptBiometric(
                phone: phone,
                password: password,
                userName: userName,
              );
              // print('Account saved successfully');
            } else {
              // print('Remember me is NOT checked - skipping save');
            }

            // Update index before navigation
            // Provider.of<BottomNavigationState>(
            //   context,
            //   listen: false,
            // ).updateSelectedIndex(0);

            // Navigate - ensure context is still valid
            if (mounted && context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                TabScreen.routeName,
                (Route<dynamic> route) => false,
              );
            }
            // if (widget.firstRoute) {
            //   Navigator.pushNamedAndRemoveUntil(
            //     context,
            //     TabScreen.routeName,
            //     (Route<dynamic> route) => false,
            //   );
            // } else {
            //   Navigator.of(context).pop();
            // }
          });
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

  /// Save account to multi-account storage
  Future<void> _saveAccountAndPromptBiometric({
    required String phone,
    required String password,
    required String userName,
  }) async {
    try {
      // print('Checking for existing account: $phone');
      // Check if account already exists with biometric enabled
      final existingAccount =
          await BiometricCredentialsManager.getAccount(phone);

      if (existingAccount != null && existingAccount.biometricEnabled) {
        // print('Account exists with biometric - updating');
        // Account already has biometric - just update timestamp and user name
        await BiometricCredentialsManager.updateLastUsed(phone);
        await BiometricCredentialsManager.updateUserName(phone, userName);
        // print('Account updated');
        return;
      }

      // print('Saving new account for $userName ($phone)');
      // Save account without biometric (user can enable it later in profile)
      final credential = BiometricCredential(
        phone: phone,
        password: password,
        biometricEnabled: false,
        userName: userName,
        lastUsed: DateTime.now(),
      );
      await BiometricCredentialsManager.saveAccount(credential);
      // print('Account saved to storage');
    } catch (e) {
      // print('Error saving account: $e');
    }
  }
}

//updated working code, android only
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:heroicons_flutter/heroicons_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:sms_autofill/sms_autofill.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/service.dart';
// import 'package:zmall/size_config.dart';
// import 'package:zmall/tab_screen.dart';

// class OtpScreen extends StatefulWidget {
//   static String id = '/otpScreen';
//   OtpScreen({
//     super.key,
//     required this.phone,
//     required this.password,
//     required this.areaCode,
//   });

//   final String phone;
//   final String password;
//   final String areaCode;

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen>
//     with CodeAutoFill, SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<Color?> _borderColorAnimation;
//   late Animation<Offset> _shakeAnimation;

//   ////
//   final TextEditingController _otpController = TextEditingController();
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   static const int countdownDuration = 60;
//   late int _remainingSeconds;
//   Timer? _timer;
//   bool _isLoading = false;
//   // String errorMessage = '';
//   // String password = '';
//   // String phone = '';
//   var otpResponse;
//   var responseData;
//   String otpCode = '';
//   bool isError = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeSmsListener();
//     _startCountdown();
//     // Hide the keyboard immediately when screen loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       SystemChannels.textInput.invokeMethod('TextInput.hide');
//     });
//     // Initialize animation controller
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     // Create border color animation
//     _borderColorAnimation = ColorTween(
//       begin: kGreyColor.withValues(alpha: 0.4),
//       end: Colors.green,
//     ).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
//       ),
//     );

//     // Create shake animation
//     _shakeAnimation = TweenSequence<Offset>([
//       TweenSequenceItem(
//         tween: Tween<Offset>(begin: Offset.zero, end: Offset(0.05, 0.0)),
//         weight: 1.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween<Offset>(
//           begin: Offset(0.05, 0.0),
//           end: Offset(-0.05, 0.0),
//         ),
//         weight: 2.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween<Offset>(
//           begin: Offset(-0.05, 0.0),
//           end: Offset(0.05, 0.0),
//         ),
//         weight: 2.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween<Offset>(
//           begin: Offset(0.05, 0.0),
//           end: Offset(-0.05, 0.0),
//         ),
//         weight: 2.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween<Offset>(
//           begin: Offset(-0.05, 0.0),
//           end: Offset(0.0, 0.0),
//         ),
//         weight: 1.0,
//       ),
//     ]).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
//       ),
//     );

//     // Add listener to rebuild widget when animation value changes
//     _animationController.addListener(() {
//       setState(() {});
//     });

//     // Listen for changes in otpCode
//     _otpController.addListener(_onOtpChanged);
//   }

//   void _onOtpChanged() {
//     setState(() {
//       otpCode = _otpController.text;
//     });
//   }

//   Future<void> _initializeSmsListener() async {
//     try {
//       // Platform-specific SMS autofill setup
//       if (Platform.isAndroid) {
//         // Android: Get app signature for SMS verification
//         final appSignature = await SmsAutoFill().getAppSignature;
//         print('==========================================');
//         print('ANDROID SMS AUTOFILL SETUP');
//         print('App signature: $appSignature');
//         print('IMPORTANT: Backend must include this in SMS format:');
//         print('Your OTP code is: 123456 $appSignature');
//         print('==========================================');

//         // Request SMS permission hint (optional - shows phone number picker)
//         try {
//           final hint = await SmsAutoFill().hint;
//           if (hint != null) {
//             print('Phone number hint: $hint');
//           }
//         } catch (e) {
//           print('Could not get phone hint: $e');
//         }
//       } else if (Platform.isIOS) {
//         // iOS: Uses system's native SMS autofill
//         print('==========================================');
//         print('iOS SMS AUTOFILL SETUP');
//         print('SMS format for iOS should be:');
//         print('Your verification code is: 123456');
//         print('iOS will automatically detect OTP codes');
//         print('==========================================');
//       }

//       // Start listening for SMS codes on both platforms
//       await SmsAutoFill().listenForCode();
//       print(
//           'Started listening for SMS codes on ${Platform.isIOS ? 'iOS' : 'Android'}');

//       // Set up timeout to stop listening after 5 minutes
//       Future.delayed(Duration(minutes: 5), () {
//         SmsAutoFill().unregisterListener();
//         print('Stopped listening for SMS codes after 5 minutes');
//       });
//     } catch (e) {
//       print('Error initializing SMS listener: $e');
//       // Continue without SMS autofill if initialization fails
//     }
//   }

//   @override
//   void codeUpdated() {
//     // This is called when SMS is detected
//     if (code != null && code!.isNotEmpty) {
//       print('Raw SMS received: $code');

//       // Try multiple patterns to extract the 6-digit OTP
//       String? extractedOtp;

//       // Pattern 1: Look for standalone 6 digit number on its own line
//       // This will match the format where OTP is on its own line like:
//       // "123456" or "123456\n"
//       final standalonePattern = RegExp(r'^(\d{6})$', multiLine: true);
//       final standaloneMatch = standalonePattern.firstMatch(code!);
//       if (standaloneMatch != null) {
//         extractedOtp = standaloneMatch.group(1);
//         print('Found OTP using standalone pattern: $extractedOtp');
//       }

//       // Pattern 2: Look for 6 digit sequence with word boundaries
//       // This matches "code: 123456" or "OTP 123456" etc
//       if (extractedOtp == null) {
//         final digitPattern = RegExp(r'\b(\d{6})\b');
//         final digitMatch = digitPattern.firstMatch(code!);
//         if (digitMatch != null) {
//           extractedOtp = digitMatch.group(1);
//           print('Found OTP using digit pattern: $extractedOtp');
//         }
//       }

//       // Pattern 3: Look for exactly 6 consecutive digits anywhere
//       if (extractedOtp == null) {
//         final consecutivePattern = RegExp(r'(\d{6})');
//         final consecutiveMatch = consecutivePattern.firstMatch(code!);
//         if (consecutiveMatch != null) {
//           extractedOtp = consecutiveMatch.group(1);
//           print('Found OTP using consecutive pattern: $extractedOtp');
//         }
//       }

//       // Pattern 4: If all else fails, extract all digits and check if total is 6
//       if (extractedOtp == null) {
//         final allDigits = code!.replaceAll(RegExp(r'[^0-9]'), '');
//         // Only use this if we have exactly 6 digits total in the message
//         if (allDigits.length == 6) {
//           extractedOtp = allDigits;
//           print('Found OTP by extracting all digits: $extractedOtp');
//         } else if (allDigits.length > 6) {
//           // If more than 6 digits, try to find first 6 consecutive
//           extractedOtp = allDigits.substring(0, 6);
//           print(
//               'Using first 6 digits from ${allDigits.length} total digits: $extractedOtp');
//         }
//       }

//       if (extractedOtp != null && extractedOtp.length == 6) {
//         setState(() {
//           otpCode = extractedOtp!;
//           _otpController.text = extractedOtp;
//         });

//         print(
//             'SMS Auto-filled code: $extractedOtp on ${Platform.isIOS ? 'iOS' : 'Android'}');

//         // Stop listening once we have the code
//         SmsAutoFill().unregisterListener();

//         // Auto-verify with a small delay for UI update
//         Future.delayed(Duration(milliseconds: 300), () {
//           if (!_isLoading) {
//             // Prevent multiple verification attempts
//             _verifyOTP(phone: widget.phone, code: extractedOtp!);
//           }
//         });
//       } else {
//         print('Could not extract valid 6-digit OTP from SMS');
//         if (extractedOtp != null) {
//           print(
//               'Extracted value was: $extractedOtp (length: ${extractedOtp.length})');
//         }
//       }
//     }
//   }

//   ////resend code countdown
//   void _startCountdown() {
//     _remainingSeconds = countdownDuration;
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_remainingSeconds > 0) {
//         setState(() {
//           _remainingSeconds--;
//         });
//       } else {
//         _timer?.cancel();
//       }
//     });
//   }

//   //resend code
//   void _handleResend() async {
//     _otpController.clear();
//     setState(() {
//       otpCode = '';
//       isError = false;
//     });

//     // Re-initialize SMS listener for new code
//     await _initializeSmsListener();

//     bool isGeneratOtp = await generateOtpAtLogin(
//       phone: widget.phone,
//       password: widget.password,
//     );
//     if (isGeneratOtp) {
//       // debugPrint("after otp resend");
//       _startCountdown();
//     }
//   }

//   // Function to show error animation
//   void _showErrorAnimation() {
//     setState(() {
//       isError = true;
//     });

//     _animationController.reset();
//     _animationController.forward();
//   }

//   // Reset error state
//   void _resetErrorState() {
//     if (isError) {
//       setState(() {
//         isError = false;
//       });
//     }
//   }

//   // Handle input of digit from custom keyboard
//   void _handleDigitInput(String digit) {
//     _resetErrorState();
//     if (otpCode.length < 6 && !_isLoading) {
//       // Prevent input during verification
//       setState(() {
//         otpCode = otpCode + digit;
//         _otpController.text = otpCode;
//       });

//       if (otpCode.length == 6) {
//         // Hide keyboard and verify
//         SystemChannels.textInput.invokeMethod('TextInput.hide');

//         // Small delay to ensure UI updates
//         Future.delayed(Duration(milliseconds: 100), () {
//           if (!_isLoading) {
//             // Double-check to prevent multiple attempts
//             _verifyOTP(phone: widget.phone, code: otpCode);
//           }
//         });
//       }
//     }
//   }

//   // Handle backspace from custom keyboard
//   void _handleBackspace() {
//     _resetErrorState();
//     if (otpCode.isNotEmpty && !_isLoading) {
//       // Prevent changes during verification
//       setState(() {
//         otpCode = otpCode.substring(0, otpCode.length - 1);
//         _otpController.text = otpCode;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _otpController.removeListener(_onOtpChanged);
//     _otpController.dispose();
//     // Cancel SMS listening
//     try {
//       SmsAutoFill().unregisterListener();
//       cancel(); // Cancel the CodeAutoFill mixin
//     } catch (e) {
//       print('Error disposing SMS listener: $e');
//     }
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Ensure keyboard stays hidden
//     SystemChannels.textInput.invokeMethod('TextInput.hide');

//     return Scaffold(
//       appBar: AppBar(title: Text('Verify OTP')),
//       body: SafeArea(
//         bottom: false,
//         child: Column(
//           children: [
//             Expanded(
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(kDefaultPadding),
//                   child: Column(
//                     spacing: kDefaultPadding,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(kDefaultPadding / 1.5),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(kDefaultPadding),
//                           color: kWhiteColor,
//                         ),
//                         child: Icon(
//                           HeroiconsOutline.chatBubbleLeftEllipsis,
//                           size: 40,
//                           color: kBlackColor.withValues(alpha: 0.7),
//                         ),
//                       ),
//                       const SizedBox(height: kDefaultPadding / 2),
//                       Text(
//                         "We have sent the code to the SMS for ${widget.areaCode + widget.phone}.\nPlease enter the code sent to your phone",
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: kDefaultPadding / 2),
//                       SlideTransition(
//                         position: _shakeAnimation,
//                         child: GestureDetector(
//                           onTap: () {
//                             // Prevent keyboard from showing when tapped
//                             SystemChannels.textInput
//                                 .invokeMethod('TextInput.hide');
//                           },
//                           child: AbsorbPointer(
//                             absorbing: true, // Prevent any touch interaction
//                             child: PinFieldAutoFill(
//                               codeLength: 6,
//                               currentCode: otpCode,
//                               controller: _otpController,
//                               autoFocus:
//                                   false, // Disable autofocus to prevent keyboard
//                               enableInteractiveSelection:
//                                   false, // Disable text selection
//                               keyboardType: TextInputType
//                                   .none, // Disable keyboard completely
//                               cursor: Cursor(
//                                 width: 2,
//                                 color: Colors.transparent, // Hide cursor
//                                 enabled: false,
//                               ),
//                               decoration: BoxLooseDecoration(
//                                 strokeColorBuilder: FixedColorBuilder(
//                                   // _otpController.text.isEmpty
//                                   // ? kGreyColor
//                                   // :
//                                   isError
//                                       ? kSecondaryColor
//                                       : kGreyColor.withValues(alpha: 0.3),
//                                 ),
//                                 bgColorBuilder: FixedColorBuilder(
//                                   isError
//                                       ? kSecondaryColor.withValues(alpha: 0.18)
//                                       : Colors.transparent,
//                                   //  kPrimaryColor.withValues(alpha: 0.6),
//                                   // kGreenColor.withValues(alpha: 0.18)
//                                   // : _otpController.text.isNotEmpty
//                                   // ? kGreenColor.withValues(alpha: 0.18)
//                                   // : kPrimaryColor.withValues(alpha: 0.6),
//                                 ),
//                                 // A border width based on error state
//                                 strokeWidth: isError ? 2.0 : 1.0,
//                               ),
//                               onCodeChanged: (code) {
//                                 if (code?.isNotEmpty == true) {
//                                   setState(() {
//                                     otpCode = code!;
//                                   });
//                                   print('OTP code changed: $code');

//                                   // Auto-verify when 6 digits are entered
//                                   if (code!.length == 6) {
//                                     _verifyOTP(phone: widget.phone, code: code);
//                                   }
//                                 }
//                               },
//                               onCodeSubmitted: (code) {
//                                 print('OTP code submitted: $code');
//                                 if (code.length == 6) {
//                                   _verifyOTP(phone: widget.phone, code: code);
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             ///////////////Resend OTP section///////////////
//             Center(
//               child: _remainingSeconds > 0
//                   ? Text(
//                       "Didn't receive a code? resend in ${_remainingSeconds}s",
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: kGreyColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           "Didn't receive a code?",
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: kGreyColor,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: _handleResend,
//                           child: Text(
//                             "Resend code",
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: kSecondaryColor,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//             ///////////////Number Keyboard section///////////////
//             Container(
//               margin: EdgeInsets.only(top: kDefaultPadding / 2),
//               padding: EdgeInsets.only(bottom: 30),
//               decoration: BoxDecoration(
//                 color: kWhiteColor,
//                 //  kGreyColor.withValues(alpha: 0.1),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
//                     children: [
//                       _numberButton('1'),
//                       _numberButton('2'),
//                       _numberButton('3'),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
//                     children: [
//                       _numberButton('4'),
//                       _numberButton('5'),
//                       _numberButton('6'),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
//                     children: [
//                       _numberButton('7'),
//                       _numberButton('8'),
//                       _numberButton('9'),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
//                     children: [
//                       // _numberButton(''),
//                       // _emptySpaceButton(),
//                       _backspaceButton(),
//                       _numberButton('0'),
//                       _submitButton(),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   //////////////////////////////Custom Widget section///////////////////////////////////////////
//   Widget _numberButton(String number) {
//     return Padding(
//       padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
//       child: SizedBox(
//         width: getProportionateScreenWidth(kDefaultPadding * 7),
//         height: getProportionateScreenHeight(kDefaultPadding * 3),
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: kPrimaryColor,
//             foregroundColor: kBlackColor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(kDefaultPadding / 2),
//             ),
//           ),
//           onPressed: () => _handleDigitInput(number),
//           child: Text(number, style: const TextStyle(fontSize: 24)),
//         ),
//       ),
//     );
//   }

//   Widget _submitButton() {
//     return Padding(
//       padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
//       child: SizedBox(
//         width: getProportionateScreenWidth(kDefaultPadding * 7),
//         height: getProportionateScreenHeight(kDefaultPadding * 3),
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: kPrimaryColor,
//             foregroundColor: kBlackColor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(kDefaultPadding / 2),
//             ),
//           ),
//           onPressed: () {
//             if (otpCode.isNotEmpty && otpCode.length == 6) {
//               _verifyOTP(phone: widget.phone, code: otpCode);
//             }
//           },
//           child: _isLoading
//               ? loadingIndicator(size: 30, color: kSecondaryColor)
//               : const Icon(
//                   size: 26,
//                   HeroiconsOutline.arrowRight,
//                   color: kBlackColor,
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _backspaceButton() {
//     return Padding(
//       padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
//       child: SizedBox(
//         width: getProportionateScreenWidth(kDefaultPadding * 7),
//         height: getProportionateScreenHeight(kDefaultPadding * 3),
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: kPrimaryColor,
//             foregroundColor: kBlackColor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(kDefaultPadding / 2),
//             ),
//           ),
//           onPressed: _handleBackspace,
//           child: const Icon(
//             size: 26,
//             HeroiconsOutline.backspace,
//             color: kBlackColor,
//           ),
//         ),
//       ),
//     );
//   }

//   //////////////////////////////API Requiest section///////////////////////////////////////////
//   //  /api/user/forgot_password_with_otp"
//   void _verifyOTP({required String phone, required String code}) async {
//     // Prevent multiple simultaneous verification attempts
//     if (_isLoading) return;

//     // Clean the code to ensure only digits
//     final cleanCode = code.replaceAll(RegExp(r'[^0-9]'), '');
//     if (cleanCode.length != 6) {
//       print('Invalid OTP length: ${cleanCode.length}');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       var data = await verifyOTP(phone, cleanCode);
//       if (data != null && data["success"] != null && data["success"]) {
//         // Success - stop listening for SMS
//         SmsAutoFill().unregisterListener();
//         _login(phone: phone, password: widget.password);
//       } else {
//         setState(() {
//           isError = true;
//         });
//         _showErrorAnimation();
//         Service.showMessage(
//           context: context,
//           title: "Your OTP is incorrect or no longer valid. Please try again.",
//           error: true,
//         );

//         // Clear the OTP field for retry
//         setState(() {
//           otpCode = '';
//           _otpController.clear();
//         });
//       }
//     } catch (e) {
//       print('Error verifying OTP: $e');
//       _showErrorAnimation();
//       setState(() {
//         isError = true;
//       });
//       Service.showMessage(
//         context: context,
//         title: "Failed to verify OTP. Please try again.",
//         error: true,
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<dynamic> verifyOTP(String phone, String code) async {
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/verify_otp";

//     setState(() {
//       _isLoading = true;
//     });

//     Map data = {"code": code, "phone": phone};
//     var body = json.encode(data);

//     try {
//       http.Response response = await http
//           .post(
//         Uri.parse(url),
//         headers: <String, String>{
//           "Content-Type": "application/json",
//           "Accept": "application/json",
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
//       Service.showMessage(
//         context: context,
//         title: "Something went wrong! Please check your internet connection!",
//         error: true,
//       );
//       return null;
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   ////////login//////

//   // get responseData => null;
//   void _login({required String phone, required String password}) async {
//     var loginResponseData = await login(phone, password, context);
//     if (this.responseData != null) {
//       if (loginResponseData['success']) {
//         if (loginResponseData['user']['is_approved']) {
//           Service.save('user', responseData);
//           Service.saveBool('logged', true);

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 "You have successfully logged in!",
//                 style: TextStyle(color: kBlackColor),
//               ),
//               backgroundColor: kPrimaryColor,
//             ),
//           );
//           _fcm.subscribeToTopic(
//             Provider.of<ZMetaData>(
//               context,
//               listen: false,
//             ).country.replaceAll(' ', ''),
//           );
//           // Update index before navigation
//           // Provider.of<BottomNavigationState>(
//           //   context,
//           //   listen: false,
//           // ).updateSelectedIndex(0);

//           // Then navigate
//           Navigator.pushNamedAndRemoveUntil(
//             context,
//             TabScreen.routeName,
//             (Route<dynamic> route) => false,
//           );
//           // if (widget.firstRoute) {
//           //   Navigator.pushNamedAndRemoveUntil(
//           //     context,
//           //     TabScreen.routeName,
//           //     (Route<dynamic> route) => false,
//           //   );
//           // } else {
//           //   Navigator.of(context).pop();
//           // }
//         } else {
//           Service.showMessage(
//             context: context,
//             title:
//                 "Your account has either been deleted or deactivated. Please reach out to our customer service via email or hotline 8707 to reactivate your account!",
//             error: true,
//             duration: 8,
//           );
//         }
//       } else {
//         setState(() {
//           _isLoading = false;
//         });

//         Service.showMessage(
//           context: context,
//           title: responseData['error_code'] != null
//               ? "${errorCodes['${responseData['error_code']}']}"
//               : responseData['error_description'],
//           error: false,
//         );
//       }
//     }
//     setState(() {
//       _isLoading = false;
//     });
//   }

//   ///
//   ///
//   ///
//   ///
//   Future<dynamic> login(String phoneNumber, String password, context) async {
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/login";
//     String deviceType = Platform.isIOS ? 'iOS' : "android";
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       Map data = {
//         "email": phoneNumber,
//         "password": password,
//         "app_version": appVersion,
//         "device_type": deviceType,
//         //modified
//         //// todo: Change the next line before pushing to the App Store
//         // "device_type": "android",
//         // "device_type": 'iOS',
//       };
//       var body = json.encode(data);
//       http.Response response = await http
//           .post(
//         Uri.parse(url),
//         headers: <String, String>{
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//         },
//         body: body,
//       )
//           .timeout(
//         Duration(seconds: 10),
//         onTimeout: () {
//           throw TimeoutException("The connection has timed out!");
//         },
//       );
//       setState(() {
//         this.responseData = json.decode(response.body);
//       });

//       return json.decode(response.body);
//     } catch (e) {
//       return null;
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//   ///////////////otp authentication/////

//   Future<dynamic> generateOtpAtLogin({
//     required String phone,
//     required String password,
//   }) async {
//     var url =
//         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/generate_otp_at_login";
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       Map data = {"phone": phone, "password": password};
//       var body = json.encode(data);
//       http.Response response = await http
//           .post(
//         Uri.parse(url),
//         headers: <String, String>{"Content-Type": "application/json"},
//         body: body,
//       )
//           .timeout(
//         Duration(seconds: 10),
//         onTimeout: () {
//           throw TimeoutException("The connection has timed out!");
//         },
//       );
//       var newResponse = json.decode(response.body);
//       if (newResponse != null &&
//           (newResponse["success"] != null && newResponse["success"])) {
//         Service.showMessage(
//           context: context,
//           title: "OTP code sent to your phone...",
//           error: false,
//         );
//         return true;
//       } else {
//         Service.showMessage(
//           context: context,
//           title:
//               "Failed to send an OTP. Please check your phone and password and try again.",
//           error: true,
//         );
//         return false;
//       }
//     } catch (e) {
//       // print(e);
//       return false;
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
// }

// /////old working code with android autofill, note: ios is not verified yet////
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/material.dart';
// // import 'package:heroicons_flutter/heroicons_flutter.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:provider/provider.dart';
// // import 'package:sms_autofill/sms_autofill.dart';
// // import 'package:zmall/constants.dart';
// // import 'package:zmall/models/metadata.dart';
// // import 'package:zmall/service.dart';
// // import 'package:zmall/size_config.dart';
// // import 'package:zmall/tab_screen.dart';

// // class OtpScreen extends StatefulWidget {
// //   static String id = '/otpScreen';
// //   OtpScreen({
// //     super.key,
// //     required this.phone,
// //     required this.password,
// //     required this.areaCode,
// //   });

// //   final String phone;
// //   final String password;
// //   final String areaCode;

// //   @override
// //   State<OtpScreen> createState() => _OtpScreenState();
// // }

// // class _OtpScreenState extends State<OtpScreen>
// //     with CodeAutoFill, SingleTickerProviderStateMixin {
// //   late AnimationController _animationController;
// //   late Animation<Color?> _borderColorAnimation;
// //   late Animation<Offset> _shakeAnimation;

// //   ////
// //   final TextEditingController _otpController = TextEditingController();
// //   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
// //   static const int countdownDuration = 60;
// //   late int _remainingSeconds;
// //   Timer? _timer;
// //   bool _isLoading = false;
// //   // String errorMessage = '';
// //   // String password = '';
// //   // String phone = '';
// //   var otpResponse;
// //   var responseData;
// //   String otpCode = '';
// //   bool isError = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     listenForCode(); // Start listening for incoming OTP
// //     _startCountdown();
// //     // Initialize animation controller
// //     _animationController = AnimationController(
// //       duration: const Duration(milliseconds: 800),
// //       vsync: this,
// //     );

// //     // Create border color animation
// //     _borderColorAnimation = ColorTween(
// //       begin: kGreyColor.withValues(alpha: 0.4),
// //       end: Colors.green,
// //     ).animate(
// //       CurvedAnimation(
// //         parent: _animationController,
// //         curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
// //       ),
// //     );

// //     // Create shake animation
// //     _shakeAnimation = TweenSequence<Offset>([
// //       TweenSequenceItem(
// //         tween: Tween<Offset>(begin: Offset.zero, end: Offset(0.05, 0.0)),
// //         weight: 1.0,
// //       ),
// //       TweenSequenceItem(
// //         tween: Tween<Offset>(begin: Offset(0.05, 0.0), end: Offset(-0.05, 0.0)),
// //         weight: 2.0,
// //       ),
// //       TweenSequenceItem(
// //         tween: Tween<Offset>(begin: Offset(-0.05, 0.0), end: Offset(0.05, 0.0)),
// //         weight: 2.0,
// //       ),
// //       TweenSequenceItem(
// //         tween: Tween<Offset>(begin: Offset(0.05, 0.0), end: Offset(-0.05, 0.0)),
// //         weight: 2.0,
// //       ),
// //       TweenSequenceItem(
// //         tween: Tween<Offset>(begin: Offset(-0.05, 0.0), end: Offset(0.0, 0.0)),
// //         weight: 1.0,
// //       ),
// //     ]).animate(
// //       CurvedAnimation(
// //         parent: _animationController,
// //         curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
// //       ),
// //     );

// //     // Add listener to rebuild widget when animation value changes
// //     _animationController.addListener(() {
// //       setState(() {});
// //     });

// //     // Listen for changes in otpCode
// //     _otpController.addListener(_onOtpChanged);
// //   }

// //   void _onOtpChanged() {
// //     setState(() {
// //       otpCode = _otpController.text;
// //     });
// //   }

// //   @override
// //   void codeUpdated() {
// //     setState(() {
// //       otpCode = code!;
// //       _otpController.text = otpCode;
// //     });

// //     if (otpCode.isNotEmpty && otpCode.length == 6) {
// //       _verifyOTP(phone: widget.phone, code: otpCode);
// //     }
// //   }

// // ////resend code countdown
// //   void _startCountdown() {
// //     _remainingSeconds = countdownDuration;
// //     _timer?.cancel();
// //     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       if (_remainingSeconds > 0) {
// //         setState(() {
// //           _remainingSeconds--;
// //         });
// //       } else {
// //         _timer?.cancel();
// //       }
// //     });
// //   }

// // //resend code
// //   void _handleResend() async {
// //     _otpController.clear();
// //     bool isGeneratOtp = await generateOtpAtLogin(
// //         phone: widget.phone, password: widget.password);
// //     if (isGeneratOtp) {
// //       // debugPrint("after otp resend");
// //       _startCountdown();
// //     }
// //   }

// //   // Function to show error animation
// //   void _showErrorAnimation() {
// //     setState(() {
// //       isError = true;
// //     });

// //     _animationController.reset();
// //     _animationController.forward();
// //   }

// //   // Reset error state
// //   void _resetErrorState() {
// //     if (isError) {
// //       setState(() {
// //         isError = false;
// //       });
// //     }
// //   }

// //   // Handle input of digit from custom keyboard
// //   void _handleDigitInput(String digit) {
// //     _resetErrorState();
// //     if (otpCode.length < 6) {
// //       setState(() {
// //         otpCode = otpCode + digit;
// //         _otpController.text = otpCode;
// //       });

// //       if (otpCode.length == 6) {
// //         _verifyOTP(phone: widget.phone, code: otpCode);
// //       }
// //     }
// //   }

// //   // Handle backspace from custom keyboard
// //   void _handleBackspace() {
// //     _resetErrorState();
// //     if (otpCode.isNotEmpty) {
// //       setState(() {
// //         otpCode = otpCode.substring(0, otpCode.length - 1);
// //         _otpController.text = otpCode;
// //       });
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _animationController.dispose();
// //     _otpController.dispose();
// //     cancel();
// //     _timer?.cancel();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // TextTheme textTheme = Theme.of(context).textTheme;
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Verify OTP'),
// //       ),
// //       body: SafeArea(
// //         bottom: false,
// //         child: Column(
// //           children: [
// //             Expanded(
// //               child: Center(
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(kDefaultPadding),
// //                   child: Column(
// //                     spacing: kDefaultPadding,
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Container(
// //                         padding: EdgeInsets.all(kDefaultPadding / 1.5),
// //                         decoration: BoxDecoration(
// //                             borderRadius:
// //                                 BorderRadius.circular(kDefaultPadding),
// //                             color: kWhiteColor),
// //                         child: Icon(
// //                           HeroiconsOutline.chatBubbleLeftEllipsis,
// //                           size: 40,
// //                           color: kBlackColor.withValues(alpha: 0.7),
// //                         ),
// //                       ),
// //                       const SizedBox(height: kDefaultPadding / 2),
// //                       Text(
// //                         "We have sent the code to the SMS for ${widget.areaCode + widget.phone}.\nPlease enter the code sent to your phone",
// //                         textAlign: TextAlign.center,
// //                       ),
// //                       const SizedBox(height: kDefaultPadding / 2),
// //                       SlideTransition(
// //                         position: _shakeAnimation,
// //                         child: PinFieldAutoFill(
// //                           codeLength: 6,
// //                           currentCode: otpCode,
// //                           controller: _otpController,
// //                           decoration: BoxLooseDecoration(
// //                             strokeColorBuilder: FixedColorBuilder(
// //                               // _otpController.text.isEmpty
// //                               // ? kGreyColor
// //                               // :
// //                               isError
// //                                   ? kSecondaryColor
// //                                   : kGreyColor.withValues(alpha: 0.3),
// //                             ),
// //                             bgColorBuilder: FixedColorBuilder(isError
// //                                     ? kSecondaryColor.withValues(alpha: 0.18)
// //                                     : Colors.transparent
// //                                 //  kPrimaryColor.withValues(alpha: 0.6),
// //                                 // kGreenColor.withValues(alpha: 0.18)
// //                                 // : _otpController.text.isNotEmpty
// //                                 // ? kGreenColor.withValues(alpha: 0.18)
// //                                 // : kPrimaryColor.withValues(alpha: 0.6),
// //                                 ),
// //                             // A border width based on error state
// //                             strokeWidth: isError ? 2.0 : 1.0,
// //                           ),
// //                           onCodeChanged: (code) {
// //                             // debugPrint("onchnage");
// //                             setState(() {
// //                               code = _otpController.text;
// //                             });
// //                             // if (code != null && code.length == 6) {

// //                             // _verifyOTP(phone: widget.phone, code: code);
// //                             // }
// //                             // FocusScope.of(context).requestFocus(FocusNode());
// //                           },
// //                           onCodeSubmitted: (code) {
// //                             // debugPrint("onCodeSubmitted");
// //                             if (_otpController.text.length == 6) {
// //                               _verifyOTP(
// //                                   phone: widget.phone,
// //                                   code: _otpController.text);
// //                             }
// //                           },
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //             ///////////////Resend OTP section///////////////
// //             Center(
// //               child: _remainingSeconds > 0
// //                   ? Text(
// //                       "Didn't receive a code? resend in ${_remainingSeconds}s",
// //                       style: const TextStyle(
// //                           fontSize: 14,
// //                           color: kGreyColor,
// //                           fontWeight: FontWeight.bold),
// //                     )
// //                   : Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Text(
// //                           "Didn't receive a code?",
// //                           style: const TextStyle(
// //                               fontSize: 14,
// //                               color: kGreyColor,
// //                               fontWeight: FontWeight.bold),
// //                         ),
// //                         TextButton(
// //                             onPressed: _handleResend,
// //                             child: Text(
// //                               "Resend code",
// //                               style: TextStyle(
// //                                   fontSize: 14,
// //                                   color: kSecondaryColor,
// //                                   fontWeight: FontWeight.bold),
// //                             )),
// //                       ],
// //                     ),
// //             ),
// //             ///////////////Number Keyboard section///////////////
// //             Container(
// //               margin: EdgeInsets.only(top: kDefaultPadding / 2),
// //               padding: EdgeInsets.only(bottom: 30),
// //               decoration: BoxDecoration(color: kWhiteColor
// //                   //  kGreyColor.withValues(alpha: 0.1),
// //                   ),
// //               child: Column(
// //                 children: [
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
// //                     children: [
// //                       _numberButton('1'),
// //                       _numberButton('2'),
// //                       _numberButton('3'),
// //                     ],
// //                   ),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
// //                     children: [
// //                       _numberButton('4'),
// //                       _numberButton('5'),
// //                       _numberButton('6'),
// //                     ],
// //                   ),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
// //                     children: [
// //                       _numberButton('7'),
// //                       _numberButton('8'),
// //                       _numberButton('9'),
// //                     ],
// //                   ),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     spacing: getProportionateScreenWidth(kDefaultPadding / 4),
// //                     children: [
// //                       // _numberButton(''),
// //                       // _emptySpaceButton(),
// //                       _backspaceButton(),
// //                       _numberButton('0'),
// //                       _submitButton(),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// // //////////////////////////////Custom Widget section///////////////////////////////////////////
// //   Widget _numberButton(String number) {
// //     return Padding(
// //       padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
// //       child: SizedBox(
// //         width: getProportionateScreenWidth(kDefaultPadding * 7),
// //         height: getProportionateScreenHeight(kDefaultPadding * 3),
// //         child: ElevatedButton(
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: kPrimaryColor,
// //             foregroundColor: kBlackColor,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(kDefaultPadding / 2),
// //             ),
// //           ),
// //           onPressed: () => _handleDigitInput(number),
// //           child: Text(
// //             number,
// //             style: const TextStyle(fontSize: 24),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _submitButton() {
// //     return Padding(
// //       padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
// //       child: SizedBox(
// //         width: getProportionateScreenWidth(kDefaultPadding * 7),
// //         height: getProportionateScreenHeight(kDefaultPadding * 3),
// //         child: ElevatedButton(
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: kPrimaryColor,
// //             foregroundColor: kBlackColor,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(kDefaultPadding / 2),
// //             ),
// //           ),
// //           onPressed: () {
// //             if (otpCode.isNotEmpty && otpCode.length == 6) {
// //               _verifyOTP(phone: widget.phone, code: otpCode);
// //             }
// //           },
// //           child: _isLoading
// //               ? loadingIndicator(size: 30, color: kSecondaryColor)
// //               : const Icon(
// //                   size: 26,
// //                   HeroiconsOutline.arrowRight,
// //                   color: kBlackColor,
// //                 ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _backspaceButton() {
// //     return Padding(
// //       padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding / 2)),
// //       child: SizedBox(
// //         width: getProportionateScreenWidth(kDefaultPadding * 7),
// //         height: getProportionateScreenHeight(kDefaultPadding * 3),
// //         child: ElevatedButton(
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: kPrimaryColor,
// //             foregroundColor: kBlackColor,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(kDefaultPadding / 2),
// //             ),
// //           ),
// //           onPressed: _handleBackspace,
// //           child: const Icon(
// //             size: 26,
// //             HeroiconsOutline.backspace,
// //             color: kBlackColor,
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// // //////////////////////////////API Requiest section///////////////////////////////////////////
// //   //  /api/user/forgot_password_with_otp"
// //   void _verifyOTP({required String phone, required String code}) async {
// //     setState(() {
// //       _isLoading = true;
// //     });
// //     try {
// //       var data = await verifyOTP(phone, code);
// //       if (data != null && data["success"] != null && data["success"]) {
// //         _login(
// //           phone: phone,
// //           password: widget.password,
// //         );
// //       } else {
// //         setState(() {
// //           isError = true;
// //         });
// //         _showErrorAnimation();
// //         Service.showMessage(
// //             context: context,
// //             title:
// //                 "Your OTP is incorrect or no longer valid. Please try again.",
// //             error: true);
// //       }
// //     } catch (e) {
// //       _showErrorAnimation();
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   Future<dynamic> verifyOTP(String phone, String code) async {
// //     var url =
// //         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/verify_otp";

// //     setState(() {
// //       _isLoading = true;
// //     });

// //     Map data = {
// //       "code": code,
// //       "phone": phone,
// //     };
// //     var body = json.encode(data);

// //     try {
// //       http.Response response = await http
// //           .post(
// //         Uri.parse(url),
// //         headers: <String, String>{
// //           "Content-Type": "application/json",
// //           "Accept": "application/json"
// //         },
// //         body: body,
// //       )
// //           .timeout(
// //         Duration(seconds: 10),
// //         onTimeout: () {
// //           setState(() {
// //             this._isLoading = false;
// //           });
// //           throw TimeoutException("The connection has timed out!");
// //         },
// //       );

// //       return json.decode(response.body);
// //     } catch (e) {
// //       Service.showMessage(
// //         context: context,
// //         title: "Something went wrong! Please check your internet connection!",
// //         error: true,
// //       );
// //       return null;
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   ////////login//////

// //   // get responseData => null;
// //   void _login({required String phone, required String password}) async {
// //     var loginResponseData = await login(phone, password, context);
// //     if (this.responseData != null) {
// //       if (loginResponseData['success']) {
// //         if (loginResponseData['user']['is_approved']) {
// //           Service.save('user', responseData);
// //           Service.saveBool('logged', true);

// //           ScaffoldMessenger.of(
// //             context,
// //           ).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 "You have successfully logged in!",
// //                 style: TextStyle(
// //                   color: kBlackColor,
// //                 ),
// //               ),
// //               backgroundColor: kPrimaryColor,
// //             ),
// //           );
// //           _fcm.subscribeToTopic(
// //             Provider.of<ZMetaData>(
// //               context,
// //               listen: false,
// //             ).country.replaceAll(' ', ''),
// //           );
// //           // Update index before navigation
// //           // Provider.of<BottomNavigationState>(
// //           //   context,
// //           //   listen: false,
// //           // ).updateSelectedIndex(0);

// //           // Then navigate
// //           Navigator.pushNamedAndRemoveUntil(
// //             context,
// //             TabScreen.routeName,
// //             (Route<dynamic> route) => false,
// //           );
// //           // if (widget.firstRoute) {
// //           //   Navigator.pushNamedAndRemoveUntil(
// //           //     context,
// //           //     TabScreen.routeName,
// //           //     (Route<dynamic> route) => false,
// //           //   );
// //           // } else {
// //           //   Navigator.of(context).pop();
// //           // }
// //         } else {
// //           Service.showMessage(
// //             context: context,
// //             title:
// //                 "Your account has either been deleted or deactivated. Please reach out to our customer service via email or hotline 8707 to reactivate your account!",
// //             error: true,
// //             duration: 8,
// //           );
// //         }
// //       } else {
// //         setState(() {
// //           _isLoading = false;
// //         });

// //         Service.showMessage(
// //           context: context,
// //           title: responseData['error_code'] != null
// //               ? "${errorCodes['${responseData['error_code']}']}"
// //               : responseData['error_description'],
// //           error: false,
// //         );
// //       }
// //     }
// //     setState(() {
// //       _isLoading = false;
// //     });
// //   }

// //   ///
// //   ///
// //   ///
// //   ///
// //   Future<dynamic> login(String phoneNumber, String password, context) async {
// //     var url =
// //         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/login";
// //     String deviceType = Platform.isIOS ? 'iOS' : "android";
// //     setState(() {
// //       _isLoading = true;
// //     });
// //     try {
// //       Map data = {
// //         "email": phoneNumber,
// //         "password": password,
// //         "app_version": appVersion,
// //         "device_type": deviceType,
// //         //modified
// //         //// todo: Change the next line before pushing to the App Store
// //         // "device_type": "android",
// //         // "device_type": 'iOS',
// //       };
// //       var body = json.encode(data);
// //       http.Response response = await http
// //           .post(
// //         Uri.parse(url),
// //         headers: <String, String>{
// //           "Content-Type": "application/json",
// //           "Accept": "application/json",
// //         },
// //         body: body,
// //       )
// //           .timeout(
// //         Duration(seconds: 10),
// //         onTimeout: () {
// //           throw TimeoutException("The connection has timed out!");
// //         },
// //       );
// //       setState(() {
// //         this.responseData = json.decode(response.body);
// //       });

// //       return json.decode(response.body);
// //     } catch (e) {
// //       return null;
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// //   ///////////////otp authentication/////

// //   Future<dynamic> generateOtpAtLogin(
// //       {required String phone, required String password}) async {
// //     var url =
// //         "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/generate_otp_at_login";
// //     setState(() {
// //       _isLoading = true;
// //     });
// //     try {
// //       Map data = {
// //         "phone": phone,
// //         "password": password,
// //       };
// //       var body = json.encode(data);
// //       http.Response response = await http
// //           .post(
// //         Uri.parse(url),
// //         headers: <String, String>{"Content-Type": "application/json"},
// //         body: body,
// //       )
// //           .timeout(
// //         Duration(seconds: 10),
// //         onTimeout: () {
// //           throw TimeoutException("The connection has timed out!");
// //         },
// //       );
// //       var newResponse = json.decode(response.body);
// //       if (newResponse != null &&
// //           (newResponse["success"] != null && newResponse["success"])) {
// //         Service.showMessage(
// //             context: context,
// //             title: "OTP code sent to your phone...",
// //             error: false);
// //         return true;
// //       } else {
// //         Service.showMessage(
// //             context: context,
// //             title:
// //                 "Failed to send an OTP. Please check your phone and password and try again.",
// //             error: true);
// //         return false;
// //       }
// //     } catch (e) {
// //       // print(e);
// //       return false;
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }
// // }

  /// Prompt user to enable biometric authentication
  // Future<void> _promptBiometricSetup(String phone, String password) async {
  //   // Check if biometric is available and not already enabled
  //   final isAvailable = await BiometricService.isBiometricAvailable();
  //   final isEnabled = await Service.isBiometricEnabled();

  //   if (!isAvailable || isEnabled) return;

  //   final biometricName = await BiometricService.getBiometricTypeName();

  //   // Show dialog to ask user if they want to enable biometric
  //   if (mounted) {
  //     await showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           backgroundColor: kPrimaryColor,
  //           title: Text("Enable $biometricName?"),
  //           content: Text(
  //             "Would you like to enable $biometricName for quick and secure login?",
  //           ),
  //           actions: <Widget>[
  //             TextButton(
  //               child: Text(
  //                 "Not Now",
  //                 style: TextStyle(color: kGreyColor),
  //               ),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //             TextButton(
  //               child: Text(
  //                 "Enable",
  //                 style: TextStyle(
  //                   color: kSecondaryColor,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               onPressed: () async {
  //                 Navigator.of(context).pop();

  //                 // Test biometric authentication
  //                 final result = await BiometricService.authenticate(
  //                   localizedReason:
  //                       'Authenticate to enable $biometricName login',
  //                 );

  //                 if (result.success) {
  //                   // Save credentials
  //                   await Service.saveBiometricCredentials(
  //                     phone: phone,
  //                     password: password,
  //                   );
  //                   await Service.enableBiometric();

  //                   if (mounted) {
  //                     Service.showMessage(
  //                       context: context,
  //                       title: "$biometricName login enabled successfully!",
  //                       error: false,
  //                     );
  //                   }
  //                 } else if (result.errorMessage != null && mounted) {
  //                   Service.showMessage(
  //                     context: context,
  //                     title: result.errorMessage!,
  //                     error: true,
  //                   );
  //                 }
  //               },
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }