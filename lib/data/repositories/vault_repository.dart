import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/crypto/aes_gcm_service.dart';
import '../../core/services/storage_service.dart';
import '../models/folder.dart';
import '../models/vault_item.dart';
import '../models/vault_descriptor.dart';
import '../models/smart_collection.dart';
import '../models/security_audit_result.dart';

class VaultRepository {
  final StorageService storageService;
  StorageService get _storageService => storageService;
  final AesGcmService _aesGcm = AesGcmService();

  List<VaultItem> _items = [];
  List<Folder> _folders = [];
  List<VaultDescriptor> _vaults = [];
  String _activeVaultId = 'default_vault';

  List<VaultItem> get items => List.unmodifiable(_items);
  List<VaultItem> get activeItems => List.unmodifiable(_items.where((i) => !i.isDeleted));
  List<VaultItem> get trashItems => List.unmodifiable(_items.where((i) => i.isDeleted));
  List<Folder> get folders => List.unmodifiable(_folders);
  List<VaultDescriptor> get vaults => List.unmodifiable(_vaults);
  
  VaultDescriptor get activeVault {
    return _vaults.firstWhere(
      (v) => v.id == _activeVaultId,
      orElse: () => _vaults.isNotEmpty ? _vaults.first : VaultDescriptor.createDefault(),
    );
  }

  String get activeVaultId => _activeVaultId;

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

  /// Initializes the multi-vault registry from storage or creates default
  Future<void> _ensureVaultRegistry() async {
    final rawRegistry = await _storageService.getVaultDescriptorsJson();
    if (rawRegistry != null && rawRegistry.isNotEmpty) {
      try {
        final list = (jsonDecode(rawRegistry) as List<dynamic>)
            .map((e) => VaultDescriptor.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _vaults = list;
          _activeVaultId = await _storageService.getActiveVaultId();
          return;
        }
      } catch (_) {}
    }

    // Default first-time vault setup
    final defaultVault = VaultDescriptor.createDefault();
    _vaults = [defaultVault];
    _activeVaultId = defaultVault.id;
    await _saveVaultRegistry();
    await _storageService.setActiveVaultId(_activeVaultId);
  }

  Future<void> _saveVaultRegistry() async {
    final jsonStr = jsonEncode(_vaults.map((e) => e.toJson()).toList());
    await _storageService.saveVaultDescriptorsJson(jsonStr);
  }

  /// Loads and decrypts vault data using the active vault secret key
  Future<void> loadVault(SecretKey activeKey) async {
    await _ensureVaultRegistry();

    final encryptedData = await storageService.getEncryptedVaultData(_activeVaultId);
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
      _updateActiveVaultItemCount();
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

    await _storageService.saveEncryptedVaultData(encryptedPayload.serialize(), _activeVaultId);
    _updateActiveVaultItemCount();
    await _saveVaultRegistry();
  }

  void _updateActiveVaultItemCount() {
    final index = _vaults.indexWhere((v) => v.id == _activeVaultId);
    if (index != -1) {
      _vaults[index] = _vaults[index].copyWith(
        itemCount: activeItems.length,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Multi-Vault Management
  Future<VaultDescriptor> createVault({
    required String name,
    String icon = '🛡️',
    String colorHex = '#1A80E5',
    String? description,
    required SecretKey activeKey,
  }) async {
    final newVault = VaultDescriptor.create(
      name: name,
      icon: icon,
      colorHex: colorHex,
      description: description,
    );
    _vaults.add(newVault);
    await _saveVaultRegistry();
    return newVault;
  }

  Future<void> switchVault(String vaultId, SecretKey activeKey) async {
    if (_activeVaultId == vaultId) return;
    final exists = _vaults.any((v) => v.id == vaultId);
    if (!exists) throw Exception('Vault not found: $vaultId');

    _activeVaultId = vaultId;
    await _storageService.setActiveVaultId(vaultId);
    await loadVault(activeKey);
  }

  Future<void> updateVaultDescriptor(VaultDescriptor descriptor) async {
    final index = _vaults.indexWhere((v) => v.id == descriptor.id);
    if (index != -1) {
      _vaults[index] = descriptor.copyWith(updatedAt: DateTime.now());
      await _saveVaultRegistry();
    }
  }

  Future<void> deleteVault(String vaultId, SecretKey activeKey) async {
    if (vaultId == 'default_vault') {
      throw Exception('Cannot delete the primary default vault.');
    }
    _vaults.removeWhere((v) => v.id == vaultId);
    await _storageService.deleteVaultData(vaultId);

    if (_activeVaultId == vaultId) {
      _activeVaultId = 'default_vault';
      await _storageService.setActiveVaultId(_activeVaultId);
      await loadVault(activeKey);
    } else {
      await _saveVaultRegistry();
    }
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

  // Replace Entire Vault (e.g. from restored backup)
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

    await _storageService.saveEncryptedVaultData(encryptedPayload.serialize(), _activeVaultId);
    _items = List.from(newItems);
    _folders = List.from(newFolders);
    _updateActiveVaultItemCount();
    await _saveVaultRegistry();
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

  // Smart Collections
  List<VaultItem> getSmartCollection(SmartCollectionType type) {
    switch (type) {
      case SmartCollectionType.all:
        return activeItems;
      case SmartCollectionType.passkeys:
        return activeItems.where((i) => i.hasPasskey).toList();
      case SmartCollectionType.favorites:
        return activeItems.where((i) => i.isFavorite).toList();
      case SmartCollectionType.weak:
        return activeItems.where((i) => i.password != null && i.password!.isNotEmpty && i.passwordStrength.score < 60).toList();
      case SmartCollectionType.reused:
        final audit = SecurityAuditResult.analyze(activeItems);
        final reusedIds = audit.reusedGroups.expand((g) => g.items.map((i) => i.id)).toSet();
        return activeItems.where((i) => reusedIds.contains(i.id)).toList();
      case SmartCollectionType.old:
        final now = DateTime.now();
        return activeItems.where((i) {
          final dt = i.passwordUpdatedAt ?? i.updatedAt;
          return i.password != null && i.password!.isNotEmpty && now.difference(dt).inDays > 180;
        }).toList();
      case SmartCollectionType.missing2FA:
        return activeItems.where((i) => i.type == VaultItemType.login && (i.totpSecret == null || i.totpSecret!.trim().isEmpty)).toList();
      case SmartCollectionType.files:
        return activeItems.where((i) => i.attachments.isNotEmpty || i.type == VaultItemType.file).toList();
      case SmartCollectionType.trash:
        return trashItems;
    }
  }

  // In-Memory Search & Sorting
  List<VaultItem> search({
    required String query,
    VaultItemType? typeFilter,
    String? folderFilter,
    String? tagFilter,
    SmartCollectionType? smartCollection,
    bool? favoriteOnly,
    bool? hasTotpOnly,
    SortOption sortOption = SortOption.nameAsc,
  }) {
    final q = query.trim().toLowerCase();
    Iterable<VaultItem> sourceList = activeItems;

    if (smartCollection != null) {
      sourceList = getSmartCollection(smartCollection);
    }

    final results = sourceList.where((item) {
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
      final passkeyMatch = item.passkey?.rpName.toLowerCase().contains(q) == true ||
          item.passkey?.rpId.toLowerCase().contains(q) == true ||
          item.passkey?.userName.toLowerCase().contains(q) == true;
      final customMatch = item.customFields.any(
        (cf) => cf.label.toLowerCase().contains(q) || (!cf.isConcealed && cf.value.toLowerCase().contains(q)),
      );

      return titleMatch || userMatch || websiteMatch || folderMatch || notesMatch || tagsMatch || passkeyMatch || customMatch;
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
