import 'vault_item.dart';
import '../../core/crypto/password_strength.dart';

class ReusedPasswordGroup {
  final String samplePassword;
  final List<VaultItem> items;

  ReusedPasswordGroup({
    required this.samplePassword,
    required this.items,
  });
}

class SecurityAuditResult {
  final int overallScore; // 0 to 100
  final String statusLabel;
  final List<VaultItem> weakItems;
  final List<ReusedPasswordGroup> reusedGroups;
  final List<VaultItem> oldItems;
  final List<VaultItem> missing2faItems;
  final int totalScanned;

  const SecurityAuditResult({
    required this.overallScore,
    required this.statusLabel,
    required this.weakItems,
    required this.reusedGroups,
    required this.oldItems,
    required this.missing2faItems,
    required this.totalScanned,
  });

  static SecurityAuditResult analyze(List<VaultItem> items) {
    final activeItems = items.where((i) => !i.isDeleted).toList();
    if (activeItems.isEmpty) {
      return const SecurityAuditResult(
        overallScore: 100,
        statusLabel: 'Vault Empty',
        weakItems: [],
        reusedGroups: [],
        oldItems: [],
        missing2faItems: [],
        totalScanned: 0,
      );
    }

    final List<VaultItem> weak = [];
    final Map<String, List<VaultItem>> passwordToItems = {};
    final List<VaultItem> old = [];
    final List<VaultItem> missing2fa = [];

    final now = DateTime.now();

    for (final item in activeItems) {
      final pwd = item.password;
      if (pwd != null && pwd.isNotEmpty) {
        // Evaluate strength
        final strength = PasswordStrength.evaluate(pwd);
        if (strength.level == PasswordStrengthLevel.veryWeak ||
            strength.level == PasswordStrengthLevel.weak) {
          weak.add(item);
        }

        // Track reuse
        passwordToItems.putIfAbsent(pwd, () => []).add(item);

        // Check age (> 90 days)
        final ageDays = now.difference(item.updatedAt).inDays;
        if (ageDays > 90) {
          old.add(item);
        }
      }

      // Check 2FA for logins
      if (item.type == VaultItemType.login) {
        if (item.totpSecret == null || item.totpSecret!.trim().isEmpty) {
          missing2fa.add(item);
        }
      }
    }

    final List<ReusedPasswordGroup> reused = passwordToItems.entries
        .where((e) => e.value.length > 1)
        .map((e) => ReusedPasswordGroup(samplePassword: e.key, items: e.value))
        .toList();

    // Calculate score (0-100)
    int passwordCount = 0;
    for (final item in activeItems) {
      if (item.password != null && item.password!.isNotEmpty) {
        passwordCount++;
      }
    }

    int score = 100;
    if (passwordCount > 0) {
      final weakRatio = weak.length / passwordCount;
      final reusedCount = reused.fold<int>(0, (prev, g) => prev + g.items.length);
      final reusedRatio = reusedCount / passwordCount;
      final oldRatio = old.length / passwordCount;

      score -= (weakRatio * 45).round();
      score -= (reusedRatio * 35).round();
      score -= (oldRatio * 20).round();
      score = score.clamp(0, 100);
    }

    String label = 'Excellent';
    if (score < 40) {
      label = 'Critical';
    } else if (score < 70) {
      label = 'Needs Attention';
    } else if (score < 90) {
      label = 'Good';
    }

    return SecurityAuditResult(
      overallScore: score,
      statusLabel: label,
      weakItems: weak,
      reusedGroups: reused,
      oldItems: old,
      missing2faItems: missing2fa,
      totalScanned: activeItems.length,
    );
  }
}
