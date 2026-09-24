import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/services/emergency_kit_service.dart';
import 'package:vault/core/services/encrypted_file_service.dart';
import 'package:vault/core/services/storage_service.dart';
import 'package:vault/core/services/vault_maintenance_service.dart';
import 'package:vault/data/models/folder.dart';
import 'package:vault/data/models/vault_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late EncryptedFileService fileService;
  late VaultMaintenanceService maintenanceService;
  late EmergencyKitService emergencyKitService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    fileService = EncryptedFileService();
    maintenanceService = VaultMaintenanceService(
      storageService: storageService,
      fileService: fileService,
    );
    emergencyKitService = EmergencyKitService(storageService: storageService);
  });

  group('V3 Maintenance & Emergency Kit Tests', () {
    test('Calculates storage breakdown accurately', () async {
      final items = [
        VaultItem(type: VaultItemType.login, title: 'Personal'),
      ];

      final breakdown = await maintenanceService.getStorageBreakdown(items);
      expect(breakdown.formattedDatabase, isNotEmpty);
      expect(breakdown.formattedTotal, isNotEmpty);
    });

    test('Generates Emergency Recovery Kit markdown document with salt fingerprint', () async {
      final items = [
        VaultItem(type: VaultItemType.login, title: 'GitHub', username: 'alice'),
      ];
      final folders = [
        const Folder(id: '1', name: 'Personal', icon: '👤'),
      ];

      final doc = await emergencyKitService.generateEmergencyKitContent(
        vaultName: 'Primary Vault',
        items: items,
        folders: folders,
        masterPasswordHint: 'My childhood pet and year',
      );

      expect(doc, contains('VAULT EMERGENCY RECOVERY KIT'));
      expect(doc, contains('Primary Vault'));
      expect(doc, contains('My childhood pet and year'));
      expect(doc, contains('AES-256-GCM'));
    });
  });
}
