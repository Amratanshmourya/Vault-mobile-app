enum SecurityEventType {
  vaultUnlocked('Vault Unlocked', '🔓'),
  biometricUnlocked('Biometric Authentication', '👆'),
  vaultLocked('Vault Locked', '🔒'),
  masterPasswordChanged('Master Password Changed', '🔑'),
  backupCreated('Backup Created', '💾'),
  backupRestored('Backup Restored', '📥'),
  itemCreated('Item Created', '➕'),
  itemUpdated('Item Updated', '✏️'),
  itemDeleted('Item Deleted', '🗑️'),
  itemRestored('Item Restored', '♻️'),
  securityAlert('Security Alert', '⚠️'),
  securityAuditRun('Security Audit Run', '🛡️');

  final String title;
  final String icon;
  const SecurityEventType(this.title, this.icon);
}

class SecurityEvent {
  final String id;
  final SecurityEventType type;
  final String description;
  final DateTime timestamp;

  const SecurityEvent({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'vaultUnlocked';
    final eventType = SecurityEventType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => SecurityEventType.vaultUnlocked,
    );

    return SecurityEvent(
      id: json['id'] as String? ?? '',
      type: eventType,
      description: json['description'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
