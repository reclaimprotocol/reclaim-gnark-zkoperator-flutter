import 'dart:async';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gnarkprover/gnarkprover.dart' as gnarkprover;

void main() {
  gnarkprover.initializeSync();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? proveSyncResult;
  Future<String>? proveAsyncResult;

  Uint8List param = _DemoDebugging.fromHexStringToUint8List(
    '7b22636970686572223a226368616368613230222c226b6579223a5b5b302c302c302c302c302c312c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c315d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d5d2c226e6f6e6365223a5b5b302c302c302c302c302c312c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c315d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d5d2c22636f756e746572223a5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c315d2c22696e707574223a5b5b312c302c302c312c312c302c302c312c302c312c302c302c312c302c302c302c312c312c302c302c302c302c312c302c302c302c312c302c302c302c302c315d2c5b312c312c312c302c312c302c312c312c312c302c302c312c302c302c312c302c312c312c312c312c302c312c302c302c302c312c302c312c312c302c312c315d2c5b312c312c312c302c302c302c312c312c302c302c302c302c302c302c312c312c302c312c302c312c302c302c312c312c312c312c302c312c302c312c302c315d2c5b302c312c312c312c312c302c312c312c302c302c312c302c312c312c302c302c302c302c302c302c312c302c312c312c302c312c302c312c302c312c302c315d2c5b302c302c302c302c312c312c312c312c312c312c312c312c312c302c302c302c302c302c312c312c312c302c302c312c312c312c312c302c302c302c312c315d2c5b302c302c312c302c312c302c312c302c312c312c312c302c312c302c312c312c302c312c312c312c302c302c312c312c302c312c312c302c312c302c302c305d2c5b302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c305d2c5b302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c305d2c5b302c302c312c302c312c302c302c312c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c302c302c302c312c302c312c302c312c305d2c5b312c312c302c312c312c302c312c302c302c312c312c302c302c302c312c302c312c302c302c302c302c312c312c302c302c312c302c302c302c302c302c305d2c5b312c302c302c312c302c312c302c302c302c312c302c312c302c302c312c302c302c312c302c302c302c312c312c312c302c312c302c312c312c312c312c315d2c5b302c312c302c302c302c312c312c312c302c312c312c302c312c312c312c302c302c302c312c302c312c302c312c312c312c312c302c302c302c302c312c315d2c5b312c302c302c302c312c312c312c302c312c302c312c302c302c302c312c312c312c302c302c302c302c312c302c302c312c312c302c312c312c312c302c315d2c5b302c312c312c312c312c302c302c312c312c312c302c302c302c312c312c302c312c312c312c302c302c312c302c302c312c302c302c312c312c312c312c315d2c5b302c302c312c302c312c312c312c302c302c312c302c312c302c302c302c312c312c312c302c302c302c302c312c312c302c312c312c312c302c302c312c315d2c5b302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c302c305d5d7d',
  );

  void onProveSync() async {
    final result = _DemoDebugging.trackTaskSync(() {
      // runs on main isolate synchronously
      return gnarkprover.proveSync(param);
    }, 'onProveSync');

    setState(() {
      proveSyncResult = result;
    });
  }

  void onProveAsync() {
    final resultFuture = _DemoDebugging.trackTaskAsync(() {
      // runs on another isolate asynchronously
      return gnarkprover.proveAsync(param);
    }, 'onProveAsync');

    setState(() {
      proveAsyncResult = resultFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
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
            ListTile(
              title: const Text('proveSync() ='),
              subtitle: SelectableText(proveSyncResult.toString()),
            ),
            FilledButton(
              onPressed: onProveSync,
              child: const Text('Prove Sync'),
            ),
            const Divider(),
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

  static T trackTaskSync<T>(
    T Function() task,
    String debugTag,
  ) {
    try {
      final start = DateTime.now();
      logEvent('Operation started ${start.toIso8601String()}', tag: debugTag);
      final result = task();
      final end = DateTime.now();
      logEvent('Operation end ${end.toIso8601String()}', tag: debugTag);
      logEvent('Operation elapsed ${end.difference(start)}', tag: debugTag);
      return result;
    } catch (e, s) {
      logEvent('Error tracking task', tag: debugTag, error: e, stackTrace: s);
      rethrow;
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
