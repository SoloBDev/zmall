package com.enigma.zmall

import android.util.Log
import androidx.fragment.app.FragmentActivity
import com.huawei.ethiopia.pay.sdk.api.core.data.PayInfo
import com.huawei.ethiopia.pay.sdk.api.core.listener.PayCallback
import com.huawei.ethiopia.pay.sdk.api.core.utils.PaymentManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TelebirrInappSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        private const val CHANNEL = "telebirrInAppSdkChannel"
        private const val TAG = "TelebirrInAppSdk"
    }

    private lateinit var channel: MethodChannel
    private var activity: FragmentActivity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "placeOrder" -> placeOrder(call, result)
            else -> result.notImplemented()
        }
    }

    private fun placeOrder(call: MethodCall, result: Result) {
        try {
            val receiveCode = call.argument<String>("receiveCode")
            val appId = call.argument<String>("appId")
            val shortCode = call.argument<String>("shortCode")

            if (receiveCode == null || appId == null || shortCode == null) {
                result.error(
                    "INVALID_ARGUMENTS",
                    "Required parameters missing",
                    "receiveCode, appId, and shortCode are required"
                )
                return
            }

            val currentActivity = activity
            if (currentActivity == null) {
                result.error("NO_ACTIVITY", "Activity is not available", null)
                return
            }

            val payInfo = PayInfo.Builder()
                .setAppId(appId)
                .setShortCode(shortCode)
                .setReceiveCode(receiveCode)
                .build()

            try {
                PaymentManager.getInstance().pay(currentActivity, payInfo)
                PaymentManager.getInstance().setPayCallback(object : PayCallback {
                    override fun onPayCallback(code: Int, errMsg: String?) {
                        currentActivity.runOnUiThread {
                            val resultMap = mutableMapOf<String, Any?>()
                            resultMap["code"] = code
                            resultMap["errMsg"] = errMsg

                            if (code == 0) {
                                resultMap["status"] = "SUCCESS"
                                result.success(resultMap)
                            } else {
                                resultMap["status"] = "FAILED"
                                result.error("PAYMENT_FAILED", errMsg, resultMap)
                            }
                        }
                    }
                })
            } catch (e: Exception) {
                // Log.e(TAG, "Error during payment", e)
                result.error("PAYMENT_ERROR", "Error during payment", e.message)
            }
        } catch (e: Exception) {
            // Log.e(TAG, "Error in placeOrder", e)
            result.error("UNEXPECTED_ERROR", "An unexpected error occurred", e.message)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}