import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/constants/app_constants.dart';
import 'package:vault/core/services/storage_service.dart';
import 'package:vault/data/models/vault_item.dart';
import 'package:vault/data/repositories/vault_repository.dart';

class FakeStorageService extends StorageService {
  String? _vaultData;

  @override
  Future<String?> getEncryptedVaultData() async => _vaultData;

  @override
  Future<void> saveEncryptedVaultData(String data) async {
    _vaultData = data;
  }

  @override
  Future<int> getTrashRetentionDays() async => 30;

  @override
  Future<SortOption> getSortOption() async => SortOption.nameAsc;
}

void main() {
  group('V2 Tags, Search, Sorting, and Bulk Actions Tests', () {
    late VaultRepository repo;
    late SecretKey activeKey;

    setUp(() async {
      repo = VaultRepository(storageService: FakeStorageService());
      activeKey = SecretKey([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
      await repo.loadVault(activeKey);

      await repo.addItem(
        VaultItem(
          id: '1',
          type: VaultItemType.login,
          title: 'Apple ID',
          tags: ['personal', 'apple'],
          isFavorite: true,
          totpSecret: 'JBSWY3DPEHPK3PXP',
          folder: 'Personal',
        ),
        activeKey,
      );

      await repo.addItem(
        VaultItem(
          id: '2',
          type: VaultItemType.login,
          title: 'Google Suite',
          tags: ['work', 'google'],
          folder: 'Work',
        ),
        activeKey,
      );

      await repo.addItem(
        VaultItem(
          id: '3',
          type: VaultItemType.card,
          title: 'Chase Sapphire',
          tags: ['finance', 'personal'],
          folder: 'Finance',
        ),
        activeKey,
      );
    });

    test('Collects unique tags across active items alphabetically', () {
      final tags = repo.allTags;
      expect(tags, equals(['apple', 'finance', 'google', 'personal', 'work']));
    });

    test('Filters by specific tag', () {
      final personalItems = repo.search(query: '', tagFilter: 'personal');
      expect(personalItems.length, equals(2));
      expect(personalItems.map((e) => e.id), containsAll(['1', '3']));

      final workItems = repo.search(query: '', tagFilter: 'work');
      expect(workItems.length, equals(1));
      expect(workItems.first.title, equals('Google Suite'));
    });

    test('Filters by TOTP enabled only', () {
      final totpItems = repo.search(query: '', hasTotpOnly: true);
      expect(totpItems.length, equals(1));
      expect(totpItems.first.title, equals('Apple ID'));
    });

    test('Sorts items correctly (Name Asc / Desc)', () {
      final asc = repo.search(query: '', sortOption: SortOption.nameAsc);
      expect(asc.map((e) => e.title).toList(), equals(['Apple ID', 'Chase Sapphire', 'Google Suite']));

      final desc = repo.search(query: '', sortOption: SortOption.nameDesc);
      expect(desc.map((e) => e.title).toList(), equals(['Google Suite', 'Chase Sapphire', 'Apple ID']));
    });

    test('Bulk operations: bulkAddTag, bulkMoveToFolder, bulkSetFavorite', () async {
      // Bulk add tag
      await repo.bulkAddTag(['1', '2'], 'urgent', activeKey);
      expect(repo.activeItems.firstWhere((i) => i.id == '1').tags, contains('urgent'));
      expect(repo.activeItems.firstWhere((i) => i.id == '2').tags, contains('urgent'));

      // Bulk move to folder
      await repo.bulkMoveToFolder(['1', '2', '3'], 'Archived', activeKey);
      expect(repo.activeItems.every((i) => i.folder == 'Archived'), isTrue);

      // Bulk set favorite
      await repo.bulkSetFavorite(['2', '3'], true, activeKey);
      expect(repo.activeItems.every((i) => i.isFavorite), isTrue);
    });

    test('Tag renaming and deletion across items', () async {
      await repo.renameTag('personal', 'private', activeKey);
      expect(repo.allTags, contains('private'));
      expect(repo.allTags, isNot(contains('personal')));

      await repo.deleteTag('private', activeKey);
      expect(repo.allTags, isNot(contains('private')));
    });
  });
}
