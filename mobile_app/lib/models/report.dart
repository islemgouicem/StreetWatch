enum DamageType {
  pothole('pothole'),
  longitudinalCrack('longitudinal_crack'),
  transverseCrack('transverse_crack'),
  alligatorCrack('alligator_crack'),
  other('other');

  final String value;
  const DamageType(this.value);

  factory DamageType.fromString(String value) {
    final normalized = normalizeDamageTypeValue(value);
    return DamageType.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => DamageType.other,
    );
  }
}

String normalizeDamageTypeValue(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
  switch (normalized) {
    case 'crack':
      return DamageType.longitudinalCrack.value;
    case 'other':
    case 'other_damage':
    case 'other_damages':
    case 'broken_sign':
    case 'flooding':
    case 'debris':
      return DamageType.other.value;
    default:
      return normalized;
  }
}

String damageTypeDisplayLabel(DamageType damageType) {
  switch (damageType) {
    case DamageType.pothole:
      return 'Pothole';
    case DamageType.longitudinalCrack:
      return 'Longitudinal Crack';
    case DamageType.transverseCrack:
      return 'Transverse Crack';
    case DamageType.alligatorCrack:
      return 'Alligator Crack';
    case DamageType.other:
      return 'Other Damage';
  }
}

enum Severity {
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const Severity(this.value);

  factory Severity.fromString(String value) {
    return Severity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Severity.medium,
    );
  }
}

enum ReportStatus {
  pending('pending'),
  verified('verified'),
  rejected('rejected'),
  resolved('resolved');

  final String value;
  const ReportStatus(this.value);

  factory ReportStatus.fromString(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

class Report {
  final String id;
  final String userId;
  final String? imageUrl;
  final DamageType damageType;
  final Severity severity;
  final String? description;
  final double latitude;
  final double longitude;
  final ReportStatus status;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userName;
  final int? userPoints;
  final double? distanceMeters;

  Report({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.damageType,
    required this.severity,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdAt,
    this.updatedAt,
    required this.userName,
    this.userPoints,
    this.distanceMeters,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String?,
      damageType: DamageType.fromString(
        json['damage_type'] as String? ?? 'other',
      ),
      severity: Severity.fromString(json['severity'] as String? ?? 'medium'),
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: ReportStatus.fromString(json['status'] as String? ?? 'pending'),
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userName: json['user_name'] as String? ?? 'Anonymous',
      userPoints: json['user_points'] as int?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'damage_type': damageType.value,
      'severity': severity.value,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.value,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_name': userName,
      'user_points': userPoints,
      'distance_meters': distanceMeters,
    };
  }

  int get voteScore => upvotes - downvotes;

  @override
  String toString() =>
      'Report(id: $id, status: $status, damage: ${damageType.value}, severity: ${severity.value})';
}
