import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'detour_flutter_plugin_method_channel.dart';

abstract class DetourFlutterPluginPlatform extends PlatformInterface {
  /// Constructs a DetourFlutterPluginPlatform.
  DetourFlutterPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static DetourFlutterPluginPlatform _instance = MethodChannelDetourFlutterPlugin();

  /// The default instance of [DetourFlutterPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelDetourFlutterPlugin].
  static DetourFlutterPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DetourFlutterPluginPlatform] when
  /// they register themselves.
  static set instance(DetourFlutterPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
