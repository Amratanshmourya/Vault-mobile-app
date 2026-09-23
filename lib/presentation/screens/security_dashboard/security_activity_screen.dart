import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/security_activity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/security_event.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/vault_card.dart';

class SecurityActivityScreen extends StatefulWidget {
  const SecurityActivityScreen({super.key});

  @override
  State<SecurityActivityScreen> createState() => _SecurityActivityScreenState();
}

class _SecurityActivityScreenState extends State<SecurityActivityScreen> {
  late final SecurityActivityService _activityService;
  List<SecurityEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final vaultState = context.read<VaultState>();
    _activityService = SecurityActivityService(storageService: vaultState.repository.storageService);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final list = await _activityService.getEvents();
    if (mounted) {
      setState(() {
        _events = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearEvents() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Security History?'),
        content: const Text('This will delete all local event logs. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _activityService.clearEvents();
      await _loadEvents();
    }
  }

  Color _getEventColor(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.vaultUnlocked:
      case SecurityEventType.biometricUnlocked:
        return AppColors.success;
      case SecurityEventType.vaultLocked:
        return AppColors.warning;
      case SecurityEventType.masterPasswordChanged:
        return Colors.orange;
      case SecurityEventType.itemCreated:
      case SecurityEventType.itemRestored:
        return AppColors.primary;
      case SecurityEventType.itemUpdated:
        return Colors.blue;
      case SecurityEventType.itemDeleted:
        return AppColors.danger;
      case SecurityEventType.backupCreated:
      case SecurityEventType.backupRestored:
        return Colors.purple;
      case SecurityEventType.securityAlert:
        return AppColors.danger;
      case SecurityEventType.securityAuditRun:
        return AppColors.info;
    }
  }

  IconData _getEventIcon(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.vaultUnlocked:
        return Icons.lock_open_rounded;
      case SecurityEventType.biometricUnlocked:
        return Icons.fingerprint_rounded;
      case SecurityEventType.vaultLocked:
        return Icons.lock_outline_rounded;
      case SecurityEventType.masterPasswordChanged:
        return Icons.key_rounded;
      case SecurityEventType.itemCreated:
        return Icons.add_circle_outline_rounded;
      case SecurityEventType.itemUpdated:
        return Icons.edit_outlined;
      case SecurityEventType.itemDeleted:
        return Icons.delete_outline_rounded;
      case SecurityEventType.itemRestored:
        return Icons.restore_rounded;
      case SecurityEventType.backupCreated:
        return Icons.backup_outlined;
      case SecurityEventType.backupRestored:
        return Icons.settings_backup_restore_rounded;
      case SecurityEventType.securityAlert:
        return Icons.warning_amber_rounded;
      case SecurityEventType.securityAuditRun:
        return Icons.security_rounded;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Activity Log'),
        actions: [
          if (_events.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear History',
              onPressed: _clearEvents,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _events.isEmpty
                ? const EmptyState(
                    icon: '📜',
                    title: 'No Security Events Yet',
                    description: 'Audit logs will appear here when you create items, modify records, or run backups.',
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: VaultCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.success, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'On-Device Audit Trail',
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Recorded strictly offline. Sensitive credentials and keys are never logged.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: theme.colorScheme.onSurface.withAlpha(150),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final event = _events[index];
                              final color = _getEventColor(event.type);
                              final icon = _getEventIcon(event.type);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: VaultCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(icon, color: color, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.description,
                                              style: AppTypography.titleSmall.copyWith(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatTimestamp(event.timestamp),
                                              style: AppTypography.bodySmall.copyWith(
                                                color: theme.colorScheme.onSurface.withAlpha(120),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _events.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
