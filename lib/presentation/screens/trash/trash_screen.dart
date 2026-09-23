import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/vault_card.dart';
import '../../widgets/dialogs/confirm_action_dialog.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  Future<void> _restoreItem(BuildContext context, VaultItem item) async {
    final vaultState = context.read<VaultState>();
    final authState = context.read<AuthState>();
    if (authState.activeKey != null) {
      await vaultState.restoreFromTrash(item.id, authState.activeKey!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored "${item.title}" to Vault'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteItemPermanently(BuildContext context, VaultItem item) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Permanently Delete?',
      message: 'This cannot be undone. "${item.title}" will be permanently wiped from your device.',
      confirmLabel: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final vaultState = context.read<VaultState>();
      final authState = context.read<AuthState>();
      if (authState.activeKey != null) {
        await vaultState.permanentlyDelete(item.id, authState.activeKey!);
      }
    }
  }

  Future<void> _emptyTrash(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Empty Trash?',
      message: 'All items in trash will be permanently wiped from your device.',
      confirmLabel: 'Empty Trash',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final vaultState = context.read<VaultState>();
      final authState = context.read<AuthState>();
      if (authState.activeKey != null) {
        await vaultState.emptyTrash(authState.activeKey!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = context.watch<VaultState>();
    final trashItems = vaultState.trashItems;
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (trashItems.isNotEmpty)
            TextButton.icon(
              onPressed: () => _emptyTrash(context),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.danger),
              label: const Text('Empty', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: trashItems.isEmpty
          ? const EmptyState(
              icon: '🗑️',
              title: 'Trash is Empty',
              description: 'Items moved to trash will appear here and can be restored or permanently removed.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: trashItems.length,
              itemBuilder: (context, index) {
                final item = trashItems[index];
                final deletedStr = item.deletedAt != null
                    ? dateFormat.format(item.deletedAt!)
                    : 'Recently';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: VaultCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Text(item.type.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Deleted on $deletedStr',
                                style: AppTypography.caption.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(140),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.restore_rounded, size: 20),
                          tooltip: 'Restore',
                          onPressed: () => _restoreItem(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.danger),
                          tooltip: 'Permanently Delete',
                          onPressed: () => _deleteItemPermanently(context, item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
