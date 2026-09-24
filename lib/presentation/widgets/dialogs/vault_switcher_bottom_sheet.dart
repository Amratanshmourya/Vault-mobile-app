import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';

class VaultSwitcherBottomSheet extends StatelessWidget {
  const VaultSwitcherBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const VaultSwitcherBottomSheet(),
    );
  }

  void _showCreateVaultDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = '🛡️';
    const selectedColor = '#1A80E5';

    final icons = ['🛡️', '💼', '🏠', '💳', '🔐', '💼', '🚀', '⭐', '📦', '🎯'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: const Text('Create New Vault'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Vault Name',
                      hintText: 'e.g. Work, Family, Crypto',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g. Work credentials and server keys',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Choose Icon', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: icons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return InkWell(
                        onTap: () => setState(() => selectedIcon = icon),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary.withAlpha(40) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final authState = Provider.of<AuthState>(context, listen: false);
                  final vaultState = Provider.of<VaultState>(context, listen: false);

                  if (authState.activeKey != null) {
                    await vaultState.createVault(
                      name: name,
                      icon: selectedIcon,
                      colorHex: selectedColor,
                      description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      activeKey: authState.activeKey!,
                    );
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                  }
                },
                child: const Text('Create Vault'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = context.watch<VaultState>();
    final authState = context.watch<AuthState>();
    final vaults = vaultState.vaults;
    final activeVault = vaultState.activeVault;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Vaults',
                    style: AppTypography.displayMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'New Vault',
                    onPressed: () => _showCreateVaultDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...vaults.map((vault) {
              final isCurrent = vault.id == activeVault.id;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Material(
                  color: isCurrent ? theme.colorScheme.primary.withAlpha(20) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      if (!isCurrent && authState.activeKey != null) {
                        await vaultState.switchVault(vault.id, authState.activeKey!);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? theme.colorScheme.primary.withAlpha(80) : theme.dividerColor.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withAlpha(40)),
                            ),
                            alignment: Alignment.center,
                            child: Text(vault.icon, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      vault.name,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    if (vault.isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Default',
                                          style: AppTypography.caption.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${vault.itemCount} items stored locally',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: theme.colorScheme.onSurface.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          else if (!vault.isDefault)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: Text('Delete "${vault.name}"?'),
                                    content: const Text(
                                      'All items inside this vault will be permanently erased. This cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete Permanently'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && authState.activeKey != null) {
                                  await vaultState.deleteVault(vault.id, authState.activeKey!);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
