import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_app/bloc/reports/reports_bloc.dart';
import 'package:mobile_app/bloc/reports/reports_event.dart';
import 'package:mobile_app/bloc/reports/reports_state.dart';
import 'package:mobile_app/services/api_service.dart';

import '../test_helpers.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService apiService;

  setUp(() {
    apiService = MockApiService();
  });

  blocTest<ReportsBloc, ReportsState>(
    'emits loading then loaded when reports are fetched',
    build: () {
      when(
        () => apiService.getReports(page: 1, pageSize: 10),
      ).thenAnswer((_) async => [sampleReport()]);
      return ReportsBloc(apiService);
    },
    act: (bloc) => bloc.add(const ReportsFetchEvent()),
    expect: () => [
      const ReportsLoading(),
      isA<ReportsLoaded>().having((state) => state.page, 'page', 1),
    ],
    verify: (_) {
      verify(() => apiService.getReports(page: 1, pageSize: 10)).called(1);
    },
  );

  blocTest<ReportsBloc, ReportsState>(
    'emits loading then nearby reports when nearby fetch succeeds',
    build: () {
      when(
        () => apiService.getNearbyReports(
          latitude: 36.687154,
          longitude: 2.865557,
          radiusKm: 5.0,
        ),
      ).thenAnswer((_) async => [sampleReport()]);
      return ReportsBloc(apiService);
    },
    act: (bloc) => bloc.add(
      const ReportsFetchNearbyEvent(latitude: 36.687154, longitude: 2.865557),
    ),
    expect: () => [const ReportsLoading(), isA<NearbyReportsLoaded>()],
  );

  blocTest<ReportsBloc, ReportsState>(
    'emits report created after create event succeeds',
    build: () {
      when(
        () => apiService.createReport(
          damageType: 'pothole',
          severity: 'high',
          latitude: 36.0,
          longitude: 2.0,
          description: 'desc',
          imageUrl: 'https://example.com/img.png',
        ),
      ).thenAnswer((_) async => sampleReport());
      return ReportsBloc(apiService);
    },
    act: (bloc) => bloc.add(
      const ReportCreateEvent(
        damageType: 'pothole',
        severity: 'high',
        latitude: 36.0,
        longitude: 2.0,
        description: 'desc',
        imageUrl: 'https://example.com/img.png',
      ),
    ),
    expect: () => [const ReportsLoading(), isA<ReportCreated>()],
  );

  blocTest<ReportsBloc, ReportsState>(
    'emits report voted when vote succeeds',
    build: () {
      when(
        () => apiService.voteReport('report-1', upvote: true),
      ).thenAnswer((_) async {});
      return ReportsBloc(apiService);
    },
    act: (bloc) =>
        bloc.add(const ReportVoteEvent(reportId: 'report-1', upvote: true)),
    expect: () => [const ReportVoted()],
  );
}
