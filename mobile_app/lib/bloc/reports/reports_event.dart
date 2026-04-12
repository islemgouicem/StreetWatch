import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class ReportsFetchEvent extends ReportsEvent {
  final int? page;
  final int pageSize;

  const ReportsFetchEvent({this.page = 1, this.pageSize = 10});

  @override
  List<Object?> get props => [page, pageSize];
}

class ReportsFetchNearbyEvent extends ReportsEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const ReportsFetchNearbyEvent({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

class ReportCreateEvent extends ReportsEvent {
  final String damageType;
  final String severity;
  final double latitude;
  final double longitude;
  final String? description;
  final String? imageUrl;

  const ReportCreateEvent({
    required this.damageType,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.description,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
    damageType,
    severity,
    latitude,
    longitude,
    description,
    imageUrl,
  ];
}

class ReportVoteEvent extends ReportsEvent {
  final String reportId;
  final bool upvote;

  const ReportVoteEvent({required this.reportId, required this.upvote});

  @override
  List<Object?> get props => [reportId, upvote];
}
