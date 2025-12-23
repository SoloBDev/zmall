import 'dart:async';
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/services/core_services.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/forgot_password/forgot_password_screen.dart';
import 'package:zmall/login/otp_screen.dart';
import 'package:zmall/models/language.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/services/service.dart';
import 'package:zmall/services/biometric_services/biometric_service.dart';
import 'package:zmall/services/biometric_services/biometric_credentials_manager.dart';
import 'package:zmall/models/biometric_credential.dart';
import 'package:zmall/login/components/saved_accounts_bottom_sheet.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/utils/tab_screen.dart';
import 'package:http/http.dart' as http;
import 'package:zmall/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = "/login";

  const LoginScreen({super.key, this.firstRoute = true});

  final bool firstRoute;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String phoneNumber = "";
  String password = "";
  bool _isLoading = false;
  var responseData;
  late double longitude, latitude;
  bool _loading = false;
  var categories;
  var categoriesResponse;
  var isAbroad = false;
  // String setUrl = testURL;
  String areaCode = "+251";
  String phoneMessage = "Start phone with 9 or 7";
  String country = "Ethiopia";
  var countries = ['Ethiopia', 'South Sudan'];
  final _formKey = GlobalKey<FormState>();
  final List<String> errors = [];
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Text editing controllers for auto-fill
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LocationPermission _permissionStatus = LocationPermission.denied;

  // Biometric authentication variables
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _showBiometricButton = false;

  // Multi-account variables
  List<BiometricCredential> _savedAccounts = [];
  BiometricCredential? _selectedAccount;
  int _savedAccountsCount = 0;

  void _requestLocationPermission() async {
    _permissionStatus = await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.always ||
        _permissionStatus == LocationPermission.whileInUse) {
      // Location permission granted, continue with location-related tasks
      getLocation();
    } else {
      // Handle permission denial

      Service.showMessage(
        context: context,
        title: "Location permission denied. Please enable and try again",
        error: true,
      );
      FlLocation.requestLocationPermission();
    }
  }

  void getLocation() async {
    var currentLocation = await FlLocation.getLocation();
    if (mounted) {
      setState(() {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
      });
      Provider.of<ZMetaData>(
        context,
        listen: false,
      ).setLocation(currentLocation.latitude, currentLocation.longitude);
    }
  }

  void _doLocationTask() async {
    LocationPermission _permissionStatus =
        await FlLocation.checkLocationPermission();
    if (_permissionStatus == LocationPermission.whileInUse ||
        _permissionStatus == LocationPermission.always) {
      if (await FlLocation.isLocationServicesEnabled) {
        getLocation();
      } else {
        LocationPermission serviceStatus =
            await FlLocation.requestLocationPermission();
        if (serviceStatus == LocationPermission.always ||
            serviceStatus == LocationPermission.whileInUse) {
          getLocation();
        } else {
          Service.showMessage(
            context: context,
            title: "Location service disabled. Please enable and try again",
            error: true,
          );
        }
      }
    } else {
      _requestLocationPermission();
    }
  }

  @override
  void initState() {
    super.initState();
    // getVersion();
    _doLocationTask();
    getNearByMerchants();
    _checkBiometricAvailability();
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load saved accounts from storage
  Future<void> _loadSavedAccounts() async {
    // Migrate old single-account system to multi-account
    await _migrateOldCredentials();

    final accounts = await BiometricCredentialsManager.getSavedAccounts();

    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
        _savedAccountsCount = accounts.length;
        // Don't show biometric button by default - only when account is selected
      });
    }
  }

  /// Migrate old biometric credentials to multi-account system
  Future<void> _migrateOldCredentials() async {
    try {
      final oldPhone = await Service.getSavedPhone();
      final oldPassword = await Service.getSavedPassword();
      final oldEnabled = await Service.isBiometricEnabled();

      if (oldPhone != null && oldPassword != null) {
        // Check if this account already exists in new system
        final existingAccount = await BiometricCredentialsManager.getAccount(
          oldPhone,
        );

        if (existingAccount == null) {
          // Migrate to new system
          final credential = BiometricCredential(
            phone: oldPhone,
            password: oldPassword,
            biometricEnabled: oldEnabled,
            userName: null, // Will be updated on next login
            lastUsed: DateTime.now(),
          );

          await BiometricCredentialsManager.saveAccount(credential);

          // Clear old storage
          await Service.clearBiometricCredentials();
          await Service.disableBiometric();

          // print('Migrated old credentials to multi-account system');
        }
      }
    } catch (e) {
      // print('Error migrating old credentials: $e');
      // Don't block login if migration fails
    }
  }

  /// Check biometric availability and saved credentials
  void _checkBiometricAvailability() async {
    final isAvailable = await BiometricService.isBiometricAvailable();
    final isEnabled = await Service.isBiometricEnabled();
    final hasCredentials = await Service.hasBiometricCredentials();
    final biometricName = await BiometricService.getBiometricTypeName();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
        _biometricType = biometricName;
        // Don't show button by default - only show when specific account is selected
        _showBiometricButton = false;
      });

      // Auto-trigger biometric if enabled AND has credentials
      if (isAvailable && isEnabled && hasCredentials) {
        Future.delayed(Duration(milliseconds: 500), () {
          _authenticateWithBiometric();
        });
      }
    }
  }

  /// Handle biometric authentication
  Future<void> _authenticateWithBiometric() async {
    // Priority 1: Check if user selected an account from multi-account system
    if (_selectedAccount != null && _selectedAccount!.biometricEnabled) {
      final result = await BiometricService.authenticate(
        localizedReason:
            'Authenticate to login as ${_selectedAccount!.displayName}',
      );

      if (result.success) {
        setState(() {
          _isLoading = true;
          phoneNumber = _selectedAccount!.phone;
          password = _selectedAccount!.password;
        });

        try {
          var loginResponseData = await Service.biometricLogin(
            phoneNumber: _selectedAccount!.phone,
            password: _selectedAccount!.password,
            context: context,
            appVersion: appVersion,
          );

          if (loginResponseData != null && loginResponseData['success']) {
            if (loginResponseData['user']['is_approved']) {
              await Service.save('user', loginResponseData);
              await Service.saveBool('logged', true);

              _fcm.subscribeToTopic(
                Provider.of<ZMetaData>(
                  context,
                  listen: false,
                ).country.replaceAll(' ', ''),
              );

              if (mounted) {
                Service.showMessage(
                  context: context,
                  title: "Biometric login successful!",
                  error: false,
                );

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  TabScreen.routeName,
                  (Route<dynamic> route) => false,
                );
              }
            } else {
              if (mounted) {
                Service.showMessage(
                  context: context,
                  title: "Account not approved",
                  error: true,
                );
              }
            }
          } else {
            if (mounted) {
              Service.showMessage(
                context: context,
                title: loginResponseData != null
                    ? (errorCodes['${loginResponseData['error_code']}'] ??
                          "Login failed")
                    : "Login failed. Please try manual login.",
                error: true,
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Service.showMessage(
              context: context,
              title: "Biometric login failed. Please try again.",
              error: true,
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else if (result.errorMessage != null) {
        if (mounted) {
          Service.showMessage(
            context: context,
            title: result.errorMessage!,
            error: true,
          );
        }
      }
      return;
    }

    // Priority 2: Fall back to old single-account system (for backward compatibility)
    final isEnabled = await Service.isBiometricEnabled();
    final hasCredentials = await Service.hasBiometricCredentials();

    if (!hasCredentials) {
      // Credentials missing - could be after logout or corrupted state
      if (isEnabled) {
        // Invalid state: enabled but no credentials - auto-disable
        await Service.disableBiometric();

        if (mounted) {
          setState(() {
            _isBiometricEnabled = false;
          });

          Service.showMessage(
            context: context,
            title: "Biometric login was reset. Please login and re-enable it.",
            error: false,
          );
        }
      } else {
        // Never set up - show setup message
        if (mounted) {
          Service.showMessage(
            context: context,
            title:
                "Please login with phone and password first to enable biometric",
            error: false,
          );
        }
      }
      return;
    }

    final result = await BiometricService.authenticate(
      localizedReason: 'Authenticate to login to ZMall',
    );

    if (result.success) {
      // Get saved credentials
      final phone = await Service.getSavedPhone();
      final password = await Service.getSavedPassword();

      if (phone != null && password != null) {
        setState(() {
          phoneNumber = phone;
          this.password = password;
          _isLoading = true;
        });

        try {
          // Direct login without OTP
          var loginResponseData = await Service.biometricLogin(
            phoneNumber: phone,
            password: password,
            context: context,
            appVersion: appVersion,
          );

          if (loginResponseData != null && loginResponseData['success']) {
            if (loginResponseData['user']['is_approved']) {
              // Save user data and login status
              await Service.save('user', loginResponseData);
              await Service.saveBool('logged', true);

              // Subscribe to FCM topic
              _fcm.subscribeToTopic(
                Provider.of<ZMetaData>(
                  context,
                  listen: false,
                ).country.replaceAll(' ', ''),
              );

              if (mounted) {
                Service.showMessage(
                  context: context,
                  title: "Biometric login successful!",
                  error: false,
                );

                // Navigate to home screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  TabScreen.routeName,
                  (Route<dynamic> route) => false,
                );
              }
            } else {
              if (mounted) {
                Service.showMessage(
                  context: context,
                  title: "Account not approved",
                  error: true,
                );
              }
            }
          } else {
            if (mounted) {
              Service.showMessage(
                context: context,
                title: loginResponseData != null
                    ? (errorCodes['${loginResponseData['error_code']}'] ??
                          "Login failed")
                    : "Login failed. Please try manual login.",
                error: true,
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Service.showMessage(
              context: context,
              title: "Biometric login failed. Please try manual login.",
              error: true,
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } else if (result.errorMessage != null) {
      if (mounted) {
        Service.showMessage(
          context: context,
          title: result.errorMessage!,
          error: true,
        );
      }
    }
  }

  /// Show saved accounts bottom sheet
  Future<void> _showSavedAccountsSheet() async {
    await showSavedAccountsBottomSheet(
      context: context,
      onAccountSelected: _onAccountSelected,
    );
  }

  /// Handle account selection from saved accounts
  Future<void> _onAccountSelected(BiometricCredential account) async {
    // Extract only 9 digits (remove country code and non-digits)
    String phoneOnly = account.phone.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneOnly.length > 9) {
      phoneOnly = phoneOnly.substring(phoneOnly.length - 9);
    }

    final isAvailable = await BiometricService.isBiometricAvailable();

    setState(() {
      _selectedAccount = account;
      phoneNumber = account.phone;
      // Only fill phone number, not password (security)
      _phoneController.text = phoneOnly;
      // Show biometric button only if account has biometric enabled and device supports it
      _showBiometricButton = isAvailable && account.biometricEnabled;
    });

    // Update last used timestamp
    await BiometricCredentialsManager.updateLastUsed(account.phone);

    // If biometric enabled for this account, trigger authentication
    if (account.biometricEnabled) {
      final result = await BiometricService.authenticate(
        localizedReason: 'Authenticate to login as ${account.displayName}',
      );

      if (result.success) {
        // Biometric success - now fill password and login
        setState(() {
          _isLoading = true;
          password = account.password;
          _passwordController.text = account.password;
        });

        try {
          // Direct login without OTP
          var loginResponseData = await Service.biometricLogin(
            phoneNumber: account.phone,
            password: account.password,
            context: context,
            appVersion: appVersion,
          );

          if (loginResponseData != null && loginResponseData['success']) {
            if (loginResponseData['user']['is_approved']) {
              await Service.save('user', loginResponseData);
              await Service.saveBool('logged', true);

              _fcm.subscribeToTopic(
                Provider.of<ZMetaData>(
                  context,
                  listen: false,
                ).country.replaceAll(' ', ''),
              );

              Navigator.pushNamedAndRemoveUntil(
                context,
                TabScreen.routeName,
                (Route<dynamic> route) => false,
              );
            } else {
              Service.showMessage(
                context: context,
                title: "Your account is not approved yet.",
                error: true,
              );
            }
          } else {
            Service.showMessage(
              context: context,
              title: loginResponseData != null
                  ? (errorCodes['${loginResponseData['error_code']}'] ??
                        "Login failed")
                  : "Login failed. Please try manual login.",
              error: true,
            );
          }
        } catch (e) {
          Service.showMessage(
            context: context,
            title: "Login failed. Please try again.",
            error: true,
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      } else if (result.errorMessage != null) {
        Service.showMessage(
          context: context,
          title: result.errorMessage!,
          error: true,
        );
      }
    }
    // Note: If biometric is not enabled, credentials are auto-filled
    // User can see them and tap the login button
  }

  // void alert() async {
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         if (Platform.isIOS) {
  //           return showCupertinoDialog(
  //                 context: context,
  //                 builder: (_) => CupertinoAlertDialog(
  //                       title: Text("Welcome!"),
  //                       content: Text("Are you in Addis Ababa, Ethiopia?"),
  //                       actions: [
  //                         CupertinoButton(
  //                           child: Text('Yes'),
  //                           onPressed: () {
  //                             Navigator.of(context).pop();
  //                           },
  //                         ),
  //                         CupertinoButton(
  //                           child: Text('No'),
  //                           onPressed: () {
  //                             Navigator.pushNamedAndRemoveUntil(context,
  //                                 "/global", (Route<dynamic> route) => false);
  //                           },
  //                         )
  //                       ],
  //                     ));
  //         } else {
  //           return AlertDialog(
  //                 title: Text("Welcome!"),
  //                 content: Text("Are you in Addis Ababa?"),
  //                 actions: [
  //                   TextButton(
  //                       onPressed: () {
  //                         Navigator.of(context).pop();
  //                       },
  //                       child: Text("Yes")),
  //                   TextButton(
  //                       onPressed: () {
  //                         Navigator.pushNamedAndRemoveUntil(context, "/global",
  //                             (Route<dynamic> route) => false);
  //                       },
  //                       child: Text("No")),
  //                 ],
  //               );
  //         }
  //       });
  // }

  // void getVersion() async {
  //   // var data = await Service.read('version');
  //   if (data != null) {
  //     setState(() {
  //       appVersion = appVersion;
  //       debugPrint("App Version: $appVersion");
  //     });
  //   }
  // }

  // void addError({required String error}) {
  //   if (!errors.contains(error))
  //     setState(() {
  //       errors.add(error);
  //     });
  // }

  // void removeError({required String error}) {
  //   if (errors.contains(error))
  //     setState(() {
  //       errors.remove(error);
  //     });
  // }

  void getNearByMerchants() async {
    // _doLocationTask();
    categoriesResponse = await CoreServices.getCategoryList(
      longitude: Provider.of<ZMetaData>(context, listen: false).longitude,
      latitude: Provider.of<ZMetaData>(context, listen: false).latitude,
      countryCode: "5b3f76f2022985030cd3a437",
      countryName: "Ethiopia",
      context: context,
    );
    if (categoriesResponse != null && categoriesResponse['success']) {
      categories = categoriesResponse['deliveries'];
      Service.saveBool('is_global', false);
    } else {
      if (categoriesResponse != null &&
          categoriesResponse['error_code'] == 999) {
        await CoreServices.clearCache();

        Service.showMessage(
          context: context,
          title: "${errorCodes['${categoriesResponse['error_code']}']}",
          error: true,
        );
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      } else if (categoriesResponse != null &&
          categoriesResponse['error_code'] == 813) {
        // debugPrint("Not in Addis Ababa");
        Provider.of<ZMetaData>(
          context,
          listen: false,
        ).changeCountrySettings('South Sudan');

        // showCupertinoDialog(
        //     context: context,
        //     builder: (_) => CupertinoAlertDialog(
        //           title: Text("ZMall Global!"),
        //           content: Text(
        //               "We have detected that your location is not in Addis Ababa. Please proceed to ZMall Global!"),
        //           actions: [
        //             CupertinoButton(
        //               child: Text('Continue'),
        //               onPressed: () {
        //                 Service.saveBool('is_global', true);
        //                 Navigator.pushNamedAndRemoveUntil(context, "/global",
        //                     (Route<dynamic> route) => false);
        //               },
        //             )
        //           ],
        //         ));
      }
      // else {
      // debugPrint("${errorCodes['${categoriesResponse['error_code']}']}");
      // ScaffoldMessenger.of(context).showSnackBar(Service.showMessage1(
      //     "${errorCodes['${categoriesResponse['error_code']}']}", true));
      // }
    }
  }

  //  body: Padding(
  //           padding: EdgeInsets.symmetric(
  //             horizontal: getProportionateScreenWidth(kDefaultPadding),
  //           ),
  //           child: Center(
  //             child: SingleChildScrollView(
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(
  //                     horizontal: kDefaultPadding, vertical: kDefaultPadding * 2),
  //                 decoration: BoxDecoration(
  //                   color: kPrimaryColor,
  //                   borderRadius: BorderRadius.circular(kDefaultPadding),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withValues(alpha: 0.1),
  //                       spreadRadius: 1,
  //                       blurRadius: 3,
  //                       offset: const Offset(0, 2),
  //                     ),
  //                   ],
  //                 ),
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        bottomNavigationBar: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Provider.of<ZLanguage>(context).noAccount,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  Provider.of<ZLanguage>(context).register,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                    // decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(kDefaultPadding * 2),
              ),
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ////header///
                      Center(
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: getProportionateScreenWidth(
                                kDefaultPadding * 5,
                              ),
                              height: getProportionateScreenHeight(
                                kDefaultPadding * 5,
                              ),
                              margin: EdgeInsets.only(top: kDefaultPadding * 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // boxShadow: [kDefaultShadow],
                                image: DecorationImage(
                                  image: AssetImage(zmallLogo),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: getProportionateScreenHeight(
                                kDefaultPadding,
                              ),
                            ),
                            Text(
                              Provider.of<ZLanguage>(context).welcome,
                              // "ZMall Delivery"
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                              // headingStyle,
                            ),
                            Text(
                              "Delivery Done Right!",
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(color: kGreyColor),
                              // headingStyle,
                            ),
                          ],
                        ),
                      ),

                      /////form filds//
                      SizedBox(height: SizeConfig.screenHeight! * 0.05),
                      buildPhoneNumberFormField(),
                      SizedBox(height: kDefaultPadding / 1.2),
                      buildPasswordFormField(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              ForgotPassword.routeName,
                            );
                          },
                          child: Text(
                            "${Provider.of<ZLanguage>(context).forgotPassword}?",
                            style: TextStyle(
                              color: kBlackColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: kDefaultPadding * 1.5),
                      ////////////login and saved accounts buttons////
                      CustomButton(
                        isLoading: _isLoading,
                        title: Provider.of<ZLanguage>(context).login,
                        child: Text(
                          Provider.of<ZLanguage>(
                            context,
                          ).login.toString().toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                wordSpacing: 3,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        press: () => loginButtonPressed(),
                        color: kSecondaryColor,
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(
                          kDefaultPadding / 4,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Biometric Login Button
                          if (_showBiometricButton)
                            InkWell(
                              onTap: _authenticateWithBiometric,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getProportionateScreenWidth(
                                    kDefaultPadding,
                                  ),
                                ),
                                child: Icon(
                                  size: getProportionateScreenWidth(30),
                                  Icons.fingerprint,
                                  // HeroiconsOutline.fingerPrint,
                                  color: kBlackColor,
                                ),
                              ),
                            ),
                          Spacer(),
                          // Saved Accounts button
                          if (_savedAccountsCount > 0)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton(
                                onPressed: _showSavedAccountsSheet,
                                child: Text(
                                  "Switch Account",
                                  style: TextStyle(
                                    color: kBlackColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(
                        height: getProportionateScreenHeight(
                          kDefaultPadding * 2,
                          //  _savedAccountsCount > 0
                          //     ? kDefaultPadding
                          //     :
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: kGreyColor.withValues(alpha: 0.5),
                              thickness: 1,
                              endIndent: 10,
                            ),
                          ),
                          Text(
                            "Continue with",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: kGreyColor,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: kGreyColor.withValues(alpha: 0.5),
                              thickness: 1,
                              indent: 10,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          vertical: getProportionateScreenHeight(
                            kDefaultPadding / 2,
                          ),
                          horizontal: getProportionateScreenWidth(
                            kDefaultPadding,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(kDefaultPadding),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TabScreen(isLaunched: true),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                            children: [
                              Icon(HeroiconsOutline.user),
                              Text(
                                "Continue as a Guest",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kBlackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: getProportionateScreenHeight(kDefaultPadding),
                      ),
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          vertical: getProportionateScreenHeight(
                            kDefaultPadding / 2,
                          ),
                          horizontal: getProportionateScreenWidth(
                            kDefaultPadding,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(kDefaultPadding),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              "/global",
                              (Route<dynamic> route) => false,
                            );
                            //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                            Provider.of<ZMetaData>(
                              context,
                              listen: false,
                            ).changeCountrySettings("Ethiopia");
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: getProportionateScreenWidth(
                              kDefaultPadding,
                            ),
                            children: [
                              Icon(HeroiconsOutline.globeEuropeAfrica),
                              Text(
                                // "ZMall Global",
                                Provider.of<ZLanguage>(context).zGlobal,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kBlackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   spacing: getProportionateScreenWidth(kDefaultPadding),
                      //   children: [
                      //     Flexible(
                      //       child: Container(
                      //         height: 50,
                      //         alignment: Alignment.center,
                      //         padding: EdgeInsets.symmetric(
                      //             vertical: getProportionateScreenHeight(
                      //                 kDefaultPadding / 2),
                      //             horizontal: getProportionateScreenWidth(
                      //                 kDefaultPadding)),
                      //         decoration: BoxDecoration(
                      //             color: kWhiteColor,
                      //             borderRadius:
                      //                 BorderRadius.circular(kDefaultPadding)),
                      //         child: InkWell(
                      //           onTap: () {
                      //             Navigator.pushReplacement(
                      //               context,
                      //               MaterialPageRoute(
                      //                 builder: (context) =>
                      //                     TabScreen(isLaunched: true),
                      //               ),
                      //             );
                      //           },
                      //           child: Row(
                      //             mainAxisAlignment: MainAxisAlignment.center,
                      //             spacing: getProportionateScreenWidth(
                      //                 kDefaultPadding),
                      //             children: [
                      //               Icon(HeroiconsOutline.user),
                      //               Text(
                      //                 "Guest",
                      //                 style: TextStyle(
                      //                   fontWeight: FontWeight.bold,
                      //                   color: kBlackColor,
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //     Flexible(
                      //       child: Container(
                      //         height: 50,
                      //         alignment: Alignment.center,
                      //         padding: EdgeInsets.symmetric(
                      //             vertical: getProportionateScreenHeight(
                      //                 kDefaultPadding / 2),
                      //             horizontal: getProportionateScreenWidth(
                      //                 kDefaultPadding)),
                      //         decoration: BoxDecoration(
                      //             color: kWhiteColor,
                      //             borderRadius:
                      //                 BorderRadius.circular(kDefaultPadding)),
                      //         child: InkWell(
                      //           onTap: () {
                      //             Navigator.pushNamedAndRemoveUntil(
                      //               context,
                      //               "/global",
                      //               (Route<dynamic> route) => false,
                      //             );
                      //             //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                      //             Provider.of<ZMetaData>(
                      //               context,
                      //               listen: false,
                      //             ).changeCountrySettings("Ethiopia");
                      //           },
                      //           child: Row(
                      //             mainAxisAlignment: MainAxisAlignment.center,
                      //             spacing: getProportionateScreenWidth(
                      //                 kDefaultPadding),
                      //             children: [
                      //               Icon(HeroiconsOutline.globeEuropeAfrica),
                      //               Text(
                      //                 "ZMall Global",
                      //                 // Provider.of<ZLanguage>(context).zGlobal,
                      //                 style: TextStyle(
                      //                   fontWeight: FontWeight.bold,
                      //                   color: kBlackColor,
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      //     ),

                      //     // TextButton(
                      //     //   onPressed: () {
                      //     //     Navigator.pushReplacement(
                      //     //       context,
                      //     //       MaterialPageRoute(
                      //     //         builder: (context) =>
                      //     //             TabScreen(isLaunched: true),
                      //     //       ),
                      //     //     );
                      //     //   },
                      //     //   child: Text(
                      //     //     "Continue as a Guest",
                      //     //     style: TextStyle(
                      //     //       color: kSecondaryColor,
                      //     //       fontWeight: FontWeight.bold,
                      //     //     ),
                      //     //   ),
                      //     // ),
                      //     // TextButton(
                      //     //   onPressed: () {
                      //     //     Navigator.pushNamedAndRemoveUntil(
                      //     //       context,
                      //     //       "/global",
                      //     //       (Route<dynamic> route) => false,
                      //     //     );
                      //     //     //TODO: the next line change the country to Ethiopia for global screen because when the user selects country to South Sudan at CountryDropDown section it changes the base url to South Sudan which results mismatch in Global screen
                      //     //     Provider.of<ZMetaData>(
                      //     //       context,
                      //     //       listen: false,
                      //     //     ).changeCountrySettings("Ethiopia");
                      //     //   },
                      //     //   child: Text(
                      //     //     Provider.of<ZLanguage>(context).zGlobal,
                      //     //     style: TextStyle(
                      //     //       fontWeight: FontWeight.bold,
                      //     //       // decoration: TextDecoration.underline,
                      //     //     ),
                      //     //   ),
                      //     // ),
                      //   ],
                      // ),
                      // SizedBox(
                      //   height: getProportionateScreenHeight(kDefaultPadding),
                      // ),
                      // Spacer(),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     Text(Provider.of<ZLanguage>(context).noAccount),
                      //     TextButton(
                      //       onPressed: () {
                      //         Navigator.pushNamed(context, '/register');
                      //       },
                      //       child: Text(
                      //         Provider.of<ZLanguage>(context).register,
                      //         style: TextStyle(
                      //           fontWeight: FontWeight.bold,
                      //           color: kSecondaryColor,
                      //           decoration: TextDecoration.underline,
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //////
  void loginButtonPressed() {
    setState(() {
      _isLoading = true;
    });
    try {
      Service.isConnected(context).then((connected) async {
        if (_formKey.currentState!.validate()) {
          if (connected) {
            // Navigator.of(context).push(MaterialPageRoute(
            //     builder: (context) => OtpScreen(
            //         password: password,
            //         phone: phoneNumber,
            //         areaCode: areaCode)));
            // await login(phoneNumber, password);
            bool isGeneratOtp = await generateOtpAtLogin(
              phone: phoneNumber,
              password: password,
            );
            // print("before otp auth $isGeneratOtp");
            if (isGeneratOtp) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OtpScreen(
                    password: password,
                    phone: phoneNumber,
                    areaCode: areaCode,
                  ),
                ),
              );
              // print("after otp auth");
            }
          } else {
            Service.showMessage(
              context: context,
              title:
                  "No internet connection. Check your network and try again.",
              error: true,
            );
          }
        }
      });
    } catch (e) {
      Service.showMessage(
        context: context,
        title: "Connection unavailable. Check your internet and try again.",
        // "Please check your internet connection",
        error: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  ////////////////otp authentication/////

  Future<dynamic> generateOtpAtLogin({
    required String phone,
    required String password,
  }) async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/user/generate_otp_at_login";
    setState(() {
      _isLoading = true;
    });
    try {
      Map data = {"phone": phone, "password": password};
      var body = json.encode(data);
      // debugPrint("body??? $body}");
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
      // debugPrint("otp??? ${json.decode(response.body)}");
      // return json.decode(response.body);
      var newResponse = json.decode(response.body);
      if (newResponse != null &&
          (newResponse["success"] != null && newResponse["success"])) {
        return true;
      } else {
        Service.showMessage(
          context: context,
          title:
              "Failed to send an OTP. Please check your phone and password and try again.",
          error: true,
        );
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

  ///
  ///////////////////////////////////////

  // TextFormField
  Widget buildPhoneNumberFormField() {
    return CustomTextField(
      controller: _phoneController,
      keyboardType: TextInputType.number,
      maxLength: 9,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _PhoneNumberFormatter(),
      ],
      onSaved: (newValue) => phoneNumber = newValue!,
      onChanged: (value) {
        setState(() {
          phoneNumber = value;
        });
        return null;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        if (!RegExp(r'^[97][0-9]{8}$').hasMatch(value)) {
          return 'Phone number must be 9 digits and start with 9 or 7';
        }
        return null; // Return null if validation passes
      },
      hintText: "$areaCode...",
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isPhoneWithFlag: true,
      initialSelection:
          Provider.of<ZMetaData>(context, listen: false).areaCode == "+251"
          ? 'ET'
          : 'SS',
      countryFilter: ['ET', 'SS'],
      onFlagChanged: (CountryCode code) {
        setState(() {
          if (code.toString() == "+251") {
            areaCode = "+251";
            country = "Ethiopia";
          } else {
            areaCode = "+211";
            country = "South Sudan";
          }
          Provider.of<ZMetaData>(
            context,
            listen: false,
          ).changeCountrySettings(country);
        });
      },
    );
  }

  bool _showPassword = false;
  Widget buildPasswordFormField() {
    return CustomTextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      onSaved: (newValue) => password = newValue!,
      keyboardType: TextInputType.visiblePassword,
      onChanged: (value) {
        password = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 8) {
          return "Password is too short";
        }
        return null; // Return null if validation passes
      },
      hintText: " Enter your password",
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _showPassword = !_showPassword;
          });
        },
        icon: Icon(
          _showPassword ? HeroiconsOutline.eyeSlash : HeroiconsOutline.eye,
        ),
      ),
    );
  }
}

/// Custom formatter to extract last 9 digits from phone numbers
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // If more than 9 digits (e.g., has country code), take last 9
    if (text.length > 9) {
      text = text.substring(text.length - 9);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// old country drop down
  // Widget buildCountryDropDown() {
  //   return DropdownButtonFormField(
  //     icon: Icon(Icons.brightness_1_outlined, color: kWhiteColor),
  //     items: countries.map((String country) {
  //       return new DropdownMenuItem(
  //         value: country,
  //         child: Row(children: <Widget>[Text(country)]),
  //       );
  //     }).toList(),
  //     onChanged: (newValue) {
  //       // do other stuff with _category
  //       Provider.of<ZMetaData>(
  //         context,
  //         listen: false,
  //       ).changeCountrySettings(newValue.toString());
  //       setState(() {
  //         country = newValue.toString();

  //         if (country == "Ethiopia") {
  //           phoneMessage = "Start phone number with 9 or 7...";
  //           areaCode = "+251";
  //         } else if (country == "South Sudan") {
  //           phoneMessage = "Start phone number with 9...";
  //           areaCode = "+211";
  //         }
  //       });
  //     },
  //     decoration: InputDecoration(
  //       labelText: Provider.of<ZLanguage>(context).country,
  //       hintText: "Choose your country",
  //       // If  you are using latest version of flutter then lable text and hint text shown like this
  //       // if you r using flutter less then 1.20.* then maybe this is not working properly
  //       floatingLabelBehavior: FloatingLabelBehavior.always,
  //       suffixIcon: CustomSuffixIcon(
  //         iconData: Icons.arrow_drop_down_circle_sharp,
  //       ),
  //     ),
  //     initialValue: Provider.of<ZMetaData>(context, listen: false).country,
  //   );
  // }
