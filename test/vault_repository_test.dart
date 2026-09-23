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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    repository = VaultRepository(storageService: storageService);
    kdf = KeyDerivationService();
  });

  test('Vault CRUD and Search Operations', () async {
    final salt = kdf.generateRandomBytes(16);
    final key = await kdf.deriveKey(password: 'MasterPassword#1', salt: salt);

    await repository.loadVault(key);
    expect(repository.activeItems.length, 0);

    // Add items
    final item1 = VaultItem(
      type: VaultItemType.login,
      title: 'GitHub',
      username: 'amratansh@github.com',
      password: 'SuperSecretGitHubPassword123!',
      website: 'https://github.com',
      folder: 'Work',
      isFavorite: true,
      tags: ['git', 'code'],
    );

    final item2 = VaultItem(
      type: VaultItemType.card,
      title: 'Work Corporate Card',
      cardholderName: 'Amratansh',
      cardNumber: '4532111122223333',
      folder: 'Finance',
      isFavorite: false,
    );

    await repository.addItem(item1, key);
    await repository.addItem(item2, key);

    expect(repository.activeItems.length, 2);
    expect(repository.activeItems.where((i) => i.isFavorite).length, 1);

    // Search tests
    final searchGit = repository.search(query: 'github');
    expect(searchGit.length, 1);
    expect(searchGit.first.title, 'GitHub');

    final searchWork = repository.search(query: 'Work');
    expect(searchWork.length, 2);

    final searchCardsOnly = repository.search(query: '', typeFilter: VaultItemType.card);
    expect(searchCardsOnly.length, 1);
    expect(searchCardsOnly.first.title, 'Work Corporate Card');

    // Trash Lifecycle
    await repository.moveToTrash(item1.id, key);
    expect(repository.activeItems.length, 1);
    expect(repository.trashItems.length, 1);

    // Restore from trash
    await repository.restoreFromTrash(item1.id, key);
    expect(repository.activeItems.length, 2);
    expect(repository.trashItems.length, 0);

    // Permanent delete
    await repository.permanentlyDeleteItem(item2.id, key);
    expect(repository.activeItems.length, 1);
  });

  test('Encrypted Backup and Restore Flow', () async {
    final backupService = BackupService();

    final testItems = [
      VaultItem(
        type: VaultItemType.login,
        title: 'AWS Cloud',
        username: 'amratansh@aws.com',
        password: 'AwsPassword#9876',
      ),
      VaultItem(
        type: VaultItemType.note,
        title: 'Recovery Codes',
        noteContent: 'code-1\ncode-2\ncode-3',
      ),
    ];

    final testFolders = [
      const Folder(id: 'f1', name: 'Cloud', icon: '☁️'),
    ];

    const backupPassword = 'MySecureBackupPassword2026!';

    // Create encrypted backup
    final backupString = await backupService.createEncryptedBackup(
      items: testItems,
      folders: testFolders,
      backupPassword: backupPassword,
    );

    expect(backupString, contains('"version": 1'));
    expect(backupString, contains('"kdf": "PBKDF2-HMAC-SHA256"'));
    expect(backupString, isNot(contains('AwsPassword#9876'))); // Ciphertext check!

    // Inspect and preview with correct password
    final preview = await backupService.inspectAndDecryptBackup(
      rawBackupString: backupString,
      backupPassword: backupPassword,
    );

    expect(preview.items.length, 2);
    expect(preview.folders.length, 1);
    expect(preview.items.first.title, 'AWS Cloud');

    // Attempt inspect with wrong password
    expect(
      () async => await backupService.inspectAndDecryptBackup(
        rawBackupString: backupString,
        backupPassword: 'WrongBackupPassword!',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Memory isolation: lockMemory wipes all decrypted items and folders from memory', () async {
    final salt = kdf.generateRandomBytes(16);
    final key = await kdf.deriveKey(password: 'MasterPassword#1', salt: salt);
    await repository.loadVault(key);

    await repository.addItem(
      VaultItem(type: VaultItemType.login, title: 'Item 1', password: 'P1'),
      key,
    );
    expect(repository.activeItems.length, 1);
    expect(repository.folders.length, 3);

    // Lock memory
    repository.lockMemory();
    expect(repository.items.length, 0);
    expect(repository.activeItems.length, 0);
    expect(repository.folders.length, 0);
  });

  test('Scale search performance across 1,000 vault items executes under 50ms', () async {
    final salt = kdf.generateRandomBytes(16);
    final key = await kdf.deriveKey(password: 'MasterPassword#1', salt: salt);
    await repository.loadVault(key);

    // Generate 1,000 items
    final largeList = List.generate(
      1000,
      (i) => VaultItem(
        id: 'item_$i',
        type: VaultItemType.values[i % VaultItemType.values.length],
        title: 'Account Service #$i',
        username: 'user$i@domain.com',
        password: 'Password$i!@#',
        folder: i % 2 == 0 ? 'Work' : 'Personal',
        tags: ['tag_${i % 10}'],
      ),
    );

    await repository.replaceAll(
      newItems: largeList,
      newFolders: repository.folders,
      activeKey: key,
    );

    expect(repository.activeItems.length, 1000);

    // Measure search latency
    final stopwatch = Stopwatch()..start();
    final results = repository.search(query: 'Account Service #789');
    stopwatch.stop();

    expect(results.length, 1);
    expect(results.first.title, 'Account Service #789');
    expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Fast in-memory indexing
  });
}
