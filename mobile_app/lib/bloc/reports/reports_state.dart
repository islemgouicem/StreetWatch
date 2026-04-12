import 'package:equatable/equatable.dart';
import '../../models/index.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsLoaded extends ReportsState {
  final List<Report> reports;
  final int page;

  const ReportsLoaded({required this.reports, required this.page});

  @override
  List<Object?> get props => [reports, page];
}

class NearbyReportsLoaded extends ReportsState {
  final List<Report> reports;

  const NearbyReportsLoaded(this.reports);

  @override
  List<Object?> get props => [reports];
}

class ReportCreated extends ReportsState {
  final Report report;

  const ReportCreated(this.report);

  @override
  List<Object?> get props => [report];
}

class ReportVoted extends ReportsState {
  const ReportVoted();
}

class ReportsFailure extends ReportsState {
  final String message;

  const ReportsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
