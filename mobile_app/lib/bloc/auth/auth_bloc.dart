import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc(this.apiService) : super(const AuthInitial()) {
    on<AuthFetchCurrentUserEvent>(_onFetchCurrentUser);
    on<AuthClearUserEvent>(_onClearUser);
  }

  Future<void> _onFetchCurrentUser(
    AuthFetchCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await apiService.getCurrentUser();
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onClearUser(
    AuthClearUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthCleared());
  }
}
