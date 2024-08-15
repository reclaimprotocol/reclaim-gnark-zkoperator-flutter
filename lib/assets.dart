import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

final _client = () {
  final dio = Dio();
  if (Platform.isAndroid || Platform.isIOS) {
    dio.httpClientAdapter = NativeAdapter(
      createCupertinoConfiguration: () {
        return URLSessionConfiguration.ephemeralSessionConfiguration();
      },
    );
  }
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

const _gnarkAssetBaseUrl = 'https://gnark-assets.s3.ap-south-1.amazonaws.com';

enum KeyAlgorithmType {
  CHACHA20(0, 'bits'),
  AES_128(1, 'aes128'),
  AES_256(2, 'aes256');

  final int id;
  final String key;

  const KeyAlgorithmType(this.id, this.key);

  Future<Uint8List?> fetchKeyAsset() {
    return _loadAssetsIfRequired('$_gnarkAssetBaseUrl/pk.$key');
  }

  Future<Uint8List?> fetchR1CSAsset() {
    return _loadAssetsIfRequired('$_gnarkAssetBaseUrl/r1cs.$key');
  }

  Future<void> precacheAssets() async {
    await Future.wait([fetchKeyAsset(), fetchR1CSAsset()]);
  }
}
