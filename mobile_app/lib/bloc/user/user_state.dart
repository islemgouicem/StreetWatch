import 'package:equatable/equatable.dart';
import '../../models/index.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  final User user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserUpdated extends UserState {
  final User user;

  const UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserFailure extends UserState {
  final String message;

  const UserFailure(this.message);

  @override
  List<Object?> get props => [message];
}
