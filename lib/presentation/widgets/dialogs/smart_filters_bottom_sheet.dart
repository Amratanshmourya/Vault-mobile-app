import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';
import '../../state/vault_state.dart';

class SmartFiltersBottomSheet extends StatelessWidget {
  const SmartFiltersBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SmartFiltersBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = context.watch<VaultState>();
    final allTags = vaultState.allTags;
    final folders = vaultState.folders;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters & Sorting',
                  style: AppTypography.displayMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    vaultState.clearFilters();
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Sort By Section
                  Text(
                    'SORT BY',
                    style: AppTypography.titleSmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140),
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortOption.values.map((opt) {
                      final isSelected = vaultState.sortOption == opt;
                      return ChoiceChip(
                        label: Text(opt.label),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            vaultState.setSortOption(opt);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Quick Toggles
                  Text(
                    'QUICK ATTRIBUTES',
                    style: AppTypography.titleSmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140),
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          avatar: Icon(
                            vaultState.filterFavoritesOnly
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: vaultState.filterFavoritesOnly ? Colors.amber : null,
                          ),
                          label: const Text('Favorites Only'),
                          selected: vaultState.filterFavoritesOnly,
                          selectedColor: Colors.amber.withAlpha(30),
                          onSelected: (_) => vaultState.toggleFavoritesFilter(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilterChip(
                          avatar: Icon(
                            vaultState.filterHasTotpOnly
                                ? Icons.timer_rounded
                                : Icons.timer_outlined,
                            size: 18,
                            color: vaultState.filterHasTotpOnly ? AppColors.success : null,
                          ),
                          label: const Text('Has 2FA / TOTP'),
                          selected: vaultState.filterHasTotpOnly,
                          selectedColor: AppColors.success.withAlpha(30),
                          onSelected: (_) => vaultState.toggleHasTotpFilter(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Categories
                  Text(
                    'CATEGORY',
                    style: AppTypography.titleSmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140),
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Categories'),
                        selected: vaultState.selectedCategory == null,
                        onSelected: (selected) {
                          if (selected) vaultState.setCategoryFilter(null);
                        },
                      ),
                      ...VaultItemType.values.map((type) {
                        final isSelected = vaultState.selectedCategory == type;
                        return ChoiceChip(
                          avatar: Text(type.icon, style: const TextStyle(fontSize: 14)),
                          label: Text('${type.label} (${vaultState.countForType(type)})'),
                          selected: isSelected,
                          onSelected: (selected) {
                            vaultState.setCategoryFilter(selected ? type : null);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Folders
                  if (folders.isNotEmpty) ...[
                    Text(
                      'FOLDER',
                      style: AppTypography.titleSmall.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(140),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Folders'),
                          selected: vaultState.selectedFolder == null,
                          onSelected: (selected) {
                            if (selected) vaultState.setFolderFilter(null);
                          },
                        ),
                        ...folders.map((folder) {
                          final isSelected = vaultState.selectedFolder == folder.id;
                          return ChoiceChip(
                            avatar: Text(folder.icon ?? '📁', style: const TextStyle(fontSize: 14)),
                            label: Text(folder.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              vaultState.setFolderFilter(selected ? folder.id : null);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tags Filter
                  if (allTags.isNotEmpty) ...[
                    Text(
                      'TAGS',
                      style: AppTypography.titleSmall.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(140),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Tags'),
                          selected: vaultState.selectedTag == null,
                          onSelected: (selected) {
                            if (selected) vaultState.setTagFilter(null);
                          },
                        ),
                        ...allTags.map((tag) {
                          final isSelected = vaultState.selectedTag == tag;
                          return ChoiceChip(
                            label: Text('#$tag'),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withAlpha(40),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              vaultState.setTagFilter(selected ? tag : null);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('View ${vaultState.filteredItems.length} Matching Items'),
            ),
          ],
        ),
      ),
    );
  }
}
