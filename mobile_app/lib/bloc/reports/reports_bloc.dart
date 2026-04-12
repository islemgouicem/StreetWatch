import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ApiService apiService;

  ReportsBloc(this.apiService) : super(const ReportsInitial()) {
    on<ReportsFetchEvent>(_onFetchReports);
    on<ReportsFetchNearbyEvent>(_onFetchNearby);
    on<ReportCreateEvent>(_onCreateReport);
    on<ReportVoteEvent>(_onVoteReport);
  }

  Future<void> _onFetchReports(
    ReportsFetchEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      final reports = await apiService.getReports(
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(ReportsLoaded(reports: reports, page: event.page ?? 1));
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }

  Future<void> _onFetchNearby(
    ReportsFetchNearbyEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      final reports = await apiService.getNearbyReports(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      emit(NearbyReportsLoaded(reports));
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }

  Future<void> _onCreateReport(
    ReportCreateEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      final report = await apiService.createReport(
        damageType: event.damageType,
        severity: event.severity,
        latitude: event.latitude,
        longitude: event.longitude,
        description: event.description,
        imageUrl: event.imageUrl,
      );
      emit(ReportCreated(report));
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }

  Future<void> _onVoteReport(
    ReportVoteEvent event,
    Emitter<ReportsState> emit,
  ) async {
    try {
      await apiService.voteReport(event.reportId, upvote: event.upvote);
      emit(const ReportVoted());
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }
}
