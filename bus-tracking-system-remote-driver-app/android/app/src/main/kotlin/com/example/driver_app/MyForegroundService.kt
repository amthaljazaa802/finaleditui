package com.example.driver_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

class MyForegroundService : Service() {

    private lateinit var fusedClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null
    private var isTrackingStarted = false  // Flag to prevent multiple registrations
    private var wakeLock: PowerManager.WakeLock? = null
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    companion object {
        const val CHANNEL_ID = "driver_foreground_channel"
        const val NOTIF_ID = 1001
    }

    override fun onCreate() {
        super.onCreate()
        fusedClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
        
        // Acquire WakeLock to prevent CPU sleep
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "DriverApp::LocationWakeLock"
        )
        wakeLock?.acquire(10*60*60*1000L /*10 hours*/)
        android.util.Log.d("MyForegroundService", "WakeLock acquired")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val apiBase = intent?.getStringExtra("api_base_url")
        val authToken = intent?.getStringExtra("auth_token")
        val busId = intent?.getIntExtra("bus_id", -1) ?: -1

        android.util.Log.d("MyForegroundService", "onStartCommand: apiBase=$apiBase, busId=$busId, hasToken=${authToken != null}, isTrackingStarted=$isTrackingStarted")

        val notification = buildNotification("Tracking", "Bus #$busId tracking active")
        startForeground(NOTIF_ID, notification)

        // Check if this is a stop request (indicated by null extras or explicit flag)
        if (intent?.getBooleanExtra("stop_service", false) == true) {
            android.util.Log.d("MyForegroundService", "Stop request received, stopping service")
            stopSelf()
            return START_NOT_STICKY
        }

        // Only start location updates if not already started
        if (!isTrackingStarted) {
            startLocationUpdates(apiBase, authToken, busId)
            isTrackingStarted = true
        } else {
            android.util.Log.d("MyForegroundService", "Location tracking already started, ignoring duplicate call")
        }

        return START_STICKY
    }

    private fun startLocationUpdates(apiBase: String?, authToken: String?, busId: Int) {
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1_000L)
            .setMinUpdateIntervalMillis(1_000L)  // تحديث كل ثانية للحصول على تتبع فوري
            .setMaxUpdateDelayMillis(500L)       // إرسال التحديثات بسرعة (نصف ثانية)
            .setMinUpdateDistanceMeters(0f)      // 0 = إرسال حتى لو لم تتحرك
            .setWaitForAccurateLocation(false)   // عدم الانتظار للدقة العالية
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                val location = result.lastLocation ?: return
                val lat = location.latitude
                val lon = location.longitude
                android.util.Log.d("MyForegroundService", "Got location: lat=$lat, lon=$lon")
                val json = JSONObject()
                json.put("latitude", lat)
                json.put("longitude", lon)
                json.put("speed", location.speed)
                json.put("timestamp", System.currentTimeMillis())
                val url = if (apiBase != null && busId != -1) "$apiBase/api/buses/$busId/update-location/" else null
                if (url != null && authToken != null) {
                    android.util.Log.d("MyForegroundService", "Posting to: $url")
                    postLocation(url, authToken, json.toString())
                } else {
                    android.util.Log.w("MyForegroundService", "Missing URL or token, cannot post")
                }
            }
        }

        try {
            fusedClient.requestLocationUpdates(request, locationCallback!!, Looper.getMainLooper())
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
    }

    private fun postLocation(url: String, token: String, jsonBody: String) {
        val body = jsonBody.toRequestBody("application/json; charset=utf-8".toMediaTypeOrNull())
        val request = Request.Builder()
            .url(url)
            .post(body)
            .addHeader("Authorization", "Token $token")
            .addHeader("ngrok-skip-browser-warning", "true")
            .build()
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                android.util.Log.e("MyForegroundService", "POST failed: ${e.message}", e)
                // TODO: queue/retry logic here
            }

            override fun onResponse(call: Call, response: Response) {
                val statusCode = response.code
                val bodySnippet = response.body?.string()?.take(200) ?: ""
                android.util.Log.d("MyForegroundService", "POST response: status=$statusCode, body=$bodySnippet")
                if (!response.isSuccessful) {
                    android.util.Log.w("MyForegroundService", "POST unsuccessful: $statusCode")
                    // TODO: queue for retry
                }
                response.close()
            }
        })
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, 
                "Driver Tracking", 
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String, content: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)  // Prevent user from dismissing
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        android.util.Log.d("MyForegroundService", "🛑 onDestroy called - stopping service")
        isTrackingStarted = false
        
        // Remove location updates first
        try {
            locationCallback?.let { 
                fusedClient.removeLocationUpdates(it)
                locationCallback = null
                android.util.Log.d("MyForegroundService", "✅ Location updates removed")
            }
        } catch (e: Exception) {
            android.util.Log.e("MyForegroundService", "❌ Error removing location updates: ${e.message}")
        }
        
        // Release WakeLock
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    android.util.Log.d("MyForegroundService", "✅ WakeLock released")
                }
                wakeLock = null
            }
        } catch (e: Exception) {
            android.util.Log.e("MyForegroundService", "❌ Error releasing WakeLock: ${e.message}")
        }
        
        // Stop foreground
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
            android.util.Log.d("MyForegroundService", "✅ Foreground notification removed")
        } catch (e: Exception) {
            android.util.Log.e("MyForegroundService", "❌ Error stopping foreground: ${e.message}")
        }
        
        android.util.Log.d("MyForegroundService", "✅ Service fully stopped")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
