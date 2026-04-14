class Badge {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;

  Badge({required this.id, required this.name, this.description, this.iconUrl});

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
    };
  }

  @override
  String toString() => 'Badge(id: $id, name: $name)';
}
