import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/security_event.dart';

class StorageService {
  SharedPreferences? _prefs;
  static const String _keyBiometricVaultKey = 'vault_biometric_key';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Master Salt
  Future<Uint8List?> getMasterSalt() async {
    final prefs = await _getPrefs();
    final saltStr = prefs.getString(AppConstants.keyMasterSalt);
    if (saltStr != null) {
      return base64Decode(saltStr);
    }
    return null;
  }

  Future<void> saveMasterSalt(Uint8List salt) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyMasterSalt, base64Encode(salt));
  }

  // Master Hash Verifier
  Future<String?> getMasterHash() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyMasterPasswordHash);
  }

  Future<void> saveMasterHash(String hash) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyMasterPasswordHash, hash);
  }

  // Encrypted Vault Payload
  Future<String?> getEncryptedVaultData() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyVaultDataEncrypted);
  }

  Future<void> saveEncryptedVaultData(String encryptedPayloadJson) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyVaultDataEncrypted, encryptedPayloadJson);
  }

  // User Profile
  Future<UserProfile> getUserProfile() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(AppConstants.keyProfileName);
    if (raw != null) {
      try {
        return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return UserProfile(
      displayName: AppConstants.defaultProfileName,
      createdAt: DateTime.now(),
    );
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyProfileName, jsonEncode(profile.toJson()));
  }

  // Biometrics enabled
  Future<bool> isBiometricsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(AppConstants.keyBiometricsEnabled) ?? false;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(AppConstants.keyBiometricsEnabled, enabled);
  }

  // Auto-lock duration
  Future<int> getAutoLockSeconds() async {
    final prefs = await _getPrefs();
    return prefs.getInt(AppConstants.keyAutoLockDuration) ?? AutoLockTimeout.fiveMinutes.seconds;
  }

  Future<void> setAutoLockSeconds(int seconds) async {
    final prefs = await _getPrefs();
    await prefs.setInt(AppConstants.keyAutoLockDuration, seconds);
  }

  // Clipboard timeout
  Future<int> getClipboardTimeoutSeconds() async {
    final prefs = await _getPrefs();
    return prefs.getInt(AppConstants.keyClipboardTimeout) ?? ClipboardTimeoutOption.thirtySeconds.seconds;
  }

  Future<void> setClipboardTimeoutSeconds(int seconds) async {
    final prefs = await _getPrefs();
    await prefs.setInt(AppConstants.keyClipboardTimeout, seconds);
  }

  // Password history setting
  Future<bool> isPasswordHistoryEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(AppConstants.keyPasswordHistoryEnabled) ?? true;
  }

  Future<void> setPasswordHistoryEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(AppConstants.keyPasswordHistoryEnabled, enabled);
  }

  // Trash retention
  Future<int> getTrashRetentionDays() async {
    final prefs = await _getPrefs();
    return prefs.getInt(AppConstants.keyTrashAutoDeleteDays) ?? TrashRetentionDays.thirtyDays.days;
  }

  Future<void> setTrashRetentionDays(int days) async {
    final prefs = await _getPrefs();
    await prefs.setInt(AppConstants.keyTrashAutoDeleteDays, days);
  }

  // Biometric Secure Key Storage (Hardware-backed encrypted storage)
  Future<void> saveBiometricKey(List<int> keyBytes) async {
    await _secureStorage.write(
      key: _keyBiometricVaultKey,
      value: base64Encode(keyBytes),
    );
  }

  Future<List<int>?> getBiometricKey() async {
    try {
      final value = await _secureStorage.read(key: _keyBiometricVaultKey);
      if (value != null && value.isNotEmpty) {
        return base64Decode(value);
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteBiometricKey() async {
    try {
      await _secureStorage.delete(key: _keyBiometricVaultKey);
    } catch (_) {}
  }

  // Security Events Log
  Future<List<SecurityEvent>> getSecurityEvents() async {
    final prefs = await _getPrefs();
    final raw = prefs.getStringList(AppConstants.keySecurityEvents);
    if (raw == null) return [];
    final List<SecurityEvent> list = [];
    for (final jsonStr in raw) {
      try {
        list.add(SecurityEvent.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
      } catch (_) {}
    }
    return list;
  }

  Future<void> saveSecurityEvents(List<SecurityEvent> events) async {
    final prefs = await _getPrefs();
    final stringList = events.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(AppConstants.keySecurityEvents, stringList);
  }

  // Backup History
  Future<List<String>> getBackupHistory() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(AppConstants.keyBackupHistory) ?? [];
  }

  Future<void> saveBackupHistory(List<String> history) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(AppConstants.keyBackupHistory, history);
  }

  // Sort Option
  Future<SortOption> getSortOption() async {
    final prefs = await _getPrefs();
    final index = prefs.getInt(AppConstants.keySortOption);
    if (index != null && index >= 0 && index < SortOption.values.length) {
      return SortOption.values[index];
    }
    return SortOption.nameAsc;
  }

  Future<void> saveSortOption(SortOption option) async {
    final prefs = await _getPrefs();
    await prefs.setInt(AppConstants.keySortOption, option.index);
  }

  // Clear all vault data (e.g. factory reset)
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    await deleteBiometricKey();
  }
}
