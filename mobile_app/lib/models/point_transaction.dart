class PointTransaction {
  final String id;
  final String userId;
  final String sourceType;
  final String? sourceId;
  final int delta;
  final String? reason;
  final DateTime createdAt;

  PointTransaction({
    required this.id,
    required this.userId,
    required this.sourceType,
    this.sourceId,
    required this.delta,
    this.reason,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceType: json['source_type'] as String? ?? 'unknown',
      sourceId: json['source_id'] as String?,
      delta: json['delta'] as int? ?? 0,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
