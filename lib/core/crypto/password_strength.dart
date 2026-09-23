import 'dart:math';

enum PasswordStrengthLevel {
  veryWeak('Very Weak', 0.15),
  weak('Weak', 0.35),
  fair('Fair', 0.60),
  strong('Strong', 0.85),
  veryStrong('Very Strong', 1.0);

  final String label;
  final double progress;
  const PasswordStrengthLevel(this.label, this.progress);
}

class PasswordStrengthResult {
  final double score; // 0.0 to 1.0
  final PasswordStrengthLevel level;
  final List<String> warnings;
  final List<String> suggestions;
  final double entropyBits;

  const PasswordStrengthResult({
    required this.score,
    required this.level,
    required this.warnings,
    required this.suggestions,
    required this.entropyBits,
  });
}

class PasswordStrength {
  static const List<String> _commonPasswords = [
    '123456', 'password', '12345678', 'qwerty', '123456789', '12345', '1234',
    '111111', '1234567', 'dragon', 'welcome', 'admin', 'password1', 'master',
    'pass123', 'qwerty123', 'iloveyou', 'letmein', 'monkey', 'sunshine',
    'princess', 'football', 'charlie', 'donald', 'trustno1'
  ];

  static PasswordStrengthResult evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0.0,
        level: PasswordStrengthLevel.veryWeak,
        warnings: ['Password cannot be empty'],
        suggestions: ['Use at least 12 characters with a mix of symbols, numbers, and letters'],
        entropyBits: 0,
      );
    }

    final lower = password.toLowerCase();
    final List<String> warnings = [];
    final List<String> suggestions = [];

    // Check exact common passwords
    if (_commonPasswords.contains(lower)) {
      return const PasswordStrengthResult(
        score: 0.05,
        level: PasswordStrengthLevel.veryWeak,
        warnings: ['This is an extremely common password'],
        suggestions: ['Avoid well-known passwords. Use a randomly generated one.'],
        entropyBits: 10,
      );
    }

    // Pool size estimation
    int poolSize = 0;
    bool hasLower = RegExp(r'[a-z]').hasMatch(password);
    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    bool hasDigit = RegExp(r'[0-9]').hasMatch(password);
    bool hasSymbol = RegExp(r'[^a-zA-Z0-9]').hasMatch(password);

    if (hasLower) poolSize += 26;
    if (hasUpper) poolSize += 26;
    if (hasDigit) poolSize += 10;
    if (hasSymbol) poolSize += 33;

    final double entropy = poolSize > 0 ? password.length * (log(poolSize) / log(2)) : 0;

    double score = 0.0;

    // Length points
    if (password.length < 8) {
      score += 0.15;
      warnings.add('Password is too short');
      suggestions.add('Use at least 12 characters');
    } else if (password.length < 12) {
      score += 0.40;
      suggestions.add('Consider using 14+ characters for optimal security');
    } else if (password.length < 16) {
      score += 0.65;
    } else {
      score += 0.80;
    }

    // Diversity points
    int typesCount = 0;
    if (hasLower) typesCount++;
    if (hasUpper) typesCount++;
    if (hasDigit) typesCount++;
    if (hasSymbol) typesCount++;

    score += (typesCount / 4.0) * 0.25;

    if (!hasUpper && !hasLower) {
      warnings.add('Missing letters');
    }
    if (!hasDigit) {
      suggestions.add('Add numbers to increase strength');
    }
    if (!hasSymbol) {
      suggestions.add('Add special symbols (e.g. !@#\$)');
    }

    // Repetition and sequence penalties
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      score -= 0.15;
      warnings.add('Contains repeated characters');
    }

    if (RegExp(r'abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz|012|123|234|345|456|567|678|789', caseSensitive: false).hasMatch(password)) {
      score -= 0.15;
      warnings.add('Contains sequential characters');
    }

    score = score.clamp(0.0, 1.0);

    PasswordStrengthLevel level;
    if (score < 0.25) {
      level = PasswordStrengthLevel.veryWeak;
    } else if (score < 0.45) {
      level = PasswordStrengthLevel.weak;
    } else if (score < 0.70) {
      level = PasswordStrengthLevel.fair;
    } else if (score < 0.88) {
      level = PasswordStrengthLevel.strong;
    } else {
      level = PasswordStrengthLevel.veryStrong;
    }

    return PasswordStrengthResult(
      score: score,
      level: level,
      warnings: warnings,
      suggestions: suggestions,
      entropyBits: entropy,
    );
  }
}
