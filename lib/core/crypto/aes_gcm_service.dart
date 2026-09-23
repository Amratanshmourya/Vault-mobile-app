import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../constants/crypto_constants.dart';
import 'key_derivation_service.dart';

class EncryptedPayload {
  final String ciphertextBase64;
  final String nonceBase64;
  final String tagBase64;

  EncryptedPayload({
    required this.ciphertextBase64,
    required this.nonceBase64,
    required this.tagBase64,
  });

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertextBase64,
    'nonce': nonceBase64,
    'tag': tagBase64,
  };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) => EncryptedPayload(
    ciphertextBase64: json['ciphertext'] as String,
    nonceBase64: json['nonce'] as String,
    tagBase64: json['tag'] as String,
  );

  String serialize() => jsonEncode(toJson());

  factory EncryptedPayload.deserialize(String raw) =>
      EncryptedPayload.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class AesGcmService {
  final AesGcm _aesGcm = AesGcm.with256bits();
  final KeyDerivationService _keyDerivationService = KeyDerivationService();

  /// Encrypts plaintext string using AES-256-GCM and returns EncryptedPayload.
  Future<EncryptedPayload> encrypt({
    required String plainText,
    required SecretKey secretKey,
  }) async {
    final nonce = _keyDerivationService.generateRandomBytes(CryptoConstants.ivLengthBytes);
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptedPayload(
      ciphertextBase64: base64Encode(secretBox.cipherText),
      nonceBase64: base64Encode(secretBox.nonce),
      tagBase64: base64Encode(secretBox.mac.bytes),
    );
  }

  /// Decrypts an EncryptedPayload using AES-256-GCM.
  /// Throws an exception if authentication fails or data is tampered.
  Future<String> decrypt({
    required EncryptedPayload payload,
    required SecretKey secretKey,
  }) async {
    final cipherText = base64Decode(payload.ciphertextBase64);
    final nonce = base64Decode(payload.nonceBase64);
    final tagBytes = base64Decode(payload.tagBase64);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(tagBytes),
    );

    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }
}
