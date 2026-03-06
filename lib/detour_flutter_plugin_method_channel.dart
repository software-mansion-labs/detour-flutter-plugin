import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'detour_flutter_plugin_platform_interface.dart';

/// An implementation of [DetourFlutterPluginPlatform] that uses method channels.
class MethodChannelDetourFlutterPlugin extends DetourFlutterPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('detour_flutter_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
