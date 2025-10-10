## Biometric Multi-Account System - Design Document

**Created:** October 6, 2025
**Status:** 🎨 Design Phase (Implementation Ready)

---

## Overview

A multi-account biometric system that allows users to:

- Save multiple accounts with credentials
- Enable/disable biometric per account
- Quick switch between accounts
- Persistent storage (survives logout)
- Better UX with account selection UI

---

## Problem Statement

### Current Limitations

1. **Single Account Only**

   - Can only save one set of credentials
   - Logout clears everything
   - Must re-enable biometric after logout

2. **Poor Multi-User Support**

   - Family members sharing device can't have separate accounts
   - Work/personal accounts can't coexist
   - Each user must re-login completely

3. **Logout Frustration**
   - User enables biometric → Logs out → Everything cleared
   - Must re-enable biometric next login
   - Lost all saved data

---

## Proposed Solution

### Multi-Account Credential Storage

**Core Concept:**

```
Instead of:
  Single credential → Clear on logout

Use:
  List of saved accounts → Persist across logout
  Each account has:
    - Phone number
    - Encrypted password
    - Biometric enabled flag
    - User name (optional)
    - Last used timestamp
```

---

## Architecture

### Data Model

**BiometricCredential Model:**

```dart
class BiometricCredential {
  final String phone;              // Unique identifier
  final String password;           // Encrypted
  final bool biometricEnabled;     // Per-account setting
  final String? userName;          // Display name
  final DateTime lastUsed;         // For sorting

  // Methods:
  toJson()         // Serialize
  fromJson()       // Deserialize
  copyWith()       // Immutable updates
  displayName      // UI display
}
```

### Storage Layer

**BiometricCredentialsManager:**

```dart
// Core operations
getSavedAccounts()                    // List all
saveAccount(credential)               // Add/update
getAccount(phone)                     // Get by phone
removeAccount(phone)                  // Delete

// Biometric operations
updateBiometricStatus(phone, enabled) // Toggle biometric
getBiometricEnabledAccounts()         // Filter by biometric

// Utility
getLastUsedPhone()                    // Last logged in
updateLastUsed(phone)                 // Update timestamp
updateUserName(phone, name)           // Set display name
clearAllAccounts()                    // Nuclear option
```

**Storage:**

- **Location:** FlutterSecureStorage
- **Key:** `saved_biometric_accounts`
- **Format:** JSON array of BiometricCredential objects
- **Encryption:** AES encryption via FlutterSecureStorage

---

## User Experience

### 1. Login Screen

**Visual Changes:**

```
┌─────────────────────────────────┐
│          Login to ZMall         │
│                                 │
│  [Phone Input]                  │
│  [Password Input]               │
│                                 │
│  [👤 Saved Accounts] [🔐 Login]│  ← New button
│                                 │
│  ────── or ──────              │
│                                 │
│  [Continue as Guest]            │
│  [ZMall Global]                 │
└─────────────────────────────────┘
```

**Saved Accounts Button:**

- Shows count badge if accounts exist
- Opens bottom sheet with account list
- Tap to select account → Auto-fill credentials

### 2. Saved Accounts Bottom Sheet

```
┌─────────────────────────────────┐
│      Saved Accounts (3)         │
├─────────────────────────────────┤
│ [A] Alice Johnson              │
│     Face ID enabled      🔐 🗑│ ← Biometric + Delete
│─────────────────────────────────│
│ [B] Bob Smith                  │
│     No biometric            🗑│
│─────────────────────────────────│
│ [W] +251 912 345 678          │
│     Fingerprint enabled  🔐 🗑│
└─────────────────────────────────┘
```

**Features:**

- Avatar with first letter
- Display name or formatted phone
- Biometric status indicator
- Delete button per account
- Tap account → Auto-fill and trigger biometric if enabled

### 3. Account Selection Flow

**With Biometric Enabled:**

```
1. User taps "Saved Accounts"
2. Bottom sheet shows accounts
3. User taps "Alice Johnson" (biometric enabled)
4. Bottom sheet closes
5. Biometric prompt appears
6. User authenticates
7. Direct login to home
```

**Without Biometric:**

```
1. User taps "Saved Accounts"
2. Bottom sheet shows accounts
3. User taps "Bob Smith" (no biometric)
4. Bottom sheet closes
5. Phone + password auto-filled
6. User can review/edit or tap Login
7. OTP screen → Home
```

### 4. Enable Biometric Flow (Updated)

**After OTP Verification:**

```
Current Login:
  Phone: +251 912 345 678
  Name: Alice Johnson (from API)

Dialog: "Enable Face ID for Alice Johnson?"
Options:
  - Not Now → Continue without saving
  - Enable → Save account with biometric enabled
```

**What Gets Saved:**

```dart
BiometricCredential(
  phone: '+251912345678',
  password: 'encrypted_password',
  biometricEnabled: true,
  userName: 'Alice Johnson',  // From API response
  lastUsed: DateTime.now(),
)
```

### 5. Logout Behavior (New)

**Before (Old System):**

```
Logout → Clear credentials → Clear biometric flag
Next login → Must re-enable
```

**After (Multi-Account System):**

```
Logout → Clear current session
BUT → Keep saved accounts
Next login → Can select from saved accounts
Result → Biometric still works!
```

---

## Implementation Details

### Login Screen Integration

**New State Variables:**

```dart
List<BiometricCredential> _savedAccounts = [];
BiometricCredential? _selectedAccount;
int _savedAccountsCount = 0;
```

**New Methods:**

```dart
_loadSavedAccounts()           // Load on init
_showSavedAccountsSheet()      // Show account picker
_onAccountSelected(account)     // Handle selection
_saveCurrentAccount()          // Save after successful login
```

**UI Changes:**

```dart
// Add button next to login
Row(
  children: [
    // Saved accounts button
    OutlinedButton.icon(
      icon: Icon(HeroiconsOutline.userCircle),
      label: Text('Saved Accounts'),
      badge: _savedAccountsCount > 0
        ? Badge(label: Text('$_savedAccountsCount'))
        : null,
      onPressed: _showSavedAccountsSheet,
    ),

    SizedBox(width: kDefaultPadding),

    // Login button
    ElevatedButton(
      child: Text('Login'),
      onPressed: _login,
    ),
  ],
)
```

### OTP Screen Integration

**After Successful Login:**

```dart
// Get user info from API response
final userName = responseData['user']['name'];
final userPhone = responseData['user']['phone'];

// Create credential
final credential = BiometricCredential(
  phone: userPhone,
  password: widget.password,  // From OTP screen
  biometricEnabled: false,    // Initially
  userName: userName,
);

// Save to manager
await BiometricCredentialsManager.saveAccount(credential);

// Show biometric prompt
final shouldEnable = await _promptBiometricSetup();
if (shouldEnable) {
  await BiometricCredentialsManager.updateBiometricStatus(
    userPhone,
    true,
  );
}
```

### Profile Screen Integration

**Enable/Disable Biometric:**

```dart
// When user toggles biometric
await BiometricCredentialsManager.updateBiometricStatus(
  currentUserPhone,
  isEnabled,
);
```

**Logout:**

```dart
// DON'T clear saved accounts
// Just clear current session
await Service.saveBool('logged', false);
await Service.remove('user');
await Service.remove('cart');

// Saved accounts persist!
```

---

## Storage Format

### JSON Structure

```json
{
  "saved_biometric_accounts": [
    {
      "phone": "+251912345678",
      "password": "encrypted_password_here",
      "biometric_enabled": true,
      "user_name": "Alice Johnson",
      "last_used": "2025-10-06T14:30:00.000Z"
    },
    {
      "phone": "+251923456789",
      "password": "encrypted_password_here",
      "biometric_enabled": false,
      "user_name": "Bob Smith",
      "last_used": "2025-10-05T10:15:00.000Z"
    }
  ],
  "last_used_phone": "+251912345678"
}
```

**Sorting:**

- Accounts sorted by `lastUsed` descending
- Most recent at top

---

## Security Considerations

### ✅ Enhanced Security

1. **Encrypted Storage:**

   - All credentials in FlutterSecureStorage
   - AES encryption at rest
   - Keychain (iOS) / EncryptedSharedPreferences (Android)

2. **Per-Account Biometric:**

   - Each account verified independently
   - No cross-account access
   - Biometric required per account

3. **Password Verification:**
   - Still calls API to verify password
   - Can't enable biometric with wrong password
   - Same security as current system

### ⚠️ Security Trade-offs

1. **Multiple Passwords Stored:**

   - **Risk:** More passwords = larger attack surface
   - **Mitigation:** All encrypted, biometric required
   - **Acceptable:** Standard for password managers

2. **Account Enumeration:**

   - **Risk:** Can see list of saved accounts
   - **Mitigation:** Requires device unlock first
   - **Acceptable:** Same as saved passwords in browser

3. **Logout Doesn't Clear:**
   - **Risk:** Credentials persist after logout
   - **Mitigation:** Device lock + biometric required
   - **Benefit:** Better UX, intentional design

---

## Migration Strategy

### Phase 1: Backward Compatible

**Detect Old System:**

```dart
// Check if old credentials exist
final oldPhone = await Service.getSavedPhone();
final oldPassword = await Service.getSavedPassword();
final oldEnabled = await Service.isBiometricEnabled();

if (oldPhone != null && oldPassword != null) {
  // Migrate to new system
  final credential = BiometricCredential(
    phone: oldPhone,
    password: oldPassword,
    biometricEnabled: oldEnabled,
  );

  await BiometricCredentialsManager.saveAccount(credential);

  // Clear old storage
  await Service.clearBiometricCredentials();
  await Service.disableBiometric();
}
```

### Phase 2: New User Flow

**First Time User:**

1. Login with phone + password
2. OTP verification
3. Prompt: "Save account for quick access?"
4. If yes → Save with biometric option
5. Done

**Existing User (Post-Migration):**

1. Open app → Sees saved accounts
2. Tap account → Biometric prompt
3. Authenticate → Direct login
4. Same experience as before, but persistent!

---

## UI/UX Improvements

### Account Management Screen (Future)

**Settings → Saved Accounts:**

```
┌─────────────────────────────────┐
│      Manage Saved Accounts      │
├─────────────────────────────────┤
│ [A] Alice Johnson              │
│     +251 912 345 678            │
│     ✓ Face ID enabled           │
│     [Edit] [Remove]             │
├─────────────────────────────────┤
│ [B] Bob Smith                  │
│     +251 923 456 789            │
│     ✗ No biometric              │
│     [Edit] [Remove]             │
└─────────────────────────────────┘

[+ Add Another Account]
[Clear All Accounts]
```

**Features:**

- Edit display name
- Toggle biometric per account
- Remove individual accounts
- Add new account (redirect to login)
- Clear all (with confirmation)

---

## Benefits

### For Users

1. **Multi-Account Support:**

   - Work and personal accounts
   - Family members on shared device
   - Multiple businesses

2. **Quick Switching:**

   - Select account → Biometric → Login
   - No re-entering credentials
   - Faster than typing

3. **Persistent Settings:**

   - Logout doesn't clear accounts
   - Biometric persists
   - Less frustration

4. **Better Privacy:**
   - Each account independent
   - Can disable biometric per account
   - Clear per-account data

### For Business

1. **Shared Devices:**

   - Retail stores (multiple employees)
   - Warehouse workers
   - Delivery drivers

2. **B2B Use Cases:**
   - Manager + Employee accounts
   - Multiple store locations
   - Franchise owners

---

## Testing Plan

### Unit Tests

```dart
test('Save and retrieve account', () async {
  final credential = BiometricCredential(
    phone: '+251912345678',
    password: 'password',
    biometricEnabled: true,
  );

  await BiometricCredentialsManager.saveAccount(credential);
  final retrieved = await BiometricCredentialsManager.getAccount(
    '+251912345678'
  );

  expect(retrieved?.phone, credential.phone);
  expect(retrieved?.biometricEnabled, true);
});

test('Update biometric status', () async {
  // Save with biometric disabled
  // Update to enabled
  // Verify status changed
});

test('Remove account', () async {
  // Save account
  // Remove account
  // Verify not in list
});
```

### Integration Tests

1. **Save Multiple Accounts:**

   - Login with Account A
   - Logout
   - Login with Account B
   - Verify both saved

2. **Account Selection:**

   - Open saved accounts
   - Select account
   - Verify auto-fill
   - Verify biometric prompt

3. **Biometric Toggle:**
   - Enable biometric for Account A
   - Logout
   - Select Account A
   - Verify biometric works
   - Login
   - Disable biometric
   - Logout
   - Verify biometric not prompted

### User Acceptance Testing

- [ ] Can save multiple accounts
- [ ] Can select account from list
- [ ] Biometric works per account
- [ ] Delete account removes it
- [ ] Logout preserves accounts
- [ ] Account names display correctly
- [ ] Last used account shows first

---

## Performance Considerations

### Storage Size

**Typical Account:**

```
Phone: 15 bytes
Password: 60 bytes (encrypted)
Name: 30 bytes
Metadata: 50 bytes
Total: ~155 bytes per account
```

**10 Accounts = ~1.5 KB**
**100 Accounts = ~15 KB**

**Conclusion:** Negligible storage impact

### Load Time

**Decrypt and parse accounts:**

- 10 accounts: ~10ms
- 100 accounts: ~50ms

**Negligible impact on app startup**

---

## Future Enhancements

### 1. Account Profiles

**Add profile pictures:**

```dart
class BiometricCredential {
  final String? profileImageUrl;
  final String? profileImagePath;
}
```

### 2. Cloud Sync

**Sync across devices:**

- Save to Firebase/backend
- Encrypt before upload
- Per-device biometric enablement
- Conflict resolution

### 3. Account Categories

**Group accounts:**

```dart
enum AccountCategory {
  personal,
  work,
  family,
  business,
}
```

### 4. Auto-Lock

**Security feature:**

- Lock saved accounts after inactivity
- Require master biometric
- Clear from memory

### 5. Account Search

**For many accounts:**

- Search bar in bottom sheet
- Filter by name/phone
- Recent accounts section

---

## Alternatives Considered

### Alternative 1: Single Account with Remember Flag

**Pros:**

- Simpler implementation
- Less storage

**Cons:**

- No multi-account support
- Same frustration on logout
- Limited use cases

### Alternative 2: OS Keychain Only

**Pros:**

- Native integration
- OS-level security

**Cons:**

- Platform-specific code
- Less control
- Harder to manage

### Alternative 3: Server-Side Storage

**Pros:**

- Sync across devices
- Cloud backup

**Cons:**

- Privacy concerns
- Network dependency
- Security risks

**Chosen Approach:** Local storage with optional cloud sync later

---

## Implementation Checklist

### Core Components ✅

- [x] BiometricCredential model
- [x] BiometricCredentialsManager service
- [x] SavedAccountsBottomSheet UI
- [ ] Login screen integration
- [ ] OTP screen integration
- [ ] Profile screen updates
- [ ] Migration logic

### UI Components

- [ ] Saved Accounts button on login
- [ ] Account list bottom sheet
- [ ] Account avatar/initials
- [ ] Biometric status badge
- [ ] Delete account dialog
- [ ] Empty state UI

### Testing

- [ ] Unit tests for manager
- [ ] Integration tests
- [ ] Migration testing
- [ ] Multi-account flow testing
- [ ] Security audit

### Documentation

- [x] Design document
- [ ] User guide
- [ ] API documentation
- [ ] Migration guide

---

## Rollout Plan

### Phase 1: Core Feature (Week 1)

- Implement model + manager
- Create UI components
- Login screen integration

### Phase 2: Integration (Week 2)

- OTP screen updates
- Profile screen updates
- Migration logic

### Phase 3: Polish (Week 3)

- UI refinements
- Error handling
- Edge case testing

### Phase 4: Release (Week 4)

- Beta testing
- User feedback
- Production release

---

**Status:** 🎨 Design Complete, Ready for Implementation
**Effort:** ~2-3 weeks for full implementation
**Impact:** High - Significant UX improvement
**Risk:** Low - Backward compatible, isolated changes
