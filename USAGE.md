# Detour Flutter Plugin — Usage

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  detour_flutter_plugin:
    path: ../detour_flutter_plugin  # or pub.dev package name once published
```

---

## Setup

### 1. Configure

Call `configure` once at app startup, before any other Detour calls. A good place is `main()` or the root widget's `initState`.

```dart
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';

final _detour = DetourFlutterPlugin();

await _detour.configure(
  const DetourConfig(
    apiKey: 'YOUR_API_KEY',
    appID: 'YOUR_APP_ID',
    shouldUseClipboard: true,              // default: true
    linkProcessingMode: LinkProcessingMode.all, // default: all
  ),
);
```

#### `DetourConfig` fields

| Field | Type | Default | Description |
|---|---|---|---|
| `apiKey` | `String` | required | Your Detour API key |
| `appID` | `String` | required | Your Detour app ID |
| `shouldUseClipboard` | `bool` | `true` | Allow clipboard-based deferred link matching (iOS only) |
| `linkProcessingMode` | `LinkProcessingMode` | `all` | Which link types to handle (see below) |

#### `LinkProcessingMode` values

| Value | Description |
|---|---|
| `LinkProcessingMode.all` | Handle all link types (deferred, universal/app links, custom schemes) |
| `LinkProcessingMode.webOnly` | Only handle web links (universal/app links) |
| `LinkProcessingMode.deferredOnly` | Only perform deferred deep link matching on first launch |

---

## Deferred Deep Links

### 2. Resolve the initial link

Call `resolveInitialLink` after `configure` to check if the app was installed via a Detour link. On first launch, this performs fingerprint-based deferred matching.

```dart
final result = await _detour.resolveInitialLink();

if (result.link != null) {
  final link = result.link!;
  // Navigate based on link.route or link.pathname
  print('type: ${link.type}');       // LinkType.deferred
  print('route: ${link.route}');     // e.g. "/products/123?color=red"
  print('pathname: ${link.pathname}'); // e.g. "/products/123"
  print('params: ${link.params}');   // e.g. {color: red}
  print('url: ${link.url}');         // original full URL
}
```

---

## Runtime Deep Links

### 3. Listen to the link stream

Subscribe to `linkStream` to receive links opened while the app is already running (universal links, app links, custom scheme URLs).

```dart
final _linkSub = _detour.linkStream.listen((result) {
  if (result.link != null) {
    _navigateTo(result.link!.route);
  }
});

// Cancel when done (e.g. in dispose())
_linkSub.cancel();
```

### 4. Process a link manually

Call `processLink` to resolve any URL on demand (e.g. from a push notification payload or in-app button).

```dart
final result = await _detour.processLink(
  'https://link.example.com/abc123',
);

if (result.link != null) {
  _navigateTo(result.link!.route);
}
```

---

## Models

### `DetourResult`

```dart
class DetourResult {
  final bool processed; // true if this session was already handled
  final DetourLink? link; // null if no link was matched
}
```

### `DetourLink`

```dart
class DetourLink {
  final String url;       // original full URL
  final String route;     // path + query, e.g. "/products/123?color=red"
  final String pathname;  // path only, e.g. "/products/123"
  final Map<String, String> params; // parsed query params
  final LinkType type;    // deferred | verified | scheme
}
```

### `LinkType`

| Value | Description |
|---|---|
| `LinkType.deferred` | Matched via fingerprint on first launch |
| `LinkType.verified` | Opened via a verified web link (universal/app link) |
| `LinkType.scheme` | Opened via a custom URL scheme |

---

## Analytics

### Mount / unmount

Analytics must be mounted before logging events. Call `mountAnalytics` after configure and once your navigation is ready. Call `unmountAnalytics` when analytics should stop (e.g. logged-out state).

```dart
await _detour.mountAnalytics();

// later, if needed:
await _detour.unmountAnalytics();
```

### Log a standard event

Use `DetourEventName` for standard event names, or pass a raw string.

```dart
// Standard event with data
await _detour.logEvent(
  DetourEventName.purchase.rawValue,
  data: {'value': 9.99, 'currency': 'USD'},
);

// Standard event without data
await _detour.logEvent(DetourEventName.login.rawValue);

// Custom event name
await _detour.logEvent('level_complete', data: {'level': 5});
```

#### Standard event names (`DetourEventName`)

| Enum | Raw value |
|---|---|
| `login` | `login` |
| `search` | `search` |
| `share` | `share` |
| `signUp` | `sign_up` |
| `tutorialBegin` | `tutorial_begin` |
| `tutorialComplete` | `tutorial_complete` |
| `reEngage` | `re_engage` |
| `invite` | `invite` |
| `openedFromPushNotification` | `opened_from_push_notification` |
| `addPaymentInfo` | `add_payment_info` |
| `addShippingInfo` | `add_shipping_info` |
| `addToCart` | `add_to_cart` |
| `removeFromCart` | `remove_from_cart` |
| `refund` | `refund` |
| `viewItem` | `view_item` |
| `beginCheckout` | `begin_checkout` |
| `purchase` | `purchase` |
| `adImpression` | `ad_impression` |

### Log a retention event

Use `logRetention` for session-level events that track user re-engagement (e.g. screen views, session starts).

```dart
await _detour.logRetention('home_screen_viewed');
await _detour.logRetention('session_start');
```

---

## Session Management

### Reset session

Call `resetSession` to clear the handled-session flag. Pass `allowDeferredRetry: true` to also re-run deferred link matching on the next `resolveInitialLink` call — useful for testing.

```dart
// Reset session state only
await _detour.resetSession();

// Reset and allow deferred matching to run again
await _detour.resetSession(allowDeferredRetry: true);
```

---

## Full Example

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

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
        apiKey: 'YOUR_API_KEY',
        appID: 'YOUR_APP_ID',
        shouldUseClipboard: true,
        linkProcessingMode: LinkProcessingMode.all,
      ),
    );

    // Handle deferred link on first launch
    final initial = await _detour.resolveInitialLink();
    if (initial.link != null) {
      _navigateTo(initial.link!.route);
    }

    // Handle links while app is running
    _linkSub = _detour.linkStream.listen((result) {
      if (result.link != null) {
        _navigateTo(result.link!.route);
      }
    });

    // Start analytics
    await _detour.mountAnalytics();
    await _detour.logRetention('app_open');
  }

  void _navigateTo(String route) {
    // Use your router here, e.g. GoRouter or Navigator
    debugPrint('[Detour] navigate to $route');
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold());
}
```
