import '../../data/models/vault_item.dart';

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
    // Check multi-part TLDs like .co.uk
    if (parts.length >= 3 && parts[parts.length - 2].length <= 3 && parts[parts.length - 1].length <= 2) {
      return '${parts[parts.length - 3]}.${parts[parts.length - 2]}.${parts[parts.length - 1]}';
    }
    // Return last 2 parts for standard domains (e.g. github.com)
    return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
  }

  /// Finds matching vault login items for a given app / website URL with strict domain checking
  static List<VaultItem> findMatches({
    required String targetUrl,
    required List<VaultItem> items,
  }) {
    final targetHost = extractHost(targetUrl);
    if (targetHost == null) return [];
    final targetBase = extractBaseDomain(targetUrl);

    final exactMatches = <VaultItem>[];
    final domainMatches = <VaultItem>[];

    for (final item in items) {
      if (item.type != VaultItemType.login) continue;
      if (item.website == null || item.website!.trim().isEmpty) continue;

      final itemHost = extractHost(item.website!);
      if (itemHost == null) continue;

      if (itemHost == targetHost) {
        exactMatches.add(item);
      } else {
        final itemBase = extractBaseDomain(item.website!);
        if (itemBase != null && targetBase != null && itemBase == targetBase) {
          domainMatches.add(item);
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
}
