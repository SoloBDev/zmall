#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <EthiopiaPaySDK/EthiopiaPayManager.h>

@interface AppDelegate : FlutterAppDelegate <EthiopiaPayManagerDelegate>
@property(nonatomic, strong) FlutterMethodChannel *channel;
@property(nonatomic, strong) FlutterResult pendingResult;
@property(nonatomic, strong) FlutterMethodChannel *securityChannel;
@property(nonatomic, strong) UITextField *secureTextField;

// Screenshot protection properties
@property(nonatomic, strong) UIView *blackOverlay;
@property(nonatomic, assign) BOOL isProtectionEnabled;

@end
