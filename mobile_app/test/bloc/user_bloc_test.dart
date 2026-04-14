import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_app/bloc/user/user_bloc.dart';
import 'package:mobile_app/bloc/user/user_event.dart';
import 'package:mobile_app/bloc/user/user_state.dart';
import 'package:mobile_app/services/api_service.dart';

import '../test_helpers.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService apiService;

  setUp(() {
    apiService = MockApiService();
  });

  blocTest<UserBloc, UserState>(
    'emits loading then loaded when user is fetched',
    build: () {
      when(
        () => apiService.getUser('user-1'),
      ).thenAnswer((_) async => sampleUser());
      return UserBloc(apiService);
    },
    act: (bloc) => bloc.add(const UserFetchEvent('user-1')),
    expect: () => [const UserLoading(), isA<UserLoaded>()],
  );

  blocTest<UserBloc, UserState>(
    'emits loading then updated when user update succeeds',
    build: () {
      when(
        () => apiService.updateUser(username: 'new-name', avatarUrl: null),
      ).thenAnswer((_) async => sampleUser(username: 'new-name'));
      return UserBloc(apiService);
    },
    act: (bloc) => bloc.add(const UserUpdateEvent(username: 'new-name')),
    expect: () => [const UserLoading(), isA<UserUpdated>()],
  );

  blocTest<UserBloc, UserState>(
    'emits failure when user fetch throws',
    build: () {
      when(() => apiService.getUser('user-1')).thenThrow(Exception('boom'));
      return UserBloc(apiService);
    },
    act: (bloc) => bloc.add(const UserFetchEvent('user-1')),
    expect: () => [const UserLoading(), isA<UserFailure>()],
  );
}
