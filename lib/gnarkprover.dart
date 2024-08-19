import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:gnarkprover/assets.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';

import 'gnarkprover_bindings_generated.dart';

export 'assets.dart';

part 'gnarkprover.bindings.dart';
part 'gnarkprover.utils.dart';

final _logger = Logger('gnarkprover');

final _didInitializeCache = <KeyAlgorithmType, bool>{};

final _initializeAlgorithmMutex = Mutex();

Future<bool> initializeAlgorithm(KeyAlgorithmType algorithm) async {
  if (_didInitializeCache[algorithm] == true) return true;

  final provingKeyFuture = () async {
    final now = DateTime.now();
    _logger.fine('Downloading key asset for ${algorithm.name}');
    final asset = await algorithm.fetchKeyAsset();
    _logger.fine(
      'Downloaded key asset for ${algorithm.name}, elapsed ${DateTime.now().difference(now)}',
    );
    return asset;
  }();
  final r1csFuture = () async {
    final now = DateTime.now();
    _logger.fine('Downloading r1cs asset for ${algorithm.name}');
    final asset = await algorithm.fetchR1CSAsset();
    _logger.fine(
      'Downloaded r1cs asset for ${algorithm.name}, elapsed ${DateTime.now().difference(now)}',
    );
    return asset;
  }();

  await Future.wait([provingKeyFuture, r1csFuture]);

  final provingKey = await provingKeyFuture;
  final r1cs = await r1csFuture;

  if (provingKey == null || r1cs == null) return false;

  Pointer<GoSlice>? provingKeyPointer;
  Pointer<GoSlice>? r1csPointer;
  try {
    await _initializeAlgorithmMutex.acquire();
    provingKeyPointer = _GoSliceExtension.fromUint8List(provingKey);
    r1csPointer = _GoSliceExtension.fromUint8List(r1cs);

    final now = DateTime.now();

    _logger.fine('Running InitAlgorithm new for ${algorithm.name}');

    final result = _bindings.InitAlgorithm(
      algorithm.id,
      provingKeyPointer.ref,
      r1csPointer.ref,
    );

    _logger.fine(
      'Init complete for ${algorithm.name}, elapsed ${DateTime.now().difference(now)}',
    );

    final didInitialize = result == 1;

    _didInitializeCache[algorithm] = didInitialize;

    return didInitialize;
  } finally {
    _initializeAlgorithmMutex.release();
    if (provingKeyPointer != null) {
      calloc.free(provingKeyPointer.ref.data);
      calloc.free(provingKeyPointer);
    }
    if (r1csPointer != null) {
      calloc.free(r1csPointer.ref.data);
      calloc.free(r1csPointer);
    }
  }
}

String proveSync(Uint8List inputBytes) {
  final inputBytesGoPointer = _GoSliceExtension.fromUint8List(inputBytes);
  final now = DateTime.now();

  final hash = Object().hashCode;
  _logger.fine(
    '[$hash] Running prove for input of size ${inputBytes.lengthInBytes} bytes',
  );
  final proof = _bindings.Prove(
    inputBytesGoPointer.ref,
  );
  _logger.fine(
    '[$hash] Prove completed, elapsed ${DateTime.now().difference(now)}',
  );

  // freeing up memory for inputBytesGoPointer
  calloc.free(inputBytesGoPointer.ref.data);
  calloc.free(inputBytesGoPointer);

  final proofStr = String.fromCharCodes(proof.r0.asTypedList(proof.r1));

  // freeing up memory for proof
  _bindings.Free(proof.r0);

  // returning the json string response
  return proofStr;
}
