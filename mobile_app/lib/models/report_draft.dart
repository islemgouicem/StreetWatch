class ReportDraft {
  final String imagePath;
  final String damageType;
  final String severity;
  final String? description;
  final double? latitude;
  final double? longitude;

  const ReportDraft({
    required this.imagePath,
    required this.damageType,
    required this.severity,
    this.description,
    this.latitude,
    this.longitude,
  });

  ReportDraft copyWith({
    String? imagePath,
    String? damageType,
    String? severity,
    String? description,
    double? latitude,
    double? longitude,
  }) {
    return ReportDraft(
      imagePath: imagePath ?? this.imagePath,
      damageType: damageType ?? this.damageType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
