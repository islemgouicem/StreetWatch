import 'package:mobile_app/models/index.dart';

User sampleUser({
  String id = 'user-1',
  String email = 'alex@example.com',
  String? username = 'alex',
  String? avatarUrl = 'https://example.com/avatar.png',
  int points = 1250,
  int totalReports = 7,
  int verifiedReports = 4,
  bool isAdmin = false,
}) {
  return User(
    id: id,
    email: email,
    username: username,
    avatarUrl: avatarUrl,
    points: points,
    totalReports: totalReports,
    verifiedReports: verifiedReports,
    createdAt: DateTime.utc(2026, 4, 11),
    updatedAt: DateTime.utc(2026, 4, 11),
    isAdmin: isAdmin,
  );
}

Report sampleReport({
  String id = 'report-1',
  String userId = 'user-1',
  String? imageUrl = 'https://example.com/report.png',
  DamageType damageType = DamageType.pothole,
  Severity severity = Severity.high,
  String? description = 'Large pothole',
  double latitude = 36.687154,
  double longitude = 2.865557,
  ReportStatus status = ReportStatus.pending,
  int upvotes = 5,
  int downvotes = 1,
  String userName = 'Alex',
  int? userPoints = 1250,
}) {
  return Report(
    id: id,
    userId: userId,
    imageUrl: imageUrl,
    damageType: damageType,
    severity: severity,
    description: description,
    latitude: latitude,
    longitude: longitude,
    status: status,
    upvotes: upvotes,
    downvotes: downvotes,
    createdAt: DateTime.utc(2026, 4, 11),
    updatedAt: DateTime.utc(2026, 4, 11),
    userName: userName,
    userPoints: userPoints,
  );
}

LeaderboardEntry sampleLeaderboardEntry({
  int rank = 1,
  String userId = 'user-1',
  String username = 'alex',
  String? avatarUrl = 'https://example.com/avatar.png',
  int points = 1250,
  int reports = 7,
  int verifiedReports = 4,
}) {
  return LeaderboardEntry(
    rank: rank,
    userId: userId,
    username: username,
    avatarUrl: avatarUrl,
    points: points,
    reports: reports,
    verifiedReports: verifiedReports,
  );
}
