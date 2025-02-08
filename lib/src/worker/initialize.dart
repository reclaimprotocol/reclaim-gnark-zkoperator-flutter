part of '../../reclaim_gnark_zkoperator.dart';

class _InitAlgorithmWorker {
  final SendPort _commands;
  final ReceivePort _responses;

  static const _debugLabel = '_InitAlgorithmWorker';

  _InitAlgorithmWorker._(this._commands, this._responses) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;

  Future<bool> initializeAlgorithm(
    ProverAlgorithmType algorithm,
    String keyAssetUrl,
    String r1csAssetUrl,
  ) async {
    if (_closed) throw StateError('$_debugLabel is disposed');

    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, algorithm, keyAssetUrl, r1csAssetUrl));

    return await completer.future as bool;
  }

  static Future<_InitAlgorithmWorker> spawn() async {
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
      final rootToken = RootIsolateToken.instance!;
      await Isolate.spawn(
        _startRemoteIsolate,
        (rootToken, initPort.sendPort),
        debugName: _debugLabel,
      );
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;

    return _InitAlgorithmWorker._(sendPort, receivePort);
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

  static Future<bool> _onInitAlgorithmInIsolate(
    ProverAlgorithmType algorithm,
    String keyAssetUrl,
    String r1csAssetUrl,
  ) async {
    final provingKeyFuture = () async {
      final now = DateTime.now();
      _logger.fine('Downloading key asset for ${algorithm.name}');
      final asset = await algorithm.fetchKeyAsset(keyAssetUrl);
      _logger.info(
        'Downloaded key asset for ${algorithm.name}, elapsed ${DateTime.now().difference(now)}',
      );
      return asset;
    }();
    final r1csFuture = () async {
      final now = DateTime.now();
      _logger.fine('Downloading r1cs asset for ${algorithm.name}');
      final asset = await algorithm.fetchR1CSAsset(r1csAssetUrl);
      _logger.info(
        'Downloaded r1cs asset for ${algorithm.name}, elapsed ${DateTime.now().difference(now)}',
      );
      return asset;
    }();

    await Future.wait([provingKeyFuture, r1csFuture]);

    final provingKey = await provingKeyFuture;
    final r1cs = await r1csFuture;

    if (provingKey == null || r1cs == null) {
      _logger.warning({
        'reason': 'Failed to download key or r1cs for ${algorithm.name}',
        'provingKey.length': provingKey?.length,
        'r1cs.length': r1cs?.length,
      });
      return false;
    }

    Pointer<GoSlice>? provingKeyPointer;
    Pointer<GoSlice>? r1csPointer;
    try {
      provingKeyPointer = _GoSliceExtension.fromUint8List(provingKey);
      r1csPointer = _GoSliceExtension.fromUint8List(r1cs);

      final now = DateTime.now();

      _logger.fine('Running InitAlgorithm new for ${algorithm.name}');

      final result = _bindings.InitAlgorithm(
        algorithm.id,
        provingKeyPointer.ref,
        r1csPointer.ref,
      );

      _logger.info(
        'Init complete for ${algorithm.name}, elapsed ${DateTime.now().difference(now)}',
      );
      _logger.finest({
        'func': 'InitAlgorithm',
        'args': {
          'algorithm': {
            'name': algorithm.name,
            'id': algorithm.id,
          },
          'provingKey.length': provingKey.length,
          'r1cs.length': r1cs.length,
        },
        'return': result,
      });

      return result == 1;
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

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) async {
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      final (
        id,
        inputBytes,
        keyAssetUrl,
        r1csAssetUrl,
      ) = message as (
        int,
        ProverAlgorithmType,
        String,
        String,
      );
      try {
        final initResponse = await _onInitAlgorithmInIsolate(
          inputBytes,
          keyAssetUrl,
          r1csAssetUrl,
        );
        sendPort.send((id, initResponse));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  static void _startRemoteIsolate((RootIsolateToken, SendPort) args) {
    final (rootToken, sendPort) = args;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
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
