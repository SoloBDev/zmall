/// Biometric Credential Model
/// Represents a saved user account with biometric settings
class BiometricCredential {
  final String phone;
  final String password;
  final bool biometricEnabled;
  final String? userName; // Optional display name
  final DateTime lastUsed;

  BiometricCredential({
    required this.phone,
    required this.password,
    required this.biometricEnabled,
    this.userName,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'password': password,
      'biometric_enabled': biometricEnabled,
      'user_name': userName,
      'last_used': lastUsed.toIso8601String(),
    };
  }

  /// Create from JSON
  factory BiometricCredential.fromJson(Map<String, dynamic> json) {
    return BiometricCredential(
      phone: json['phone'] as String,
      password: json['password'] as String,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      userName: json['user_name'] as String?,
      lastUsed: json['last_used'] != null
          ? DateTime.parse(json['last_used'] as String)
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  BiometricCredential copyWith({
    String? phone,
    String? password,
    bool? biometricEnabled,
    String? userName,
    DateTime? lastUsed,
  }) {
    return BiometricCredential(
      phone: phone ?? this.phone,
      password: password ?? this.password,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      userName: userName ?? this.userName,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Get display text for account (name or phone)
  String get displayName => userName ?? formatPhone(phone);

  /// Format phone number for display
  static String formatPhone(String phone) {
    if (phone.length == 9) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BiometricCredential && other.phone == phone;
  }

  @override
  int get hashCode => phone.hashCode;
}
