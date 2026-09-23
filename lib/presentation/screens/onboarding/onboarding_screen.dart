import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/crypto/password_strength.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/security/strength_indicator_bar.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController(text: AppConstants.defaultProfileName);

  PasswordStrengthResult _strength = const PasswordStrengthResult(
    score: 0,
    level: PasswordStrengthLevel.veryWeak,
    warnings: [],
    suggestions: [],
    entropyBits: 0,
  );

  bool _isCreating = false;
  String? _passwordError;

  @override
  void dispose() {
    _pageController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String val) {
    setState(() {
      _strength = PasswordStrength.evaluate(val);
      _passwordError = null;
    });
  }

  Future<void> _completeSetup() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter a master password');
      return;
    }
    if (password.length < 8) {
      setState(() => _passwordError = 'Master password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final authState = context.read<AuthState>();
      final vaultState = context.read<VaultState>();

      final key = await authState.setupMasterPassword(
        password: password,
        displayName: _nameController.text.trim(),
      );

      await vaultState.loadVault(key);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize vault: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.lightBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildPage1(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Vault',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'Your sensitive passwords and credentials stay on this device. 100% offline-first and encrypted.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(170),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_open_rounded, size: 64, color: AppColors.secondary),
          ),
          const SizedBox(height: 32),
          Text(
            'True Privacy',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'No account. No cloud servers. No telemetry. No trackers.\n\nYou have total ownership over your data and backups.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(170),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Create Master Password',
            style: AppTypography.displayMedium.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'This unlocks your encrypted vault. It is never stored or sent anywhere.',
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _nameController,
            label: 'Your Name (Local Display Only)',
            hintText: 'e.g. Amratansh',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Master Password',
            hintText: 'Enter a strong master password',
            isPassword: true,
            onChanged: _onPasswordChanged,
            prefixIcon: const Icon(Icons.key_outlined, size: 20),
          ),
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            StrengthIndicatorBar(strength: _strength),
          ],
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmController,
            label: 'Confirm Master Password',
            hintText: 'Re-enter your master password',
            isPassword: true,
            prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
          ),
          if (_passwordError != null) ...[
            const SizedBox(height: 12),
            Text(
              _passwordError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPage1(theme),
                  _buildPage2(theme),
                  _buildPage3(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: _currentPage < 2
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            _pageController.animateToPage(
                              2,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(130, 48),
                          ),
                          child: const Text('Next'),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _isCreating ? null : _completeSetup,
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create My Vault'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
