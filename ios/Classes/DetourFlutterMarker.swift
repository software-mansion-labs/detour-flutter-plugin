// CONTRACT: The native iOS SDK (DetourIOS) discovers this class by name via
// NSClassFromString in DetourConstants.swift. Do NOT rename this class or the
// sdkHeaderValue property without updating the native SDK.

import Foundation

// Native iOS SDK looks up this marker class and reads the final X-SDK value directly.
// We keep the version explicit here because static CocoaPods linking places plugin code
// in the host app bundle, so bundle-based version lookup would read the app version.
@objc(DetourFlutterMarker)
public final class DetourFlutterMarker: NSObject {
    @objc public static let sdkHeaderValue = "flutter/1.1.1"
}
