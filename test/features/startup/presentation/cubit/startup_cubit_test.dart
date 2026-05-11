import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/startup/presentation/cubit/startup_cubit.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    // Default: stream is empty so the cubit awaits indefinitely unless the
    // individual test stubs a richer stream / synchronous state.
    whenListen<AuthState>(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthInitial(),
    );
  });

  group('StartupCubit', () {
    test('initial state is StartupInitial', () async {
      final cubit = StartupCubit(authBloc: authBloc);
      expect(cubit.state, isA<StartupInitial>());
      await cubit.close();
    });

    blocTest<StartupCubit, StartupState>(
      'initialize() with synchronous AuthAuthenticated emits Loading -> Authenticated',
      build: () {
        when(() => authBloc.state)
            .thenReturn(AuthAuthenticated(AuthUserFactory.withHousehold()));
        return StartupCubit(authBloc: authBloc);
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const StartupLoading(progress: 0.2),
        const StartupLoading(progress: 0.7),
        const StartupAuthenticated(),
      ],
    );

    blocTest<StartupCubit, StartupState>(
      'initialize() with synchronous AuthUnauthenticated emits Loading -> Unauthenticated',
      build: () {
        when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
        return StartupCubit(authBloc: authBloc);
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const StartupLoading(progress: 0.2),
        const StartupLoading(progress: 0.7),
        const StartupUnauthenticated(),
      ],
    );

    blocTest<StartupCubit, StartupState>(
      'initialize() while AuthInitial resolves once stream emits AuthAuthenticated',
      build: () {
        whenListen<AuthState>(
          authBloc,
          Stream<AuthState>.fromIterable([
            AuthAuthenticated(AuthUserFactory.withHousehold()),
          ]),
          initialState: const AuthInitial(),
        );
        return StartupCubit(authBloc: authBloc);
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const StartupLoading(progress: 0.2),
        const StartupLoading(progress: 0.7),
        const StartupAuthenticated(),
      ],
    );

    blocTest<StartupCubit, StartupState>(
      'AuthNeedsHousehold counts as a session (StartupAuthenticated)',
      build: () {
        when(() => authBloc.state)
            .thenReturn(AuthNeedsHousehold(AuthUserFactory.withoutHousehold()));
        return StartupCubit(authBloc: authBloc);
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const StartupLoading(progress: 0.2),
        const StartupLoading(progress: 0.7),
        const StartupAuthenticated(),
      ],
    );

    blocTest<StartupCubit, StartupState>(
      'AuthErrorState resolves to StartupUnauthenticated',
      build: () {
        when(() => authBloc.state).thenReturn(
          const AuthErrorState(AuthCancelledFailure()),
        );
        return StartupCubit(authBloc: authBloc);
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const StartupLoading(progress: 0.2),
        const StartupLoading(progress: 0.7),
        const StartupUnauthenticated(),
      ],
    );

    blocTest<StartupCubit, StartupState>(
      'initialize() ignores transient AuthLoading and waits for terminal state',
      build: () {
        whenListen<AuthState>(
          authBloc,
          Stream<AuthState>.fromIterable([
            const AuthLoading(),
            AuthAuthenticated(AuthUserFactory.withHousehold()),
          ]),
          initialState: const AuthInitial(),
        );
        return StartupCubit(authBloc: authBloc);
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const StartupLoading(progress: 0.2),
        const StartupLoading(progress: 0.7),
        const StartupAuthenticated(),
      ],
    );

    blocTest<StartupCubit, StartupState>(
      'calling initialize() twice from a terminal state is a no-op',
      build: () {
        when(() => authBloc.state)
            .thenReturn(AuthAuthenticated(AuthUserFactory.withHousehold()));
        return StartupCubit(authBloc: authBloc);
      },
      act: (cubit) async {
        await cubit.initialize();
        await cubit.initialize();
      },
      expect: () => [
        const StartupLoading(progress: 0.2),
        const StartupLoading(progress: 0.7),
        const StartupAuthenticated(),
      ],
    );
  });
}
