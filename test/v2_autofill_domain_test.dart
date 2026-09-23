import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/services/autofill_matching_service.dart';
import 'package:vault/data/models/vault_item.dart';

void main() {
  group('V2 Strict Anti-Phishing Autofill Matching Tests', () {
    final testItems = [
      VaultItem(
        id: '1',
        type: VaultItemType.login,
        title: 'Google Account',
        website: 'https://accounts.google.com/signin',
        username: 'user@gmail.com',
      ),
      VaultItem(
        id: '2',
        type: VaultItemType.login,
        title: 'GitHub',
        website: 'github.com',
        username: 'octocat',
      ),
      VaultItem(
        id: '3',
        type: VaultItemType.login,
        title: 'Amazon Shopping',
        website: 'www.amazon.com/gp/signin',
        username: 'amazon_user',
      ),
      VaultItem(
        id: '4',
        type: VaultItemType.login,
        title: 'Work Email',
        website: 'https://mail.company.co.uk/login',
        username: 'employee@company.co.uk',
      ),
    ];

    test('Normalizes various URL formats to standard base domains', () {
      expect(AutofillMatchingService.normalizeUrlOrHost('https://www.github.com/login'), equals('github.com'));
      expect(AutofillMatchingService.normalizeUrlOrHost('http://github.com'), equals('github.com'));
      expect(AutofillMatchingService.normalizeUrlOrHost('GITHUB.COM'), equals('github.com'));
      expect(AutofillMatchingService.normalizeUrlOrHost('accounts.google.com'), equals('accounts.google.com'));
      expect(AutofillMatchingService.extractBaseDomain('accounts.google.com'), equals('google.com'));
      expect(AutofillMatchingService.extractBaseDomain('sub.mail.company.co.uk'), equals('company.co.uk'));
    });

    test('Matches exact and subdomain logins strictly', () {
      final matches1 = AutofillMatchingService.findMatchingLogins(
        targetUrlOrHost: 'https://github.com/login',
        items: testItems,
      );
      expect(matches1.length, equals(1));
      expect(matches1.first.title, equals('GitHub'));

      final matches2 = AutofillMatchingService.findMatchingLogins(
        targetUrlOrHost: 'https://accounts.google.com',
        items: testItems,
      );
      expect(matches2.length, equals(1));
      expect(matches2.first.title, equals('Google Account'));
    });

    test('Rejects phishing and spoofed lookalike domains', () {
      // Fake / phishing domain should NOT match legitimate accounts
      final phishMatches1 = AutofillMatchingService.findMatchingLogins(
        targetUrlOrHost: 'https://github.com.attacker.com',
        items: testItems,
      );
      expect(phishMatches1, isEmpty);

      final phishMatches2 = AutofillMatchingService.findMatchingLogins(
        targetUrlOrHost: 'https://fake-google.com',
        items: testItems,
      );
      expect(phishMatches2, isEmpty);

      final phishMatches3 = AutofillMatchingService.findMatchingLogins(
        targetUrlOrHost: 'https://amazon.com.fake.org',
        items: testItems,
      );
      expect(phishMatches3, isEmpty);
    });
  });
}
