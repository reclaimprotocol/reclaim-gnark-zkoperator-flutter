import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

final _clientInstanceFuture = () async {
  final logger =
      Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator._client.RetryInterceptor');
  final dio = Dio();
  if (Platform.isIOS) {
    dio.httpClientAdapter = NativeAdapter(
      createCupertinoConfiguration: () {
        return URLSessionConfiguration.defaultSessionConfiguration();
      },
    );
  } else if (Platform.isAndroid) {
    final cacheDir = await path_provider.getApplicationCacheDirectory();
    final cronetCacheDir = Directory(path.join(
      cacheDir.absolute.path,
      'gnark-assets-cache',
    ));
    await cronetCacheDir.create(
      recursive: true,
    );
    dio.httpClientAdapter = NativeAdapter(
      createCronetEngine: () {
        return CronetEngine.build(
          cacheMode: CacheMode.disk,
          enableBrotli: true,
          enableHttp2: true,
          enableQuic: true,
          storagePath: cronetCacheDir.path,
        );
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

Future<Uint8List?> downloadWithHttp(String url) async {
  final client = await _clientInstanceFuture;
  final response = await client.get(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  final status = response.statusCode;
  if (status != null && status >= 200 && status < 300) {
    final data = response.data;
    if (data is Uint8List && data.isNotEmpty) {
      return data;
    }
  }
  return null;
}
