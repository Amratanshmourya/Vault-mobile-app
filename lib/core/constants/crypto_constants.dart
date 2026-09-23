class CryptoConstants {
  // Key Derivation Parameters
  static const int pbkdf2Iterations = 100000;
  static const int saltLengthBytes = 16;
  static const int keyLengthBytes = 32; // 256-bit key for AES-256
  static const int ivLengthBytes = 12;   // 96-bit nonce for AES-GCM
  static const int tagLengthBits = 128;  // 128-bit authentication tag

  // Backup format version
  static const int currentBackupVersion = 1;
  static const String kdfAlgorithm = 'PBKDF2-HMAC-SHA256';
  static const String cipherAlgorithm = 'AES-256-GCM';
}
