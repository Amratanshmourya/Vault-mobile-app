import 'dart:convert';
import '../../core/constants/crypto_constants.dart';

class VaultBackupContainer {
  final int version;
  final DateTime createdAt;
  final String kdf;
  final int iterations;
  final String saltBase64;
  final String nonceBase64;
  final String tagBase64;
  final String ciphertextBase64;
  final int itemCount;
  final int folderCount;

  VaultBackupContainer({
    this.version = CryptoConstants.currentBackupVersion,
    required this.createdAt,
    this.kdf = CryptoConstants.kdfAlgorithm,
    this.iterations = CryptoConstants.pbkdf2Iterations,
    required this.saltBase64,
    required this.nonceBase64,
    required this.tagBase64,
    required this.ciphertextBase64,
    required this.itemCount,
    required this.folderCount,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'kdf': kdf,
    'iterations': iterations,
    'salt': saltBase64,
    'nonce': nonceBase64,
    'tag': tagBase64,
    'ciphertext': ciphertextBase64,
    'itemCount': itemCount,
    'folderCount': folderCount,
  };

  factory VaultBackupContainer.fromJson(Map<String, dynamic> json) => VaultBackupContainer(
    version: json['version'] as int? ?? 1,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    kdf: json['kdf'] as String? ?? CryptoConstants.kdfAlgorithm,
    iterations: json['iterations'] as int? ?? CryptoConstants.pbkdf2Iterations,
    saltBase64: json['salt'] as String,
    nonceBase64: json['nonce'] as String,
    tagBase64: json['tag'] as String,
    ciphertextBase64: json['ciphertext'] as String,
    itemCount: json['itemCount'] as int? ?? 0,
    folderCount: json['folderCount'] as int? ?? 0,
  );

  String serialize() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory VaultBackupContainer.deserialize(String raw) =>
      VaultBackupContainer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
