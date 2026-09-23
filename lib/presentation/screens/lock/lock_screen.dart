import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../state/auth_state.dart';
import '../../state/vault_state.dart';
import '../../widgets/common/custom_text_field.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricUnlock() async {
    if (_isAuthenticating) return;
    final authState = context.read<AuthState>();
    final vaultState = context.read<VaultState>();
    if (authState.biometricsEnabled && authState.biometricsAvailable) {
      setState(() {
        _isAuthenticating = true;
        _errorMessage = null;
      });
      try {
        final key = await authState.unlockWithBiometrics();
        if (key != null && mounted) {
          await vaultState.loadVault(key);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Biometric authentication failed. Please enter master password.';
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isAuthenticating = false);
        }
      }
    }
  }

  Future<void> _unlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your master password');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthState>();
      final vaultState = context.read<VaultState>();

      final key = await authState.unlockWithPassword(password);
      await vaultState.loadVault(key);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Incorrect master password. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthState>();
    final userName = authState.userProfile.displayName;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Vault Locked',
                    style: AppTypography.displayMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome back, $userName',
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Enter Master Password',
                    isPassword: true,
                    autofocus: true,
                    prefixIcon: const Icon(Icons.key_outlined, size: 20),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isAuthenticating ? null : _unlock,
                    child: _isAuthenticating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Unlock Vault'),
                  ),
                  if (authState.biometricsAvailable && authState.biometricsEnabled) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isAuthenticating ? null : _tryBiometricUnlock,
                      icon: const Icon(Icons.fingerprint_rounded, size: 20),
                      label: const Text('Use Biometrics'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
