import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/bloc/auth/auth_bloc.dart';
import 'package:mobile_app/bloc/auth/auth_event.dart';
import 'package:mobile_app/bloc/auth/auth_state.dart';
import 'package:mobile_app/services/api_service.dart';

import '../test_helpers.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService apiService;

  setUp(() {
    apiService = MockApiService();
  });

  blocTest<AuthBloc, AuthState>(
    'emits loading then success when current user is fetched',
    build: () {
      when(
        () => apiService.getCurrentUser(),
      ).thenAnswer((_) async => sampleUser());
      return AuthBloc(apiService);
    },
    act: (bloc) => bloc.add(const AuthFetchCurrentUserEvent()),
    expect: () => [const AuthLoading(), isA<AuthSuccess>()],
    verify: (_) {
      verify(() => apiService.getCurrentUser()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits loading then failure when current user fetch throws',
    build: () {
      when(() => apiService.getCurrentUser()).thenThrow(Exception('boom'));
      return AuthBloc(apiService);
    },
    act: (bloc) => bloc.add(const AuthFetchCurrentUserEvent()),
    expect: () => [const AuthLoading(), isA<AuthFailure>()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits cleared when clear event is sent',
    build: () => AuthBloc(apiService),
    act: (bloc) => bloc.add(const AuthClearUserEvent()),
    expect: () => [const AuthCleared()],
  );
}
