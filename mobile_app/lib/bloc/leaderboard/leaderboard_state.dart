import 'package:equatable/equatable.dart';
import '../../models/index.dart';

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntry> entries;

  const LeaderboardLoaded(this.entries);

  @override
  List<Object?> get props => [entries];
}

class LeaderboardFailure extends LeaderboardState {
  final String message;

  const LeaderboardFailure(this.message);

  @override
  List<Object?> get props => [message];
}
