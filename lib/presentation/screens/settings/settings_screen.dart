import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/vault_card.dart';
import '../../widgets/dialogs/backup_password_dialog.dart';
import '../../widgets/dialogs/confirm_action_dialog.dart';
import '../../widgets/dialogs/vault_switcher_bottom_sheet.dart';
import '../security_dashboard/security_activity_screen.dart';
import '../trash/trash_screen.dart';
import 'vault_maintenance_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();

  AutoLockTimeout _autoLock = AutoLockTimeout.fiveMinutes;
  ClipboardTimeoutOption _clipboardTimeout = ClipboardTimeoutOption.thirtySeconds;
  TrashRetentionDays _trashRetention = TrashRetentionDays.thirtyDays;
  bool _pwHistoryEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoSecs = await _storageService.getAutoLockSeconds();
    final clipSecs = await _storageService.getClipboardTimeoutSeconds();
    final trashDays = await _storageService.getTrashRetentionDays();
    final pwHist = await _storageService.isPasswordHistoryEnabled();

    if (mounted) {
      setState(() {
        _autoLock = AutoLockTimeout.values.firstWhere(
          (e) => e.seconds == autoSecs,
          orElse: () => AutoLockTimeout.fiveMinutes,
        );
        _clipboardTimeout = ClipboardTimeoutOption.values.firstWhere(
          (e) => e.seconds == clipSecs,
          orElse: () => ClipboardTimeoutOption.thirtySeconds,
        );
        _trashRetention = TrashRetentionDays.values.firstWhere(
          (e) => e.days == trashDays,
          orElse: () => TrashRetentionDays.thirtyDays,
        );
        _pwHistoryEnabled = pwHist;
      });
    }
  }

  void _editDisplayName(BuildContext context) {
    final authState = context.read<AuthState>();
    final controller = TextEditingController(text: authState.userProfile.displayName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: CustomTextField(
          controller: controller,
          label: 'Name',
          hintText: 'e.g. Amratansh',
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                authState.updateDisplayName(controller.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changeMasterPassword(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Change Master Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: oldCtrl,
                  label: 'Current Master Password',
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: newCtrl,
                  label: 'New Master Password',
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: confirmCtrl,
                  label: 'Confirm New Password',
                  isPassword: true,
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (newCtrl.text.length < 8) {
                  setDlgState(() => error = 'New password must be at least 8 characters');
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  setDlgState(() => error = 'New passwords do not match');
                  return;
                }

                try {
                  final authState = context.read<AuthState>();
                  final vaultState = context.read<VaultState>();
                  final newKey = await authState.changeMasterPassword(
                    oldPassword: oldCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  await vaultState.loadVault(newKey);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Master password updated successfully!')),
                    );
                  }
                } catch (e) {
                  setDlgState(() => error = 'Incorrect current password');
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    final password = await BackupPasswordDialog.show(
      context,
      title: 'Create Encrypted Backup',
      description: 'Choose a dedicated backup password to encrypt this file. You will need this password to restore your vault.',
      actionLabel: 'Export Backup',
      isConfirmRequired: true,
    );

    if (password != null && context.mounted) {
      try {
        final vaultState = context.read<VaultState>();
        final backupString = await vaultState.exportBackup(password);

        // Verification pass: cryptographically verify backup integrity before sharing
        final isValid = await vaultState.verifyBackup(
          rawBackupString: backupString,
          backupPassword: password,
        );

        if (!isValid) {
          throw Exception('Cryptographic backup verification failed.');
        }

        final nowStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
        final fileName = 'Vault_$nowStr.vault';

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(backupString);

        await Share.shareXFiles([XFile(file.path)], text: 'Vault Encrypted Backup ($fileName)');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup creation failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _verifyBackupFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final file = File(filePath);
    final rawBackup = await file.readAsString();

    if (!context.mounted) return;

    final password = await BackupPasswordDialog.show(
      context,
      title: 'Verify Backup File',
      description: 'Enter the backup password to test cryptographic integrity.',
      actionLabel: 'Verify Integrity',
      isConfirmRequired: false,
    );

    if (password == null || !context.mounted) return;

    try {
      final vaultState = context.read<VaultState>();
      final preview = await vaultState.inspectBackup(
        rawBackupString: rawBackup,
        backupPassword: password,
      );

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 8),
              Text('Backup Verified'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Integrity status: 100% Valid (AES-256-GCM / PBKDF2)'),
              const SizedBox(height: 8),
              Text('Items: ${preview.items.length}'),
              Text('Folders: ${preview.folders.length}'),
              Text('Created: ${DateFormat('d MMM yyyy, HH:mm').format(preview.metadata.createdAt)}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final file = File(filePath);
    final rawBackup = await file.readAsString();

    if (!context.mounted) return;

    final password = await BackupPasswordDialog.show(
      context,
      title: 'Restore Encrypted Backup',
      description: 'Enter the password used when creating this backup file to decrypt and inspect diff.',
      actionLabel: 'Inspect & Compare',
      isConfirmRequired: false,
    );

    if (password == null || !context.mounted) return;

    try {
      final vaultState = context.read<VaultState>();
      final authState = context.read<AuthState>();

      final preview = await vaultState.inspectBackup(
        rawBackupString: rawBackup,
        backupPassword: password,
      );

      final diff = vaultState.computeRestoreDiff(preview);

      if (!context.mounted) return;

      final dateFormat = DateFormat('d MMM yyyy, HH:mm');
      final createdStr = dateFormat.format(preview.metadata.createdAt);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Diff Preview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backup Date: $createdStr', style: AppTypography.bodySmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('➕ New Items to Add:'),
                        Text('+${diff.addedCount}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🔄 Items to Update:'),
                        Text('~${diff.modifiedCount}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('➖ Items to Remove:'),
                        Text('-${diff.removedCount}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('✔️ Identical Items:'),
                        Text('${diff.unchangedCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Restoring will replace the current contents of your vault.',
                style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Confirm Restore'),
            ),
          ],
        ),
      );

      if (confirmed == true && authState.activeKey != null) {
        await vaultState.restoreBackup(
          preview: preview,
          activeKey: authState.activeKey!,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vault restored successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _clearRecentHistory(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Clear Recent History?',
      message: 'This will reset recently used timestamps on all items.',
      confirmLabel: 'Clear History',
    );

    if (confirmed && context.mounted) {
      final vaultState = context.read<VaultState>();
      final authState = context.read<AuthState>();
      if (authState.activeKey != null) {
        await vaultState.clearRecentHistory(authState.activeKey!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recent history cleared')),
          );
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final authState = context.watch<AuthState>();
    final vaultState = context.watch<VaultState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            VaultCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withAlpha(25),
                    child: Text(
                      authState.userProfile.displayName.isNotEmpty
                          ? authState.userProfile.displayName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.userProfile.displayName,
                          style: AppTypography.titleMedium.copyWith(color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local Vault Owner',
                          style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface.withAlpha(140)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit name',
                    onPressed: () => _editDisplayName(context),
                  ),
                ],
              ),
            ),

            // SECURITY SECTION
            _buildSectionHeader('Security'),
            VaultCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: const Text('Master Password'),
                    subtitle: const Text('Change your master encryption password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _changeMasterPassword(context),
                  ),
                  const Divider(),
                  if (authState.biometricsAvailable) ...[
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded),
                      title: const Text('Biometric Unlock'),
                      subtitle: const Text('Unlock using fingerprint or face ID'),
                      value: authState.biometricsEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final bioService = BiometricService();
                          final authed = await bioService.authenticate(
                            reason: 'Confirm biometrics to enable biometric unlock',
                          );
                          if (authed) {
                            await authState.setBiometricsEnabled(true);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Biometric unlock enabled')),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Biometric verification failed')),
                              );
                            }
                          }
                        } else {
                          await authState.setBiometricsEnabled(false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Biometric unlock disabled')),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Auto-Lock Timeout'),
                    subtitle: Text('Lock vault after ${_autoLock.label}'),
                    trailing: DropdownButton<AutoLockTimeout>(
                      value: _autoLock,
                      underline: const SizedBox(),
                      items: AutoLockTimeout.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _autoLock = val);
                          _storageService.setAutoLockSeconds(val.seconds);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.content_paste_go_outlined),
                    title: const Text('Clipboard Auto-Clear'),
                    subtitle: Text('Clear copied passwords after ${_clipboardTimeout.label}'),
                    trailing: DropdownButton<ClipboardTimeoutOption>(
                      value: _clipboardTimeout,
                      underline: const SizedBox(),
                      items: ClipboardTimeoutOption.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _clipboardTimeout = val);
                          _storageService.setClipboardTimeoutSeconds(val.seconds);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.history_toggle_off_rounded),
                    title: const Text('Password History'),
                    subtitle: const Text('Keep encrypted record of previous passwords'),
                    value: _pwHistoryEnabled,
                    onChanged: (val) {
                      setState(() => _pwHistoryEnabled = val);
                      _storageService.setPasswordHistoryEnabled(val);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.history_edu_rounded),
                    title: const Text('Security Activity Log'),
                    subtitle: const Text('View local on-device security audit trail'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SecurityActivityScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    title: const Text('Lock Vault Now', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    onTap: () => authState.lock(),
                  ),
                ],
              ),
            ),

            // APPEARANCE SECTION
            _buildSectionHeader('Appearance'),
            VaultCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeType>(
                    segments: const [
                      ButtonSegment(value: ThemeType.system, label: Text('System')),
                      ButtonSegment(value: ThemeType.light, label: Text('Light')),
                      ButtonSegment(value: ThemeType.dark, label: Text('Dark')),
                      ButtonSegment(value: ThemeType.amoled, label: Text('AMOLED')),
                    ],
                    selected: {themeProvider.themeType},
                    onSelectionChanged: (set) {
                      themeProvider.setTheme(set.first);
                    },
                  ),
                ],
              ),
            ),

            // VAULT & TRASH SECTION
            _buildSectionHeader('Vault & Data'),
            VaultCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                    title: const Text('Manage Multiple Vaults'),
                    subtitle: Text('${vaultState.vaults.length} vaults configured • Active: ${vaultState.activeVault.name}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => VaultSwitcherBottomSheet.show(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.pie_chart_outline_rounded, color: Colors.teal),
                    title: const Text('Vault Maintenance & Storage'),
                    subtitle: const Text('Integrity diagnostics, storage breakdown & Emergency Kit'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VaultMaintenanceScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Trash'),
                    subtitle: Text('${vaultState.trashItems.length} deleted items'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrashScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.auto_delete_outlined),
                    title: const Text('Auto-Empty Trash'),
                    subtitle: Text('Purge items after ${_trashRetention.label}'),
                    trailing: DropdownButton<TrashRetentionDays>(
                      value: _trashRetention,
                      underline: const SizedBox(),
                      items: TrashRetentionDays.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _trashRetention = val);
                          _storageService.setTrashRetentionDays(val.days);
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.clear_all_rounded),
                    title: const Text('Clear Recent History'),
                    subtitle: const Text('Reset recently accessed items list'),
                    onTap: () => _clearRecentHistory(context),
                  ),
                ],
              ),
            ),

            // BACKUP & RESTORE SECTION
            _buildSectionHeader('Backup & Restore'),
            VaultCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.secondary),
                    title: const Text('Create Encrypted Backup'),
                    subtitle: const Text('Export verified .vault file with password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _createBackup(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.verified_outlined, color: AppColors.success),
                    title: const Text('Verify Backup File'),
                    subtitle: const Text('Check cryptographic validity of a .vault file'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _verifyBackupFile(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_download_outlined, color: AppColors.primary),
                    title: const Text('Restore Encrypted Backup'),
                    subtitle: const Text('Inspect diff and restore from a .vault file'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _restoreBackup(context),
                  ),
                ],
              ),
            ),

            // PRIVACY GUARANTEE & ABOUT
            _buildSectionHeader('Privacy & About'),
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
                          color: AppColors.success.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('100% Offline Guaranteed', style: AppTypography.titleSmall),
                            Text(
                              'Zero cloud servers, zero analytics, zero external network calls.',
                              style: AppTypography.caption.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Version', style: AppTypography.bodySmall),
                      Text('${AppConstants.appVersion} (Offline)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Encryption', style: AppTypography.bodySmall),
                      Text('AES-256-GCM / PBKDF2', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
