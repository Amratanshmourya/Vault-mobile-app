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
import '../../widgets/dialogs/quick_add_bottom_sheet.dart';
import '../../widgets/dialogs/vault_switcher_bottom_sheet.dart';
import '../item_detail/item_detail_screen.dart';
import '../item_editor/item_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex) onNavigateTab;
  final void Function(VaultItemType category) onSelectCategory;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    required this.onSelectCategory,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openItem(BuildContext context, VaultItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(itemId: item.id),
      ),
    );
  }

  void _createNewItem(BuildContext context) async {
    final type = await QuickAddBottomSheet.show(context);
    if (type != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItemEditorScreen(initialType: type),
        ),
      );
    }
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

  Widget _buildCategoryRow(
    BuildContext context, {
    required VaultItemType type,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: VaultCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () => onSelectCategory(type),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(type.icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                type.label,
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: AppTypography.titleSmall.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthState>();
    final vaultState = context.watch<VaultState>();
    final userName = authState.userProfile.displayName;

    final totalItems = vaultState.totalCount;
    final favorites = vaultState.favoriteItems;
    final recents = vaultState.recentlyUsedItems;
    final activeVault = vaultState.activeVault;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar & Multi-Vault Switcher
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getTimeGreeting()}, $userName',
                          style: AppTypography.displayMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => VaultSwitcherBottomSheet.show(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(activeVault.icon, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(
                                  '${activeVault.name} ($totalItems)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.lock_outline_rounded, size: 20),
                      tooltip: 'Lock Vault Now',
                      onPressed: () => authState.lock(),
                    ),
                  ],
                ),
              ),
            ),

            // Search Trigger Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: VaultCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: () => onNavigateTab(1), // Switch to Search tab
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search your vault...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Smart Collections Quick Filters
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ActionChip(
                      avatar: const Text('🛡️', style: TextStyle(fontSize: 13)),
                      label: Text('Passkeys (${vaultState.passkeysCount})'),
                      onPressed: () {
                        vaultState.setSmartCollection(SmartCollectionType.passkeys);
                        onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Text('⭐', style: TextStyle(fontSize: 13)),
                      label: Text('Favorites (${favorites.length})'),
                      onPressed: () {
                        vaultState.setSmartCollection(SmartCollectionType.favorites);
                        onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Text('📎', style: TextStyle(fontSize: 13)),
                      label: const Text('Files'),
                      onPressed: () {
                        vaultState.setSmartCollection(SmartCollectionType.files);
                        onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Text('⚠️', style: TextStyle(fontSize: 13)),
                      label: const Text('Weak/Reused'),
                      onPressed: () {
                        vaultState.setSmartCollection(SmartCollectionType.weak);
                        onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Text('🔐', style: TextStyle(fontSize: 13)),
                      label: const Text('Missing 2FA'),
                      onPressed: () {
                        vaultState.setSmartCollection(SmartCollectionType.missing2FA);
                        onNavigateTab(1);
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (totalItems == 0) ...[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: '🔐',
                  title: 'Your Vault is Ready',
                  description: 'Add your first login, passkey, card, or secure note to protect it offline.',
                  actionLabel: 'Add Item',
                  onAction: () => _createNewItem(context),
                ),
              ),
            ] else ...[
              // Favorites Section
              if (favorites.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Favorites',
                      style: AppTypography.titleSmall.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = favorites[index];
                        return VaultItemTile(
                          item: item,
                          onTap: () => _openItem(context, item),
                          onFavoriteToggle: () {
                            if (authState.activeKey != null) {
                              vaultState.toggleFavorite(item.id, authState.activeKey!);
                            }
                          },
                          onQuickCopy: item.password != null ? () => _quickCopy(context, item) : null,
                        );
                      },
                      childCount: favorites.length,
                    ),
                  ),
                ),
              ],

              // Recently Used Section
              if (recents.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Recently Used',
                      style: AppTypography.titleSmall.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = recents[index];
                        return VaultItemTile(
                          item: item,
                          onTap: () => _openItem(context, item),
                          onFavoriteToggle: () {
                            if (authState.activeKey != null) {
                              vaultState.toggleFavorite(item.id, authState.activeKey!);
                            }
                          },
                          onQuickCopy: item.password != null ? () => _quickCopy(context, item) : null,
                        );
                      },
                      childCount: recents.length.clamp(0, 5),
                    ),
                  ),
                ),
              ],

              // Tags Section
              if (vaultState.allTags.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Tags',
                      style: AppTypography.titleSmall.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: vaultState.allTags.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final tag = vaultState.allTags[idx];
                        return ActionChip(
                          avatar: const Icon(Icons.tag_rounded, size: 14),
                          label: Text('#$tag'),
                          onPressed: () {
                            vaultState.setTagFilter(tag);
                            onNavigateTab(1); // Switch to search
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Categories Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Categories',
                    style: AppTypography.titleSmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(180),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.login,
                        count: vaultState.countForType(VaultItemType.login),
                        color: AppColors.categoryLogin,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.passkey,
                        count: vaultState.countForType(VaultItemType.passkey),
                        color: Colors.deepPurpleAccent,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.password,
                        count: vaultState.countForType(VaultItemType.password),
                        color: AppColors.categoryPassword,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.card,
                        count: vaultState.countForType(VaultItemType.card),
                        color: AppColors.categoryCard,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.identity,
                        count: vaultState.countForType(VaultItemType.identity),
                        color: AppColors.categoryIdentity,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.note,
                        count: vaultState.countForType(VaultItemType.note),
                        color: AppColors.categoryNote,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.file,
                        count: vaultState.countForType(VaultItemType.file),
                        color: Colors.teal,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.recoveryCode,
                        count: vaultState.countForType(VaultItemType.recoveryCode),
                        color: Colors.indigo,
                      ),
                      _buildCategoryRow(
                        context,
                        type: VaultItemType.license,
                        count: vaultState.countForType(VaultItemType.license),
                        color: Colors.amber.shade800,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewItem(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
