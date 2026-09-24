import 'package:flutter_test/flutter_test.dart';
import 'package:vault/data/models/passkey_credential.dart';
import 'package:vault/data/models/vault_item.dart';
import 'package:vault/core/services/autofill_matching_service.dart';

void main() {
  group('V3 Passkey Credential & WebAuthn Tests', () {
    test('Serializes and deserializes PasskeyCredential model correctly', () {
      final passkey = PasskeyCredential(
        rpId: 'github.com',
        rpName: 'GitHub',
        userName: 'alice@example.com',
        userHandle: 'dXNlcl9oYW5kbGVfMTIzNA==',
        credentialId: 'Y3JlZGVudGlhbF9pZF9hYmNkMTIzNA==',
        algorithm: PasskeyAlgorithm.es256,
        authenticatorAttachment: AuthenticatorAttachment.platform,
        transports: ['internal', 'hybrid'],
      );

      final json = passkey.toJson();
      final roundTrip = PasskeyCredential.fromJson(json);

      expect(roundTrip.rpId, 'github.com');
      expect(roundTrip.rpName, 'GitHub');
      expect(roundTrip.userName, 'alice@example.com');
      expect(roundTrip.userHandle, 'dXNlcl9oYW5kbGVfMTIzNA==');
      expect(roundTrip.credentialId, 'Y3JlZGVudGlhbF9pZF9hYmNkMTIzNA==');
      expect(roundTrip.algorithm, PasskeyAlgorithm.es256);
      expect(roundTrip.authenticatorAttachment, AuthenticatorAttachment.platform);
      expect(roundTrip.transports, contains('internal'));
      expect(roundTrip.backupEligible, true);
      expect(roundTrip.backupState, true);
    });

    test('VaultItem embeds Passkey and evaluates hasPasskey flag correctly', () {
      final item = VaultItem(
        type: VaultItemType.passkey,
        title: 'GitHub Passkey',
        passkey: PasskeyCredential(
          rpId: 'github.com',
          rpName: 'GitHub',
          userName: 'alice',
          credentialId: 'cred_12345',
        ),
      );

      expect(item.hasPasskey, isTrue);
      expect(item.normalizedDomain, 'github.com');

      final json = item.toJson();
      final decoded = VaultItem.fromJson(json);

      expect(decoded.hasPasskey, isTrue);
      expect(decoded.type, VaultItemType.passkey);
      expect(decoded.passkey?.rpName, 'GitHub');
      expect(decoded.passkey?.credentialId, 'cred_12345');
    });

    test('Autofill engine finds ranked passkey credentials for target domain', () {
      final items = [
        VaultItem(
          type: VaultItemType.passkey,
          title: 'Google Passkey',
          passkey: PasskeyCredential(
            rpId: 'accounts.google.com',
            rpName: 'Google',
            userName: 'alice@gmail.com',
            credentialId: 'google_cred_1',
          ),
        ),
        VaultItem(
          type: VaultItemType.login,
          title: 'GitHub Login',
          website: 'https://github.com/login',
          username: 'alice',
          password: 'Password123!',
        ),
      ];

      final matches = AutofillMatchingService.findRankedMatches(
        targetUrl: 'https://accounts.google.com/signin',
        items: items,
      );

      expect(matches.length, 1);
      expect(matches.first.item.title, 'Google Passkey');
      expect(matches.first.hasPasskey, isTrue);
      expect(matches.first.isExactHostMatch, isTrue);
    });
  });
}
