class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int points;
  final int reports;
  final int verifiedReports;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.points,
    required this.reports,
    required this.verifiedReports,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) {
    return LeaderboardEntry(
      rank: rank,
      userId: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'Anonymous',
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      points: json['points'] as int? ?? 0,
      reports: json['total_reports'] as int? ?? 0,
      verifiedReports: json['verified_reports'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'points': points,
      'total_reports': reports,
      'verified_reports': verifiedReports,
    };
  }

  @override
  String toString() =>
      'LeaderboardEntry(rank: $rank, username: $username, points: $points, avatarUrl: $avatarUrl)';
}