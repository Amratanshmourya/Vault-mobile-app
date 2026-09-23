import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../data/models/vault_backup_metadata.dart';
import '../../data/models/vault_item.dart';
import '../../data/models/folder.dart';
import '../../data/models/backup_diff_result.dart';
import '../constants/crypto_constants.dart';
import '../crypto/aes_gcm_service.dart';
import '../crypto/key_derivation_service.dart';

class DecryptedBackupPreview {
  final VaultBackupContainer metadata;
  final List<VaultItem> items;
  final List<Folder> folders;

  DecryptedBackupPreview({
    required this.metadata,
    required this.items,
    required this.folders,
  });
}

class BackupService {
  final KeyDerivationService _keyDerivation = KeyDerivationService();
  final AesGcmService _aesGcm = AesGcmService();

  /// Creates a versioned encrypted backup string for export
  Future<String> createEncryptedBackup({
    required List<VaultItem> items,
    required List<Folder> folders,
    required String backupPassword,
  }) async {
    final salt = _keyDerivation.generateRandomBytes(CryptoConstants.saltLengthBytes);
    final SecretKey key = await _keyDerivation.deriveKey(
      password: backupPassword,
      salt: salt,
      iterations: CryptoConstants.pbkdf2Iterations,
    );

    final payloadJson = jsonEncode({
      'items': items.map((e) => e.toJson()).toList(),
      'folders': folders.map((e) => e.toJson()).toList(),
    });

    final encryptedPayload = await _aesGcm.encrypt(
      plainText: payloadJson,
      secretKey: key,
    );

    final container = VaultBackupContainer(
      version: CryptoConstants.currentBackupVersion,
      createdAt: DateTime.now(),
      kdf: CryptoConstants.kdfAlgorithm,
      iterations: CryptoConstants.pbkdf2Iterations,
      saltBase64: base64Encode(salt),
      nonceBase64: encryptedPayload.nonceBase64,
      tagBase64: encryptedPayload.tagBase64,
      ciphertextBase64: encryptedPayload.ciphertextBase64,
      itemCount: items.length,
      folderCount: folders.length,
    );

    return container.serialize();
  }

  /// Decrypts and validates a backup string before applying it to the vault
  Future<DecryptedBackupPreview> inspectAndDecryptBackup({
    required String rawBackupString,
    required String backupPassword,
  }) async {
    VaultBackupContainer container;
    try {
      container = VaultBackupContainer.deserialize(rawBackupString);
    } catch (_) {
      throw Exception('Invalid or corrupted backup file format.');
    }

    if (container.version > CryptoConstants.currentBackupVersion) {
      throw Exception(
        'This backup was created by a newer version of Vault (v${container.version}). Please update the app to restore it.',
      );
    }

    final salt = base64Decode(container.saltBase64);
    final SecretKey key = await _keyDerivation.deriveKey(
      password: backupPassword,
      salt: salt,
      iterations: container.iterations,
    );

    final encryptedPayload = EncryptedPayload(
      ciphertextBase64: container.ciphertextBase64,
      nonceBase64: container.nonceBase64,
      tagBase64: container.tagBase64,
    );

    String decryptedJson;
    try {
      decryptedJson = await _aesGcm.decrypt(
        payload: encryptedPayload,
        secretKey: key,
      );
    } catch (_) {
      throw Exception('Incorrect backup password or corrupted data.');
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final itemsRaw = decoded['items'] as List<dynamic>? ?? [];
      final foldersRaw = decoded['folders'] as List<dynamic>? ?? [];

      final items = itemsRaw
          .map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final folders = foldersRaw
          .map((e) => Folder.fromJson(e as Map<String, dynamic>))
          .toList();

      return DecryptedBackupPreview(
        metadata: container,
        items: items,
        folders: folders,
      );
    } catch (_) {
      throw Exception('Failed to parse decrypted vault payload.');
    }
  }

  /// Verifies a backup's cryptographic integrity and format without applying it
  Future<bool> verifyBackup({
    required String rawBackupString,
    required String backupPassword,
  }) async {
    final preview = await inspectAndDecryptBackup(
      rawBackupString: rawBackupString,
      backupPassword: backupPassword,
    );
    // Integrity checks: counts match metadata
    if (preview.items.length != preview.metadata.itemCount ||
        preview.folders.length != preview.metadata.folderCount) {
      throw Exception('Backup metadata item counts do not match payload.');
    }
    return true;
  }

  /// Computes a diff comparison between current vault items and backup items
  BackupDiffResult computeRestoreDiff({
    required List<VaultItem> backupItems,
    required List<VaultItem> currentItems,
  }) {
    final Map<String, VaultItem> currentMap = {
      for (final item in currentItems) item.id: item,
    };
    final Map<String, VaultItem> backupMap = {
      for (final item in backupItems) item.id: item,
    };

    final List<VaultItem> addedItems = [];
    final List<VaultItem> modifiedItems = [];
    int unchangedCount = 0;

    for (final backupItem in backupItems) {
      if (!currentMap.containsKey(backupItem.id)) {
        addedItems.add(backupItem);
      } else {
        final currentItem = currentMap[backupItem.id]!;
        // Check if modified
        if (currentItem.updatedAt != backupItem.updatedAt ||
            currentItem.title != backupItem.title ||
            currentItem.username != backupItem.username ||
            currentItem.password != backupItem.password ||
            currentItem.notes != backupItem.notes) {
          modifiedItems.add(backupItem);
        } else {
          unchangedCount++;
        }
      }
    }

    final List<VaultItem> removedItems = [];
    for (final currentItem in currentItems) {
      if (!backupMap.containsKey(currentItem.id)) {
        removedItems.add(currentItem);
      }
    }

    return BackupDiffResult(
      currentCount: currentItems.length,
      backupCount: backupItems.length,
      addedItems: addedItems,
      removedItems: removedItems,
      modifiedItems: modifiedItems,
      unchangedCount: unchangedCount,
    );
  }
}
