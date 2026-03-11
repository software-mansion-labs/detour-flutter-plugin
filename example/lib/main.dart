import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:detour_flutter_plugin/detour_flutter_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = DetourFlutterPlugin();

  DetourResult? _initialResult;
  DetourResult? _runtimeResult;
  DetourResult? _processedResult;
  String _status = 'Initializing...';
  StreamSubscription<DetourResult>? _linkSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _plugin.configure(
        const DetourConfig(
          apiKey: 'YOUR_API_KEY',
          appID: 'YOUR_APP_ID',
          shouldUseClipboard: true,
          linkProcessingMode: LinkProcessingMode.all,
        ),
      );

      final initial = await _plugin.resolveInitialLink();
      setState(() {
        _initialResult = initial;
        _status = 'Ready';
      });

      _linkSub = _plugin.linkStream.listen((result) {
        setState(() => _runtimeResult = result);
      });
    } on PlatformException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _processTestLink() async {
    try {
      final result = await _plugin.processLink(
        'https://godetour.dev/abc123?campaign=test',
      );
      setState(() => _processedResult = result);
    } on PlatformException catch (e) {
      setState(() => _status = 'processLink error: ${e.message}');
    }
  }

  Future<void> _logEvent() async {
    await _plugin.logEvent(
      DetourEventName.purchase,
      data: {'value': 9.99, 'currency': 'USD'},
    );
    setState(() => _status = 'logEvent sent');
  }

  Future<void> _logRetention() async {
    await _plugin.logRetention('home_screen_viewed');
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
              const SizedBox(height: 16),
              _ResultCard('Initial Link', _initialResult),
              const SizedBox(height: 8),
              _ResultCard('Runtime Link', _runtimeResult),
              const SizedBox(height: 8),
              _ResultCard('Processed Link', _processedResult),
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
