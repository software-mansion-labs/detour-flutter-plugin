## 1.3.0

- **Breaking:** minimum iOS version raised from 13.0 to 15.0, following the native iOS SDK. Set `platform :ios, '15.0'` (or higher) in your app's `Podfile`.
- **Behavior change:** `route` and `pathname` stay percent-encoded on both platforms (`/hello%20world`, not `/hello world`). Decode them yourself if you compare them with plain strings.
- Update native SDK requirements to Android `1.1.1` and iOS `1.1.2`.
- Link parsing now works the same on Android and iOS. Params ignore the URL fragment (`?id=5#section` → `id: "5"`), and a stray `%` (`?a=50%off`) no longer breaks parsing.
- iOS: the native SDK now ships its own privacy manifest. Deferred-link clipboard matching sends only the copied URL, not the text around it.

## 1.2.1

- Fix Android release builds failing. The plugin's Android namespace is now `com.swmansion.detour.flutter`, so it no longer collides with the native SDK.
- Keep `DetourFlutterMarker` in R8-minified Android builds so requests are reported as `flutter/<plugin-version>`.

## 1.2.0

- Improve universal link analytics.
- Update native SDK requirements to Android `1.1.0` and iOS `1.1.0`.

## 1.1.1

- Override native `X-SDK` header to `flutter/<plugin-version>` when requests are made via the Flutter wrapper.
- Update native SDK requirements to Android `1.0.1` and iOS `1.0.2`.

## 1.1.0

- iOS native SDK is now consumed via CocoaPods (`Detour ~> 1.0.1`) instead of bundled source files.
- Remove embedded iOS SDK sources (`ios/Sources/Detour/`).
- Improve example app with configurable placeholders and setup documentation.

## 1.0.1

- Fix Android Maven dependency coordinates to `com.swmansion.detour:detour-sdk`.

## 1.0.0

- Refactor plugin into a thin bridge over native Detour SDKs.
- Android now consumes `com.swmansion.detour:detour-sdk` instead of embedded native implementation.
- iOS now consumes `Detour` CocoaPod instead of embedded native implementation.
- Remove Flutter API methods without 1:1 native equivalent: `mountAnalytics`, `unmountAnalytics`, `resetSession`.
- `logEvent` now accepts only predefined `DetourEventName` values.
- Refresh unit/integration/example tests to match the current API.
- Add `DetourService` helper for routing-safe integration (`resolveInitialLink` + `linkStream` merge, consume semantics, short duplicate suppression window).
