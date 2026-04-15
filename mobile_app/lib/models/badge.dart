class Badge {
  final String id;
  final String? code;
  final String name;
  final String? description;
  final String? iconUrl;
  final int pointsReward;
  final DateTime? awardedAt;

  Badge({
    required this.id,
    this.code,
    required this.name,
    this.description,
    this.iconUrl,
    this.pointsReward = 0,
    this.awardedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    final badgeJson = json['badge'] is Map<String, dynamic>
        ? json['badge'] as Map<String, dynamic>
        : json;
    return Badge(
      id: badgeJson['id'] as String,
      code: badgeJson['code'] as String?,
      name: badgeJson['name'] as String,
      description: badgeJson['description'] as String?,
      iconUrl: badgeJson['icon_url'] as String?,
      pointsReward: badgeJson['points_reward'] as int? ?? 0,
      awardedAt: json['awarded_at'] != null
          ? DateTime.parse(json['awarded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'points_reward': pointsReward,
      'awarded_at': awardedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Badge(id: $id, name: $name)';
}
