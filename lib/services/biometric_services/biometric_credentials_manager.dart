import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zmall/models/biometric_credential.dart';

/// Manages multiple saved biometric credentials
class BiometricCredentialsManager {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _savedAccountsKey = 'saved_biometric_accounts';
  static const String _lastUsedPhoneKey = 'last_used_phone';

  /// Get all saved accounts
  static Future<List<BiometricCredential>> getSavedAccounts() async {
    try {
      final accountsJson = await _secureStorage.read(key: _savedAccountsKey);
      if (accountsJson == null) return [];

      final List<dynamic> accountsList = json.decode(accountsJson);
      return accountsList
          .map((json) => BiometricCredential.fromJson(json))
          .toList()
        ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed)); // Sort by last used
    } catch (e) {
      // print('Error loading saved accounts: $e');
      return [];
    }
  }

  /// Save a new account or update existing
  static Future<void> saveAccount(BiometricCredential credential) async {
    try {
      final accounts = await getSavedAccounts();

      // Remove existing account with same phone
      accounts.removeWhere((acc) => acc.phone == credential.phone);

      // Add updated account
      accounts.insert(0, credential); // Add to front

      // Save all accounts
      final accountsJson = json.encode(
        accounts.map((acc) => acc.toJson()).toList(),
      );
      await _secureStorage.write(key: _savedAccountsKey, value: accountsJson);

      // Update last used phone
      await _secureStorage.write(
        key: _lastUsedPhoneKey,
        value: credential.phone,
      );
    } catch (e) {
      // print('Error saving account: $e');
      throw Exception('Failed to save account');
    }
  }

  /// Get account by phone number
  static Future<BiometricCredential?> getAccount(String phone) async {
    try {
      final accounts = await getSavedAccounts();
      return accounts.firstWhere(
        (acc) => acc.phone == phone,
        orElse: () => throw Exception('Account not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Update account's biometric status
  static Future<void> updateBiometricStatus(
    String phone,
    bool enabled,
  ) async {
    try {
      final account = await getAccount(phone);
      if (account != null) {
        final updatedAccount = account.copyWith(biometricEnabled: enabled);
        await saveAccount(updatedAccount);
      }
    } catch (e) {
      // print('Error updating biometric status: $e');
    }
  }

  /// Remove an account
  static Future<void> removeAccount(String phone) async {
    try {
      final accounts = await getSavedAccounts();
      accounts.removeWhere((acc) => acc.phone == phone);

      final accountsJson = json.encode(
        accounts.map((acc) => acc.toJson()).toList(),
      );
      await _secureStorage.write(key: _savedAccountsKey, value: accountsJson);
    } catch (e) {
      // print('Error removing account: $e');
    }
  }

  /// Get last used phone number
  static Future<String?> getLastUsedPhone() async {
    try {
      return await _secureStorage.read(key: _lastUsedPhoneKey);
    } catch (e) {
      return null;
    }
  }

  /// Get accounts with biometric enabled
  static Future<List<BiometricCredential>> getBiometricEnabledAccounts() async {
    final accounts = await getSavedAccounts();
    return accounts.where((acc) => acc.biometricEnabled).toList();
  }

  /// Check if any account has biometric enabled
  static Future<bool> hasAnyBiometricEnabled() async {
    final accounts = await getBiometricEnabledAccounts();
    return accounts.isNotEmpty;
  }

  /// Clear all saved accounts
  static Future<void> clearAllAccounts() async {
    try {
      await _secureStorage.delete(key: _savedAccountsKey);
      await _secureStorage.delete(key: _lastUsedPhoneKey);
    } catch (e) {
      // print('Error clearing accounts: $e');
    }
  }

  /// Update account's last used timestamp
  static Future<void> updateLastUsed(String phone) async {
    try {
      final account = await getAccount(phone);
      if (account != null) {
        final updatedAccount = account.copyWith(lastUsed: DateTime.now());
        await saveAccount(updatedAccount);
      }
    } catch (e) {
      // print('Error updating last used: $e');
    }
  }

  /// Update account's user name
  static Future<void> updateUserName(String phone, String userName) async {
    try {
      final account = await getAccount(phone);
      if (account != null) {
        final updatedAccount = account.copyWith(userName: userName);
        await saveAccount(updatedAccount);
      }
    } catch (e) {
      // print('Error updating user name: $e');
    }
  }
}
