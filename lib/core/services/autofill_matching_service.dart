import '../../data/models/vault_item.dart';

class AutofillMatchResult {
  final VaultItem item;
  final bool isExactHostMatch;
  final bool hasPasskey;
  final bool hasTotp;

  const AutofillMatchResult({
    required this.item,
    required this.isExactHostMatch,
    required this.hasPasskey,
    required this.hasTotp,
  });
}

class AutofillMatchingService {
  /// Extracts and normalizes the host from a URL or domain string
  static String? extractHost(String rawUrl) {
    if (rawUrl.trim().isEmpty) return null;
    String url = rawUrl.trim().toLowerCase();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      final uri = Uri.parse(url);
      String host = uri.host.toLowerCase();
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      return host.isEmpty ? null : host;
    } catch (_) {
      return null;
    }
  }

  /// Alias for extractHost that normalizes any URL or host string
  static String? normalizeUrlOrHost(String rawUrl) => extractHost(rawUrl);

  /// Extracts the effective registrable base domain (e.g. "auth.github.com" -> "github.com")
  static String? extractBaseDomain(String rawUrl) {
    final host = extractHost(rawUrl);
    if (host == null) return null;
    final parts = host.split('.');
    if (parts.length <= 2) return host;
    // Check multi-part TLDs like .co.uk, .com.au, .co.in
    if (parts.length >= 3 && parts[parts.length - 2].length <= 3 && parts[parts.length - 1].length <= 2) {
      return '${parts[parts.length - 3]}.${parts[parts.length - 2]}.${parts[parts.length - 1]}';
    }
    // Return last 2 parts for standard domains (e.g. github.com)
    return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
  }

  /// Finds matching vault login & passkey items for a given app / website URL with strict domain checking
  static List<VaultItem> findMatches({
    required String targetUrl,
    required List<VaultItem> items,
  }) {
    final ranked = findRankedMatches(targetUrl: targetUrl, items: items);
    return ranked.map((r) => r.item).toList();
  }

  /// Ranked matches including exact host, base domain, and passkey availability
  static List<AutofillMatchResult> findRankedMatches({
    required String targetUrl,
    required List<VaultItem> items,
  }) {
    final targetHost = extractHost(targetUrl);
    if (targetHost == null) return [];
    final targetBase = extractBaseDomain(targetUrl);

    final exactMatches = <AutofillMatchResult>[];
    final domainMatches = <AutofillMatchResult>[];

    for (final item in items) {
      if (item.isDeleted) continue;
      if (item.type != VaultItemType.login && item.type != VaultItemType.passkey) continue;

      final targetDomain = item.website ?? item.passkey?.rpId;
      if (targetDomain == null || targetDomain.trim().isEmpty) continue;

      final itemHost = extractHost(targetDomain);
      if (itemHost == null) continue;

      final hasPasskey = item.hasPasskey;
      final hasTotp = item.totpSecret != null && item.totpSecret!.trim().isNotEmpty;

      if (itemHost == targetHost) {
        exactMatches.add(AutofillMatchResult(
          item: item,
          isExactHostMatch: true,
          hasPasskey: hasPasskey,
          hasTotp: hasTotp,
        ));
      } else {
        final itemBase = extractBaseDomain(targetDomain);
        if (itemBase != null && targetBase != null && itemBase == targetBase) {
          domainMatches.add(AutofillMatchResult(
            item: item,
            isExactHostMatch: false,
            hasPasskey: hasPasskey,
            hasTotp: hasTotp,
          ));
        }
      }
    }

    return [...exactMatches, ...domainMatches];
  }

  /// Convenience alias matching findMatches
  static List<VaultItem> findMatchingLogins({
    required String targetUrlOrHost,
    required List<VaultItem> items,
  }) {
    return findMatches(targetUrl: targetUrlOrHost, items: items);
  }

  /// Strict Anti-Phishing Origin Verification: returns true if targetUrl is spoofing or mismatched
  static bool isOriginSuspicious(String targetUrl, String savedUrl) {
    final tHost = extractHost(targetUrl);
    final sHost = extractHost(savedUrl);
    if (tHost == null || sHost == null) return true;

    final tBase = extractBaseDomain(targetUrl);
    final sBase = extractBaseDomain(savedUrl);

    return tBase != sBase;
  }
}
