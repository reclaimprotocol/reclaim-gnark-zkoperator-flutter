import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
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

// The logger for gnarkprover package. Using 'reclaim_flutter_sdk' as parent logger name to allow
// logs from this package to be listened from reclaim_flutter_sdk if sdk is filtering sdk only logs under reclaim_flutter_sdk.
final _logger = Logger('reclaim_flutter_sdk.gnarkprover');

/// A cache to store the initialization status of different key algorithm types.
/// The key is the [KeyAlgorithmType] and the value is a boolean indicating
/// whether the initialization was successful.
final _didInitializeCache = <KeyAlgorithmType, bool>{};

/// The main class for interacting with the Gnark prover.
/// This class provides methods to initialize the prover and compute witness proofs.
class Gnarkprover {
  /// Initializes the prover by loading the necessary algorithms asynchronously.
  static Future<void> _initialize() async {
    final initAlgorithmWorker = await _InitAlgorithmWorker.spawn();
    try {
      await Future.wait(KeyAlgorithmType.values.map((algorithm) async {
        // Skip initialization for algorithms where last initialization was successful
        if (_didInitializeCache[algorithm] == true) return true;
        // just locking the cache to prevent duplicate initialization
        _didInitializeCache[algorithm] = true;

        try {
          await initAlgorithmWorker.initializeAlgorithm(
            algorithm,
          );
        } catch (e, s) {
          _logger.severe('Error initializing algorithm $algorithm', e, s);
          _didInitializeCache[algorithm] = false;
          rethrow;
        }
      }));
    } finally {
      initAlgorithmWorker.close();
    }
  }

  static Completer<Gnarkprover>? _completer;

  /// Returns a singleton instance of [Gnarkprover].
  ///
  /// If the instance is not yet created, it creates a new one and initializes it.
  /// Running this for the first time will initialize the prover, and this initialization
  /// **can take a while**.
  ///
  /// It is recommended to call this method once in your application's lifecycle, in advance of its usage.
  /// For example, you can call it in your application's `main` function or a widget's `initState` method
  /// without awaiting the result.
  ///
  /// Running this method more than once is safe.
  static Future<Gnarkprover> getInstance() async {
    if (_completer == null) {
      final completer = Completer<Gnarkprover>();
      _completer = completer;
      try {
        await _initialize();
        completer.complete(Gnarkprover._());
      } catch (e, s) {
        // If there's an error, explicitly return the future with an error.
        // then set the completer to null so we can retry.
        completer.completeError(e);
        final Future<Gnarkprover> gnarkProverFuture = completer.future;
        _completer = null;
        _logger.severe('Error initializing Gnark prover', e, s);
        return gnarkProverFuture;
      }
    }
    return _completer!.future;
  }

  Gnarkprover._();

  Future<_ProveWorker>? _proveWorkerFuture;

  /// Computes the witness proof for the given bytes.
  ///
  /// The `type` parameter should be one of the key algorithm types supported by the prover.
  /// The `bytes` parameter should be the data in bytes received from the witness to be proven.
  ///
  /// When using this with `reclaim_flutter_sdk`, this function can be utilized as follows when creating a ReclaimVerification object:
  /// ```dart
  /// final reclaimVerification = ReclaimVerification(
  ///   buildContext: context,
  ///   appId: appId,
  ///   providerId: providerId,
  ///   secret: appSecret,
  ///   context: '',
  ///   parameters: {},
  ///   // Pass the computeWitnessProof callback to the sdk. This can be optionally used to compute the witness proof externally.
  ///   // For example, we can use the gnark prover to compute the witness proof locally.
  ///   computeWitnessProof: (type, bytes) async {
  ///     // Get gnark prover instance and compute the witness proof.
  ///     return (await Gnarkprover.getInstance())
  ///         .computeWitnessProof(type, bytes);
  ///   },
  ///   hideLanding: true,
  /// );
  /// ```
  ///
  /// Note: Use of `computeWitnessProof` could be disabled by default in the reclaim_flutter_sdk as this is still experimental.
  /// Read more about it in reclaim_flutter_sdk's README and reclaim_flutter_sdk/example's README.md.
  Future<String> computeWitnessProof(String type, Uint8List bytes) async {
    final proveWorkerFuture = _proveWorkerFuture ??= _ProveWorker.spawn();
    final worker = await proveWorkerFuture;
    return worker.prove(bytes);
  }

  /// Disposes of the prover by closing the worker.
  ///
  /// This method should be called when the prover is no longer needed to free up resources.
  Future<void> close() async {
    final proverWorkerFuture = _proveWorkerFuture;
    if (proverWorkerFuture != null) {
      (await proverWorkerFuture).close();
    }
  }
}
