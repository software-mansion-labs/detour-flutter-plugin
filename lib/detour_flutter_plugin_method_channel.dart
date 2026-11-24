import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'detour_flutter_plugin_platform_interface.dart';
import 'src/event_name_rules.dart';
import 'src/models.dart';

class MethodChannelDetourFlutterPlugin extends DetourFlutterPluginPlatform {
  final methodChannel = const MethodChannel('detour_flutter_plugin');
  final _eventChannel = const EventChannel('detour_flutter_plugin/links');

  Stream<DetourResult>? _linkStream;

  @override
  Stream<DetourResult> get linkStream {
    _linkStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => DetourResult.fromMap(event as Map));
    return _linkStream!;
  }

  @override
  Future<void> configure(DetourConfig config) async {
    await methodChannel.invokeMethod<void>('configure', {
      'apiKey': config.apiKey,
      'appID': config.appID,
      'shouldUseClipboard': config.shouldUseClipboard,
      'linkProcessingMode': config.linkProcessingMode.value,
    });
  }

  @override
  Future<DetourResult> resolveInitialLink() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'resolveInitialLink',
    );
    return DetourResult.fromMap(result ?? {});
  }

  @override
  Future<DetourResult> processLink(String url) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'processLink',
      {'url': url},
    );
    return DetourResult.fromMap(result ?? {});
  }

  @override
  Future<void> logEvent(
    DetourEventName eventName, {
    Map<String, dynamic>? data,
  }) async {
    await methodChannel.invokeMethod<void>('logEvent', {
      'eventName': eventName.rawValue,
      'data': data,
    });
  }

  @override
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    final problem = eventNameProblem(eventName);
    if (problem != null) {
      debugPrint('[Detour:ANALYTICS] Event "$eventName" dropped: $problem.');
      return;
    }

    if (kDebugMode && data != null) {
      _warnIfDataTooLarge(eventName, data);
    }

    await methodChannel.invokeMethod<void>('logEvent', {
      'eventName': eventName,
      'data': data,
    });
  }

  // Debug-only, so the JSON length is a close enough stand-in for the server's byte count.
  void _warnIfDataTooLarge(String eventName, Map<String, dynamic> data) {
    final length = _jsonLength(data);
    if (length != null && length > maxEventDataBytes) {
      debugPrint(
        '[Detour:ANALYTICS] Event "$eventName" has $length characters of data as JSON. '
        'Detour stores at most $maxEventDataBytes bytes of data per event and may refuse larger events.',
      );
    }
  }

  // Data that can't be encoded fails when it is sent, and that logs the error.
  int? _jsonLength(Map<String, dynamic> data) {
    try {
      return jsonEncode(data).length;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logRetention(String eventName) async {
    await methodChannel.invokeMethod<void>('logRetention', {
      'eventName': eventName,
    });
  }
}
