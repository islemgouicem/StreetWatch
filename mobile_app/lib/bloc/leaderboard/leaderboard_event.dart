import 'package:equatable/equatable.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class LeaderboardFetchEvent extends LeaderboardEvent {
  final int? limit;

  const LeaderboardFetchEvent({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}
