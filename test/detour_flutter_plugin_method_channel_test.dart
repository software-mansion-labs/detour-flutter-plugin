import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';
import 'package:detour_flutter_plugin/detour_flutter_plugin_method_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelDetourFlutterPlugin();
  const channel = MethodChannel('detour_flutter_plugin');

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          switch (methodCall.method) {
            case 'resolveInitialLink':
              return {
                'processed': true,
                'link': {
                  'url': 'https://detour.dev/promo?campaign=spring',
                  'route': '/promo?campaign=spring',
                  'pathname': '/promo',
                  'params': {'campaign': 'spring'},
                  'type': 'verified',
                },
              };
            case 'processLink':
              return {
                'processed': true,
                'link': null,
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configure sends expected payload', () async {
    await platform.configure(
      const DetourConfig(
        apiKey: 'api-key',
        appID: 'app-id',
        shouldUseClipboard: false,
        linkProcessingMode: LinkProcessingMode.webOnly,
      ),
    );

    expect(calls, hasLength(1));
    expect(calls.first.method, 'configure');
    expect(calls.first.arguments, {
      'apiKey': 'api-key',
      'appID': 'app-id',
      'shouldUseClipboard': false,
      'linkProcessingMode': 'web-only',
    });
  });

  test('resolveInitialLink maps native payload into DetourResult', () async {
    final result = await platform.resolveInitialLink();

    expect(result.processed, true);
    expect(result.link, isNotNull);
    expect(result.link?.route, '/promo?campaign=spring');
    expect(result.link?.pathname, '/promo');
    expect(result.link?.params['campaign'], 'spring');
    expect(result.link?.type, LinkType.verified);
  });

  test('logEvent sends enum raw value', () async {
    await platform.logEvent(
      DetourEventName.addToCart,
      data: {'sku': 'ABC-123'},
    );

    expect(calls, hasLength(1));
    expect(calls.first.method, 'logEvent');
    expect(calls.first.arguments, {
      'eventName': 'add_to_cart',
      'data': {'sku': 'ABC-123'},
    });
  });

  test('logCustomEvent sends the name as is', () async {
    await platform.logCustomEvent('level_complete', data: {'level': 3});

    expect(calls, hasLength(1));
    expect(calls.first.method, 'logEvent');
    expect(calls.first.arguments, {
      'eventName': 'level_complete',
      'data': {'level': 3},
    });
  });

  test('logCustomEvent drops invalid names and logs an error', () async {
    final logs = <String?>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = originalDebugPrint);

    for (final name in ['Level-Complete', 'af_install', 'opened_via_universal_link']) {
      await platform.logCustomEvent(name);
    }

    expect(calls, isEmpty);
    expect(logs, hasLength(3));
    expect(logs.first, contains('Event "Level-Complete" dropped'));
  });

  test('logCustomEvent warns about large data and still sends it', () async {
    final logs = <String?>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = originalDebugPrint);

    await platform.logCustomEvent('big_event', data: {'text': 'x' * 3000});

    expect(calls, hasLength(1));
    expect(logs.single, contains('at most 2048 bytes'));
  });

  test('logRetention forwards custom retention name', () async {
    await platform.logRetention('home_screen_viewed');

    expect(calls, hasLength(1));
    expect(calls.first.method, 'logRetention');
    expect(calls.first.arguments, {
      'eventName': 'home_screen_viewed',
    });
  });
}
