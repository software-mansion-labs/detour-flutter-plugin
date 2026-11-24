import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';
import 'package:detour_flutter_plugin/src/event_name_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts every standard name', () {
    for (final name in DetourEventName.values) {
      expect(eventNameProblem(name.rawValue), isNull, reason: name.rawValue);
    }
  });

  test('accepts custom names', () {
    for (final name in ['level_complete', 'a', 'x' * 64, 'step_2', 'app_open']) {
      expect(eventNameProblem(name), isNull, reason: name);
    }
  });

  test('refuses names that break the pattern', () {
    for (final name in ['', 'Level', 'level-complete', 'level complete', 'x' * 65, 'zażółć']) {
      expect(eventNameProblem(name), r'event names must match ^[a-z0-9_]{1,64}$', reason: name);
    }
  });

  test('refuses reserved prefixes', () {
    for (final name in ['af_install', 'dt_click']) {
      expect(eventNameProblem(name), 'the af_ and dt_ prefixes are reserved', reason: name);
    }
  });

  test('refuses opened_via_universal_link', () {
    expect(eventNameProblem('opened_via_universal_link'), 'this name is reserved for Detour');
  });
}
