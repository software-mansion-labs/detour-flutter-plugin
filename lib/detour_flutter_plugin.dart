import 'src/models.dart';
import 'detour_flutter_plugin_platform_interface.dart';

export 'src/models.dart';

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

  Future<void> logRetention(String eventName) {
    return DetourFlutterPluginPlatform.instance.logRetention(eventName);
  }
}
