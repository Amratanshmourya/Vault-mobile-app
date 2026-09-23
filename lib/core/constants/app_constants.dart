class AppConstants {
  static const String appName = 'Vault';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Private by design. Works completely offline.';
  static const String defaultProfileName = 'Amratansh';

  // Storage Keys
  static const String keyProfileName = 'vault_profile_name';
  static const String keyMasterPasswordHash = 'vault_master_pw_hash';
  static const String keyMasterSalt = 'vault_master_salt';
  static const String keyVaultDataEncrypted = 'vault_data_encrypted';
  static const String keyBiometricsEnabled = 'vault_biometrics_enabled';
  static const String keyAutoLockDuration = 'vault_auto_lock_duration';
  static const String keyClipboardTimeout = 'vault_clipboard_timeout';
  static const String keyThemeMode = 'vault_theme_mode';
  static const String keyPasswordHistoryEnabled = 'vault_pw_history_enabled';
  static const String keyTrashAutoDeleteDays = 'vault_trash_auto_delete_days';
  static const String keyHideAppPreview = 'vault_hide_app_preview';
  static const String keyDefaultFolder = 'vault_default_folder';
  static const String keySecurityEvents = 'vault_security_events';
  static const String keyBackupHistory = 'vault_backup_history';
  static const String keySortOption = 'vault_sort_option';
}

enum SortOption {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  updatedDesc('Recently Updated'),
  createdDesc('Date Created'),
  mostUsedDesc('Most Used'),
  strengthAsc('Password Strength');

  final String label;
  const SortOption(this.label);
}

enum ThemeType {
  system,
  light,
  dark,
  amoled,
}

enum AutoLockTimeout {
  immediately(0, 'Immediately'),
  oneMinute(60, '1 minute'),
  fiveMinutes(300, '5 minutes'),
  fifteenMinutes(900, '15 minutes'),
  thirtyMinutes(1800, '30 minutes'),
  never(-1, 'Never');

  final int seconds;
  final String label;
  const AutoLockTimeout(this.seconds, this.label);
}

enum ClipboardTimeoutOption {
  fifteenSeconds(15, '15 seconds'),
  thirtySeconds(30, '30 seconds'),
  sixtySeconds(60, '60 seconds'),
  never(-1, 'Never');

  final int seconds;
  final String label;
  const ClipboardTimeoutOption(this.seconds, this.label);
}

enum TrashRetentionDays {
  never(0, 'Never'),
  sevenDays(7, '7 days'),
  thirtyDays(30, '30 days'),
  ninetyDays(90, '90 days');

  final int days;
  final String label;
  const TrashRetentionDays(this.days, this.label);
}
