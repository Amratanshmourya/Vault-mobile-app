import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/security_activity_service.dart';
import '../../data/models/backup_diff_result.dart';
import '../../data/models/folder.dart';
import '../../data/models/security_event.dart';
import '../../data/models/vault_item.dart';
import '../../data/repositories/vault_repository.dart';

class VaultState extends ChangeNotifier {
  final VaultRepository repository;
  VaultRepository get _repository => repository;
  final BackupService _backupService = BackupService();
  final ClipboardService clipboardService;
  late final SecurityActivityService _securityActivityService;

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  VaultItemType? _selectedCategory;
  String? _selectedFolder;
  String? _selectedTag;
  bool _filterFavoritesOnly = false;
  bool _filterHasTotpOnly = false;
  SortOption _sortOption = SortOption.nameAsc;

  // Multi-select bulk action mode
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  VaultItemType? get selectedCategory => _selectedCategory;
  String? get selectedFolder => _selectedFolder;
  String? get selectedTag => _selectedTag;
  bool get filterFavoritesOnly => _filterFavoritesOnly;
  bool get filterHasTotpOnly => _filterHasTotpOnly;
  SortOption get sortOption => _sortOption;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedItemIds => Set.unmodifiable(_selectedItemIds);
  int get selectedCount => _selectedItemIds.length;

  List<VaultItem> get allItems => repository.activeItems;
  List<VaultItem> get trashItems => repository.trashItems;
  List<Folder> get folders => repository.folders;
  List<String> get allTags => repository.allTags;

  List<VaultItem> get favoriteItems =>
      repository.activeItems.where((i) => i.isFavorite).toList();

  List<VaultItem> get recentlyUsedItems {
    final list = repository.activeItems.where((i) => i.lastUsedAt != null).toList();
    list.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return list.take(10).toList();
  }

  // Filtered items based on current search & filters
  List<VaultItem> get filteredItems {
    return repository.search(
      query: _searchQuery,
      typeFilter: _selectedCategory,
      folderFilter: _selectedFolder,
      tagFilter: _selectedTag,
      favoriteOnly: _filterFavoritesOnly ? true : null,
      hasTotpOnly: _filterHasTotpOnly ? true : null,
      sortOption: _sortOption,
    );
  }

  int get totalCount => repository.activeItems.length;

  int countForType(VaultItemType type) =>
      repository.activeItems.where((i) => i.type == type).length;

  VaultState({
    required this.repository,
    required this.clipboardService,
  }) {
    _securityActivityService = SecurityActivityService(storageService: repository.storageService);
    _initSortOption();
  }

  Future<void> _initSortOption() async {
    _sortOption = await repository.storageService.getSortOption();
    notifyListeners();
  }

  Future<void> loadVault(SecretKey activeKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.loadVault(activeKey);
    } catch (e) {
      _errorMessage = 'Failed to load vault. Please check your master password.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(VaultItemType? type) {
    _selectedCategory = type;
    notifyListeners();
  }

  void setFolderFilter(String? folder) {
    _selectedFolder = folder;
    notifyListeners();
  }

  void setTagFilter(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void toggleFavoritesFilter() {
    _filterFavoritesOnly = !_filterFavoritesOnly;
    notifyListeners();
  }

  void toggleHasTotpFilter() {
    _filterHasTotpOnly = !_filterHasTotpOnly;
    notifyListeners();
  }

  Future<void> setSortOption(SortOption option) async {
    _sortOption = option;
    await repository.storageService.saveSortOption(option);
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedFolder = null;
    _selectedTag = null;
    _filterFavoritesOnly = false;
    _filterHasTotpOnly = false;
    notifyListeners();
  }

  // Multi-Select Mode
  void toggleSelectionMode([bool? enabled]) {
    _isSelectionMode = enabled ?? !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }

  void toggleItemSelection(String itemId) {
    if (_selectedItemIds.contains(itemId)) {
      _selectedItemIds.remove(itemId);
      if (_selectedItemIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedItemIds.add(itemId);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedItemIds.addAll(filteredItems.map((e) => e.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedItemIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // Item Actions
  Future<void> addItem(VaultItem item, SecretKey activeKey) async {
    await _repository.addItem(item, activeKey);
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemCreated,
      description: 'Created "${item.title}" (${item.type.name})',
    );
    notifyListeners();
  }

  Future<void> updateItem(VaultItem item, SecretKey activeKey) async {
    await _repository.updateItem(item, activeKey);
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemUpdated,
      description: 'Updated "${item.title}"',
    );
    notifyListeners();
  }

  Future<void> toggleFavorite(String itemId, SecretKey activeKey) async {
    await _repository.toggleFavorite(itemId, activeKey);
    notifyListeners();
  }

  Future<void> recordUsage(String itemId, SecretKey activeKey) async {
    await _repository.recordItemUsage(itemId, activeKey);
    notifyListeners();
  }

  Future<void> moveToTrash(String itemId, SecretKey activeKey) async {
    final item = repository.activeItems.firstWhere((i) => i.id == itemId, orElse: () => repository.trashItems.firstWhere((i) => i.id == itemId));
    await _repository.moveToTrash(itemId, activeKey);
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemDeleted,
      description: 'Moved "${item.title}" to trash',
    );
    notifyListeners();
  }

  Future<void> restoreFromTrash(String itemId, SecretKey activeKey) async {
    final item = repository.trashItems.firstWhere((i) => i.id == itemId);
    await _repository.restoreFromTrash(itemId, activeKey);
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemRestored,
      description: 'Restored "${item.title}" from trash',
    );
    notifyListeners();
  }

  Future<void> permanentlyDelete(String itemId, SecretKey activeKey) async {
    await _repository.permanentlyDeleteItem(itemId, activeKey);
    notifyListeners();
  }

  Future<void> emptyTrash(SecretKey activeKey) async {
    await _repository.emptyTrash(activeKey);
    notifyListeners();
  }

  Future<void> clearRecentHistory(SecretKey activeKey) async {
    await _repository.clearRecentHistory(activeKey);
    notifyListeners();
  }

  // Bulk Operations
  Future<void> bulkMoveToFolder(String? folderId, SecretKey activeKey) async {
    final count = _selectedItemIds.length;
    await _repository.bulkMoveToFolder(_selectedItemIds.toList(), folderId, activeKey);
    clearSelection();
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemUpdated,
      description: 'Moved $count items to ${folderId ?? "None"}',
    );
    notifyListeners();
  }

  Future<void> bulkAddTag(String tag, SecretKey activeKey) async {
    final count = _selectedItemIds.length;
    await _repository.bulkAddTag(_selectedItemIds.toList(), tag, activeKey);
    clearSelection();
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemUpdated,
      description: 'Added tag #$tag to $count items',
    );
    notifyListeners();
  }

  Future<void> bulkRemoveTag(String tag, SecretKey activeKey) async {
    final count = _selectedItemIds.length;
    await _repository.bulkRemoveTag(_selectedItemIds.toList(), tag, activeKey);
    clearSelection();
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemUpdated,
      description: 'Removed tag #$tag from $count items',
    );
    notifyListeners();
  }

  Future<void> bulkSetFavorite(bool isFavorite, SecretKey activeKey) async {
    await _repository.bulkSetFavorite(_selectedItemIds.toList(), isFavorite, activeKey);
    clearSelection();
    notifyListeners();
  }

  Future<void> bulkMoveToTrash(SecretKey activeKey) async {
    final count = _selectedItemIds.length;
    await _repository.bulkMoveToTrash(_selectedItemIds.toList(), activeKey);
    clearSelection();
    await _securityActivityService.recordEvent(
      type: SecurityEventType.itemDeleted,
      description: 'Moved $count items to trash in bulk',
    );
    notifyListeners();
  }

  Future<void> bulkPermanentDelete(SecretKey activeKey) async {
    await _repository.bulkPermanentDelete(_selectedItemIds.toList(), activeKey);
    clearSelection();
    notifyListeners();
  }

  // Tag Management
  Future<void> renameTag(String oldTag, String newTag, SecretKey activeKey) async {
    await _repository.renameTag(oldTag, newTag, activeKey);
    if (_selectedTag == oldTag) {
      _selectedTag = newTag;
    }
    notifyListeners();
  }

  Future<void> deleteTag(String tag, SecretKey activeKey) async {
    await _repository.deleteTag(tag, activeKey);
    if (_selectedTag == tag) {
      _selectedTag = null;
    }
    notifyListeners();
  }

  // Backup & Restore
  Future<String> exportBackup(String backupPassword) async {
    final backup = await _backupService.createEncryptedBackup(
      items: _repository.items,
      folders: _repository.folders,
      backupPassword: backupPassword,
    );
    await _securityActivityService.recordEvent(
      type: SecurityEventType.backupCreated,
      description: 'Created encrypted backup (${_repository.items.length} items)',
    );
    return backup;
  }

  Future<bool> verifyBackup({
    required String rawBackupString,
    required String backupPassword,
  }) async {
    return await _backupService.verifyBackup(
      rawBackupString: rawBackupString,
      backupPassword: backupPassword,
    );
  }

  Future<DecryptedBackupPreview> inspectBackup({
    required String rawBackupString,
    required String backupPassword,
  }) async {
    return await _backupService.inspectAndDecryptBackup(
      rawBackupString: rawBackupString,
      backupPassword: backupPassword,
    );
  }

  BackupDiffResult computeRestoreDiff(DecryptedBackupPreview preview) {
    return _backupService.computeRestoreDiff(
      backupItems: preview.items,
      currentItems: _repository.activeItems,
    );
  }

  Future<void> restoreBackup({
    required DecryptedBackupPreview preview,
    required SecretKey activeKey,
  }) async {
    await _repository.replaceAll(
      newItems: preview.items,
      newFolders: preview.folders,
      activeKey: activeKey,
    );
    await _securityActivityService.recordEvent(
      type: SecurityEventType.backupRestored,
      description: 'Restored backup (${preview.items.length} items)',
    );
    notifyListeners();
  }

  void lockMemory() {
    _repository.lockMemory();
    _searchQuery = '';
    _selectedCategory = null;
    _selectedFolder = null;
    _selectedTag = null;
    _filterFavoritesOnly = false;
    _filterHasTotpOnly = false;
    _isSelectionMode = false;
    _selectedItemIds.clear();
    notifyListeners();
  }
}
