import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';
import 'vault_card.dart';

class VaultItemTile extends StatelessWidget {
  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onQuickCopy;

  const VaultItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onQuickCopy,
  });

  String _getSubtitle() {
    switch (item.type) {
      case VaultItemType.login:
        return item.username ?? item.website ?? 'No username';
      case VaultItemType.password:
        return '••••••••••••';
      case VaultItemType.card:
        if (item.cardNumber != null && item.cardNumber!.length >= 4) {
          final last4 = item.cardNumber!.substring(item.cardNumber!.length - 4);
          return '•••• $last4';
        }
        return item.cardholderName ?? 'Card';
      case VaultItemType.identity:
        return item.fullName ?? item.email ?? 'Identity';
      case VaultItemType.note:
        if (item.noteContent != null && item.noteContent!.isNotEmpty) {
          final lines = item.noteContent!.split('\n');
          return lines.first;
        }
        return 'Secure note';
      case VaultItemType.file:
        if (item.attachments.isNotEmpty) {
          return '${item.attachments.length} encrypted ${item.attachments.length == 1 ? "file" : "files"}';
        }
        return 'Secure encrypted file';
      case VaultItemType.recoveryCode:
        final rem = item.recoveryCodes.where((c) => !c.isUsed).length;
        return '$rem of ${item.recoveryCodes.length} recovery codes unused';
      case VaultItemType.license:
        return item.licensedTo ?? item.licenseKey ?? 'Software license';
    }
  }

  Color _getIconBgColor() {
    switch (item.type) {
      case VaultItemType.login:
        return AppColors.categoryLogin.withAlpha(30);
      case VaultItemType.password:
        return AppColors.categoryPassword.withAlpha(30);
      case VaultItemType.card:
        return AppColors.categoryCard.withAlpha(30);
      case VaultItemType.identity:
        return AppColors.categoryIdentity.withAlpha(30);
      case VaultItemType.note:
        return AppColors.categoryNote.withAlpha(30);
      case VaultItemType.file:
        return Colors.teal.withAlpha(30);
      case VaultItemType.recoveryCode:
        return Colors.indigo.withAlpha(30);
      case VaultItemType.license:
        return Colors.amber.shade800.withAlpha(30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: VaultCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconBgColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                item.type.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (item.folder != null && item.folder!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.folder!,
                            style: AppTypography.caption.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(150),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            // Actions: Quick Copy & Favorite
            if (onQuickCopy != null && (item.password != null || item.type == VaultItemType.login)) ...[
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy password',
                color: theme.colorScheme.onSurface.withAlpha(150),
                onPressed: onQuickCopy,
              ),
            ],
            if (onFavoriteToggle != null) ...[
              IconButton(
                icon: Icon(
                  item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 20,
                  color: item.isFavorite ? AppColors.warning : theme.colorScheme.onSurface.withAlpha(120),
                ),
                tooltip: item.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                onPressed: onFavoriteToggle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
