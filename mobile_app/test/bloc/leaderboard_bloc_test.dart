import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_app/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:mobile_app/bloc/leaderboard/leaderboard_event.dart';
import 'package:mobile_app/bloc/leaderboard/leaderboard_state.dart';
import 'package:mobile_app/services/api_service.dart';

import '../test_helpers.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService apiService;

  setUp(() {
    apiService = MockApiService();
  });

  blocTest<LeaderboardBloc, LeaderboardState>(
    'emits loading then loaded when leaderboard fetch succeeds',
    build: () {
      when(
        () => apiService.getLeaderboard(limit: 50),
      ).thenAnswer((_) async => [sampleLeaderboardEntry()]);
      return LeaderboardBloc(apiService);
    },
    act: (bloc) => bloc.add(const LeaderboardFetchEvent()),
    expect: () => [const LeaderboardLoading(), isA<LeaderboardLoaded>()],
    verify: (_) {
      verify(() => apiService.getLeaderboard(limit: 50)).called(1);
    },
  );

  blocTest<LeaderboardBloc, LeaderboardState>(
    'emits failure when leaderboard fetch throws',
    build: () {
      when(
        () => apiService.getLeaderboard(limit: 50),
      ).thenThrow(Exception('boom'));
      return LeaderboardBloc(apiService);
    },
    act: (bloc) => bloc.add(const LeaderboardFetchEvent()),
    expect: () => [const LeaderboardLoading(), isA<LeaderboardFailure>()],
  );
}
