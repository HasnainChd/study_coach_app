package com.devorastudio.studycoach

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "study_coach_app/notifications"

    companion object {
        // Matches FlutterLocalNotificationsPlugin.SCHEDULED_NOTIFICATIONS
        private const val SCHEDULED_NOTIFICATIONS_PREFS = "scheduled_notifications"
        private const val SCHEDULED_NOTIFICATIONS_KEY = "scheduled_notifications"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "isPostNotificationsGranted" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            val granted = ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.POST_NOTIFICATIONS,
                            ) == PackageManager.PERMISSION_GRANTED
                            result.success(granted)
                        } else {
                            result.success(true)
                        }
                    }
                    "clearScheduledNotificationsCache" -> {
                        clearScheduledNotificationsCache()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun clearScheduledNotificationsCache() {
        val prefsOld = getSharedPreferences(
            SCHEDULED_NOTIFICATIONS_PREFS,
            Context.MODE_PRIVATE,
        )
        prefsOld.edit().remove(SCHEDULED_NOTIFICATIONS_KEY).apply()

        val prefsNew = getSharedPreferences(
            "notification_plugin_cache",
            Context.MODE_PRIVATE,
        )
        prefsNew.edit().remove("scheduled_notifications").apply()
    }
}
