package com.swmansion.detour

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class DetourAnalytics {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private var apiKey: String = ""
    private var appID: String = ""
    private var deviceId: String = ""
    private var isMounted = false

    fun mount(apiKey: String, appID: String, deviceId: String) {
        if (isMounted) return
        isMounted = true
        this.apiKey = apiKey
        this.appID = appID
        this.deviceId = deviceId
        logRetention("app_open")
    }

    fun unmount() {
        isMounted = false
    }

    fun logEvent(eventName: String, data: Map<String, Any>?) {
        if (!isMounted) {
            android.util.Log.w("Detour", "DetourAnalytics.logEvent called but analytics is not mounted. Event dropped.")
            return
        }
        val key = apiKey
        val id = appID
        val deviceId = deviceId
        scope.launch {
            DetourNetwork.sendEvent(key, id, deviceId, eventName, data)
        }
    }

    fun logRetention(eventName: String) {
        if (!isMounted) {
            android.util.Log.w("Detour", "DetourAnalytics.logRetention called but analytics is not mounted. Event dropped.")
            return
        }
        val key = apiKey
        val id = appID
        val deviceId = deviceId
        scope.launch {
            DetourNetwork.sendRetention(key, id, deviceId, eventName)
        }
    }
}
