// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/size_config.dart';

// import 'update_password.dart';

// class VerificationScreen extends StatefulWidget {
//   static String id = '/verification';
//   VerificationScreen({required this.code, required this.phone, this.login = false});
//   final String code;
//   final String phone;
//   final bool login;

//   @override
//   _VerificationScreenState createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   TextEditingController controller = TextEditingController(text: "");
//   bool hasError = false;
//   String? code;
//   String? phone;

//   @override
//   void initState() {
//     code = widget.code;
//     phone = widget.phone;
//     super.initState();
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Verify Code",
//           style: TextStyle(color: kBlackColor),
//         ),
//         elevation: 1.0,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(
//           getProportionateScreenHeight(kDefaultPadding),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             Text(
//               "An OTP (verification code) has been sent to your phone number or email address. Please enter the code correctly and press 'verify'!",
//               style: Theme.of(context)
//                   .textTheme
//                   .titleMedium
//                   ?.copyWith(color: kGreyColor),
//             ),
//             SizedBox(height: getProportionateScreenHeight(kDefaultPadding)),
//             TextField(
//               style: TextStyle(color: kBlackColor),
//               keyboardType: TextInputType.number,
//               maxLength: 4,
//               controller: controller,
//               onChanged: (val) {
//                 setState(() {
//                   hasError = false;
//                 });
//               },
//               decoration: textFieldInputDecorator.copyWith(labelText: "Code"),
//             ),
//             Visibility(
//               child: Text(
//                 "INCORRECT! Please try again.",
//                 style: TextStyle(color: kSecondaryColor),
//               ),
//               visible: hasError,
//             ),
//             SizedBox(height: kDefaultPadding),
//             Wrap(
//               alignment: WrapAlignment.spaceEvenly,
//               children: <Widget>[
//                 if (!kIsWeb)
//                   MaterialButton(
//                     color: kBlackColor,
//                     textColor: kPrimaryColor,
//                     child: Text("Verify"),
//                     onPressed: () {
//                       if (controller.text == code) {
//                         if(widget.login){

//                         } else {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => UpdatePasswordScreen(
//                                 phone: phone!,
//                               ),
//                             ),
//                           );
//                         }

//                       } else {
//                         setState(() {
//                           this.hasError = true;
//                         });
//                       }
//                     },
//                   ),
//                 SizedBox(
//                   width: kDefaultPadding,
//                 ),
//                 MaterialButton(
//                   color: kSecondaryColor,
//                   textColor: kPrimaryColor,
//                   child: Text("Erase"),
//                   onPressed: () {
//                     controller.clear();
//                     setState(() {
//                       this.hasError = false;
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_back_button.dart';
import 'update_password.dart';

class VerificationScreen extends StatefulWidget {
  static String id = '/verification';
  VerificationScreen(
      {required this.code,
      required this.phone,
      this.login = false,
      required this.areaCode});
  final String code;
  final String phone;
  final String areaCode;
  final bool login;

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<bool> _fieldFilled = List.generate(6, (_) => false);

  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Offset> _shakeAnimation;
  String message = '';
  bool _isError = false;
  String errorMessage = '';
  String? code;
  String? phone;

  @override
  void initState() {
    super.initState();
    phone = widget.phone;
    code = widget.code;
    message = widget.areaCode == "+251"
        ? "phone ${widget.areaCode + widget.phone}"
        : "email";
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

  // Function to verify OTP
  void _verifyOTP() {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      if (otp == code) {
        // Show successful animation
        setState(() {
          _isError = false;
        });

        _animationController.forward().then((_) {
          _animationController.reverse();

          // Navigate after animation completes
          if (widget.login) {
            // Handle login case
          } else {
            // debugPrint('OTP Entered: $otp');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UpdatePasswordScreen(
                  phone: phone!,
                ),
              ),
            );
          }
        });
      } else {
        // Show error animation
        setState(() {
          _isError = true;
          errorMessage = "INCORRECT! Please enter the correct code.";
        });

        // Vibrate phone if available
        HapticFeedback.mediumImpact();

        // Run shake animation
        _animationController.reset();
        _animationController.forward();
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Code"),
        leading: CustomBackButton(),
      ),
      body: SafeArea(
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
                  const Text(
                    'Enter OTP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "An OTP (verification code) has been sent to your $message.",
                    // "An OTP (verification code) has been sent to your phone ${widget.areaCode + widget.phone}.",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
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
                                              kGreyColor.withValues(alpha: 0.4)
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
                                              kGreyColor.withValues(alpha: 0.4)
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
                                  _verifyOTP();
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
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontWeight:
                          _isError ? FontWeight.bold : FontWeight.normal,
                    ),
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
                          _verifyOTP();
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
}
