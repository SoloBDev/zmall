# Biometric Storage Architecture - ZMall

## Overview
The biometric authentication system in ZMall uses a **hybrid storage approach** that maximizes reuse of existing Service methods while adding secure storage only where necessary.

## Storage Methods Used

### 1. Existing Service Methods (Reused)
These methods already exist in `lib/service.dart` and are reused for biometric functionality:

#### SharedPreferences Methods
```dart
// Check if biometric is enabled
await Service.readBool('biometric_enabled')  // Returns bool or null
await Service.saveBool('biometric_enabled', true)  // Save boolean value

// User data (already exists)
await Service.save('user', userData)  // Save user data
await Service.getUser()               // Get user data
await Service.read('user')            // Alternative to getUser()

// Login status (already exists)
await Service.saveBool('logged', true)   // Mark as logged in
await Service.isLogged()                  // Check login status

// Remove data (already exists)
await Service.remove('user')       // Remove user data
await Service.remove('cart')       // Remove cart data
```

### 2. New Secure Storage Methods (Added)
These methods were added to handle sensitive credentials:

```dart
// Save credentials (phone & password) - ENCRYPTED
await Service.saveBiometricCredentials(
  phone: '0912345678',
  password: 'userPassword123'
)

// Get saved phone - ENCRYPTED
String? phone = await Service.getSavedPhone()

// Get saved password - ENCRYPTED
String? password = await Service.getSavedPassword()

// Clear credentials - ENCRYPTED
await Service.clearBiometricCredentials()

// Check if credentials exist
bool hasCredentials = await Service.hasBiometricCredentials()
```

## Implementation Details

### Biometric Enabled Status
**Storage:** SharedPreferences (via existing `saveBool`/`readBool`)

```dart
// In Service.dart
static Future<bool> isBiometricEnabled() async {
  return await readBool('biometric_enabled') ?? false;
}

static Future<void> enableBiometric() async {
  await saveBool('biometric_enabled', true);
}

static Future<void> disableBiometric() async {
  await saveBool('biometric_enabled', false);
  await clearBiometricCredentials();
}
```

**Why SharedPreferences?**
- ✅ Non-sensitive boolean flag
- ✅ Reuses existing proven methods
- ✅ Consistent with app's storage pattern

### User Credentials (Phone & Password)
**Storage:** FlutterSecureStorage (new, encrypted)

```dart
// In Service.dart
static const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);

static Future<void> saveBiometricCredentials({
  required String phone,
  required String password,
}) async {
  await _secureStorage.write(key: 'saved_phone', value: phone);
  await _secureStorage.write(key: 'saved_password', value: password);
}

static Future<String?> getSavedPhone() async {
  return await _secureStorage.read(key: 'saved_phone');
}

static Future<String?> getSavedPassword() async {
  return await _secureStorage.read(key: 'saved_password');
}
```

**Why FlutterSecureStorage?**
- ✅ Phone and password are SENSITIVE data
- ✅ Encrypted at rest (Keychain on iOS, EncryptedSharedPreferences on Android)
- ✅ Cannot use SharedPreferences for passwords (security risk)
- ✅ Industry standard for credential storage

### User Data
**Storage:** SharedPreferences (via existing `save`/`getUser`)

```dart
// Already exists in Service.dart
static Future<dynamic> getUser() async {
  return read('user');
}

static Future<dynamic> save(String key, value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, json.encode(value));
}
```

**Usage:**
```dart
// No changes needed - use existing methods
var userData = await Service.getUser();
await Service.save('user', responseData);
```

## Data Flow

### On Login Success (OTP Screen)
```dart
// 1. Save user data (existing method)
await Service.save('user', responseData);
await Service.saveBool('logged', true);

// 2. Prompt for biometric setup
if (biometric available && not enabled) {
  // Ask user if they want to enable
  if (user clicks "Enable") {
    // 3. Authenticate with biometric
    final result = await BiometricService.authenticate(...);

    if (result.success) {
      // 4. Save credentials securely
      await Service.saveBiometricCredentials(
        phone: phone,
        password: password,
      );

      // 5. Enable biometric flag
      await Service.enableBiometric();
    }
  }
}
```

### On App Launch (Login Screen)
```dart
// 1. Check if biometric is enabled
final isEnabled = await Service.isBiometricEnabled();
final hasCredentials = await Service.hasBiometricCredentials();

if (isEnabled && hasCredentials) {
  // 2. Authenticate with biometric
  final result = await BiometricService.authenticate(...);

  if (result.success) {
    // 3. Get saved credentials
    final phone = await Service.getSavedPhone();
    final password = await Service.getSavedPassword();

    // 4. Auto-login with saved credentials
    await generateOtpAtLogin(phone: phone, password: password);
  }
}
```

### On Logout
```dart
// 1. Clear user data (existing method)
await Service.saveBool('logged', false);
await Service.remove('user');
await Service.remove('cart');

// 2. Clear biometric credentials
await Service.clearBiometricCredentials();

// Note: Biometric enabled status is NOT cleared
// User can re-enable by logging in again
```

## Security Considerations

### What's Encrypted
✅ Phone number (in FlutterSecureStorage)
✅ Password (in FlutterSecureStorage)

### What's NOT Encrypted (But Non-Sensitive)
✅ Biometric enabled flag (boolean in SharedPreferences)
✅ User data (already in SharedPreferences via existing methods)
✅ Login status (boolean in SharedPreferences)

### Why This Hybrid Approach?
1. **Reuse Existing Logic:** No need to duplicate working storage methods
2. **Security Where Needed:** Only credentials use secure storage
3. **Performance:** SharedPreferences is faster for non-sensitive data
4. **Consistency:** Follows app's established patterns
5. **Maintainability:** Minimal changes to existing codebase

## File Structure

```
lib/
├── service.dart (MODIFIED)
│   ├── Existing methods: read(), save(), readBool(), saveBool(), remove()
│   ├── New secure storage: _secureStorage instance
│   └── New methods: saveBiometricCredentials(), getSavedPhone(), etc.
│
└── services/
    └── biometric_service.dart (NEW)
        └── BiometricService class for authentication
```

## Comparison: Before vs After

### Before (Separate Service Approach)
```dart
// Had separate SecureStorageService class
await SecureStorageService.isBiometricEnabled()
await SecureStorageService.saveCredentials(...)
await SecureStorageService.getSavedPhone()

// Result: Duplicate storage logic, two services to maintain
```

### After (Unified Service Approach)
```dart
// Everything through Service class
await Service.isBiometricEnabled()      // Uses existing readBool()
await Service.saveBiometricCredentials(...) // New secure method
await Service.getSavedPhone()           // New secure method

// Result: Single service, reuses existing methods where possible
```

## Advantages

1. ✅ **Minimal Code Changes:** Only adds what's necessary
2. ✅ **Reuses Proven Code:** Existing methods are already tested
3. ✅ **Single Responsibility:** Service class handles ALL storage
4. ✅ **Easy to Understand:** Developers already know Service class
5. ✅ **Secure:** Credentials encrypted at rest
6. ✅ **Consistent:** Follows app's existing patterns

## Testing Checklist

- [ ] Biometric enabled flag persists across app restarts
- [ ] Credentials stored securely (check with device inspector)
- [ ] Credentials cleared on logout
- [ ] Existing storage methods still work (user, cart, etc.)
- [ ] No data loss when toggling biometric on/off
- [ ] SharedPreferences values accessible (non-sensitive data)
- [ ] SecureStorage values encrypted (phone, password)

---

**Last Updated:** October 6, 2025
**Approach:** Hybrid (SharedPreferences + SecureStorage)
**Pattern:** Reuse existing, add only what's needed
