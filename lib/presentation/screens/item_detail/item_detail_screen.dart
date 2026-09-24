import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/crypto/password_strength.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/category_badge.dart';
import '../../widgets/common/vault_card.dart';
import '../../widgets/dialogs/confirm_action_dialog.dart';
import '../../widgets/security/sensitive_field_tile.dart';
import '../../widgets/security/strength_indicator_bar.dart';
import '../../widgets/security/totp_tile.dart';
import '../files/secure_file_viewer_screen.dart';
import '../item_editor/item_editor_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  void _copy(BuildContext context, String text, String label) async {
    final vaultState = context.read<VaultState>();
    final authState = context.read<AuthState>();
    if (authState.activeKey != null) {
      await vaultState.recordUsage(itemId, authState.activeKey!);
    }
    final msg = await vaultState.clipboardService.copyWithAutoClear(
      text: text,
      itemLabel: label,
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

  void _edit(BuildContext context, VaultItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemEditorScreen(initialItem: item),
      ),
    );
  }

  Future<void> _delete(BuildContext context, VaultItem item) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Move to Trash?',
      message: 'This item will be moved to Trash. You can restore it later.',
      confirmLabel: 'Move to Trash',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final vaultState = context.read<VaultState>();
      final authState = context.read<AuthState>();
      if (authState.activeKey != null) {
        await vaultState.moveToTrash(item.id, authState.activeKey!);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _toggleRecoveryCode(BuildContext context, VaultItem item, int index) async {
    final authState = context.read<AuthState>();
    final vaultState = context.read<VaultState>();
    final activeKey = authState.activeKey;
    if (activeKey == null) return;

    final updatedCodes = List<RecoveryCodeEntry>.from(item.recoveryCodes);
    final current = updatedCodes[index];
    updatedCodes[index] = current.copyWith(isUsed: !current.isUsed);

    final updatedItem = item.copyWith(recoveryCodes: updatedCodes);
    await vaultState.updateItem(updatedItem, activeKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = context.watch<VaultState>();
    final authState = context.watch<AuthState>();

    final item = vaultState.allItems.cast<VaultItem?>().firstWhere(
          (i) => i?.id == itemId,
          orElse: () => null,
        );

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found')),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: item.isFavorite ? AppColors.warning : null,
            ),
            tooltip: 'Favorite',
            onPressed: () {
              if (authState.activeKey != null) {
                vaultState.toggleFavorite(item.id, authState.activeKey!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _edit(context, item),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') {
                _delete(context, item);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Move to Trash', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category, Folder, and Tags Header
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CategoryBadge(type: item.type),
                if (item.folder != null && item.folder!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📁 ${item.folder}',
                      style: AppTypography.caption.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                ...item.tags.map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Text(
                      '#$tag',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Passkey Credential Showcase Section
            if (item.hasPasskey) ...[
              VaultCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.deepPurpleAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.passkey?.rpName ?? item.title,
                                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'WebAuthn / FIDO2',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'RP: ${item.passkey?.rpId ?? (item.normalizedDomain ?? "Unknown")}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (item.passkey?.userName != null && item.passkey!.userName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Account:', style: AppTypography.caption.copyWith(color: theme.colorScheme.onSurface.withAlpha(140))),
                            Text(item.passkey!.userName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    if (item.passkey?.credentialId != null && item.passkey!.credentialId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('Credential ID: ', style: AppTypography.caption.copyWith(color: theme.colorScheme.onSurface.withAlpha(140))),
                            Expanded(
                              child: Text(
                                item.passkey!.credentialId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.monospace.copyWith(fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              tooltip: 'Copy Credential ID',
                              onPressed: () => _copy(context, item.passkey!.credentialId, 'Credential ID'),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(item.passkey?.algorithm.label ?? 'ES256'),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                        Chip(
                          label: Text(item.passkey?.authenticatorAttachment.label ?? 'Platform Authenticator'),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Login specific fields
            if (item.username != null && item.username!.isNotEmpty)
              SensitiveFieldTile(
                label: 'USERNAME / EMAIL',
                value: item.username!,
                onCopy: () => _copy(context, item.username!, 'Username'),
              ),

            if (item.password != null && item.password!.isNotEmpty) ...[
              SensitiveFieldTile(
                label: 'PASSWORD',
                value: item.password!,
                isSensitive: true,
                isMonospace: true,
                onCopy: () => _copy(context, item.password!, 'Password'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: StrengthIndicatorBar(
                  strength: PasswordStrength.evaluate(item.password!),
                  showSuggestions: false,
                ),
              ),
            ],

            if (item.website != null && item.website!.isNotEmpty)
              SensitiveFieldTile(
                label: 'WEBSITE',
                value: item.website!,
                onCopy: () => _copy(context, item.website!, 'Website'),
              ),

            // TOTP Authenticator section
            if (item.totpSecret != null && item.totpSecret!.isNotEmpty)
              TotpTile(
                secretBase32: item.totpSecret!,
                onCopy: (code) => _copy(context, code, '2FA Code'),
              ),

            // Payment Card fields
            if (item.cardholderName != null && item.cardholderName!.isNotEmpty)
              SensitiveFieldTile(
                label: 'CARDHOLDER NAME',
                value: item.cardholderName!,
                onCopy: () => _copy(context, item.cardholderName!, 'Cardholder name'),
              ),

            if (item.cardNumber != null && item.cardNumber!.isNotEmpty)
              SensitiveFieldTile(
                label: 'CARD NUMBER',
                value: item.cardNumber!,
                isSensitive: true,
                isMonospace: true,
                onCopy: () => _copy(context, item.cardNumber!, 'Card number'),
              ),

            if ((item.expiryMonth != null && item.expiryMonth!.isNotEmpty) ||
                (item.expiryYear != null && item.expiryYear!.isNotEmpty))
              SensitiveFieldTile(
                label: 'EXPIRY DATE',
                value: '${item.expiryMonth ?? '--'}/${item.expiryYear ?? '--'}',
              ),

            if (item.cvv != null && item.cvv!.isNotEmpty)
              SensitiveFieldTile(
                label: 'CVV / CVC',
                value: item.cvv!,
                isSensitive: true,
                isMonospace: true,
                onCopy: () => _copy(context, item.cvv!, 'CVV'),
              ),

            if (item.pin != null && item.pin!.isNotEmpty)
              SensitiveFieldTile(
                label: 'PIN',
                value: item.pin!,
                isSensitive: true,
                isMonospace: true,
                onCopy: () => _copy(context, item.pin!, 'PIN'),
              ),

            // Identity fields
            if (item.fullName != null && item.fullName!.isNotEmpty)
              SensitiveFieldTile(
                label: 'FULL NAME',
                value: item.fullName!,
                onCopy: () => _copy(context, item.fullName!, 'Full name'),
              ),

            if (item.email != null && item.email!.isNotEmpty)
              SensitiveFieldTile(
                label: 'EMAIL',
                value: item.email!,
                onCopy: () => _copy(context, item.email!, 'Email'),
              ),

            if (item.phone != null && item.phone!.isNotEmpty)
              SensitiveFieldTile(
                label: 'PHONE NUMBER',
                value: item.phone!,
                onCopy: () => _copy(context, item.phone!, 'Phone number'),
              ),

            if (item.address != null && item.address!.isNotEmpty)
              SensitiveFieldTile(
                label: 'ADDRESS',
                value: item.address!,
                onCopy: () => _copy(context, item.address!, 'Address'),
              ),

            if (item.dateOfBirth != null && item.dateOfBirth!.isNotEmpty)
              SensitiveFieldTile(
                label: 'DATE OF BIRTH',
                value: item.dateOfBirth!,
              ),

            // Secure Note content
            if (item.noteContent != null && item.noteContent!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: VaultCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SECURE NOTE',
                            style: AppTypography.caption.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(150),
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy note',
                            onPressed: () => _copy(context, item.noteContent!, 'Note'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        item.noteContent!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Software License fields
            if (item.licenseKey != null && item.licenseKey!.isNotEmpty)
              SensitiveFieldTile(
                label: 'LICENSE KEY',
                value: item.licenseKey!,
                isSensitive: true,
                isMonospace: true,
                onCopy: () => _copy(context, item.licenseKey!, 'License Key'),
              ),

            if (item.licensedTo != null && item.licensedTo!.isNotEmpty)
              SensitiveFieldTile(
                label: 'LICENSED TO',
                value: item.licensedTo!,
                onCopy: () => _copy(context, item.licensedTo!, 'Licensed To'),
              ),

            if (item.licenseExpiry != null && item.licenseExpiry!.isNotEmpty)
              SensitiveFieldTile(
                label: 'EXPIRATION / VALIDITY',
                value: item.licenseExpiry!,
              ),

            // Recovery Codes Checklist Section
            if (item.recoveryCodes.isNotEmpty) ...[
              const SizedBox(height: 12),
              VaultCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECOVERY CODES (${item.recoveryCodes.where((c) => !c.isUsed).length}/${item.recoveryCodes.length} REMAINING)',
                          style: AppTypography.caption.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...item.recoveryCodes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final code = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: code.isUsed,
                              onChanged: (_) => _toggleRecoveryCode(context, item, idx),
                            ),
                            Expanded(
                              child: Text(
                                code.code,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: code.isUsed ? TextDecoration.lineThrough : null,
                                  color: code.isUsed
                                      ? theme.colorScheme.onSurface.withAlpha(100)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              tooltip: 'Copy Code',
                              onPressed: () => _copy(context, code.code, 'Recovery Code'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Encrypted File Attachments Section
            if (item.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              VaultCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENCRYPTED ATTACHMENTS (${item.attachments.length})',
                      style: AppTypography.caption.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...item.attachments.map((att) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(att.fileName, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                        subtitle: Text('${att.formattedSize} • AES-256-GCM'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SecureFileViewerScreen(attachment: att),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Custom fields 2.0
            if (item.customFields.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...item.customFields.map((cf) => SensitiveFieldTile(
                    label: '${cf.label.toUpperCase()} (${cf.type.label.toUpperCase()})',
                    value: cf.value,
                    isSensitive: cf.isConcealed,
                    onCopy: () => _copy(context, cf.value, cf.label),
                  )),
            ],

            // General Notes
            if (item.notes != null && item.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: VaultCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTES',
                        style: AppTypography.caption.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        item.notes!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Password History Section
            if (item.passwordHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              VaultCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASSWORD HISTORY',
                      style: AppTypography.caption.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...item.passwordHistory.reversed.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '••••••••••••',
                                    style: AppTypography.monospace,
                                  ),
                                  Text(
                                    dateFormat.format(entry.recordedAt),
                                    style: AppTypography.caption.copyWith(
                                      color: theme.colorScheme.onSurface.withAlpha(120),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _copy(context, entry.password, 'Historical password'),
                                child: const Text('Copy'),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Updated metadata
            Center(
              child: Text(
                'Updated ${dateFormat.format(item.updatedAt)}',
                style: AppTypography.caption.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
