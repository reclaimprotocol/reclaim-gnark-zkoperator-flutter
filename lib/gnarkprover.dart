import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'gnarkprover_bindings_generated.dart';

part 'gnarkprover.bindings.dart';
part 'gnarkprover.utils.dart';

void initializeSync() {
  return _bindings.Init();
}

String proveSync(Uint8List inputBytes) {
  final inputBytesGoPointer = _GoSliceExtension.fromUint8List(inputBytes);

  final proof = _bindings.Prove(
    inputBytesGoPointer.ref,
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

Future<String> proveAsync(Uint8List inputBytes) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextSumRequestId++;
  final _ProveRequest request = _ProveRequest(
    requestId,
    inputBytes: inputBytes,
  );
  final Completer<String> completer = Completer<String>();
  _proveRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

/// A request to compute `proveAsync`.
///
/// Sent from one isolate to another.
class _ProveRequest {
  final int id;
  final Uint8List inputBytes;

  const _ProveRequest(
    this.id, {
    required this.inputBytes,
  });
}

/// A response with the result of `proveAsync`.
///
/// Sent from one isolate to another.
class _ProofResponse {
  final int id;
  final String result;

  const _ProofResponse(this.id, this.result);
}

/// Counter to identify [_ProveRequest]s and [_ProofResponse]s.
int _nextSumRequestId = 0;

/// Mapping from [_ProveRequest] `id`s to the completers corresponding to the correct future of the pending request.
final Map<int, Completer<String>> _proveRequests = <int, Completer<String>>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is _ProofResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<String> completer = _proveRequests[data.id]!;
        _proveRequests.remove(data.id);
        completer.complete(data.result);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) async {
    final ReceivePort helperReceivePort = ReceivePort()
      ..listen((dynamic data) {
        // On the helper isolate listen to requests and respond to them.
        if (data is _ProveRequest) {
          final String result = proveSync(data.inputBytes);
          final _ProofResponse response = _ProofResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}();
