package com.example.driver_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Request battery optimization exemption on startup
        BatteryOptimizationHelper.requestIgnoreBatteryOptimizations(this)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "driver_app_channel",
                "Driver App Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
            // Also create the foreground service channel expected by background_service
            val fgChannel = NotificationChannel(
                "my_foreground_service",
                "Driver App Foreground Service",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(fgChannel)
        }

        // MethodChannel for starting/stopping the native foreground service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.driver_app/foreground").setMethodCallHandler { call, result ->
            when (call.method) {
                "startNativeService" -> {
                    val api = call.argument<String>("api_base_url")
                    val token = call.argument<String>("auth_token")
                    val busId = call.argument<Int>("bus_id") ?: -1
                    val intent = Intent(this, MyForegroundService::class.java).apply {
                        putExtra("api_base_url", api)
                        putExtra("auth_token", token)
                        putExtra("bus_id", busId)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        ContextCompat.startForegroundService(this, intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopNativeService" -> {
                    android.util.Log.d("MainActivity", "stopNativeService called")
                    // First, send stop intent to the service
                    val stopIntent = Intent(this, MyForegroundService::class.java).apply {
                        putExtra("stop_service", true)
                    }
                    startService(stopIntent)
                    
                    // Then call stopService to ensure it stops
                    val intent = Intent(this, MyForegroundService::class.java)
                    val stopped = stopService(intent)
                    android.util.Log.d("MainActivity", "stopService returned: $stopped")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
