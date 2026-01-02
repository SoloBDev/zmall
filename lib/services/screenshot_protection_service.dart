import 'dart:io';
import 'package:flutter/services.dart';

/// Service for protecting screens from screenshots and screen recording
///
/// **Platform-Specific Behavior:**
///
/// **Android:**
/// - Uses FLAG_SECURE to **completely prevent** screenshots
/// - No overlay needed - screenshots are blocked at system level
/// - User sees error: "Couldn't capture screenshot. Taking screenshots isn't allowed by the app"
///
/// **iOS:**
/// - **Cannot prevent** screenshots (no official API)
/// - **Detects** when screenshot is taken
/// - Shows black overlay so screenshot captures black screen with text
/// - Overlay is Flutter-side UI (customizable)
class ScreenshotProtectionService {
  static const _channel = MethodChannel('com.zmall.user/security');

  static bool _isProtectionEnabled = false;
  static bool _isScreenRecording = false;
  static bool _showOverlay = false;

  // Callbacks (iOS only)
  static Function()? _onScreenshotTaken;
  static Function(bool)? _onScreenRecordingChanged;
  static Function(bool)? _onOverlayChanged;

  /// Initialize the screenshot protection service
  ///
  /// **Note:** Callbacks only work on iOS
  ///
  /// [onScreenshotTaken] - Called when user takes a screenshot (iOS only)
  /// [onScreenRecordingChanged] - Called when screen recording state changes (iOS only)
  /// [onOverlayChanged] - Called when overlay should be shown/hidden (iOS only)
  static Future<void> init({
    Function()? onScreenshotTaken,
    Function(bool)? onScreenRecordingChanged,
    Function(bool)? onOverlayChanged,
  }) async {
    // Only set up callbacks on iOS
    // Android uses FLAG_SECURE and doesn't need callbacks
    if (Platform.isIOS) {
      _onScreenshotTaken = onScreenshotTaken;
      _onScreenRecordingChanged = onScreenRecordingChanged;
      _onOverlayChanged = onOverlayChanged;

      // Set up method call handler to receive events from iOS
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  /// Handle method calls from native platforms
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'screenshotTaken':
        // Show overlay for 2 seconds
        _showOverlay = true;
        _onOverlayChanged?.call(true);
        _onScreenshotTaken?.call();

        // Hide after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          _showOverlay = false;
          _onOverlayChanged?.call(false);
        });
        break;

      case 'screenCaptureChanged':
        _isScreenRecording = call.arguments as bool;
        _showOverlay = _isScreenRecording;
        _onScreenRecordingChanged?.call(_isScreenRecording);
        _onOverlayChanged?.call(_showOverlay);
        break;

      case 'appWillResignActive':
        _showOverlay = true;
        _onOverlayChanged?.call(true);
        break;

      case 'appDidBecomeActive':
        // Only hide if not recording
        if (!_isScreenRecording) {
          _showOverlay = false;
          _onOverlayChanged?.call(false);
        }
        break;
    }
  }

  /// Enable screenshot protection
  ///
  /// Android: Enables FLAG_SECURE (completely prevents screenshots)
  /// iOS: Enables detection and black overlay
  static Future<bool> enableProtection() async {
    try {
      final result = await _channel.invokeMethod('enableScreenshotProtection');
      _isProtectionEnabled = true;
      return result ?? true;
    } catch (e) {
      print('Error enabling screenshot protection: $e');
      return false;
    }
  }

  /// Disable screenshot protection
  ///
  /// Android: Disables FLAG_SECURE (allows screenshots)
  /// iOS: Disables detection and overlay
  static Future<bool> disableProtection() async {
    try {
      final result = await _channel.invokeMethod('disableScreenshotProtection');
      _isProtectionEnabled = false;
      return result ?? true;
    } catch (e) {
      print('Error disabling screenshot protection: $e');
      return false;
    }
  }

  /// Check if protection is currently enabled
  static bool get isProtectionEnabled => _isProtectionEnabled;

  /// Check if screen is being recorded (iOS only)
  static bool get isScreenRecording => _isScreenRecording;

  /// Check if overlay should be shown (iOS only)
  static bool get shouldShowOverlay => _showOverlay;
}
