// package com.enigma.zmall;

// import io.flutter.embedding.android.FlutterFragmentActivity;
// import io.flutter.embedding.android.FlutterActivity;
// import io.flutter.embedding.engine.FlutterEngine;
// import io.flutter.plugins.GeneratedPluginRegistrant;

// public class MainActivity extends FlutterFragmentActivity {

//      @Override
//     public void configureFlutterEngine(FlutterEngine flutterEngine) {
//         super.configureFlutterEngine(flutterEngine);
//         flutterEngine.getPlugins().add(new TelebirrInappSdkPlugin());  // <-- Manually registering the plugin
//     }
// }














































// // package com.enigma.zmall;

// // import android.os.Bundle;
// // import android.util.Log;
// // import android.widget.Toast;

// // import androidx.annotation.NonNull;

// // import io.flutter.embedding.android.FlutterFragmentActivity;
// // import io.flutter.embedding.engine.FlutterEngine;
// // import io.flutter.plugin.common.MethodCall;
// // import io.flutter.plugin.common.MethodChannel;
// // import io.flutter.plugin.common.MethodChannel.Result;
// // import io.flutter.embedding.android.FlutterActivity;

// // import com.huawei.ethiopia.pay.sdk.api.core.data.PayInfo;
// // import com.huawei.ethiopia.pay.sdk.api.core.listener.PayCallback;
// // import com.huawei.ethiopia.pay.sdk.api.core.utils.PaymentManager;
// // //import com.ethiotelecom.telebirr.customer.uat;

// // import java.text.SimpleDateFormat;
// // import java.util.Date;
// // import java.util.Locale;

// // public class MainActivity extends FlutterFragmentActivity {
// //     private static final String CHANNEL = "telebirrInAppSdkChannel";
// //     private static final String TAG = "TeleBirrInAppPay";
// //     private MethodChannel channel;

// //     @Override
// //     public void configureFlutterEngine(FlutterEngine flutterEngine) {
// //         super.configureFlutterEngine(flutterEngine);
// //         channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
// //         channel.setMethodCallHandler(new MethodChannel.MethodCallHandler() {

// //             @Override
// //             public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
// //                 if (call.method.equals("placeOrder")) {
                  
// //                     placeOrder(call, result);
// //                 } else {
// //                     result.notImplemented();
// //                 }
// //             }
// //         });
// //     }

// //  private void placeOrder(@NonNull MethodCall call, @NonNull Result result) {
// //         try {
// //               // Get order info from Flutter app
// //             String receiveCode = call.argument("receiveCode");
// //             String appId = call.argument("appId");
// //             String shortCode = call.argument("shortCode");
          
// //              // Step 6	Then invoke the SDK API to start the payment.
// //            final PayInfo payInfo = new PayInfo.Builder()
// //                .setAppId(appId)
// //                .setShortCode(shortCode)
// //                .setReceiveCode(receiveCode)
// //                .build();
// //         PaymentManager.getInstance().pay(this, payInfo);

// //             // Step 7	Listen to the payment callback.
// //         PaymentManager.getInstance().setPayCallback(new PayCallback() {
// //         @Override
// //         public void onPayCallback(int code, String errMsg) {
// //                Log.d(TAG, "onPayCallback: code "+ code +" errMsg " + errMsg);
// //             //    Toast.makeText(MainActivity.this, code + errMsg, Toast.LENGTH_SHORT).show();
// //         }
// //      });
// //    }catch (Exception e) {
// //             Log.e(TAG, "Error: ", e);
// //             result.error("PAYMENT_ERROR", "Error placing order", e.getMessage());
// //         }
// //     }
// //  }