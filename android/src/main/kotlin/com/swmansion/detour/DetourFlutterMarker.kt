package com.swmansion.detour

// Native SDK detects this marker via reflection to tag requests as Flutter-originated.
object DetourFlutterMarker {
    @JvmField
    val SDK_HEADER_VALUE: String = BuildConfig.FLUTTER_SDK_HEADER_VALUE
}
