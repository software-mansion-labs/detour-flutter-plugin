<img src="https://github.com/user-attachments/assets/c965b51b-7307-477a-8d22-9c9cd6da6231" alt="Flutter Detour by Software Mansion" width="100%"/>

# Flutter Detour

SDK for handling deferred links in Flutter.

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

No additional dependencies are required. Platform-specific setup (install referrer on Android, Universal Links and clipboard on iOS) is handled by the plugin automatically.

## Usage

### Initialize the plugin

Create a single `DetourFlutterPlugin` instance and call `configure()` once at app startup:

```dart
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';

final _detour = DetourFlutterPlugin();

await _detour.configure(
  const DetourConfig(
    apiKey: '<REPLACE_WITH_YOUR_API_KEY>',
    appID: '<REPLACE_WITH_APP_ID_FROM_PLATFORM>',
    shouldUseClipboard: true,
  ),
);
```

### Resolve the initial link (deferred deep links)

```dart
final result = await _detour.resolveInitialLink();

if (result.link != null) {
  navigateTo(result.link!.route);
}
```

### Listen for runtime links

```dart
final _linkSub = _detour.linkStream.listen((result) {
  if (result.link != null) {
    navigateTo(result.link!.route);
  }
});

// Cancel in dispose()
_linkSub.cancel();
```

### Full example

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';

class _MyAppState extends State<MyApp> {
  final _detour = DetourFlutterPlugin();
  StreamSubscription<DetourResult>? _linkSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _detour.configure(
      const DetourConfig(
        apiKey: '<REPLACE_WITH_YOUR_API_KEY>',
        appID: '<REPLACE_WITH_APP_ID_FROM_PLATFORM>',
        shouldUseClipboard: true,
      ),
    );

    final initial = await _detour.resolveInitialLink();
    if (initial.link != null) {
      navigateTo(initial.link!.route);
    }

    _linkSub = _detour.linkStream.listen((result) {
      if (result.link != null) {
        navigateTo(result.link!.route);
      }
    });

    await _detour.mountAnalytics();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }
}
```

Learn more about usage from our [docs](https://docs.swmansion.com/detour/docs/flutter-sdk/flutter-sdk-usage).

### Controlling which links Detour processes

Use `linkProcessingMode` to control which link sources the SDK listens to:

| Value | Universal/App Links | Deferred links | Custom scheme links |
|---|---|---|---|
| `LinkProcessingMode.all` (default) | ✅ | ✅ | ✅ |
| `LinkProcessingMode.webOnly` | ✅ | ✅ | ❌ |
| `LinkProcessingMode.deferredOnly` | ❌ | ✅ | ❌ |

```dart
await _detour.configure(
  const DetourConfig(
    apiKey: '<REPLACE_WITH_YOUR_API_KEY>',
    appID: '<REPLACE_WITH_APP_ID_FROM_PLATFORM>',
    // Process Universal/App links and deferred links, but let your own
    // navigation layer handle custom scheme links (e.g. myapp://...).
    linkProcessingMode: LinkProcessingMode.webOnly,
  ),
);
```

## Types

### DetourConfig

```dart
class DetourConfig {
  /// Your API key from the Detour dashboard.
  final String apiKey;

  /// Your app ID from the Detour dashboard.
  final String appID;

  /// Whether to check the clipboard for a deferred link.
  /// iOS-only — on Android the clipboard is never accessed.
  /// Defaults to true.
  final bool shouldUseClipboard;

  /// Controls which link sources are handled by the SDK.
  /// - all: deferred links + Universal/App links + custom scheme links (default)
  /// - webOnly: deferred links + Universal/App links, but NOT custom scheme links
  /// - deferredOnly: only deferred links
  final LinkProcessingMode linkProcessingMode;
}
```

### DetourResult

```dart
class DetourResult {
  /// true if this session has already been handled.
  final bool processed;

  /// The resolved link, or null if nothing was matched.
  final DetourLink? link;
}
```

### DetourLink

```dart
class DetourLink {
  /// The original full URL.
  final String url;

  /// Full route path including query string (e.g. '/details/42?campaign=summer').
  final String route;

  /// Route path without query string (e.g. '/details/42').
  final String pathname;

  /// Parsed query parameters (e.g. {'campaign': 'summer'}).
  final Map<String, String> params;

  /// The type of the detected link:
  /// - deferred: resolved from the Detour API on first app install
  /// - verified: Universal Link (iOS) or App Link (Android)
  /// - scheme: custom scheme deep link (only when linkProcessingMode is all)
  final LinkType type;
}
```

---

## License

This library is licensed under [The MIT License](./LICENSE).

## Flutter Detour is created by Software Mansion

Since 2012, [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects?utm_source=detour&utm_medium=readme).

[![swm](https://logo.swmansion.com/logo?color=white&variant=desktop&width=150&tag=react-native-executorch-github 'Software Mansion')](https://swmansion.com)
