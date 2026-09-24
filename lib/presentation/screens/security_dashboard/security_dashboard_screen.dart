import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/security_audit_result.dart';
import '../../../data/models/vault_item.dart';
import '../../state/security_dashboard_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/vault_card.dart';
import '../../widgets/common/vault_item_tile.dart';
import '../item_detail/item_detail_screen.dart';
import '../item_editor/item_editor_screen.dart';
import 'security_activity_screen.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = context.read<VaultState>().allItems;
      context.read<SecurityDashboardState>().analyze(items);
    });
  }

  void _openItem(BuildContext context, VaultItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(itemId: item.id),
      ),
    );
  }

  void _fixItem(BuildContext context, VaultItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemEditorScreen(initialItem: item),
      ),
    );
  }

  void _openActivityLog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SecurityActivityScreen(),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: VaultCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: isSelected ? color.withAlpha(20) : null,
        border: isSelected ? BorderSide(color: color, width: 1.5) : null,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: color),
                Text(
                  '$count',
                  style: AppTypography.titleLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(160),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = context.watch<VaultState>();
    final dashboardState = context.watch<SecurityDashboardState>();

    // Re-analyze when items change
    final audit = dashboardState.auditResult ?? SecurityAuditResult.analyze(vaultState.allItems);
    final filter = dashboardState.selectedFilter;

    Color scoreColor = AppColors.success;
    if (audit.overallScore < 50) {
      scoreColor = AppColors.danger;
    } else if (audit.overallScore < 80) {
      scoreColor = AppColors.warning;
    }

    // Determine items to display based on selected filter
    List<VaultItem> displayedItems = [];
    if (filter == SecurityFilterType.weak) {
      displayedItems = audit.weakItems;
    } else if (filter == SecurityFilterType.reused) {
      displayedItems = audit.reusedGroups.expand((g) => g.items).toList();
    } else if (filter == SecurityFilterType.old) {
      displayedItems = audit.oldItems;
    } else if (filter == SecurityFilterType.missing2fa) {
      displayedItems = audit.missing2faItems;
    } else if (filter == SecurityFilterType.passkeyOpportunities) {
      displayedItems = audit.passkeyOpportunities.map((o) => o.item).toList();
    } else {
      // All issues combined
      final Set<String> issueIds = {
        ...audit.weakItems.map((e) => e.id),
        ...audit.reusedGroups.expand((g) => g.items).map((e) => e.id),
        ...audit.oldItems.map((e) => e.id),
      };
      displayedItems = vaultState.allItems.where((i) => issueIds.contains(i.id)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard & Audit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            tooltip: 'Activity Audit Log',
            onPressed: () => _openActivityLog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card
            VaultCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Circular Score indicator
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: audit.overallScore / 100.0,
                          strokeWidth: 6,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                        Text(
                          '${audit.overallScore}',
                          style: AppTypography.displayMedium.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vault Health: ${audit.statusLabel}',
                          style: AppTypography.titleMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zero-knowledge evaluation across ${audit.totalScanned} items for weak, reused, or unhardened credentials.',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Passkey Opportunities Alert Card
            if (audit.passkeyOpportunities.isNotEmpty) ...[
              VaultCard(
                padding: const EdgeInsets.all(16),
                color: Colors.deepPurpleAccent.withAlpha(15),
                border: BorderSide(color: Colors.deepPurpleAccent.withAlpha(50)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🛡️', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${audit.passkeyOpportunities.length} Passkey Upgrades Available',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upgrade logins on ${audit.passkeyOpportunities.take(2).map((o) => o.serviceName).join(", ")} to phishing-resistant passkeys.',
                            style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => dashboardState.setFilter(SecurityFilterType.passkeyOpportunities),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Metrics Grid (Weak, Reused, Old, Missing 2FA)
            Row(
              children: [
                _buildMetricCard(
                  context,
                  title: 'Weak',
                  count: audit.weakItems.length,
                  icon: Icons.gpp_bad_outlined,
                  color: AppColors.danger,
                  isSelected: filter == SecurityFilterType.weak,
                  onTap: () => dashboardState.setFilter(
                    filter == SecurityFilterType.weak ? SecurityFilterType.all : SecurityFilterType.weak,
                  ),
                ),
                const SizedBox(width: 10),
                _buildMetricCard(
                  context,
                  title: 'Reused (ZK)',
                  count: audit.reusedGroups.fold<int>(0, (prev, g) => prev + g.items.length),
                  icon: Icons.repeat_rounded,
                  color: AppColors.warning,
                  isSelected: filter == SecurityFilterType.reused,
                  onTap: () => dashboardState.setFilter(
                    filter == SecurityFilterType.reused ? SecurityFilterType.all : SecurityFilterType.reused,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricCard(
                  context,
                  title: 'Old (>180d)',
                  count: audit.oldItems.length,
                  icon: Icons.history_rounded,
                  color: AppColors.info,
                  isSelected: filter == SecurityFilterType.old,
                  onTap: () => dashboardState.setFilter(
                    filter == SecurityFilterType.old ? SecurityFilterType.all : SecurityFilterType.old,
                  ),
                ),
                const SizedBox(width: 10),
                _buildMetricCard(
                  context,
                  title: 'No 2FA',
                  count: audit.missing2faItems.length,
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.secondary,
                  isSelected: filter == SecurityFilterType.missing2fa,
                  onTap: () => dashboardState.setFilter(
                    filter == SecurityFilterType.missing2fa ? SecurityFilterType.all : SecurityFilterType.missing2fa,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actionable Review Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filter == SecurityFilterType.weak
                      ? 'Weak Passwords (${audit.weakItems.length})'
                      : filter == SecurityFilterType.reused
                          ? 'Reused Passwords (${audit.reusedGroups.fold<int>(0, (p, g) => p + g.items.length)})'
                          : filter == SecurityFilterType.old
                              ? 'Outdated Passwords (${audit.oldItems.length})'
                              : filter == SecurityFilterType.missing2fa
                                  ? 'Logins without 2FA (${audit.missing2faItems.length})'
                                  : filter == SecurityFilterType.passkeyOpportunities
                                      ? 'Passkey Candidates (${audit.passkeyOpportunities.length})'
                                      : 'Items Requiring Review (${displayedItems.length})',
                  style: AppTypography.titleSmall.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
                if (filter != SecurityFilterType.all)
                  TextButton(
                    onPressed: () => dashboardState.setFilter(SecurityFilterType.all),
                    child: const Text('Show All Issues'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (displayedItems.isEmpty) ...[
              const EmptyState(
                icon: '🛡️',
                title: 'No Issues Found',
                description: 'All your scanned vault items meet healthy security standards.',
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedItems.length,
                itemBuilder: (context, index) {
                  final item = displayedItems[index];
                  return Row(
                    children: [
                      Expanded(
                        child: VaultItemTile(
                          item: item,
                          onTap: () => _openItem(context, item),
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonal(
                        onPressed: () => _fixItem(context, item),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(64, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Fix', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
