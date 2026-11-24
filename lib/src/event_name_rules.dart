// Mirrors `lib/services/eventsService/eventNames.ts` in detour-website. Keep in sync.

final RegExp appEventNamePattern = RegExp(r'^[a-z0-9_]{1,64}$');

/// `af_` marks events imported from AppsFlyer; `dt_` is kept for Detour's own names.
const List<String> reservedEventNamePrefixes = ['af_', 'dt_'];

/// The server turns these into link clicks, so an app may not log them itself.
const Set<String> reservedEventNames = {'opened_via_universal_link'};

/// The server's limit for `data`, as UTF-8 bytes of its JSON.
const int maxEventDataBytes = 2048;

/// Why the server would refuse [name], or `null` when it is a valid event name.
String? eventNameProblem(String name) {
  if (!appEventNamePattern.hasMatch(name)) {
    return 'event names must match ${appEventNamePattern.pattern}';
  }
  if (reservedEventNamePrefixes.any(name.startsWith)) {
    return 'the ${reservedEventNamePrefixes.join(' and ')} prefixes are reserved';
  }
  if (reservedEventNames.contains(name)) {
    return 'this name is reserved for Detour';
  }
  return null;
}
