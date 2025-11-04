import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Check if device is enrolled with biometrics
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric authentication is available on device
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await canCheckBiometrics();
      final isSupported = await isDeviceSupported();
      final availableBiometrics = await getAvailableBiometrics();

      return canCheck && isSupported && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user with biometrics
  static Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Please authenticate to login',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorMessage:
              'Biometric authentication is not available on this device',
        );
      }

      // Attempt authentication
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );

      return BiometricAuthResult(success: authenticated);
    } catch (e) {
      // Handle specific error codes
      String errorMessage = 'Authentication failed';

      if (e.toString().contains('NotEnrolled')) {
        errorMessage =
            'No biometrics enrolled. Please set up biometrics in device settings.';
      } else if (e.toString().contains('LockedOut')) {
        errorMessage = 'Too many failed attempts. Please try again later.';
      } else if (e.toString().contains('PermanentlyLockedOut')) {
        errorMessage =
            'Biometric authentication is locked. Please unlock your device.';
      } else if (e.toString().contains('NotAvailable')) {
        errorMessage = 'Biometric authentication is not available.';
      }

      return BiometricAuthResult(success: false, errorMessage: errorMessage);
    }
  }

  /// Stop any ongoing authentication
  static Future<bool> stopAuthentication() async {
    try {
      return await _auth.stopAuthentication();
    } catch (e) {
      return false;
    }
  }

  /// Get a user-friendly name for available biometric types
  static Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }

    return 'Biometric Authentication';
  }
}

/// Result class for biometric authentication
class BiometricAuthResult {
  final bool success;
  final String? errorMessage;

  BiometricAuthResult({required this.success, this.errorMessage});
}


//
// import 'package:local_auth/local_auth.dart';

// class BiometricService {
//   static final LocalAuthentication _auth = LocalAuthentication();

//   /// Check if device supports biometric authentication
//   static Future<bool> canCheckBiometrics() async {
//     try {
//       return await _auth.canCheckBiometrics;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Check if device is enrolled with biometrics
//   static Future<bool> isDeviceSupported() async {
//     try {
//       return await _auth.isDeviceSupported();
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Get available biometric types
//   static Future<List<BiometricType>> getAvailableBiometrics() async {
//     try {
//       return await _auth.getAvailableBiometrics();
//     } catch (e) {
//       return [];
//     }
//   }

//   /// Check if biometric authentication is available on device
//   static Future<bool> isBiometricAvailable() async {
//     try {
//       final canCheck = await canCheckBiometrics();
//       final isSupported = await isDeviceSupported();
//       final availableBiometrics = await getAvailableBiometrics();

//       return canCheck && isSupported && availableBiometrics.isNotEmpty;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Authenticate user with biometrics
//   static Future<BiometricAuthResult> authenticate({
//     String localizedReason = 'Please authenticate to login',
//     bool useErrorDialogs = true,
//     bool stickyAuth = true,
//   }) async {
//     try {
//       // Check if biometric is available
//       final isAvailable = await isBiometricAvailable();

//       if (!isAvailable) {
//         return BiometricAuthResult(
//           success: false,
//           errorMessage:
//               'Biometric authentication is not available on this device',
//         );
//       }

//       // Attempt authentication
//       final authenticated = await _auth.authenticate(
//         localizedReason: localizedReason,
//         biometricOnly: true,
//         // options: AuthenticationOptions(
//         //   useErrorDialogs: useErrorDialogs,
//         //   stickyAuth: stickyAuth,
//         //   biometricOnly: true,
//         // ),
//       );

//       return BiometricAuthResult(success: authenticated);
//     } catch (e) {
//       // Handle specific error codes
//       String errorMessage = 'Authentication failed';

//       if (e.toString().contains('NotEnrolled')) {
//         errorMessage =
//             'No biometrics enrolled. Please set up biometrics in device settings.';
//       } else if (e.toString().contains('LockedOut')) {
//         errorMessage = 'Too many failed attempts. Please try again later.';
//       } else if (e.toString().contains('PermanentlyLockedOut')) {
//         errorMessage =
//             'Biometric authentication is locked. Please unlock your device.';
//       } else if (e.toString().contains('NotAvailable')) {
//         errorMessage = 'Biometric authentication is not available.';
//       }
//       return BiometricAuthResult(success: false, errorMessage: errorMessage);
//     }
//   }

//   /// Stop any ongoing authentication
//   static Future<bool> stopAuthentication() async {
//     try {
//       return await _auth.stopAuthentication();
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Get a user-friendly name for available biometric types
//   static Future<String> getBiometricTypeName() async {
//     final biometrics = await getAvailableBiometrics();

//     if (biometrics.contains(BiometricType.face)) {
//       return 'Face ID';
//     } else if (biometrics.contains(BiometricType.fingerprint)) {
//       return 'Fingerprint';
//     } else if (biometrics.contains(BiometricType.iris)) {
//       return 'Iris';
//     } else if (biometrics.contains(BiometricType.strong) ||
//         biometrics.contains(BiometricType.weak)) {
//       return 'Biometric';
//     }

//     return 'Biometric Authentication';
//   }
// }

// /// Result class for biometric authentication
// class BiometricAuthResult {
//   final bool success;
//   final String? errorMessage;

//   BiometricAuthResult({required this.success, this.errorMessage});
// }