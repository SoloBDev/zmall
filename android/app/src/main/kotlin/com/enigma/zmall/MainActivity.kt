package com.enigma.zmall

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

//edge to edge
import androidx.core.view.WindowCompat
import android.os.Bundle

class MainActivity : FlutterFragmentActivity() {


    ///edge-to-edge display
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable edge-to-edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(TelebirrInappSdkPlugin())  // Manually registering the plugin
    }
}