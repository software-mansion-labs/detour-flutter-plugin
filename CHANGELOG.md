## 1.0.0

* Stable release.
* Set up automated pub.dev publishing via GitHub Actions (OIDC).
* Clean up `pubspec.yaml`: add topics, issue tracker, remove boilerplate.

## 0.1.0

* Refactor plugin into a thin bridge over native Detour SDKs.
* Android now consumes `com.swmansion:detour` instead of embedded native implementation.
* iOS now consumes `Detour` CocoaPod instead of embedded native implementation.
* Remove Flutter API methods without 1:1 native equivalent: `mountAnalytics`, `unmountAnalytics`, `resetSession`.
* `logEvent` now accepts only predefined `DetourEventName` values.
* Refresh unit/integration/example tests to match the current API.
* Add `DetourService` helper for routing-safe integration (`resolveInitialLink` + `linkStream` merge, consume semantics, short duplicate suppression window).
