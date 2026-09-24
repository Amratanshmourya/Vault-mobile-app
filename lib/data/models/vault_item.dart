import 'package:uuid/uuid.dart';
import '../../core/crypto/password_strength.dart';
import 'encrypted_file_attachment.dart';
import 'passkey_credential.dart';

enum VaultItemType {
  login('Login', '🔑'),
  passkey('Passkey', '🛡️'),
  password('Password', '🔐'),
  card('Card', '💳'),
  identity('Identity', '🪪'),
  note('Secure Note', '📝'),
  file('Secure File', '📎'),
  recoveryCode('Recovery Codes', '🛡️'),
  license('License', '📜');

  final String label;
  final String icon;
  const VaultItemType(this.label, this.icon);
}

enum CustomFieldType {
  text('Text', '🔤'),
  secret('Concealed / Secret', '🔒'),
  url('Website / URL', '🌐'),
  email('Email Address', '✉️'),
  username('Username', '👤'),
  password('Password', '🔑'),
  number('Number', '🔢'),
  date('Date', '📅'),
  multiline('Multi-line Note', '📄'),
  boolean('Toggle (Yes/No)', '🔘');

  final String label;
  final String icon;
  const CustomFieldType(this.label, this.icon);

  static CustomFieldType fromString(String? val) {
    if (val == null) return CustomFieldType.text;
    return CustomFieldType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => CustomFieldType.text,
    );
  }
}

class CustomField {
  final String id;
  final String label;
  final String value;
  final CustomFieldType type;
  final bool isConcealed;

  CustomField({
    String? id,
    required this.label,
    required this.value,
    CustomFieldType? type,
    bool? isConcealed,
  })  : id = id ?? const Uuid().v4(),
        type = type ?? (isConcealed == true ? CustomFieldType.secret : CustomFieldType.text),
        isConcealed = isConcealed ?? (type == CustomFieldType.secret || type == CustomFieldType.password);

  CustomField copyWith({
    String? id,
    String? label,
    String? value,
    CustomFieldType? type,
    bool? isConcealed,
  }) {
    return CustomField(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      type: type ?? this.type,
      isConcealed: isConcealed ?? this.isConcealed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'type': type.name,
    'isConcealed': isConcealed,
  };

  factory CustomField.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final concealed = json['isConcealed'] as bool? ?? false;
    final type = typeStr != null
        ? CustomFieldType.fromString(typeStr)
        : (concealed ? CustomFieldType.secret : CustomFieldType.text);

    return CustomField(
      id: json['id'] as String?,
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: type,
      isConcealed: concealed || type == CustomFieldType.secret || type == CustomFieldType.password,
    );
  }
}

class PasswordHistoryEntry {
  final String password;
  final DateTime recordedAt;

  PasswordHistoryEntry({
    required this.password,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'password': password,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory PasswordHistoryEntry.fromJson(Map<String, dynamic> json) => PasswordHistoryEntry(
    password: json['password'] as String? ?? '',
    recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class RecoveryCodeEntry {
  final String code;
  final bool isUsed;

  const RecoveryCodeEntry({
    required this.code,
    this.isUsed = false,
  });

  RecoveryCodeEntry copyWith({
    String? code,
    bool? isUsed,
  }) {
    return RecoveryCodeEntry(
      code: code ?? this.code,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'isUsed': isUsed,
  };

  factory RecoveryCodeEntry.fromJson(Map<String, dynamic> json) => RecoveryCodeEntry(
    code: json['code'] as String? ?? '',
    isUsed: json['isUsed'] as bool? ?? false,
  );
}

class VaultItem {
  final String id;
  final VaultItemType type;
  final String title;
  final String? folder;
  final bool isFavorite;
  final List<String> tags;
  final String? notes;

  // Login & Standalone Password fields
  final String? username;
  final String? password;
  final String? website;
  final String? totpSecret;
  final DateTime? passwordUpdatedAt;
  final List<PasswordHistoryEntry> passwordHistory;

  // Passkey fields (V3)
  final PasskeyCredential? passkey;

  // Payment Card fields
  final String? cardholderName;
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvv;
  final String? pin;

  // Identity fields
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? dateOfBirth;

  // Secure Note content
  final String? noteContent;

  // License fields
  final String? licenseKey;
  final String? licensedTo;
  final String? licenseExpiry;

  // Recovery Codes list
  final List<RecoveryCodeEntry> recoveryCodes;

  // Encrypted File Attachments
  final List<EncryptedFileAttachment> attachments;

  // Custom fields
  final List<CustomField> customFields;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  VaultItem({
    String? id,
    required this.type,
    required this.title,
    this.folder,
    this.isFavorite = false,
    this.tags = const [],
    this.notes,
    this.username,
    this.password,
    this.website,
    this.totpSecret,
    this.passwordUpdatedAt,
    this.passwordHistory = const [],
    this.passkey,
    this.cardholderName,
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
    this.pin,
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.noteContent,
    this.licenseKey,
    this.licensedTo,
    this.licenseExpiry,
    this.recoveryCodes = const [],
    this.attachments = const [],
    this.customFields = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastUsedAt,
    this.isDeleted = false,
    this.deletedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Normalized domain extracted from website URL for strict matching
  String? get normalizedDomain {
    final targetUrl = website ?? passkey?.rpId;
    if (targetUrl == null || targetUrl.trim().isEmpty) return null;
    try {
      String url = targetUrl.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return null;
    }
  }

  /// Password strength evaluation result
  PasswordStrengthResult get passwordStrength => PasswordStrength.evaluate(password ?? '');

  /// Checks if this item has an active passkey or is a standalone passkey
  bool get hasPasskey => type == VaultItemType.passkey || passkey != null;

  VaultItem copyWith({
    String? id,
    VaultItemType? type,
    String? title,
    String? folder,
    bool? isFavorite,
    List<String>? tags,
    String? notes,
    String? username,
    String? password,
    String? website,
    String? totpSecret,
    DateTime? passwordUpdatedAt,
    List<PasswordHistoryEntry>? passwordHistory,
    PasskeyCredential? passkey,
    String? cardholderName,
    String? cardNumber,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    String? pin,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? dateOfBirth,
    String? noteContent,
    String? licenseKey,
    String? licensedTo,
    String? licenseExpiry,
    List<RecoveryCodeEntry>? recoveryCodes,
    List<EncryptedFileAttachment>? attachments,
    List<CustomField>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return VaultItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      folder: folder ?? this.folder,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      totpSecret: totpSecret ?? this.totpSecret,
      passwordUpdatedAt: passwordUpdatedAt ?? this.passwordUpdatedAt,
      passwordHistory: passwordHistory ?? this.passwordHistory,
      passkey: passkey ?? this.passkey,
      cardholderName: cardholderName ?? this.cardholderName,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
      pin: pin ?? this.pin,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      noteContent: noteContent ?? this.noteContent,
      licenseKey: licenseKey ?? this.licenseKey,
      licensedTo: licensedTo ?? this.licensedTo,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      recoveryCodes: recoveryCodes ?? this.recoveryCodes,
      attachments: attachments ?? this.attachments,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'folder': folder,
    'isFavorite': isFavorite,
    'tags': tags,
    'notes': notes,
    'username': username,
    'password': password,
    'website': website,
    'totpSecret': totpSecret,
    'passwordUpdatedAt': passwordUpdatedAt?.toIso8601String(),
    'passwordHistory': passwordHistory.map((e) => e.toJson()).toList(),
    'passkey': passkey?.toJson(),
    'cardholderName': cardholderName,
    'cardNumber': cardNumber,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'cvv': cvv,
    'pin': pin,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'address': address,
    'dateOfBirth': dateOfBirth,
    'noteContent': noteContent,
    'licenseKey': licenseKey,
    'licensedTo': licensedTo,
    'licenseExpiry': licenseExpiry,
    'recoveryCodes': recoveryCodes.map((e) => e.toJson()).toList(),
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'customFields': customFields.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'isDeleted': isDeleted,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory VaultItem.fromJson(Map<String, dynamic> json) => VaultItem(
    id: json['id'] as String?,
    type: VaultItemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => VaultItemType.login,
    ),
    title: json['title'] as String? ?? '',
    folder: json['folder'] as String?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    notes: json['notes'] as String?,
    username: json['username'] as String?,
    password: json['password'] as String?,
    website: json['website'] as String?,
    totpSecret: json['totpSecret'] as String?,
    passwordUpdatedAt: json['passwordUpdatedAt'] != null
        ? DateTime.tryParse(json['passwordUpdatedAt'] as String)
        : null,
    passwordHistory: (json['passwordHistory'] as List<dynamic>?)
            ?.map((e) => PasswordHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    passkey: json['passkey'] != null
        ? PasskeyCredential.fromJson(json['passkey'] as Map<String, dynamic>)
        : null,
    cardholderName: json['cardholderName'] as String?,
    cardNumber: json['cardNumber'] as String?,
    expiryMonth: json['expiryMonth'] as String?,
    expiryYear: json['expiryYear'] as String?,
    cvv: json['cvv'] as String?,
    pin: json['pin'] as String?,
    fullName: json['fullName'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    dateOfBirth: json['dateOfBirth'] as String?,
    noteContent: json['noteContent'] as String?,
    licenseKey: json['licenseKey'] as String?,
    licensedTo: json['licensedTo'] as String?,
    licenseExpiry: json['licenseExpiry'] as String?,
    recoveryCodes: (json['recoveryCodes'] as List<dynamic>?)
            ?.map((e) => RecoveryCodeEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    attachments: (json['attachments'] as List<dynamic>?)
            ?.map((e) => EncryptedFileAttachment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    customFields: (json['customFields'] as List<dynamic>?)
            ?.map((e) => CustomField.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    lastUsedAt: json['lastUsedAt'] != null ? DateTime.tryParse(json['lastUsedAt'] as String) : null,
    isDeleted: json['isDeleted'] as bool? ?? false,
    deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'] as String) : null,
  );
}
