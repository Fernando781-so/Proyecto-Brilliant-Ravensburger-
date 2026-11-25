package com.example.brilliantravensburger

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import java.net.HttpURLConnection
import java.net.URL

class SessionCleanupService : Service() {
    companion object {
        const val PREFS_NAME = "brilliant_session_lifecycle"
        const val KEY_ACTIVE_TOKEN = "active_token"
        const val KEY_LOGOUT_URL = "logout_url"
        const val KEY_CLOSED_FROM_RECENTS = "closed_from_recents"
        const val KEY_PENDING_LOGOUT_TOKEN = "pending_logout_token"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val token = intent?.getStringExtra(KEY_ACTIVE_TOKEN)
        val logoutUrl = intent?.getStringExtra(KEY_LOGOUT_URL)
        if (!token.isNullOrEmpty() && !logoutUrl.isNullOrEmpty()) {
            getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_ACTIVE_TOKEN, token)
                .putString(KEY_LOGOUT_URL, logoutUrl)
                .putBoolean(KEY_CLOSED_FROM_RECENTS, false)
                .remove(KEY_PENDING_LOGOUT_TOKEN)
                .apply()
        }
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val token = prefs.getString(KEY_ACTIVE_TOKEN, null)
        val logoutUrl = prefs.getString(KEY_LOGOUT_URL, null)

        if (token.isNullOrEmpty() || logoutUrl.isNullOrEmpty()) {
            stopSelf()
            super.onTaskRemoved(rootIntent)
            return
        }

        // Persistir de forma síncrona antes de que el sistema destruya el proceso.
        prefs.edit()
            .remove(KEY_ACTIVE_TOKEN)
            .putBoolean(KEY_CLOSED_FROM_RECENTS, true)
            .putString(KEY_PENDING_LOGOUT_TOKEN, token)
            .commit()

        val logoutThread = Thread {
            try {
                val connection = (URL(logoutUrl).openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 8000
                    readTimeout = 8000
                    setRequestProperty("Authorization", "Bearer $token")
                    doOutput = false
                }
                try {
                    val code = connection.responseCode
                    if (code == 200 || code == 401 || code == 403) {
                        prefs.edit()
                            .remove(KEY_PENDING_LOGOUT_TOKEN)
                            .commit()
                    }
                } finally {
                    connection.disconnect()
                }
            } catch (_: Exception) {
                // Si no hubo red al cerrar, queda pending_logout_token para reintentar al abrir.
            } finally {
                stopSelf()
            }
        }
        logoutThread.start()
        try {
            logoutThread.join(2500)
        } catch (_: InterruptedException) {
        }
        super.onTaskRemoved(rootIntent)
    }
}
