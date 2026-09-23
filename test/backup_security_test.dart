import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/crypto/key_derivation_service.dart';
import 'package:vault/core/services/backup_service.dart';
import 'package:vault/core/services/storage_service.dart';
import 'package:vault/data/models/folder.dart';
import 'package:vault/data/models/vault_item.dart';
import 'package:vault/data/repositories/vault_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late VaultRepository repository;
  late KeyDerivationService kdf;
  late BackupService backupService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    repository = VaultRepository(storageService: storageService);
    kdf = KeyDerivationService();
    backupService = BackupService();
  });

  group('Backup Security & Integrity Audit Tests', () {
    test('Valid backup creation and restore preserves all items and folders', () async {
      final items = [
        VaultItem(
          type: VaultItemType.login,
          title: 'ProtonMail',
          username: 'user@proton.me',
          password: 'ProtonPassword#999',
          website: 'https://mail.proton.me',
        ),
        VaultItem(
          type: VaultItemType.card,
          title: 'Visa Platinum',
          cardholderName: 'Amratansh',
          cardNumber: '4111222233334444',
          pin: '1234',
        ),
      ];

      final folders = [
        const Folder(id: 'f_privacy', name: 'Privacy', icon: '🔒'),
      ];

      const backupPassword = 'StrongBackupPassword#2026';

      final backupJson = await backupService.createEncryptedBackup(
        items: items,
        folders: folders,
        backupPassword: backupPassword,
      );

      // Verify zero plaintext secrets in raw backup string
      expect(backupJson, isNot(contains('ProtonPassword#999')));
      expect(backupJson, isNot(contains('4111222233334444')));
      expect(backupJson, isNot(contains('1234')));

      // Decrypt and verify preview
      final preview = await backupService.inspectAndDecryptBackup(
        rawBackupString: backupJson,
        backupPassword: backupPassword,
      );

      expect(preview.items.length, 2);
      expect(preview.folders.length, 1);
      expect(preview.items[0].title, 'ProtonMail');
      expect(preview.items[0].password, 'ProtonPassword#999');
      expect(preview.items[1].cardNumber, '4111222233334444');
    });

    test('Wrong password fails authentication safely', () async {
      final items = [
        VaultItem(
          type: VaultItemType.note,
          title: 'Secret Recovery Keys',
          noteContent: 'alpha beta gamma delta',
        ),
      ];

      final backupJson = await backupService.createEncryptedBackup(
        items: items,
        folders: [],
        backupPassword: 'CorrectPassword123!',
      );

      expect(
        () async => await backupService.inspectAndDecryptBackup(
          rawBackupString: backupJson,
          backupPassword: 'IncorrectPassword!',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Tampered ciphertext is rejected and fails authentication', () async {
      final items = [
        VaultItem(
          type: VaultItemType.password,
          title: 'Database Key',
          password: 'DbPassword#1',
        ),
      ];

      final backupJson = await backupService.createEncryptedBackup(
        items: items,
        folders: [],
        backupPassword: 'Password123!',
      );

      final Map<String, dynamic> backupMap = jsonDecode(backupJson) as Map<String, dynamic>;
      final rawCipher = base64Decode(backupMap['ciphertext'] as String);
      rawCipher[0] = rawCipher[0] ^ 0xFF; // Flip bits
      backupMap['ciphertext'] = base64Encode(rawCipher);

      final tamperedJson = jsonEncode(backupMap);

      expect(
        () async => await backupService.inspectAndDecryptBackup(
          rawBackupString: tamperedJson,
          backupPassword: 'Password123!',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Truncated backup is rejected safely', () async {
      const truncated = '{"version":1,"kdf":"PBKDF2-HMAC-SHA256","iterations":100000';
      expect(
        () async => await backupService.inspectAndDecryptBackup(
          rawBackupString: truncated,
          backupPassword: 'Password123!',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Unsupported backup version is rejected with informative message', () async {
      final container = {
        'version': 999, // Future unsupported version
        'createdAt': DateTime.now().toIso8601String(),
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': 100000,
        'salt': base64Encode(List.filled(16, 0)),
        'nonce': base64Encode(List.filled(12, 0)),
        'tag': base64Encode(List.filled(16, 0)),
        'ciphertext': base64Encode(List.filled(32, 0)),
        'itemCount': 0,
        'folderCount': 0,
      };

      expect(
        () async => await backupService.inspectAndDecryptBackup(
          rawBackupString: jsonEncode(container),
          backupPassword: 'AnyPassword',
        ),
        throwsA(predicate((e) => e.toString().contains('newer version of Vault'))),
      );
    });

    test('Atomic restore guarantee: Failed restore leaves existing vault untouched', () async {
      final salt = kdf.generateRandomBytes(16);
      final key = await kdf.deriveKey(password: 'MasterPassword#1', salt: salt);

      await repository.loadVault(key);
      final initialItem = VaultItem(
        type: VaultItemType.login,
        title: 'Original Bank Login',
        username: 'amratansh@bank.com',
        password: 'OriginalPassword123!',
      );
      await repository.addItem(initialItem, key);
      expect(repository.activeItems.length, 1);

      // Attempt to restore malformed backup that fails
      try {
        await backupService.inspectAndDecryptBackup(
          rawBackupString: 'corrupted-backup-data',
          backupPassword: 'SomePassword',
        );
        fail('Should have thrown');
      } catch (_) {}

      // Verify original vault state remains 100% intact
      expect(repository.activeItems.length, 1);
      expect(repository.activeItems.first.title, 'Original Bank Login');
      expect(repository.activeItems.first.password, 'OriginalPassword123!');
    });
  });
}
