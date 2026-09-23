import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/services/backup_service.dart';
import 'package:vault/data/models/folder.dart';
import 'package:vault/data/models/vault_item.dart';

void main() {
  group('V2 Encrypted Backup & Diff Engine Tests', () {
    final backupService = BackupService();

    final item1 = VaultItem(id: 'i1', type: VaultItemType.login, title: 'Item 1', username: 'user1');
    final item2 = VaultItem(id: 'i2', type: VaultItemType.login, title: 'Item 2', username: 'user2');
    final item3 = VaultItem(id: 'i3', type: VaultItemType.card, title: 'Item 3');
    final folders = [const Folder(id: 'f1', name: 'Personal')];

    test('Cryptographically verifies generated backup with correct password', () async {
      final encryptedBackup = await backupService.createEncryptedBackup(
        items: [item1, item2],
        folders: folders,
        backupPassword: 'SecureBackupPassword123!',
      );

      final isValid = await backupService.verifyBackup(
        rawBackupString: encryptedBackup,
        backupPassword: 'SecureBackupPassword123!',
      );
      expect(isValid, isTrue);

      // Wrong password fails verification
      expect(
        () async => await backupService.verifyBackup(
          rawBackupString: encryptedBackup,
          backupPassword: 'WrongPassword!',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Accurately computes backup restore diff (Added, Removed, Modified, Unchanged)', () {
      final currentItems = [
        item1,
        item2, // Will be modified in backup
        item3, // Will be removed in backup
      ];

      final modifiedItem2 = item2.copyWith(username: 'user2_updated', title: 'Item 2 Modified');
      final newItem4 = VaultItem(id: 'i4', type: VaultItemType.note, title: 'New Note');

      final backupItems = [
        item1,         // Unchanged
        modifiedItem2, // Modified
        newItem4,      // Added
      ];

      final diff = backupService.computeRestoreDiff(
        backupItems: backupItems,
        currentItems: currentItems,
      );

      expect(diff.currentCount, equals(3));
      expect(diff.backupCount, equals(3));
      expect(diff.unchangedCount, equals(1));
      expect(diff.addedCount, equals(1));
      expect(diff.addedItems.first.id, equals('i4'));
      expect(diff.modifiedCount, equals(1));
      expect(diff.modifiedItems.first.id, equals('i2'));
      expect(diff.removedCount, equals(1));
      expect(diff.removedItems.first.id, equals('i3'));
      expect(diff.hasChanges, isTrue);
    });
  });
}
