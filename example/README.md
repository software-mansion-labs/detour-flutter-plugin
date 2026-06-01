# Detour Flutter Plugin — Example App

This example demonstrates a full `DetourService` integration covering all three link types:

- **Deferred link** — resolved on first launch after install
- **Universal/App Link** — http/https link handled while the app is installed
- **Custom scheme link** — e.g. `detour-flutter-example://products/42`

The app displays separate intent cards for initial, runtime, and manually processed links, and includes buttons for triggering analytics events.

## Prerequisites

You need a Detour account with an app configured for both Android and iOS. Sign up at [godetour.dev](https://godetour.dev/auth/signup) if you haven't already.

## Setup

### 1. Create your app in the Detour Dashboard

You will need:

- **Android:** package name `com.example.detour_flutter_plugin_example` and the SHA256 fingerprint of your debug keystore:
  ```sh
  keytool -list -v \
    -keystore ~/.android/debug.keystore \
    -alias androiddebugkey \
    -storepass android -keypass android \
    | grep "SHA256"
  ```
  > Each developer must register their own fingerprint — debug certificates are machine-specific.

- **iOS:** bundle ID `com.example.detourFlutterPluginExample` and your Apple Team ID (found in Xcode under Runner → Signing & Capabilities, or at [developer.apple.com/account](https://developer.apple.com/account))

### 2. Add your credentials

```sh
cp .env.example .env
# Edit .env with your DETOUR_API_KEY and DETOUR_APP_ID
```

### 3. Configure link domains and schemes

- **iOS Associated Domains** — replace `YOUR_DOMAIN` in `ios/Runner/Runner.entitlements` with your Detour link domain (e.g. `applinks:yourapp.godetour.link`). Append `?mode=developer` during development to bypass Apple's CDN cache.
- **Android App Link host** — update `<data android:host="...">` in `android/app/src/main/AndroidManifest.xml`.
- **Custom scheme** (optional) — change `detour-flutter-example` in both `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`.

### 4. iOS signing

Open `ios/Runner.xcworkspace` in Xcode, select the **Runner** target → **Signing & Capabilities**, and set your Team.

### 5. Install dependencies and run

```sh
flutter pub get
flutter run -d <device-id>
```

iOS only — install CocoaPods first:

```sh
cd ios && pod install && cd ..
```

## Testing

### Deferred link

Uninstall the app, copy a link from the Detour Dashboard, open it on the device, then install and launch — the deferred link resolves on first open and appears in the **Initial Intent** card.

### Universal/App Link

Trigger while the app is running:

```sh
# Android
adb shell am start -a android.intent.action.VIEW \
  -d "https://<your-link-domain>/<link-token>" \
  com.example.detour_flutter_plugin_example

# iOS — open the link in Safari or Notes on the device
```

The **Runtime Intent** card updates with type `verified`.

### Custom scheme

```sh
# Android
adb shell am start -a android.intent.action.VIEW \
  -d "detour-flutter-example://products/42?source=scheme" \
  com.example.detour_flutter_plugin_example

# iOS Simulator
xcrun simctl openurl booted "detour-flutter-example://products/42?source=scheme"
```

The **Runtime Intent** card updates with type `scheme`.

### Manual processing

Tap **Process Test Link** in the app to call `processLink()` directly. The result appears in the **processLink() Result** card.

### Analytics

Use the **Log Event** and **Log Retention** buttons to fire analytics events. Events appear under **Analytics → Events** in the [Detour Dashboard](https://godetour.dev). For local debugging on Android:

```sh
adb logcat | grep -i detour
```
