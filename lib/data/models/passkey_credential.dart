import 'package:uuid/uuid.dart';

enum PasskeyAlgorithm {
  es256('ES256', -7),
  rs256('RS256', -257),
  ed25519('Ed25519', -8);

  final String label;
  final int coseValue;
  const PasskeyAlgorithm(this.label, this.coseValue);

  static PasskeyAlgorithm fromString(String? val) {
    if (val == null) return PasskeyAlgorithm.es256;
    return PasskeyAlgorithm.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => PasskeyAlgorithm.es256,
    );
  }
}

enum AuthenticatorAttachment {
  platform('Platform (Device)'),
  crossPlatform('Cross-Platform (Security Key)');

  final String label;
  const AuthenticatorAttachment(this.label);

  static AuthenticatorAttachment fromString(String? val) {
    if (val == null) return AuthenticatorAttachment.platform;
    return AuthenticatorAttachment.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AuthenticatorAttachment.platform,
    );
  }
}

class PasskeyCredential {
  final String id;
  final String rpId; // e.g. "github.com"
  final String rpName; // e.g. "GitHub"
  final String userName; // e.g. "user@example.com"
  final String? userHandle; // Base64 or Hex user handle
  final String credentialId; // Base64 credential identifier
  final PasskeyAlgorithm algorithm;
  final AuthenticatorAttachment authenticatorAttachment;
  final List<String> transports; // internal, usb, nfc, ble, hybrid
  final bool backupEligible;
  final bool backupState;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  PasskeyCredential({
    String? id,
    required this.rpId,
    required this.rpName,
    required this.userName,
    this.userHandle,
    required this.credentialId,
    this.algorithm = PasskeyAlgorithm.es256,
    this.authenticatorAttachment = AuthenticatorAttachment.platform,
    this.transports = const ['internal', 'hybrid'],
    this.backupEligible = true,
    this.backupState = true,
    DateTime? createdAt,
    this.lastUsedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  PasskeyCredential copyWith({
    String? id,
    String? rpId,
    String? rpName,
    String? userName,
    String? userHandle,
    String? credentialId,
    PasskeyAlgorithm? algorithm,
    AuthenticatorAttachment? authenticatorAttachment,
    List<String>? transports,
    bool? backupEligible,
    bool? backupState,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return PasskeyCredential(
      id: id ?? this.id,
      rpId: rpId ?? this.rpId,
      rpName: rpName ?? this.rpName,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      credentialId: credentialId ?? this.credentialId,
      algorithm: algorithm ?? this.algorithm,
      authenticatorAttachment: authenticatorAttachment ?? this.authenticatorAttachment,
      transports: transports ?? this.transports,
      backupEligible: backupEligible ?? this.backupEligible,
      backupState: backupState ?? this.backupState,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rpId': rpId,
    'rpName': rpName,
    'userName': userName,
    'userHandle': userHandle,
    'credentialId': credentialId,
    'algorithm': algorithm.name,
    'authenticatorAttachment': authenticatorAttachment.name,
    'transports': transports,
    'backupEligible': backupEligible,
    'backupState': backupState,
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt?.toIso8601String(),
  };

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) => PasskeyCredential(
    id: json['id'] as String?,
    rpId: json['rpId'] as String? ?? '',
    rpName: json['rpName'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    userHandle: json['userHandle'] as String?,
    credentialId: json['credentialId'] as String? ?? '',
    algorithm: PasskeyAlgorithm.fromString(json['algorithm'] as String?),
    authenticatorAttachment: AuthenticatorAttachment.fromString(json['authenticatorAttachment'] as String?),
    transports: (json['transports'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['internal', 'hybrid'],
    backupEligible: json['backupEligible'] as bool? ?? true,
    backupState: json['backupState'] as bool? ?? true,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    lastUsedAt: json['lastUsedAt'] != null ? DateTime.tryParse(json['lastUsedAt'] as String) : null,
  );
}
