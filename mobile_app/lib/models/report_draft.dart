class ReportDraft {
  final String imagePath;
  final String damageType;
  final String severity;
  final String? description;
  final double? latitude;
  final double? longitude;
  final List<Map<String, dynamic>>? boundingBoxes;

  const ReportDraft({
    required this.imagePath,
    required this.damageType,
    required this.severity,
    this.description,
    this.latitude,
    this.longitude,
    this.boundingBoxes,
  });

  ReportDraft copyWith({
    String? imagePath,
    String? damageType,
    String? severity,
    String? description,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>>? boundingBoxes,
  }) {
    return ReportDraft(
      imagePath: imagePath ?? this.imagePath,
      damageType: damageType ?? this.damageType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      boundingBoxes: boundingBoxes ?? this.boundingBoxes,
    );
  }
}
