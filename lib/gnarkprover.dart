import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:gnarkprover/assets.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';

import 'gnarkprover_bindings_generated.dart';

export 'assets.dart';

part 'gnarkprover.bindings.dart';
part 'gnarkprover.utils.dart';

part 'worker/initialize.dart';
part 'worker/log.dart';
part 'worker/prover.dart';

final _logger = Logger('gnarkprover');

final _didInitializeCache = <KeyAlgorithmType, bool>{};

class Gnarkprover {
  static Future<void> _initialize() async {
    final initAlgorithmWorker = await _InitAlgorithmWorker.spawn();
    try {
      await Future.wait(KeyAlgorithmType.values.map((algorithm) async {
        // Skip initialization for algorithms where last initialization was successful
        if (_didInitializeCache[algorithm] == true) return true;

        _didInitializeCache[algorithm] =
            await initAlgorithmWorker.initializeAlgorithm(
          algorithm,
        );
      }));
    } finally {
      initAlgorithmWorker.close();
    }
  }

  static Completer<Gnarkprover>? _completer;
  static Future<Gnarkprover> getInstance() async {
    if (_completer == null) {
      final completer = Completer<Gnarkprover>();
      _completer = completer;
      try {
        await _initialize();
        completer.complete(Gnarkprover._());
      } catch (e) {
        // If there's an error, explicitly return the future with an error.
        // then set the completer to null so we can retry.
        completer.completeError(e);
        final Future<Gnarkprover> gnarkProverFuture = completer.future;
        _completer = null;
        return gnarkProverFuture;
      }
    }
    return _completer!.future;
  }

  Gnarkprover._();

  final _proveWorkerFuture = _ProveWorker.spawn();

  Future<String> computeWitnessProof(String type, Uint8List bytes) async {
    final worker = await _proveWorkerFuture;
    return worker.prove(bytes);
  }

  Future<void> close() async {
    (await _proveWorkerFuture).close();
  }
}
