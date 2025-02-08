import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'src/algorithm/algorithm.dart';
import 'src/algorithm/assets.dart';
import 'src/generated_bindings.dart';
import 'src/zk_operator.dart';

export 'src/algorithm/algorithm.dart';
export 'src/algorithm/assets.dart';
export 'src/zk_operator.dart';

part 'src/part/bindings.dart';
part 'src/part/bytes.dart';
part 'src/part/json.dart';

part 'src/worker/initialize.dart';
part 'src/worker/log.dart';
part 'src/worker/oprf/generate_request.dart';
part 'src/worker/oprf/finalize.dart';
part 'src/worker/prover.dart';

// The logger for reclaim_gnark_zkoperator package. Using 'reclaim_flutter_sdk' as parent logger name to allow
// logs from this package to be listened from reclaim_flutter_sdk if sdk is filtering sdk only logs under reclaim_flutter_sdk.
final _logger = Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator');

/// A cache to store the initialization status of different key algorithm types.
/// The key is the [ProverAlgorithmType] and the value is a boolean indicating
/// whether the initialization was successful.
final _didInitializeCache = <ProverAlgorithmType, bool>{};

class KeyAlgorithmAssetUrls {
  final String keyAssetUrl;
  final String r1csAssetUrl;

  const KeyAlgorithmAssetUrls(this.keyAssetUrl, this.r1csAssetUrl);
}

typedef KeyAlgorithmAssetUrlsProvider = KeyAlgorithmAssetUrls Function(
  ProverAlgorithmType algorithm,
);

/// {@macro reclaim_gnark_zkoperator.ZkOperator}
///
/// The main class for interacting with the Gnark prover and Reclaim Attestor Browser RPC.
/// This class provides methods to initialize the prover and compute witness proofs.
///
/// This class extends [ZkOperator] and implements the methods defined in the [ZkOperator] interface.
class ReclaimZkOperator extends ZkOperator {
  static final _initAlgorithmWorkerFuture = _InitAlgorithmWorker.spawn();

  /// Initializes the prover by loading the necessary algorithms asynchronously.
  static Future<void> initializeAlgorithms(
    Iterable<ProverAlgorithmType> algorithms,
    KeyAlgorithmAssetUrlsProvider getAssetUrls,
  ) async {
    final worker = await _initAlgorithmWorkerFuture;

    await Future.wait(algorithms.map((algorithm) async {
      // Skip initialization for algorithms where last initialization was successful
      if (_didInitializeCache[algorithm] == true) return true;
      // just locking the cache to prevent duplicate initialization
      _didInitializeCache[algorithm] = true;

      try {
        final assetUrls = getAssetUrls(algorithm);
        await worker.initializeAlgorithm(
          algorithm,
          assetUrls.keyAssetUrl,
          assetUrls.r1csAssetUrl,
        );
      } catch (e, s) {
        _logger.severe('Error initializing algorithm $algorithm', e, s);
        _didInitializeCache[algorithm] = false;
        rethrow;
      }
    }));
  }

  static Completer<void>? _oprfInitializedCompleter;

  /// Ensures that the OPRF is initialized.
  ///
  /// This method is used to ensure that the OPRF is initialized before any OPRF operations are performed.
  /// It will initialize the OPRF if it has not already been initialized.
  /// If the OPRF is already initialized, it will return immediately.
  /// If the OPRF is not initialized, it will initialize the OPRF and return a future that completes when the OPRF is initialized.
  /// If there is an error during initialization, it will return a future that completes with an error.
  Future<void> ensureOprfInitialized() async {
    if (_oprfInitializedCompleter == null) {
      final completer = Completer<void>();
      _oprfInitializedCompleter = completer;
      try {
        final log = Logger(
            'reclaim_flutter_sdk.reclaim_gnark_zkoperator.ensureOprfInitialized');
        final start = DateTime.now();
        await initializeAlgorithms(ProverAlgorithmType.oprf, getAssetUrls);
        final end = DateTime.now();
        final diff = end.difference(start);
        log.info(
          'Initialized Gnark Prover (oprf) in ${diff.inMilliseconds} ms or ${diff.inSeconds} s',
        );
        completer.complete();
      } catch (e, s) {
        // If there's an error, explicitly return the future with an error.
        // then set the completer to null so we can retry.
        completer.completeError(e);
        final Future<void> gnarkProverFuture = completer.future;
        _oprfInitializedCompleter = null;
        _logger.severe('Error initializing OPRF in Gnark prover', e, s);
        return gnarkProverFuture;
      }
    }
    return await _oprfInitializedCompleter!.future;
  }

  static Completer<ReclaimZkOperator>? _completer;

  /// Returns a singleton instance of [ReclaimZkOperator].
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
  ///
  /// To update an algorithm [ProverAlgorithmType]'s key and r1cs assets, you can call
  /// [ReclaimZkOperator.initializeAlgorithms] and use [ReclaimZkOperator] later when [initializeAlgorithms] completes.
  static Future<ReclaimZkOperator> getInstance([
    KeyAlgorithmAssetUrlsProvider getAssetUrls =
        defaultKeyAlgorithmsAssetUrlsProvider,
  ]) async {
    if (_completer == null) {
      final completer = Completer<ReclaimZkOperator>();
      _completer = completer;
      try {
        final log =
            Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator.getInstance');
        final start = DateTime.now();
        // start initializing non-oprf algorithms but will wait later
        final nonOprfInitFuture = initializeAlgorithms(
          ProverAlgorithmType.nonOprf,
          getAssetUrls,
        );
        final prover = ReclaimZkOperator._(getAssetUrls);

        // wait for non-oprf algorithms to initialize
        await nonOprfInitFuture;
        final end = DateTime.now();
        final diff = end.difference(start);
        log.info(
          'Initialized Gnark Prover (non-oprf) in ${diff.inMilliseconds} ms or ${diff.inSeconds} s',
        );
        // start initializing oprf algorithm but don't wait for it to complete in this method
        // intention for doing this: Most providers don't use oprf.
        _unawaited(Future.wait([
          // This here is not needed (already awaited above)
          // Just keeping it here to help with refactoring later
          // Doing this shouldn't affect program.
          nonOprfInitFuture,
          prover.ensureOprfInitialized(),
        ]).then((_) {
          final end = DateTime.now();
          final diff = end.difference(start);
          log.info(
            'Initialized Gnark Prover in ${diff.inMilliseconds} ms or ${diff.inSeconds} s',
          );
        }));

        completer.complete(prover);
      } catch (e, s) {
        // If there's an error, explicitly return the future with an error.
        // then set the completer to null so we can retry.
        completer.completeError(e);
        final Future<ReclaimZkOperator> gnarkProverFuture = completer.future;
        _completer = null;
        _logger.severe('Error initializing Gnark prover', e, s);
        return gnarkProverFuture;
      }
    }
    return _completer!.future;
  }

  static KeyAlgorithmAssetUrls defaultKeyAlgorithmsAssetUrlsProvider(
    ProverAlgorithmType algorithm,
  ) {
    return KeyAlgorithmAssetUrls(
      algorithm.defaultKeyAssetUrl,
      algorithm.defaultR1CSAssetUrl,
    );
  }

  final KeyAlgorithmAssetUrlsProvider getAssetUrls;

  ReclaimZkOperator._(this.getAssetUrls);

  Future<_ProveWorker>? _proveWorkerFuture;

  /// Computes the witness proof for the given bytes.
  ///
  /// The `fnName` parameter should be the name of the zk or oprf functions supported by the prover.
  /// The `args` parameter should be the arguments for the function.
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
  ///   // Pass the computeAttestorProof callback to the sdk. This can be optionally used to compute the witness proof externally.
  ///   // For example, we can use the Reclaim ZK Operator to compute the witness proof locally.
  ///   computeAttestorProof: (fnName, args) async {
  ///     // Get Reclaim ZK Operator instance and compute the witness proof.
  ///     return (await ReclaimZkOperator.getInstance())
  ///         .computeAttestorProof(fnName, args);
  ///   },
  ///   hideLanding: true,
  /// );
  /// ```
  ///
  /// Note: Use of `computeAttestorProof` could be disabled by default in the reclaim_flutter_sdk as this is still experimental.
  /// Read more about it in reclaim_flutter_sdk's README and reclaim_flutter_sdk/example's README.md.
  @override
  Future<String> computeAttestorProof(String fnName, List<dynamic> args) async {
    final String response = await () async {
      switch (fnName) {
        case 'groth16Prove':
          final bytesInput = base64.decode(args[0]['value']);

          return await groth16Prove(bytesInput);
        case 'finaliseOPRF':
          await ensureOprfInitialized();
          final [serverPublicKey, request, responses] = args;
          final jsonString = json.encode(
            _replaceBase64Json({
              'serverPublicKey': serverPublicKey,
              'request': request,
              'responses': responses,
            }),
          );
          final Uint8List bytesInput = utf8.encode(jsonString);
          final response = await finaliseOPRF(bytesInput);
          return json.encode(json.decode(response)['output']);
        case 'generateOPRFRequestData':
          await ensureOprfInitialized();
          final [data, domainSeparator] = args;
          final jsonString = json.encode(
            _replaceBase64Json({
              'data': data,
              'domainSeparator': domainSeparator,
            }),
          );
          final Uint8List bytesInput = utf8.encode(jsonString);
          final response = await generateOPRFRequestData(bytesInput);
          return response;
        default:
          throw UnimplementedError('Function $fnName not implemented');
      }
    }();
    return _reformatJsonStringForRPC(response);
  }

  @override
  Future<String> groth16Prove(Uint8List bytes) async {
    final proveWorkerFuture = _proveWorkerFuture ??= _ProveWorker.spawn();
    final worker = await proveWorkerFuture;
    return worker.prove(bytes);
  }

  Future<_TOPRFFinalizeWorker>? _toprfFinalizeWorkerFuture;

  @override
  Future<String> finaliseOPRF(Uint8List bytes) async {
    final workerFuture =
        _toprfFinalizeWorkerFuture ??= _TOPRFFinalizeWorker.spawn();
    final worker = await workerFuture;
    return worker.toprfFinalize(bytes);
  }

  Future<_GenerateOPRFRequestDataWorker>? _generateOPRFRequestDataWorkerFuture;

  @override
  Future<String> generateOPRFRequestData(Uint8List bytes) async {
    final workerFuture = _generateOPRFRequestDataWorkerFuture ??=
        _GenerateOPRFRequestDataWorker.spawn();
    final worker = await workerFuture;
    return worker.generateOPRFRequestData(bytes);
  }

  @override
  Future<void> close() async {
    final proverWorkerFuture = _proveWorkerFuture;
    if (proverWorkerFuture != null) {
      (await proverWorkerFuture).close();
    }
  }
}

void _unawaited(Future<void>? f) {}
