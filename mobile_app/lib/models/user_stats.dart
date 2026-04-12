class UserStats {
  final int reportsCount;
  final int verifiedReports;
  final int votesCast;
  final int badgesCount;
  final int points;

  UserStats({
    required this.reportsCount,
    required this.verifiedReports,
    required this.votesCast,
    required this.badgesCount,
    required this.points,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      reportsCount: json['reports_count'] as int? ?? 0,
      verifiedReports: json['verified_reports'] as int? ?? 0,
      votesCast: json['votes_cast'] as int? ?? 0,
      badgesCount: json['badges_count'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
    );
  }
}
