import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import '../../core/constants/crypto_constants.dart';
import '../../core/crypto/key_derivation_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/user_profile.dart';

enum AuthStatus {
  uninitialized, // First launch: no master password set
  locked,        // Master password exists, vault is locked
  unlocked,      // Vault is decrypted and unlocked
}

class AuthState extends ChangeNotifier {
  final StorageService storageService;
  StorageService get _storageService => storageService;
  final KeyDerivationService _keyDerivation = KeyDerivationService();
  final BiometricService _biometricService = BiometricService();

  AuthStatus _status = AuthStatus.uninitialized;
  SecretKey? _activeKey;
  UserProfile _userProfile = UserProfile(createdAt: DateTime.now());
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;

  AuthStatus get status => _status;
  bool get isUnlocked => _status == AuthStatus.unlocked;
  bool get isLocked => _status == AuthStatus.locked;
  bool get isUninitialized => _status == AuthStatus.uninitialized;
  SecretKey? get activeKey => _activeKey;
  UserProfile get userProfile => _userProfile;
  bool get biometricsAvailable => _biometricsAvailable;
  bool get biometricsEnabled => _biometricsEnabled;

  AuthState({required this.storageService});

  Future<void> initialize() async {
    _userProfile = await storageService.getUserProfile();
    final masterHash = await storageService.getMasterHash();
    _biometricsAvailable = await _biometricService.isDeviceSupported();
    _biometricsEnabled = await storageService.isBiometricsEnabled();

    if (masterHash == null || masterHash.isEmpty) {
      _status = AuthStatus.uninitialized;
    } else {
      _status = AuthStatus.locked;
    }
    notifyListeners();
  }

  /// Sets up a new Master Password during initial onboarding
  Future<SecretKey> setupMasterPassword({
    required String password,
    String? displayName,
  }) async {
    final salt = _keyDerivation.generateRandomBytes(CryptoConstants.saltLengthBytes);
    final key = await _keyDerivation.deriveKey(
      password: password,
      salt: salt,
    );

    final hash = await _keyDerivation.calculateMasterHash(
      password: password,
      salt: salt,
    );

    await _storageService.saveMasterSalt(salt);
    await _storageService.saveMasterHash(hash);

    if (displayName != null && displayName.trim().isNotEmpty) {
      _userProfile = _userProfile.copyWith(displayName: displayName.trim());
      await _storageService.saveUserProfile(_userProfile);
    }

    _activeKey = key;
    _status = AuthStatus.unlocked;
    notifyListeners();
    return key;
  }

  /// Unlocks vault using Master Password
  Future<SecretKey> unlockWithPassword(String password) async {
    final salt = await _storageService.getMasterSalt();
    final storedHash = await _storageService.getMasterHash();

    if (salt == null || storedHash == null) {
      throw Exception('Vault is not properly configured.');
    }

    final computedHash = await _keyDerivation.calculateMasterHash(
      password: password,
      salt: salt,
    );

    if (computedHash != storedHash) {
      throw Exception('Incorrect master password.');
    }

    final key = await _keyDerivation.deriveKey(
      password: password,
      salt: salt,
    );

    _activeKey = key;
    _status = AuthStatus.unlocked;
    _userProfile = _userProfile.copyWith(lastLoginAt: DateTime.now());
    await _storageService.saveUserProfile(_userProfile);

    if (_biometricsEnabled) {
      final keyBytes = await key.extractBytes();
      await _storageService.saveBiometricKey(keyBytes);
    }

    notifyListeners();
    return key;
  }

  /// Changes master password, re-derives key and updates stored verifiers
  Future<SecretKey> changeMasterPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // Verify old password first
    await unlockWithPassword(oldPassword);

    final newSalt = _keyDerivation.generateRandomBytes(CryptoConstants.saltLengthBytes);
    final newKey = await _keyDerivation.deriveKey(
      password: newPassword,
      salt: newSalt,
    );

    final newHash = await _keyDerivation.calculateMasterHash(
      password: newPassword,
      salt: newSalt,
    );

    await _storageService.saveMasterSalt(newSalt);
    await _storageService.saveMasterHash(newHash);

    _activeKey = newKey;
    if (_biometricsEnabled) {
      final keyBytes = await newKey.extractBytes();
      await _storageService.saveBiometricKey(keyBytes);
    }
    notifyListeners();
    return newKey;
  }

  /// Toggles biometric unlock preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    _biometricsEnabled = enabled;
    await _storageService.setBiometricsEnabled(enabled);
    if (enabled) {
      if (_activeKey != null) {
        final keyBytes = await _activeKey!.extractBytes();
        await _storageService.saveBiometricKey(keyBytes);
      }
    } else {
      await _storageService.deleteBiometricKey();
    }
    notifyListeners();
  }

  /// Authenticate and unlock vault with Biometrics
  Future<SecretKey?> unlockWithBiometrics() async {
    if (!_biometricsAvailable || !_biometricsEnabled) return null;
    final authed = await _biometricService.authenticate(reason: 'Unlock your Vault');
    if (!authed) return null;

    final keyBytes = await _storageService.getBiometricKey();
    if (keyBytes == null || keyBytes.isEmpty) return null;

    final key = SecretKey(keyBytes);
    _activeKey = key;
    _status = AuthStatus.unlocked;
    _userProfile = _userProfile.copyWith(lastLoginAt: DateTime.now());
    await _storageService.saveUserProfile(_userProfile);

    notifyListeners();
    return key;
  }

  /// Updates local display name
  Future<void> updateDisplayName(String name) async {
    _userProfile = _userProfile.copyWith(displayName: name.trim());
    await _storageService.saveUserProfile(_userProfile);
    notifyListeners();
  }

  /// Locks the vault and wipes the active decryption key from memory
  void lock() {
    _activeKey = null;
    _status = AuthStatus.locked;
    notifyListeners();
  }
}
