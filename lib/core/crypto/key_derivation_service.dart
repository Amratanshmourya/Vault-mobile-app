import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../constants/crypto_constants.dart';

class KeyDerivationService {
  /// Generates cryptographically secure random bytes of specified length.
  Uint8List generateRandomBytes([int length = CryptoConstants.saltLengthBytes]) {
    final secureRandom = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = secureRandom.nextInt(256);
    }
    return bytes;
  }

  /// Derives a 256-bit encryption key from a master password and salt using PBKDF2-HMAC-SHA256.
  Future<SecretKey> deriveKey({
    required String password,
    required Uint8List salt,
    int iterations = CryptoConstants.pbkdf2Iterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: CryptoConstants.keyLengthBytes * 8,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return secretKey;
  }

  /// Calculates a verification hash for the master password to verify unlock without storing plaintext.
  Future<String> calculateMasterHash({
    required String password,
    required Uint8List salt,
  }) async {
    final derived = await deriveKey(password: password, salt: salt);
    final keyBytes = await derived.extractBytes();
    // Additional SHA-256 pass over derived key for the stored verifier
    final sha256 = Sha256();
    final hash = await sha256.hash(keyBytes);
    return base64Encode(hash.bytes);
  }
}
