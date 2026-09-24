import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/crypto/key_derivation_service.dart';
import 'package:vault/core/services/storage_service.dart';
import 'package:vault/data/models/vault_item.dart';
import 'package:vault/data/repositories/vault_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late VaultRepository repository;
  late SecretKey activeKey;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();

    final kdf = KeyDerivationService();
    final salt = kdf.generateRandomBytes();
    activeKey = await kdf.deriveKey(
      password: 'MasterPassword123!',
      salt: salt,
    );

    repository = VaultRepository(storageService: storageService);
    await repository.loadVault(activeKey);
  });

  group('V3 Multiple Independent Vaults Tests', () {
    test('Initializes with default primary vault', () {
      expect(repository.vaults.length, 1);
      expect(repository.activeVault.id, 'default_vault');
      expect(repository.activeVault.isDefault, true);
    });

    test('Creates new independent vault and switches active context', () async {
      await repository.addItem(
        VaultItem(type: VaultItemType.login, title: 'Personal Email'),
        activeKey,
      );
      expect(repository.activeItems.length, 1);

      // Create "Work" vault
      final workVault = await repository.createVault(
        name: 'Work',
        icon: '💼',
        activeKey: activeKey,
      );

      expect(repository.vaults.length, 2);

      // Switch to Work vault
      await repository.switchVault(workVault.id, activeKey);
      expect(repository.activeVault.id, workVault.id);
      expect(repository.activeItems.length, 0); // Isolated storage

      // Add item to Work vault
      await repository.addItem(
        VaultItem(type: VaultItemType.login, title: 'Work Slack'),
        activeKey,
      );
      expect(repository.activeItems.length, 1);

      // Switch back to Primary Vault
      await repository.switchVault('default_vault', activeKey);
      expect(repository.activeItems.length, 1);
      expect(repository.activeItems.first.title, 'Personal Email');
    });

    test('Protects default vault from deletion', () async {
      expect(
        () async => await repository.deleteVault('default_vault', activeKey),
        throwsException,
      );
    });
  });
}
