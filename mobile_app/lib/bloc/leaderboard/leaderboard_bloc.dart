import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final ApiService apiService;

  LeaderboardBloc(this.apiService) : super(const LeaderboardInitial()) {
    on<LeaderboardFetchEvent>(_onFetchLeaderboard);
  }

  Future<void> _onFetchLeaderboard(
    LeaderboardFetchEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    try {
      final entries = await apiService.getLeaderboard(limit: event.limit);
      emit(LeaderboardLoaded(entries));
    } catch (e) {
      emit(LeaderboardFailure(e.toString()));
    }
  }
}
