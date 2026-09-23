import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TotpResult {
  final String code;
  final String formattedCode;
  final int remainingSeconds;
  final double progress; // 1.0 (just refreshed) to 0.0 (about to refresh)

  TotpResult({
    required this.code,
    required this.formattedCode,
    required this.remainingSeconds,
    required this.progress,
  });
}

class ParsedOtpAuthUri {
  final String secret;
  final String? issuer;
  final String? account;
  final int period;
  final int digits;

  const ParsedOtpAuthUri({
    required this.secret,
    this.issuer,
    this.account,
    this.period = 30,
    this.digits = 6,
  });

  String? get accountName => account;
  int get periodSeconds => period;
}

class TotpService {
  static const int defaultPeriod = 30;
  static const int defaultDigits = 6;

  /// Parses standard otpauth:// URI into structured metadata
  static ParsedOtpAuthUri? parseOtpAuthUri(String rawUri) {
    try {
      final uri = Uri.parse(rawUri.trim());
      if (uri.scheme.toLowerCase() != 'otpauth') return null;

      final secret = uri.queryParameters['secret'];
      if (secret == null || secret.isEmpty) return null;

      String? issuer = uri.queryParameters['issuer'];
      String? account;

      // Extract from path e.g. /totp/Issuer:account or /totp/account
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final label = Uri.decodeComponent(pathSegments.last);
        if (label.contains(':')) {
          final parts = label.split(':');
          issuer ??= parts[0].trim();
          account = parts.sublist(1).join(':').trim();
        } else {
          account = label.trim();
        }
      }

      final period = int.tryParse(uri.queryParameters['period'] ?? '') ?? defaultPeriod;
      final digits = int.tryParse(uri.queryParameters['digits'] ?? '') ?? defaultDigits;

      return ParsedOtpAuthUri(
        secret: secret.trim().replaceAll(' ', ''),
        issuer: issuer,
        account: account,
        period: period > 0 ? period : defaultPeriod,
        digits: digits > 0 ? digits : defaultDigits,
      );
    } catch (_) {
      return null;
    }
  }

  /// Base32 decoder without external dependencies
  static Uint8List decodeBase32(String input) {
    const String base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
    
    if (cleaned.isEmpty) return Uint8List(0);

    final List<int> result = [];
    int buffer = 0;
    int bitsLeft = 0;

    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];
      final val = base32Chars.indexOf(char);
      if (val == -1) continue;

      buffer = (buffer << 5) | val;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        result.add((buffer >> bitsLeft) & 0xFF);
      }
    }

    return Uint8List.fromList(result);
  }

  /// Generates the current TOTP code and countdown status for a Base32 secret
  static TotpResult? generateCurrent({
    required String secretBase32,
    int period = defaultPeriod,
    int digits = defaultDigits,
    DateTime? now,
  }) {
    final cleanSecret = secretBase32.trim();
    if (cleanSecret.isEmpty) return null;

    try {
      final key = decodeBase32(cleanSecret);
      if (key.isEmpty) return null;

      final currentTime = now ?? DateTime.now();
      final currentSeconds = currentTime.millisecondsSinceEpoch ~/ 1000;
      final counter = currentSeconds ~/ period;
      final elapsedInWindow = currentSeconds % period;
      final remaining = period - elapsedInWindow;
      final progress = remaining / period;

      final code = _generateHotp(key, counter, digits);
      final formatted = digits == 6 
          ? '${code.substring(0, 3)} ${code.substring(3, 6)}' 
          : code;

      return TotpResult(
        code: code,
        formattedCode: formatted,
        remainingSeconds: remaining,
        progress: progress,
      );
    } catch (_) {
      return null;
    }
  }

  static String _generateHotp(Uint8List key, int counter, int digits) {
    // 8-byte big-endian counter
    final msg = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      msg[i] = counter & 0xFF;
      counter = counter >> 8;
    }

    final hmac = Hmac(sha1, key);
    final hash = hmac.convert(msg).bytes;

    // Dynamic truncation
    final offset = hash[hash.length - 1] & 0x0F;
    final binary = ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    final otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  /// Validates if a Base32 secret is formatted reasonably
  static bool isValidSecret(String secret) {
    final cleaned = secret.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length < 8) return false;
    return RegExp(r'^[A-Z2-7]+=*$').hasMatch(cleaned);
  }

  /// Convenience helper to generate a raw code string
  static String? generateCode(
    String secretBase32, {
    DateTime? timestamp,
    int period = defaultPeriod,
    int digits = defaultDigits,
  }) {
    return generateCurrent(
      secretBase32: secretBase32,
      period: period,
      digits: digits,
      now: timestamp,
    )?.code;
  }

  /// Calculates remaining seconds in current window
  static int getRemainingSeconds({
    int periodSeconds = defaultPeriod,
    DateTime? now,
  }) {
    final currentSeconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final elapsedInWindow = currentSeconds % periodSeconds;
    return periodSeconds - elapsedInWindow;
  }

  /// Calculates progress proportion (1.0 to 0.0) in current window
  static double getProgress({
    int periodSeconds = defaultPeriod,
    DateTime? now,
  }) {
    return getRemainingSeconds(periodSeconds: periodSeconds, now: now) / periodSeconds;
  }
}
