# ZMall Registration Flow - Code-Level Analysis

**Purpose**: This document provides a detailed, code-level explanation of ZMall's user registration system including the exact registration flow, validation rules, API integration, and business logic.

**Target Audience**: Developers who need to understand the registration implementation details.

**File Location**: `/Users/apple/Documents/ZMall-Projects/zmall/lib/register/register_screen.dart`

---

## Table of Contents

1. [Registration Flow Overview](#registration-flow-overview)
2. [Form Structure & State Management](#form-structure--state-management)
3. [Form Fields & Validation Rules](#form-fields--validation-rules)
4. [Country Selection Logic](#country-selection-logic)
5. [Registration Submission Process](#registration-submission-process)
6. [API Integration](#api-integration)
7. [Success & Error Handling](#success--error-handling)
8. [Testing Checklist](#testing-checklist)

---

## Registration Flow Overview

### High-Level Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Registration Screen                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  SECTION 1: User Info                                        │
│  ├─ First Name (required)                                    │
│  └─ Last Name (required)                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  SECTION 2: Contact Info                                     │
│  ├─ Email (required, validated)                              │
│  └─ Phone Number (9 digits, must start with 9)              │
│      └─ Country Code Picker (Ethiopia +251 / S.Sudan +211) │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  SECTION 3: Security                                         │
│  ├─ Password (min 8 chars, mixed case, number, special)     │
│  ├─ Confirm Password (must match)                           │
│  └─ Terms & Conditions Checkbox (required)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Form Validation (all fields)                    │
│              Terms & Conditions checked?                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                        ┌─────┴──────┐
                        │  Valid?    │
                        └─────┬──────┘
                              │
                 ┌────────────┴────────────┐
                 │                         │
                NO                        YES
                 │                         │
                 ▼                         ▼
       ┌─────────────────┐      ┌──────────────────┐
       │  Show Validation│      │  Call register() │
       │  Error Messages │      │   API Function   │
       └─────────────────┘      └──────────────────┘
                                          │
                                          ▼
                              ┌───────────────────────┐
                              │ POST /api/user/register│
                              └───────────────────────┘
                                          │
                              ┌───────────┴──────────┐
                              │                      │
                           SUCCESS               FAILURE
                              │                      │
                              ▼                      ▼
                  ┌────────────────────┐   ┌──────────────────┐
                  │ Log Analytics      │   │ Check error_code │
                  │ Show Success Msg   │   │ 501: Reg failed  │
                  │ Navigate to Login  │   │ 502: Email exists│
                  └────────────────────┘   │ 503: Phone exists│
                                           └──────────────────┘
                                                     │
                                                     ▼
                                           ┌──────────────────┐
                                           │ If 503: Navigate │
                                           │ to Login Screen  │
                                           │ Else: Show Error │
                                           └──────────────────┘
```

### Key Design Decisions

1. **No OTP Verification**: Current implementation sets `is_phone_number_verified: true` automatically
   - OTP verification was removed to simplify registration process

2. **Country-Based Configuration**: The app changes base URL, validation rules, and default city based on country selection

3. **Terms & Conditions**: Required checkbox that opens web view to https://app.zmallshop.com/terms.html

4. **Referral Code**: Field exists in state but hardcoded to `"referralCode"` in API call (line 537)

---

## Form Structure & State Management

### State Variables (lines 28-52)

```dart
class _RegisterScreenState extends State<RegisterScreen> {
  // Form controller
  final _formKey = GlobalKey<FormState>();
  ScrollController scrollController = ScrollController();

  // User input fields
  String firstName = "";
  String lastName = "";
  String email = "";
  String password = "";
  String confirmPassword = "";
  String phoneNumber = "";
  String referralCode = "";

  // Country/location settings
  String country = "Ethiopia";           // Default country
  String city = "Addis Ababa";          // Default city
  String address = "";                  // Auto-generated based on areaCode
  String setUrl = BASE_URL;             // API base URL
  String areaCode = "+251";             // Country phone code
  String phoneMessage = "Start phone with 9 or 7";  // Validation hint

  // UI state
  bool termsAndConditions = false;
  bool _loading = false;
  bool _isSelected = false;             // Terms checkbox state
  bool _isCollapsed = false;            // App bar collapse state
  bool _showPassword = false;           // Password visibility toggle
  bool _showConfirmPassword = false;    // Confirm password visibility toggle

  // Response handling
  var responseData;
  var appVersion;

  // Constants
  var countries = ['Ethiopia', 'South Sudan'];
  var cities = ["Addis Ababa"];
}
```

### Form Layout Structure (lines 179-317)

The form is divided into **3 main sections**:

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      // SECTION 1: User Info
      Column(
        children: [
          Text("User Info"),
          buildFirstNameFormField(),
          buildLastNameFormField(),
        ],
      ),

      // SECTION 2: Contact Info
      Column(
        children: [
          Text("Contact Info"),
          buildEmailFormField(),
          buildPhoneNumberFormField(),  // Includes country picker
        ],
      ),

      // SECTION 3: Security
      Column(
        children: [
          Text("Security"),
          buildPasswordFormField(),
          buildConformPassFormField(),

          // Terms & Conditions Checkbox
          Row(
            children: [
              Checkbox.adaptive(
                value: _isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    _isSelected = value ?? false;
                  });
                },
              ),
              Column(
                children: [
                  Text("By continuing your confirm that you agree with our"),
                  InkWell(
                    onTap: () {
                      Service.launchInWebViewOrVC(
                        "https://app.zmallshop.com/terms.html"
                      );
                    },
                    child: Text("Terms & Conditions"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Submit Button
      CustomButton(
        title: "Complete",
        color: _isSelected ? kSecondaryColor : kSecondaryColor.withOpacity(0.7),
        press: !_isSelected
          ? () {}  // Disabled if terms not checked
          : () {
              if (_formKey.currentState!.validate() && _isSelected) {
                _formKey.currentState!.save();
                _register();  // Submit registration
              }
            },
      ),
    ],
  ),
)
```

---

## Form Fields & Validation Rules

### 1. First Name Field (lines 321-340)

**Widget Code:**
```dart
Widget buildFirstNameFormField() {
  return CustomTextField(
    onSaved: (newValue) => firstName = newValue!,
    onChanged: (value) {
      firstName = value;
      return null;
    },
    validator: (value) {
      if (value!.isEmpty) {
        return kNameNullError;  // "Please Enter your name"
      }
      return null;
    },
    hintText: "Enter your first name",
    prefixIcon: CustomSuffixIcon(
      iconData: HeroiconsOutline.user,
    ),
  );
}
```

**Validation Rules:**
- ✅ Required field
- ✅ Must not be empty

**Error Message:**
- `kNameNullError` = `"Please Enter your name"`

---

### 2. Last Name Field (lines 342-359)

**Widget Code:**
```dart
Widget buildLastNameFormField() {
  return CustomTextField(
    onSaved: (newValue) => lastName = newValue!,
    onChanged: (value) => lastName = value,
    hintText: "Enter your last name",
    validator: (value) {
      if (value!.isEmpty) {
        return kNameLastNullError;  // "Please Enter your last name"
      }
      return null;
    },
    prefixIcon: CustomSuffixIcon(
      iconData: HeroiconsOutline.user,
    ),
  );
}
```

**Validation Rules:**
- ✅ Required field
- ✅ Must not be empty

**Error Message:**
- `kNameLastNullError` = `"Please Enter your last name"`

---

### 3. Email Field (lines 426-449)

**Widget Code:**
```dart
Widget buildEmailFormField() {
  return CustomTextField(
    keyboardType: TextInputType.emailAddress,
    onSaved: (newValue) => email = newValue!,
    onChanged: (value) {
      email = value;
    },
    validator: (value) {
      if (value!.isEmpty) {
        return kEmailNullError;  // "Please Enter your email"
      } else if (!emailValidatorRegExp.hasMatch(value)) {
        return kInvalidEmailError;  // "Please Enter Valid Email"
      }
      return null;
    },
    hintText: "Enter your email",
    floatingLabelBehavior: FloatingLabelBehavior.always,
    prefixIcon: CustomSuffixIcon(
      iconData: HeroiconsOutline.envelope,
    ),
  );
}
```

**Validation Rules:**
- ✅ Required field
- ✅ Must match email regex pattern

**Email Regex (from constants.dart:144-146):**
```dart
final RegExp emailValidatorRegExp = RegExp(
  r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
);
```

**What this regex means:**
- Starts with alphanumeric characters and dots: `[a-zA-Z0-9.]+`
- Followed by `@` symbol
- Domain name (alphanumeric): `[a-zA-Z0-9]+`
- Followed by `.`
- Top-level domain (letters only): `[a-zA-Z]+`

**Examples:**
- ✅ Valid: `user@example.com`, `user.name@domain.co`, `test123@mail.org`
- ❌ Invalid: `user@domain`, `@example.com`, `user.example.com`

**Error Messages:**
- `kEmailNullError` = `"Please Enter your email"`
- `kInvalidEmailError` = `"Please Enter Valid Email"`

---

### 4. Phone Number Field with Country Picker (lines 362-424)

**Widget Code:**
```dart
Widget buildPhoneNumberFormField() {
  return CustomTextField(
    maxLength: 9,  // Exactly 9 digits
    keyboardType: TextInputType.number,
    onSaved: (newValue) => phoneNumber = newValue!,
    onChanged: (value) {
      if (value.isNotEmpty) {
        setState(() {
          phoneNumber = value;
        });
      }
      return null;
    },
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a phone number';
      }

      if (!phoneValidatorRegExp.hasMatch(value)) {
        return 'Phone number must be 9 digits and start with 9';
      }
      return null;
    },
    hintText: "Enter your phone",
    floatingLabelBehavior: FloatingLabelBehavior.always,
    isPhoneWithFlag: true,

    // Country code picker configuration
    initialSelection: Provider.of<ZMetaData>(context, listen: false).areaCode == "+251"
      ? 'ET'  // Ethiopia
      : 'SS', // South Sudan
    countryFilter: ['ET', 'SS'],  // Only allow Ethiopia and South Sudan

    onFlagChanged: (CountryCode code) {
      setState(() {
        if (code.toString() == "+251") {
          // Ethiopia selected
          setUrl = BASE_URL;
          country = "Ethiopia";
          areaCode = "+251";
          city = "Addis Ababa";
          phoneMessage = "Start phone number with 9 or 7...";
        } else {
          // South Sudan selected
          setUrl = BASE_URL_JUBA;
          country = "South Sudan";
          areaCode = "+211";
          city = "Juba";
          phoneMessage = "Start phone number with 9...";
        }

        // Update global metadata provider
        Provider.of<ZMetaData>(context, listen: false)
          .changeCountrySettings(country);
      });
    },
  );
}
```

**Phone Number Regex (from constants.dart:141):**
```dart
final RegExp phoneValidatorRegExp = RegExp(r'^[9][0-9]{8}$');
```

**Important Note**: The regex only allows numbers starting with `9`, but the commented code (line 143) shows it previously allowed `7` or `9`:
```dart
// Old regex: RegExp(r'^[97][0-9]{8}$');
```

**What the current regex means:**
- Must start with `9`: `^[9]`
- Followed by exactly 8 more digits: `[0-9]{8}$`
- Total: 9 digits starting with 9

**Validation Rules:**
- ✅ Required field
- ✅ Must be exactly 9 digits
- ✅ Must start with digit `9`
- ✅ Numeric characters only

**Examples:**
- ✅ Valid: `912345678`, `987654321`, `901234567`
- ❌ Invalid: `712345678` (starts with 7), `9123456` (too short), `91234567890` (too long)

**Full Phone Number Format:**
- Ethiopia: `+251` + `912345678` → `+251912345678`
- South Sudan: `+211` + `912345678` → `+211912345678`

---

### 5. Password Field (lines 454-485)

**Widget Code:**
```dart
bool _showPassword = false;  // State for visibility toggle

Widget buildPasswordFormField() {
  return CustomTextField(
    obscureText: !_showPassword,  // Hide/show password
    keyboardType: TextInputType.visiblePassword,
    onSaved: (newValue) => password = newValue!,
    onChanged: (value) {
      password = value;
    },
    validator: (value) {
      if (!passwordRegex.hasMatch(value!)) {
        return kPasswordErrorMessage;
      }
      return null;
    },
    hintText: "Enter your password",
    floatingLabelBehavior: FloatingLabelBehavior.always,

    // Eye icon to toggle visibility
    suffixIcon: IconButton(
      onPressed: () {
        setState(() {
          _showPassword = !_showPassword;
        });
      },
      icon: Icon(
        _showPassword ? HeroiconsOutline.eyeSlash : HeroiconsOutline.eye
      ),
    ),
    prefixIcon: CustomSuffixIcon(
      iconData: HeroiconsOutline.lockClosed,
    ),
  );
}
```

**Password Regex (from constants.dart:147-149):**
```dart
final RegExp passwordRegex = RegExp(
  r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
);
```

**Breaking Down the Regex:**

| Part | Meaning |
|------|---------|
| `^` | Start of string |
| `(?=.*[A-Z])` | **Positive lookahead**: Must contain at least 1 uppercase letter (A-Z) |
| `(?=.*[a-z])` | **Positive lookahead**: Must contain at least 1 lowercase letter (a-z) |
| `(?=.*\d)` | **Positive lookahead**: Must contain at least 1 digit (0-9) |
| `(?=.*[@$!%*?&])` | **Positive lookahead**: Must contain at least 1 special character from `@$!%*?&` |
| `[A-Za-z\d@$!%*?&]{8,}` | Must be 8+ characters long, using only allowed characters |
| `$` | End of string |

**Validation Rules:**
- ✅ Minimum 8 characters
- ✅ At least 1 uppercase letter (A-Z)
- ✅ At least 1 lowercase letter (a-z)
- ✅ At least 1 digit (0-9)
- ✅ At least 1 special character from: `@ $ ! % * ? &`
- ✅ Only allows: letters, digits, and `@$!%*?&`

**Error Message (from constants.dart:151-152):**
```dart
const String kPasswordErrorMessage =
    "Password must be at least 8 characters long, one uppercase letter, one lowercase letter, one number, and one special character (@, !, %, ?, &, $, *).";
```

**Examples:**
- ✅ Valid: `Password1!`, `MyPass123@`, `Secure&Pass9`
- ❌ Invalid:
  - `password1!` (no uppercase)
  - `PASSWORD1!` (no lowercase)
  - `Password!` (no digit)
  - `Password1` (no special character)
  - `Pass1!` (too short, less than 8 characters)
  - `Password1#` (# not allowed, only `@$!%*?&`)

---

### 6. Confirm Password Field (lines 487-521)

**Widget Code:**
```dart
bool _showConfirmPassword = false;  // State for visibility toggle

Widget buildConformPassFormField() {
  return CustomTextField(
    obscureText: !_showConfirmPassword,  // Hide/show password
    keyboardType: TextInputType.visiblePassword,
    onSaved: (newValue) => confirmPassword = newValue!,
    onChanged: (value) {
      confirmPassword = value;
    },
    validator: (value) {
      if (value!.isEmpty) {
        return kPassNullError;  // "Please Enter your password"
      } else if ((password != value)) {
        return kMatchPassError;  // "Passwords don't match"
      }
      return null;
    },
    hintText: "Confirm your password",
    floatingLabelBehavior: FloatingLabelBehavior.always,

    // Eye icon to toggle visibility
    suffixIcon: IconButton(
      onPressed: () {
        setState(() {
          _showConfirmPassword = !_showConfirmPassword;
        });
      },
      icon: Icon(
        _showConfirmPassword
          ? HeroiconsOutline.eyeSlash
          : HeroiconsOutline.eye
      ),
    ),
    prefixIcon: CustomSuffixIcon(
      iconData: HeroiconsOutline.lockClosed,
    ),
  );
}
```

**Validation Rules:**
- ✅ Required field (cannot be empty)
- ✅ Must exactly match the password field

**Error Messages:**
- `kPassNullError` = `"Please Enter your password"`
- `kMatchPassError` = `"Passwords don't match"`

---

### Validation Summary Table

| Field | Required | Min Length | Max Length | Pattern | Special Rules |
|-------|----------|------------|------------|---------|---------------|
| **First Name** | ✅ Yes | 1 | - | Any | Cannot be empty |
| **Last Name** | ✅ Yes | 1 | - | Any | Cannot be empty |
| **Email** | ✅ Yes | - | - | Email regex | Must match `name@domain.tld` |
| **Phone Number** | ✅ Yes | 9 | 9 | `^[9][0-9]{8}$` | Must start with 9, exactly 9 digits |
| **Password** | ✅ Yes | 8 | - | Complex regex | Must have uppercase, lowercase, digit, special char |
| **Confirm Password** | ✅ Yes | - | - | Must match password | Exact match with password field |
| **Terms Checkbox** | ✅ Yes | - | - | Boolean | Must be checked to enable submit |

---

## Country Selection Logic

### Country Configuration Map

When the user selects a country via the flag picker, the following values are updated:

| Setting | Ethiopia (ET) | South Sudan (SS) |
|---------|---------------|------------------|
| **Area Code** | `+251` | `+211` |
| **Country Name** | `"Ethiopia"` | `"South Sudan"` |
| **Default City** | `"Addis Ababa"` | `"Juba"` |
| **Base URL** | `BASE_URL` | `BASE_URL_JUBA` |
| **Phone Message** | `"Start phone number with 9 or 7..."` | `"Start phone number with 9..."` |
| **Country ISO** | `ET` | `SS` |

### Country Change Handler (lines 398-421)

```dart
onFlagChanged: (CountryCode code) {
  setState(() {
    if (code.toString() == "+251") {
      // ETHIOPIA CONFIGURATION
      setUrl = BASE_URL;                              // API endpoint
      country = "Ethiopia";                          // Country name
      areaCode = "+251";                             // Phone code
      city = "Addis Ababa";                          // Default city
      phoneMessage = "Start phone number with 9 or 7...";  // Hint text
    } else {
      // SOUTH SUDAN CONFIGURATION
      setUrl = BASE_URL_JUBA;                        // Different API endpoint
      country = "South Sudan";                       // Country name
      areaCode = "+211";                             // Phone code
      city = "Juba";                                 // Default city
      phoneMessage = "Start phone number with 9..."; // Different hint
    }

    // Update global provider state
    Provider.of<ZMetaData>(context, listen: false)
      .changeCountrySettings(country);
  });
}
```

### Impact of Country Selection

1. **API Base URL Changes**:
   - Ethiopia → Calls `BASE_URL/api/user/register`
   - South Sudan → Calls `BASE_URL_JUBA/api/user/register`

2. **Phone Validation Hint Changes**:
   - Ethiopia: Shows "Start phone number with 9 or 7..."
   - South Sudan: Shows "Start phone number with 9..."
   - **Note**: Despite the hint, the current regex only allows `9` (line 141)

3. **Default Address Changes** (set during `_register()` function at line 73-74):
   ```dart
   address = areaCode == "+251"
     ? "Addis Ababa, Ethiopia"
     : "Juba, South Sudan";
   ```

4. **Global State Updates**:
   - Updates `ZMetaData` provider with new country settings
   - This affects other parts of the app that depend on country configuration

---

## Registration Submission Process

### Submit Button Logic (lines 288-305)

```dart
CustomButton(
  title: "Complete",
  // Button color changes based on terms checkbox
  color: _isSelected
    ? kSecondaryColor                       // Full color if checked
    : kSecondaryColor.withValues(alpha: 0.7),  // Faded if unchecked

  // Button press handler
  press: !_isSelected
    ? () {}  // Do nothing if terms not checked
    : () {
        // Only proceed if form is valid AND terms are checked
        if (_formKey.currentState!.validate() && _isSelected) {
          _formKey.currentState!.save();  // Save all form field values
          _register();  // Call registration function
        }
      },
)
```

### Pre-Submit Checklist

Before `_register()` is called, the following must be true:

1. ✅ All form fields pass validation:
   - First name is not empty
   - Last name is not empty
   - Email matches regex pattern
   - Phone number is 9 digits starting with 9
   - Password meets complexity requirements
   - Confirm password matches password

2. ✅ Terms & Conditions checkbox is checked (`_isSelected == true`)

3. ✅ Form state is saved (`_formKey.currentState!.save()`)

---

### `_register()` Function Flow (lines 71-101)

```dart
Future<void> _register() async {
  // STEP 1: Set loading state and auto-generate address
  setState(() {
    // Auto-generate address based on selected country
    address = areaCode == "+251"
      ? "Addis Ababa, Ethiopia"   // Ethiopia
      : "Juba, South Sudan";      // South Sudan

    _loading = true;  // Show loading indicator
  });

  // STEP 2: Call the register() API function
  var data = await register();

  // STEP 3: Handle response
  if (data != null && data['success']) {
    // ✅ SUCCESS CASE

    // Show success message to user
    Service.showMessage(
      context: context,
      title: "Registration successful. Ready to login!",
      error: false,
      duration: 3,  // Show for 3 seconds
    );

    // Log analytics event
    await MyApp.analytics.logEvent(name: "user_registered");

    // Navigate to login screen, clearing navigation stack
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,   // "/login"
      (Route<dynamic> route) => false  // Remove all previous routes
    );

  } else {
    // ❌ FAILURE CASE

    setState(() {
      _loading = false;  // Stop loading indicator
    });

    // Show error message with error code description
    Service.showMessage(
      context: context,
      title: "${errorCodes['${data['error_code']}']}!",
      error: true
    );

    // SPECIAL CASE: Error 503 (phone already registered)
    if (data['error_code'] == 503) {
      // Phone number already registered, send user to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (Route<dynamic> route) => false
      );
    }
  }
}
```

### Registration Flow Diagram

```
┌─────────────────────────────────────────┐
│ User clicks "Complete" button           │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ Validate all form fields                │
│ Check terms checkbox is selected        │
└─────────────────────────────────────────┘
                  │
        ┌─────────┴──────────┐
        │                    │
    INVALID               VALID
        │                    │
        ▼                    ▼
┌────────────────┐   ┌──────────────────┐
│ Show validation│   │ Call _register() │
│ error messages │   └──────────────────┘
└────────────────┘            │
                              ▼
                   ┌─────────────────────┐
                   │ Set loading = true  │
                   │ Generate address    │
                   └─────────────────────┘
                              │
                              ▼
                   ┌─────────────────────┐
                   │ Call register()     │
                   │ (API function)      │
                   └─────────────────────┘
                              │
                              ▼
                   ┌─────────────────────┐
                   │ POST to server      │
                   │ Wait for response   │
                   └─────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
           SUCCESS (200)              FAILURE/ERROR
                │                           │
                ▼                           ▼
    ┌──────────────────────┐    ┌─────────────────────┐
    │ response.success==true│    │ response.success==false│
    └──────────────────────┘    └─────────────────────┘
                │                           │
                ▼                           ▼
    ┌──────────────────────┐    ┌─────────────────────┐
    │ Show success message │    │ Set loading = false │
    │ Log analytics event  │    │ Show error message  │
    │ Navigate to login    │    └─────────────────────┘
    │ (clear stack)        │                │
    └──────────────────────┘                │
                                            ▼
                                ┌───────────────────────┐
                                │ Check error_code      │
                                │ == 503?               │
                                └───────────────────────┘
                                            │
                                ┌───────────┴──────────┐
                                │                      │
                              YES (503)               NO
                                │                      │
                                ▼                      ▼
                    ┌──────────────────────┐  ┌──────────────┐
                    │ Phone already exists │  │ Stay on page │
                    │ Navigate to login    │  │ User can retry│
                    └──────────────────────┘  └──────────────┘
```

---

## API Integration

### API Endpoint

```
POST {setUrl}/api/user/register
```

Where `setUrl` is:
- **Ethiopia**: `BASE_URL` (e.g., `https://api.zmallshop.com`)
- **South Sudan**: `BASE_URL_JUBA` (e.g., `https://api.zmallshop.ss`)

### `register()` API Function (lines 525-570)

```dart
Future<dynamic> register() async {
  // Construct full URL
  var url = "$setUrl/api/user/register";

  // Build request payload
  Map data = {
    "country_id": Provider.of<ZMetaData>(context, listen: false).countryId,
    "email": email,
    "phone": phoneNumber,
    "first_name": firstName,
    "last_name": lastName,
    "password": password,
    "country_phone_code": Provider.of<ZMetaData>(context, listen: false).areaCode,
    "city": Provider.of<ZMetaData>(context, listen: false).cityId,
    "referral_code": "referralCode",  // ⚠️ HARDCODED, not from user input
    "address": address,
    "is_phone_number_verified": true,  // ⚠️ Always true (no OTP verification)
  };

  // Encode as JSON
  var body = json.encode(data);

  try {
    // Make POST request with 30-second timeout
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
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException("The connection has timed out!");
        },
      );

    // Parse and return response
    return json.decode(response.body);

  } catch (e) {
    // Handle errors (network issues, timeout, etc.)
    return null;
  } finally {
    // Always stop loading indicator
    setState(() {
      _loading = false;
    });
  }
}
```

### Request Payload Details

| Field | Type | Source | Example | Notes |
|-------|------|--------|---------|-------|
| `country_id` | String | `ZMetaData.countryId` | `"507f1f77bcf86cd799439011"` | MongoDB ObjectID from provider |
| `email` | String | Form input | `"user@example.com"` | Already validated |
| `phone` | String | Form input | `"912345678"` | Without country code, 9 digits |
| `first_name` | String | Form input | `"John"` | User's first name |
| `last_name` | String | Form input | `"Doe"` | User's last name |
| `password` | String | Form input | `"Password123!"` | Plain text (server should hash) |
| `country_phone_code` | String | `ZMetaData.areaCode` | `"+251"` or `"+211"` | From provider |
| `city` | String | `ZMetaData.cityId` | `"507f1f77bcf86cd799439012"` | MongoDB ObjectID from provider |
| `referral_code` | String | **Hardcoded** | `"referralCode"` | ⚠️ Always this exact string, not user input |
| `address` | String | Auto-generated | `"Addis Ababa, Ethiopia"` | Set in `_register()` function |
| `is_phone_number_verified` | Boolean | **Hardcoded** | `true` | ⚠️ Always true, no OTP flow |

### Important Notes

1. **Referral Code Issue**:
   - Line 537 hardcodes `"referral_code": "referralCode"`
   - User input from `referralCode` state variable is NOT used
   - This appears to be a bug

2. **Phone Verification Bypass**:
   - `is_phone_number_verified` is always `true`
   - No OTP verification happens (commented code at lines 726-827 shows it was removed)

3. **Provider Dependencies**:
   - `countryId`, `areaCode`, and `cityId` come from `ZMetaData` provider
   - Provider is updated when country flag is changed (line 416-419)

### Request Example

**Ethiopia User:**
```json
POST https://app.zmall.et/api/user/register
Content-Type: application/json

{
  "country_id": "5b3f76f2022985030cd3a437", // actual ID
  "email": "john.doe@example.com",
  "phone": "912345678",
  "first_name": "John",
  "last_name": "Doe",
  "password": "SecurePass123!",
  "country_phone_code": "+251",
  "city": "5b406b46d2ddf8062d11b788",// actual ID
  "referral_code": "referralCode",
  "address": "Addis Ababa, Ethiopia",
  "is_phone_number_verified": true
}
```

**South Sudan User:**
```json
POST https://juba.zmallapp.com/api/user/register
Content-Type: application/json

{
  "country_id": "62fef1d6ae93d51e87b468aa",// actual ID
  "email": "jane.smith@example.com",
  "phone": "923456789",
  "first_name": "Jane",
  "last_name": "Smith",
  "password": "MyPassword1@",
  "country_phone_code": "+211",
  "city": "62fef290ae93d51e87b468ab",// actual ID
  "referral_code": "referralCode",
  "address": "Juba, South Sudan",
  "is_phone_number_verified": true
}
```

---

## Success & Error Handling

### Success Response

**Expected Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "_id": "507f1f77bcf86cd799439015",
    "email": "john.doe@example.com",
    "phone": "+251912345678",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

**Success Handler (lines 78-87):**
```dart
if (data != null && data['success']) {
  // 1. Show success message
  Service.showMessage(
    context: context,
    title: "Registration successful. Ready to login!",
    error: false,
    duration: 3,  // 3 seconds
  );

  // 2. Log analytics
  await MyApp.analytics.logEvent(name: "user_registered");

  // 3. Navigate to login screen
  Navigator.pushNamedAndRemoveUntil(
    context,
    LoginScreen.routeName,  // "/login"
    (Route<dynamic> route) => false  // Clear all previous routes
  );
}
```

**Success Flow:**
1. ✅ Display success toast/snackbar for 3 seconds
2. ✅ Log Firebase Analytics event `user_registered`
3. ✅ Navigate to login screen
4. ✅ Clear navigation stack (user cannot go back to registration)

---

### Error Response

**Expected Error Response:**
```json
{
  "success": false,
  "error_code": 502,
  "message": "Email already registered."
}
```

### Error Codes (from constants.dart:185-195)

| Error Code | Error Message | Meaning |
|------------|---------------|---------|
| `501` | `"Registration failed."` | General registration failure |
| `502` | `"Email already registered."` | Email exists in database |
| `503` | `"Phone number already registered."` | Phone number exists in database |
| `505` | `"User already registered with social account."` | Conflict with OAuth account |
| `506` | `"User not registered with social account."` | OAuth-related error |
| `511` | `"Login failed."` | Login error (shouldn't happen during registration) |
| `512` | `"You are not registered."` | User doesn't exist |
| `513` | `"Invalid password."` | Wrong password |

**Error Handler (lines 89-100):**
```dart
else {
  // Stop loading
  setState(() {
    _loading = false;
  });

  // Show error message with error code description
  Service.showMessage(
    context: context,
    title: "${errorCodes['${data['error_code']}']}!",
    error: true
  );

  // SPECIAL CASE: Error 503 (phone already registered)
  if (data['error_code'] == 503) {
    // Phone already exists, navigate to login
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (Route<dynamic> route) => false
    );
  }
  // For other errors, user stays on registration page to retry
}
```

### Error Handling Flow

```
┌──────────────────────────────────────┐
│ API returns error response           │
│ { success: false, error_code: XXX }  │
└──────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Stop loading indicator               │
│ (_loading = false)                   │
└──────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Lookup error message from errorCodes │
│ Show error toast/snackbar            │
└──────────────────────────────────────┘
                │
                ▼
        ┌───────┴──────┐
        │ error_code?  │
        └───────┬──────┘
                │
    ┌───────────┴───────────┐
    │                       │
   503                   Other
    │                       │
    ▼                       ▼
┌─────────────┐    ┌──────────────────┐
│ Phone exists│    │ Stay on page     │
│ Navigate to │    │ User can:        │
│ Login screen│    │ - Fix input      │
│ (clear stack)│    │ - Retry submit  │
└─────────────┘    └──────────────────┘
```

### Error Examples by Code

**502: Email Already Registered**
```json
Response: {
  "success": false,
  "error_code": 502,
  "message": "Email already registered."
}

User sees: "Email already registered.!"
Action: User stays on registration page, can change email and retry
```

**503: Phone Number Already Registered**
```json
Response: {
  "success": false,
  "error_code": 503,
  "message": "Phone number already registered."
}

User sees: "Phone number already registered.!"
Action: User is automatically navigated to login screen
```

**501: Registration Failed**
```json
Response: {
  "success": false,
  "error_code": 501,
  "message": "Registration failed."
}

User sees: "Registration failed.!"
Action: User stays on registration page, can retry
```

### Network Error Handling

If the request fails due to network issues or timeout:

```dart
catch (e) {
  return null;  // Returns null instead of error object
}
```

When `data == null`:
```dart
if (data != null && data['success']) {
  // This block is NOT executed
} else {
  // This else block executes
  // But data['error_code'] will cause error accessing null
  // App may crash or show generic error
}
```

**⚠️ Potential Bug**: The code doesn't properly handle `data == null` case. It tries to access `data['error_code']` which will fail.

**Better handling would be:**
```dart
if (data == null) {
  Service.showMessage(
    context: context,
    title: "Network error. Please check your internet connection.",
    error: true
  );
  return;
}

if (data['success']) {
  // Success handling
} else {
  // Error handling with error_code
}
```

---

## Testing Checklist

Use this checklist to ensure implementation matches the mobile app:

### Form Validation
- [ ] First name cannot be empty
- [ ] Last name cannot be empty
- [ ] Email matches regex: `^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$`
- [ ] Phone number is exactly 9 digits
- [ ] Phone number starts with `9`
- [ ] Password is minimum 8 characters
- [ ] Password has at least 1 uppercase letter
- [ ] Password has at least 1 lowercase letter
- [ ] Password has at least 1 digit
- [ ] Password has at least 1 special character from `@$!%*?&`
- [ ] Confirm password matches password exactly
- [ ] Terms & Conditions must be checked to enable submit

### Country Selection
- [ ] Ethiopia flag sets area code to `+251`
- [ ] Ethiopia flag sets base URL to `BASE_URL`
- [ ] Ethiopia flag sets city to `"Addis Ababa"`
- [ ] South Sudan flag sets area code to `+211`
- [ ] South Sudan flag sets base URL to `BASE_URL_JUBA`
- [ ] South Sudan flag sets city to `"Juba"`
- [ ] Address is auto-generated based on country selection

### API Integration
- [ ] Request goes to correct URL based on country
- [ ] Request includes all required fields
- [ ] `country_id` comes from metadata/provider
- [ ] `city` comes from metadata/provider (cityId)
- [ ] `country_phone_code` matches selected country
- [ ] `is_phone_number_verified` is `true`
- [ ] `referral_code` is `"referralCode"` (hardcoded)
- [ ] Request timeout is 30 seconds

### Success Handling
- [ ] Success message displayed for 3 seconds
- [ ] Analytics event `user_registered` is logged
- [ ] User navigated to login page
- [ ] Navigation stack is cleared (cannot go back)

### Error Handling
- [ ] Error code 501: Show message, stay on page
- [ ] Error code 502: Show message, stay on page
- [ ] Error code 503: Show message, redirect to login after 2 seconds
- [ ] Network error: Show appropriate message
- [ ] Timeout error: Show appropriate message
- [ ] Loading indicator stops after error

### UI/UX
- [ ] Submit button disabled when terms not checked
- [ ] Submit button shows loading state during API call
- [ ] All inputs disabled during loading
- [ ] Password has show/hide toggle
- [ ] Confirm password has show/hide toggle
- [ ] Terms link opens in new tab/window
- [ ] Error messages appear below respective fields
- [ ] Phone input restricted to 9 digits, numbers only

---

## Conclusion

This document provides a complete code-level analysis of ZMall's registration flow.

**Key Findings:**
1. ✅ **Validation rules** are well-defined with regex patterns
2. ✅ **Country-based configuration** (Ethiopia vs South Sudan)
3. ✅ **API payload structure** is documented
4. ✅ **Success and error cases** are handled
5. ⚠️ **Potential bugs**: Referral code not using user input, phone regex discrepancy

**Important Notes:**
- No OTP verification (set to true by default)
- Different API endpoints for Ethiopia and South Sudan
- Error code 503 triggers automatic redirect to login
- Referral code is hardcoded as "referralCode" instead of using user input

**Related Documentation:**
- Payment Flow: [PAYMENT_FLOW_CODE_ANALYSIS.md](PAYMENT_FLOW_CODE_ANALYSIS.md)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-23
**Flutter File**: `/Users/apple/Documents/ZMall-Projects/zmall/lib/register/register_screen.dart`
**Lines Analyzed**: 0-1045
