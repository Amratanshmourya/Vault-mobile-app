import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/crypto/aes_gcm_service.dart';
import 'package:vault/core/crypto/key_derivation_service.dart';
import 'package:vault/core/crypto/password_generator.dart';
import 'package:vault/core/crypto/password_strength.dart';
import 'package:vault/core/crypto/totp_service.dart';

void main() {
  group('KeyDerivationService Tests', () {
    final kdf = KeyDerivationService();

    test('Derives key and calculates deterministic master hash', () async {
      final salt = kdf.generateRandomBytes(16);
      expect(salt.length, 16);

      final key1 = await kdf.deriveKey(password: 'MySecretMasterKey123!', salt: salt);
      final key2 = await kdf.deriveKey(password: 'MySecretMasterKey123!', salt: salt);

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();
      expect(bytes1, equals(bytes2));

      final hash1 = await kdf.calculateMasterHash(password: 'MySecretMasterKey123!', salt: salt);
      final hash2 = await kdf.calculateMasterHash(password: 'MySecretMasterKey123!', salt: salt);
      expect(hash1, equals(hash2));

      final hashWrong = await kdf.calculateMasterHash(password: 'WrongPassword!', salt: salt);
      expect(hash1, isNot(equals(hashWrong)));
    });
  });

  group('AesGcmService Tests', () {
    final aes = AesGcmService();
    final kdf = KeyDerivationService();

    test('Encrypts and decrypts sensitive payload accurately', () async {
      final salt = kdf.generateRandomBytes(16);
      final key = await kdf.deriveKey(password: 'MasterPassword#2026', salt: salt);

      const plaintext = 'SuperSecretVaultData!#\$%12345';
      final encrypted = await aes.encrypt(plainText: plaintext, secretKey: key);

      expect(encrypted.ciphertextBase64, isNotEmpty);
      expect(encrypted.nonceBase64, isNotEmpty);
      expect(encrypted.tagBase64, isNotEmpty);

      final decrypted = await aes.decrypt(payload: encrypted, secretKey: key);
      expect(decrypted, equals(plaintext));
    });

    test('Fails closed on incorrect key or tampered ciphertext', () async {
      final salt = kdf.generateRandomBytes(16);
      final correctKey = await kdf.deriveKey(password: 'CorrectPassword', salt: salt);
      final wrongKey = await kdf.deriveKey(password: 'WrongPassword', salt: salt);

      final encrypted = await aes.encrypt(plainText: 'Confidential', secretKey: correctKey);

      // Wrong key should fail
      expect(
        () async => await aes.decrypt(payload: encrypted, secretKey: wrongKey),
        throwsA(isA<Exception>()),
      );

      // Tampered ciphertext should fail
      final tamperedCiphertext = base64Encode(
        base64Decode(encrypted.ciphertextBase64).map((b) => b ^ 0xFF).toList(),
      );
      final tamperedPayload = EncryptedPayload(
        ciphertextBase64: tamperedCiphertext,
        nonceBase64: encrypted.nonceBase64,
        tagBase64: encrypted.tagBase64,
      );

      expect(
        () async => await aes.decrypt(payload: tamperedPayload, secretKey: correctKey),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PasswordGenerator Tests', () {
    test('Generates random password with specified constraints', () {
      final pwd = PasswordGenerator.generatePassword(
        const PasswordGeneratorOptions(
          length: 20,
          includeUppercase: true,
          includeLowercase: true,
          includeNumbers: true,
          includeSymbols: true,
        ),
      );

      expect(pwd.length, 20);
      expect(RegExp(r'[A-Z]').hasMatch(pwd), isTrue);
      expect(RegExp(r'[a-z]').hasMatch(pwd), isTrue);
      expect(RegExp(r'[0-9]').hasMatch(pwd), isTrue);
      expect(RegExp(r'[^a-zA-Z0-9]').hasMatch(pwd), isTrue);
    });

    test('Generates readable diceware passphrase', () {
      final phrase = PasswordGenerator.generatePassphrase(
        const PassphraseOptions(
          wordCount: 4,
          separator: '-',
          capitalize: true,
          includeNumber: true,
        ),
      );

      final parts = phrase.split('-');
      expect(parts.length, 4);
      expect(RegExp(r'[0-9]').hasMatch(phrase), isTrue);
    });
  });

  group('PasswordStrength Tests', () {
    test('Identifies common or short passwords as weak', () {
      final resCommon = PasswordStrength.evaluate('123456');
      expect(resCommon.level, equals(PasswordStrengthLevel.veryWeak));

      final resShort = PasswordStrength.evaluate('abc12');
      expect(resShort.level, equals(PasswordStrengthLevel.veryWeak));
    });

    test('Identifies high entropy complex passwords as strong/very strong', () {
      final res = PasswordStrength.evaluate('K8#mQ9!zL2@pX7\$vW4');
      expect(res.level, isIn([PasswordStrengthLevel.strong, PasswordStrengthLevel.veryStrong]));
      expect(res.score, greaterThan(0.8));
    });
  });

  group('TotpService Tests', () {
    test('Computes valid TOTP codes with countdown progress', () {
      // Standard RFC 6238 Base32 test secret: JBSWY3DPEHPK3PXP
      const secret = 'JBSWY3DPEHPK3PXP';
      final testTime = DateTime.fromMillisecondsSinceEpoch(1600000000000); // Fixed timestamp

      final result = TotpService.generateCurrent(
        secretBase32: secret,
        now: testTime,
      );

      expect(result, isNotNull);
      expect(result!.code.length, 6);
      expect(result.formattedCode.length, 7); // "123 456"
      expect(result.remainingSeconds, inInclusiveRange(1, 30));
    });

    test('Validates Base32 secrets accurately', () {
      expect(TotpService.isValidSecret('JBSWY3DPEHPK3PXP'), isTrue);
      expect(TotpService.isValidSecret('jbsw y3dp ehpk 3pxp'), isTrue);
      expect(TotpService.isValidSecret('invalid!#@'), isFalse);
      expect(TotpService.isValidSecret('abc'), isFalse);
    });
  });
}
