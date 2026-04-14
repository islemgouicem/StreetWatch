enum VoteValue {
  upvote(1),
  downvote(-1);

  final int value;
  const VoteValue(this.value);

  factory VoteValue.fromInt(int value) {
    return value > 0 ? VoteValue.upvote : VoteValue.downvote;
  }
}

class Vote {
  final String id;
  final String reportId;
  final String userId;
  final VoteValue value;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vote({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.value,
    required this.createdAt,
    this.updatedAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      userId: json['user_id'] as String,
      value: VoteValue.fromInt(json['value'] as int? ?? 1),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'user_id': userId,
      'value': value.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Vote(id: $id, reportId: $reportId, value: ${value.value})';
}
