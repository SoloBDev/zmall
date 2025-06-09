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
    FlutterViewController *controller = (FlutterViewController *)self.window.rootViewController;
    self.channel = [FlutterMethodChannel methodChannelWithName:@"telebirrInAppSdkChannel" binaryMessenger:controller.binaryMessenger];

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
