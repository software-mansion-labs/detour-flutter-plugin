# Detour Flutter SDK — Example App

This example demonstrates a full integration of `detour_flutter_plugin` with the recommended `DetourService` flow.

## Scenario represented

- `lib/main.dart`: initializes `DetourService` with `DetourConfig`, handles the pending intent queue (`initial` / `runtime` / `manual`) via `consumePendingIntent()`, and logs a `ReEngage` event on every link-driven open.
- `android/app/src/main/AndroidManifest.xml`: app links intent filter plus optional custom scheme (`detour-flutter-example`).
- `ios/Runner/Runner.entitlements`: Associated Domains entry for Universal Links.
- `ios/Runner/AppDelegate.swift`: deep-link forwarding for URL schemes and Universal Links.
- `ios/Runner/Info.plist`: custom scheme registration via `CFBundleURLTypes`.

## What this example covers

- SDK initialization and `DetourService` lifecycle wiring.
- Router-safe consume semantics via `consumePendingIntent()`.
- Initial and runtime link handling without duplicate navigation.
- Runtime handling for both verified web links and custom scheme links.
- Manual processing via `processLink(url)`.
- `LinkResult` handling: `Success` (with `route`, `pathname`, `params`, `type`), `NoLink`, `Error`.
- Analytics:
  - `main.dart` — `Detour.logEvent(ReEngage)` on every link-driven open, with `source` (from `LinkType.name`) and `route` properties.
  - `main.dart` — `Detour.logEvent(...)` via `Log Event` button for manual event firing.
  - `main.dart` — `Detour.logRetention(...)` via `Log Retention` button.

## Test flow

1) Start the app on a device or emulator.
2) Confirm app reaches `Status: Ready` and `Initial processed: true`.
3) Tap `Process Test Link` and verify:
   - `processLink() Result` card is updated.
   - `Manual Intent` card is updated.

**Android**

4) Trigger a runtime App link:
   ```shell
   adb shell am start -a android.intent.action.VIEW \
     -d "https://<your-link-domain>/<link-token>" \
     com.example.detour_flutter_plugin_example
   ```
   - `Runtime Intent` card updates. Type shows `VERIFIED`.
   - Alternatively, paste the link into a browser on the device — Android will open the app directly if App Links are configured.
5) Trigger a runtime custom scheme link:
   ```shell
   adb shell am start -a android.intent.action.VIEW \
     -d "detour-flutter-example://products/42?source=scheme" \
     com.example.detour_flutter_plugin_example
   ```
   - `Runtime Intent` card updates. Type shows `SCHEME`.

**iOS**

6) Trigger a runtime Universal Link (open in Safari or Notes) and verify `Runtime Intent` card updates with type `VERIFIED`.
7) Trigger a runtime custom scheme link on simulator:
   ```shell
   xcrun simctl openurl booted "detour-flutter-example://products/42?source=scheme"
   ```
   - `Runtime Intent` card updates. Type shows `SCHEME`.

**Both platforms**

8) For deferred link testing: uninstall the app, copy a Detour link from the Dashboard, then install and launch — the deferred link should resolve on first open.

> **Verifying analytics:** once triggered, events appear under **Analytics → Events** in the [Detour Dashboard](https://godetour.dev). For local debugging on Android run `adb logcat | grep -i detour` to see SDK-level logs in real time.

## Quick start

1. **Create an app in the [Detour Dashboard](https://godetour.dev).** You'll need:
   - **Android package name:** `com.example.detour_flutter_plugin_example` — and the **SHA256 certificate fingerprint** from your debug keystore:
     ```shell
     keytool -list -v \
       -keystore ~/.android/debug.keystore \
       -alias androiddebugkey \
       -storepass android \
       -keypass android \
       | grep "SHA256"
     ```
     > The debug certificate is machine-specific — each developer must register their own fingerprint. For a release build, use your release keystore and its alias instead.
   - **iOS bundle ID:** `com.example.detourFlutterPluginExample` and your **Apple Team ID** (found in Xcode under Runner → Signing & Capabilities, or at [developer.apple.com/account](https://developer.apple.com/account))

2. **Add your credentials from the Dashboard:**
   ```shell
   cp .env.example .env
   # then edit .env with your DETOUR_API_KEY and DETOUR_APP_ID
   ```

3. **iOS signing setup** — open `ios/Runner.xcworkspace` in Xcode, select the **Runner** target → **Signing & Capabilities**, and set your **Team**. The `DEVELOPMENT_TEAM` in the project is intentionally left blank so each developer can use their own Apple Developer account.

4. **Update link configuration** with values matching your Dashboard app:
   - **Associated Domains** — replace `YOUR_DOMAIN` in `ios/Runner/Runner.entitlements` with your link domain (e.g. `applinks:yourapp.godetour.link` or `applinks:links.yourdomain.com`). For development, append `?mode=developer` to bypass Apple's CDN cache.
   - **Universal Link / App Link intent filter** — update the `<data android:host="...">` in `android/app/src/main/AndroidManifest.xml`.
   - **Custom scheme** (optional) — change `detour-flutter-example` in both:
     - `android/app/src/main/AndroidManifest.xml` (`<data android:scheme="...">`)
     - `ios/Runner/Info.plist` (`CFBundleURLSchemes`)

5. **(Optional)** To test `Process Test Link`, modify the `_processTestLink` function in `lib/main.dart` with a link that matches your Detour Dashboard setup.

6. **Install dependencies and run:**
   ```shell
   flutter pub get
   flutter run -d <device-id>
   ```
   iOS only — install CocoaPods first:
   ```shell
   cd ios && pod install && cd ..
   ```

7. **Trigger test links:** **deferred** — copy the link from Detour Dashboard before a fresh install, then install and launch. **Universal Link / App Link** — open the link while the app is running or from cold start. **Custom scheme** — use the commands from steps 5 and 7 in **Test flow**.
