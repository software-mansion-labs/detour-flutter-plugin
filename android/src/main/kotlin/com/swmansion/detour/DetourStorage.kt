package com.swmansion.detour

import android.content.Context
import java.util.UUID

class DetourStorage(context: Context) {
    companion object {
        private const val PREFS_NAME = "DetourPrefs"
        private const val KEY_FIRST_ENTRANCE = "Detour_firstEntranceFlag"
        private const val KEY_DEVICE_ID = "Detour_deviceId"
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isFirstEntrance(): Boolean = !prefs.getBoolean(KEY_FIRST_ENTRANCE, false)

    fun markFirstEntrance() = prefs.edit().putBoolean(KEY_FIRST_ENTRANCE, true).apply()

    fun resetFirstEntrance() = prefs.edit().putBoolean(KEY_FIRST_ENTRANCE, false).apply()

    fun getOrCreateDeviceId(): String {
        val existing = prefs.getString(KEY_DEVICE_ID, null)
        if (!existing.isNullOrEmpty()) return existing
        val newId = UUID.randomUUID().toString().lowercase()
        prefs.edit().putString(KEY_DEVICE_ID, newId).apply()
        return newId
    }
}
