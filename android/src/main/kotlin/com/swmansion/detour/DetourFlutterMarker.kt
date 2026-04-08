// CONTRACT: The native Android SDK (android-detour) discovers this class by name
// via reflection in FlutterSdkHeaderResolver.kt. Do NOT rename this class or the
// SDK_HEADER_VALUE field without updating the native SDK.

package com.swmansion.detour

// Native SDK detects this marker via reflection to tag requests as Flutter-originated.
object DetourFlutterMarker {
    @JvmField
    val SDK_HEADER_VALUE: String = BuildConfig.FLUTTER_SDK_HEADER_VALUE
}
