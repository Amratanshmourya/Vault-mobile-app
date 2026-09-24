import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';
import '../../../data/models/smart_collection.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/vault_card.dart';
import '../../widgets/common/vault_item_tile.dart';
import '../../widgets/dialogs/smart_filters_bottom_sheet.dart';
import '../item_detail/item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final VaultItemType? initialCategory;

  const SearchScreen({super.key, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null) {
        context.read<VaultState>().setCategoryFilter(widget.initialCategory);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openItem(BuildContext context, VaultItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(itemId: item.id),
      ),
    );
  }

  void _quickCopy(BuildContext context, VaultItem item) async {
    final pwd = item.password;
    if (pwd != null && pwd.isNotEmpty) {
      final vaultState = context.read<VaultState>();
      final authState = context.read<AuthState>();
      if (authState.activeKey != null) {
        await vaultState.recordUsage(item.id, authState.activeKey!);
      }
      final msg = await vaultState.clipboardService.copyWithAutoClear(
        text: pwd,
        itemLabel: 'Password',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showBulkMoveFolderDialog(BuildContext context) async {
    final vaultState = context.read<VaultState>();
    final authState = context.read<AuthState>();
    if (authState.activeKey == null) return;

    final folder = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to Folder'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('__none__'),
            child: const Text('No Folder'),
          ),
          ...vaultState.folders.map(
            (f) => SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(f.name),
              child: Text('${f.icon} ${f.name}'),
            ),
          ),
        ],
      ),
    );

    if (folder != null) {
      await vaultState.bulkMoveToFolder(
        folder == '__none__' ? null : folder,
        authState.activeKey!,
      );
    }
  }

  void _showBulkAddTagDialog(BuildContext context) async {
    final vaultState = context.read<VaultState>();
    final authState = context.read<AuthState>();
    if (authState.activeKey == null) return;

    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag to Selected'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Work, Banking, Social',
            prefixText: '#',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add Tag'),
          ),
        ],
      ),
    );

    if (tag != null && tag.isNotEmpty) {
      await vaultState.bulkAddTag(tag, authState.activeKey!);
    }
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withAlpha(30),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withAlpha(200),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : theme.colorScheme.outline.withAlpha(100),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = context.watch<VaultState>();
    final authState = context.watch<AuthState>();

    final results = vaultState.filteredItems;
    final isSelecting = vaultState.isSelectionMode;
    final selectedCount = vaultState.selectedCount;

    return Scaffold(
      appBar: isSelecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => vaultState.clearSelection(),
              ),
              title: Text('$selectedCount selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all_rounded),
                  tooltip: 'Select All',
                  onPressed: () => vaultState.selectAll(),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open_rounded),
                  tooltip: 'Move to Folder',
                  onPressed: selectedCount > 0 ? () => _showBulkMoveFolderDialog(context) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.tag_rounded),
                  tooltip: 'Add Tag',
                  onPressed: selectedCount > 0 ? () => _showBulkAddTagDialog(context) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.star_outline_rounded),
                  tooltip: 'Favorite Selected',
                  onPressed: selectedCount > 0 && authState.activeKey != null
                      ? () => vaultState.bulkSetFavorite(true, authState.activeKey!)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  tooltip: 'Trash Selected',
                  onPressed: selectedCount > 0 && authState.activeKey != null
                      ? () => vaultState.bulkMoveToTrash(authState.activeKey!)
                      : null,
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => vaultState.setSearchQuery(val),
                      style: AppTypography.bodyLarge.copyWith(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search items, tags, usernames, notes...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  vaultState.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Smart Filters & Sorting',
                    onPressed: () => SmartFiltersBottomSheet.show(context),
                  ),
                ],
              ),
            ),

            // Horizontal Filter Chips & Tag Carousel
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    context,
                    label: 'All',
                    isSelected: vaultState.selectedCategory == null &&
                        vaultState.selectedSmartCollection == null &&
                        !vaultState.filterFavoritesOnly &&
                        !vaultState.filterHasTotpOnly &&
                        vaultState.selectedTag == null,
                    onTap: () => vaultState.clearFilters(),
                  ),
                  _buildFilterChip(
                    context,
                    label: '🛡️ Passkeys (${vaultState.passkeysCount})',
                    isSelected: vaultState.selectedSmartCollection == SmartCollectionType.passkeys ||
                        vaultState.selectedCategory == VaultItemType.passkey,
                    onTap: () => vaultState.setSmartCollection(
                      vaultState.selectedSmartCollection == SmartCollectionType.passkeys
                          ? null
                          : SmartCollectionType.passkeys,
                    ),
                  ),
                  _buildFilterChip(
                    context,
                    label: '⭐ Favorites',
                    isSelected: vaultState.filterFavoritesOnly ||
                        vaultState.selectedSmartCollection == SmartCollectionType.favorites,
                    onTap: () => vaultState.toggleFavoritesFilter(),
                  ),
                  _buildFilterChip(
                    context,
                    label: '⏱ 2FA TOTP',
                    isSelected: vaultState.filterHasTotpOnly,
                    onTap: () => vaultState.toggleHasTotpFilter(),
                  ),
                  ...VaultItemType.values.map(
                    (type) => _buildFilterChip(
                      context,
                      label: '${type.icon} ${type.label}',
                      isSelected: vaultState.selectedCategory == type,
                      onTap: () => vaultState.setCategoryFilter(
                        vaultState.selectedCategory == type ? null : type,
                      ),
                    ),
                  ),
                  ...vaultState.allTags.map(
                    (tag) => _buildFilterChip(
                      context,
                      label: '#$tag',
                      isSelected: vaultState.selectedTag == tag,
                      onTap: () => vaultState.setTagFilter(
                        vaultState.selectedTag == tag ? null : tag,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search Results List
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      icon: '🔍',
                      title: 'No Matching Items',
                      description: 'Try changing keywords, tags, or clearing active filters.',
                      actionLabel: 'Clear All Filters',
                      onAction: () {
                        _searchController.clear();
                        vaultState.clearFilters();
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final isSelected = vaultState.selectedItemIds.contains(item.id);

                        if (isSelecting) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: VaultCard(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              onTap: () => vaultState.toggleItemSelection(item.id),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => vaultState.toggleItemSelection(item.id),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: AppTypography.titleMedium.copyWith(fontSize: 15),
                                        ),
                                        if (item.username != null && item.username!.isNotEmpty)
                                          Text(
                                            item.username!,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: theme.colorScheme.onSurface.withAlpha(140),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(item.type.icon, style: const TextStyle(fontSize: 20)),
                                ],
                              ),
                            ),
                          );
                        }

                        return GestureDetector(
                          onLongPress: () {
                            vaultState.toggleSelectionMode(true);
                            vaultState.toggleItemSelection(item.id);
                          },
                          child: VaultItemTile(
                            item: item,
                            onTap: () => _openItem(context, item),
                            onFavoriteToggle: () {
                              if (authState.activeKey != null) {
                                vaultState.toggleFavorite(item.id, authState.activeKey!);
                              }
                            },
                            onQuickCopy: item.password != null ? () => _quickCopy(context, item) : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
