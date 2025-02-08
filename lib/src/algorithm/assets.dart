import 'algorithm.dart';

const _gnarkAssetBaseUrl = 'https://d5znggfgtutzp.cloudfront.net';

extension ProverAlgorithmTypeAssets on ProverAlgorithmType {
  String get defaultKeyAssetUrl => '$_gnarkAssetBaseUrl/pk.$key';
  String get defaultR1CSAssetUrl => '$_gnarkAssetBaseUrl/r1cs.$key';
}
