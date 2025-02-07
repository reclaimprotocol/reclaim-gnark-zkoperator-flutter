import 'dart:typed_data';
import 'download.dart';

final _gnarkAssetCache = <String, Uint8List>{};

Future<Uint8List?> _loadAssetsIfRequired(String assetUrl) async {
  if (_gnarkAssetCache[assetUrl] != null) return _gnarkAssetCache[assetUrl];
  // TODO(mushaheed): handle exponential retries on failures
  final data = await downloadWithHttp(assetUrl);
  if (data != null) {
    _gnarkAssetCache[assetUrl] = data;
  }
  return data;
}

const _gnarkAssetBaseUrl = 'https://d5znggfgtutzp.cloudfront.net';

// Reference: https://github.com/reclaimprotocol/zk-symmetric-crypto/blob/31cb348f26a4c959b9d426d86d37b8d25821aae8/gnark/libraries/prover/impl/library.go#L18
enum KeyAlgorithmType {
  CHACHA20(0, 'chacha20'),
  AES_128(1, 'aes128'),
  AES_256(2, 'aes256'),
  CHACHA20_OPRF(3, 'chacha20_oprf'),
  AES_128_OPRF(4, 'aes128_oprf'),
  AES_256_OPRF(5, 'aes256_oprf');

  static const List<KeyAlgorithmType> oprf = [
    CHACHA20_OPRF,
    AES_128_OPRF,
    AES_256_OPRF,
  ];

  static const List<KeyAlgorithmType> nonOprf = [
    CHACHA20,
    AES_128,
    AES_256,
  ];

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
