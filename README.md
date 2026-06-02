<img src="https://github.com/user-attachments/assets/c965b51b-7307-477a-8d22-9c9cd6da6231" alt="Detour Flutter Plugin by Software Mansion" width="100%"/>

[![Ad](https://revive-adserver.swmansion.com/www/images/zone-gh-flutter-detour-1?n=1)](https://revive-adserver.swmansion.com/www/delivery/ck.php?zoneid=zone-gh-flutter-detour-1&n=1)
[![Ad](https://revive-adserver.swmansion.com/www/images/zone-gh-flutter-detour-2?n=1)](https://revive-adserver.swmansion.com/www/delivery/ck.php?zoneid=zone-gh-flutter-detour-2&n=1)
[![Ad](https://revive-adserver.swmansion.com/www/images/zone-gh-flutter-detour-3?n=1)](https://revive-adserver.swmansion.com/www/delivery/ck.php?zoneid=zone-gh-flutter-detour-3&n=1)

# Detour Flutter Plugin

Detour Flutter Plugin wraps the native Detour SDKs for Android and iOS, giving Flutter apps access to deferred deep linking. A deferred link works like a regular deep link, but survives the Play Store or App Store install — a user who clicks a link before having the app installed is redirected to the right screen on first launch. The plugin also handles Universal/App Links and custom scheme links in a single unified API.

## Quick links

- Documentation: [https://detour.swmansion.com/docs/](https://detour.swmansion.com/docs/)
- Installation guide: [https://detour.swmansion.com/docs/sdk/flutter/sdk-installation](https://detour.swmansion.com/docs/sdk/flutter/sdk-installation)

## Create an account

You need a Detour account to generate app credentials and configure your links.  
Sign up here: [https://godetour.dev/auth/signup](https://godetour.dev/auth/signup)

## Installation

### Package

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  detour_flutter_plugin: ^1.2.0
```

Then run `flutter pub get`.

### Native SDK dependencies

This plugin uses native Detour SDK implementations:

- Android: `com.swmansion.detour:detour-sdk:1.1.0`
- iOS: `Detour` CocoaPod `~> 1.1.0` (pulled automatically via the plugin podspec)

#### Android

Make sure your Android repositories can resolve `com.swmansion.detour:detour-sdk` (for example via `google()` and `mavenCentral()` in your project repositories block).

#### iOS

The native iOS SDK is resolved automatically as a CocoaPods dependency. Just run:

```sh
cd ios && pod install && cd ..
```

### Requirements

- Dart: `^3.11.1`
- Flutter: `>=3.3.0`
- Android: min SDK 24
- iOS: 13.0+

## Usage

### Recommended: `DetourService`

`DetourService` is the recommended integration layer. It extends `ChangeNotifier` and merges initial and runtime link handling into a single pending intent with explicit consume semantics.

<details>
<summary>DetourService example</summary>

```dart
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';

final detour = DetourService();

@override
void initState() {
  super.initState();
  detour.addListener(_onDetourChanged);
  _startDetour();
}

Future<void> _startDetour() async {
  await detour.start(
    const DetourConfig(
      apiKey: '<REPLACE_WITH_YOUR_API_KEY>',
      appID: '<REPLACE_WITH_APP_ID_FROM_PLATFORM>',
    ),
  );
}

void _onDetourChanged() {
  final intent = detour.pendingIntent;
  if (intent == null) return;

  // Navigate once, then mark as consumed.
  // context.go(intent.link.route);
  detour.consumePendingIntent();
}

@override
void dispose() {
  detour.removeListener(_onDetourChanged);
  detour.dispose();
  super.dispose();
}
```

</details>

### Low-level API: `DetourFlutterPlugin`

For full manual control, use `DetourFlutterPlugin` directly:

<details>
<summary>DetourFlutterPlugin example</summary>

```dart
final plugin = DetourFlutterPlugin();

await plugin.configure(
  const DetourConfig(
    apiKey: '<REPLACE_WITH_YOUR_API_KEY>',
    appID: '<REPLACE_WITH_APP_ID_FROM_PLATFORM>',
  ),
);

final initial = await plugin.resolveInitialLink();
final stream = plugin.linkStream;
final processed = await plugin.processLink('https://example.com/path');
```

</details>

### Link processing mode

Use `linkProcessingMode` to control which link sources the SDK handles:

| Value                          | Universal/App links | Deferred links | Custom scheme links |
| ------------------------------ | ------------------- | -------------- | ------------------- |
| `LinkProcessingMode.all` (default) | ✅             | ✅             | ✅                  |
| `LinkProcessingMode.webOnly`   | ✅                  | ✅             | ❌                  |
| `LinkProcessingMode.deferredOnly` | ❌               | ✅             | ❌                  |

### Custom scheme runtime links

Custom scheme links require `linkProcessingMode: LinkProcessingMode.all` and native registration on each platform.

<details>
<summary>Native registration</summary>

Android (`AndroidManifest.xml`):

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="myapp" />
</intent-filter>
```

iOS (`Info.plist`):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

Test commands:

```sh
# Android
adb shell am start -a android.intent.action.VIEW \
  -d "myapp://products/42?source=scheme" \
  <your.package.name>

# iOS Simulator
xcrun simctl openurl booted "myapp://products/42?source=scheme"
```

</details>

## Analytics

<details>
<summary>Analytics example</summary>

```dart
await detour.logEvent(
  DetourEventName.purchase,
  data: {'value': 9.99, 'currency': 'USD'},
);

await detour.logRetention('week_1');
```

</details>

See the [analytics docs](https://detour.swmansion.com/docs/) for the full event list and retention tracking setup.

## Types

### `DetourConfig`

<details>
<summary>DetourConfig</summary>

```dart
class DetourConfig {
  final String apiKey;
  final String appID;
  final bool shouldUseClipboard;        // default: true
  final LinkProcessingMode linkProcessingMode;  // default: LinkProcessingMode.all
}
```

</details>

### `DetourIntent`

<details>
<summary>DetourIntent</summary>

```dart
class DetourIntent {
  final DetourLink link;
  final DetourIntentSource source;  // initial, runtime, or manual
  final DateTime receivedAt;
}

enum DetourIntentSource { initial, runtime, manual }
```

</details>

### `DetourResult`

<details>
<summary>DetourResult</summary>

```dart
class DetourResult {
  final bool processed;
  final DetourLink? link;
}
```

</details>

### `DetourLink`

<details>
<summary>DetourLink</summary>

```dart
class DetourLink {
  final String url;
  final String route;
  final String pathname;
  final Map<String, String> params;
  final LinkType type;  // deferred, verified, or scheme
}
```

</details>

### `DetourEventName`

<details>
<summary>DetourEventName</summary>

```dart
enum DetourEventName {
  login, search, share, signUp, tutorialBegin, tutorialComplete,
  reEngage, invite, openedFromPushNotification, addPaymentInfo,
  addShippingInfo, addToCart, removeFromCart, refund, viewItem,
  beginCheckout, purchase, adImpression,
}
```

</details>

## API Reference

### `DetourService`

High-level integration helper (extends `ChangeNotifier`):

- `Future<void> start(DetourConfig config)`
- `bool get isStarted`
- `bool get isInitialLinkProcessed`
- `DetourIntent? get pendingIntent`
- `void consumePendingIntent()`
- `Future<DetourResult> processLink(String url, {bool emitIntent = true})`
- `Future<void> logEvent(DetourEventName eventName, {Map<String, dynamic>? data})`
- `Future<void> logRetention(String eventName)`
- `Future<void> stop()`

### `DetourFlutterPlugin`

Low-level bridge API:

- `Future<void> configure(DetourConfig config)`
- `Future<DetourResult> resolveInitialLink()`
- `Stream<DetourResult> get linkStream`
- `Future<DetourResult> processLink(String url)`
- `Future<void> logEvent(DetourEventName eventName, {Map<String, dynamic>? data})`
- `Future<void> logRetention(String eventName)`

## Example

A complete integration example covering deferred links, Universal/App Links, and custom scheme links is in [`example/`](./example). See the [example setup guide](./example/README.md) for step-by-step instructions.

## Other Detour SDKs

Detour is also available for other app stacks:

- Android SDK: [https://github.com/software-mansion-labs/android-detour](https://github.com/software-mansion-labs/android-detour)
- iOS SDK: [https://github.com/software-mansion-labs/ios-detour](https://github.com/software-mansion-labs/ios-detour)
- React Native SDK: [https://github.com/software-mansion-labs/react-native-detour](https://github.com/software-mansion-labs/react-native-detour)

---

## License

This library is licensed under [The MIT License](./LICENSE).

## Detour Flutter Plugin is created by Software Mansion

Since 2012, [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects?utm_source=detour&utm_medium=readme).

[![swm](https://logo.swmansion.com/logo?color=white&variant=desktop&width=150&tag=detour-flutter-github "Software Mansion")](https://swmansion.com)
