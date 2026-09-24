import 'package:flutter_test/flutter_test.dart';
import 'package:vault/data/models/security_audit_result.dart';
import 'package:vault/data/models/vault_item.dart';
import 'package:vault/data/models/passkey_credential.dart';

void main() {
  group('V3 Advanced Security Audit Tests', () {
    test('Zero-Knowledge password reuse detects identical passwords without cleartext grouping', () {
      final items = [
        VaultItem(type: VaultItemType.login, title: 'Service A', password: 'SharedPassword99!'),
        VaultItem(type: VaultItemType.login, title: 'Service B', password: 'SharedPassword99!'),
        VaultItem(type: VaultItemType.login, title: 'Service C', password: 'UniquePassword123!'),
      ];

      final audit = SecurityAuditResult.analyze(items);

      expect(audit.reusedGroups.length, 1);
      expect(audit.reusedGroups.first.items.length, 2);
      expect(audit.reusedGroups.first.passwordHash.length, 64); // SHA-256 hash length
    });

    test('Detects passkey upgrade opportunities on compatible domains', () {
      final items = [
        VaultItem(
          type: VaultItemType.login,
          title: 'Google Login',
          website: 'https://accounts.google.com',
          username: 'alice@gmail.com',
          password: 'Password123!',
        ),
        VaultItem(
          type: VaultItemType.login,
          title: 'GitHub Login',
          website: 'https://github.com',
          username: 'alice',
          password: 'Password123!',
          passkey: PasskeyCredential(
            rpId: 'github.com',
            rpName: 'GitHub',
            userName: 'alice',
            credentialId: 'cred_gh_1',
          ),
        ),
      ];

      final audit = SecurityAuditResult.analyze(items);

      expect(audit.passkeyOpportunities.length, 1);
      expect(audit.passkeyOpportunities.first.serviceName, 'Google');
      expect(audit.passkeyCount, 1);
    });
  });
}
