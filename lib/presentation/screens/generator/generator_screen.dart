import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/crypto/password_generator.dart';
import '../../../core/crypto/password_strength.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/vault_item.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/vault_card.dart';
import '../../widgets/security/strength_indicator_bar.dart';
import '../item_editor/item_editor_screen.dart';

enum GeneratorMode {
  randomPassword,
  passphrase,
}

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  GeneratorMode _mode = GeneratorMode.randomPassword;

  // Random Password settings
  int _length = 18;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _avoidAmbiguous = false;

  // Passphrase settings
  int _wordCount = 4;
  final String _separator = '-';
  bool _capitalize = true;
  bool _includeNumberInPassphrase = true;

  String _generated = '';
  PasswordStrengthResult _strength = const PasswordStrengthResult(
    score: 0,
    level: PasswordStrengthLevel.veryWeak,
    warnings: [],
    suggestions: [],
    entropyBits: 0,
  );

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    if (_mode == GeneratorMode.randomPassword) {
      _generated = PasswordGenerator.generatePassword(
        PasswordGeneratorOptions(
          length: _length,
          includeUppercase: _includeUppercase,
          includeLowercase: _includeLowercase,
          includeNumbers: _includeNumbers,
          includeSymbols: _includeSymbols,
          avoidAmbiguous: _avoidAmbiguous,
        ),
      );
    } else {
      _generated = PasswordGenerator.generatePassphrase(
        PassphraseOptions(
          wordCount: _wordCount,
          separator: _separator,
          capitalize: _capitalize,
          includeNumber: _includeNumberInPassphrase,
        ),
      );
    }

    setState(() {
      _strength = PasswordStrength.evaluate(_generated);
    });
  }

  void _copy() async {
    final vaultState = context.read<VaultState>();
    final msg = await vaultState.clipboardService.copyWithAutoClear(
      text: _generated,
      itemLabel: 'Generated password',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveToVault() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemEditorScreen(
          initialType: VaultItemType.password,
          initialItem: VaultItem(
            type: VaultItemType.password,
            title: 'Generated Password',
            password: _generated,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generated Result Card
            VaultCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GENERATED VALUE',
                        style: AppTypography.caption.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.primary),
                        tooltip: 'Regenerate',
                        onPressed: _regenerate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _generated,
                    style: AppTypography.monospace.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StrengthIndicatorBar(strength: _strength),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveToVault,
                          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                          label: const Text('Save to Vault'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mode Toggle (Random vs Passphrase)
            SegmentedButton<GeneratorMode>(
              segments: const [
                ButtonSegment(
                  value: GeneratorMode.randomPassword,
                  label: Text('Random Password'),
                  icon: Icon(Icons.password_rounded, size: 18),
                ),
                ButtonSegment(
                  value: GeneratorMode.passphrase,
                  label: Text('Passphrase'),
                  icon: Icon(Icons.text_fields_rounded, size: 18),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (set) {
                setState(() {
                  _mode = set.first;
                  _regenerate();
                });
              },
            ),
            const SizedBox(height: 20),

            // Random Password Controls
            if (_mode == GeneratorMode.randomPassword) ...[
              VaultCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Length', style: AppTypography.titleSmall),
                        Text('$_length', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: _length.toDouble(),
                      min: 8,
                      max: 48,
                      divisions: 40,
                      label: '$_length',
                      onChanged: (val) {
                        setState(() {
                          _length = val.round();
                          _regenerate();
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Uppercase (A-Z)'),
                      value: _includeUppercase,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (!val && !_includeLowercase && !_includeNumbers && !_includeSymbols) return;
                        setState(() {
                          _includeUppercase = val;
                          _regenerate();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Lowercase (a-z)'),
                      value: _includeLowercase,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (!val && !_includeUppercase && !_includeNumbers && !_includeSymbols) return;
                        setState(() {
                          _includeLowercase = val;
                          _regenerate();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Numbers (0-9)'),
                      value: _includeNumbers,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (!val && !_includeUppercase && !_includeLowercase && !_includeSymbols) return;
                        setState(() {
                          _includeNumbers = val;
                          _regenerate();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Symbols (!@#\$)'),
                      value: _includeSymbols,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (!val && !_includeUppercase && !_includeLowercase && !_includeNumbers) return;
                        setState(() {
                          _includeSymbols = val;
                          _regenerate();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Avoid Ambiguous (1, l, I, 0, O)'),
                      value: _avoidAmbiguous,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          _avoidAmbiguous = val;
                          _regenerate();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Passphrase Controls
              VaultCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Words Count', style: AppTypography.titleSmall),
                        Text('$_wordCount', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: _wordCount.toDouble(),
                      min: 3,
                      max: 8,
                      divisions: 5,
                      label: '$_wordCount',
                      onChanged: (val) {
                        setState(() {
                          _wordCount = val.round();
                          _regenerate();
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Capitalize Words'),
                      value: _capitalize,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          _capitalize = val;
                          _regenerate();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Include Number'),
                      value: _includeNumberInPassphrase,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          _includeNumberInPassphrase = val;
                          _regenerate();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
