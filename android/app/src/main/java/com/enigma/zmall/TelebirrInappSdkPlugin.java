// package com.enigma.zmall;

// import android.util.Log;
// import androidx.annotation.NonNull;
// import androidx.fragment.app.FragmentActivity;
// import com.huawei.ethiopia.pay.sdk.api.core.data.PayInfo;
// import com.huawei.ethiopia.pay.sdk.api.core.listener.PayCallback;
// import com.huawei.ethiopia.pay.sdk.api.core.utils.PaymentManager;
// import io.flutter.embedding.engine.plugins.FlutterPlugin;
// import io.flutter.embedding.engine.plugins.activity.ActivityAware;
// import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
// import io.flutter.plugin.common.MethodCall;
// import io.flutter.plugin.common.MethodChannel;
// import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
// import io.flutter.plugin.common.MethodChannel.Result;
// import java.util.Map;
// import java.util.HashMap;


// public class TelebirrInappSdkPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
//     private static final String CHANNEL = "telebirrInAppSdkChannel";
//     private static final String TAG = "TelebirrInAppSdk";
//     private MethodChannel channel;
//     private FragmentActivity activity;

//     @Override
//     public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
//         channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL);
//         channel.setMethodCallHandler(this);
//     }

//     @Override
//     public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
//         if ("placeOrder".equals(call.method)) {
//             placeOrder(call, result);
//         } else {
//             result.notImplemented();
//         }
//     }

//     private void placeOrder(@NonNull MethodCall call, @NonNull Result result) {
//         try {
//             String receiveCode = call.argument("receiveCode");
//             String appId = call.argument("appId");
//             String shortCode = call.argument("shortCode");

//             if (receiveCode == null || appId == null || shortCode == null) {
//                 result.error("INVALID_ARGUMENTS", "Required parameters missing", "receiveCode, appId, and shortCode are required");
//                 return;
//             }

//             if (activity == null) {
//                 result.error("NO_ACTIVITY", "Activity is not available", null);
//                 return;
//             }

//             PayInfo payInfo = new PayInfo.Builder()
//                     .setAppId(appId)
//                     .setShortCode(shortCode)
//                     .setReceiveCode(receiveCode)
//                     .build();

//             try {
//                 PaymentManager.getInstance().pay(activity, payInfo);
//                 PaymentManager.getInstance().setPayCallback(new PayCallback() {
//                     @Override
//                     public void onPayCallback(int code, String errMsg) {
//                         // Log.d(TAG, "onPayCallback: code " + code + " errMsg " + errMsg);
//                         // activity.runOnUiThread(() -> {
//                         //     if (code == 0) {
//                         //         result.success("status" : "SUCCESS", "code": code);
//                         //     } else {
//                         //         // result.error("PAYMENT_FAILED", errMsg, null);
//                         //         result.error("status" :"FAILED", "errMsg":errMsg, "code": code);
//                         //     }

//                         // });
//                         activity.runOnUiThread(() -> {
//                         Map<String, Object> resultMap = new HashMap<>();
//                         resultMap.put("code", code);
//                         resultMap.put("errMsg", errMsg);

//                             if (code == 0) {
//                                 resultMap.put("status", "SUCCESS");
//                                 result.success(resultMap);  // Success result with the map
//                             } else {
//                                 resultMap.put("status", "FAILED");
//                                 result.error("PAYMENT_FAILED", errMsg, resultMap);  // Failure result with the map
//                             }
//                     });
//                     }
//                 });
//             } catch (Exception e) {
//                 Log.e(TAG, "Error during payment", e);
//                 result.error("PAYMENT_ERROR", "Error during payment", e.getMessage());
//             }
//         } catch (Exception e) {
//             Log.e(TAG, "Error in placeOrder", e);
//             result.error("UNEXPECTED_ERROR", "An unexpected error occurred", e.getMessage());
//         }
//     }

//     @Override
//     public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
//         channel.setMethodCallHandler(null);
//     }

//     @Override
//     public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
//         activity = (FragmentActivity) binding.getActivity();
//     }

//     @Override
//     public void onDetachedFromActivityForConfigChanges() {
//         activity = null;
//     }

//     @Override
//     public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
//         activity = (FragmentActivity) binding.getActivity();
//     }

//     @Override
//     public void onDetachedFromActivity() {
//         activity = null;
//     }
// }