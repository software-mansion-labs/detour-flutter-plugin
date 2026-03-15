package com.swmansion.detour

import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

object DetourNetwork {
    private const val BASE_URL = "https://godetour.dev"
    private const val MATCH_LINK_PATH = "/api/link/match-link"
    private const val RESOLVE_SHORT_PATH = "/api/link/resolve-short"
    private const val EVENT_PATH = "/api/analytics/event"
    private const val RETENTION_PATH = "/api/analytics/retention"

    data class DetourResultData(
        val url: String,
        val route: String,
        val pathname: String,
        val params: Map<String, String>,
        val type: String
    )

    fun matchLink(
        apiKey: String,
        appID: String,
        fingerprint: Map<String, Any?>
    ): DetourResultData? {
        return try {
            val body = mapToJson(fingerprint).toString()
            val responseJson = post("$BASE_URL$MATCH_LINK_PATH", apiKey, appID, body) ?: return null
            val linkStr = responseJson.optString("link", null.toString())
            if (linkStr == null || linkStr == "null" || linkStr.isEmpty()) return null
            parseUrl(linkStr, typeOverride = "deferred")
        } catch (e: Exception) {
            android.util.Log.e("Detour", "matchLink error: ${e.message}")
            null
        }
    }

    fun resolveShortLink(
        apiKey: String,
        appID: String,
        url: String
    ): DetourResultData? {
        return try {
            val body = JSONObject().put("url", url).toString()
            val responseJson = post("$BASE_URL$RESOLVE_SHORT_PATH", apiKey, appID, body) ?: return null
            val linkStr = responseJson.optString("link", null.toString())
            if (linkStr == null || linkStr == "null" || linkStr.isEmpty()) return null
            parseUrl(linkStr)
        } catch (e: Exception) {
            android.util.Log.e("Detour", "resolveShortLink error: ${e.message}")
            null
        }
    }

    fun sendEvent(
        apiKey: String,
        appID: String,
        deviceId: String,
        eventName: String,
        data: Map<String, Any?>?,
        platform: String = "android"
    ) {
        try {
            val body = JSONObject().apply {
                put("event_name", eventName)
                put("timestamp", java.time.Instant.now().toString())
                put("platform", platform)
                put("device_id", deviceId)
                if (data != null) {
                    put("data", mapToJson(data))
                }
            }.toString()
            post("$BASE_URL$EVENT_PATH", apiKey, appID, body)
        } catch (e: Exception) {
            android.util.Log.e("Detour", "sendEvent error: ${e.message}")
        }
    }

    fun sendRetention(
        apiKey: String,
        appID: String,
        deviceId: String,
        eventName: String,
        platform: String = "android"
    ) {
        try {
            val body = JSONObject().apply {
                put("event_name", eventName)
                put("timestamp", java.time.Instant.now().toString())
                put("platform", platform)
                put("device_id", deviceId)
            }.toString()
            post("$BASE_URL$RETENTION_PATH", apiKey, appID, body)
        } catch (e: Exception) {
            android.util.Log.e("Detour", "sendRetention error: ${e.message}")
        }
    }

    fun parseUrl(raw: String, typeOverride: String? = null): DetourResultData {
        val normalized = if (raw.startsWith("//")) "https:$raw" else raw
        val looksLikeUrl = raw.contains("://") || raw.startsWith("//")

        if (!looksLikeUrl) {
            val path = if (raw.startsWith("/")) raw else "/$raw"
            val parts = path.split("?", limit = 2)
            val pathname = parts[0]
            val query = if (parts.size > 1) parts[1] else null
            val params = parseQueryParams(query)
            val route = pathname + (if (query != null) "?$query" else "")
            return DetourResultData(
                url = path,
                route = route,
                pathname = pathname,
                params = params,
                type = typeOverride ?: "verified"
            )
        }

        return try {
            val url = java.net.URI(normalized).toURL()
            val scheme = url.protocol?.lowercase() ?: ""
            val isWeb = scheme == "http" || scheme == "https"
            val type = typeOverride ?: (if (isWeb) "verified" else "scheme")

            val route: String
            val pathname: String
            val params: Map<String, String>

            if (isWeb) {
                val fullPath = url.path ?: "/"
                val restOfPath = getRestOfPath(fullPath)
                val query = url.query
                route = restOfPath + (if (query != null) "?$query" else "")
                pathname = restOfPath
                params = parseQueryParams(query)
            } else {
                val host = url.host ?: ""
                val path = url.path ?: ""
                val query = url.query
                val combined = host + path + (if (query != null) "?$query" else "")
                route = if (combined.startsWith("/")) combined else "/$combined"
                pathname = route.split("?", limit = 2)[0]
                params = parseQueryParams(query)
            }

            DetourResultData(
                url = raw,
                route = route,
                pathname = pathname,
                params = params,
                type = type
            )
        } catch (e: Exception) {
            DetourResultData(
                url = raw,
                route = raw,
                pathname = raw,
                params = emptyMap(),
                type = typeOverride ?: "verified"
            )
        }
    }

    private fun getRestOfPath(pathname: String): String {
        if (pathname.length < 2) return "/"
        val searchFrom = 1
        val secondSlash = pathname.indexOf('/', searchFrom)
        return if (secondSlash >= 0) pathname.substring(secondSlash) else "/"
    }

    private fun parseQueryParams(query: String?): Map<String, String> {
        if (query.isNullOrEmpty()) return emptyMap()
        val result = mutableMapOf<String, String>()
        for (pair in query.split("&")) {
            val parts = pair.split("=", limit = 2)
            val key = java.net.URLDecoder.decode(parts[0], "UTF-8")
            val value = if (parts.size > 1) java.net.URLDecoder.decode(parts[1], "UTF-8") else ""
            result[key] = value
        }
        return result
    }

    private fun post(urlStr: String, apiKey: String, appID: String, body: String): JSONObject? {
        val url = URL(urlStr)
        val conn = url.openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setRequestProperty("Authorization", "Bearer $apiKey")
        conn.setRequestProperty("X-App-ID", appID)
        conn.doOutput = true
        conn.connectTimeout = 10_000
        conn.readTimeout = 10_000

        OutputStreamWriter(conn.outputStream).use { it.write(body) }

        val code = conn.responseCode
        if (code == 404) return null
        if (code !in 200..299) {
            android.util.Log.e("Detour", "HTTP $code from $urlStr")
            return null
        }

        val response = conn.inputStream.bufferedReader().readText()
        return JSONObject(response)
    }

    private fun mapToJson(map: Map<String, Any?>): JSONObject {
        val json = JSONObject()
        for ((k, v) in map) {
            when (v) {
                null -> json.put(k, JSONObject.NULL)
                is Map<*, *> -> json.put(k, mapToJson(@Suppress("UNCHECKED_CAST") (v as Map<String, Any?>)))
                is List<*> -> {
                    val arr = org.json.JSONArray()
                    for (item in v) {
                        when (item) {
                            null -> arr.put(JSONObject.NULL)
                            is Map<*, *> -> arr.put(mapToJson(@Suppress("UNCHECKED_CAST") (item as Map<String, Any?>)))
                            else -> arr.put(item)
                        }
                    }
                    json.put(k, arr)
                }
                else -> json.put(k, v)
            }
        }
        return json
    }
}
