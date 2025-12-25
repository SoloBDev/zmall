# ZMall Magazine Feature

A secure magazine reader feature that allows users to read PDF magazines with screenshot prevention and no download/share capabilities.

## Features

✅ **Secure PDF Reading** - Read magazines without ability to screenshot, share, or download
✅ **Book-like Experience** - Tap left/right to turn pages with smooth animations
✅ **Category Filtering** - Browse magazines by category
✅ **Network Loading** - Load PDFs from remote URLs
✅ **Screenshot Prevention** - Native Android implementation to prevent screenshots
✅ **Beautiful UI** - Magazine cards with cover images, categories, and page counts

## Installation

### 1. Add Required Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  pdfx: ^2.6.0  # For PDF rendering
```

Then run:
```bash
flutter pub get
```

### 2. Android Setup (Already Configured)

The Android screenshot prevention has been added to `MainActivity.kt`. It uses `FLAG_SECURE` to prevent screenshots and screen recording.

### 3. iOS Setup (Optional)

For iOS screenshot prevention, add the following to your `AppDelegate.swift`:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let SECURITY_CHANNEL = "com.zmall.user/security"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let securityChannel = FlutterMethodChannel(name: SECURITY_CHANNEL,
                                                   binaryMessenger: controller.binaryMessenger)

        securityChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "disableScreenshot" || call.method == "enableScreenshot" else {
                result(FlutterMethodNotImplemented)
                return
            }

            // Note: iOS doesn't have built-in screenshot prevention
            // You can detect screenshots but can't prevent them
            result(true)
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

## Usage

### Navigate to Magazine List

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const MagazineListScreen(),
  ),
);
```

### Open a Specific Magazine

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => MagazineReaderScreen(magazine: magazine),
  ),
);
```

## API Integration

Update `magazine_service.dart` to integrate with your backend API:

```dart
static Future<List<Magazine>> fetchMagazines() async {
  final response = await http.get(
    Uri.parse('$BASE_URL/api/magazines'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final magazines = (jsonData['magazines'] as List)
        .map((mag) => Magazine.fromJson(mag))
        .toList();
    return magazines;
  } else {
    throw Exception('Failed to load magazines');
  }
}
```

## API Response Format

Expected JSON format:

```json
{
  "success": true,
  "magazines": [
    {
      "id": "1",
      "title": "ZMall Monthly - January 2025",
      "description": "Discover the latest products and deals",
      "cover_image": "magazines/covers/jan_2025.jpg",
      "pdf_url": "magazines/pdfs/jan_2025.pdf",
      "page_count": 24,
      "category": "Monthly",
      "published_date": "2025-01-01T00:00:00Z",
      "is_new": true,
      "tags": ["Featured", "New Year", "Deals"]
    }
  ]
}
```

## File Structure

```
lib/home/magazine/
├── models/
│   └── magazine_model.dart          # Magazine data model
├── screens/
│   ├── magazine_list_screen.dart    # List of all magazines
│   └── magazine_reader_screen.dart  # PDF reader with security
├── widgets/
│   └── magazine_card.dart           # Magazine card component
├── services/
│   └── magazine_service.dart        # API service for magazines
└── README.md                        # This file
```

## Security Features

### Screenshot Prevention (Android)
- **Conditional Protection**: Only enabled when `is_protected: true` in magazine data
- Uses `FLAG_SECURE` to prevent screenshots and screen recording
- Automatically enabled when opening a protected magazine
- Automatically disabled when closing the magazine or switching to non-protected content
- **Visual Indicators**: Shows "PROTECTED" badge on magazine cards and in reader

### No Download/Share
- PDF viewer has no download or share buttons
- Users can only read the content within the app
- Navigation restricted to left/right page turns

### Content Protection
- PDFs are loaded from secure URLs
- Smart lazy loading with prefetching for optimal performance
- Page-by-page rendering prevents bulk extraction

### ⚠️ Important Security Notes

**Emulator Limitations:**
- Android emulators may bypass `FLAG_SECURE` using the emulator's built-in screenshot button
- This is a **known Android emulator limitation**, not a bug in the implementation
- **Screenshot prevention WORKS on real Android devices** (phones/tablets)
- Always test security features on physical devices, not emulators

**Testing Screenshot Prevention:**
1. ✅ **Real Device**: FLAG_SECURE blocks all screenshot attempts (system buttons, apps, etc.)
2. ❌ **Emulator**: Emulator screenshot button may bypass FLAG_SECURE (expected behavior)
3. ✅ **Screen Recording**: Blocked on both real devices and some emulators

## Customization

### Change Colors

Update the colors in `magazine_reader_screen.dart` and `magazine_card.dart`:

```dart
// Primary color
const Color(0xFFED2437)  // ZMall Red

// Background
Colors.black  // Reader background
kWhiteColor   // List background
```

### Modify Page Turn Animation

In `magazine_reader_screen.dart`, adjust the animation:

```dart
_pdfController.nextPage(
  duration: const Duration(milliseconds: 300),  // Change duration
  curve: Curves.easeInOut,  // Change curve
);
```

### Add More Categories

Update the categories list in `magazine_list_screen.dart`:

```dart
final List<String> categories = [
  'All',
  'Monthly',
  'Food',
  'Technology',
  'Fashion',
  'Your New Category',  // Add here
];
```

## Troubleshooting

### PDF Not Loading
- Check that the PDF URL is accessible
- Verify internet connection
- Check console for error messages

### Screenshot Prevention Not Working
- Ensure MainActivity.kt changes are compiled
- Run `flutter clean && flutter build apk`
- Test on a physical Android device (emulator may not respect FLAG_SECURE)

### Image Not Showing
- Verify cover_image URL is correct
- Check that images are accessible from the device
- Ensure proper BASE_URL configuration in constants.dart

## Future Enhancements

- [ ] Bookmarking favorite pages
- [ ] Search within magazine content
- [ ] Offline reading mode (with encrypted storage)
- [ ] Reading progress tracking
- [ ] Annotations and highlights (saved server-side only)
- [ ] Magazine recommendations

## Notes

- iOS does not support true screenshot prevention at the OS level
- Consider implementing server-side analytics to track suspicious behavior
- For maximum security, use DRM-protected PDFs
- Test thoroughly on physical devices, not emulators

---

Created for ZMall - Secure Magazine Reading Experience
