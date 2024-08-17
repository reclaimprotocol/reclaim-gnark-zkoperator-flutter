import 'dart:async';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gnarkprover/gnarkprover.dart' as gnarkprover;
import 'package:gnarkprover/gnarkprover.dart';
import 'package:logging/logging.dart';

final logs = <LogRecord>[];

final logger = Logger('gnarkprover_example');

void main() {
  hierarchicalLoggingEnabled = true;

  Logger('').onRecord.listen((entry) {
    if (!kReleaseMode) {
      debugPrintThrottled(
          '${entry.sequenceNumber} [${entry.level}] ${entry.message}');
    }
    logs.add(entry);
  });
  Logger('').level = Level.ALL;

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

final Uint8List param = _DemoDebugging.fromHexStringToUint8List(
  '7b22636970686572223a226368616368613230222c226b6579223a5b5b302c302c302c302c302c312c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c315d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d5d2c226e6f6e6365223a5b5b302c302c302c302c302c312c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c315d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d5d2c22636f756e746572223a5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c315d2c22696e707574223a5b5b312c302c302c312c312c302c302c312c302c312c302c302c312c302c302c302c312c312c302c302c302c302c312c302c302c302c312c302c302c302c302c315d2c5b312c312c312c302c312c302c312c312c312c302c302c312c302c302c312c302c312c312c312c312c302c312c302c302c302c312c302c312c312c302c312c315d2c5b312c312c312c302c302c302c312c312c302c302c302c302c302c302c312c312c302c312c302c312c302c302c312c312c312c312c302c312c302c312c302c315d2c5b302c312c312c312c312c302c312c312c302c302c312c302c312c312c302c302c302c302c302c302c312c302c312c312c302c312c302c312c302c312c302c315d2c5b302c302c302c302c312c312c312c312c312c312c312c312c312c302c302c302c302c302c312c312c312c302c302c312c312c312c312c302c302c302c312c315d2c5b302c302c312c302c312c302c312c302c312c312c312c302c312c302c312c312c302c312c312c312c302c302c312c312c302c312c312c302c312c302c302c305d2c5b302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c305d2c5b302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c305d2c5b302c302c312c302c312c302c302c312c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c305d2c5b312c312c302c312c312c302c312c302c302c312c312c302c302c302c312c302c312c302c302c302c302c312c312c302c302c312c302c302c302c302c302c305d2c5b312c302c302c312c302c312c302c302c302c312c302c312c302c302c312c302c302c312c302c302c302c312c312c312c302c312c302c312c312c312c312c315d2c5b302c312c302c302c302c312c312c312c302c312c312c302c312c312c312c302c302c302c312c302c312c302c312c312c312c312c302c302c302c302c312c315d2c5b312c302c302c302c312c312c312c302c312c302c312c302c302c302c312c312c312c302c302c302c302c312c302c302c312c312c302c312c312c312c302c315d2c5b302c312c312c312c312c302c302c312c312c312c302c302c302c312c312c302c312c312c312c302c302c312c302c302c312c302c302c312c312c312c312c315d2c5b302c302c312c302c312c312c312c302c302c312c302c312c302c302c302c312c312c312c302c302c302c302c312c312c302c312c312c312c302c302c312c315d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d5d7d',
);

class _MyAppState extends State<MyApp> {
  Future<String>? proveAsyncResult;
  gnarkprover.KeyAlgorithmType? _selectedAlgorithmType;

  void onInitializeButtonPressed() async {
    lock();
    try {
      await _DemoDebugging.trackTaskAsync(() {
        return gnarkprover.initializeSync();
      }, 'initializeSync');
    } finally {
      unlock();
    }
  }

  void onProveButtonPressed() async {
    try {
      lock();
      final resultFuture = _DemoDebugging.trackTaskAsync(() {
        // runs on another isolate asynchronously
        return gnarkprover.proveSync(param);
      }, 'proveSync');

      setState(() {
        proveAsyncResult = resultFuture;
      });

      await resultFuture;
    } finally {
      unlock();
    }
  }

  Future<void> _initializeAlgorithmButton(
    gnarkprover.KeyAlgorithmType algorithm,
  ) async {
    bool response = false;
    try {
      lock();
      response = await _DemoDebugging.trackTaskAsync(() {
        // runs on another isolate asynchronously
        return gnarkprover.initializeAlgorithm(algorithm);
      }, 'initializeAlgorithm');
    } finally {
      unlock();
    }

    if (mounted) {
      final msg = ScaffoldMessenger.of(context);

      msg.removeCurrentSnackBar();

      msg.showSnackBar(
        SnackBar(
          content: Text(
            'Initialization of "${algorithm.name}" was ${response ? 'Successful' : 'Failure'}',
          ),
        ),
      );
    }
  }

  bool _locked = false;

  void lock() {
    setState(() {
      _locked = true;
    });
  }

  void unlock() {
    setState(() {
      _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gnark Prover Example'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _LogsViewerScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bug_report),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const Text(
            'This can be used to call gnarkprover\'s native functions for gnark prove through FFI that is shipped as source in the package.',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          FilledButton(
            onPressed: _locked ? null : onInitializeButtonPressed,
            child: const Text('Initialize'),
          ),
          spacerSmall,
          DropdownButton(
            value: _selectedAlgorithmType,
            hint: const Text(
              'Select algorithm',
              textAlign: TextAlign.center,
            ),
            alignment: Alignment.center,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            items: const [
              DropdownMenuItem(
                value: gnarkprover.KeyAlgorithmType.CHACHA20,
                child: Text('CHACHA 20'),
              ),
              DropdownMenuItem(
                value: gnarkprover.KeyAlgorithmType.AES_128,
                child: Text('AES 128'),
              ),
              DropdownMenuItem(
                value: gnarkprover.KeyAlgorithmType.AES_256,
                child: Text('AES 256'),
              ),
            ],
            onChanged: _locked
                ? null
                : (KeyAlgorithmType? algorithm) {
                    setState(() {
                      _selectedAlgorithmType = algorithm;
                    });

                    if (algorithm != null) {
                      _initializeAlgorithmButton(algorithm);
                    }
                  },
          ),
          spacerSmall,
          FutureBuilder<String>(
            future: proveAsyncResult,
            builder: (
              BuildContext context,
              AsyncSnapshot<String> value,
            ) {
              final displayValue = (value.hasData) ? value.data : 'null';
              return ListTile(
                title: Text(
                    'proveSync() (status ${value.connectionState.name}) ='),
                subtitle: SelectableText(displayValue.toString()),
              );
            },
          ),
          FilledButton(
            onPressed: _locked ? null : onProveButtonPressed,
            child: const Text('Prove Sync'),
          ),
          const SizedBox(
            height: 100,
          ),
        ],
      ),
    );
  }
}

class _DemoDebugging {
  static void logEvent(
    Object? message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final label = '[$tag]';
    logger.info('$label $message', error, stackTrace);
  }

  static Future<T> trackTaskAsync<T>(
    FutureOr<T> Function() task,
    String debugTag,
  ) async {
    try {
      final start = DateTime.now();
      logEvent('Operation started ${start.toIso8601String()}', tag: debugTag);
      final result = await task();
      final end = DateTime.now();
      logEvent('Operation end ${end.toIso8601String()}', tag: debugTag);
      logEvent('Operation elapsed ${end.difference(start)}', tag: debugTag);
      return result;
    } catch (e, s) {
      logEvent('error tracking task', error: e, stackTrace: s, tag: debugTag);
      rethrow;
    }
  }

  static Uint8List fromHexStringToUint8List(String hexString) {
    final bytes = hex.decode(hexString);
    return Uint8List.fromList(bytes);
  }
}

class _LogsViewerScreen extends StatelessWidget {
  const _LogsViewerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          OutlinedButton(
            onPressed: () async {
              final msg = ScaffoldMessenger.of(context);
              final text = logs
                  .map((e) => '${e.sequenceNumber} [${e.level}] ${e.message}')
                  .join('\n');
              await Clipboard.setData(
                ClipboardData(text: text),
              );
              msg.showSnackBar(
                const SnackBar(
                  content: Text('Logs Copied'),
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return ExpansionTile(
            leading: Text(log.sequenceNumber.toString()),
            title: Text(log.message),
          );
        },
      ),
    );
  }
}
