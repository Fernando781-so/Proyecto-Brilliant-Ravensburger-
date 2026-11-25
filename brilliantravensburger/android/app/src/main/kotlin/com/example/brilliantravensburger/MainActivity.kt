package com.example.brilliantravensburger

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.brilliantravensburger/session_lifecycle"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(
                    SessionCleanupService.PREFS_NAME,
                    Context.MODE_PRIVATE
                )
                when (call.method) {
                    "startSessionMonitor" -> {
                        val token = call.argument<String>("token")
                        val logoutUrl = call.argument<String>("logoutUrl")
                        if (!token.isNullOrEmpty() && !logoutUrl.isNullOrEmpty()) {
                            prefs.edit()
                                .putString(SessionCleanupService.KEY_ACTIVE_TOKEN, token)
                                .putString(SessionCleanupService.KEY_LOGOUT_URL, logoutUrl)
                                .putBoolean(SessionCleanupService.KEY_CLOSED_FROM_RECENTS, false)
                                .remove(SessionCleanupService.KEY_PENDING_LOGOUT_TOKEN)
                                .apply()
                            val serviceIntent = Intent(this, SessionCleanupService::class.java).apply {
                                putExtra(SessionCleanupService.KEY_ACTIVE_TOKEN, token)
                                putExtra(SessionCleanupService.KEY_LOGOUT_URL, logoutUrl)
                            }
                            try {
                                startService(serviceIntent)
                            } catch (_: Exception) {
                            }
                        }
                        result.success(null)
                    }
                    "stopSessionMonitor" -> {
                        prefs.edit()
                            .remove(SessionCleanupService.KEY_ACTIVE_TOKEN)
                            .remove(SessionCleanupService.KEY_LOGOUT_URL)
                            .putBoolean(SessionCleanupService.KEY_CLOSED_FROM_RECENTS, false)
                            .remove(SessionCleanupService.KEY_PENDING_LOGOUT_TOKEN)
                            .apply()
                        try {
                            stopService(Intent(this, SessionCleanupService::class.java))
                        } catch (_: Exception) {
                        }
                        result.success(null)
                    }
                    "consumePendingLogout" -> {
                        val closed = prefs.getBoolean(
                            SessionCleanupService.KEY_CLOSED_FROM_RECENTS,
                            false
                        )
                        val pendingToken = prefs.getString(
                            SessionCleanupService.KEY_PENDING_LOGOUT_TOKEN,
                            null
                        )
                        prefs.edit()
                            .putBoolean(SessionCleanupService.KEY_CLOSED_FROM_RECENTS, false)
                            .remove(SessionCleanupService.KEY_PENDING_LOGOUT_TOKEN)
                            .apply()
                        result.success(
                            mapOf(
                                "closedFromRecents" to closed,
                                "pendingToken" to pendingToken
                            )
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
