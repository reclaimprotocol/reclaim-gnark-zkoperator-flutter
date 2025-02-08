import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:cronet_http/cronet_http.dart' as cronet;
import 'package:cupertino_http/cupertino_http.dart' as cupertino;
import 'package:retry/retry.dart';

import 'package:flutter/services.dart';

http.Client _buildClient() {
  if (Platform.isAndroid) {
    final cacheDir = Directory.systemTemp.createTempSync('cronet_cache');
    return cronet.CronetClient.fromCronetEngine(
      cronet.CronetEngine.build(
        cacheMode: cronet.CacheMode.disk,
        // 200MB cache
        cacheMaxSize: 200 * 1024 * 1024,
        storagePath: cacheDir.path,
        enableBrotli: true,
        enableHttp2: true,
        enableQuic: true,
      ),
      closeEngine: true,
    );
  } else if (Platform.isIOS || Platform.isMacOS) {
    return cupertino.CupertinoClient.fromSessionConfiguration(
      cupertino.URLSessionConfiguration.defaultSessionConfiguration(),
    );
  }
  return http.Client();
}

class _RetryableHttpException extends http.ClientException {
  _RetryableHttpException(super.message, [super.uri]);
}

class _EmptyResponseException extends http.ClientException {
  _EmptyResponseException(String message, [Uri? uri])
      : super('Empty response: $message', uri);
}

extension _ReadUnstreamed on http.Client {
  String _createMessage(http.BaseResponse response, Uri url) {
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    return message;
  }

  Future<Uint8List> readUnstreamed(Uri uri) async {
    final request = http.Request('GET', uri);
    final streamedResponse = await send(request);
    final bodyBytes = await streamedResponse.stream.toBytes();
    final statusCode = streamedResponse.statusCode;
    if (statusCode >= 500) {
      throw _RetryableHttpException(
        _createMessage(streamedResponse, uri),
        uri,
      );
    }
    if (bodyBytes.isEmpty) {
      throw _EmptyResponseException(
        _createMessage(streamedResponse, uri),
        uri,
      );
    }
    return bodyBytes;
  }
}

/// Defaults to true to download with single connection on an isolate.
/// Retries will use the same client.
const _useSingleClient = bool.fromEnvironment(
  'org.reclaimprotocol.gnark_zkoperator.USE_SINGLE_HTTP_CLIENT',
  defaultValue: true,
);

http.Client? _commonClient;

Future<Uint8List?> downloadWithHttp(
  String url, [
  bool useSingleClient = _useSingleClient,
]) async {
  final uri = Uri.parse(url);
  final client = useSingleClient
      // Only build the client once if [_commonClient] is null
      ? (_commonClient ??= _buildClient())
      // Build a new client for each download
      : _buildClient();

  try {
    final response = await retry(
      () {
        return client.readUnstreamed(uri);
      },
      // Retry on SocketException or TimeoutException or _RetryableHttpException
      retryIf: (e) {
        return e is SocketException ||
            e is TimeoutException ||
            e is _RetryableHttpException ||
            e is _EmptyResponseException;
      },
    );
    if (!useSingleClient) {
      client.close();
    }
    return response;
  } catch (_) {
    if (!useSingleClient) {
      client.close();
    }
    rethrow;
  }
}
