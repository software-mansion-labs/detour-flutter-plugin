import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Local fallback for CI/tests without .env file.
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _detourService = DetourService();

  DetourIntent? _initialIntent;
  DetourIntent? _runtimeIntent;
  DetourIntent? _manualIntent;
  DetourResult? _processedResult;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _detourService.addListener(_onDetourChanged);
    _init();
  }

  Future<void> _init() async {
    try {
      await _detourService.start(
        DetourConfig(
          apiKey: dotenv.env['DETOUR_API_KEY'] ?? 'YOUR_API_KEY',
          appID: dotenv.env['DETOUR_APP_ID'] ?? 'YOUR_APP_ID',
          shouldUseClipboard: true,
          linkProcessingMode: LinkProcessingMode.all,
        ),
      );

      if (mounted &&
          _detourService.isInitialLinkProcessed &&
          _status == 'Initializing...') {
        setState(() => _status = 'Ready');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: ${e.message}');
    }
  }

  void _onDetourChanged() {
    if (!mounted) return;

    final intent = _detourService.pendingIntent;
    if (intent != null) {
      setState(() {
        switch (intent.source) {
          case DetourIntentSource.initial:
            _initialIntent = intent;
            break;
          case DetourIntentSource.runtime:
            _runtimeIntent = intent;
            break;
          case DetourIntentSource.manual:
            _manualIntent = intent;
            break;
        }
        _status = 'Handled ${intent.source.name} intent';
      });
      _detourService.consumePendingIntent();
      return;
    }

    if (_detourService.isInitialLinkProcessed && _status == 'Initializing...') {
      setState(() => _status = 'Ready');
    }
  }

  @override
  void dispose() {
    _detourService.removeListener(_onDetourChanged);
    _detourService.dispose();
    super.dispose();
  }

  Future<void> _processTestLink() async {
    try {
      final result = await _detourService.processLink(
        // Use a test URL that matches your Detour dashboard setup for testing.
        'https://godetour.link/abc123?campaign=test',
      );
      if (!mounted) return;
      setState(() => _processedResult = result);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _status = 'processLink error: ${e.message}');
    }
  }

  Future<void> _logEvent() async {
    await _detourService.logEvent(
      DetourEventName.purchase,
      data: {'value': 9.99, 'currency': 'USD'},
    );
    if (!mounted) return;
    setState(() => _status = 'logEvent sent');
  }

  Future<void> _logRetention() async {
    await _detourService.logRetention('home_screen_viewed');
    if (!mounted) return;
    setState(() => _status = 'logRetention sent');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Detour Flutter Plugin')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 8),
              Text(
                'Initial processed: ${_detourService.isInitialLinkProcessed}',
              ),
              const SizedBox(height: 16),
              _IntentCard('Initial Intent', _initialIntent),
              const SizedBox(height: 8),
              _IntentCard('Runtime Intent', _runtimeIntent),
              const SizedBox(height: 8),
              _IntentCard('Manual Intent', _manualIntent),
              const SizedBox(height: 8),
              _ResultCard('processLink() Result', _processedResult),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _processTestLink,
                    child: const Text('Process Test Link'),
                  ),
                  ElevatedButton(
                    onPressed: _logEvent,
                    child: const Text('Log Event'),
                  ),
                  ElevatedButton(
                    onPressed: _logRetention,
                    child: const Text('Log Retention'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard(this.title, this.intent);

  final String title;
  final DetourIntent? intent;

  @override
  Widget build(BuildContext context) {
    final value = intent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (value == null)
              const Text('None')
            else ...[
              Text('source: ${value.source.name}'),
              Text('type: ${value.link.type.name}'),
              Text('route: ${value.link.route}'),
              Text('pathname: ${value.link.pathname}'),
              Text('params: ${value.link.params}'),
              Text('url: ${value.link.url}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final DetourResult? result;

  const _ResultCard(this.title, this.result);

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (r == null)
              const Text('None')
            else if (r.link == null)
              Text('processed: ${r.processed}, link: null')
            else ...[
              Text('type: ${r.link!.type.name}'),
              Text('route: ${r.link!.route}'),
              Text('pathname: ${r.link!.pathname}'),
              Text('params: ${r.link!.params}'),
              Text('url: ${r.link!.url}'),
            ],
          ],
        ),
      ),
    );
  }
}
