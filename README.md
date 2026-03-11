<img src="https://github.com/user-attachments/assets/c965b51b-7307-477a-8d22-9c9cd6da6231" alt="Flutter Detour by Software Mansion" width="100%"/>

# Flutter Detour

Thin Flutter bridge for native Detour SDKs on Android and iOS.

## Create an account

You need a Detour account to generate app credentials and configure your links.
Sign up here: [https://godetour.dev/auth/signup](https://godetour.dev/auth/signup)

## Quick links

- Documentation: [https://docs.swmansion.com/detour/docs/](https://docs.swmansion.com/detour/docs/)
- Installation guide: [https://docs.swmansion.com/detour/docs/flutter-sdk/flutter-sdk-installation](https://docs.swmansion.com/detour/docs/flutter-sdk/flutter-sdk-installation)

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  detour_flutter_plugin: ^0.0.1
```

Then run:

```sh
flutter pub get
```

### Native SDK dependencies

This plugin depends on native Detour SDK artifacts:

- Android: `com.swmansion:detour`
- iOS: `Detour` CocoaPod

If those artifacts are not yet publicly published, point your app to local/native repositories.

Example `ios/Podfile` setup with a local checkout:

```ruby
target 'Runner' do
  use_frameworks!

  detour_ios_sdk_path = File.expand_path('../path/to/ios-detour', __dir__)
  if File.exist?(File.join(detour_ios_sdk_path, 'Detour.podspec'))
    pod 'Detour', :path => detour_ios_sdk_path
  end

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

## Usage

### Initialize once

```dart
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';

final detour = DetourFlutterPlugin();

await detour.configure(
  const DetourConfig(
    apiKey: '<REPLACE_WITH_YOUR_API_KEY>',
    appID: '<REPLACE_WITH_APP_ID_FROM_PLATFORM>',
    shouldUseClipboard: true,
  ),
);
```

### Resolve initial link (deferred + launch links)

```dart
final result = await detour.resolveInitialLink();
if (result.link != null) {
  navigateTo(result.link!.route);
}
```

### Listen for runtime links

```dart
final sub = detour.linkStream.listen((result) {
  if (result.link != null) {
    navigateTo(result.link!.route);
  }
});

// Cancel in dispose()
await sub.cancel();
```

### Analytics

`DetourFlutterPlugin` follows native SDK analytics lifecycle.

- No explicit `mountAnalytics` / `unmountAnalytics` / `resetSession` methods in Flutter API.
- Log predefined events via `DetourEventName` enum.
- Log retention events via free-form string.

```dart
await detour.logEvent(
  DetourEventName.addToCart,
  data: {'sku': 'ABC-123'},
);

await detour.logRetention('home_screen_viewed');
```

## Link processing mode

Use `linkProcessingMode` to control which link sources the SDK handles:

| Value | Universal/App Links | Deferred links | Custom scheme links |
|---|---|---|---|
| `LinkProcessingMode.all` (default) | Yes | Yes | Yes |
| `LinkProcessingMode.webOnly` | Yes | Yes | No |
| `LinkProcessingMode.deferredOnly` | No | Yes | No |

```dart
await detour.configure(
  const DetourConfig(
    apiKey: '<REPLACE_WITH_YOUR_API_KEY>',
    appID: '<REPLACE_WITH_APP_ID_FROM_PLATFORM>',
    linkProcessingMode: LinkProcessingMode.webOnly,
  ),
);
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

---

## License

This library is licensed under [The MIT License](./LICENSE).

## Flutter Detour is created by Software Mansion

Since 2012, [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues. We can help you build your next dream product - [Hire us](https://swmansion.com/contact/projects?utm_source=detour&utm_medium=readme).

[![swm](https://logo.swmansion.com/logo?color=white&variant=desktop&width=150&tag=react-native-executorch-github 'Software Mansion')](https://swmansion.com)
