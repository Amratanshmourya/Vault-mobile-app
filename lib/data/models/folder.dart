class Folder {
  final String id;
  final String name;
  final String? icon;

  const Folder({
    required this.id,
    required this.name,
    this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
  };

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String?,
  );
}
