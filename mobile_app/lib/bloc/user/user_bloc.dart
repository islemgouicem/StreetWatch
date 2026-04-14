import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final ApiService apiService;

  UserBloc(this.apiService) : super(const UserInitial()) {
    on<UserFetchEvent>(_onFetchUser);
    on<UserUpdateEvent>(_onUpdateUser);
  }

  Future<void> _onFetchUser(
    UserFetchEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final user = await apiService.getUser(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserFailure(e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UserUpdateEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final user = await apiService.updateUser(
        username: event.username,
        avatarUrl: event.avatarUrl,
      );
      emit(UserUpdated(user));
    } catch (e) {
      emit(UserFailure(e.toString()));
    }
  }
}
