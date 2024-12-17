import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:logging/logging.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

final _client = () {
  final logger =
      Logger('reclaim_flutter_sdk.gnarkprover._client.RetryInterceptor');
  final dio = Dio();
  if (Platform.isAndroid || Platform.isIOS) {
    dio.httpClientAdapter = NativeAdapter(
      createCupertinoConfiguration: () {
        return URLSessionConfiguration.ephemeralSessionConfiguration();
      },
    );
  }
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: logger.fine,
    retries: 3,
    retryDelays: const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  ));
  return dio;
}();

final _gnarkAssetCache = <String, Uint8List>{};

Future<Uint8List?> _loadAssetsIfRequired(String assetUrl) async {
  if (_gnarkAssetCache[assetUrl] != null) return _gnarkAssetCache[assetUrl];
  // TODO(mushaheed): handle exponential retries on failures
  final response = await _client.get(
    assetUrl,
    options: Options(responseType: ResponseType.bytes),
  );
  final status = response.statusCode;
  if (status != null && status >= 200 && status < 300) {
    final data = response.data;
    if (data is Uint8List && data.isNotEmpty) {
      _gnarkAssetCache[assetUrl] = data;
      return data;
    }
  }
  return null;
}

const _gnarkAssetBaseUrl = 'https://d1e3okc3py860p.cloudfront.net';

enum KeyAlgorithmType {
  CHACHA20(0, 'chacha20'),
  AES_128(1, 'aes128'),
  AES_256(2, 'aes256');

  final int id;
  final String key;

  const KeyAlgorithmType(this.id, this.key);

  String get defaultKeyAssetUrl => '$_gnarkAssetBaseUrl/pk.$key';
  String get defaultR1CSAssetUrl => '$_gnarkAssetBaseUrl/r1cs.$key';

  Future<Uint8List?> fetchKeyAsset(String url) {
    return _loadAssetsIfRequired(url);
  }

  Future<Uint8List?> fetchR1CSAsset(String url) {
    return _loadAssetsIfRequired(url);
  }

  Future<void> precacheAssets(String keyAssetUrl, String r1csAssetUrl) async {
    await Future.wait([
      fetchKeyAsset(keyAssetUrl),
      fetchR1CSAsset(r1csAssetUrl),
    ]);
  }
}
