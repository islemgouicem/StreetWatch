class User {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final int points;
  final int totalReports;
  final int verifiedReports;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAdmin;
  final String? image_profile;

  User({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.points = 0,
    this.totalReports = 0,
    this.verifiedReports = 0,
    required this.createdAt,
    this.updatedAt,
    this.isAdmin = false, 
    this.image_profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final avatarUrl = _readString(json['avatar_url']) ??
        _readString(json['avatarUrl']) ??
        _readString(json['image_profile']);

    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      image_profile: _readString(json['image_profile']),
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: avatarUrl,
      points: json['points'] as int? ?? 0,
      totalReports: json['total_reports'] as int? ?? 0,
      verifiedReports: json['verified_reports'] as int? ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'points': points,
      'total_reports': totalReports,
      'verified_reports': verifiedReports,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_admin': isAdmin,
      'image_profile': image_profile,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? image_profile,
    String? fullName,
    String? avatarUrl,
    int? points,
    int? totalReports,
    int? verifiedReports,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      image_profile: image_profile ?? this.image_profile,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      totalReports: totalReports ?? this.totalReports,
      verifiedReports: verifiedReports ?? this.verifiedReports,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  String toString() =>
      'User(id: $id, email: $email, username: $username, points: $points)';
}

String? _readString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
