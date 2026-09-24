import 'package:uuid/uuid.dart';

class VaultDescriptor {
  final String id;
  final String name;
  final String icon; // emoji or icon code name
  final String colorHex;
  final String? description;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int itemCount;

  const VaultDescriptor({
    required this.id,
    required this.name,
    this.icon = '🛡️',
    this.colorHex = '#1A80E5',
    this.description,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount = 0,
  });

  factory VaultDescriptor.createDefault() {
    final now = DateTime.now();
    return VaultDescriptor(
      id: 'default_vault',
      name: 'Primary Vault',
      icon: '🔐',
      colorHex: '#1A80E5',
      description: 'Your default offline personal vault',
      isDefault: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory VaultDescriptor.create({
    required String name,
    String icon = '🛡️',
    String colorHex = '#1A80E5',
    String? description,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return VaultDescriptor(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      colorHex: colorHex,
      description: description,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  VaultDescriptor copyWith({
    String? id,
    String? name,
    String? icon,
    String? colorHex,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
  }) {
    return VaultDescriptor(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      itemCount: itemCount ?? this.itemCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'colorHex': colorHex,
    'description': description,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'itemCount': itemCount,
  };

  factory VaultDescriptor.fromJson(Map<String, dynamic> json) => VaultDescriptor(
    id: json['id'] as String? ?? 'default_vault',
    name: json['name'] as String? ?? 'Primary Vault',
    icon: json['icon'] as String? ?? '🛡️',
    colorHex: json['colorHex'] as String? ?? '#1A80E5',
    description: json['description'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    itemCount: json['itemCount'] as int? ?? 0,
  );
}
