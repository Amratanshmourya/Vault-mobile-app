import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';

class ActionBottomSheet extends StatelessWidget {
  const ActionBottomSheet({super.key});

  static Future<VaultItemType?> show(BuildContext context) {
    return showModalBottomSheet<VaultItemType>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const ActionBottomSheet(),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required VaultItemType type,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Navigator.of(context).pop(type),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(type.icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(120),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'New Vault Item',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              type: VaultItemType.login,
              title: 'Login',
              subtitle: 'Website or app username and password',
              color: AppColors.categoryLogin,
            ),
            _buildOption(
              context,
              type: VaultItemType.password,
              title: 'Password',
              subtitle: 'Standalone password or secret key',
              color: AppColors.categoryPassword,
            ),
            _buildOption(
              context,
              type: VaultItemType.card,
              title: 'Payment Card',
              subtitle: 'Credit, debit, or ATM card with PIN & CVV',
              color: AppColors.categoryCard,
            ),
            _buildOption(
              context,
              type: VaultItemType.identity,
              title: 'Identity',
              subtitle: 'Personal info, passport, license, address',
              color: AppColors.categoryIdentity,
            ),
            _buildOption(
              context,
              type: VaultItemType.note,
              title: 'Secure Note',
              subtitle: 'Encrypted private text, Wi-Fi keys, codes',
              color: AppColors.categoryNote,
            ),
          ],
        ),
      ),
    );
  }
}
