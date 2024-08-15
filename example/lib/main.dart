import 'dart:async';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gnarkprover/gnarkprover.dart' as gnarkprover;

void main() {
  _DemoDebugging.trackTaskAsync(() {
    return gnarkprover.initializeAsync();
  }, 'initializeAsync');

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

  void onProveAsync() {
    final resultFuture = _DemoDebugging.trackTaskAsync(() {
      // runs on another isolate asynchronously
      return gnarkprover.proveAsync(param);
    }, 'onProveAsync');

    setState(() {
      proveAsyncResult = resultFuture;
    });
  }

  Future<void> _initializeAlgorithm(
    gnarkprover.KeyAlgorithmType algorithm,
  ) async {
    final response = await _DemoDebugging.trackTaskAsync(() {
      // runs on another isolate asynchronously
      return gnarkprover.initializeAlgorithmAsync(algorithm);
    }, 'initializeAlgorithmAsync');

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

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gnark Prover Example'),
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
            onChanged: (algorithm) {
              setState(() {
                _selectedAlgorithmType = algorithm;
              });

              if (algorithm != null) {
                _initializeAlgorithm(algorithm);
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
                    'proveAsync() (status ${value.connectionState.name}) ='),
                subtitle: SelectableText(displayValue.toString()),
              );
            },
          ),
          FilledButton(
            onPressed: onProveAsync,
            child: const Text('Prove Async'),
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
  static int _i = 0;
  static void logEvent(
    Object? message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final id = _i++;
    final label = '$id [$tag]';
    debugPrint('$label $message');
    if (error != null) {
      debugPrintThrottled('$id [$tag] (error) $error');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, label: label);
    }
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
