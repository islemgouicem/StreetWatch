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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
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
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
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
