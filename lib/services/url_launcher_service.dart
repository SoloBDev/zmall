import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized URL launcher service for opening external links
///
/// Handles:
/// - Web URLs (https://)
/// - Email links (mailto:)
/// - Phone calls (tel:)
/// - SMS messages (sms:)
///
/// Usage:
/// ```dart
/// await UrlLauncherService.openUrl('https://example.com');
/// await UrlLauncherService.openEmail('support@example.com', subject: 'Help');
/// await UrlLauncherService.makePhoneCall('+251912345678');
/// await UrlLauncherService.sendSms('+251912345678', message: 'Hello');
/// ```
class UrlLauncherService {
  /// Sanitizes a URL by removing double slashes (except after protocol)
  ///
  /// Example: https://example.com//path -> https://example.com/path
  ///
  ///
  static Future<void> launchInWebViewOrVC(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        // forceSafariVC: true,
        // forceWebView: true,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static String _sanitizeUrl(String url) {
    // Replace multiple consecutive slashes with a single slash,
    // but preserve the double slash after the protocol (http:// or https://)
    return url.replaceAllMapped(
      RegExp(r'([^:]\/)\/+'),
      (match) => match.group(1)!,
    );
  }

  /// Opens a web URL in the default browser
  ///
  /// [url] - The web URL to open (must start with http:// or https://)
  /// Returns true if successfully launched, false otherwise
  static Future<bool> openUrl(String url) async {
    try {
      // Sanitize URL to remove double slashes
      final sanitizedUrl = _sanitizeUrl(url);

      final uri = Uri.parse(sanitizedUrl);

      if (!uri.hasScheme) {
        //debugPrint('URL missing scheme, prepending https://');
        return await openUrl('https://$sanitizedUrl');
      }

      if (await canLaunchUrl(uri)) {
        //debugPrint('Opening URL: $sanitizedUrl');
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        //debugPrint('Cannot launch URL: $sanitizedUrl');
        return false;
      }
    } catch (e) {
      //debugPrint('Error launching URL: $url, error $e');
      return false;
    }
  }

  /// Opens an email client with pre-filled fields
  ///
  /// [email] - The recipient email address
  /// [subject] - Optional email subject
  /// [body] - Optional email body
  /// Returns true if successfully launched, false otherwise
  static Future<bool> openEmail(
    String email, {
    String? subject,
    String? body,
  }) async {
    try {
      final emailUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        //debugPrint('Opening email client for: $email');
        return await launchUrl(emailUri);
      } else {
        //debugPrint('Cannot launch email client for: $email');
        return false;
      }
    } catch (e) {
      //debugPrint('Error opening email: $email, error $e');
      return false;
    }
  }

  /// Makes a phone call to the specified number
  ///
  /// [phoneNumber] - The phone number to call (with country code recommended)
  /// Returns true if successfully launched, false otherwise
  static Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      final telUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(telUri)) {
        //debugPrint('Making phone call to: $phoneNumber');
        return await launchUrl(telUri);
      } else {
        //debugPrint('Cannot make phone call to: $phoneNumber');
        return false;
      }
    } catch (e) {
      //debugPrint('Error making phone call: $phoneNumber, error $e');
      return false;
    }
  }

  /// Opens SMS app with pre-filled message
  ///
  /// [phoneNumber] - The recipient phone number
  /// [message] - Optional pre-filled message
  /// Returns true if successfully launched, false otherwise
  static Future<bool> sendSms(String phoneNumber, {String? message}) async {
    try {
      final smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: message != null ? {'body': message} : null,
      );

      if (await canLaunchUrl(smsUri)) {
        //debugPrint('Opening SMS app for: $phoneNumber');
        return await launchUrl(smsUri);
      } else {
        //debugPrint('Cannot open SMS app for: $phoneNumber');
        return false;
      }
    } catch (e) {
      //debugPrint('Error opening SMS: $phoneNumber, error $e');
      return false;
    }
  }

  /// Opens a URL in an in-app WebView (if supported)
  ///
  /// [url] - The web URL to open
  /// Returns true if successfully launched, false otherwise
  static Future<bool> openInAppWebView(String url) async {
    try {
      // Sanitize URL to remove double slashes
      final sanitizedUrl = _sanitizeUrl(url);

      final uri = Uri.parse(sanitizedUrl);

      if (!uri.hasScheme) {
        //debugPrint('URL missing scheme, prepending https://');
        return await openInAppWebView('https://$sanitizedUrl');
      }

      if (await canLaunchUrl(uri)) {
        //debugPrint('Opening in-app WebView: $sanitizedUrl');
        return await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        //debugPrint('Cannot launch in-app WebView: $sanitizedUrl');
        return false;
      }
    } catch (e) {
      //debugPrint('Error launching in-app WebView: $url, error $e');
      return false;
    }
  }

  /// Opens a URL with custom launch mode
  ///
  /// [url] - The URL to open
  /// [mode] - The launch mode (external, inAppWebView, etc.)
  /// Returns true if successfully launched, false otherwise
  static Future<bool> openWithMode(String url, LaunchMode mode) async {
    try {
      // Sanitize URL to remove double slashes
      final sanitizedUrl = _sanitizeUrl(url);

      final uri = Uri.parse(sanitizedUrl);

      if (!uri.hasScheme) {
        //debugPrint('URL missing scheme, prepending https://');
        return await openWithMode('https://$sanitizedUrl', mode);
      }

      if (await canLaunchUrl(uri)) {
        //debugPrint('Opening URL with mode $mode: $sanitizedUrl');
        return await launchUrl(uri, mode: mode);
      } else {
        //debugPrint('Cannot launch URL: $sanitizedUrl');
        return false;
      }
    } catch (e) {
      //debugPrint('Error launching URL: $url error $e');
      return false;
    }
  }

  /// Opens WhatsApp chat with a phone number
  ///
  /// [phoneNumber] - The phone number (with country code, no + or spaces)
  /// [message] - Optional pre-filled message
  /// Returns true if successfully launched, false otherwise
  static Future<bool> openWhatsApp(
    String phoneNumber, {
    String? message,
  }) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final whatsappUrl = message != null
          ? 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}'
          : 'https://wa.me/$cleanNumber';

      return await openUrl(whatsappUrl);
    } catch (e) {
      //debugPrint('Error opening WhatsApp: $phoneNumber, error $e');
      return false;
    }
  }

  /// Opens Telegram chat with a username
  ///
  /// [username] - The Telegram username (without @)
  /// Returns true if successfully launched, false otherwise
  static Future<bool> openTelegram(String username) async {
    try {
      final cleanUsername = username.replaceAll('@', '');
      final telegramUrl = 'https://t.me/$cleanUsername';
      return await openUrl(telegramUrl);
    } catch (e) {
      //debugPrint('Error opening Telegram: $username , error $e');
      return false;
    }
  }
}
