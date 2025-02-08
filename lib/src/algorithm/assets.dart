import 'dart:typed_data';
import 'algorithm.dart';
import '../download/download.dart';

final _gnarkAssetCache = <String, Uint8List>{};

Future<Uint8List?> _loadAssetsIfRequired(String assetUrl) async {
  if (_gnarkAssetCache[assetUrl] != null) return _gnarkAssetCache[assetUrl];
  final data = await downloadWithHttp(assetUrl);
  if (data != null) {
    _gnarkAssetCache[assetUrl] = data;
  }
  return data;
}

const _gnarkAssetBaseUrl = 'https://d5znggfgtutzp.cloudfront.net';

extension ProverAlgorithmTypeAssets on ProverAlgorithmType {
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
