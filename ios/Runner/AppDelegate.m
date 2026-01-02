#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <GoogleMaps/GoogleMaps.h>
#import <EthiopiaPaySDK/EthiopiaPayManager.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Google Maps initialization
    [GMSServices provideAPIKey:@"AIzaSyDAgZScAJfUHxahi_n4OpuI8HrTHVlirJk"];

    [GeneratedPluginRegistrant registerWithRegistry:self];

    // Use FlutterPluginRegistry API instead of accessing window.rootViewController
    NSObject<FlutterPluginRegistrar>* registrar =
        [self registrarForPlugin:@"TelebirrInAppSdkPlugin"];
    self.channel = [FlutterMethodChannel methodChannelWithName:@"telebirrInAppSdkChannel"
                                               binaryMessenger:registrar.messenger];

    __weak typeof(self) weakSelf = self;
    [self.channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        // NSLog(@"Received method call from Flutter: %@", call.method);
        if ([call.method isEqualToString:@"placeOrder"]) {
            NSDictionary *args = call.arguments;
            NSString *appId = args[@"appId"];
            NSString *shortCode = args[@"shortCode"];
            NSString *receiveCode = args[@"receiveCode"];

            if (!appId || !shortCode || !receiveCode) {
                // NSLog(@"Error: Missing parameters - appId: %@, shortCode: %@, receiveCode: %@", appId, shortCode, receiveCode);
                result(@{@"code": @(-1), @"message": @"Missing or invalid parameters"});
                return;
            }

            // NSLog(@"Placing order with appId: %@, shortCode: %@, receiveCode: %@", appId, shortCode, receiveCode);
            weakSelf.pendingResult = result;

            EthiopiaPayManager *manager = [EthiopiaPayManager sharedManager];
            manager.delegate = weakSelf;
            // NSLog(@"Starting payment with appId: %@, shortCode: %@, receiveCode: %@", appId, shortCode, receiveCode);
            [manager startPayWithAppId:appId shortCode:shortCode receiveCode:receiveCode returnAppScheme:@"zmallreturn"];
        } else {
            // NSLog(@"Method not implemented: %@", call.method);
            result(FlutterMethodNotImplemented);
        }
    }];


    // Setup security method channel for screenshot detection and protection
    NSObject<FlutterPluginRegistrar>* securityRegistrar =
        [self registrarForPlugin:@"SecurityPlugin"];
    self.securityChannel = [FlutterMethodChannel methodChannelWithName:@"com.zmall.user/security"
                                                        binaryMessenger:securityRegistrar.messenger];

    // Initialize protection state
    self.isProtectionEnabled = NO;

    // Handle method calls from Flutter
    [self.securityChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        if ([call.method isEqualToString:@"enableScreenshotProtection"]) {
            weakSelf.isProtectionEnabled = YES;
            result(@YES);
        } else if ([call.method isEqualToString:@"disableScreenshotProtection"]) {
            weakSelf.isProtectionEnabled = NO;
            result(@YES);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];

    // Listen for screenshot notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidTakeScreenshot:)
                                                 name:UIApplicationUserDidTakeScreenshotNotification
                                               object:nil];

    // Listen for screen recording/mirroring changes (iOS 11+)
    if (@available(iOS 11.0, *)) {
        [[UIScreen mainScreen] addObserver:self
                                 forKeyPath:@"captured"
                                    options:NSKeyValueObservingOptionNew
                                    context:nil];
    }

    // Listen for app state changes to show/hide overlay
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    // NSLog(@"Handling open URL: %@", url);
    [[EthiopiaPayManager sharedManager] handleOpenURL:url];
    return YES;
}

- (void)payResultCallbackWithCode:(NSInteger)code msg:(NSString *)msg {
    // NSLog(@"Payment result - Code: %ld, Message: %@", (long)code, msg);
    if (self.pendingResult) {
        NSDictionary *result = @{
            @"code": @(code),
            @"message": msg ?: @""
        };
        self.pendingResult(result);
        self.pendingResult = nil;
    }
}

#pragma mark - Screenshot Protection Methods

// Called when user takes a screenshot
- (void)userDidTakeScreenshot:(NSNotification *)notification {
    if (self.isProtectionEnabled) {
        // Notify Flutter immediately to show overlay
        // Flutter will handle the black screen UI
        [self.securityChannel invokeMethod:@"screenshotTaken" arguments:nil];
    }
}

// Called when screen recording state changes
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"captured"]) {
        BOOL isCaptured = [[UIScreen mainScreen] isCaptured];

        // Notify Flutter about screen capture state
        // Flutter will handle showing/hiding overlay
        [self.securityChannel invokeMethod:@"screenCaptureChanged" arguments:@(isCaptured)];
    }
}

// Called when app is about to go to background
- (void)applicationWillResignActive:(NSNotification *)notification {
    if (self.isProtectionEnabled) {
        // Notify Flutter to show overlay for app switcher
        [self.securityChannel invokeMethod:@"appWillResignActive" arguments:nil];
    }
}

// Called when app becomes active again
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.isProtectionEnabled) {
        // Notify Flutter to hide overlay
        [self.securityChannel invokeMethod:@"appDidBecomeActive" arguments:nil];
    }
}

// Cleanup observers
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (@available(iOS 11.0, *)) {
        [[UIScreen mainScreen] removeObserver:self forKeyPath:@"captured"];
    }
}

@end





// #import "AppDelegate.h"
// #import "GeneratedPluginRegistrant.h"
// #import "GoogleMaps/GoogleMaps.h"


// @implementation AppDelegate

// - (BOOL)application:(UIApplication *)application
//     didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//     [GMSServices provideAPIKey:@"AIzaSyDAgZScAJfUHxahi_n4OpuI8HrTHVlirJk"];

//   [GeneratedPluginRegistrant registerWithRegistry:self];
//   // Override point for customization after application launch.
//   return [super application:application didFinishLaunchingWithOptions:launchOptions];
// }

// @end

/////////////////Unoffical (Not supported by apple, shich is jail-braking )/////////////////////////
//  NSObject<FlutterPluginRegistrar>* securityRegistrar =
//         [self registrarForPlugin:@"SecurityPlugin"];
//     self.securityChannel = [FlutterMethodChannel methodChannelWithName:@"com.zmall.user/security"
//                                                         binaryMessenger:securityRegistrar.messenger];

//     [self.securityChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
//         if ([call.method isEqualToString:@"disableScreenshot"]) {
//             @try {
//                 // iOS screenshot prevention using secure text field trick
//                 if (weakSelf.secureTextField == nil) {
//                     weakSelf.secureTextField = [[UITextField alloc] init];
//                     weakSelf.secureTextField.secureTextEntry = YES;

//                     UIView *view = weakSelf.window.rootViewController.view;
//                     [view addSubview:weakSelf.secureTextField];
//                     [view.layer.superlayer addSublayer:weakSelf.secureTextField.layer];

//                     if (weakSelf.secureTextField.layer.superlayer) {
//                         [weakSelf.secureTextField.layer.superlayer addSublayer:view.layer];
//                     }
//                 }
//                 // NSLog(@"Screenshot prevention ENABLED on iOS");
//                 result(@YES);
//             } @catch (NSException *exception) {
//                 // NSLog(@"Failed to disable screenshot: %@", exception.reason);
//                 result([FlutterError errorWithCode:@"ERROR"
//                                            message:@"Failed to disable screenshot"
//                                            details:exception.reason]);
//             }
//         } else if ([call.method isEqualToString:@"enableScreenshot"]) {
//             @try {
//                 // Remove the secure text field to allow screenshots
//                 if (weakSelf.secureTextField != nil) {
//                     [weakSelf.secureTextField removeFromSuperview];
//                     weakSelf.secureTextField = nil;
//                 }
//                 // NSLog(@"Screenshot prevention DISABLED on iOS");
//                 result(@YES);
//             } @catch (NSException *exception) {
//                 // NSLog(@"Failed to enable screenshot: %@", exception.reason);
//                 result([FlutterError errorWithCode:@"ERROR"
//                                            message:@"Failed to enable screenshot"
//                                            details:exception.reason]);
//             }
//         } else {
//             result(FlutterMethodNotImplemented);
//         }
//     }];
///////////////////////////////////////////////////////////////