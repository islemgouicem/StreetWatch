import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserFetchEvent extends UserEvent {
  final String userId;

  const UserFetchEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UserUpdateEvent extends UserEvent {
  final String? username;
  final String? avatarUrl;

  const UserUpdateEvent({this.username, this.avatarUrl});

  @override
  List<Object?> get props => [username, avatarUrl];
}
