import 'vault_item.dart';

class BackupDiffResult {
  final int currentCount;
  final int backupCount;
  final List<VaultItem> addedItems;
  final List<VaultItem> removedItems;
  final List<VaultItem> modifiedItems;
  final int unchangedCount;

  const BackupDiffResult({
    required this.currentCount,
    required this.backupCount,
    required this.addedItems,
    required this.removedItems,
    required this.modifiedItems,
    required this.unchangedCount,
  });

  int get addedCount => addedItems.length;
  int get removedCount => removedItems.length;
  int get modifiedCount => modifiedItems.length;

  bool get hasChanges => addedCount > 0 || removedCount > 0 || modifiedCount > 0;
}
