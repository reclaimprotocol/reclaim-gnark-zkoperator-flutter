part of '../gnarkprover.dart';

class _ProveWorker {
  final SendPort _commands;
  final ReceivePort _responses;

  static const _debugLabel = '_ProveWorker';

  _ProveWorker._(this._commands, this._responses) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;

  Future<String> prove(Uint8List inputBytes) async {
    if (_closed) throw StateError('$_debugLabel is disposed');

    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, inputBytes));
    return await completer.future as String;
  }

  static Future<_ProveWorker> spawn() async {
    // Create a receive port and add its initial message handler
    final initPort = RawReceivePort(null, _debugLabel);
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };
    // Spawn the isolate.
    try {
      await Isolate.spawn(
        _startRemoteIsolate,
        (initPort.sendPort),
        debugName: _debugLabel,
      );
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    return _ProveWorker._(sendPort, receivePort);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is _LogRecordIsolateMessage) {
      _LogRecordIsolateMessage.log(message, _debugLabel);
      return;
    }

    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }
  }

  static Future<String> _onProveInIsolate(Uint8List inputBytes) async {
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

    _logger.finest('[$hash] proof completed: $proofStr');

    // returning the json string response
    return proofStr;
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) async {
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      final (id, inputBytes) = message as (int, Uint8List);
      try {
        final proofResponse = await _onProveInIsolate(inputBytes);
        sendPort.send((id, proofResponse));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort(_debugLabel);
    sendPort.send(receivePort.sendPort);
    _LogRecordIsolateMessage.setup(sendPort.send);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  bool _closed = false;

  bool close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
      return true;
    }
    return true;
  }
}
