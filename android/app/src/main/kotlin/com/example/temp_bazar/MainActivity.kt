package com.example.bazar_suez

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Must be called before super.onCreate so Android 12+ uses our splash logo
        // instead of falling back to the launcher icon on real devices.
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
