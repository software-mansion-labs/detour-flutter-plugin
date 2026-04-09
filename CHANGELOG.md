## 1.1.1

* Override native `X-SDK` header to `flutter/<plugin-version>` when requests are made via the Flutter wrapper.
* Update native SDK requirements to Android `1.0.1` and iOS `1.0.2`.

## 1.1.0

* iOS native SDK is now consumed via CocoaPods (`Detour ~> 1.0.1`) instead of bundled source files.
* Remove embedded iOS SDK sources (`ios/Sources/Detour/`).
* Improve example app with configurable placeholders and setup documentation.

## 1.0.1

* Fix Android Maven dependency coordinates to `com.swmansion.detour:detour-sdk`.

## 1.0.0

* Refactor plugin into a thin bridge over native Detour SDKs.
* Android now consumes `com.swmansion.detour:detour-sdk` instead of embedded native implementation.
* iOS now consumes `Detour` CocoaPod instead of embedded native implementation.
* Remove Flutter API methods without 1:1 native equivalent: `mountAnalytics`, `unmountAnalytics`, `resetSession`.
* `logEvent` now accepts only predefined `DetourEventName` values.
* Refresh unit/integration/example tests to match the current API.
* Add `DetourService` helper for routing-safe integration (`resolveInitialLink` + `linkStream` merge, consume semantics, short duplicate suppression window).
