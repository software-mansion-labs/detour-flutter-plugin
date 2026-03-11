## 0.0.1

* Refactor plugin into a thin bridge over native Detour SDKs.
* Android now consumes `com.swmansion:detour` instead of embedded native implementation.
* iOS now consumes `Detour` CocoaPod instead of embedded native implementation.
* Remove Flutter API methods without 1:1 native equivalent: `mountAnalytics`, `unmountAnalytics`, `resetSession`.
* `logEvent` now accepts only predefined `DetourEventName` values.
* Refresh unit/integration/example tests to match the current API.
