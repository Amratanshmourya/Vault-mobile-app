import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/crypto/password_generator.dart';

void main() {
  group('V3 Advanced Password & Diceware Generator Tests', () {
    test('High Security preset generates strong 32-character random string', () {
      final pwd = PasswordGenerator.generatePassword(PasswordGeneratorOptions.highSecurity());
      expect(pwd.length, 32);
      expect(pwd.contains(RegExp(r'[A-Z]')), isTrue);
      expect(pwd.contains(RegExp(r'[a-z]')), isTrue);
      expect(pwd.contains(RegExp(r'[0-9]')), isTrue);
      expect(pwd.contains(RegExp(r'[^a-zA-Z0-9]')), isTrue);
    });

    test('Memorable Passphrase generator generates hyphenated Diceware words', () {
      final passphrase = PasswordGenerator.generatePassphrase(
        const PassphraseOptions(wordCount: 5, separator: '-', capitalize: true, includeNumber: true),
      );
      final parts = passphrase.split('-');
      expect(parts.length, 5);
      expect(parts.every((p) => p.isNotEmpty), isTrue);
      expect(parts.any((p) => p.contains(RegExp(r'[0-9]'))), isTrue);
    });

    test('Numeric PIN generator produces correct digits length', () {
      final pin6 = PasswordGenerator.generatePin(6);
      expect(pin6.length, 6);
      expect(RegExp(r'^\d{6}$').hasMatch(pin6), isTrue);

      final pin8 = PasswordGenerator.generatePin(8);
      expect(pin8.length, 8);
      expect(RegExp(r'^\d{8}$').hasMatch(pin8), isTrue);
    });

    test('Shannon entropy calculation evaluates complexity accurately', () {
      final weakEntropy = PasswordGenerator.calculateEntropy('123456');
      final strongEntropy = PasswordGenerator.calculateEntropy('K9#pL8!vQ2\$xZ0@mY5&w');

      expect(weakEntropy, greaterThan(0));
      expect(strongEntropy, greaterThan(weakEntropy * 3));
    });
  });
}
