import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'vault_item.dart';
import '../../core/crypto/password_strength.dart';

class ReusedPasswordGroup {
  final String passwordHash;
  final String sampleTitle;
  final List<VaultItem> items;

  ReusedPasswordGroup({
    required this.passwordHash,
    required this.sampleTitle,
    required this.items,
  });
}

class PasskeyOpportunity {
  final VaultItem item;
  final String serviceName;
  final String domain;

  const PasskeyOpportunity({
    required this.item,
    required this.serviceName,
    required this.domain,
  });
}

class SecurityAuditResult {
  final int overallScore; // 0 to 100
  final String statusLabel;
  final List<VaultItem> weakItems;
  final List<ReusedPasswordGroup> reusedGroups;
  final List<VaultItem> oldItems;
  final List<VaultItem> missing2faItems;
  final List<PasskeyOpportunity> passkeyOpportunities;
  final int passkeyCount;
  final int totalScanned;

  const SecurityAuditResult({
    required this.overallScore,
    required this.statusLabel,
    required this.weakItems,
    required this.reusedGroups,
    required this.oldItems,
    required this.missing2faItems,
    required this.passkeyOpportunities,
    required this.passkeyCount,
    required this.totalScanned,
  });

  static const Map<String, String> _passkeyCompatibleDomains = {
    'google.com': 'Google',
    'github.com': 'GitHub',
    'apple.com': 'Apple',
    'microsoft.com': 'Microsoft',
    'amazon.com': 'Amazon',
    'paypal.com': 'PayPal',
    'x.com': 'X / Twitter',
    'twitter.com': 'X / Twitter',
    'cloudflare.com': 'Cloudflare',
    'uber.com': 'Uber',
    'ebay.com': 'eBay',
    'shopify.com': 'Shopify',
    'tiktok.com': 'TikTok',
    'adobe.com': 'Adobe',
    'whatsapp.com': 'WhatsApp',
    'fastmail.com': 'Fastmail',
    'sony.com': 'PlayStation / Sony',
    'playstation.com': 'PlayStation',
    'nintendo.com': 'Nintendo',
  };

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
        passkeyOpportunities: [],
        passkeyCount: 0,
        totalScanned: 0,
      );
    }

    final List<VaultItem> weak = [];
    final Map<String, List<VaultItem>> hashToItems = {};
    final List<VaultItem> old = [];
    final List<VaultItem> missing2fa = [];
    final List<PasskeyOpportunity> passkeyOpportunities = [];
    int passkeyCount = 0;

    final now = DateTime.now();

    for (final item in activeItems) {
      if (item.hasPasskey) {
        passkeyCount++;
      }

      final pwd = item.password;
      if (pwd != null && pwd.isNotEmpty) {
        // Evaluate strength
        final strength = PasswordStrength.evaluate(pwd);
        if (strength.level == PasswordStrengthLevel.veryWeak ||
            strength.level == PasswordStrengthLevel.weak) {
          weak.add(item);
        }

        // Zero-Knowledge reuse tracking (by SHA-256 hash)
        final hash = sha256.convert(utf8.encode(pwd)).toString();
        hashToItems.putIfAbsent(hash, () => []).add(item);

        // Check age (> 180 days)
        final updateDate = item.passwordUpdatedAt ?? item.updatedAt;
        final ageDays = now.difference(updateDate).inDays;
        if (ageDays > 180) {
          old.add(item);
        }
      }

      // Check 2FA for logins
      if (item.type == VaultItemType.login) {
        if (item.totpSecret == null || item.totpSecret!.trim().isEmpty) {
          missing2fa.add(item);
        }

        // Check Passkey opportunities
        if (!item.hasPasskey && item.normalizedDomain != null) {
          final domain = item.normalizedDomain!;
          for (final entry in _passkeyCompatibleDomains.entries) {
            if (domain == entry.key || domain.endsWith('.${entry.key}')) {
              passkeyOpportunities.add(PasskeyOpportunity(
                item: item,
                serviceName: entry.value,
                domain: domain,
              ));
              break;
            }
          }
        }
      }
    }

    final List<ReusedPasswordGroup> reused = hashToItems.entries
        .where((e) => e.value.length > 1)
        .map((e) => ReusedPasswordGroup(
              passwordHash: e.key,
              sampleTitle: e.value.first.title,
              items: e.value,
            ))
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

      score -= (weakRatio * 40).round();
      score -= (reusedRatio * 30).round();
      score -= (oldRatio * 15).round();
      if (missing2fa.isNotEmpty) {
        final m2faRatio = (missing2fa.length / activeItems.length).clamp(0.0, 1.0);
        score -= (m2faRatio * 15).round();
      }
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
      passkeyOpportunities: passkeyOpportunities,
      passkeyCount: passkeyCount,
      totalScanned: activeItems.length,
    );
  }
}
