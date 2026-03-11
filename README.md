<img src="https://github.com/user-attachments/assets/c965b51b-7307-477a-8d22-9c9cd6da6231" alt="Flutter Detour by Software Mansion" width="100%"/>

# Flutter Detour

Flutter SDK for handling deferred deep links with native Detour SDKs on Android and iOS.

## Documentation

Check out our documentation page for integration guides and API details:

- Docs home: [https://docs.swmansion.com/detour/docs/](https://docs.swmansion.com/detour/docs/)
- Flutter installation guide: [https://docs.swmansion.com/detour/docs/flutter-sdk/flutter-sdk-installation](https://docs.swmansion.com/detour/docs/flutter-sdk/flutter-sdk-installation)

## Create account on platform

Create account and configure your links: [https://godetour.dev/auth/signup](https://godetour.dev/auth/signup)

## Installation

### Package

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  detour_flutter_plugin: ^0.0.1
```

Install dependencies:

```sh
flutter pub get
```

### Native SDK dependencies

This plugin is a bridge over native Detour SDK artifacts:

- Android: `com.swmansion:detour:0.1.0`
- iOS: `Detour` pod (`>= 0.1.0`)

#### Android

Make sure your Android repositories can resolve `com.swmansion:detour`.  
For local development this usually means adding `mavenLocal()` in your app's Gradle repositories and publishing Android SDK locally.

#### iOS

If `Detour` pod is not in your remote specs yet, point `Podfile` to local `ios-detour` checkout:

```ruby
target 'Runner' do
  use_frameworks!

  detour_sdk_path = File.expand_path('../path/to/ios-detour', __dir__)
  if File.exist?(File.join(detour_sdk_path, 'Detour.podspec'))
    pod 'Detour', :path => detour_sdk_path
  end

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

Run pods:

```sh
cd ios
pod install
cd ..
```

## Usage

### Recommended integration with `DetourService`

`DetourService` is the recommended orchestration layer. It:

- configures SDK once,
- merges initial and runtime link handling into a single pending intent,
- exposes readiness via `isInitialLinkProcessed`,
- uses explicit consume semantics with `consumePendingIntent()`,
- suppresses short-window duplicate emissions.

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
      shouldUseClipboard: true,
      linkProcessingMode: LinkProcessingMode.all,
    ),
  );
}

void _onDetourChanged() {
  final intent = detour.pendingIntent;
  if (intent == null) return;

  // Route once, then mark as consumed.
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

### Link processing mode

Use `linkProcessingMode` to control which sources are handled by SDK:

| Value | Universal/App links | Deferred links | Custom scheme links |
|---|---|---|---|
| `LinkProcessingMode.all` (default) | ✅ | ✅ | ✅ |
| `LinkProcessingMode.webOnly` | ✅ | ✅ | ❌ |
| `LinkProcessingMode.deferredOnly` | ❌ | ✅ | ❌ |

### Custom scheme runtime links

Custom scheme links require:

- `linkProcessingMode: LinkProcessingMode.all`
- native registration on each platform

Android (`AndroidManifest.xml`):

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="detour-flutter-example" />
</intent-filter>
```

iOS (`Info.plist`):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>detour-flutter-example</string>
    </array>
  </dict>
</array>
```

Test commands:

```sh
# Android
adb shell am start -a android.intent.action.VIEW \
  -d "detour-flutter-example://products/42?source=scheme" \
  <your.package.name>

# iOS Simulator
xcrun simctl openurl booted "detour-flutter-example://products/42?source=scheme"
```

### Low-level API

If you need full manual control, use `DetourFlutterPlugin` directly:

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

## Analytics

Flutter API follows native SDK analytics contract:

- predefined events via `DetourEventName`,
- retention events as string names.

```dart
await detour.logEvent(
  DetourEventName.purchase,
  data: {'value': 9.99, 'currency': 'USD'},
);

await detour.logRetention('home_screen_viewed');
```

## Types

### `DetourConfig`

```dart
class DetourConfig {
  final String apiKey;
  final String appID;
  final bool shouldUseClipboard;
  final LinkProcessingMode linkProcessingMode;
}
```

### `DetourIntent`

```dart
class DetourIntent {
  final DetourLink link;
  final DetourIntentSource source;
  final DateTime receivedAt;
}
```

### `DetourResult`

```dart
class DetourResult {
  final bool processed;
  final DetourLink? link;
}
```

### `DetourLink`

```dart
class DetourLink {
  final String url;
  final String route;
  final String pathname;
  final Map<String, String> params;
  final LinkType type;
}
```

### `DetourEventName`

```dart
enum DetourEventName {
  login,
  search,
  share,
  signUp,
  tutorialBegin,
  tutorialComplete,
  reEngage,
  invite,
  openedFromPushNotification,
  addPaymentInfo,
  addShippingInfo,
  addToCart,
  removeFromCart,
  refund,
  viewItem,
  beginCheckout,
  purchase,
  adImpression,
}
```

## API Reference

### `DetourService`

High-level integration helper:

- `Future<void> start(DetourConfig config)`
- `DetourIntent? get pendingIntent`
- `void consumePendingIntent()`
- `bool get isInitialLinkProcessed`
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

## Requirements

- Dart: `^3.11.1`
- Flutter: `>=3.3.0`
- Android: min SDK 24
- iOS: 13.0+

## Example

A complete integration example is available in this repo:

- `example/`

## License

This library is licensed under [The MIT License](./LICENSE).

## Flutter Detour is created by Software Mansion

Since 2012, [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues. We can help you build your next dream product - [Hire us](https://swmansion.com/contact/projects?utm_source=detour&utm_medium=readme).

[![swm](https://logo.swmansion.com/logo?color=white&variant=desktop&width=150&tag=react-native-executorch-github 'Software Mansion')](https://swmansion.com)
