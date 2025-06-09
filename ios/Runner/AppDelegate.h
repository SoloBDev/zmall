#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <EthiopiaPaySDK/EthiopiaPayManager.h>

@interface AppDelegate : FlutterAppDelegate <EthiopiaPayManagerDelegate>
@property(nonatomic, strong) FlutterMethodChannel *channel;
@property(nonatomic, strong) FlutterResult pendingResult;

@end




// #import <Flutter/Flutter.h>
// #import <UIKit/UIKit.h>

// @interface AppDelegate : FlutterAppDelegate

// @end
