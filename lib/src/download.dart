import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

final _clientInstance = () {
  final logger = Logger(
    'reclaim_flutter_sdk.reclaim_gnark_zkoperator._client.RetryInterceptor',
  );
  final dio = Dio();
  if (Platform.isIOS) {
    dio.httpClientAdapter = NativeAdapter(
      createCupertinoConfiguration: () {
        return URLSessionConfiguration.defaultSessionConfiguration();
      },
    );
  } else if (Platform.isAndroid) {
    dio.httpClientAdapter = NativeAdapter(
      createCronetEngine: () {
        return CronetEngine.build(
          cacheMode: CacheMode.disk,
          enableBrotli: true,
          enableHttp2: true,
          enableQuic: true,
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
  final client = _clientInstance;
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
