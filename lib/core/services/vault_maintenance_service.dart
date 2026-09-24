import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../services/encrypted_file_service.dart';
import '../services/storage_service.dart';
import '../../data/models/vault_item.dart';

class VaultIntegrityReport {
  final int totalItems;
  final int validItems;
  final int corruptedItems;
  final int orphanedFilesCount;
  final int orphanedBytes;
  final int missingAttachmentsCount;
  final bool isHealthy;
  final List<String> issues;

  const VaultIntegrityReport({
    required this.totalItems,
    required this.validItems,
    required this.corruptedItems,
    required this.orphanedFilesCount,
    required this.orphanedBytes,
    required this.missingAttachmentsCount,
    required this.isHealthy,
    required this.issues,
  });
}

class StorageBreakdown {
  final int databaseBytes;
  final int attachmentsBytes;
  final int backupsBytes;
  final int cacheBytes;

  int get totalBytes => databaseBytes + attachmentsBytes + backupsBytes + cacheBytes;

  const StorageBreakdown({
    required this.databaseBytes,
    required this.attachmentsBytes,
    required this.backupsBytes,
    required this.cacheBytes,
  });

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDatabase => formatBytes(databaseBytes);
  String get formattedAttachments => formatBytes(attachmentsBytes);
  String get formattedBackups => formatBytes(backupsBytes);
  String get formattedCache => formatBytes(cacheBytes);
  String get formattedTotal => formatBytes(totalBytes);
}

class VaultMaintenanceService {
  final StorageService storageService;
  final EncryptedFileService fileService;

  VaultMaintenanceService({
    required this.storageService,
    required this.fileService,
  });

  /// Audits the integrity of the active vault and its local filesystem storage
  Future<VaultIntegrityReport> runIntegrityAudit(List<VaultItem> items) async {
    final issues = <String>[];
    int validItems = 0;
    int corruptedItems = 0;
    int missingAttachments = 0;

    final referencedFileIds = <String>{};

    for (final item in items) {
      try {
        final json = item.toJson();
        final roundTrip = VaultItem.fromJson(json);
        if (roundTrip.id != item.id) {
          corruptedItems++;
          issues.add('Item ID mismatch in roundtrip serialization: ${item.title}');
        } else {
          validItems++;
        }
      } catch (e) {
        corruptedItems++;
        issues.add('Failed to serialize/deserialize item "${item.title}": $e');
      }

      for (final att in item.attachments) {
        referencedFileIds.add(att.id);
        final file = await fileService.getEncryptedFile(att.id);
        if (!await file.exists()) {
          missingAttachments++;
          issues.add('Missing encrypted attachment "${att.fileName}" for item "${item.title}"');
        }
      }
    }

    // Inspect files directory for orphaned blobs
    int orphanedCount = 0;
    int orphanedBytes = 0;
    try {
      final dir = await fileService.getEncryptedFilesDirectory();
      if (await dir.exists()) {
        final fileList = dir.listSync();
        for (final entity in fileList) {
          if (entity is File) {
            final fileName = entity.uri.pathSegments.last;
            final fileId = fileName.replaceFirst('.enc', '');
            if (!referencedFileIds.contains(fileId)) {
              orphanedCount++;
              orphanedBytes += entity.lengthSync();
            }
          }
        }
      }
    } catch (_) {}

    final isHealthy = corruptedItems == 0 && missingAttachments == 0 && orphanedCount == 0;

    return VaultIntegrityReport(
      totalItems: items.length,
      validItems: validItems,
      corruptedItems: corruptedItems,
      orphanedFilesCount: orphanedCount,
      orphanedBytes: orphanedBytes,
      missingAttachmentsCount: missingAttachments,
      isHealthy: isHealthy,
      issues: issues,
    );
  }

  /// Prunes orphaned attachment blobs and cleans up local caches
  Future<int> cleanupOrphanedFiles(List<VaultItem> items) async {
    final referencedFileIds = <String>{};
    for (final item in items) {
      for (final att in item.attachments) {
        referencedFileIds.add(att.id);
      }
    }

    int removedCount = 0;
    try {
      final dir = await fileService.getEncryptedFilesDirectory();
      if (await dir.exists()) {
        final fileList = dir.listSync();
        for (final entity in fileList) {
          if (entity is File) {
            final fileName = entity.uri.pathSegments.last;
            final fileId = fileName.replaceFirst('.enc', '');
            if (!referencedFileIds.contains(fileId)) {
              await entity.delete();
              removedCount++;
            }
          }
        }
      }
    } catch (_) {}
    return removedCount;
  }

  /// Calculates storage breakdown by category
  Future<StorageBreakdown> getStorageBreakdown(List<VaultItem> items) async {
    int dbBytes = 0;
    try {
      final data = await storageService.getEncryptedVaultData();
      if (data != null) {
        dbBytes = Uint8List.fromList(data.codeUnits).length;
      }
    } catch (_) {}

    int attachmentsBytes = 0;
    try {
      final dir = await fileService.getEncryptedFilesDirectory();
      if (await dir.exists()) {
        for (final entity in dir.listSync()) {
          if (entity is File) {
            attachmentsBytes += entity.lengthSync();
          }
        }
      }
    } catch (_) {}

    int backupsBytes = 0;
    int cacheBytes = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        for (final entity in tempDir.listSync(recursive: true)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.vault') || path.endsWith('.json')) {
              backupsBytes += entity.lengthSync();
            } else {
              cacheBytes += entity.lengthSync();
            }
          }
        }
      }
    } catch (_) {}

    return StorageBreakdown(
      databaseBytes: dbBytes,
      attachmentsBytes: attachmentsBytes,
      backupsBytes: backupsBytes,
      cacheBytes: cacheBytes,
    );
  }
}
