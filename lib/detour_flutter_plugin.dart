import 'src/models.dart';
import 'detour_flutter_plugin_platform_interface.dart';

export 'src/models.dart';
export 'src/detour_service.dart';

class DetourFlutterPlugin {
  Future<void> configure(DetourConfig config) {
    return DetourFlutterPluginPlatform.instance.configure(config);
  }

  Future<DetourResult> resolveInitialLink() {
    return DetourFlutterPluginPlatform.instance.resolveInitialLink();
  }

  Future<DetourResult> processLink(String url) {
    return DetourFlutterPluginPlatform.instance.processLink(url);
  }

  Stream<DetourResult> get linkStream =>
      DetourFlutterPluginPlatform.instance.linkStream;

  Future<void> logEvent(
    DetourEventName eventName, {
    Map<String, dynamic>? data,
  }) {
    return DetourFlutterPluginPlatform.instance.logEvent(eventName, data: data);
  }

  /// Logs an analytics event under a custom name. Custom names must match
  /// `^[a-z0-9_]{1,64}$`. Names starting with `af_` or `dt_`, and
  /// `opened_via_universal_link`, are reserved. An invalid name is dropped
  /// and logged as an error.
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) {
    return DetourFlutterPluginPlatform.instance.logCustomEvent(
      eventName,
      data: data,
    );
  }

  Future<void> logRetention(String eventName) {
    return DetourFlutterPluginPlatform.instance.logRetention(eventName);
  }
}
