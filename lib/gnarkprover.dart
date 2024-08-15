import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:gnarkprover/assets.dart';

import 'gnarkprover_bindings_generated.dart';

export 'assets.dart';

part 'gnarkprover.bindings.dart';
part 'gnarkprover.utils.dart';

Future<void> initializeAsync() {
  return Isolate.run(() => _bindings.Init());
}

final _didInitializeCache = <KeyAlgorithmType, bool>{};

Future<bool> initializeAlgorithmAsync(KeyAlgorithmType algorithm) async {
  if (_didInitializeCache[algorithm] == true) return true;
  final provingKeyFuture = algorithm.fetchKeyAsset();
  final r1csFuture = algorithm.fetchR1CSAsset();

  await Future.wait([provingKeyFuture, r1csFuture]);

  final provingKey = await provingKeyFuture;
  final r1cs = await r1csFuture;

  if (provingKey == null || r1cs == null) return false;

  Pointer<GoSlice>? provingKeyPointer;
  Pointer<GoSlice>? r1csPointer;
  try {
    provingKeyPointer = _GoSliceExtension.fromUint8List(provingKey);
    r1csPointer = _GoSliceExtension.fromUint8List(r1cs);

    final result = await Isolate.run(() {
      return _bindings.InitAlgorithm(
        algorithm.id,
        provingKeyPointer!.ref,
        r1csPointer!.ref,
      );
    });

    final didInitialize = result == 1;

    _didInitializeCache[algorithm] = didInitialize;

    return didInitialize;
  } finally {
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

Future<String> proveAsync(Uint8List inputBytes) async {
  final inputBytesGoPointer = _GoSliceExtension.fromUint8List(inputBytes);

  final proof = await Isolate.run(() {
    return _bindings.Prove(
      inputBytesGoPointer.ref,
    );
  });

  // freeing up memory for inputBytesGoPointer
  calloc.free(inputBytesGoPointer.ref.data);
  calloc.free(inputBytesGoPointer);

  final proofStr = String.fromCharCodes(proof.r0.asTypedList(proof.r1));

  // freeing up memory for proof
  _bindings.Free(proof.r0);

  // returning the json string response
  return proofStr;
}
