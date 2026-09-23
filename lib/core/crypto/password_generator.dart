import 'dart:math';

class PasswordGeneratorOptions {
  final int length;
  final bool includeUppercase;
  final bool includeLowercase;
  final bool includeNumbers;
  final bool includeSymbols;
  final bool avoidAmbiguous;

  const PasswordGeneratorOptions({
    this.length = 16,
    this.includeUppercase = true,
    this.includeLowercase = true,
    this.includeNumbers = true,
    this.includeSymbols = true,
    this.avoidAmbiguous = false,
  });

  PasswordGeneratorOptions copyWith({
    int? length,
    bool? includeUppercase,
    bool? includeLowercase,
    bool? includeNumbers,
    bool? includeSymbols,
    bool? avoidAmbiguous,
  }) {
    return PasswordGeneratorOptions(
      length: length ?? this.length,
      includeUppercase: includeUppercase ?? this.includeUppercase,
      includeLowercase: includeLowercase ?? this.includeLowercase,
      includeNumbers: includeNumbers ?? this.includeNumbers,
      includeSymbols: includeSymbols ?? this.includeSymbols,
      avoidAmbiguous: avoidAmbiguous ?? this.avoidAmbiguous,
    );
  }
}

class PassphraseOptions {
  final int wordCount;
  final String separator;
  final bool capitalize;
  final bool includeNumber;

  const PassphraseOptions({
    this.wordCount = 4,
    this.separator = '-',
    this.capitalize = true,
    this.includeNumber = true,
  });

  PassphraseOptions copyWith({
    int? wordCount,
    String? separator,
    bool? capitalize,
    bool? includeNumber,
  }) {
    return PassphraseOptions(
      wordCount: wordCount ?? this.wordCount,
      separator: separator ?? this.separator,
      capitalize: capitalize ?? this.capitalize,
      includeNumber: includeNumber ?? this.includeNumber,
    );
  }
}

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  static const String _ambiguous = 'il1Lo0O';

  static const List<String> _dicewareWords = [
    'amber', 'anchor', 'apple', 'arcade', 'arrow', 'atlas', 'autumn', 'badge',
    'bamboo', 'beacon', 'breeze', 'bridge', 'cabin', 'cactus', 'canyon', 'castle',
    'cedar', 'cliff', 'clover', 'comet', 'coral', 'crater', 'crystal', 'delta',
    'desert', 'diamond', 'dolphin', 'dragon', 'dune', 'eagle', 'ember', 'falcon',
    'feather', 'flame', 'forest', 'fossil', 'galaxy', 'garden', 'geyser', 'glacier',
    'granite', 'harbor', 'haven', 'horizon', 'island', 'jungle', 'lagoon', 'lantern',
    'legend', 'lighthouse', 'lotus', 'lunar', 'meadow', 'meteor', 'mineral', 'monarch',
    'moon', 'mountain', 'nebula', 'oasis', 'ocean', 'olive', 'orbit', 'orchid',
    'peak', 'pebble', 'phoenix', 'pillar', 'planet', 'prairie', 'prism', 'quartz',
    'quarry', 'radar', 'radiant', 'rainbow', 'ranger', 'reef', 'river', 'rocket',
    'ruby', 'safari', 'sahara', 'sailor', 'sapphire', 'shadow', 'shield', 'sierra',
    'silver', 'solar', 'spark', 'summit', 'temple', 'thunder', 'timber', 'topaz',
    'valley', 'vapor', 'velvet', 'vessel', 'volcano', 'voyage', 'wave', 'whisper',
    'willow', 'winter', 'zenith', 'zephyr'
  ];

  /// Generates a cryptographically secure random password based on options
  static String generatePassword(PasswordGeneratorOptions options) {
    final Random secureRandom = Random.secure();
    String chars = '';

    String lower = _lowercase;
    String upper = _uppercase;
    String nums = _numbers;
    String syms = _symbols;

    if (options.avoidAmbiguous) {
      for (final c in _ambiguous.split('')) {
        lower = lower.replaceAll(c, '');
        upper = upper.replaceAll(c, '');
        nums = nums.replaceAll(c, '');
      }
    }

    final List<String> guaranteed = [];

    if (options.includeLowercase) {
      chars += lower;
      guaranteed.add(lower[secureRandom.nextInt(lower.length)]);
    }
    if (options.includeUppercase) {
      chars += upper;
      guaranteed.add(upper[secureRandom.nextInt(upper.length)]);
    }
    if (options.includeNumbers) {
      chars += nums;
      guaranteed.add(nums[secureRandom.nextInt(nums.length)]);
    }
    if (options.includeSymbols) {
      chars += syms;
      guaranteed.add(syms[secureRandom.nextInt(syms.length)]);
    }

    if (chars.isEmpty) {
      chars = _lowercase + _numbers;
      guaranteed.add(_lowercase[secureRandom.nextInt(_lowercase.length)]);
    }

    final int remaining = max(0, options.length - guaranteed.length);
    final List<String> result = List.from(guaranteed);

    for (int i = 0; i < remaining; i++) {
      result.add(chars[secureRandom.nextInt(chars.length)]);
    }

    // Cryptographically shuffle
    for (int i = result.length - 1; i > 0; i--) {
      final j = secureRandom.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }

    return result.take(options.length).join();
  }

  /// Generates a human-friendly diceware passphrase
  static String generatePassphrase(PassphraseOptions options) {
    final Random secureRandom = Random.secure();
    final List<String> selectedWords = [];

    for (int i = 0; i < options.wordCount; i++) {
      String word = _dicewareWords[secureRandom.nextInt(_dicewareWords.length)];
      if (options.capitalize) {
        word = word[0].toUpperCase() + word.substring(1);
      }
      selectedWords.add(word);
    }

    if (options.includeNumber) {
      final num = secureRandom.nextInt(100);
      final insertIndex = secureRandom.nextInt(selectedWords.length);
      selectedWords[insertIndex] = '${selectedWords[insertIndex]}$num';
    }

    return selectedWords.join(options.separator);
  }
}
