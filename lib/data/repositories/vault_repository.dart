import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/crypto/aes_gcm_service.dart';
import '../../core/services/storage_service.dart';
import '../models/folder.dart';
import '../models/vault_item.dart';

class VaultRepository {
  final StorageService storageService;
  StorageService get _storageService => storageService;
  final AesGcmService _aesGcm = AesGcmService();

  List<VaultItem> _items = [];
  List<Folder> _folders = [];

  List<VaultItem> get items => List.unmodifiable(_items);
  List<VaultItem> get activeItems => List.unmodifiable(_items.where((i) => !i.isDeleted));
  List<VaultItem> get trashItems => List.unmodifiable(_items.where((i) => i.isDeleted));
  List<Folder> get folders => List.unmodifiable(_folders);

  /// All unique tags currently in active items (sorted alphabetically)
  List<String> get allTags {
    final Set<String> tagSet = {};
    for (final item in activeItems) {
      tagSet.addAll(item.tags);
    }
    final sorted = tagSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List.unmodifiable(sorted);
  }

  VaultRepository({required this.storageService});

  /// Loads and decrypts vault data using the active vault secret key
  Future<void> loadVault(SecretKey activeKey) async {
    final encryptedData = await storageService.getEncryptedVaultData();
    if (encryptedData == null || encryptedData.isEmpty) {
      _items = [];
      _folders = [
        const Folder(id: 'f_personal', name: 'Personal', icon: '👤'),
        const Folder(id: 'f_work', name: 'Work', icon: '💼'),
        const Folder(id: 'f_finance', name: 'Finance', icon: '💰'),
      ];
      await saveVault(activeKey);
      return;
    }

    try {
      final payload = EncryptedPayload.deserialize(encryptedData);
      final decryptedJson = await _aesGcm.decrypt(
        payload: payload,
        secretKey: activeKey,
      );

      final Map<String, dynamic> decoded = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final rawItems = decoded['items'] as List<dynamic>? ?? [];
      final rawFolders = decoded['folders'] as List<dynamic>? ?? [];

      _items = rawItems.map((e) => VaultItem.fromJson(e as Map<String, dynamic>)).toList();
      _folders = rawFolders.map((e) => Folder.fromJson(e as Map<String, dynamic>)).toList();

      // Clean up expired trash items automatically
      await cleanupExpiredTrash(activeKey);
    } catch (e) {
      throw Exception('Failed to unlock and decrypt vault: $e');
    }
  }

  /// Encrypts and persists vault data using the active vault secret key
  Future<void> saveVault(SecretKey activeKey) async {
    final payloadJson = jsonEncode({
      'items': _items.map((e) => e.toJson()).toList(),
      'folders': _folders.map((e) => e.toJson()).toList(),
    });

    final encryptedPayload = await _aesGcm.encrypt(
      plainText: payloadJson,
      secretKey: activeKey,
    );

    await _storageService.saveEncryptedVaultData(encryptedPayload.serialize());
  }

  // CRUD Operations
  Future<void> addItem(VaultItem item, SecretKey activeKey) async {
    _items.add(item);
    await saveVault(activeKey);
  }

  Future<void> updateItem(VaultItem item, SecretKey activeKey) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item.copyWith(updatedAt: DateTime.now());
      await saveVault(activeKey);
    }
  }

  Future<void> recordItemUsage(String itemId, SecretKey activeKey) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(lastUsedAt: DateTime.now());
      await saveVault(activeKey);
    }
  }

  Future<void> toggleFavorite(String itemId, SecretKey activeKey) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final current = _items[index];
      _items[index] = current.copyWith(isFavorite: !current.isFavorite);
      await saveVault(activeKey);
    }
  }

  Future<void> moveToTrash(String itemId, SecretKey activeKey) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      await saveVault(activeKey);
    }
  }

  Future<void> restoreFromTrash(String itemId, SecretKey activeKey) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isDeleted: false,
        deletedAt: null,
      );
      await saveVault(activeKey);
    }
  }

  Future<void> permanentlyDeleteItem(String itemId, SecretKey activeKey) async {
    _items.removeWhere((i) => i.id == itemId);
    await saveVault(activeKey);
  }

  Future<void> emptyTrash(SecretKey activeKey) async {
    _items.removeWhere((i) => i.isDeleted);
    await saveVault(activeKey);
  }

  Future<void> clearRecentHistory(SecretKey activeKey) async {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].lastUsedAt != null) {
        _items[i] = _items[i].copyWith(lastUsedAt: null);
      }
    }
    await saveVault(activeKey);
  }

  Future<void> cleanupExpiredTrash(SecretKey activeKey) async {
    final retentionDays = await _storageService.getTrashRetentionDays();
    if (retentionDays <= 0) return; // 0 = never

    final now = DateTime.now();
    final initialCount = _items.length;
    _items.removeWhere((item) {
      if (!item.isDeleted || item.deletedAt == null) return false;
      final age = now.difference(item.deletedAt!).inDays;
      return age >= retentionDays;
    });

    if (_items.length != initialCount) {
      await saveVault(activeKey);
    }
  }

  // Bulk Operations
  Future<void> bulkMoveToFolder(List<String> itemIds, String? folderId, SecretKey activeKey) async {
    final set = itemIds.toSet();
    for (int i = 0; i < _items.length; i++) {
      if (set.contains(_items[i].id)) {
        _items[i] = _items[i].copyWith(folder: folderId);
      }
    }
    await saveVault(activeKey);
  }

  Future<void> bulkAddTag(List<String> itemIds, String tag, SecretKey activeKey) async {
    final cleanTag = tag.trim().replaceFirst(RegExp(r'^#'), '');
    if (cleanTag.isEmpty) return;
    final set = itemIds.toSet();
    for (int i = 0; i < _items.length; i++) {
      if (set.contains(_items[i].id)) {
        if (!_items[i].tags.contains(cleanTag)) {
          final updatedTags = List<String>.from(_items[i].tags)..add(cleanTag);
          _items[i] = _items[i].copyWith(tags: updatedTags);
        }
      }
    }
    await saveVault(activeKey);
  }

  Future<void> bulkRemoveTag(List<String> itemIds, String tag, SecretKey activeKey) async {
    final cleanTag = tag.trim().replaceFirst(RegExp(r'^#'), '');
    final set = itemIds.toSet();
    for (int i = 0; i < _items.length; i++) {
      if (set.contains(_items[i].id)) {
        final updatedTags = List<String>.from(_items[i].tags)..remove(cleanTag);
        _items[i] = _items[i].copyWith(tags: updatedTags);
      }
    }
    await saveVault(activeKey);
  }

  Future<void> bulkSetFavorite(List<String> itemIds, bool isFavorite, SecretKey activeKey) async {
    final set = itemIds.toSet();
    for (int i = 0; i < _items.length; i++) {
      if (set.contains(_items[i].id)) {
        _items[i] = _items[i].copyWith(isFavorite: isFavorite);
      }
    }
    await saveVault(activeKey);
  }

  Future<void> bulkMoveToTrash(List<String> itemIds, SecretKey activeKey) async {
    final set = itemIds.toSet();
    final now = DateTime.now();
    for (int i = 0; i < _items.length; i++) {
      if (set.contains(_items[i].id)) {
        _items[i] = _items[i].copyWith(isDeleted: true, deletedAt: now);
      }
    }
    await saveVault(activeKey);
  }

  Future<void> bulkPermanentDelete(List<String> itemIds, SecretKey activeKey) async {
    final set = itemIds.toSet();
    _items.removeWhere((i) => set.contains(i.id));
    await saveVault(activeKey);
  }

  // Tag Management
  Future<void> renameTag(String oldTag, String newTag, SecretKey activeKey) async {
    final cleanOld = oldTag.trim().replaceFirst(RegExp(r'^#'), '');
    final cleanNew = newTag.trim().replaceFirst(RegExp(r'^#'), '');
    if (cleanNew.isEmpty) return;

    for (int i = 0; i < _items.length; i++) {
      if (_items[i].tags.contains(cleanOld)) {
        final updated = List<String>.from(_items[i].tags)
          ..remove(cleanOld)
          ..add(cleanNew);
        _items[i] = _items[i].copyWith(tags: updated.toSet().toList());
      }
    }
    await saveVault(activeKey);
  }

  Future<void> deleteTag(String tag, SecretKey activeKey) async {
    final cleanTag = tag.trim().replaceFirst(RegExp(r'^#'), '');
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].tags.contains(cleanTag)) {
        final updated = List<String>.from(_items[i].tags)..remove(cleanTag);
        _items[i] = _items[i].copyWith(tags: updated);
      }
    }
    await saveVault(activeKey);
  }

  // Replace Entire Vault (e.g. from restored backup) - Atomic non-destructive replace
  Future<void> replaceAll({
    required List<VaultItem> newItems,
    required List<Folder> newFolders,
    required SecretKey activeKey,
  }) async {
    final payloadJson = jsonEncode({
      'items': newItems.map((e) => e.toJson()).toList(),
      'folders': newFolders.map((e) => e.toJson()).toList(),
    });

    final encryptedPayload = await _aesGcm.encrypt(
      plainText: payloadJson,
      secretKey: activeKey,
    );

    await _storageService.saveEncryptedVaultData(encryptedPayload.serialize());
    _items = List.from(newItems);
    _folders = List.from(newFolders);
  }

  // Folders
  Future<void> addFolder(Folder folder, SecretKey activeKey) async {
    _folders.add(folder);
    await saveVault(activeKey);
  }

  Future<void> deleteFolder(String folderId, SecretKey activeKey) async {
    _folders.removeWhere((f) => f.id == folderId);
    await saveVault(activeKey);
  }

  // In-Memory Search & Sorting
  List<VaultItem> search({
    required String query,
    VaultItemType? typeFilter,
    String? folderFilter,
    String? tagFilter,
    bool? favoriteOnly,
    bool? hasTotpOnly,
    SortOption sortOption = SortOption.nameAsc,
  }) {
    final q = query.trim().toLowerCase();
    final results = activeItems.where((item) {
      if (typeFilter != null && item.type != typeFilter) return false;
      if (folderFilter != null && item.folder != folderFilter) return false;
      if (tagFilter != null && tagFilter.isNotEmpty && !item.tags.contains(tagFilter)) return false;
      if (favoriteOnly == true && !item.isFavorite) return false;
      if (hasTotpOnly == true && (item.totpSecret == null || item.totpSecret!.trim().isEmpty)) return false;

      if (q.isEmpty) return true;

      final titleMatch = item.title.toLowerCase().contains(q);
      final userMatch = item.username?.toLowerCase().contains(q) ?? false;
      final websiteMatch = item.website?.toLowerCase().contains(q) ?? false;
      final folderMatch = item.folder?.toLowerCase().contains(q) ?? false;
      final notesMatch = item.notes?.toLowerCase().contains(q) ?? false;
      final tagsMatch = item.tags.any((t) => t.toLowerCase().contains(q));
      final customMatch = item.customFields.any(
        (cf) => cf.label.toLowerCase().contains(q) || (!cf.isConcealed && cf.value.toLowerCase().contains(q)),
      );

      return titleMatch || userMatch || websiteMatch || folderMatch || notesMatch || tagsMatch || customMatch;
    }).toList();

    // Apply sorting
    switch (sortOption) {
      case SortOption.nameAsc:
        results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.nameDesc:
        results.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.updatedDesc:
        results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortOption.createdDesc:
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.mostUsedDesc:
        results.sort((a, b) {
          if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
          if (a.lastUsedAt == null) return 1;
          if (b.lastUsedAt == null) return -1;
          return b.lastUsedAt!.compareTo(a.lastUsedAt!);
        });
        break;
      case SortOption.strengthAsc:
        results.sort((a, b) => a.passwordStrength.score.compareTo(b.passwordStrength.score));
        break;
    }

    return results;
  }

  /// Locks and clears decrypted state from memory
  void lockMemory() {
    _items = [];
    _folders = [];
  }
}
