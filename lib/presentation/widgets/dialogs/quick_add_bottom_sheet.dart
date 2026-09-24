import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';

class QuickAddBottomSheet extends StatelessWidget {
  const QuickAddBottomSheet({super.key});

  static Future<VaultItemType?> show(BuildContext context) {
    return showModalBottomSheet<VaultItemType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QuickAddBottomSheet(),
    );
  }

  Widget _buildItemOption(
    BuildContext context, {
    required VaultItemType type,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Navigator.of(context).pop(type),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withAlpha(50), width: 1),
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
              Icons.arrow_forward_ios_rounded,
              size: 14,
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
                    'Quick Add to Vault',
                    style: AppTypography.displayMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '100% Offline',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildItemOption(
              context,
              type: VaultItemType.login,
              title: 'Login Credential',
              subtitle: 'Username, password, website, TOTP 2FA',
              color: AppColors.categoryLogin,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.passkey,
              title: 'Passkey Credential',
              subtitle: 'FIDO2 / WebAuthn passwordless credential',
              color: Colors.deepPurpleAccent,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.password,
              title: 'Standalone Password',
              subtitle: 'PINs, Wi-Fi keys, passcodes',
              color: AppColors.categoryPassword,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.card,
              title: 'Payment Card',
              subtitle: 'Credit, debit, CVV, expiry date',
              color: AppColors.categoryCard,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.identity,
              title: 'Identity & Passport',
              subtitle: 'SSN, ID numbers, address',
              color: AppColors.categoryIdentity,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.note,
              title: 'Secure Note',
              subtitle: 'Encrypted confidential text & memos',
              color: AppColors.categoryNote,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.file,
              title: 'Encrypted File / Document',
              subtitle: 'ID photo, PDF, seed phrase backup',
              color: Colors.teal,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.recoveryCode,
              title: 'Recovery Codes Checklist',
              subtitle: 'Single-use backup 2FA recovery keys',
              color: Colors.indigo,
            ),
            _buildItemOption(
              context,
              type: VaultItemType.license,
              title: 'Software License',
              subtitle: 'Product activation key & registration info',
              color: Colors.amber.shade800,
            ),
          ],
        ),
      ),
    );
  }
}
