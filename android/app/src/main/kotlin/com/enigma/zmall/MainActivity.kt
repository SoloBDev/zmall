package com.enigma.zmall

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel

//edge to edge
import androidx.core.view.WindowCompat
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterFragmentActivity() {

    private val SECURITY_CHANNEL = "com.zmall.user/security"

    ///edge-to-edge display
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable edge-to-edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(TelebirrInappSdkPlugin())  // Manually registering the plugin


        // Setup security method channel for screenshot prevention
        // Android: Uses FLAG_SECURE (complete prevention)
        // iOS: Uses detection and Flutter overlay
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableScreenshotProtection" -> {
                    try {
                        // Set FLAG_SECURE to prevent screenshots and screen recording
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        android.util.Log.d("MainActivity", "Screenshot protection ENABLED - FLAG_SECURE set")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Failed to enable protection: ${e.message}")
                        result.error("ERROR", "Failed to enable screenshot protection", e.message)
                    }
                }
                "disableScreenshotProtection" -> {
                    try {
                        // Clear FLAG_SECURE to allow screenshots again
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        android.util.Log.d("MainActivity", "Screenshot protection DISABLED - FLAG_SECURE cleared")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Failed to disable protection: ${e.message}")
                        result.error("ERROR", "Failed to disable screenshot protection", e.message)
                    }
                }
                // Keep old method names for backward compatibility
                "disableScreenshot" -> {
                    try {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to disable screenshot", e.message)
                    }
                }
                "enableScreenshot" -> {
                    try {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to enable screenshot", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}