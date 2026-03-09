package com.swmansion.detour

import android.content.Context
import android.content.res.Resources
import android.os.Build
import android.util.Log
import android.view.WindowManager
import java.net.URLDecoder
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.atomic.AtomicBoolean

object DetourFingerprint {
    private const val TAG = "DetourFingerprint"

    private var cachedUserAgent: String? = null

    fun setCachedUserAgent(ua: String) {
        cachedUserAgent = ua.ifEmpty { null }
    }

    fun buildFingerprint(context: Context): Map<String, Any?> {
        val (width, height, density) = getScreenMetrics(context)
        val locale = Locale.getDefault()

        return mapOf(
            "platform" to "android",
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "systemVersion" to Build.VERSION.RELEASE,
            "screenWidth" to width,
            "screenHeight" to height,
            "scale" to density,
            "locale" to listOf(mapOf("languageTag" to locale.toLanguageTag())),
            "timezone" to TimeZone.getDefault().id,
            "userAgent" to cachedUserAgent,
            "timestamp" to System.currentTimeMillis(),
            "pastedLink" to null
        )
    }

    private data class ScreenMetrics(val width: Int, val height: Int, val density: Float)

    private fun getScreenMetrics(context: Context): ScreenMetrics {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            if (wm != null) {
                val bounds = wm.currentWindowMetrics.bounds
                val density = Resources.getSystem().displayMetrics.density
                return ScreenMetrics(
                    (bounds.width() / density).toInt(),
                    (bounds.height() / density).toInt(),
                    density
                )
            }
        }

        val dm = Resources.getSystem().displayMetrics
        return ScreenMetrics(
            (dm.widthPixels / dm.density).toInt(),
            (dm.heightPixels / dm.density).toInt(),
            dm.density
        )
    }

    fun getInstallReferrerClickId(
        context: Context,
        callback: (String?) -> Unit
    ) {
        try {
            val client = com.android.installreferrer.api.InstallReferrerClient.newBuilder(context).build()
            val completed = AtomicBoolean(false)

            fun resumeOnce(value: String?) {
                if (!completed.compareAndSet(false, true)) return
                try { client.endConnection() } catch (_: Exception) {}
                callback(value)
            }

            client.startConnection(object : com.android.installreferrer.api.InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    when (responseCode) {
                        com.android.installreferrer.api.InstallReferrerClient.InstallReferrerResponse.OK -> {
                            try {
                                val referrerUrl = client.installReferrer?.installReferrer
                                resumeOnce(extractClickId(referrerUrl))
                            } catch (e: Exception) {
                                Log.e(TAG, "Error reading install referrer", e)
                                resumeOnce(null)
                            }
                        }
                        else -> {
                            Log.w(TAG, "Install referrer response code: $responseCode")
                            resumeOnce(null)
                        }
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    Log.w(TAG, "Install referrer service disconnected")
                    resumeOnce(null)
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Error getting install referrer", e)
            callback(null)
        }
    }

    private fun extractClickId(referrerUrl: String?): String? {
        if (referrerUrl.isNullOrEmpty()) return null
        return try {
            val decodedUrl = URLDecoder.decode(referrerUrl, "UTF-8")
            val regex = Regex("(?:^|&)click_id=([^&]+)")
            regex.find(decodedUrl)?.groupValues?.getOrNull(1)
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting click_id", e)
            null
        }
    }
}
