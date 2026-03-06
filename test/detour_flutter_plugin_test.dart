import 'package:flutter_test/flutter_test.dart';
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';
import 'package:detour_flutter_plugin/detour_flutter_plugin_platform_interface.dart';
import 'package:detour_flutter_plugin/detour_flutter_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDetourFlutterPluginPlatform
    with MockPlatformInterfaceMixin
    implements DetourFlutterPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DetourFlutterPluginPlatform initialPlatform = DetourFlutterPluginPlatform.instance;

  test('$MethodChannelDetourFlutterPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDetourFlutterPlugin>());
  });

  test('getPlatformVersion', () async {
    DetourFlutterPlugin detourFlutterPlugin = DetourFlutterPlugin();
    MockDetourFlutterPluginPlatform fakePlatform = MockDetourFlutterPluginPlatform();
    DetourFlutterPluginPlatform.instance = fakePlatform;

    expect(await detourFlutterPlugin.getPlatformVersion(), '42');
  });
}
