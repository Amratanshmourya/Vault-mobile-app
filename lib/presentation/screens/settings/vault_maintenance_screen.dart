import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/emergency_kit_service.dart';
import '../../../core/services/encrypted_file_service.dart';
import '../../../core/services/vault_maintenance_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/vault_card.dart';

class VaultMaintenanceScreen extends StatefulWidget {
  const VaultMaintenanceScreen({super.key});

  @override
  State<VaultMaintenanceScreen> createState() => _VaultMaintenanceScreenState();
}

class _VaultMaintenanceScreenState extends State<VaultMaintenanceScreen> {
  late final VaultMaintenanceService _maintenanceService;
  late final EmergencyKitService _emergencyKitService;

  StorageBreakdown? _storageBreakdown;
  VaultIntegrityReport? _integrityReport;
  bool _isLoading = true;
  bool _isOptimizing = false;
  bool _isGeneratingKit = false;

  @override
  void initState() {
    super.initState();
    final vaultState = context.read<VaultState>();
    final storageService = vaultState.repository.storageService;
    final fileService = EncryptedFileService();

    _maintenanceService = VaultMaintenanceService(
      storageService: storageService,
      fileService: fileService,
    );
    _emergencyKitService = EmergencyKitService(storageService: storageService);

    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final vaultState = context.read<VaultState>();
    final items = vaultState.allItems;

    final breakdown = await _maintenanceService.getStorageBreakdown(items);
    final audit = await _maintenanceService.runIntegrityAudit(items);

    if (mounted) {
      setState(() {
        _storageBreakdown = breakdown;
        _integrityReport = audit;
        _isLoading = false;
      });
    }
  }

  Future<void> _runOptimization() async {
    setState(() => _isOptimizing = true);
    final vaultState = context.read<VaultState>();
    final items = vaultState.allItems;

    final pruned = await _maintenanceService.cleanupOrphanedFiles(items);
    await _loadStats();

    if (mounted) {
      setState(() => _isOptimizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pruned > 0
              ? 'Optimized! Pruned $pruned orphaned file attachments.'
              : 'Vault is fully optimized! No orphaned files found.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _generateEmergencyKit() async {
    setState(() => _isGeneratingKit = true);
    final vaultState = context.read<VaultState>();

    try {
      await _emergencyKitService.shareEmergencyKit(
        vaultName: vaultState.activeVault.name,
        items: vaultState.allItems,
        folders: vaultState.folders,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate kit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingKit = false);
    }
  }

  Widget _buildStorageRow(String label, String size, Color color, double fraction) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(label, style: AppTypography.bodyMedium),
                ],
              ),
              Text(size, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.01, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Maintenance & Storage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Diagnostics',
            onPressed: _isLoading ? null : _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vault Integrity Card
                  VaultCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _integrityReport?.isHealthy == true
                                  ? Icons.verified_user_rounded
                                  : Icons.warning_amber_rounded,
                              color: _integrityReport?.isHealthy == true ? AppColors.success : AppColors.warning,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _integrityReport?.isHealthy == true ? 'Cryptographic Integrity Verified' : 'Integrity Issues Detected',
                                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_integrityReport?.validItems ?? 0} valid items • 0 corruptions',
                                    style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_integrityReport != null && _integrityReport!.issues.isNotEmpty) ...[
                          const Divider(height: 24),
                          ..._integrityReport!.issues.map(
                            (issue) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(issue, style: AppTypography.caption)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Storage Footprint Card
                  VaultCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Storage Breakdown', style: AppTypography.titleMedium),
                            Text(
                              _storageBreakdown?.formattedTotal ?? '0 B',
                              style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_storageBreakdown != null) ...[
                          _buildStorageRow(
                            'Encrypted Database (JSON)',
                            _storageBreakdown!.formattedDatabase,
                            AppColors.categoryLogin,
                            _storageBreakdown!.totalBytes > 0
                                ? _storageBreakdown!.databaseBytes / _storageBreakdown!.totalBytes
                                : 0.25,
                          ),
                          _buildStorageRow(
                            'Encrypted File Attachments',
                            _storageBreakdown!.formattedAttachments,
                            Colors.teal,
                            _storageBreakdown!.totalBytes > 0
                                ? _storageBreakdown!.attachmentsBytes / _storageBreakdown!.totalBytes
                                : 0.25,
                          ),
                          _buildStorageRow(
                            'Encrypted Backups Archive',
                            _storageBreakdown!.formattedBackups,
                            Colors.indigo,
                            _storageBreakdown!.totalBytes > 0
                                ? _storageBreakdown!.backupsBytes / _storageBreakdown!.totalBytes
                                : 0.25,
                          ),
                          _buildStorageRow(
                            'Temporary Cache',
                            _storageBreakdown!.formattedCache,
                            Colors.grey,
                            _storageBreakdown!.totalBytes > 0
                                ? _storageBreakdown!.cacheBytes / _storageBreakdown!.totalBytes
                                : 0.25,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: _isOptimizing ? null : _runOptimization,
                            icon: _isOptimizing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.cleaning_services_rounded, size: 18),
                            label: const Text('Optimize Storage & Clean Orphans'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Emergency Recovery Kit Export Card
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
                                color: AppColors.warning.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.medical_services_outlined, color: AppColors.warning, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Emergency Recovery Kit', style: AppTypography.titleMedium),
                                  Text(
                                    'Generate a printable/savable physical recovery sheet with your cryptographic salt fingerprint and restore manual.',
                                    style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isGeneratingKit ? null : _generateEmergencyKit,
                            icon: _isGeneratingKit
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.print_rounded, size: 18),
                            label: const Text('Export Emergency Kit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
