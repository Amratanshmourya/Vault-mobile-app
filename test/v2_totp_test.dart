import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/crypto/totp_service.dart';

void main() {
  group('V2 RFC 6238 TOTP Engine Tests', () {
    const secret = 'JBSWY3DPEHPK3PXP'; // Standard Base32 test vector

    test('Validates Base32 secret strings', () {
      expect(TotpService.isValidSecret('JBSWY3DPEHPK3PXP'), isTrue);
      expect(TotpService.isValidSecret('jbsw y3dp ehpk 3pxp'), isTrue); // With whitespace
      expect(TotpService.isValidSecret('12345'), isFalse);
      expect(TotpService.isValidSecret(''), isFalse);
      expect(TotpService.isValidSecret('INVALID!@#'), isFalse);
    });

    test('Generates deterministic 6-digit TOTP code for timestamp', () {
      final time = DateTime.fromMillisecondsSinceEpoch(1600000000000); // Fixed epoch
      final code = TotpService.generateCode(secret, timestamp: time);
      expect(code, isNotNull);
      expect(code!.length, equals(6));
      expect(int.tryParse(code), isNotNull);

      final code2 = TotpService.generateCode(secret, timestamp: time);
      expect(code, equals(code2));
    });

    test('Computes correct remaining seconds for time window', () {
      final remaining = TotpService.getRemainingSeconds(periodSeconds: 30);
      expect(remaining, greaterThanOrEqualTo(1));
      expect(remaining, lessThanOrEqualTo(30));

      final progress = TotpService.getProgress(periodSeconds: 30);
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });

    test('Parses standard otpauth:// URIs with issuer and account name', () {
      const uri1 = 'otpauth://totp/Google:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Google&digits=6&period=30';
      final parsed1 = TotpService.parseOtpAuthUri(uri1);
      expect(parsed1, isNotNull);
      expect(parsed1!.secret, equals('JBSWY3DPEHPK3PXP'));
      expect(parsed1.issuer, equals('Google'));
      expect(parsed1.accountName, equals('user@example.com'));
      expect(parsed1.digits, equals(6));
      expect(parsed1.periodSeconds, equals(30));

      const uri2 = 'otpauth://totp/GitHub:octocat?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ';
      final parsed2 = TotpService.parseOtpAuthUri(uri2);
      expect(parsed2, isNotNull);
      expect(parsed2!.secret, equals('HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ'));
      expect(parsed2.issuer, equals('GitHub'));
      expect(parsed2.accountName, equals('octocat'));

      // Non-otpauth URI returns null
      expect(TotpService.parseOtpAuthUri('https://example.com'), isNull);
    });
  });
}
